import 'package:flutter/material.dart';

class AppTextField extends StatelessWidget {
  final String placeholder;
  final bool obscureText;
  final TextInputType keyboardType;
  final TextEditingController? controller;
  final bool enabled;
  final Key? formFieldKey;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final FormFieldValidator<String>? validator;
  final AutovalidateMode? autovalidateMode;
  final String? errorText;
  final ValueChanged<String>? onFieldSubmitted;
  final VoidCallback? onEditingComplete;
  final VoidCallback? onTap;

  const AppTextField({
    super.key,
    required this.placeholder,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.controller,
    this.enabled = true,
    this.formFieldKey,
    this.focusNode,
    this.textInputAction,
    this.validator,
    this.autovalidateMode,
    this.errorText,
    this.onFieldSubmitted,
    this.onEditingComplete,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      child: TextFormField(
        key: formFieldKey,
        controller: controller,
        focusNode: focusNode,
        obscureText: obscureText,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        enabled: enabled,
        validator: validator,
        autovalidateMode: autovalidateMode,
        onFieldSubmitted: onFieldSubmitted,
        onEditingComplete: onEditingComplete,
        onTap: onTap,
        style: const TextStyle(
          fontSize: 10,
          color: Color(0xFF888780),
        ),
        decoration: InputDecoration(
          hintText: placeholder,
          hintStyle: const TextStyle(
            fontSize: 10,
            color: Color(0xFF888780),
          ),
          filled: true,
          fillColor: const Color(0xFFF1EFEA),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(
              color: Color(0xFFD3D1C7),
              width: 1,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(
              color: Color(0xFFD3D1C7),
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(
              color: Color(0xFF1D9E75),
              width: 1,
            ),
          ),
          errorText: errorText,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        ),
      ),
    );
  }
}
