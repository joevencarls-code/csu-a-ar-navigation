import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

/// Animated "Back" button shared by all kiosk pages: lifts and glows on
/// hover, compresses on press, and slides its arrow slightly on hover.
class KioskBackButton extends StatefulWidget {
  const KioskBackButton({super.key});

  @override
  State<KioskBackButton> createState() => _KioskBackButtonState();
}

class _KioskBackButtonState extends State<KioskBackButton> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() {
        _hovered = false;
        _pressed = false;
      }),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: () => Navigator.of(context).pop(),
        child: AnimatedScale(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          scale: _pressed ? 0.94 : (_hovered ? 1.03 : 1.0),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.royalBlue.withValues(
                  alpha: _hovered ? 0.35 : 0.0,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.royalBlue.withValues(
                    alpha: _hovered ? 0.18 : 0.06,
                  ),
                  blurRadius: _hovered ? 14 : 8,
                  offset: Offset(0, _hovered ? 4 : 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSlide(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  offset: _hovered ? const Offset(-0.15, 0) : Offset.zero,
                  child: const Icon(
                    Icons.arrow_back_rounded,
                    size: 20,
                    color: AppColors.royalBlue,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Back',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.royalBlue,
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
