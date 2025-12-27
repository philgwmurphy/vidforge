import 'package:flutter/material.dart';

/// Breakpoints for responsive design
class Breakpoints {
  static const double mobile = 600;
  static const double tablet = 900;
  static const double desktop = 1200;
}

/// Responsive layout builder
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    required this.desktop,
  });

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < Breakpoints.mobile;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= Breakpoints.mobile &&
      MediaQuery.of(context).size.width < Breakpoints.tablet;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= Breakpoints.tablet;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= Breakpoints.tablet) {
          return desktop;
        } else if (constraints.maxWidth >= Breakpoints.mobile) {
          return tablet ?? mobile;
        } else {
          return mobile;
        }
      },
    );
  }
}

/// Responsive padding
class ResponsivePadding extends StatelessWidget {
  final Widget child;
  final EdgeInsets? mobilePadding;
  final EdgeInsets? tabletPadding;
  final EdgeInsets? desktopPadding;

  const ResponsivePadding({
    super.key,
    required this.child,
    this.mobilePadding,
    this.tabletPadding,
    this.desktopPadding,
  });

  @override
  Widget build(BuildContext context) {
    EdgeInsets padding;

    if (ResponsiveLayout.isDesktop(context)) {
      padding = desktopPadding ?? const EdgeInsets.all(24);
    } else if (ResponsiveLayout.isTablet(context)) {
      padding = tabletPadding ?? const EdgeInsets.all(20);
    } else {
      padding = mobilePadding ?? const EdgeInsets.all(16);
    }

    return Padding(
      padding: padding,
      child: child,
    );
  }
}

/// Constrained content width for readability
class ConstrainedContent extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final bool center;

  const ConstrainedContent({
    super.key,
    required this.child,
    this.maxWidth = 1200,
    this.center = true,
  });

  @override
  Widget build(BuildContext context) {
    final content = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: child,
    );

    if (center) {
      return Center(child: content);
    }
    return content;
  }
}
