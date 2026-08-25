import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Arcade-style chunky button: thick 2px border, hard 4px offset shadow that
/// collapses to `translate-y-1` on press, mimicking a physical switch.
class NeoButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color background;
  final Color foreground;
  final Color borderColor;
  final double fontSize;
  final EdgeInsets padding;
  final Widget? leading;

  const NeoButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.background = AppColors.medium,
    this.foreground = AppColors.canvas,
    this.borderColor = AppColors.textPrimary,
    this.fontSize = 16,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    this.leading,
  });

  @override
  State<NeoButton> createState() => _NeoButtonState();
}

class _NeoButtonState extends State<NeoButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    const shadowDepth = 4.0;
    final enabled = widget.onPressed != null;
    final bg = enabled ? widget.background : widget.borderColor;
    final fg = enabled ? widget.foreground : AppColors.textMuted;

    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
      onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
      onTapUp: enabled
          ? (_) {
              setState(() => _pressed = false);
              widget.onPressed?.call();
            }
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        curve: Curves.easeOut,
        transform: _pressed
            ? Matrix4.translationValues(0, shadowDepth, 0)
            : Matrix4.identity(),
        padding: widget.padding,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(9999),
          border: Border.all(color: widget.borderColor, width: 2),
          boxShadow: _pressed
              ? const []
              : [
                  BoxShadow(
                    color: AppColors.shadow.withValues(alpha: 0.9),
                    offset: const Offset(0, shadowDepth),
                    blurRadius: 0,
                  ),
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.leading != null) ...[
              widget.leading!,
              const SizedBox(width: 8),
            ],
            Text(
              widget.label,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: widget.fontSize,
                letterSpacing: 0.6,
                color: fg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}