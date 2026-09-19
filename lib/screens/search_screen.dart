import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/campus_models.dart';
import '../services/campus_repository.dart';
import '../theme/app_colors.dart';
import '../widgets/kiosk_back_button.dart';
import '../widgets/on_screen_keyboard.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late TextEditingController _searchController;
  late ScrollController _scrollController;
  String _query = '';
  bool _showKeyboard = false;
  late DateTime _currentTime;
  late Timer _timer;
  final CampusRepository _repository = CampusRepository();
  bool _isLoadingData = true;
  List<Building> _buildings = [];
  List<OfficeEntry> _offices = [];
  List<LeadershipMember> _leadership = [];
  List<CollegeFacultyGroup> _collegeFaculty = [];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _scrollController = ScrollController();
    _currentTime = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _currentTime = DateTime.now());
    });
    _loadData();
  }

  Future<void> _loadData() async {
    final results = await Future.wait([
      _repository.getBuildings(),
      _repository.getOfficeEntries(),
      _repository.getLeadership(),
      _repository.getCollegeFacultyGroups(),
    ]);
    if (!mounted) return;
    setState(() {
      _buildings = results[0] as List<Building>;
      _offices = results[1] as List<OfficeEntry>;
      _leadership = results[2] as List<LeadershipMember>;
      _collegeFaculty = results[3] as List<CollegeFacultyGroup>;
      _isLoadingData = false;
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String _formattedTime(DateTime dt) {
    final h = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final m = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $ampm';
  }

  String _formattedDate(DateTime dt) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  List<Map<String, String>> _searchResults() {
    if (_query.isEmpty) return [];
    final q = _query.toLowerCase();
    final results = <Map<String, String>>[];

    for (final b in _buildings) {
      if (b.name.toLowerCase().contains(q) ||
          (b.description ?? '').toLowerCase().contains(q) ||
          (b.offices ?? '').toLowerCase().contains(q)) {
        results.add({
          'type': 'Building',
          'name': b.name,
          'detail': b.description ?? '',
          'location': b.location ?? '',
        });
      }
    }
    for (final o in _offices) {
      if (o.name.toLowerCase().contains(q) ||
          (o.abbreviation ?? '').toLowerCase().contains(q) ||
          (o.purpose ?? '').toLowerCase().contains(q)) {
        results.add({
          'type': 'Office',
          'name': o.name,
          'detail': o.purpose ?? '',
          'location': o.location ?? '',
        });
      }
    }
    for (final c in _leadership) {
      if (c.name.toLowerCase().contains(q) ||
          (c.department ?? '').toLowerCase().contains(q) ||
          (c.position ?? '').toLowerCase().contains(q)) {
        results.add({
          'type': 'Faculty',
          'name': c.name,
          'detail': '${c.position} — ${c.department}',
          'location': '',
        });
      }
    }
    for (final f in _collegeFaculty) {
      if (f.college.toLowerCase().contains(q) ||
          (f.faculty ?? '').toLowerCase().contains(q)) {
        results.add({
          'type': 'Faculty',
          'name': f.college,
          'detail': f.faculty ?? '',
          'location': '',
        });
      }
    }
    return results;
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'Building':
        return Icons.business_rounded;
      case 'Office':
        return Icons.apartment_rounded;
      case 'Faculty':
        return Icons.person_rounded;
      default:
        return Icons.search_rounded;
    }
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'Building':
        return AppColors.royalBlue;
      case 'Office':
        return AppColors.royalBlueLight;
      case 'Faculty':
        return AppColors.royalBlueDark;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final results = _searchResults();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: Stack(
              children: [
                SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBackButton(context),
                      const SizedBox(height: 16),
                      _buildTitleSection(),
                      const SizedBox(height: 24),
                      _buildSearchBar(),
                      const SizedBox(height: 24),
                      if (_isLoadingData)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else ...[
                        if (_query.isEmpty) _buildRecentSuggestions(),
                        if (_query.isNotEmpty && results.isEmpty)
                          _buildNoResults(),
                        if (results.isNotEmpty) _buildResults(results),
                      ],
                      if (_showKeyboard) const SizedBox(height: 260),
                    ],
                  ),
                ),
                if (_showKeyboard)
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: SizedBox(
                        width: (MediaQuery.of(context).size.width * 0.5)
                            .clamp(420.0, 760.0),
                        child: OnScreenKeyboard(
                          controller: _searchController,
                          onSubmit: () =>
                              setState(() => _showKeyboard = false),
                          onClose: () =>
                              setState(() => _showKeyboard = false),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
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
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.account_balance_rounded,
              size: 28,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cagayan State University',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Aparri Campus',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withValues(alpha: 0.7),
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.access_time_rounded,
                  size: 16,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
                const SizedBox(width: 8),
                Text(
                  _formattedTime(_currentTime),
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 1,
                  height: 16,
                  color: Colors.white.withValues(alpha: 0.3),
                ),
                const SizedBox(width: 12),
                Icon(
                  Icons.calendar_today_rounded,
                  size: 14,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
                const SizedBox(width: 8),
                Text(
                  _formattedDate(_currentTime),
                  style: GoogleFonts.inter(
                    fontSize: 13,
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

  Widget _buildBackButton(BuildContext context) {
    return const KioskBackButton();
  }

  Widget _buildTitleSection() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.gold.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'SEARCH CAMPUS',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.gold,
              letterSpacing: 3,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Find Anything on Campus',
          style: GoogleFonts.poppins(
            color: AppColors.royalBlue,
            fontWeight: FontWeight.w800,
            fontSize: 38,
            height: 1.1,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Search buildings, offices, services, and faculty',
          style: GoogleFonts.inter(
            color: Colors.grey[500],
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.royalBlue.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        autofocus: true,
        onTap: () => setState(() => _showKeyboard = true),
        onChanged: (val) => setState(() => _query = val),
        style: GoogleFonts.inter(fontSize: 16),
        decoration: InputDecoration(
          hintText: 'Search buildings, offices, services, faculty...',
          hintStyle: GoogleFonts.inter(
            fontSize: 16,
            color: Colors.grey[400],
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            size: 24,
            color: AppColors.royalBlue,
          ),
          suffixIcon: _query.isNotEmpty
              ? GestureDetector(
                  onTap: () {
                    _searchController.clear();
                    setState(() => _query = '');
                  },
                  child: const Icon(
                    Icons.close_rounded,
                    size: 20,
                    color: Colors.grey,
                  ),
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildRecentSuggestions() {
    final suggestions = [
      ('Administration Building', Icons.business_rounded),
      ('CICS Building', Icons.business_rounded),
      ('Registrar', Icons.apartment_rounded),
      ('Library', Icons.menu_book_rounded),
      ('Enrollment', Icons.how_to_reg_rounded),
      ('Grades', Icons.grade_rounded),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Popular Searches',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.royalBlue,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: suggestions.map((s) {
            return GestureDetector(
              onTap: () {
                _searchController.text = s.$1;
                setState(() => _query = s.$1);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.royalBlue.withValues(alpha: 0.12),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(s.$2, size: 18, color: AppColors.royalBlue),
                    const SizedBox(width: 8),
                    Text(
                      s.$1,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.royalBlueDark,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildNoResults() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 64,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              'No results found',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Try searching for a building, office, or service',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey[400],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResults(List<Map<String, String>> results) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${results.length} result${results.length == 1 ? '' : 's'} found',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[500],
          ),
        ),
        const SizedBox(height: 16),
        ...results.map((r) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildResultCard(r),
            )),
      ],
    );
  }

  Widget _buildResultCard(Map<String, String> result) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _typeColor(result['type']!).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _typeIcon(result['type']!),
              size: 22,
              color: _typeColor(result['type']!),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        result['name']!,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.royalBlueDark,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _typeColor(result['type']!)
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        result['type']!,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _typeColor(result['type']!),
                        ),
                      ),
                    ),
                  ],
                ),
                if (result['detail']!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    result['detail']!,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.grey[600],
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (result['location']!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_rounded,
                        size: 14,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        result['location']!,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
