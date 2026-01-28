import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../common_widget/textformfield/crp_text_form_field.dart';
import '../../../common_widget/snackbar/custom_snackbar.dart';
import '../../../core/route_management/app_routes.dart';
import '../../../core/api/corporate/cpr_api_services.dart';
import '../../../core/services/storage_services.dart';

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
  bool _isLoading = false;

  @override
  void dispose() {
    currentPasswordController.dispose();
    newPasswordController.dispose();
    reenterPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleChangePassword() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Get email from storage
        final email = await StorageServices.instance.read('email');
        if (email == null || email.isEmpty) {
          if (context.mounted) {
            CustomFailureSnackbar.show(context, 'Email not found. Please login again.');
          }
          return;
        }

        // Prepare query parameters
        final params = <String, dynamic>{
          'emailID': email,
          'oldPassword': currentPasswordController.text,
          'password': newPasswordController.text,
          // token and user will be auto-added by postRequestParamsNew
        };

        // Call the API
        final response = await CprApiService().postRequestParamsNew<Map<String, dynamic>>(
          'PostUpdatePassword',
          params,
          (data) {
            // Handle response parsing - API service already handles JSON decoding
            if (data is Map<String, dynamic>) {
              return data;
            } else if (data is String) {
              // If response is a JSON string, try to parse it
              try {
                // Remove surrounding quotes if present
                String jsonString = data;
                if (jsonString.startsWith('"') && jsonString.endsWith('"')) {
                  jsonString = jsonString.substring(1, jsonString.length - 1);
                  // Unescape the string
                  jsonString = jsonString.replaceAll('\\"', '"');
                }
                // Try to parse as JSON
                final parsed = jsonDecode(jsonString);
                if (parsed is Map<String, dynamic>) {
                  return parsed;
                }
                // If parsing gives us a string, return it as message
                return {'bStatus': false, 'sMessage': parsed.toString()};
              } catch (e) {
                // If parsing fails, return the string as message
                return {'bStatus': false, 'sMessage': data};
              }
            }
            // Fallback for unknown types
            return {'bStatus': false, 'sMessage': 'Unknown error occurred'};
          },
          context,
        );

        // Check response status
        final bStatus = response['bStatus'] as bool? ?? false;
        final sMessage = response['sMessage'] as String? ?? 'Unknown error occurred';

        if (context.mounted) {
          if (bStatus) {
            // Success
            CustomSuccessSnackbar.show(context, sMessage.isNotEmpty ? sMessage : 'Password changed successfully');
            // Navigate back after successful password change
            context.pop();
          } else {
            // Failure
            CustomFailureSnackbar.show(context, sMessage);
          }
        }
      } catch (e) {
        if (context.mounted) {
          CustomFailureSnackbar.show(context, 'Error: ${e.toString()}');
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
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
                onTap: _isLoading ? null : _handleChangePassword,
                child: Container(
                  height: 48,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: _isLoading 
                        ? const Color(0xFF01ACF2).withOpacity(0.6)
                        : const Color(0xFF01ACF2), // Teal/blue-green color
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
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
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

