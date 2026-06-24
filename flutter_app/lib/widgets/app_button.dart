import 'package:flutter/material.dart';

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;  // nullable to allow disabling
  final bool fullWidth;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,             // no longer required
    this.fullWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: fullWidth ? double.infinity : null,
      child: ElevatedButton(
        onPressed: onPressed,   // null automatically disables the button
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1D9E75),
          foregroundColor: const Color(0xFF04342C),
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
          elevation: 0,
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}