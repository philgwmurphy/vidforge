import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

enum AppButtonVariant {
  primary,
  secondary,
  outline,
  ghost,
  danger,
}

enum AppButtonSize {
  small,
  medium,
  large,
}

/// A styled button widget for VidForge
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final IconData? icon;
  final bool iconRight;
  final bool loading;
  final bool expanded;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.medium,
    this.icon,
    this.iconRight = false,
    this.loading = false,
    this.expanded = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final colors = _getColors(isDark);
    final sizing = _getSizing();

    Widget child = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (loading) ...[
          SizedBox(
            width: sizing.iconSize,
            height: sizing.iconSize,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: colors.foreground,
            ),
          ),
          const SizedBox(width: 8),
        ] else if (icon != null && !iconRight) ...[
          Icon(icon, size: sizing.iconSize),
          const SizedBox(width: 8),
        ],
        Text(label),
        if (icon != null && iconRight && !loading) ...[
          const SizedBox(width: 8),
          Icon(icon, size: sizing.iconSize),
        ],
      ],
    );

    final button = _buildButton(
      colors: colors,
      sizing: sizing,
      child: child,
    );

    if (expanded) {
      return SizedBox(
        width: double.infinity,
        child: button,
      );
    }

    return button;
  }

  Widget _buildButton({
    required _ButtonColors colors,
    required _ButtonSizing sizing,
    required Widget child,
  }) {
    switch (variant) {
      case AppButtonVariant.primary:
      case AppButtonVariant.danger:
        return ElevatedButton(
          onPressed: loading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.background,
            foregroundColor: colors.foreground,
            disabledBackgroundColor: colors.background.withOpacity(0.5),
            disabledForegroundColor: colors.foreground.withOpacity(0.5),
            padding: sizing.padding,
            textStyle: sizing.textStyle,
          ),
          child: child,
        );
      case AppButtonVariant.secondary:
        return ElevatedButton(
          onPressed: loading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.background,
            foregroundColor: colors.foreground,
            padding: sizing.padding,
            textStyle: sizing.textStyle,
          ),
          child: child,
        );
      case AppButtonVariant.outline:
        return OutlinedButton(
          onPressed: loading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: colors.foreground,
            side: BorderSide(color: colors.border),
            padding: sizing.padding,
            textStyle: sizing.textStyle,
          ),
          child: child,
        );
      case AppButtonVariant.ghost:
        return TextButton(
          onPressed: loading ? null : onPressed,
          style: TextButton.styleFrom(
            foregroundColor: colors.foreground,
            padding: sizing.padding,
            textStyle: sizing.textStyle,
          ),
          child: child,
        );
    }
  }

  _ButtonColors _getColors(bool isDark) {
    switch (variant) {
      case AppButtonVariant.primary:
        return _ButtonColors(
          background: AppColors.primary,
          foreground: Colors.white,
          border: AppColors.primary,
        );
      case AppButtonVariant.secondary:
        return _ButtonColors(
          background:
              isDark ? AppColors.darkBgTertiary : AppColors.lightBgTertiary,
          foreground:
              isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          border: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        );
      case AppButtonVariant.outline:
        return _ButtonColors(
          background: Colors.transparent,
          foreground:
              isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          border: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        );
      case AppButtonVariant.ghost:
        return _ButtonColors(
          background: Colors.transparent,
          foreground: AppColors.primary,
          border: Colors.transparent,
        );
      case AppButtonVariant.danger:
        return _ButtonColors(
          background: AppColors.error,
          foreground: Colors.white,
          border: AppColors.error,
        );
    }
  }

  _ButtonSizing _getSizing() {
    switch (size) {
      case AppButtonSize.small:
        return _ButtonSizing(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          iconSize: 16,
        );
      case AppButtonSize.medium:
        return _ButtonSizing(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          iconSize: 18,
        );
      case AppButtonSize.large:
        return _ButtonSizing(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          iconSize: 20,
        );
    }
  }
}

class _ButtonColors {
  final Color background;
  final Color foreground;
  final Color border;

  _ButtonColors({
    required this.background,
    required this.foreground,
    required this.border,
  });
}

class _ButtonSizing {
  final EdgeInsets padding;
  final TextStyle textStyle;
  final double iconSize;

  _ButtonSizing({
    required this.padding,
    required this.textStyle,
    required this.iconSize,
  });
}

/// Icon-only button
class AppIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final AppButtonVariant variant;
  final double size;

  const AppIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.tooltip,
    this.variant = AppButtonVariant.ghost,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget button = SizedBox(
      width: size,
      height: size,
      child: IconButton(
        icon: Icon(icon),
        onPressed: onPressed,
        color: variant == AppButtonVariant.primary
            ? AppColors.primary
            : (isDark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary),
        iconSize: size * 0.5,
      ),
    );

    if (tooltip != null) {
      button = Tooltip(
        message: tooltip!,
        child: button,
      );
    }

    return button;
  }
}
