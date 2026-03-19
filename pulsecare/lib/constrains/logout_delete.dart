import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

void showConfirmationDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String iconPath,
  required String confirmText,
  required VoidCallback onConfirm,
}) {
  String formatMessage(String text) {
    if (text.length <= 30) return text;
    final mid = text.length ~/ 2;
    final splitAt = text.lastIndexOf(' ', mid);
    if (splitAt <= 0) return text;
    return '${text.substring(0, splitAt)}\n${text.substring(splitAt + 1)}';
  }

  showDialog(
    context: context,
    builder: (context) {
      final screenWidth = MediaQuery.of(context).size.width;
      final isCompact = screenWidth < 390;
      final buttonFontSize = isCompact ? 14.0 : 16.0;
      final buttonHorizontalPadding = isCompact ? 4.0 : 20.0;
      final actionsSidePadding = isCompact ? 4.0 : 20.0;
      final buttonHeight = isCompact ? 56.0 : 50.0;

      return AlertDialog(
        backgroundColor: Colors.white,
        insetPadding: EdgeInsets.symmetric(horizontal: isCompact ? 12 : 24),
        actionsPadding: EdgeInsets.fromLTRB(
          isCompact ? 10 : 20,
          0,
          isCompact ? 10 : 20,
          20,
        ),
        icon: CircleAvatar(
          radius: 30,
          backgroundColor: const Color.fromARGB(255, 222, 229, 255),
          child: SvgPicture.asset(iconPath, height: 20, width: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w500),
        ),
        content: Text(
          formatMessage(message),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: actionsSidePadding),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      height: buttonHeight,
                      padding: EdgeInsets.symmetric(
                        horizontal: buttonHorizontalPadding,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xffD9D9D9),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'Cancel',
                            maxLines: 1,
                            softWrap: false,
                            style: TextStyle(
                              fontSize: buttonFontSize,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: isCompact ? 10 : 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      onConfirm();
                    },
                    child: Container(
                      height: buttonHeight,
                      padding: EdgeInsets.symmetric(
                        horizontal: buttonHorizontalPadding,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xff3F67FD),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            confirmText,
                            maxLines: 1,
                            softWrap: false,
                            style: TextStyle(
                              fontSize: buttonFontSize,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    },
  );
}
