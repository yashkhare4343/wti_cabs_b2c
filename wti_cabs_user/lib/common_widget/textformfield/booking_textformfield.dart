import 'package:flutter/material.dart';
import 'package:wti_cabs_user/utility/constants/fonts/common_fonts.dart';

class BookingTextFormField extends StatefulWidget {
  final String hintText;
  final TextEditingController controller;
  final void Function()? onTap;
  final String? errorText; // <-- Add this

  const BookingTextFormField({
    super.key,
    required this.hintText,
    required this.controller,
    this.onTap,
    this.errorText, // <-- Add this
  });

  @override
  State<BookingTextFormField> createState() => _BookingTextFormFieldState();
}

class _BookingTextFormFieldState extends State<BookingTextFormField> {
  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorText != null;

    return TextFormField(
      controller: widget.controller,
      onTap: widget.onTap,
      readOnly: true,
      decoration: InputDecoration(
        hintText: widget.hintText,
        errorText: widget.errorText,
        errorStyle: CommonFonts.errorTextStatus,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        filled: true,
        fillColor: Colors.white,
        suffixIcon: null,

        // ✅ Normal border
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Color(0xFFCCCCCC)),
        ),

        // ✅ Border when focused
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.blue, width: 1.5),
        ),

        // ✅ Border when error is active
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.red, width: 1.5),
        ),

        // ✅ Border when focused and error is active
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.red, width: 1.5),
        ),
      ),
    );
  }
}
