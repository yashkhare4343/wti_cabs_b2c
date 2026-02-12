import 'package:flutter/material.dart';
import 'package:wti_cabs_user/common_widget/loader/custom_loader.dart';

import '../../utility/constants/colors/app_colors.dart';
import '../../utility/constants/fonts/common_fonts.dart';

class MainButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color backgroundColor;
  final bool? isIcon;
  final IconData? icon;
  final bool isLoading;
  final bool isDisabled;

  const MainButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.backgroundColor = AppColors.mainButtonBg,
    this.isIcon,
    this.icon,
    this.isLoading = false, // ✅ Optional, default false
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: (isLoading || isDisabled) ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 12),
      ),
      child: isLoading
          ? const SizedBox(
        width: 20,
        height: 20,
        child: CustomLoader(),
      )
          : isIcon == true
          ? Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(text, style: CommonFonts.mainButtonText),
          Icon(
            icon,
            color: Colors.white,
            size: 20.0,
          ),
        ],
      )
          : Text(text, style: CommonFonts.mainButtonText),
    );
  }
}
