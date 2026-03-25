import 'package:flutter/material.dart';
import 'package:pulsecare/utils/app_responsive.dart';

class RegisterLoginToggleButton extends StatelessWidget {
  final bool isRegisterSelected;
  final VoidCallback onRegisterTap;
  final VoidCallback onLoginTap;

  const RegisterLoginToggleButton({
    super.key,
    required this.isRegisterSelected,
    required this.onRegisterTap,
    required this.onLoginTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveHeight = AppResponsive.compactPx(context, 60);
    final effectiveRadius = AppResponsive.compactPx(context, 30);
    final effectiveFontSize = AppResponsive.compactPx(context, 20);
    return Container(
      height: effectiveHeight,
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 227, 231, 246),
        borderRadius: BorderRadius.circular(effectiveRadius),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: onRegisterTap,
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isRegisterSelected
                      ? const Color(0xFF3F67FD)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(effectiveRadius),
                ),
                child: Text(
                  'Register',
                  style: TextStyle(
                    color: isRegisterSelected ? Colors.white : Colors.black,
                    fontSize: effectiveFontSize,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: onLoginTap,
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: !isRegisterSelected
                      ? const Color(0xFF3F67FD)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(effectiveRadius),
                ),
                child: Text(
                  'Login',
                  style: TextStyle(
                    color: !isRegisterSelected ? Colors.white : Colors.black,
                    fontSize: effectiveFontSize,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
