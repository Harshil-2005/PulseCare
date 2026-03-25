import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pulsecare/utils/app_responsive.dart';

class AppTextField extends StatelessWidget {
  final String hintText;

  final String? prefixIconPath;
  final String? suffixIconPath;

  final Color? prefixIconColor;
  final Color? suffixIconColor;

  final double textSize;
  final Color? textColor;
  final Color? cursorColor;

  final TextEditingController? controller;
  final TextInputType keyboardType;
  final bool obscureText;
  final VoidCallback? onSuffixTap;
  final String? Function(String?)? validator;
  final AutovalidateMode autovalidateMode;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final FocusNode? focusNode;

  const AppTextField({
    super.key,
    required this.hintText,
    this.prefixIconPath,
    this.suffixIconPath,
    this.prefixIconColor,
    this.suffixIconColor,
    this.textSize = 16,
    this.textColor,
    this.cursorColor,
    this.controller,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.onSuffixTap,
    this.validator,
    this.autovalidateMode = AutovalidateMode.disabled,
    this.textInputAction,
    this.autofillHints,
    this.onSubmitted,
    this.onChanged,
    this.focusNode,
  });

  bool _isSvg(String path) => path.toLowerCase().endsWith('.svg');

  Widget? _buildIcon(String? path, Color? color, {VoidCallback? onTap}) {
    if (path == null) return null;

    final icon = _isSvg(path)
        ? SvgPicture.asset(
            path,
            colorFilter: color == null
                ? null
                : ColorFilter.mode(color, BlendMode.srcIn),
          )
        : Image.asset(path, color: color);

    final widget = SizedBox(width: 48, child: Center(child: icon));

    return onTap != null
        ? GestureDetector(onTap: onTap, child: widget)
        : widget;
  }

  @override
  Widget build(BuildContext context) {
    final effectiveTextSize = AppResponsive.compactPx(context, textSize);
    final effectiveRadius = AppResponsive.compactPx(context, 30);
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      autovalidateMode: autovalidateMode,
      textInputAction: textInputAction,
      autofillHints: autofillHints,
      onFieldSubmitted: onSubmitted,
      onChanged: onChanged,
      style: TextStyle(
        fontSize: effectiveTextSize,
        color: textColor ?? Colors.black,
      ),
      cursorColor: cursorColor ?? textColor ?? Colors.black,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          fontSize: effectiveTextSize,
          color: Colors.grey.shade400,
        ),
        prefixIcon: _buildIcon(prefixIconPath, prefixIconColor),
        suffixIcon: _buildIcon(
          suffixIconPath,
          suffixIconColor,
          onTap: onSuffixTap,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(effectiveRadius),
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(effectiveRadius),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(effectiveRadius),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(effectiveRadius),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.4),
        ),
      ),
    );
  }
}
