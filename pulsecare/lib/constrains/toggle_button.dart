import 'package:flutter/material.dart';

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
    return Container(
      height: 60,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 227, 231, 246),
        borderRadius: BorderRadius.circular(30),
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
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  'Register',
                  style: TextStyle(
                    color: isRegisterSelected
                        ? Colors.white
                        : Colors.black,
                    fontSize: 20,
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
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  'Login',
                  style: TextStyle(
                    color: !isRegisterSelected
                        ? Colors.white
                        : Colors.black,
                    fontSize: 20,
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
