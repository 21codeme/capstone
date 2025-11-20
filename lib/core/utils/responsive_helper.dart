import 'package:flutter/material.dart';

/// Responsive helper utility for adaptive sizing across different screen sizes
class ResponsiveHelper {
  static const double _smallScreenThreshold = 600.0;
  static const double _mediumScreenThreshold = 900.0;
  
  /// Get screen size category
  static ScreenSize getScreenSize(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    
    if (width < _smallScreenThreshold || height < 600) {
      return ScreenSize.small;
    } else if (width < _mediumScreenThreshold) {
      return ScreenSize.medium;
    } else {
      return ScreenSize.large;
    }
  }
  
  /// Get adaptive padding based on screen size
  static EdgeInsets getAdaptivePadding(BuildContext context) {
    final screenSize = getScreenSize(context);
    switch (screenSize) {
      case ScreenSize.small:
        return const EdgeInsets.all(12.0);
      case ScreenSize.medium:
        return const EdgeInsets.all(16.0);
      case ScreenSize.large:
        return const EdgeInsets.all(20.0);
    }
  }
  
  /// Get adaptive spacing between elements
  static double getAdaptiveSpacing(BuildContext context) {
    final screenSize = getScreenSize(context);
    switch (screenSize) {
      case ScreenSize.small:
        return 8.0;
      case ScreenSize.medium:
        return 12.0;
      case ScreenSize.large:
        return 16.0;
    }
  }
  
  /// Get adaptive icon size
  static double getAdaptiveIconSize(BuildContext context) {
    final screenSize = getScreenSize(context);
    switch (screenSize) {
      case ScreenSize.small:
        return 32.0;
      case ScreenSize.medium:
        return 40.0;
      case ScreenSize.large:
        return 50.0;
    }
  }
  
  /// Get adaptive text size
  static double getAdaptiveTextSize(BuildContext context, {double baseSize = 14.0}) {
    final screenSize = getScreenSize(context);
    switch (screenSize) {
      case ScreenSize.small:
        return baseSize * 0.9;
      case ScreenSize.medium:
        return baseSize;
      case ScreenSize.large:
        return baseSize * 1.1;
    }
  }
  
  /// Check if screen is small (for compact layouts)
  static bool isSmallScreen(BuildContext context) {
    return getScreenSize(context) == ScreenSize.small;
  }
  
  /// Get adaptive card height
  static double getAdaptiveCardHeight(BuildContext context) {
    final screenSize = getScreenSize(context);
    switch (screenSize) {
      case ScreenSize.small:
        return 100.0;
      case ScreenSize.medium:
        return 120.0;
      case ScreenSize.large:
        return 140.0;
    }
  }
}

/// Screen size categories
enum ScreenSize {
  small,
  medium,
  large,
}

/// Responsive widget wrapper
class ResponsiveWidget extends StatelessWidget {
  final Widget Function(BuildContext, ScreenSize) builder;
  
  const ResponsiveWidget({
    super.key,
    required this.builder,
  });
  
  @override
  Widget build(BuildContext context) {
    return builder(context, ResponsiveHelper.getScreenSize(context));
  }
}

/// Adaptive spacing widget
class AdaptiveSpacing extends StatelessWidget {
  final double? height;
  final double? width;
  
  const AdaptiveSpacing({
    super.key,
    this.height,
    this.width,
  });
  
  @override
  Widget build(BuildContext context) {
    final spacing = ResponsiveHelper.getAdaptiveSpacing(context);
    return SizedBox(
      height: height ?? spacing,
      width: width ?? spacing,
    );
  }
}

/// Adaptive container with responsive sizing
class AdaptiveContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;
  final BoxDecoration? decoration;
  
  const AdaptiveContainer({
    super.key,
    required this.child,
    this.padding,
    this.width,
    this.height,
    this.decoration,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: padding ?? ResponsiveHelper.getAdaptivePadding(context),
      decoration: decoration,
      child: child,
    );
  }
}





