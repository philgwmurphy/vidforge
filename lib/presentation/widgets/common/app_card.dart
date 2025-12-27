import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// A styled card widget for VidForge
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final VoidCallback? onTap;
  final bool selected;
  final bool hoverable;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.color,
    this.onTap,
    this.selected = false,
    this.hoverable = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = color ??
        (isDark ? AppColors.darkSurface : AppColors.lightSurface);
    final borderColor = selected
        ? AppColors.primary
        : (isDark ? AppColors.darkBorder : AppColors.lightBorder);

    Widget card = Container(
      margin: margin,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borderColor,
          width: selected ? 2 : 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: Padding(
          padding: padding ?? const EdgeInsets.all(16),
          child: child,
        ),
      ),
    );

    if (onTap != null) {
      card = MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: card,
        ),
      );

      if (hoverable) {
        card = _HoverableCard(
          borderColor: borderColor,
          selected: selected,
          child: card,
        );
      }
    }

    return card;
  }
}

class _HoverableCard extends StatefulWidget {
  final Widget child;
  final Color borderColor;
  final bool selected;

  const _HoverableCard({
    required this.child,
    required this.borderColor,
    required this.selected,
  });

  @override
  State<_HoverableCard> createState() => _HoverableCardState();
}

class _HoverableCardState extends State<_HoverableCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: _isHovered && !widget.selected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: widget.child,
      ),
    );
  }
}
