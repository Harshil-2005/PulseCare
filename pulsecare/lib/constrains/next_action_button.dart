import 'package:flutter/material.dart';
import 'package:pulsecare/utils/app_responsive.dart';

class NextActionButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final bool isLoading;
  final String? loadingText;

  final double height;
  final double arrowWidth;
  final Color backgroundColor;
  final Color arrowBackgroundColor;
  final Color textColor;
  final Color arrowTextColor;

  const NextActionButton({
    super.key,
    required this.text,
    required this.onTap,
    this.isLoading = false,
    this.loadingText,
    this.height = 60,
    this.arrowWidth = 88,
    this.backgroundColor = const Color(0xFF3F67FD),
    this.arrowBackgroundColor = Colors.white,
    this.textColor = Colors.white,
    this.arrowTextColor = const Color(0xFF3F67FD),
  });

  @override
  Widget build(BuildContext context) {
    final effectiveHeight = AppResponsive.compactPx(context, height);
    final effectiveArrowWidth = AppResponsive.compactPx(context, arrowWidth);
    final effectiveMainTextSize = AppResponsive.compactPx(context, 18);
    final effectiveArrowTextSize = AppResponsive.compactPx(context, 25);
    final effectiveLeadingGap = AppResponsive.compactPx(context, 90);
    final effectiveRadius = AppResponsive.compactPx(context, 30);
    return AbsorbPointer(
      absorbing: isLoading,
      child: InkWell(
        borderRadius: BorderRadius.circular(effectiveRadius),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: effectiveHeight,
          width: double.infinity,
          decoration: BoxDecoration(
            color: backgroundColor.withValues(alpha: isLoading ? 0.7 : 1),
            borderRadius: BorderRadius.circular(effectiveRadius),
          ),
          child: Row(
            children: [
              SizedBox(width: effectiveLeadingGap),

              /// TEXT OR LOADER
              Expanded(
                child: Center(
                  child: Text(
                    isLoading ? (loadingText ?? '$text...') : text,
                    style: TextStyle(
                      fontSize: effectiveMainTextSize,
                      color: textColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),

              /// RIGHT ARROW SECTION
              Padding(
                padding: const EdgeInsets.all(5),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: effectiveHeight - 5,
                  width: effectiveArrowWidth,
                  decoration: BoxDecoration(
                    color: arrowBackgroundColor,
                    borderRadius: BorderRadius.circular(effectiveRadius),
                  ),
                  child: Center(
                    child: isLoading
                        ? SizedBox(
                            width: 26,
                            height: 26,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                arrowTextColor,
                              ),
                            ),
                          )
                        : Text(
                            '>>>',
                            style: TextStyle(
                              fontSize: effectiveArrowTextSize,
                              fontWeight: FontWeight.w400,
                              color: arrowTextColor,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
