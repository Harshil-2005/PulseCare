import 'package:flutter/material.dart';

class NextActionButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final bool isLoading;

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
    this.height = 60,
    this.arrowWidth = 88,
    this.backgroundColor = const Color(0xFF3F67FD),
    this.arrowBackgroundColor = Colors.white,
    this.textColor = Colors.white,
    this.arrowTextColor = const Color(0xFF3F67FD),
  });

  @override
  Widget build(BuildContext context) {
    return AbsorbPointer(
      absorbing: isLoading,
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: height,
          width: double.infinity,
          decoration: BoxDecoration(
            color: backgroundColor.withOpacity(isLoading ? 0.7 : 1),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            children: [
              const SizedBox(width: 90),

              /// TEXT OR LOADER
              Expanded(
                child: Center(
                  child: isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          text,
                          style: TextStyle(
                            fontSize: 18,
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
                  height: height - 5,
                  width: arrowWidth,
                  decoration: BoxDecoration(
                    color: arrowBackgroundColor,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Center(
                    child: isLoading
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF3F67FD),
                            ),
                          )
                        : Text(
                            '>>>',
                            style: TextStyle(
                              fontSize: 25,
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
