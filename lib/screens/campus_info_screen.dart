import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/campus_models.dart';
import '../services/campus_repository.dart';
import '../theme/app_colors.dart';
import '../widgets/expandable_card.dart';
import '../widgets/kiosk_back_button.dart';

enum _InfoCategory { deans, faculty }

class CampusInfoScreen extends StatefulWidget {
  const CampusInfoScreen({super.key});

  @override
  State<CampusInfoScreen> createState() => _CampusInfoScreenState();
}

class _CampusInfoScreenState extends State<CampusInfoScreen> {
  static const Color _goldText = Color(0xFF9C7A00);
  static const Color _facultyAccent = Color(0xFFB8860B);

  late DateTime _currentTime;
  late Timer _timer;

  final CampusRepository _repository = CampusRepository();

  late Future<(List<LeadershipMember>, List<CollegeFacultyGroup>)>
      _dataFuture;

  _InfoCategory? _selectedCategory;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    _currentTime = DateTime.now();

    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (mounted) {
          setState(() {
            _currentTime = DateTime.now();
          });
        }
      },
    );

    _dataFuture = _loadData();
  }

  Future<(List<LeadershipMember>, List<CollegeFacultyGroup>)>
      _loadData() async {
    final results = await Future.wait([
      _repository.getLeadership(),
      _repository.getCollegeFacultyGroups(),
    ]);

    return (
      results[0] as List<LeadershipMember>,
      results[1] as List<CollegeFacultyGroup>,
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _selectCategory(_InfoCategory category) {
    setState(() {
      _selectedCategory = category;
    });
    _scrollToTop();
  }

  void _showCategories() {
    setState(() {
      _selectedCategory = null;
    });
    _scrollToTop();
  }

  void _scrollToTop() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  String _formattedTime(DateTime dt) {
    final h = dt.hour > 12
        ? dt.hour - 12
        : (dt.hour == 0 ? 12 : dt.hour);

    final m = dt.minute.toString().padLeft(2, '0');

    final ampm = dt.hour >= 12 ? 'PM' : 'AM';

    return '$h:$m $ampm';
  }

  String _formattedDate(DateTime dt) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  // ============================================================
  // IMPORTANT CEO / EXECUTIVE OFFICER LOGIC
  // ============================================================
  //
  // DO NOT use leadership.first.
  //
  // We specifically search for the Executive Officer.
  //
  // If the Executive Officer is deleted, this returns null.
  // The screen will then show VACANT.
  //
  // The next Dean/Head will NEVER become CEO automatically.
  // ============================================================

  LeadershipMember? _findExecutiveOfficer(
    List<LeadershipMember> leadership,
  ) {
    for (final member in leadership) {
      final position =
          (member.position ?? '').trim().toLowerCase();

      if (position == 'campus executive officer' ||
          position == 'executive officer' ||
          position == 'ceo' ||
          position.contains('campus executive officer') ||
          position.contains('executive officer')) {
        return member;
      }
    }

    return null;
  }

  bool _isDean(LeadershipMember member) {
    final position = (member.position ?? '').trim().toLowerCase();
    return position.contains('dean');
  }

  List<String> _parseFacultyNames(String? raw) {
    return (raw ?? '')
        .split(', ')
        .map((name) => name.trim())
        .where((name) => name.isNotEmpty)
        .toList();
  }

  (String, String?) _splitFacultyLabel(String label) {
    final parts = label.split(' â€” ');
    if (parts.length >= 2) {
      return (
        parts.first.trim(),
        parts.sublist(1).join(' â€” ').trim(),
      );
    }
    return (label.trim(), null);
  }

  String _initialsOf(String name) {
    final words = name
        .replaceAll('.', '')
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .where((w) =>
            w.toLowerCase() != 'prof' && w.toLowerCase() != 'dr')
        .toList();

    if (words.isEmpty) return '?';
    if (words.length == 1) {
      return words.first.substring(0, 1).toUpperCase();
    }
    return (words.first.substring(0, 1) + words.last.substring(0, 1))
        .toUpperCase();
  }

  // ============================================================
  // BUILD
  // ============================================================

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
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: EdgeInsets.symmetric(
                horizontal: isWide ? 64 : 32,
                vertical: 24,
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const KioskBackButton(),

                  const SizedBox(height: 16),

                  _buildTitleSection(),

                  const SizedBox(height: 28),

                  FutureBuilder<
                      (
                        List<LeadershipMember>,
                        List<CollegeFacultyGroup>
                      )>(
                    future: _dataFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Padding(
                          padding:
                              EdgeInsets.symmetric(
                            vertical: 60,
                          ),
                          child: Center(
                            child:
                                CircularProgressIndicator(),
                          ),
                        );
                      }

                      if (snapshot.hasError) {
                        return _buildEmptyMessage(
                          Icons.error_outline_rounded,
                          'Unable to load campus information',
                        );
                      }

                      final leadership =
                          snapshot.data?.$1 ?? [];

                      final collegeFaculty =
                          snapshot.data?.$2 ?? [];

                      // ====================================================
                      // FIND CEO SPECIFICALLY
                      //
                      // DO NOT use leadership.first.
                      //
                      // Remove the Executive Officer from the list
                      // before displaying College Deans.
                      // ====================================================

                      final executiveOfficer =
                          _findExecutiveOfficer(
                        leadership,
                      );

                      final deans = leadership
                          .where((member) =>
                              member !=
                                  executiveOfficer &&
                              _isDean(member))
                          .toList();

                      final facultyCount =
                          collegeFaculty.fold<int>(
                        0,
                        (sum, group) =>
                            sum +
                            _parseFacultyNames(
                                    group.faculty)
                                .length,
                      );

                      return AnimatedSwitcher(
                        duration: const Duration(
                            milliseconds: 250),
                        child:
                            _selectedCategory == null
                                ? KeyedSubtree(
                                    key: const ValueKey(
                                        'menu'),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment
                                              .start,
                                      children: [
                                        _buildCampusExecutiveSection(
                                          executiveOfficer,
                                        ),

                                        const SizedBox(
                                            height: 36),

                                        _buildCategoryMenu(
                                          deansCount:
                                              deans
                                                  .length,
                                          facultyCount:
                                              facultyCount,
                                        ),
                                      ],
                                    ),
                                  )
                                : KeyedSubtree(
                                    key: ValueKey(
                                        _selectedCategory),
                                    child:
                                        _buildCategoryContent(
                                      isWide: isWide,
                                      deans: deans,
                                      collegeFaculty:
                                          collegeFaculty,
                                    ),
                                  ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EMPTY MESSAGE
  // ============================================================

  Widget _buildEmptyMessage(
    IconData icon,
    String message,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 48,
            color: Colors.grey[300],
          ),

          const SizedBox(height: 12),

          Text(
            message,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.royalBlue,
            AppColors.royalBlueDark,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 32,
        vertical: 16,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(
                alpha: 0.15,
              ),
              borderRadius:
                  BorderRadius.circular(12),
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
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Cagayan State University',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight:
                        FontWeight.w700,
                    color: Colors.white,
                  ),
                ),

                Text(
                  'Aparri Campus',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight:
                        FontWeight.w400,
                    color:
                        Colors.white.withValues(
                      alpha: 0.7,
                    ),
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),

          Container(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(
                alpha: 0.1,
              ),
              borderRadius:
                  BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white
                    .withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.access_time_rounded,
                  size: 16,
                  color:
                      Colors.white.withValues(
                    alpha: 0.8,
                  ),
                ),

                const SizedBox(width: 8),

                Text(
                  _formattedTime(
                    _currentTime,
                  ),
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight:
                        FontWeight.w600,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(width: 12),

                Container(
                  width: 1,
                  height: 16,
                  color:
                      Colors.white.withValues(
                    alpha: 0.3,
                  ),
                ),

                const SizedBox(width: 12),

                Icon(
                  Icons.calendar_today_rounded,
                  size: 14,
                  color:
                      Colors.white.withValues(
                    alpha: 0.8,
                  ),
                ),

                const SizedBox(width: 8),

                Text(
                  _formattedDate(
                    _currentTime,
                  ),
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight:
                        FontWeight.w500,
                    color:
                        Colors.white.withValues(
                      alpha: 0.9,
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

  // ============================================================
  // TITLE
  // ============================================================

  Widget _buildTitleSection() {
    return Column(
      children: [
        Container(
          padding:
              const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: AppColors.gold
                .withValues(alpha: 0.15),
            borderRadius:
                BorderRadius.circular(20),
          ),
          child: Text(
            'CAMPUS INFORMATION',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight:
                  FontWeight.w700,
              color: AppColors.gold,
              letterSpacing: 3,
            ),
          ),
        ),

        const SizedBox(height: 20),

        Text(
          'Deans & Faculty',
          style: GoogleFonts.poppins(
            color: AppColors.royalBlue,
            fontWeight:
                FontWeight.w800,
            fontSize: 38,
            height: 1.1,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 8),

        Text(
          'Select a category to view the leaders and faculty of CSU-Aparri',
          style: GoogleFonts.inter(
            color: Colors.grey[500],
            fontSize: 16,
            fontWeight:
                FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // ============================================================
  // CATEGORY MENU (Deans / Faculty buttons)
  // ============================================================

  Widget _buildCategoryMenu({
    required int deansCount,
    required int facultyCount,
  }) {
    final isWide =
        MediaQuery.of(context).size.width > 900;

    Widget tile(_InfoCategory category,
        IconData icon,
        String title,
        String subtitle,
        int count,
        Color accent) {
      return _CategoryButton(
        icon: icon,
        title: title,
        subtitle: subtitle,
        count: count,
        accent: accent,
        onTap: () => _selectCategory(category),
      );
    }

    final deansTile = tile(
      _InfoCategory.deans,
      Icons.workspace_premium_rounded,
      'Deans',
      'College deans across the campus',
      deansCount,
      AppColors.royalBlue,
    );

    final facultyTile = tile(
      _InfoCategory.faculty,
      Icons.groups_rounded,
      'Faculty',
      'Faculty members per college',
      facultyCount,
      _facultyAccent,
    );

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Text(
            'SELECT A CATEGORY',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 3,
              color: Colors.grey[500],
            ),
          ),
        ),

        const SizedBox(height: 18),

        if (isWide)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment:
                  CrossAxisAlignment.stretch,
              children: [
                Expanded(child: deansTile),
                const SizedBox(width: 16),
                Expanded(child: facultyTile),
              ],
            ),
          )
        else ...[
          deansTile,
          const SizedBox(height: 14),
          facultyTile,
        ],
      ],
    );
  }

  // ============================================================
  // SELECTED CATEGORY CONTENT
  // ============================================================

  Widget _buildCategoryContent({
    required bool isWide,
    required List<LeadershipMember> deans,
    required List<CollegeFacultyGroup>
        collegeFaculty,
  }) {
    switch (_selectedCategory!) {
      case _InfoCategory.deans:
        return Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            _buildCategoryTopBar(
              'College Deans',
              deans.length,
            ),

            const SizedBox(height: 18),

            if (deans.isEmpty)
              _buildEmptyMessage(
                Icons
                    .workspace_premium_outlined,
                'No deans added yet',
              )
            else
              _buildIdCardGrid(
                isWide,
                deans,
                perRow: 4,
                photoSize: 116,
              ),
          ],
        );

      case _InfoCategory.faculty:
        return Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            _buildCategoryTopBar(
              'Faculty Members',
              collegeFaculty.length,
            ),

            const SizedBox(height: 18),

            _buildFacultySection(
              isWide,
              collegeFaculty,
            ),
          ],
        );
    }
  }

  Widget _buildCategoryTopBar(
    String title,
    int count,
  ) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            behavior:
                HitTestBehavior.opaque,
            onTap: _showCategories,
            child: AnimatedContainer(
              duration: const Duration(
                  milliseconds: 150),
              padding:
                  const EdgeInsets
                      .symmetric(
                horizontal: 14,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(
                        10),
                border: Border.all(
                  color: AppColors.royalBlue
                      .withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                mainAxisSize:
                    MainAxisSize.min,
                children: [
                  const Icon(
                    Icons
                        .arrow_back_ios_new_rounded,
                    size: 13,
                    color:
                        AppColors.royalBlue,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'All Categories',
                    style:
                        GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight:
                          FontWeight.w600,
                      color: AppColors
                          .royalBlue,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 18),

        _buildSectionTitle(title),

        const SizedBox(height: 6),

        Text(
          '$count ${count == 1 ? 'entry' : 'entries'} available',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: Colors.grey[500],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // EXECUTIVE OFFICER
  // ============================================================

  Widget _buildCampusExecutiveSection(
    LeadershipMember? ceo,
  ) {
    final bool isVacant = ceo == null;

    final String name = isVacant
        ? 'VACANT'
        : ceo.name;

    final String department =
        isVacant
            ? 'No Campus Executive Officer assigned'
            : (ceo.department ?? '');

    final String? imagePath =
        isVacant ? null : ceo.imagePath;

    final String? initials =
        isVacant ? null : ceo.initials;

    Widget photo;
    if (isVacant) {
      photo = Container(
        width: 116,
        height: 116,
        decoration: BoxDecoration(
          color: Colors.white.withValues(
            alpha: 0.12,
          ),
          border: Border.all(
            color: AppColors.gold.withValues(
              alpha: 0.5,
            ),
            width: 2,
          ),
        ),
        child: const Center(
          child: Icon(
            Icons.person_off_rounded,
            size: 44,
            color: AppColors.gold,
          ),
        ),
      );
    } else if (imagePath != null) {
      photo = Image.asset(
        imagePath,
        width: 116,
        height: 116,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            _buildPhotoFallback(
          initials,
          116,
        ),
      );
    } else {
      photo = _buildPhotoFallback(
        initials,
        116,
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AppColors.royalBlue,
            AppColors.royalBlueDark,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius:
            BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.royalBlue
                .withValues(alpha: 0.3),
            blurRadius: 24,
            offset:
                const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // ====================================================
          // PHOTO / VACANT ICON (rectangular)
          // ====================================================

          ClipRRect(
            borderRadius:
                BorderRadius.circular(16),
            child: photo,
          ),

          const SizedBox(width: 24),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Campus Executive Officer',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight:
                        FontWeight.w600,
                    color: AppColors.secondary
                        .withValues(
                      alpha: 0.9,
                    ),
                    letterSpacing: 1.5,
                  ),
                ),

                const SizedBox(height: 8),

                Container(
                  padding:
                      const EdgeInsets
                          .symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration:
                      BoxDecoration(
                    color: Colors.white
                        .withValues(
                      alpha: 0.12,
                    ),
                    borderRadius:
                        BorderRadius.circular(
                      12,
                    ),
                    border: Border.all(
                      color: AppColors.gold
                          .withValues(
                        alpha: 0.4,
                      ),
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    name,
                    style:
                        GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight:
                          FontWeight.w700,
                      color: isVacant
                          ? AppColors.gold
                          : Colors.white,
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                Row(
                  children: [
                    Icon(
                      Icons.place_rounded,
                      size: 14,
                      color: Colors.white
                          .withValues(
                        alpha: 0.6,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        department,
                        style: GoogleFonts
                            .inter(
                          fontSize: 14,
                          fontWeight:
                              FontWeight.w400,
                          color: Colors.white
                              .withValues(
                            alpha: 0.7,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PHOTO FALLBACK (rectangular initials tile)
  // ============================================================

  Widget _buildPhotoFallback(
    String? initials,
    double height,
  ) {
    return Container(
      height: height,
      width: height,
      color: AppColors.royalBlue
          .withValues(alpha: 0.07),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.person_rounded,
              size: height * 0.36,
              color: AppColors.royalBlue
                  .withValues(alpha: 0.35),
            ),
            SizedBox(height: height * 0.07),
            Text(
              initials ?? '?',
              style: GoogleFonts.poppins(
                fontSize: height * 0.19,
                fontWeight:
                    FontWeight.w700,
                color: AppColors.royalBlue
                    .withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SECTION TITLE
  // ============================================================

  Widget _buildSectionTitle(
    String title,
  ) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 28,
          decoration: BoxDecoration(
            color: AppColors.secondary,
            borderRadius:
                BorderRadius.circular(2),
          ),
        ),

        const SizedBox(width: 12),

        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight:
                FontWeight.w700,
            color:
                AppColors.royalBlue,
          ),
        ),
      ],
    );
  }


  // ============================================================
  // FACULTY
  // ============================================================

  Widget _buildFacultySection(
    bool isWide,
    List<CollegeFacultyGroup> collegeFaculty,
  ) {
    if (collegeFaculty.isEmpty) {
      return _buildEmptyMessage(
        Icons.school_outlined,
        'No faculty records added yet',
      );
    }

    final sections = <Widget>[];

    for (final (index, entry) in collegeFaculty.indexed) {
      final hasMembers = entry.members.isNotEmpty;
      final names = hasMembers
          ? []
          : _parseFacultyNames(
              entry.faculty,
            );

      final members = hasMembers
          ? entry.members.map((m) {
              return LeadershipMember(
                id: m.id,
                name: m.fullname,
                position: m.position,
                department: entry.college,
                imagePath: m.imageUrl,
                initials: _initialsOf(m.fullname),
              );
            }).toList()
          : names.map((label) {
              final (name, position) =
                  _splitFacultyLabel(label);

              return LeadershipMember(
                id: entry.id,
                name: name,
                position: position,
                department: entry.college,
                imagePath: null,
                initials: _initialsOf(name),
              );
            }).toList();

      sections.add(
        ExpandableCard(
          initiallyExpanded: index == 0,
          header: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.royalBlue,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  entry.college,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${names.length} ${names.length == 1 ? 'member' : 'members'}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
          body: _buildIdCardGrid(
            isWide,
            members,
            perRow: 4,
            photoSize: 116,
          ),
        ),
      );

      sections.add(
        const SizedBox(height: 24),
      );
    }

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: sections,
    );
  }

  // ============================================================
  // FACULTY GRID (2 per row) + ID-STYLE CARD
  // (square 2x2-style picture beside the name)
  // ============================================================

  Widget _buildIdCardGrid(
    bool isWide,
    List<LeadershipMember> members, {
    int perRow = 2,
    double photoSize = 140,
  }) {
    if (!isWide) {
      return Column(
        children:
            members.map((member) {
          return Padding(
            padding:
                const EdgeInsets.only(
              bottom: 14,
            ),
            child: _buildIdCard(
              member,
              photoSize: photoSize,
            ),
          );
        }).toList(),
      );
    }

    final rows = <Widget>[];

    for (int i = 0;
        i < members.length;
        i += perRow) {
      LeadershipMember? cell(int index) =>
          index < members.length
              ? members[index]
              : null;

      Widget slot(LeadershipMember? m) =>
          m == null
              ? const Expanded(
                  child:
                      SizedBox.shrink(),
                )
              : Expanded(
                  child: _buildIdCard(
                    m,
                    photoSize:
                        photoSize,
                  ),
                );

      final rowChildren =
          <Widget>[];

      for (int k = i;
          k < i + perRow;
          k++) {
        if (k > i) {
          rowChildren.add(
            const SizedBox(width: 16),
          );
        }
        rowChildren.add(
          slot(cell(k)),
        );
      }

      rows.add(
        Padding(
          padding:
              const EdgeInsets.only(
            bottom: 14,
          ),
          child: Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: rowChildren,
          ),
        ),
      );
    }

    return Column(children: rows);
  }

  Widget _buildIdCard(
    LeadershipMember member, {
    double photoSize = 140,
  }) {
    final position =
        (member.position ?? '').trim();

    final department =
        (member.department ?? '').trim();

    Widget squarePhoto;
    if (member.imagePath != null) {
      final imagePath = member.imagePath!.trim();
      if (imagePath.isNotEmpty && imagePath.startsWith('assets/')) {
        squarePhoto = Image.asset(
          imagePath,
          width: photoSize,
          height: photoSize,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              _buildPhotoFallback(
            member.initials,
            photoSize,
          ),
        );
      } else if (imagePath.isEmpty || imagePath.startsWith('http')) {
        squarePhoto = Image.network(
          imagePath,
          width: photoSize,
          height: photoSize,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              _buildPhotoFallback(
            member.initials,
            photoSize,
          ),
        );
      } else {
        squarePhoto = Image.asset(
          imagePath,
          width: photoSize,
          height: photoSize,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              _buildPhotoFallback(
            member.initials,
            photoSize,
          ),
        );
      }
    } else {
      squarePhoto = _buildPhotoFallback(
        member.initials,
        photoSize,
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.royalBlue
              .withValues(alpha: 0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.royalBlue
                .withValues(alpha: 0.08),
            blurRadius: 16,
            offset:
                const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius:
                BorderRadius.circular(14),
            child: squarePhoto,
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                if (position.isNotEmpty)
                  Container(
                    padding: const EdgeInsets
                        .symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration:
                        BoxDecoration(
                      color: AppColors.gold
                          .withValues(
                        alpha: 0.18,
                      ),
                      borderRadius:
                          BorderRadius
                              .circular(8),
                    ),
                    child: Text(
                      position
                          .toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow
                          .ellipsis,
                      style: GoogleFonts
                          .inter(
                        fontSize: 10,
                        fontWeight:
                            FontWeight
                                .w700,
                        color: _goldText,
                        letterSpacing:
                            1.2,
                      ),
                    ),
                  ),

                Container(
                  width: double.infinity,
                  margin: EdgeInsets.only(
                    top: position.isNotEmpty
                        ? 10
                        : 0,
                  ),
                  padding:
                      const EdgeInsets
                          .symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration:
                      BoxDecoration(
                    color: AppColors
                        .royalBlue
                        .withValues(
                      alpha: 0.05,
                    ),
                    borderRadius:
                        BorderRadius
                            .circular(12),
                    border: Border.all(
                      color: AppColors
                          .royalBlue
                          .withValues(
                        alpha: 0.15,
                      ),
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    member.name,
                    maxLines: 2,
                    overflow: TextOverflow
                        .ellipsis,
                    style: GoogleFonts
                        .poppins(
                      fontSize: 15,
                      fontWeight:
                          FontWeight.w700,
                      color: AppColors
                          .royalBlueDark,
                    ),
                  ),
                ),

                if (department
                    .isNotEmpty) ...[
                  const SizedBox(
                      height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons
                            .place_rounded,
                        size: 14,
                        color: Colors
                            .grey[500],
                      ),
                      const SizedBox(
                          width: 6),
                      Expanded(
                        child: Text(
                          department,
                          maxLines: 2,
                          overflow:
                              TextOverflow
                                  .ellipsis,
                          style: GoogleFonts
                              .inter(
                            fontSize: 12,
                            fontWeight:
                                FontWeight
                                    .w500,
                            color: Colors
                                .grey[600],
                          ),
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

// ============================================================
// CATEGORY BUTTON
// ============================================================

class _CategoryButton extends StatefulWidget {
  const _CategoryButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.count,
    required this.accent,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final int count;
  final Color accent;
  final VoidCallback onTap;

  @override
  State<_CategoryButton> createState() =>
      _CategoryButtonState();
}

class _CategoryButtonState
    extends State<_CategoryButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final accent = widget.accent;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) =>
          setState(() => _hovered = true),
      onExit: (_) =>
          setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration:
              const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          transform: Matrix4.translationValues(
            0,
            _hovered ? -4 : 0,
            0,
          ),
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.circular(20),
            border: Border.all(
              color: accent.withValues(
                alpha: _hovered ? 0.45 : 0.08,
              ),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(
                  alpha:
                      _hovered ? 0.22 : 0.08,
                ),
                blurRadius:
                    _hovered ? 24 : 14,
                offset: Offset(
                  0,
                  _hovered ? 10 : 5,
                ),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: accent.withValues(
                    alpha: 0.12,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                          16),
                ),
                child: Icon(
                  widget.icon,
                  size: 30,
                  color: accent,
                ),
              ),

              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    Text(
                      widget.title,
                      style: GoogleFonts
                          .poppins(
                        fontSize: 19,
                        fontWeight:
                            FontWeight.w700,
                        color: AppColors
                            .royalBlueDark,
                      ),
                    ),

                    const SizedBox(
                        height: 3),

                    Text(
                      widget.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow
                          .ellipsis,
                      style: GoogleFonts
                          .inter(
                        fontSize: 12.5,
                        color: Colors
                            .grey[500],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              Column(
                crossAxisAlignment:
                    CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets
                        .symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration:
                        BoxDecoration(
                      color:
                          accent.withValues(
                        alpha: 0.12,
                      ),
                      borderRadius:
                          BorderRadius
                              .circular(20),
                    ),
                    child: Text(
                      '${widget.count}',
                      style: GoogleFonts
                          .inter(
                        fontSize: 13,
                        fontWeight:
                            FontWeight.w700,
                        color: accent,
                      ),
                    ),
                  ),

                  const SizedBox(
                      height: 8),

                  AnimatedSlide(
                    duration: const Duration(
                        milliseconds: 200),
                    offset: _hovered
                        ? const Offset(
                            0.25, 0)
                        : Offset.zero,
                    child: Icon(
                      Icons
                          .arrow_forward_rounded,
                      size: 18,
                      color: accent,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
