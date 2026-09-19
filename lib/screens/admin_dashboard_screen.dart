import 'dart:async';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_colors.dart';
import '../models/campus_models.dart';
import '../services/admin_auth.dart';
import '../services/campus_repository.dart';
import '../services/notification_service.dart';
import '../services/pending_change_service.dart';
import 'admin/approvals_admin_screen.dart';
import 'admin/buildings_admin_screen.dart';
import 'admin/faculty_admin_screen.dart';
import 'admin/leadership_admin_screen.dart';
import 'admin/offices_admin_screen.dart';
import 'admin/colleges_admin_screen.dart';
import 'admin/about_admin_screen.dart';
import 'welcome_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  final AdminUser user;

  const AdminDashboardScreen({super.key, required this.user});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _DashboardPage {
  final IconData icon;
  final String label;
  final Widget Function(BuildContext context, bool isWide) builder;

  const _DashboardPage(this.icon, this.label, this.builder);
}

class _DashboardStats {
  final int buildings;
  final int offices;
  final int colleges;
  final int totalFaculty;

  _DashboardStats({
    required this.buildings,
    required this.offices,
    required this.colleges,
    required this.totalFaculty,
  });
}

class _SummaryCategory {
  final String label;
  final int value;
  final Color color;
  final IconData icon;

  const _SummaryCategory(this.label, this.value, this.color, this.icon);
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  late final List<_DashboardPage> _pages;

  final CampusRepository _repository = CampusRepository();
  late Future<_DashboardStats> _statsFuture;
  int _touchedSegment = -1;
  int _selected = 0;
  int _pendingCount = 0;
  Timer? _pendingTimer;
  int _unreadCount = 0;
  Timer? _notificationTimer;
  bool _notificationsOpen = false;

  @override
  void initState() {
    super.initState();
    _statsFuture = _loadStats();
    if (widget.user.isSuperAdmin) {
      _refreshPendingCount();
      _pendingTimer = Timer.periodic(
        const Duration(seconds: 30),
        (_) => _refreshPendingCount(),
      );
    } else {
      _refreshUnreadCount();
      _notificationTimer = Timer.periodic(
        const Duration(seconds: 30),
        (_) => _refreshUnreadCount(),
      );
    }
    final role = widget.user.role;
    _pages = [
      _DashboardPage(
        Icons.dashboard_rounded,
        'Dashboard',
        (_, isWide) => _buildHomePage(isWide),
      ),
      if (adminCanAccess(role, 'buildings'))
        _DashboardPage(Icons.business_rounded, 'Buildings', (_, isWide) =>
            BuildingsAdminScreen(showBackButton: false, user: widget.user)),
      if (adminCanAccess(role, 'faculty'))
        _DashboardPage(Icons.school_rounded, 'Faculty', (_, isWide) =>
            FacultyAdminScreen(showBackButton: false, user: widget.user)),
      if (adminCanAccess(role, 'colleges'))
        _DashboardPage(Icons.account_balance_rounded, 'Colleges', (_, isWide) =>
            CollegesAdminScreen(showBackButton: false, user: widget.user)),
      if (adminCanAccess(role, 'offices'))
        _DashboardPage(Icons.apartment_rounded, 'Offices', (_, isWide) =>
            OfficesAdminScreen(showBackButton: false, user: widget.user)),
      if (adminCanAccess(role, 'leadership'))
        _DashboardPage(Icons.workspace_premium_rounded, 'Leadership', (_, isWide) =>
            LeadershipAdminScreen(showBackButton: false, user: widget.user)),
      if (adminCanAccess(role, 'approvals'))
        _DashboardPage(Icons.verified_user_rounded, 'Approvals', (_, isWide) =>
            ApprovalsAdminScreen(showBackButton: false, user: widget.user)),
      _DashboardPage(
        Icons.info_rounded,
        'About',
        (_, isWide) => const AdminAboutScreen(showBackButton: false),
      ),
    ];
  }

  Future<_DashboardStats> _loadStats() async {
    final results = await Future.wait([
      _repository.getBuildings(),
      _repository.getOfficeEntries(),
      _repository.getColleges(),
      _repository.getFaculty(),
    ]);
    return _DashboardStats(
      buildings: (results[0] as List).length,
      offices: (results[1] as List).length,
      colleges: (results[2] as List).length,
      totalFaculty: (results[3] as List).length,
    );
  }

@override
  void dispose() {
    _pendingTimer?.cancel();
    _notificationTimer?.cancel();
    super.dispose();
  }

