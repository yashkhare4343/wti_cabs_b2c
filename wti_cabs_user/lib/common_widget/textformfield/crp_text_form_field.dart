import 'package:flutter/material.dart';

class CprTextFormField extends StatefulWidget {
  final GlobalKey<FormFieldState>? fieldKey; // ✅ custom property
  final String hintText;
  final String? labelText;
  final TextEditingController controller;
  final bool isPassword;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final EdgeInsetsGeometry contentPadding;
  final FocusNode? focusNode;
  final void Function(String)? onFieldSubmitted;
  final void Function(String)? onChanged;

  const CprTextFormField({
    required this.controller,
    required this.hintText,
    this.labelText,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.contentPadding = const EdgeInsets.symmetric(vertical: 10, horizontal: 15), this.focusNode, this.onFieldSubmitted, this.onChanged, this.fieldKey,
  });

  @override
  State<CprTextFormField> createState() => _CprTextFormFieldState();
}

class _CprTextFormFieldState extends State<CprTextFormField> {
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: widget.fieldKey,
      controller: widget.controller,
      obscureText: widget.isPassword,
      keyboardType: widget.keyboardType,
      validator: widget.validator,
      focusNode: widget.focusNode,
      onFieldSubmitted: widget.onFieldSubmitted,
      onChanged: widget.onChanged,
      maxLength: widget.isPassword==true?10:null,
      decoration: InputDecoration(
        errorMaxLines: 2,
        labelText: widget.labelText,
        hintText: widget.hintText,
        labelStyle: const TextStyle(fontSize:14,fontWeight:FontWeight.w400,color: Color(0xFF333333)),
        hintStyle: const TextStyle(fontSize:14,fontWeight:FontWeight.w400,color: Color(0xFF333333)),
        contentPadding: widget.contentPadding,
        counterText: '',
        border: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0x1A000000), width: 1),
          borderRadius: BorderRadius.circular(10),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0x1A000000), width: 1),
          borderRadius: BorderRadius.circular(10),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.grey, width: 1),
          borderRadius: BorderRadius.circular(10),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.redAccent, width: 1),
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}
