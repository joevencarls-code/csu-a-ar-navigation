import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../data/campus_routes_data.dart';
import '../models/campus_models.dart';
import '../models/campus_route.dart';
import '../services/campus_repository.dart';
import '../services/chat_service.dart';
import '../theme/app_colors.dart';
import '../widgets/on_screen_keyboard.dart';
import '../widgets/route_overlay_painter.dart';
import 'directory_screen.dart';
import 'campus_info_screen.dart';
import 'about_screen.dart';

enum _KeyboardTarget { none, mapSearch, chat }

/// Maps building names to AR navigation QR code keys.
const Map<String, String> _buildingQrKeys = {
  'Administration Building': 'admin',
  'College of Teacher Education': 'cte',
  'Gymplex': 'gymplex',
  'Gatchalian Building': 'gatchalian',
  'College of Information and Computing Sciences': 'cics',
  'Library Building': 'library',
  'AVR Building': 'avr',
  'Canteen / Food Court': 'canteen',
  'CIT Building': 'cit',
  'CBEA Building': 'cbea',
  'Infrastructure Office': 'infra',
  'DNST Building': 'dnst',
  'Old Admin Building': 'oldadmin',
  'Hatchery': 'hatchery',
  'ICRM Building': 'icrm',
  "CEO's Cottage": 'ceo_cottage',
  'Executive Villa 1': 'villa1',
  "Lecturer's Dormitory": 'dorm',
};

/// Intrinsic aspect ratio (width / height) of assets/csu_map.png, used so the
/// route overlay's normalized coordinates always land on the right streets
/// regardless of the rendered size.
const double _kMapImageAspectRatio = 1672 / 941;

class MapDirectoryScreen extends StatefulWidget {
  const MapDirectoryScreen({super.key});

  @override
  State<MapDirectoryScreen> createState() => _MapDirectoryScreenState();
}

