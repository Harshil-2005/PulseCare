import 'package:flutter/widgets.dart';

class AppResponsive {
  const AppResponsive._();

  static double width(BuildContext context) => MediaQuery.sizeOf(context).width;

  static bool isSmall(BuildContext context) => width(context) <= 390;

  static bool isVerySmall(BuildContext context) => width(context) <= 360;

  static double compactTextScale(BuildContext context) {
    if (isVerySmall(context)) return 0.98;
    if (isSmall(context)) return 0.99;
    return 1.0;
  }

  // Keep the same look as large devices, with only a subtle 1-2px compacting
  // on small phones to avoid oversized controls.
  static double compactPx(BuildContext context, double value) {
    if (!isSmall(context)) return value;

    final scale = isVerySmall(context) ? 0.96 : 0.98;
    final scaled = value * scale;
    final minAllowed = value - 2.0;
    return scaled < minAllowed ? minAllowed : scaled;
  }
}
