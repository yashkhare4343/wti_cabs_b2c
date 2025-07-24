import 'package:flutter/material.dart';
import 'package:wti_cabs_user/utility/constants/fonts/common_fonts.dart';

import '../../utility/constants/colors/app_colors.dart';

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
        // boxShadow: [
        //   BoxShadow(
        //     color: const Color(0x1F2C2C6F), // #2C2C6F1F
        //     blurRadius: 12,
        //     offset: const Offset(0, 3),
        //   ),
        // ],
      ),
      child: TextFormField(
        onTap: onTap,
        controller: controller,
        readOnly: true,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, size: 20, color: AppColors.greyText3),
          prefixText: prefixText,
          hintText: hintText,
          helperStyle: CommonFonts.greyTextMedium2,
          hintStyle: CommonFonts.labelText,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          filled: true,
          fillColor: Colors.transparent,

          // ✅ Default border (used when no focus or enable override exists)
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: Color(0xFFD9D9D9), // 40% black
              width: 1,
            ),
          ),

          // ✅ Enabled border
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: Color(0xFFD9D9D9), // 40% black
              width: 1,
            ),
          ),

          // ✅ Focused border
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: Color(0xFFD9D9D9), // 40% black
              width: 1,
            ),
          ),
        ),
      ),
    );
  }
}
