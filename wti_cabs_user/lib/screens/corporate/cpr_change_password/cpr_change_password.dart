import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../common_widget/textformfield/crp_text_form_field.dart';
import '../../../core/route_management/app_routes.dart';

class CprChangePassword extends StatefulWidget {
  const CprChangePassword({super.key});

  @override
  State<CprChangePassword> createState() => _CprChangePasswordState();
}

class _CprChangePasswordState extends State<CprChangePassword> {
  final TextEditingController currentPasswordController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController reenterPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureReenterPassword = true;

  @override
  void dispose() {
    currentPasswordController.dispose();
    newPasswordController.dispose();
    reenterPasswordController.dispose();
    super.dispose();
  }

  void _handleChangePassword() {
    if (_formKey.currentState?.validate() ?? false) {
      // TODO: Implement password change API call
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password changed successfully'),
          backgroundColor: Colors.green,
        ),
      );
      // Navigate back after successful password change
      if (context.mounted) {
        context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: TextButton(
          onPressed: () => context.pop(),
          child: const Icon(Icons.arrow_back_ios, size: 20, color: Color(0xFF000000),),
        ),
        centerTitle: true,
        title: const Text(
          'Change password',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              // Password requirements section
              const Text(
                'To create a secure password:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 16),
              _buildRequirementItem('Use at least 8 characters'),
              const SizedBox(height: 8),
              _buildRequirementItem(
                  'Use a mix of letters, numbers, and special characters (e.g.: #\$!%)'),
              const SizedBox(height: 8),
              _buildRequirementItem(
                  'Try combining words and symbols into a unique phrase'),
              const SizedBox(height: 32),
              // Current password field
              CprTextFormField(
                controller: currentPasswordController,
                hintText: 'Current password',
                labelText: 'Current password',
                isPassword: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Current password is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // New password field
              CprTextFormField(
                controller: newPasswordController,
                hintText: 'New password',
                labelText: 'New password',
                isPassword: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'New password is required';
                  }
                  if (value.length < 8) {
                    return 'Password must be at least 8 characters';
                  }
                  // Check for mix of letters, numbers, and special characters
                  final hasLetter = value.contains(RegExp(r'[a-zA-Z]'));
                  final hasNumber = value.contains(RegExp(r'[0-9]'));
                  final hasSpecialChar =
                      value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
                  if (!hasLetter || !hasNumber || !hasSpecialChar) {
                    return 'Password must include letters, numbers, and special characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Reenter password field
              CprTextFormField(
                controller: reenterPasswordController,
                hintText: 'Reenter your new password',
                labelText: 'Reenter your new password',
                isPassword: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please reenter your new password';
                  }
                  if (value != newPasswordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              // Change password button
              GestureDetector(
                onTap: _handleChangePassword,
                child: Container(
                  height: 48,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFF01ACF2), // Teal/blue-green color
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0x2203A9F4),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'Change password',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRequirementItem(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 6, right: 8),
          child: Icon(
            Icons.circle,
            size: 6,
            color: Colors.black,
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}

