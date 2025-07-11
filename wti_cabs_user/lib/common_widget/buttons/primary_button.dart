import 'package:flutter/material.dart';

import '../../utility/constants/colors/app_colors.dart';
import '../../utility/constants/fonts/common_fonts.dart';

class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color backgroundColor;
  final bool? isIcon;
  final IconData? icon;

  // Constructor with default values for backgroundColor and borderRadius
  const PrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.backgroundColor = AppColors.purple1,  // Default to blue if no color is provided
    this.isIcon, this.icon,  // Default border radius
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,  // Set background color
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),  // Set border radius
        ),
        padding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),  // Adjust padding
      ),
      child:isIcon== true?
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [

          Text(text, style: CommonFonts.primaryButtonText,),
          Icon(
            icon,
            color: Colors.white,
            size: 20.0,
          ),

        ],
      ): Text(text, style: CommonFonts.primaryButtonText,)
    );
  }
}
