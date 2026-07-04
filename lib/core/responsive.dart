import 'package:flutter/material.dart';

/// Breakpoints estándar para diseño responsive.
///
/// - mobile: < 600px
/// - tablet: 600px - 899px
/// - desktop: >= 900px
class ResponsiveBreakpoints {
  static const double mobile = 600;
  static const double tablet = 900;
  static const double desktop = 1200;
}

enum ScreenType { mobile, tablet, desktop }

extension BuildContextResponsive on BuildContext {
  Size get screenSize => MediaQuery.sizeOf(this);

  double get screenWidth => screenSize.width;

  double get screenHeight => screenSize.height;

  ScreenType get screenType {
    final width = screenWidth;
    if (width >= ResponsiveBreakpoints.tablet) {
      return ScreenType.desktop;
    }
    if (width >= ResponsiveBreakpoints.mobile) {
      return ScreenType.tablet;
    }
    return ScreenType.mobile;
  }

  bool get isMobile => screenType == ScreenType.mobile;

  bool get isTablet => screenType == ScreenType.tablet;

  bool get isDesktop => screenType == ScreenType.desktop;

  bool get isMobileOrTablet => isMobile || isTablet;

  T responsiveValue<T>({
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    switch (screenType) {
      case ScreenType.desktop:
        return desktop ?? tablet ?? mobile;
      case ScreenType.tablet:
        return tablet ?? desktop ?? mobile;
      case ScreenType.mobile:
        return mobile;
    }
  }
}

/// Widget que reconstruye según el ancho disponible.
class ResponsiveBuilder extends StatelessWidget {
  const ResponsiveBuilder({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  final WidgetBuilder mobile;
  final WidgetBuilder? tablet;
  final WidgetBuilder? desktop;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= ResponsiveBreakpoints.tablet) {
          return (desktop ?? tablet ?? mobile)(context);
        }
        if (constraints.maxWidth >= ResponsiveBreakpoints.mobile) {
          return (tablet ?? desktop ?? mobile)(context);
        }
        return mobile(context);
      },
    );
  }
}

/// Widget que muestra uno u otro hijo según el ancho.
class ResponsiveVisibility extends StatelessWidget {
  const ResponsiveVisibility({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= ResponsiveBreakpoints.tablet) {
          return desktop ?? tablet ?? mobile;
        }
        if (constraints.maxWidth >= ResponsiveBreakpoints.mobile) {
          return tablet ?? desktop ?? mobile;
        }
        return mobile;
      },
    );
  }
}
