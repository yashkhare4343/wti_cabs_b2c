import 'package:flutter/material.dart';

import '../colors/app_colors.dart';
// Common Fonts Class with Rubik Font
class CommonFonts {
  static const String fontFamily = 'Inter';

  // Base font style
  static TextStyle base({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.normal,
    Color color = AppColors.bodyTextPrimary,
    FontStyle fontStyle = FontStyle.normal,
  }) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      fontStyle: fontStyle,
    );
  }

  // Predefined styles
  static final TextStyle h1Purple = base(fontSize: 20, fontWeight: FontWeight.w500, color: AppColors.primary);
  static final TextStyle headline2 = base(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.headingColorSecondary);
  static final TextStyle bodyText1 = base(fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.bodyTextPrimary);
  static final TextStyle bodyText1Black = base(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black);

  static final TextStyle bodyTextSpan1 = base(fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.primary);
  static final TextStyle bodyTextSpanblack = base(fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.greyText3);
  static final TextStyle labelText = base(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.greyText3);

  static final TextStyle errorTextStatus = base(fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.errorStatusText);
  static final TextStyle h5TextHeading = base(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.secondary);
  static final TextStyle h3TextHeading = base(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.headingColorSecondary);
  static final TextStyle h3TextHeadingPrimary = base(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primary);

  static final TextStyle greytext2 = base(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.greyText1);
  static final TextStyle greytext2Light = base(fontSize: 10, fontWeight: FontWeight.w400, color: AppColors.greyText1);

  static final TextStyle greenText1Secondary = base(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.bgGreen3);

  static final TextStyle successTextStatus = base(fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.successStatusText);
  static final TextStyle bodyText4PrimarySmall = base(fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.h3ColorPrimary);
  static final TextStyle primaryButtonText = base(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.buttonPrimaryText);
  static final TextStyle primaryButtonText2 = base(fontSize: 10, fontWeight: FontWeight.w400, color: AppColors.buttonPrimaryText);

  static final TextStyle formHintTextAuth = base(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.formHintText);
  static final TextStyle prefixTextAuth = base(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.prefixAuthText);
  static final TextStyle prefixTextAuthSmall = base(fontSize: 10, fontWeight: FontWeight.w400, color: AppColors.prefixAuthText);
  static final TextStyle inputTextAuth = base(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.inputTextPrimary);
  static final TextStyle inputTextAuthLarge = base(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.inputTextPrimary);

  static final TextStyle whiteButtonText = base(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.buttonTextPrimary1);
  static final TextStyle blueText1 = base(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.bluePrimary);
  static final TextStyle greyText1 = base(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.greyText1);
  static final TextStyle greyText2 = base(fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.greyText2);
  static final TextStyle greyTextSecondary = base(fontSize: 10, fontWeight: FontWeight.w400, color: AppColors.greyText1);
  static final TextStyle bodyText5Secondary = base(fontSize: 11, fontWeight: FontWeight.w400, color: AppColors.secondary);

  static final TextStyle bodyText3 = base(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.secondary);
  static final TextStyle bodyText3Red = base(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.errorStatusText);

  static final TextStyle bodyText3Secondary = base(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.secondary);

  static final TextStyle greenText1 = base(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary);
  static final TextStyle greenTextSecondary = base(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.primary);
  static final TextStyle greenText3 = base(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.greenPrimary2);


  static final TextStyle appBarText = base(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.blue4);
  static final TextStyle bodyText4 = base(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.inputTextPrimary);
  static final TextStyle bodyText4Ternanory = base(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.inputTextPrimary);

  static final TextStyle bodyText4Primary = base(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.primary);

  static final TextStyle bodyText4Secondary = base(fontSize: 16, fontWeight: FontWeight.w400, color: AppColors.inputTextPrimary);
  static final TextStyle bodyText2Secondary = base(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.kmsText);
  static final TextStyle bodyText3ternanory = base(fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.kmsText);

  static final TextStyle bodyText5 = base(fontSize: 10, fontWeight: FontWeight.w400, color: AppColors.greyText2);
  static final TextStyle bodyText5Black = base(fontSize: 10, fontWeight: FontWeight.w400, color: Colors.black);
  static final TextStyle bodyText6Black = base(fontSize: 12, fontWeight: FontWeight.w400, color: Colors.black);

  static final TextStyle bodyText5tertiary = base(fontSize: 10, fontWeight: FontWeight.w400, color: AppColors.secondary);

  static final TextStyle bodyText2 = base(fontSize: 14);
  static final TextStyle caption = base(fontSize: 12, color: AppColors.bodyTextPrimary);
  static final TextStyle buttonTextSecondary = base(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.buttonPrimaryText);
  static final TextStyle whiteTextBold = base(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white);
  static final TextStyle whiteTextMedium = base(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white);





  // Customizable copies
  static TextStyle custom({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    FontStyle? fontStyle,
    TextStyle? baseStyle,
  }) {
    return (baseStyle ?? base()).copyWith(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      fontStyle: fontStyle,
    );
  }
}
