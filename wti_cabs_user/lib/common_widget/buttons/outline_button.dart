import 'package:flutter/material.dart';

import '../../utility/constants/colors/app_colors.dart';

class CommonOutlineButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color borderColor;
  final Color textColor;
  final double borderRadius;
  final EdgeInsetsGeometry padding;

  const CommonOutlineButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.borderColor = AppColors.mainButtonBg,
    this.textColor = AppColors.mainButtonBg,
    this.borderRadius = 24.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: Colors.white,
        side: BorderSide(color: borderColor),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        padding: padding,
      ),
      child: Text(
        text,
        style: TextStyle(fontSize:12, fontWeight: FontWeight.w500, color: textColor),
      ),
    );
  }
}
