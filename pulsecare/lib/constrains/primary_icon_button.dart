import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
  });

  bool get _isSvg => iconPath.toLowerCase().endsWith('.svg');

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(borderRadius),
      onTap: onTap,
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _isSvg
                ? SvgPicture.asset(
                    iconPath,
                    width: iconSize,
                    height: iconSize,
                    // ignore: deprecated_member_use
                    color: iconColor,
                  )
                : Image.asset(
                    iconPath,
                    width: iconSize,
                    height: iconSize,
                    color: iconColor,
                  ),
            const SizedBox(width: 8),
            Text(
              text,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
