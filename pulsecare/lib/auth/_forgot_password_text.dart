import 'package:flutter/material.dart';

class _ForgotPasswordText extends StatefulWidget {
  final VoidCallback onTap;
  const _ForgotPasswordText({required this.onTap});

  @override
  State<_ForgotPasswordText> createState() => _ForgotPasswordTextState();
}

class _ForgotPasswordTextState extends State<_ForgotPasswordText> {
  bool _pressed = false;

  void _handleTapDown(TapDownDetails details) {
    setState(() => _pressed = true);
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _pressed = false);
  }

  void _handleTapCancel() {
    setState(() => _pressed = false);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: AnimatedDefaultTextStyle(
        duration: const Duration(milliseconds: 100),
        style: TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.w500,
          fontSize: 14,
          decoration: _pressed ? TextDecoration.underline : TextDecoration.none,
          decorationColor: Theme.of(context).primaryColor,
          decorationThickness: 2,
        ),
        child: const Text("Forgot password?"),
      ),
    );
  }
}