  Future<void> _refreshPendingCount() async {
    try {
      final count = await PendingChangeService().countPending();
      if (mounted && count != _pendingCount) {
        setState(() => _pendingCount = count);
      }
    } catch (_) {}
  }

  Future<void> _refreshUnreadCount() async {
    try {
      final count = await NotificationService().unreadCount(widget.user.email);
      if (mounted && count != _unreadCount) {
        setState(() => _unreadCount = count);
      }
    } catch (_) {}
  }

  Future<void> _openNotifications() async {
    if (!_notificationsOpen) {
      _notificationsOpen = true;
      try {
        final items = await NotificationService().getForUser(widget.user.email);
        await NotificationService().markAllRead(widget.user.email);
        if (!mounted) return;
        setState(() => _unreadCount = 0);
        await showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => _NotificationsSheet(
            items: items,
            userEmail: widget.user.email,
          ),
        );
      } catch (_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: const Text('Could not load notifications.'),
              backgroundColor: Colors.red.shade700,
            ),
          );
      } finally {
        _notificationsOpen = false;
      }
    }
  }

  void _onSelect(int index) {
    if (index == _selected) return;
    setState(() {
      if (index == 0 && _selected != 0) {
        _statsFuture = _loadStats();
      }
      _selected = index;
    });
    if (widget.user.isSuperAdmin) _refreshPendingCount();
  }

  void _openModule(int index) {
    if (index == _selected) return;
    setState(() {
      _selected = index;
    });
  }

  Future<void> _logout() async {
    await Supabase.instance.client.auth.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
_AdminSidebar(
                  items: _pages,
                  selectedIndex: _selected,
                  onSelect: _onSelect,
                  onLogout: _logout,
                  pendingCount: _pendingCount,
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 280),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeIn,
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.02, 0),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: KeyedSubtree(
                      key: ValueKey(_selected),
                      child: _buildPage(_selected, isWide),
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

Widget _buildPage(int index, bool isWide) {
    return _pages[index].builder(context, isWide);
  }

  Widget _buildHomePage(bool isWide) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? 40 : 24,
        vertical: 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
_buildTitleSection(),
          const SizedBox(height: 32),
          FutureBuilder<_DashboardStats>(
            future: _statsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final stats = snapshot.data;
              if (stats == null) return const SizedBox();
              return _buildStatsRow(isWide, stats);
            },
          ),
          const SizedBox(height: 32),
          _buildSectionTitle('Campus Data Summary'),
          const SizedBox(height: 18),
          FutureBuilder<_DashboardStats>(
            future: _statsFuture,
            builder: (context, snapshot) {
              final stats = snapshot.data;
              if (stats == null) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              return _buildDataSummary(isWide, stats);
            },
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.royalBlueDark, Color(0xFF001A3D)],
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
              color: AppColors.gold.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.admin_panel_settings_rounded,
              size: 28,
              color: AppColors.gold,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CSU-A Admin Panel',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Kiosk Management System',
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
          if (screenWidth > 1050) ...[
            const _LiveClock(),
            const SizedBox(width: 16),
          ],
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.gold.withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.shield_rounded,
                  size: 16,
                  color: AppColors.gold.withValues(alpha: 0.9),
                ),
                const SizedBox(width: 8),
                Text(
                  widget.user.roleLabel,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          if (!widget.user.isSuperAdmin) ...[
            GestureDetector(
              onTap: _openNotifications,
              child: Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(
                      Icons.notifications_rounded,
                      size: 22,
                      color: _unreadCount > 0
                          ? AppColors.gold
                          : Colors.white70,
                    ),
                    if (_unreadCount > 0)
                      Positioned(
                        right: -7,
                        top: -7,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.red.shade600,
                            borderRadius: BorderRadius.circular(99),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Text(
                            _unreadCount > 99 ? '99+' : '$_unreadCount',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          ClipOval(
            child: Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              color: Colors.white.withValues(alpha: 0.15),
              child: Text(
                widget.user.initials,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
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
            'ADMIN PANEL',
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
          'Dashboard',
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
          'Manage kiosk data and settings',
          style: GoogleFonts.inter(
            color: Colors.grey[500],
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

List<_SummaryCategory> _summaryCategories(_DashboardStats data) {
    return [
      _SummaryCategory('Buildings', data.buildings, const Color(0xFF003D82),
          Icons.business_rounded),
      _SummaryCategory('Offices', data.offices, const Color(0xFF1A5FAF),
          Icons.apartment_rounded),
      _SummaryCategory('Colleges', data.colleges, const Color(0xFF3949AB),
          Icons.school_rounded),
      _SummaryCategory('Faculty', data.totalFaculty, const Color(0xFF9C27B0),
          Icons.person_rounded),
    ];
  }

  int? _pageIndexOf(String label) {
    final i = _pages.indexWhere((p) => p.label == label);
    return i < 0 ? null : i;
  }

Widget _buildStatsRow(bool isWide, _DashboardStats data) {
    final cats = _summaryCategories(data);
    final total = cats.fold<int>(0, (sum, c) => sum + c.value);
    final stats = [
      {
        'icon': Icons.business_rounded,
        'label': 'Buildings',
        'value': data.buildings.toString(),
        'color': AppColors.royalBlue,
        'share': total == 0 ? 0.0 : data.buildings / total,
        'pageIndex': _pageIndexOf('Buildings'),
      },
      {
        'icon': Icons.apartment_rounded,
        'label': 'Offices',
        'value': data.offices.toString(),
        'color': AppColors.royalBlueLight,
        'share': total == 0 ? 0.0 : data.offices / total,
        'pageIndex': _pageIndexOf('Offices'),
      },
      {
        'icon': Icons.school_rounded,
        'label': 'Faculty',
        'value': data.totalFaculty.toString(),
        'color': const Color(0xFF9C27B0),
        'share': total == 0 ? 0.0 : data.totalFaculty / total,
        'pageIndex': _pageIndexOf('Faculty'),
      },
    ];

    if (isWide) {
      return Row(
        children: stats.map((s) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: _buildStatCard(s),
            ),
          );
        }).toList(),
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildStatCard(stats[0])),
            const SizedBox(width: 16),
            Expanded(child: _buildStatCard(stats[1])),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildStatCard(stats[2])),
          ],
        ),
      ],
    );
  }

Widget _buildStatCard(Map<String, dynamic> stat) {
    final color = stat['color'] as Color;
    final share = (stat['share'] as double).clamp(0.0, 1.0);
    final pageIndex = stat['pageIndex'] as int?;
    final tappable = pageIndex != null;

    Widget card = Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color.withValues(alpha: 0.14), color.withValues(alpha: 0.06)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(stat['icon'] as IconData, size: 26, color: color),
              ),
              const Spacer(),
              if (tappable)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.arrow_forward_rounded,
                          size: 13, color: color),
                      const SizedBox(width: 4),
                      Text(
                        'Open',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${(share * 100).toStringAsFixed(share * 100 >= 9.95 || share * 100 < 1 ? 0 : 1)}%',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            stat['value'] as String,
            style: GoogleFonts.poppins(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              height: 1,
              color: AppColors.royalBlueDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            stat['label'] as String,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: share),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) {
                return FractionallySizedBox(
                  widthFactor: value,
                  alignment: Alignment.centerLeft,
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [color, Color.lerp(color, Colors.white, 0.35)!],
                      ),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );

    if (!tappable) return card;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _openModule(pageIndex),
        child: card,
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 28,
          decoration: BoxDecoration(
            color: AppColors.secondary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppColors.royalBlue,
          ),
        ),
      ],
    );
  }

  Widget _buildDataSummary(bool isWide, _DashboardStats data) {
    final cats = _summaryCategories(data);
    final distributionCard = _buildDistributionCard(cats);
    final breakdownCard = _buildBreakdownCard(cats);

    if (isWide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 5, child: distributionCard),
          const SizedBox(width: 16),
          Expanded(flex: 4, child: breakdownCard),
        ],
      );
    }

    return Column(
      children: [
        distributionCard,
        const SizedBox(height: 16),
        breakdownCard,
      ],
    );
  }

  Widget _summaryCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _cardHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.royalBlueDark,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: GoogleFonts.inter(
            fontSize: 12.5,
            fontWeight: FontWeight.w400,
            color: Colors.grey[500],
          ),
        ),
      ],
    );
  }

  Widget _buildDistributionCard(List<_SummaryCategory> cats) {
    final visible = cats.where((c) => c.value > 0).toList();
    final total = visible.fold<int>(0, (sum, c) => sum + c.value);
    final touched =
        _touchedSegment >= 0 && _touchedSegment < visible.length
            ? visible[_touchedSegment]
            : null;

    return _summaryCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader('Records Overview', 'Share of all kiosk content'),
          const SizedBox(height: 12),
          SizedBox(
            height: 240,
            child: total == 0
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.donut_large_rounded,
                            size: 44, color: Colors.grey[300]),
                        const SizedBox(height: 10),
                        Text(
                          'No records yet',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  )
                : Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        PieChartData(
                          sectionsSpace: 3,
                          centerSpaceRadius: 62,
                          startDegreeOffset: -90,
pieTouchData: PieTouchData(
                            touchCallback: (event, response) {
                              if (!mounted) return;
                              if (!event.isInterestedForInteractions ||
                                  response?.touchedSection == null) {
                                if (event is FlPointerExitEvent ||
                                    event is FlTapCancelEvent ||
                                    _touchedSegment != -1) {
                                  setState(() => _touchedSegment = -1);
                                }
                                return;
                              }
                              final index =
                                  response?.touchedSection?.touchedSectionIndex;
                              if (index == null ||
                                  index < 0 ||
                                  index >= visible.length) {
                                if (_touchedSegment != -1) {
                                  setState(() => _touchedSegment = -1);
                                }
                                return;
                              }
                              if (_touchedSegment != index) {
                                setState(() => _touchedSegment = index);
                              }
                            },
                          ),
                          sections: [
                            for (int i = 0; i < visible.length; i++)
                              () {
                                final c = visible[i];
                                final isTouched = i == _touchedSegment;
                                final pct = c.value / total;
                                return PieChartSectionData(
                                  value: c.value.toDouble(),
                                  color: c.color,
                                  radius: isTouched ? 66 : 56,
                                  showTitle: pct >= 0.06,
                                  title:
                                      '${(pct * 100).round()}%',
                                  titleStyle: GoogleFonts.inter(
                                    fontSize: isTouched ? 15 : 13,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    shadows: const [
                                      Shadow(color: Colors.black26, blurRadius: 3),
                                    ],
                                  ),
                                );
                              }(),
                          ],
                        ),
                      ),
