import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

/// Collapsible card: tap the header to expand or collapse the body.
/// Used by Campus Info and Directory for college accordions.
class ExpandableCard extends StatefulWidget {
  const ExpandableCard({
    super.key,
    required this.header,
    required this.body,
    this.initiallyExpanded = false,
  });

  final Widget header;
  final Widget body;
  final bool initiallyExpanded;

  @override
  State<ExpandableCard> createState() => _ExpandableCardState();
}

class _ExpandableCardState extends State<ExpandableCard> {
  late bool _expanded = widget.initiallyExpanded;
  bool _hovered = false;
  bool _pressed = false;

  void _toggle() {
    setState(() {
      _expanded = !_expanded;
      _pressed = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Material(
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MouseRegion(
              cursor: SystemMouseCursors.click,
              onEnter: (_) => setState(() => _hovered = true),
              onExit: (_) => setState(() {
                _hovered = false;
                _pressed = false;
              }),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (_) => setState(() => _pressed = true),
                onTapUp: (_) => _toggle(),
                onTapCancel: () => setState(() => _pressed = false),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _hovered
                        ? AppColors.royalBlue.withValues(alpha: 0.05)
                        : Colors.transparent,
                  ),
                  child: Row(
                    children: [
                      Expanded(child: widget.header),
                      AnimatedRotation(
                        turns: _expanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                        child: AnimatedScale(
                          duration: const Duration(milliseconds: 200),
                          scale: _pressed ? 0.75 : 1,
                          child: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 28,
                            color: AppColors.royalBlue.withValues(
                              alpha: _hovered ? 0.9 : 0.55,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeInOutCubic,
              alignment: Alignment.topCenter,
              child: _expanded
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                      child: widget.body,
                    )
                  : const SizedBox(width: double.infinity),
            ),
          ],
        ),
      ),
    );
  }
}