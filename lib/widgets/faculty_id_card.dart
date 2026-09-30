import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';
import 'directory_cards.dart';

/// The faculty "ID card" shown by the Directory's college detail popup: a
/// square photo beside a gold position badge, the name in a bordered blue
/// box, then the department and email rows.
///
/// Pass [onTap] to turn the whole card into one tap target — the Directory
/// popup uses this to open the member's enlarged view.
class FacultyIdCard extends StatelessWidget {
  const FacultyIdCard({
    super.key,
    required this.fullname,
    this.position,
    this.imageUrl,
    this.department,
    this.email,
    this.photoSize = 116,
    this.showTapHint = false,
    this.onTap,
  });

  final String fullname;
  final String? position;
  final String? imageUrl;
  final String? department;
  final String? email;
  final double photoSize;
  final bool showTapHint;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final position = this.position?.trim() ?? '';
    final department = this.department?.trim() ?? '';
    final email = this.email?.trim() ?? '';

    final card = Container(
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
            child: _buildPhoto(),
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
                    fullname,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.royalBlueDark,
                    ),
                  ),
                ),
                if (department.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _buildInfoRow(Icons.apartment_rounded, department),
                ],
                if (email.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  _buildInfoRow(Icons.email_rounded, email),
                ],
                if (showTapHint && onTap != null)
                  buildDetailsHint(AppColors.royalBlue),
              ],
            ),
          ),
        ],
      ),
    );

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

  Widget _buildPhoto() {
    final imagePath = imageUrl?.trim() ?? '';
    if (imagePath.isEmpty) return _buildFallback();

    final errorBuilder = (_, __, ___) => _buildFallback();
    return SizedBox(
      width: photoSize,
      height: photoSize,
      child: imagePath.startsWith('http')
          ? Image.network(
              imagePath,
              width: photoSize,
              height: photoSize,
              fit: BoxFit.cover,
              errorBuilder: errorBuilder,
            )
          : Image.asset(
              imagePath,
              width: photoSize,
              height: photoSize,
              fit: BoxFit.cover,
              errorBuilder: errorBuilder,
            ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
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

  Widget _buildFallback() {
    return Container(
      height: photoSize,
      width: photoSize,
      color: AppColors.royalBlue.withValues(alpha: 0.07),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.person_rounded,
              size: photoSize * 0.36,
              color: AppColors.royalBlue.withValues(alpha: 0.35),
            ),
            SizedBox(height: photoSize * 0.07),
            Text(
              directoryInitialsOf(fullname),
              style: GoogleFonts.poppins(
                fontSize: photoSize * 0.19,
                fontWeight: FontWeight.w700,
                color: AppColors.royalBlue.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
