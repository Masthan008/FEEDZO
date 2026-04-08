import 'package:flutter/material.dart';

/// Responsive utility class for handling different screen sizes
class Responsive {
  static late MediaQueryData _mediaQueryData;
  static late double screenWidth;
  static late double screenHeight;
  static late double blockSizeHorizontal;
  static late double blockSizeVertical;
  static late double safeAreaHorizontal;
  static late double safeAreaVertical;
  static late double safeWidth;
  static late double safeHeight;
  static late double devicePixelRatio;
  static late bool isTablet;
  static late bool isPhone;
  static late bool isSmallPhone;
  static late bool isDesktop;
  static late double textScaleFactor;

  static void init(BuildContext context) {
    _mediaQueryData = MediaQuery.of(context);
    screenWidth = _mediaQueryData.size.width;
    screenHeight = _mediaQueryData.size.height;
    blockSizeHorizontal = screenWidth / 100;
    blockSizeVertical = screenHeight / 100;
    safeAreaHorizontal = _mediaQueryData.padding.left + _mediaQueryData.padding.right;
    safeAreaVertical = _mediaQueryData.padding.top + _mediaQueryData.padding.bottom;
    safeWidth = screenWidth - safeAreaHorizontal;
    safeHeight = screenHeight - safeAreaVertical;
    devicePixelRatio = _mediaQueryData.devicePixelRatio;
    textScaleFactor = _mediaQueryData.textScaleFactor.clamp(0.8, 1.2);
    
    // Device type detection
    isDesktop = screenWidth > 1200;
    isTablet = screenWidth > 600 && screenWidth <= 1200;
    isPhone = screenWidth <= 600;
    isSmallPhone = screenWidth < 360;
  }

  /// Get width percentage
  static double wp(double percentage) => screenWidth * percentage / 100;
  
  /// Get height percentage  
  static double hp(double percentage) => screenHeight * percentage / 100;
  
  /// Get adaptive font size
  static double sp(double size) => size * textScaleFactor;
  
  /// Get adaptive padding
  static EdgeInsets padding(double horizontal, double vertical) =>
      EdgeInsets.symmetric(
        horizontal: wp(horizontal),
        vertical: hp(vertical),
      );
}

/// Responsive widget that rebuilds on size changes
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, ResponsiveInfo info) builder;

  const ResponsiveBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);
    final info = ResponsiveInfo(
      isMobile: Responsive.isPhone,
      isTablet: Responsive.isTablet,
      isDesktop: Responsive.isDesktop,
      width: Responsive.screenWidth,
      height: Responsive.screenHeight,
      textScale: Responsive.textScaleFactor,
    );
    return builder(context, info);
  }
}

class ResponsiveInfo {
  final bool isMobile;
  final bool isTablet;
  final bool isDesktop;
  final double width;
  final double height;
  final double textScale;

  ResponsiveInfo({
    required this.isMobile,
    required this.isTablet,
    required this.isDesktop,
    required this.width,
    required this.height,
    required this.textScale,
  });
}

/// Safe area wrapper with keyboard handling
class SafeResponsive extends StatelessWidget {
  final Widget child;
  final bool avoidBottomInset;

  const SafeResponsive({
    super.key,
    required this.child,
    this.avoidBottomInset = true,
  });

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);
    return Scaffold(
      resizeToAvoidBottomInset: avoidBottomInset,
      body: SafeArea(
        child: child,
      ),
    );
  }
}

/// Flexible text that scales and avoids overflow
class AutoText extends StatelessWidget {
  final String text;
  final double? size;
  final FontWeight? weight;
  final Color? color;
  final int? maxLines;
  final TextAlign? align;
  final double? minSize;

  const AutoText(
    this.text, {
    super.key,
    this.size,
    this.weight,
    this.color,
    this.maxLines,
    this.align,
    this.minSize,
  });

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);
    final fontSize = size ?? 14;
    final adaptiveSize = Responsive.sp(fontSize);
    final clampedSize = minSize != null 
        ? adaptiveSize.clamp(minSize!, double.infinity)
        : adaptiveSize;
    
    return Text(
      text,
      style: TextStyle(
        fontSize: clampedSize,
        fontWeight: weight,
        color: color,
      ),
      maxLines: maxLines,
      textAlign: align,
      overflow: maxLines != null ? TextOverflow.ellipsis : null,
    );
  }
}

/// Responsive spacing widget
class Gap extends StatelessWidget {
  final double? width;
  final double? height;

  const Gap.h(this.width, {super.key}) : height = null;
  const Gap.v(this.height, {super.key}) : width = null;
  const Gap.square(double size, {super.key}) 
      : width = size, 
        height = size;

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);
    return SizedBox(
      width: width != null ? Responsive.wp(width!) : null,
      height: height != null ? Responsive.hp(height!) : null,
    );
  }
}
