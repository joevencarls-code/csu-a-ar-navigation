import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

/// A touch-friendly QWERTY keyboard for kiosk screens with no physical
/// keyboard attached. Types directly into [controller].
class OnScreenKeyboard extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback? onSubmit;
  final VoidCallback? onClose;

  const OnScreenKeyboard({
    super.key,
    required this.controller,
    this.onSubmit,
    this.onClose,
  });

  @override
  State<OnScreenKeyboard> createState() => _OnScreenKeyboardState();
}

class _OnScreenKeyboardState extends State<OnScreenKeyboard> {
  bool _caps = false;

  static const _row1 = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '0'];
  static const _row2 = ['q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p'];
  static const _row3 = ['a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l'];
  static const _row4 = ['z', 'x', 'c', 'v', 'b', 'n', 'm'];

  void _insertText(String text) {
    setState(() {
      widget.controller.text += _caps ? text.toUpperCase() : text;
      widget.controller.selection =
          TextSelection.collapsed(offset: widget.controller.text.length);
    });
  }

  void _backspace() {
    final text = widget.controller.text;
    if (text.isEmpty) return;
    setState(() {
      widget.controller.text = text.substring(0, text.length - 1);
      widget.controller.selection =
          TextSelection.collapsed(offset: widget.controller.text.length);
    });
  }

  Widget _buildKey(
    String label, {
    int flex = 1,
    VoidCallback? onTap,
    Widget? child,
  }) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          elevation: 1,
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: onTap ?? () => _insertText(label),
            child: SizedBox(
              height: 48,
              child: Center(
                child: child ??
                    Text(
                      _caps ? label.toUpperCase() : label,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.royalBlueDark,
                      ),
                    ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFE8EDF2),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(children: _row1.map((k) => _buildKey(k)).toList()),
          Row(children: _row2.map((k) => _buildKey(k)).toList()),
          Row(
            children: [
              const SizedBox(width: 22),
              ..._row3.map((k) => _buildKey(k)),
              const SizedBox(width: 22),
            ],
          ),
          Row(
            children: [
              _buildKey(
                'shift',
                flex: 2,
                onTap: () => setState(() => _caps = !_caps),
                child: Icon(
                  Icons.keyboard_capslock_rounded,
                  size: 18,
                  color: _caps ? AppColors.royalBlue : Colors.grey,
                ),
              ),
              ..._row4.map((k) => _buildKey(k)),
              _buildKey(
                'back',
                flex: 2,
                onTap: _backspace,
                child: const Icon(Icons.backspace_outlined, size: 18),
              ),
            ],
          ),
          Row(
            children: [
              _buildKey(
                'close',
                flex: 2,
                onTap: widget.onClose,
                child: const Icon(Icons.keyboard_hide_rounded, size: 18),
              ),
              _buildKey(
                'space',
                flex: 6,
                onTap: () => _insertText(' '),
                child: const Icon(Icons.space_bar_rounded, size: 16),
              ),
              _buildKey(
                'go',
                flex: 2,
                onTap: widget.onSubmit,
                child: const Icon(
                  Icons.check_circle_rounded,
                  size: 18,
                  color: AppColors.royalBlue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
