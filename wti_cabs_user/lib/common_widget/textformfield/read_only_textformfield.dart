import 'package:flutter/material.dart';
import 'package:wti_cabs_user/utility/constants/fonts/common_fonts.dart';

class ReadOnlyTextFormField extends StatelessWidget {
  final TextEditingController controller;
  final IconData icon;
  final String prefixText;
  final String hintText;
  final void Function()? onTap;

  const ReadOnlyTextFormField({
    super.key,
    required this.controller,
    required this.icon,
    required this.prefixText,
    this.hintText = '', this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white, // White background
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0x1F2C2C6F), // #2C2C6F1F
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextFormField(
        onTap: onTap,
        controller: controller,
        readOnly: true,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, size: 20,),
          prefixText: prefixText,
          hintText: hintText,
          hintStyle: CommonFonts.labelText,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none, // Remove default border
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          filled: true,
          fillColor: Colors.transparent, // Transparent because Container already has white
        ),
      ),
    );
  }
}
