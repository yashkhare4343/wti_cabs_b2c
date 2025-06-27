import 'package:flutter/material.dart';

import '../../utility/constants/fonts/common_fonts.dart';

class CustomDropdownField extends StatelessWidget {
  final String? hintText;
  final String? errorText;
  final String? value;
  final List<String> items;
  final Function(String?) onChanged;

  const CustomDropdownField({
    Key? key,
    required this.hintText,
    required this.items,
    required this.onChanged,
    this.errorText,
    this.value,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      icon: const Icon(Icons.keyboard_arrow_down_rounded),
      dropdownColor: Colors.white, // popup background
      style: const TextStyle(
        color: Colors.black,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        errorText: errorText,
        errorStyle: CommonFonts.errorTextStatus,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        suffixIcon: null,

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFCCCCCC)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFCCCCCC), ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
      ),
      onChanged: onChanged,
      items: items
          .map(
            (item) => DropdownMenuItem(
          value: item,
          child: Text(item),
        ),
      )
          .toList(),
    );
  }
}
