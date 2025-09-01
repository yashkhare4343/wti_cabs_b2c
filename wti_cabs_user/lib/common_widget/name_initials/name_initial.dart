import 'package:flutter/material.dart';
import 'dart:math';

import '../../utility/constants/colors/app_colors.dart';

class NameInitialCircle extends StatelessWidget {
  final String name;
  final double size;
  final double borderWidth;
  final Color? borderColor;

  const NameInitialCircle({
    Key? key,
    required this.name,
    this.size = 64,
    this.borderWidth = 0,
    this.borderColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final trimmed = name.trim();
    final letter = (trimmed.isEmpty ? '?' : trimmed.characters.first).toUpperCase();

    final bg = _colorFromString(trimmed);

    final fg = Colors.white;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: bg,
        border: borderWidth > 0
            ? Border.all(color: borderColor ?? Colors.black12, width: borderWidth)
            : null,
      ),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: TextStyle(
          fontSize: size * 0.45,
          fontWeight: FontWeight.w700,
          color: fg,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  /// Generates a stable background color from the given string
  Color _colorFromString(String input) {
    if (input.isEmpty) return AppColors.mainButtonBg;
    int hash = 0;
    for (int i = 0; i < input.length; i++) {
      hash = input.codeUnitAt(i) + ((hash << 5) - hash);
    }
    final hue = (hash.abs() % 360).toDouble();
    return HSVColor.fromAHSV(1, hue, 0.45, 0.85).toColor();
  }
}


class NameInitialHomeCircle extends StatelessWidget {
  final String name;
  final double size;
  final double borderWidth;
  final Color? borderColor;

  const NameInitialHomeCircle({
    Key? key,
    required this.name,
    this.size = 44,
    this.borderWidth = 0,
    this.borderColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final trimmed = name.trim();
    final letter = (trimmed.isEmpty ? '?' : trimmed.characters.first).toUpperCase();

    final bg = Color(0xFFEA580C);

    final fg = Colors.white;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: bg,
        border: borderWidth > 0
            ? Border.all(color: borderColor ?? Colors.black12, width: borderWidth)
            : null,
      ),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: fg,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  /// Generates a stable background color from the given string
  Color _colorFromString(String input) {
    if (input.isEmpty) return AppColors.mainButtonBg;
    int hash = 0;
    for (int i = 0; i < input.length; i++) {
      hash = input.codeUnitAt(i) + ((hash << 5) - hash);
    }
    final hue = (hash.abs() % 360).toDouble();
    return HSVColor.fromAHSV(1, hue, 0.45, 0.85).toColor();
  }
}

