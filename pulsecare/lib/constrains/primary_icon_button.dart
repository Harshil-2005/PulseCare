import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pulsecare/utils/app_responsive.dart';


class PrimaryIconButton extends StatelessWidget {
  final String text;
  final String iconPath;
  final VoidCallback onTap;
  final double height;
  final double width;
  final Color backgroundColor;
  final Color textColor;
  final Color iconColor;
  final double borderRadius;
  final double iconSize;
  final bool isLoading;
  final String? loadingText;

  const PrimaryIconButton({
    super.key,
    required this.text,
    required this.iconPath,
    required this.onTap,
    this.height = 60,
    this.width = double.infinity,
    this.backgroundColor = const Color(0xff3F67FD),
    this.textColor = Colors.white,
    this.iconColor = Colors.white,
    this.borderRadius = 35,
    this.iconSize = 22,
    this.isLoading = false,
    this.loadingText,
  });

  bool get _isSvg => iconPath.toLowerCase().endsWith('.svg');

  @override
  Widget build(BuildContext context) {
    final effectiveHeight = AppResponsive.compactPx(context, height);
    final effectiveIconSize = AppResponsive.compactPx(context, iconSize);
    final effectiveRadius = AppResponsive.compactPx(context, borderRadius);
    final effectiveTextSize = AppResponsive.compactPx(context, 16);
    return InkWell(
      borderRadius: BorderRadius.circular(effectiveRadius),
      onTap: isLoading ? null : onTap,
      child: Container(
        height: effectiveHeight,
        width: width,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(effectiveRadius),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!isLoading)
              (_isSvg
                  ? SvgPicture.asset(
                      iconPath,
                      width: effectiveIconSize,
                      height: effectiveIconSize,
                      colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
                    )
                  : Image.asset(
                      iconPath,
                      width: effectiveIconSize,
                      height: effectiveIconSize,
                      color: iconColor,
                    )),
            if (!isLoading) const SizedBox(width: 8),
            Text(
              isLoading ? (loadingText ?? text) : text,
              style: TextStyle(
                fontSize: effectiveTextSize,
                fontWeight: FontWeight.w500,
                color: textColor.withValues(alpha: isLoading ? 0.7 : 1),
              ),
            ),
            if (isLoading) ...[
              const SizedBox(width: 12),
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    textColor.withValues(alpha: 0.7),
                  ),
                  strokeWidth: 2.2,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