IgnorePointer(
                        child: Column(
                          key: ValueKey('seg$_touchedSegment'),
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (touched != null) ...[
                              Text(
                                touched.value.toString(),
                                style: GoogleFonts.poppins(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w800,
                                  color: touched.color,
                                  height: 1,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                touched.label,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.royalBlueDark,
                                ),
                              ),
                              Text(
                                '${((touched.value / total) * 100).toStringAsFixed(1)}% of total',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ] else ...[
                              Text(
                                total.toString(),
                                style: GoogleFonts.poppins(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.royalBlueDark,
                                  height: 1,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Total Records',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final c in visible)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: c.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        c.label,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.royalBlueDark,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        c.value.toString(),
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: c.color,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownCard(List<_SummaryCategory> cats) {
    final sorted = List<_SummaryCategory>.from(cats)
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxV = sorted.isEmpty ? 0 : sorted.first.value;

    return _summaryCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader('Category Breakdown', 'Record count per category'),
          const SizedBox(height: 20),
          if (maxV == 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Text(
                  'No data available',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[400],
                  ),
                ),
              ),
            )
          else
            for (int i = 0; i < sorted.length; i++) ...[
              if (i > 0) const SizedBox(height: 14),
              Row(
                children: [
                  SizedBox(
                    width: 86,
                    child: Row(
                      children: [
                        Icon(sorted[i].icon,
                            size: 15, color: sorted[i].color),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            sorted[i].label,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.royalBlueDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(
                        begin: 0,
                        end: sorted[i].value / maxV,
                      ),
                      duration: Duration(milliseconds: 700 + i * 90),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, _) {
                        return Align(
                          alignment: Alignment.centerLeft,
                          child: FractionallySizedBox(
                            widthFactor: value.clamp(0.02, 1.0),
                            child: Container(
                              height: 22,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    sorted[i].color,
                                    Color.lerp(
                                        sorted[i].color, Colors.white, 0.35)!,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(7),
                              ),
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 8),
                              child: value > 0.25
                                  ? Text(
                                      '${((sorted[i].value / maxV) * 100).round()}%',
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 42,
                    child: Text(
                      sorted[i].value.toString(),
                      textAlign: TextAlign.right,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: sorted[i].color,
                      ),
                    ),
                  ),
                ],
              ),
            ],
        ],
      ),
    );
  }
}

class _NotificationsSheet extends StatefulWidget {
  final List<NotificationItem> items;
  final String userEmail;

  const _NotificationsSheet({
    required this.items,
    required this.userEmail,
  });

  @override
  State<_NotificationsSheet> createState() => _NotificationsSheetState();
}

class _NotificationsSheetState extends State<_NotificationsSheet> {
  late List<NotificationItem> _items;
  bool _deleting = false;

  @override
  void initState() {
    super.initState();
    _items = List.of(widget.items);
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return '';
    final local = dt.toLocal();
    final h =
        local.hour > 12 ? local.hour - 12 : (local.hour == 0 ? 12 : local.hour);
    final m = local.minute.toString().padLeft(2, '0');
    final ampm = local.hour >= 12 ? 'PM' : 'AM';
    final date =
        '${local.month.toString().padLeft(2, '0')}/${local.day.toString().padLeft(2, '0')}/${local.year}';
    return '$date · $h:$m $ampm';
  }

  Future<void> _deleteItem(int index) async {
    if (_deleting || index < 0 || index >= _items.length) return;
    final item = _items[index];
    setState(() => _deleting = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await NotificationService().delete(item.id);
      if (!mounted) return;
      setState(() => _items.removeAt(index));
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: const Text('Notification deleted'),
            backgroundColor: Colors.grey.shade800,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
    } catch (_) {
      if (!mounted) return;
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: const Text('Could not delete notification.'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  Future<void> _clearAll() async {
    if (_deleting || _items.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Clear notifications?'),
        content: Text(
          'Delete all ${_items.length} notification${_items.length == 1 ? '' : 's'}?',
          style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[600]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel', style: GoogleFonts.inter(color: Colors.grey[600])),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Clear all', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _deleting = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await NotificationService().clearAll(widget.userEmail);
      if (!mounted) return;
      setState(() => _items.clear());
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: const Text('All notifications cleared'),
            backgroundColor: Colors.grey.shade800,
            behavior: SnackBarBehavior.floating,
          ),
        );
    } catch (_) {
      if (!mounted) return;
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: const Text('Could not clear notifications.'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return Container(
      height: screenHeight * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 14, 12, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.notifications_rounded,
                    size: 20,
                    color: AppColors.gold,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Notifications',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.royalBlueDark,
                    ),
                  ),
                ),
                if (_items.isNotEmpty)
                  TextButton.icon(
                    onPressed: _deleting ? null : _clearAll,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red.shade400,
                    ),
                    icon: const Icon(Icons.delete_sweep_rounded, size: 18),
                    label: Text(
                      'Clear all',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close_rounded, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade200),
          Expanded(
            child: _items.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.notifications_none_rounded,
                          size: 52,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No notifications yet',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                        Text(
                          'Updates on your submitted changes will show here.',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _items.length,
                    separatorBuilder: (_, __) =>
                        Divider(height: 1, color: Colors.grey.shade100),
                    itemBuilder: (context, i) {
                      final item = _items[i];
                      final approved = item.type == 'approved';
                      final Color color =
                          approved ? Colors.green.shade700 : Colors.red;
                      return Container(
                        color:
                            item.read ? Colors.transparent : color.withValues(alpha: 0.04),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(9),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                approved
                                    ? Icons.check_circle_rounded
                                    : Icons.cancel_rounded,
                                size: 19,
                                color: color,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          item.title,
                                          style: GoogleFonts.inter(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.royalBlueDark,
                                          ),
                                        ),
                                      ),
                                      if (!item.read)
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: color,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    item.message,
                                    style: GoogleFonts.inter(
                                      fontSize: 12.5,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatTime(item.createdAt),
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: Colors.grey[400],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: _deleting ? null : () => _deleteItem(i),
                              tooltip: 'Delete notification',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                              icon: Icon(
                                Icons.delete_outline_rounded,
                                size: 18,
                                color: Colors.grey[400],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _AdminSidebar extends StatefulWidget {
  final List<_DashboardPage> items;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onLogout;
  final int pendingCount;

  const _AdminSidebar({
    required this.items,
    required this.selectedIndex,
    required this.onSelect,
    required this.onLogout,
    this.pendingCount = 0,
  });

  @override
  State<_AdminSidebar> createState() => _AdminSidebarState();
}

class _AdminSidebarState extends State<_AdminSidebar> {
  static const Duration _duration = Duration(milliseconds: 260);
  static const Curve _curve = Curves.easeOutCubic;

  bool _collapsed = false;
  bool _initializedWidth = false;
  int _hovered = -1;
  bool _logoutHovered = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initializedWidth) {
      _collapsed = MediaQuery.of(context).size.width < 1100;
      _initializedWidth = true;
    }
  }

  Widget _buildBrand() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 12, 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.gold, AppColors.goldLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.admin_panel_settings_rounded,
              size: 22,
              color: AppColors.royalBlueDark,
            ),
          ),
          Expanded(
            child: ClipRect(
              child: AnimatedAlign(
                alignment: Alignment.centerLeft,
                widthFactor: _collapsed ? 0.0 : 1.0,
                duration: _duration,
                curve: _curve,
                child: AnimatedOpacity(
                  opacity: _collapsed ? 0.0 : 1.0,
                  duration: _duration,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CSU-A Admin',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.fade,
                        ),
                        Text(
                          'Management Console',
                          style: GoogleFonts.inter(
                            fontSize: 10.5,
                            color: Colors.white54,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.fade,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Align(
        alignment: _collapsed ? Alignment.center : Alignment.centerRight,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => setState(() => _collapsed = !_collapsed),
            borderRadius: BorderRadius.circular(10),
            child: AnimatedContainer(
              duration: _duration,
              curve: _curve,
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: AnimatedRotation(
                turns: _collapsed ? 0.5 : 0.0,
                duration: _duration,
                curve: _curve,
                child: Icon(
                  _collapsed
                      ? Icons.keyboard_double_arrow_right_rounded
                      : Icons.keyboard_double_arrow_left_rounded,
                  size: 17,
                  color: Colors.white70,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

Widget _buildItem({
    required int index,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    int? badgeCount,
    bool danger = false,
  }) {
    final selected = widget.selectedIndex == index && !danger;
    final hovered = _hovered == index;
    final showBadge = badgeCount != null && badgeCount > 0;

    final Color iconColor = danger
        ? (hovered ? Colors.red.shade300 : Colors.red.shade200)
        : selected
            ? AppColors.gold
            : hovered
                ? Colors.white
                : Colors.white60;

    Widget badge() {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.red.shade600,
          borderRadius: BorderRadius.circular(99),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Text(
          badgeCount! > 99 ? '99+' : '$badgeCount',
          style: GoogleFonts.inter(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = index),
        onExit: (_) => setState(() => _hovered = -1),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: AnimatedContainer(
            duration: _duration,
            curve: _curve,
            height: 46,
            padding: EdgeInsets.symmetric(horizontal: _collapsed ? 5 : 10),
            decoration: BoxDecoration(
              color: selected
                  ? Colors.white.withValues(alpha: 0.12)
                  : hovered
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: _duration,
                  curve: _curve,
                  width: selected ? 4 : 0,
                  height: 24,
                  margin: EdgeInsets.only(right: selected ? 9 : 0),
                  decoration: BoxDecoration(
                    color: danger ? Colors.red.shade300 : AppColors.gold,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                AnimatedScale(
                  scale: hovered || selected ? 1.12 : 1.0,
                  duration: _duration,
                  curve: _curve,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(icon, size: 21, color: iconColor),
                      if (_collapsed && showBadge)
                        Positioned(
                          right: -9,
                          top: -9,
                          child: badge(),
                        ),
                    ],
                  ),
                ),
                AnimatedContainer(
                  duration: _duration,
                  curve: _curve,
                  width: _collapsed ? 0 : 13,
                ),
                Expanded(
                  child: ClipRect(
                    child: AnimatedAlign(
                      alignment: Alignment.centerLeft,
                      widthFactor: _collapsed ? 0.0 : 1.0,
                      duration: _duration,
                      curve: _curve,
                      child: AnimatedOpacity(
                        opacity: _collapsed ? 0.0 : 1.0,
                        duration: _duration,
                        child: AnimatedDefaultTextStyle(
                          duration: _duration,
                          curve: _curve,
                          style: GoogleFonts.inter(
                            fontSize: 13.5,
                            fontWeight:
                                selected ? FontWeight.w600 : FontWeight.w500,
                            color: danger
                                ? Colors.red.shade200
                                : selected
                                    ? Colors.white
                                    : Colors.white70,
                          ),
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.fade,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (!_collapsed && showBadge) ...[
                  const SizedBox(width: 6),
                  badge(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      width: _collapsed ? 76 : 236,
      duration: _duration,
      curve: _curve,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF00234A), Color(0xFF001A3D)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(2, 0)),
        ],
      ),
      child: Column(
        children: [
          _buildBrand(),
          _buildToggleButton(),
          const SizedBox(height: 10),
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            color: Colors.white.withValues(alpha: 0.08),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 4, bottom: 8),
              itemCount: widget.items.length,
itemBuilder: (context, i) {
                final item = widget.items[i];
                final badge = item.label == 'Approvals'
                    ? widget.pendingCount
                    : null;
                return _collapsed
                    ? Tooltip(
                        message: item.label,
                        waitDuration: const Duration(milliseconds: 350),
                        child: _buildItem(
                          index: i,
                          icon: item.icon,
                          label: item.label,
                          onTap: () => widget.onSelect(i),
                          badgeCount: badge,
                        ),
                      )
                    : _buildItem(
                        index: i,
                        icon: item.icon,
                        label: item.label,
                        onTap: () => widget.onSelect(i),
                        badgeCount: badge,
                      );
              },
            ),
          ),
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            color: Colors.white.withValues(alpha: 0.08),
          ),
          const SizedBox(height: 8),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            onEnter: (_) => setState(() => _logoutHovered = true),
            onExit: (_) => setState(() => _logoutHovered = false),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.onLogout,
              child: AnimatedContainer(
                duration: _duration,
                curve: _curve,
                height: 46,
                margin: const EdgeInsets.fromLTRB(12, 0, 12, 14),
                padding: EdgeInsets.symmetric(horizontal: _collapsed ? 5 : 10),
                decoration: BoxDecoration(
                  color: _logoutHovered
                      ? Colors.red.withValues(alpha: 0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    AnimatedScale(
                      scale: _logoutHovered ? 1.12 : 1.0,
                      duration: _duration,
                      curve: _curve,
                      child: Icon(
                        Icons.logout_rounded,
                        size: 21,
                        color: _logoutHovered
                            ? Colors.red.shade300
                            : Colors.red.shade200,
                      ),
                    ),
                    AnimatedContainer(
                      duration: _duration,
                      curve: _curve,
                      width: _collapsed ? 0 : 13,
                    ),
                    Expanded(
                      child: ClipRect(
                        child: AnimatedAlign(
                          alignment: Alignment.centerLeft,
                          widthFactor: _collapsed ? 0.0 : 1.0,
                          duration: _duration,
                          curve: _curve,
                          child: AnimatedOpacity(
                            opacity: _collapsed ? 0.0 : 1.0,
                            duration: _duration,
                            child: Text(
                              'Logout',
                              maxLines: 1,
                              overflow: TextOverflow.fade,
                              style: GoogleFonts.inter(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w500,
                                color: Colors.red.shade200,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveClock extends StatefulWidget {
  const _LiveClock();

  @override
  State<_LiveClock> createState() => _LiveClockState();
}

class _LiveClockState extends State<_LiveClock> {
  late DateTime _now = DateTime.now();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
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

  @override
  Widget build(BuildContext context) {
    return Container(
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
            _formattedTime(_now),
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
            _formattedDate(_now),
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }
}
