import 'package:flutter/material.dart';

import '../constants/app_sizes.dart';

abstract final class Breakpoints {
  static const mobile = 600.0;
  static const tablet = 1024.0;
}

abstract final class AppResponsive {
  static double widthOf(BuildContext context) =>
      MediaQuery.sizeOf(context).width;

  static bool isMobile(BuildContext context) =>
      widthOf(context) < Breakpoints.mobile;

  static bool isTablet(BuildContext context) {
    final width = widthOf(context);
    return width >= Breakpoints.mobile && width < Breakpoints.tablet;
  }

  static bool isDesktop(BuildContext context) =>
      widthOf(context) >= Breakpoints.tablet;

  static double pagePadding(BuildContext context) {
    if (isDesktop(context)) return AppSizes.pagePaddingDesktop;
    if (isTablet(context)) return AppSizes.pagePaddingTablet;
    return AppSizes.pagePaddingMobile;
  }
}