class _MapDirectoryScreenState extends State<MapDirectoryScreen>
    with TickerProviderStateMixin {
  bool showChatBot = false;
  bool showMapSearch = false;
  _KeyboardTarget _keyboardTarget = _KeyboardTarget.none;
  int selectedNavIndex = 1;
  late TextEditingController _messageController;
  late TextEditingController _mapSearchController;
  late ScrollController _scrollController;
  bool isLoading = false;
  late TransformationController _transformationController;
  double _currentZoom = 1.0;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _routeDrawController;
  late AnimationController _walkerController;
  late DateTime _currentTime;
  late Timer _timer;
  final CampusRepository _repository = CampusRepository();
  final ChatService _chatService = ChatService();
  List<Building> _buildings = [];
  List<OfficeEntry> _offices = [];
  String? _executiveOfficer;
  BuildingRouteSet? _activeRouteSet;
  RouteMode _activeMode = RouteMode.fastestWalk;
  Building? _selectedBuildingInfo;
  OfficeEntry? _selectedOfficeInfo;
  String? _selectedPlaceName;
  bool _navigating = false;

  CampusRoutePath? get _activeRoute => _activeRouteSet?.routes[_activeMode];

  final List<Map<String, String>> chatConversation = [
    {
      'sender': 'bot',
      'message':
          'Hello! I am the CSU-A Navigation Assistant. How can I help you find your way around campus?',
      'time': 'System',
    },
  ];

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController();
    _mapSearchController = TextEditingController();
    _scrollController = ScrollController();
    _transformationController = TransformationController();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _routeDrawController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _walkerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );
    _routeDrawController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _walkerController
          ..reset()
          ..repeat();
      }
    });
    _currentTime = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _currentTime = DateTime.now());
    });
    _loadDirectoryData();
  }

  Future<void> _loadDirectoryData() async {
    final results = await Future.wait([
      _repository.getBuildings(),
      _repository.getOfficeEntries(),
      _repository.getCampusSettings(),
    ]);
    if (!mounted) return;
    setState(() {
      _buildings = results[0] as List<Building>;
      _offices = results[1] as List<OfficeEntry>;
      _executiveOfficer = (results[2] as CampusSettings?)?.executiveOfficer;
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _messageController.dispose();
    _mapSearchController.dispose();
    _scrollController.dispose();
    _transformationController.dispose();
    _fadeController.dispose();
    _routeDrawController.dispose();
    _walkerController.dispose();
    super.dispose();
  }

  /// Restarts the "path draws, then a walker loops along it" animation for
  /// whichever route is now active.
  void _playRouteAnimation() {
    _walkerController.stop();
    _routeDrawController
      ..stop()
      ..forward(from: 0);
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.isEmpty) return;
    final userMessage = _messageController.text;
    _messageController.clear();

    final history = chatConversation
        .map((chat) => {
              'role': chat['sender'] == 'bot' ? 'assistant' : 'user',
              'content': chat['message']!,
            })
        .toList();

    setState(() {
      chatConversation.add({
        'sender': 'user',
        'message': userMessage,
        'time': _getCurrentTime(),
      });
      isLoading = true;
    });
    _scrollToBottom();

    try {
      final response = await _chatService.sendMessage(
        userMessage,
        history: history,
      );
      setState(() {
        chatConversation.add({
          'sender': 'bot',
          'message': response,
          'time': _getCurrentTime(),
        });
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        chatConversation.add({
          'sender': 'bot',
          'message': 'Sorry, something went wrong: $e',
          'time': _getCurrentTime(),
        });
        isLoading = false;
      });
    }
    _scrollToBottom();
  }

  String _getCurrentTime() {
    final now = DateTime.now();
    final h = now.hour > 12 ? now.hour - 12 : (now.hour == 0 ? 12 : now.hour);
    final m = now.minute.toString().padLeft(2, '0');
    final ampm = now.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $ampm';
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _zoomIn() {
    final matrix = _transformationController.value;
    _transformationController.value = Matrix4.identity()
      ..translate(matrix.getTranslation().x, matrix.getTranslation().y)
      ..scale(_currentZoom + 0.3);
    _currentZoom += 0.3;
  }

  void _zoomOut() {
    if (_currentZoom > 1.0) {
      _transformationController.value =
          Matrix4.identity()..scale(_currentZoom - 0.3);
      _currentZoom -= 0.3;
    }
  }

  void _resetMap() {
    _transformationController.value = Matrix4.identity();
    _currentZoom = 1.0;
  }

  Building? _findBuildingByName(String name) {
    final q = name.toLowerCase().trim();
    for (final b in _buildings) {
      final bn = b.name.toLowerCase();
      if (bn == q || bn.contains(q) || q.contains(bn)) return b;
    }
    return null;
  }

  OfficeEntry? _findOfficeByName(String name) {
    final q = name.toLowerCase().trim();
    for (final o in _offices) {
      final on = o.name.toLowerCase();
      final ob = (o.abbreviation ?? '').toLowerCase();
      if (on == q || on.contains(q) || q.contains(on) || (ob.isNotEmpty && ob == q)) {
        return o;
      }
    }
    return null;
  }

  void _selectBuilding(String name) {
    final info = _findBuildingByName(name);
    final office = info == null ? _findOfficeByName(name) : null;
    setState(() {
      _mapSearchController.text = name;
      showMapSearch = false;
      if (_keyboardTarget == _KeyboardTarget.mapSearch) {
        _keyboardTarget = _KeyboardTarget.none;
      }
      _selectedPlaceName = name;
      _selectedBuildingInfo = info;
      _selectedOfficeInfo = office;
      _navigating = false;
      _activeRouteSet = null;
      _activeMode = RouteMode.fastestWalk;
    });
  }

  void _startNavigation() {
    final name = _selectedPlaceName;
    if (name == null || name.isEmpty) return;
    final routeSet = findRoutesFor(name);
    setState(() {
      _navigating = true;
      _activeRouteSet = routeSet;
      _activeMode = RouteMode.fastestWalk;
    });
    if (routeSet != null) {
      _playRouteAnimation();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Directions not available yet for "$name".'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _clearRoute() {
    _routeDrawController.stop();
    _walkerController.stop();
    setState(() {
      _mapSearchController.clear();
      showMapSearch = false;
      _activeRouteSet = null;
      _selectedBuildingInfo = null;
      _selectedOfficeInfo = null;
      _selectedPlaceName = null;
      _navigating = false;
      if (_keyboardTarget == _KeyboardTarget.mapSearch) {
        _keyboardTarget = _KeyboardTarget.none;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(context).pop();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        body: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildMapView(context),
                    _buildMapSearchBar(context),
                    if (_selectedPlaceName != null ||
                        _selectedBuildingInfo != null ||
                        _activeRouteSet != null)
                      _buildPlaceInfoPanel(context),
                    _buildZoomControls(context),
                    _buildChatbotButton(context),
                    if (showChatBot) _buildChatbotPanel(context),
                    if (_keyboardTarget == _KeyboardTarget.mapSearch)
                      _buildKeyboardOverlay(context),
                  ],
                ),
              ),
            ),
            _buildBottomNav(context),
          ],
        ),
      ),
    );
  }

  String _formattedDate(DateTime dt) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  Widget _buildHeader(BuildContext context) {
    final h = _currentTime.hour > 12
        ? _currentTime.hour - 12
        : (_currentTime.hour == 0 ? 12 : _currentTime.hour);
    final m = _currentTime.minute.toString().padLeft(2, '0');
    final ampm = _currentTime.hour >= 12 ? 'PM' : 'AM';

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.royalBlue, AppColors.royalBlueDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                size: 20,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.account_balance_rounded,
              size: 22,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cagayan State University',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Aparri Campus  •  Wayfinding Hub',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withValues(alpha: 0.7),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.access_time_rounded,
                  size: 14,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
                const SizedBox(width: 6),
                Text(
                  '$h:$m $ampm',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 1,
                  height: 14,
                  color: Colors.white.withValues(alpha: 0.3),
                ),
                const SizedBox(width: 10),
                Icon(
                  Icons.calendar_today_rounded,
                  size: 12,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
                const SizedBox(width: 6),
                Text(
                  _formattedDate(_currentTime),
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildMapView(BuildContext context) {
    final activeRoute = _activeRoute;
    return Container(
      color: const Color(0xFFE8EDF2),
      child: InteractiveViewer(
        transformationController: _transformationController,
        minScale: 1.0,
        maxScale: 4.0,
        child: Center(
          child: AspectRatio(
            aspectRatio: _kMapImageAspectRatio,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  'assets/csu_map.png',
                  fit: BoxFit.fill,
                  errorBuilder: (_, __, ___) => _buildMapPlaceholder(),
                ),
                if (activeRoute != null)
                  AnimatedBuilder(
                    animation: Listenable.merge(
                      [_routeDrawController, _walkerController],
                    ),
                    builder: (context, _) => CustomPaint(
                      painter: RouteOverlayPainter(
                        activeRoute,
                        pathProgress: _routeDrawController.value,
                        walkerT: _walkerController.value,
                      ),
                    ),
                  ),
                for (final routeSet in allBuildingRoutes)
                  _buildBuildingPin(routeSet),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBuildingPin(BuildingRouteSet routeSet) {
    final isSelected = _selectedBuildingInfo?.name == routeSet.buildingName ||
        _activeRouteSet == routeSet;
    final isAdmin = routeSet.buildingName == 'Administration Building';
    final p = routeSet.markerPoint;
    return Align(
      alignment: Alignment(p.dx * 2 - 1, p.dy * 2 - 1),
      child: GestureDetector(
        onTap: () => _selectBuilding(routeSet.buildingName),
        child: AnimatedScale(
          scale: isSelected ? 1.15 : 1.0,
          duration: const Duration(milliseconds: 150),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.gold : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.white : AppColors.royalBlue,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              isAdmin
                  ? Icons.admin_panel_settings_rounded
                  : Icons.account_balance_rounded,
              size: 16,
              color: isSelected ? Colors.white : AppColors.royalBlue,
            ),
          ),
        ),
      ),
    );
  }

  List<Map<String, String>> _mapSearchResults(String query) {
    if (query.isEmpty) return [];
    final q = query.toLowerCase();
    final results = <Map<String, String>>[];
    for (final b in _buildings) {
      if (b.name.toLowerCase().contains(q) ||
          (b.offices ?? '').toLowerCase().contains(q)) {
        results.add({'type': 'Building', 'name': b.name, 'detail': b.location ?? ''});
      }
    }
    for (final o in _offices) {
      if (o.name.toLowerCase().contains(q) ||
          (o.abbreviation ?? '').toLowerCase().contains(q)) {
        results.add({'type': 'Office', 'name': o.name, 'detail': o.location ?? ''});
      }
    }
    return results;
  }

  Widget _buildMapSearchBar(BuildContext context) {
    final barWidth = (MediaQuery.of(context).size.width * 0.25).clamp(150.0, 260.0);
    return Positioned(
      top: 12,
      left: 16,
      child: SizedBox(
        width: barWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(11),
              border: Border.all(
                color: AppColors.royalBlue.withValues(alpha: 0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.royalBlue.withValues(alpha: 0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              controller: _mapSearchController,
              onTap: () => setState(() {
                showMapSearch = true;
                _keyboardTarget = _KeyboardTarget.mapSearch;
              }),
              onChanged: (_) => setState(() {}),
              style: GoogleFonts.inter(fontSize: 12),
              decoration: InputDecoration(
                hintText: 'Search...',
                hintStyle: GoogleFonts.inter(fontSize: 12, color: Colors.grey[400]),
                prefixIcon: const Icon(Icons.search_rounded, size: 16, color: AppColors.royalBlue),
                prefixIconConstraints: const BoxConstraints(minWidth: 30, minHeight: 16),
                suffixIcon: showMapSearch || _activeRouteSet != null
                    ? GestureDetector(
                        onTap: _clearRoute,
                        child: const Icon(Icons.close_rounded, size: 14, color: Colors.grey),
                      )
                    : null,
                suffixIconConstraints: const BoxConstraints(minWidth: 26, minHeight: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(11),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              ),
            ),
          ),
          if (showMapSearch) ...[
            const SizedBox(height: 8),
            Container(
              constraints: const BoxConstraints(maxHeight: 220),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.grey.withValues(alpha: 0.15),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: _mapSearchController.text.isEmpty
                  ? _buildSearchSuggestions()
                  : _buildSearchResults(),
            ),
          ],
          ],
        ),
      ),
    );
  }

  /// A Google-Maps-style place card: photo, details, and directions for
  /// whichever building is selected (via search or by tapping its pin).
  Widget _buildPlaceInfoPanel(BuildContext context) {
    final building = _selectedBuildingInfo;
    final office = _selectedOfficeInfo;
    final routeSet = _activeRouteSet;
    final route = _activeRoute;
    final title =
        _selectedPlaceName ?? building?.name ?? office?.name ?? routeSet?.buildingName ?? '';
    final screenSize = MediaQuery.of(context).size;
    final panelWidth = screenSize.width < 420 ? screenSize.width - 32 : 320.0;
    final offices = (building?.offices ?? '')
        .split(',')
        .map((o) => o.trim())
        .where((o) => o.isNotEmpty)
        .toList();

    return Positioned(
      left: 16,
      top: 74,
      child: Container(
        width: panelWidth,
        constraints: BoxConstraints(maxHeight: screenSize.height * 0.75),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildPlacePanelImage(building, office),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.royalBlueDark,
                      ),
                    ),
                    if (office != null) ...[
                      if (office.abbreviation != null &&
                          office.abbreviation!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          office.abbreviation!,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.2,
                            color: AppColors.royalBlue,
                          ),
                        ),
                      ],
                      if (office.location != null &&
                          office.location!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.location_on_rounded, size: 15, color: AppColors.gold),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                office.location!,
                                style: GoogleFonts.inter(fontSize: 12.5, color: Colors.grey[600]),
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (office.head != null && office.head!.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: AppColors.gold.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(7),
                              ),
                              child: const Icon(Icons.person_rounded, size: 15, color: AppColors.gold),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'OFFICE HEAD',
                              style: GoogleFonts.inter(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: Colors.grey[400],
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Padding(
                          padding: const EdgeInsets.only(left: 34),
                          child: Text(
                            office.head!,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.royalBlueDark,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                      if (office.purpose != null &&
                          office.purpose!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: AppColors.royalBlue.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(7),
                              ),
                              child: const Icon(Icons.info_outline_rounded, size: 15, color: AppColors.royalBlue),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'ABOUT THIS OFFICE',
                              style: GoogleFonts.inter(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: Colors.grey[400],
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Padding(
                          padding: const EdgeInsets.only(left: 34),
                          child: Text(
                            office.purpose!,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              height: 1.5,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ],
                      if (office.contact != null &&
                          office.contact!.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: AppColors.royalBlue.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(7),
                              ),
                              child: const Icon(Icons.phone_rounded, size: 15, color: AppColors.royalBlue),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                office.contact!,
                                style: GoogleFonts.inter(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.royalBlueDark,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                    if (building?.location != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.location_on_rounded, size: 15, color: AppColors.gold),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              building!.location!,
                              style: GoogleFonts.inter(fontSize: 12.5, color: Colors.grey[600]),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (building?.dean != null &&
                        building!.dean!.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: AppColors.gold.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(7),
                            ),
                            child: const Icon(Icons.person_rounded, size: 15, color: AppColors.gold),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'BUILDING HEAD',
                            style: GoogleFonts.inter(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.grey[400],
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.only(left: 34),
                        child: Text(
                          building!.dean!,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.royalBlueDark,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                    if (building?.description != null &&
                        building!.description!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: AppColors.royalBlue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(7),
                            ),
                            child: const Icon(Icons.info_outline_rounded, size: 15, color: AppColors.royalBlue),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'ABOUT THIS BUILDING',
                            style: GoogleFonts.inter(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.grey[400],
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.only(left: 34),
                        child: Text(
                          building!.description!,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            height: 1.5,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                    if (offices.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        'INSIDE THIS BUILDING',
                        style: GoogleFonts.inter(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey[400],
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: offices.map((o) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppColors.royalBlue.withValues(alpha: 0.07),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              o,
                              style: GoogleFonts.inter(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.royalBlue,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                    if (_navigating && routeSet != null && route != null) ...[
                      const SizedBox(height: 14),
                      Divider(height: 1, color: Colors.grey[200]),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.directions_rounded, size: 16, color: AppColors.royalBlue),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Directions',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.royalBlueDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: RouteMode.values.map((mode) {
                          final routePath = routeSet.routes[mode];
                          if (routePath == null) return const SizedBox.shrink();
                          final selected = mode == _activeMode;
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: GestureDetector(
                                onTap: () {
                                  setState(() => _activeMode = mode);
                                  _playRouteAnimation();
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? mode.color.withValues(alpha: 0.12)
                                        : const Color(0xFFF5F7FA),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: selected ? mode.color : Colors.transparent,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(mode.icon, size: 18, color: selected ? mode.color : Colors.grey[500]),
                                      const SizedBox(height: 4),
                                      Text(
                                        mode.label,
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.inter(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w600,
                                          color: selected ? mode.color : Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(Icons.straighten_rounded, size: 14, color: Colors.grey[400]),
                          const SizedBox(width: 4),
                          Text(
                            route.distanceLabel,
                            style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600]),
                          ),
                          const SizedBox(width: 14),
                          Icon(Icons.schedule_rounded, size: 14, color: Colors.grey[400]),
                          const SizedBox(width: 4),
                          Text(
                            route.timeLabel,
                            style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ] else ...[
                      const SizedBox(height: 14),
                      Divider(height: 1, color: Colors.grey[200]),
                      const SizedBox(height: 12),
                      if (findRoutesFor(title) != null)
                        _buildNavigateButton(title)
                      else if (title.isNotEmpty)
                        Text(
                          'Directions not available yet for "$title".',
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            color: Colors.grey[400],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                    ],
                    // ── AR Navigation QR Code (shown once navigating) ──
                    if (_navigating && _buildingQrKeys.containsKey(title)) ...[
                      const SizedBox(height: 14),
                      Divider(height: 1, color: Colors.grey[200]),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.qr_code_2_rounded, size: 16, color: AppColors.royalBlue),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'AR Navigation',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.royalBlueDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Scan with your phone to open AR wayfinding',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: Colors.grey[500],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.06),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: QrImageView(
                            data: '${dotenv.env['AR_NAV_BASE_URL'] ?? 'https://yourdomain.com/ar_navigation.html'}?dest=${_buildingQrKeys[title]}',
                            version: QrVersions.auto,
                            size: 130,
                            backgroundColor: Colors.white,
                            eyeStyle: const QrEyeStyle(
                              eyeShape: QrEyeShape.square,
                              color: AppColors.royalBlue,
                            ),
                            dataModuleStyle: const QrDataModuleStyle(
                              dataModuleShape: QrDataModuleShape.square,
                              color: Color(0xFF1a1a2e),
                            ),
                            padding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          '${dotenv.env['AR_NAV_BASE_URL'] ?? 'ar_navigation.html'}?dest=${_buildingQrKeys[title]}',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 9.5,
                            color: Colors.grey[400],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigateButton(String title) {
    return GestureDetector(
      onTap: _startNavigation,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.royalBlue, AppColors.royalBlueLight],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.royalBlue.withValues(alpha: 0.35),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.directions_rounded, size: 22, color: Colors.white),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'Navigate to $title',
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.navigate_next_rounded, size: 24, color: Colors.white),
          ],
        ),
      ),
    );
  }

  Widget _buildPlacePanelImage(Building? building, OfficeEntry? office) {
    final url = building?.imageUrl ?? office?.imageUrl;
    return Stack(
      children: [
        SizedBox(
          height: 140,
          width: double.infinity,
          child: (url != null && url.isNotEmpty)
              ? _buildPlaceImage(url)
              : _buildPlaceImageFallback(),
        ),
        Positioned(
          top: 10,
          right: 10,
          child: GestureDetector(
            onTap: _clearRoute,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.45),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close_rounded, size: 18, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceImage(String url) {
    if (url.startsWith('assets/')) {
      return Image.asset(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildPlaceImageFallback(),
      );
    }
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _buildPlaceImageFallback(),
    );
  }

  Widget _buildPlaceImageFallback() {
    return Image.asset(
      'assets/campus_building.png',
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: AppColors.royalBlue.withValues(alpha: 0.08),
        alignment: Alignment.center,
        child: const Icon(Icons.account_balance_rounded, size: 48, color: AppColors.royalBlue),
      ),
    );
  }

  Widget _buildSearchSuggestions() {
    final suggestions = [
      ('Administration Building', Icons.business_rounded),
      ('CICS Building', Icons.computer_rounded),
      ('Library Building', Icons.menu_book_rounded),
      ('Canteen', Icons.restaurant_rounded),
      ('Gymnasium', Icons.sports_basketball_rounded),
      ('University Clinic', Icons.local_hospital_rounded),
      ('Registrar', Icons.apartment_rounded),
      ('Bookstore', Icons.store_rounded),
    ];
    return ListView(
      padding: const EdgeInsets.all(8),
      shrinkWrap: true,
      children: suggestions.map((s) {
        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => _selectBuilding(s.$1),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.royalBlue.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(s.$2, size: 16, color: AppColors.royalBlue),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      s.$1,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.royalBlueDark,
                      ),
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.grey[300]),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSearchResults() {
    final results = _mapSearchResults(_mapSearchController.text);
    if (results.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          'No results found',
          style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[400]),
        ),
      );
    }
    return Flexible(
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        shrinkWrap: true,
        itemCount: results.length,
        itemBuilder: (context, index) {
          final r = results[index];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
            child: Material(
              color: AppColors.royalBlue.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => _selectBuilding(r['name']!),
              child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Icon(
                    r['type'] == 'Building' ? Icons.business_rounded : Icons.apartment_rounded,
                    size: 18,
                    color: AppColors.royalBlue,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          r['name']!,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.royalBlueDark,
                          ),
                        ),
                        if (r['detail']!.isNotEmpty)
                          Text(
                            r['detail']!,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: Colors.grey[500],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMapPlaceholder() {
    return Container(
      margin: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.royalBlue.withValues(alpha: 0.1),
            blurRadius: 20,
          ),
        ],
      ),
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.royalBlue.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.map_rounded,
              size: 64,
              color: AppColors.royalBlue,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'CSU-A Aparri Campus Map',
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.royalBlue,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add campus_map.png to the assets folder',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.gold.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Setup Instructions',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    color: AppColors.royalBlueDark,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '1. Place image in assets/campus_map.png\n'
                  '2. Add to pubspec.yaml under flutter > assets\n'
                  '3. Run: flutter pub get',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.royalBlueDark,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildZoomControls(BuildContext context) {
    return Positioned(
      left: 20,
      bottom: 20,
      child: Column(
        children: [
          _buildCircleButton(
            icon: Icons.add_rounded,
            onTap: _zoomIn,
          ),
          const SizedBox(height: 8),
          _buildCircleButton(
            icon: Icons.remove_rounded,
            onTap: _zoomOut,
          ),
          const SizedBox(height: 8),
          _buildCircleButton(
            icon: Icons.my_location_rounded,
            onTap: _resetMap,
          ),
        ],
      ),
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.95),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, size: 20, color: AppColors.royalBlue),
      ),
    );
  }

  Widget _buildChatbotButton(BuildContext context) {
    return Positioned(
      right: 20,
      bottom: 20,
      child: GestureDetector(
        onTap: () => setState(() {
          showChatBot = !showChatBot;
          if (!showChatBot && _keyboardTarget == _KeyboardTarget.chat) {
            _keyboardTarget = _KeyboardTarget.none;
          }
        }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.royalBlue, AppColors.royalBlueLight],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.royalBlue.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                showChatBot ? Icons.close_rounded : Icons.psychology_rounded,
                size: 20,
                color: Colors.white,
              ),
              const SizedBox(width: 8),
              Text(
                showChatBot ? 'Close' : 'AI Assistant',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChatbotPanel(BuildContext context) {
    final showKeyboardHere = _keyboardTarget == _KeyboardTarget.chat;
    final screenSize = MediaQuery.of(context).size;
    return Align(
      alignment: const Alignment(0, -0.1),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: screenSize.width * 0.75,
            height: screenSize.height * 0.50,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.royalBlue.withValues(alpha: 0.25),
                  blurRadius: 32,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                _buildChatHeader(),
                Expanded(child: _buildChatMessages()),
                if (isLoading) _buildTypingIndicator(),
                _buildChatInput(),
              ],
            ),
          ),
          if (showKeyboardHere) ...[
            const SizedBox(height: 12),
            _buildOnScreenKeyboard(
              context,
              _messageController,
              onSubmit: _sendMessage,
              width: screenSize.width * 0.75,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOnScreenKeyboard(
    BuildContext context,
    TextEditingController controller, {
    required VoidCallback onSubmit,
    double? width,
  }) {
    final keyboardWidth = width ??
        (MediaQuery.of(context).size.width * 0.5).clamp(420.0, 760.0);
    return SizedBox(
      width: keyboardWidth,
      child: OnScreenKeyboard(
        controller: controller,
        onSubmit: onSubmit,
        onClose: () => setState(() => _keyboardTarget = _KeyboardTarget.none),
      ),
    );
  }

  Widget _buildKeyboardOverlay(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _buildOnScreenKeyboard(
          context,
          _mapSearchController,
          onSubmit: () => setState(() {}),
        ),
      ),
    );
  }

  Widget _buildChatHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.gold, AppColors.goldLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: AppColors.royalBlue.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.psychology_rounded,
              size: 18,
              color: AppColors.royalBlueDark,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CSU-A Navigation',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: AppColors.royalBlueDark,
                  ),
                ),
                Text(
                  'Assistant Bot',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.royalBlueDark.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => setState(() {
              showChatBot = false;
              if (_keyboardTarget == _KeyboardTarget.chat) {
                _keyboardTarget = _KeyboardTarget.none;
              }
            }),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.royalBlueDark.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close_rounded,
                size: 16,
                color: AppColors.royalBlueDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatMessages() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(12),
      itemCount: chatConversation.length,
      itemBuilder: (context, index) {
        final chat = chatConversation[index];
        final isBot = chat['sender'] == 'bot';
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment:
                isBot ? MainAxisAlignment.start : MainAxisAlignment.end,
            children: [
              if (isBot)
                Container(
                  margin: const EdgeInsets.only(right: 8, top: 2),
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: AppColors.royalBlue.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.smart_toy_rounded,
                    size: 14,
                    color: AppColors.royalBlue,
                  ),
                ),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isBot
                        ? const Color(0xFFF0F3F8)
                        : AppColors.royalBlue,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(12),
                      topRight: const Radius.circular(12),
                      bottomLeft: Radius.circular(isBot ? 12 : 4),
                      bottomRight: Radius.circular(isBot ? 4 : 12),
                    ),
                  ),
                  child: Text(
                    chat['message'] ?? '',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      height: 1.4,
                      color: isBot ? Colors.grey[800] : Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                AppColors.royalBlue.withValues(alpha: 0.6),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Thinking...',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: Colors.grey[400],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatInput() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFB),
        border: Border(
          top: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              enabled: !isLoading,
              maxLines: 1,
              onTap: () => setState(() => _keyboardTarget = _KeyboardTarget.chat),
              style: GoogleFonts.inter(fontSize: 12),
              decoration: InputDecoration(
                hintText: 'Ask about campus locations...',
                hintStyle: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.grey[400],
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(color: AppColors.royalBlue),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: isLoading ? null : _sendMessage,
            child: Container(
              padding: const EdgeInsets.all(9),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.gold, AppColors.goldLight],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.send_rounded,
                size: 16,
                color: AppColors.royalBlueDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.shade200),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(6, Icons.home_rounded, 'Home', onTap: () {
            Navigator.of(context).popUntil((route) => route.isFirst);
          }),
          _buildNavItem(1, Icons.map_rounded, 'Map', selected: true),
          _buildNavItem(2, Icons.menu_rounded, 'Directory', onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const DirectoryScreen()),
            );
          }),
          _buildNavItem(4, Icons.groups_rounded, 'Campus Info', onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CampusInfoScreen()),
            );
          }),
          _buildNavItem(5, Icons.info_rounded, 'About', onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AboutScreen()),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData icon,
    String label, {
    bool selected = false,
    VoidCallback? onTap,
  }) {
    return _KioskNavItem(
      icon: icon,
      label: label,
      selected: selected,
      onTap: onTap,
    );
  }
}

class _KioskNavItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const _KioskNavItem({
    required this.icon,
    required this.label,
    this.selected = false,
    this.onTap,
  });

  @override
  State<_KioskNavItem> createState() => _KioskNavItemState();
}

class _KioskNavItemState extends State<_KioskNavItem> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.selected;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() {
        _hovered = false;
        _pressed = false;
      }),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: widget.onTap == null ? null : (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          scale: _pressed ? 0.92 : 1.0,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            decoration: BoxDecoration(
              color: active
                  ? AppColors.royalBlue.withValues(alpha: 0.12)
                  : _hovered
                      ? AppColors.royalBlue.withValues(alpha: 0.06)
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedScale(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutBack,
                  scale: active ? 1.15 : (_hovered ? 1.08 : 1.0),
                  child: Icon(
                    widget.icon,
                    size: 24,
                    color: active
                        ? AppColors.royalBlue
                        : _hovered
                            ? AppColors.royalBlueDark
                            : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    color: active
                        ? AppColors.royalBlue
                        : _hovered
                            ? AppColors.royalBlueDark
                            : Colors.grey[700]!,
                  ),
                  child: Text(widget.label),
                ),
                const SizedBox(height: 5),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  width: active ? 20 : (_hovered ? 8 : 0),
                  height: 3,
                  decoration: BoxDecoration(
                    color: active
                        ? AppColors.royalBlue
                        : AppColors.royalBlue.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
