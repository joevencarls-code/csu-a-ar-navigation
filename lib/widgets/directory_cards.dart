import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/campus_models.dart';
import '../theme/app_colors.dart';

/// Shared directory-style cards used by both the kiosk Directory screen
/// and the admin management screens.
///
/// Buildings and offices render as equal-height "box" cards whose top
/// half shows the place's picture; faculty render as ID-style cards.
///
/// Cards on the kiosk Directory screen are tappable ([onTap]) and show a
/// "View details" hint that opens the enlarged view. The admin screens
/// omit [onTap] so their cards stay plain containers.

/// Wraps a card so the whole surface is one tap target, with a pointer
/// cursor on platforms that show one.
Widget _tappableDirectoryCard(Widget card, VoidCallback? onTap) {
  if (onTap == null) return card;
  return MouseRegion(
    cursor: SystemMouseCursors.click,
    child: GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: card,
    ),
  );
}

Widget buildDetailsHint(Color accent) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 12),
      const Divider(height: 1, color: Colors.grey),
      const SizedBox(height: 8),
      Row(
        children: [
          Icon(Icons.open_in_full_rounded, size: 13, color: accent),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Tap to view full details',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: accent,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    ],
  );
}

String directoryInitialsOf(String name) {
  final words = name
      .replaceAll('.', '')
      .trim()
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .where((w) => w.toLowerCase() != 'prof' && w.toLowerCase() != 'dr')
      .toList();
  if (words.isEmpty) return '?';
  if (words.length == 1) {
    return words.first.substring(0, 1).toUpperCase();
  }
  return (words.first.substring(0, 1) + words.last.substring(0, 1))
      .toUpperCase();
}

class CollegeDirectoryCard extends StatelessWidget {
  final College college;
  final VoidCallback? onTap;

  const CollegeDirectoryCard({super.key, required this.college, this.onTap});

  @override
  Widget build(BuildContext context) {
    const accent = AppColors.royalBlue;
    final abbrev = (college.abbrev ?? '').trim();
    final displayAbbrev = abbrev.isNotEmpty
        ? abbrev
        : directoryInitialsOf(college.name);
    final card = Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 150,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.royalBlue, AppColors.royalBlueDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              displayAbbrev,
              style: GoogleFonts.poppins(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 2,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  college.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.royalBlueDark,
                    height: 1.25,
                  ),
                ),
                if (college.dean != null && college.dean!.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  _buildInfoRow(Icons.school_rounded, college.dean!),
                ],
                if (college.location != null &&
                    college.location!.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  _buildInfoRow(Icons.location_on_rounded, college.location!),
                ],
                const SizedBox(height: 12),
                if (college.programs != null &&
                    college.programs!.isNotEmpty) ...[
                  const Divider(height: 1, color: Colors.grey),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.menu_book_rounded,
                        size: 13,
                        color: accent.withValues(alpha: 0.8),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          college.programs!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                if (onTap != null) buildDetailsHint(accent),
              ],
            ),
          ),
        ],
      ),
    );
    return _tappableDirectoryCard(card, onTap);
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 13, color: AppColors.gold),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(fontSize: 11.5, color: Colors.grey[600]),
          ),
        ),
      ],
    );
  }
}

class BuildingDirectoryCard extends StatelessWidget {
  final Building building;
  final VoidCallback? onTap;

  const BuildingDirectoryCard({super.key, required this.building, this.onTap});

  @override
  Widget build(BuildContext context) {
    const accent = AppColors.royalBlue;
    final offices = (building.offices ?? '').trim();
    final card = Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 145,
            width: double.infinity,
            child: (building.imageUrl != null && building.imageUrl!.isNotEmpty)
                ? _buildBuildingImage(building)
                : _buildBuildingImageFallback(),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  building.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.royalBlueDark,
                    height: 1.25,
                  ),
                ),
                if (building.location != null &&
                    building.location!.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        size: 13,
                        color: AppColors.gold,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          building.location!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                if (building.dean != null && building.dean!.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(
                        Icons.school_rounded,
                        size: 13,
                        color: AppColors.gold,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          building.dean!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                if (building.description != null &&
                    building.description!.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    building.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      color: Colors.grey[500],
                      height: 1.4,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                if (offices.isNotEmpty) ...[
                  const Divider(height: 1, color: Colors.grey),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.door_front_door_rounded,
                        size: 13,
                        color: accent.withValues(alpha: 0.8),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          offices,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                if (onTap != null) buildDetailsHint(accent),
              ],
            ),
          ),
        ],
      ),
    );
    return _tappableDirectoryCard(card, onTap);
  }
}

class OfficeDirectoryCard extends StatelessWidget {
  final OfficeEntry office;
  final int index;
  final VoidCallback? onTap;

