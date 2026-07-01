import 'package:flutter/material.dart';

class AppTextField extends StatelessWidget {
  final String placeholder;
  final bool obscureText;
  final TextInputType keyboardType;
  final TextEditingController? controller;
  final bool enabled;

  const AppTextField({
    super.key,
    required this.placeholder,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.controller,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        enabled: enabled,
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
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        ),
      ),
    );
  }
}
