import 'package:flutter/material.dart';

import '../../utility/constants/colors/app_colors.dart';
import '../../utility/constants/fonts/common_fonts.dart';

class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color backgroundColor;
  final bool? isIcon;
  final IconData? icon;
  final bool isLoading;

  // Constructor with default values for backgroundColor and borderRadius
  const PrimaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.backgroundColor = AppColors.purple1,  // Default to blue if no color is provided
    this.isIcon, this.icon,  // Default border radius
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveOnPressed = isLoading ? null : onPressed;
    final isDisabled = effectiveOnPressed == null;
    
    return ElevatedButton(
      onPressed: effectiveOnPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isDisabled 
            ? backgroundColor.withOpacity(0.4) 
            : backgroundColor,  // Set background color
        foregroundColor: Colors.white,
        disabledBackgroundColor: backgroundColor.withOpacity(0.4),
        disabledForegroundColor: Colors.white.withOpacity(0.7),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),  // Set border radius
        ),
        padding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),  // Adjust padding
      ),
      child: isLoading
          ? const SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : (isIcon == true
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      text,
                      style: CommonFonts.primaryButtonText,
                    ),
                    Icon(
                      icon,
                      color: Colors.white,
                      size: 20.0,
                    ),
                  ],
                )
              : Text(
                  text,
                  style: CommonFonts.primaryButtonText,
                )),
    );
  }
}