  const OfficeDirectoryCard({
    super.key,
    required this.office,
    this.index = 0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = index.isEven ? AppColors.royalBlue : const Color(0xFFB8860B);
    final card = Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 145,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                (office.imageUrl != null && office.imageUrl!.isNotEmpty)
                    ? _buildOfficeImage(office, accent)
                    : _buildOfficeImageFallback(accent),
                if (office.abbreviation != null &&
                    office.abbreviation!.isNotEmpty)
                  Positioned(
                    left: 10,
                    bottom: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        office.abbreviation!,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: accent,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  office.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.royalBlueDark,
                    height: 1.25,
                  ),
                ),
                if (office.purpose != null && office.purpose!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    office.purpose!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: Colors.grey[500],
                      height: 1.35,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                if (office.location != null ||
                    office.head != null ||
                    office.contact != null) ...[
                  const Divider(height: 1, color: Colors.grey),
                  const SizedBox(height: 6),
                  if (office.location != null)
                    _buildDetailRow(
                      Icons.location_on_rounded,
                      office.location!,
                      accent,
                    ),
                  if (office.head != null)
                    _buildDetailRow(Icons.person_rounded, office.head!, accent),
                  if (office.contact != null)
                    _buildDetailRow(
                      Icons.phone_rounded,
                      office.contact!,
                      accent,
                    ),
                ],
                if (onTap != null) buildDetailsHint(accent),
              ],
            ),
          ),
        ],
      ),
    );
    return _tappableDirectoryCard(card, onTap);
  }

  Widget _buildDetailRow(IconData icon, String text, Color accent) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 13, color: accent.withValues(alpha: 0.8)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[600]),
            ),
          ),
        ],
      ),
    );
  }
}

class FacultyDirectoryCard extends StatelessWidget {
  final FacultyMember member;
  final String? roomName;

  const FacultyDirectoryCard({super.key, required this.member, this.roomName});

  @override
  Widget build(BuildContext context) {
    final position = (member.position ?? '').trim();
    final room = roomName;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.royalBlue.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: AppColors.royalBlue.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: _buildPhoto(member),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (position.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      position.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF9C7A00),
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                Container(
                  width: double.infinity,
                  margin: EdgeInsets.only(top: position.isNotEmpty ? 10 : 0),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.royalBlue.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.royalBlue.withValues(alpha: 0.15),
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    member.fullname,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.royalBlueDark,
                    ),
                  ),
                ),
                if (room != null && room.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _buildInfoRow(Icons.door_front_door_rounded, room),
                ],
                if (member.email != null && member.email!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  _buildInfoRow(Icons.email_rounded, member.email!),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoto(FacultyMember member, {double size = 116}) {
    final url = (member.imageUrl ?? '').trim();
    final fallback = _buildPhotoFallback(
      directoryInitialsOf(member.fullname),
      size,
    );
    if (url.isEmpty) return fallback;
    if (url.startsWith('assets/')) {
      return Container(
        height: size,
        width: size,
        child: Image.asset(
          url,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => fallback,
        ),
      );
    }
    return Container(
      height: size,
      width: size,
      child: Image.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback,
      ),
    );
  }

  Widget _buildPhotoFallback(String? initials, double size) {
    return Container(
      height: size,
      width: size,
      color: AppColors.royalBlue.withValues(alpha: 0.07),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.person_rounded,
              size: size * 0.36,
              color: AppColors.royalBlue.withValues(alpha: 0.35),
            ),
            SizedBox(height: size * 0.07),
            Text(
              initials ?? '?',
              style: GoogleFonts.poppins(
                fontSize: size * 0.19,
                fontWeight: FontWeight.w700,
                color: AppColors.royalBlue.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: Colors.grey[500]),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
        ),
      ],
    );
  }
}

Widget _buildBuildingImage(Building building) {
  final url = building.imageUrl ?? '';
  final fallback = _buildBuildingImageFallback();
  if (url.startsWith('assets/')) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      child: Image.asset(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback,
      ),
    );
  }
  return Container(
    width: double.infinity,
    height: double.infinity,
    child: Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => fallback,
    ),
  );
}

Widget _buildBuildingImageFallback() {
  return _buildImageTile(
    gradient: LinearGradient(
      colors: [
        AppColors.royalBlue,
        AppColors.royalBlue.withValues(alpha: 0.75),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    icon: Icons.account_balance_rounded,
  );
}

Widget _buildOfficeImage(OfficeEntry office, Color accent) {
  final url = office.imageUrl ?? '';
  final fallback = _buildOfficeImageFallback(accent);
  if (url.startsWith('assets/')) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      child: Image.asset(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback,
      ),
    );
  }
  return Container(
    width: double.infinity,
    height: double.infinity,
    child: Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => fallback,
    ),
  );
}

Widget _buildOfficeImageFallback(Color accent) {
  return _buildImageTile(
    gradient: LinearGradient(
      colors: [accent, accent.withValues(alpha: 0.75)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    icon: Icons.apartment_rounded,
  );
}

Widget _buildImageTile({required Gradient gradient, required IconData icon}) {
  return Container(
    decoration: BoxDecoration(gradient: gradient),
    alignment: Alignment.center,
    child: Icon(icon, size: 56, color: Colors.white.withValues(alpha: 0.7)),
  );
}
