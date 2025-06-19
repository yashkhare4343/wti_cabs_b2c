import 'package:flutter/material.dart';
import 'package:wti_cabs_user/utility/constants/colors/app_colors.dart';
import 'package:wti_cabs_user/utility/constants/fonts/common_fonts.dart';

class BookingTextFormField extends StatefulWidget {
  final String hintText;
  final TextEditingController controller;
  final void Function()? onTap;

  final bool isError;
  final String? errorText;

  const BookingTextFormField({
    super.key,
    required this.hintText,
    required this.controller,
    this.onTap,
    this.isError = false,
    this.errorText,
  });

  @override
  State<BookingTextFormField> createState() => _BookingTextFormFieldState();
}

class _BookingTextFormFieldState extends State<BookingTextFormField> {
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      onTap: widget.onTap,
      readOnly: true,
      decoration: InputDecoration(
        hintText: widget.hintText,
        hintStyle: CommonFonts.labelText,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        filled: true,
        fillColor: Colors.white,
        suffixIcon: null,

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: widget.isError ? AppColors.errorStatusText : const Color(0xFFCCCCCC),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: widget.isError ? AppColors.errorStatusText : Colors.blue,
            width: 1.5,
          ),
        ),

        // ✅ Add these:
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.errorStatusText),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.errorStatusText, width: 1.5),
        ),

        errorText: widget.isError ? widget.errorText ?? 'Invalid region' : null,
        errorStyle: CommonFonts.errorTextStatus
      ),

    );
  }
}
