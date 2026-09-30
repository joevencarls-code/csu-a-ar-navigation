import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/campus_models.dart';
import '../services/campus_repository.dart';
import '../theme/app_colors.dart';
import '../widgets/kiosk_back_button.dart';

class AboutScreen extends StatefulWidget {
  final bool showBackButton;

  const AboutScreen({super.key, this.showBackButton = true});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  late DateTime _currentTime;
  late Timer _timer;
  final CampusRepository _repository = CampusRepository();
  late final Future<List<dynamic>> _infoFuture = Future.wait([
    _repository.getCampusSettings(),
    _repository.getColleges(),
    _repository.getFaculty(),
  ]);

  @override
  void initState() {
    super.initState();
    _currentTime = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _currentTime = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer.cancel();
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isWide ? 64 : 32,
                vertical: 24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.showBackButton) ...[
                    _buildBackButton(context),
                    const SizedBox(height: 16),
                  ],
                  _buildTitleSection(),
                  const SizedBox(height: 36),
                  _buildAboutCard(
                    icon: Icons.info_rounded,
                    title: 'About the Kiosk',
                    body: 'This interactive wayfinding kiosk is designed to help '
                        'students, faculty, and visitors navigate the Cagayan State '
                        'University - Aparri Campus. Explore the campus map, browse '
                        'the directory, and find the information you need.',
                  ),
                  const SizedBox(height: 20),
                  FutureBuilder<List<dynamic>>(
                    future: _infoFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      final settings =
                          snapshot.data?[0] as CampusSettings?;
                      if (settings == null) {
                        return _buildAboutCard(
                          icon: Icons.info_outline_rounded,
                          title: 'Campus Information',
                          body: 'Campus information has not been set up yet.',
                        );
                      }
                      final collegeCount =
                          (snapshot.data?[1] as List?)?.length ?? 0;
                      final facultyCount =
                          (snapshot.data?[2] as List?)?.length ?? 0;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildAboutCard(
                            icon: Icons.location_on_rounded,
                            title: 'Location',
                            body: settings.address ?? 'Not set',
                          ),
                          const SizedBox(height: 20),
                          _buildAboutCard(
                            icon: Icons.phone_rounded,
                            title: 'Contact',
                            body: 'Phone: ${settings.phone ?? 'Not set'}\n'
                                'Email: ${settings.email ?? 'Not set'}',
                          ),
                          const SizedBox(height: 20),
                          _buildAboutCard(
                            icon: Icons.language_rounded,
                            title: 'Website',
                            body: settings.website ?? 'Not set',
                          ),
                          const SizedBox(height: 20),
                          _buildAboutCard(
                            icon: Icons.school_rounded,
                            title: 'Campus Statistics',
                            body: '$collegeCount Colleges  •  '
                                '${settings.totalPrograms ?? 0} Programs  •  '
                                '$facultyCount Faculty Members',
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildAboutCard(
                    icon: Icons.developer_mode_rounded,
                    title: 'Version',
                    body: 'Kiosk Terminal #01 — Main Gate\n'
                        'CSU-A Kiosk v1.0.0',
                  ),
                  const SizedBox(height: 32),
                ],
              ),
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
            color: AppColors.gold,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'ABOUT',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.royalBlue,
              letterSpacing: 3,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'About This Kiosk',
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
          'Cagayan State University - Aparri Campus',
          style: GoogleFonts.inter(
            color: Colors.grey[500],
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildAboutCard({
    required IconData icon,
    required String title,
    required String body,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.royalBlue.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 24,
              color: AppColors.royalBlue,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.royalBlueDark,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  body,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
