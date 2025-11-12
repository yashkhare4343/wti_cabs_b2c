import 'package:flutter/material.dart';

class CprSelectBox extends StatelessWidget {
  final String labelText;
  final String hintText;
  final List<String> items;
  final String? selectedValue;
  final Function(String?) onChanged;
  final String? Function(String?)? validator;
  final EdgeInsetsGeometry? contentPadding;

  const CprSelectBox({
    super.key,
    required this.labelText,
    required this.hintText,
    required this.items,
    required this.selectedValue,
    required this.onChanged,
    this.validator,
    this.contentPadding,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: selectedValue,
      validator: validator,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        labelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: Color(0xFF333333),
        ),
        hintStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: Color(0xFF333333),
        ),
        contentPadding:
        contentPadding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0x1A000000), width: 1),
          borderRadius: BorderRadius.circular(10),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0x1A000000), width: 1),
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black54),

      // 👇 Add white background to dropdown menu
      dropdownColor: Colors.white,

      // 👇 Style for the selected text
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: Color(0xFF333333),
      ),

      // 👇 Customize dropdown menu margin
      menuMaxHeight: 300,
      borderRadius: BorderRadius.circular(12),

      // This part renders each item in the list
      items: items
          .map((value) => DropdownMenuItem(
        value: value,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16), // 👈 margin inside menu
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Color(0xFF333333),
            ),
          ),
        ),
      ))
          .toList(),
      onChanged: onChanged,
    );
  }
}
