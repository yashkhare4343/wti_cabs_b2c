import 'package:flutter/material.dart';

class BookingTextFormField extends StatefulWidget {
  final String hintText;
  final TextEditingController controller;
  final void Function()? onTap;

  const BookingTextFormField({
    super.key,
    required this.hintText,
    required this.controller, this.onTap,
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        filled: true,
        fillColor: Colors.white,
        suffixIcon: null,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFCCCCCC)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.blue, width: 1.5),
        ),
      ),
    );
  }
}
