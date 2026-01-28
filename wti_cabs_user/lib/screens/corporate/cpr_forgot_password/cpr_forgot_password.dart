import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:another_flushbar/flushbar.dart';
import '../../../core/route_management/app_routes.dart';
import '../../../core/services/storage_services.dart';
import '../../../core/api/corporate/cpr_api_services.dart';

class CprForgotPassword extends StatefulWidget {
  const CprForgotPassword({super.key});

  @override
  State<CprForgotPassword> createState() => _CprForgotPasswordState();
}

class _CprForgotPasswordState extends State<CprForgotPassword> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController otpController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isEmailValid = false;
  bool _isLoading = false;
  bool _showOtpFields = false;
  bool _emailLocked = false;
  bool _obscurePassword = true;
  String? _errorMessage;
  String? _successMessage;
  int _resendTimer = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadSavedEmail();
  }

  Future<void> _loadSavedEmail() async {
    final savedEmail = await StorageServices.instance.read('email') ?? '';
    if (savedEmail.isNotEmpty && mounted) {
      emailController.text = savedEmail;
      _validateEmail(savedEmail);
    }
  }

  void _validateEmail(String email) {
    final isValid = email.isNotEmpty && email.contains('@');
    setState(() {
      _isEmailValid = isValid;
    });
  }

  @override
  void dispose() {
    emailController.dispose();
    otpController.dispose();
    newPasswordController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    _resendTimer = 30;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_resendTimer > 0) {
            _resendTimer--;
          } else {
            timer.cancel();
          }
        });
      }
    });
  }

  Future<void> _handleContinue() async {
    if (!_showOtpFields) {
      // First step: Send OTP
      if (_formKey.currentState?.validate() ?? false) {
        await _sendOtp();
      }
    } else {
      // Second step: Verify OTP and reset password
      if (_formKey.currentState?.validate() ?? false) {
        await _resetPassword();
      }
    }
  }

  Future<void> _sendOtp() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final email = emailController.text.trim();
      
      // URL encode the email to handle special characters
      final encodedEmail = Uri.encodeComponent(email);
      
      // Build the full URL
      final baseUrl = '${CprApiService().baseUrl}';
      final url = Uri.parse('$baseUrl/GetSendPassOTP?Email=$encodedEmail');
      
      // Get token for authorization
      final token = await StorageServices.instance.read('crpKey');
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': token != null
            ? 'Basic $token'
            : 'Basic ${base64Encode(utf8.encode('harsh:123'))}',
      };

      // Make the HTTP GET request
      final httpResponse = await http.get(url, headers: headers);

      if (mounted) {
        // Check status code explicitly
        if (httpResponse.statusCode == 200) {
          // Parse the response body
          dynamic body = jsonDecode(httpResponse.body);
          
          // Handle double-encoded JSON strings (as per API service pattern)
          if (body is String) {
            if (body.startsWith('"') && body.endsWith('"')) {
              body = jsonDecode(body);
            }
            if (body is String && 
                ((body.startsWith('{') && body.endsWith('}')) ||
                 (body.startsWith('[') && body.endsWith(']')))) {
              body = jsonDecode(body);
            }
          }
          
          // Extract GuestID and message
          Map<String, dynamic> responseMap;
          if (body is Map<String, dynamic>) {
            responseMap = body;
          } else {
            responseMap = {};
          }
          
          dynamic guestIdValue = responseMap['GuestID'];
          int guestId = 0;
          
          // Handle different response formats
          if (guestIdValue is int) {
            guestId = guestIdValue;
          } else if (guestIdValue is String) {
            guestId = int.tryParse(guestIdValue) ?? 0;
          } else if (guestIdValue != null) {
            guestId = int.tryParse(guestIdValue.toString()) ?? 0;
          }

          final message = responseMap['sMessage'] as String? ?? '';

          // If GuestID == 0 and status code is 200, show error with resend button
          if (guestId == 0) {
            setState(() {
              _errorMessage = message.isNotEmpty 
                  ? message 
                  : 'User not found. Please check your email address.';
              _isLoading = false;
            });
            _startResendTimer();
          } else {
            // If GuestID != 0, show OTP fields and lock email
            setState(() {
              _showOtpFields = true;
              _emailLocked = true;
              _isLoading = false;
              _errorMessage = null;
              _successMessage = null;
            });
            
            // Show success flushbar for 1 second
            final successMessage = message.isNotEmpty 
                ? message 
                : 'OTP sent successfully to your email address.';
            
            Flushbar(
              flushbarPosition: FlushbarPosition.TOP,
              margin: const EdgeInsets.all(12),
              borderRadius: BorderRadius.circular(12),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 1),
              icon: const Icon(Icons.check_circle, color: Colors.white),
              messageText: Text(
                successMessage,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ).show(context);
          }
        } else {
          // Handle non-200 status codes
          setState(() {
            _isLoading = false;
            _errorMessage = 'Failed to send OTP. Please try again.';
          });
          _startResendTimer();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to send OTP. Please try again.';
        });
        _startResendTimer();
      }
    }
  }

  Future<void> _resetPassword() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final otp = otpController.text.trim();
      final email = emailController.text.trim();
      final password = newPasswordController.text.trim();

      // URL encode the parameters to handle special characters
      final encodedOtp = Uri.encodeComponent(otp);
      final encodedEmail = Uri.encodeComponent(email);
      final encodedPassword = Uri.encodeComponent(password);

      // Build the full URL
      final baseUrl = '${CprApiService().baseUrl}';
      final url = Uri.parse(
          '$baseUrl/GetCheckPassOTP?OTP=$encodedOtp&EmailID=$encodedEmail&Password=$encodedPassword');

      // Get token for authorization
      final token = await StorageServices.instance.read('crpKey');
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': token != null
            ? 'Basic $token'
            : 'Basic ${base64Encode(utf8.encode('harsh:123'))}',
      };

      // Make the HTTP GET request
      final httpResponse = await http.get(url, headers: headers);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // Check status code explicitly
        if (httpResponse.statusCode == 200) {
          // Parse the response body
          dynamic body = jsonDecode(httpResponse.body);

          // Handle double-encoded JSON strings (as per API service pattern)
          if (body is String) {
            if (body.startsWith('"') && body.endsWith('"')) {
              body = jsonDecode(body);
            }
            if (body is String &&
                ((body.startsWith('{') && body.endsWith('}')) ||
                    (body.startsWith('[') && body.endsWith(']')))) {
              body = jsonDecode(body);
            }
          }

          // Extract bStatus and message
          Map<String, dynamic> responseMap;
          if (body is Map<String, dynamic>) {
            responseMap = body;
          } else {
            responseMap = {};
          }

          final bStatus = responseMap['bStatus'] as bool? ?? false;
          dynamic messageValue = responseMap['sMessage'];
          String message = '';
          
          // Extract only the message text, handling different formats
          if (messageValue != null) {
            if (messageValue is String) {
              // If message contains comma-separated values, extract only the message part
              // Handle cases like "1,msg,12121" or just "msg"
              final parts = messageValue.split(',');
              // Find the part that looks like a message (not a number)
              for (var part in parts) {
                final trimmed = part.trim();
                // If it's not a number and not empty, it's likely the message
                if (trimmed.isNotEmpty && 
                    !RegExp(r'^-?\d+$').hasMatch(trimmed) && 
                    trimmed.toLowerCase() != 'true' && 
                    trimmed.toLowerCase() != 'false') {
                  message = trimmed;
                  break;
                }
              }
              // If no message found in parts, use the original string if it doesn't look like numbers
              if (message.isEmpty && !RegExp(r'^[\d,\s]+$').hasMatch(messageValue)) {
                message = messageValue;
              }
            } else {
              message = messageValue.toString();
            }
          }

          if (bStatus == true) {
            // Show success flushbar
            Flushbar(
              flushbarPosition: FlushbarPosition.TOP,
              margin: const EdgeInsets.all(12),
              borderRadius: BorderRadius.circular(12),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
              icon: const Icon(Icons.check_circle, color: Colors.white),
              messageText: Text(
                message.isNotEmpty
                    ? message
                    : 'Password reset successfully!',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ).show(context);

            // Navigate back to sign in screen after flushbar duration
            await Future.delayed(const Duration(seconds: 1));
            
            // Navigate to sign in screen - ensure we're still mounted
            if (!mounted) return;
            
            // Get the GoRouter instance and try .go() method
            final router = GoRouter.of(context);
            
            // Debug: Print current location
            debugPrint('Current route: ${router.routerDelegate.currentConfiguration.uri}');
            debugPrint('Navigating to: ${AppRoutes.cprLogin}');
            
            // Try .go() method - this should replace the current route
            try {
              // Use go() method directly on the router
              router.push(AppRoutes.cprLogin);
              debugPrint('Successfully called router.go()');
            } catch (e, stackTrace) {
              debugPrint('Error with router.go(): $e');
              debugPrint('Stack trace: $stackTrace');
              
              // If router.go() fails, try context.go() extension method
              if (mounted) {
                try {
                  context.push(AppRoutes.cprLogin);
                  debugPrint('Successfully called context.go()');
                } catch (e2) {
                  debugPrint('Error with context.go(): $e2');
                  // Last resort: use push if go() doesn't work
                  if (mounted) {
                    debugPrint('Falling back to context.push()');
                    context.push(AppRoutes.cprLogin);
                  }
                }
              }
            }
          } else {
            // Show error flushbar
            Flushbar(
              flushbarPosition: FlushbarPosition.TOP,
              margin: const EdgeInsets.all(12),
              borderRadius: BorderRadius.circular(12),
              backgroundColor: Colors.redAccent,
              duration: const Duration(seconds: 3),
              icon: const Icon(Icons.error, color: Colors.white),
              messageText: Text(
                message.isNotEmpty
                    ? message
                    : 'Failed to reset password. Please try again.',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ).show(context);
          }
        } else {
          // Handle non-200 status codes
          Flushbar(
            flushbarPosition: FlushbarPosition.TOP,
            margin: const EdgeInsets.all(12),
            borderRadius: BorderRadius.circular(12),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 3),
            icon: const Icon(Icons.error, color: Colors.white),
            messageText: const Text(
              'Failed to reset password. Please try again.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ).show(context);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        Flushbar(
          flushbarPosition: FlushbarPosition.TOP,
          margin: const EdgeInsets.all(12),
          borderRadius: BorderRadius.circular(12),
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 3),
          icon: const Icon(Icons.error, color: Colors.white),
          messageText: const Text(
            'Failed to reset password. Please try again.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ).show(context);
      }
    }
  }

  Future<void> _handleResend() async {
    if (_resendTimer > 0) return;
    await _sendOtp();
  }

  Future<void> _resendOtpFromOtpScreen() async {
    if (_resendTimer > 0 || _isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final email = emailController.text.trim();
      
      // URL encode the email to handle special characters
      final encodedEmail = Uri.encodeComponent(email);
      
      // Build the full URL
      final baseUrl = '${CprApiService().baseUrl}';
      final url = Uri.parse('$baseUrl/GetSendPassOTP?Email=$encodedEmail');
      
      // Get token for authorization
      final token = await StorageServices.instance.read('crpKey');
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': token != null
            ? 'Basic $token'
            : 'Basic ${base64Encode(utf8.encode('harsh:123'))}',
      };

      // Make the HTTP GET request
      final httpResponse = await http.get(url, headers: headers);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // Check status code explicitly
        if (httpResponse.statusCode == 200) {
          // Parse the response body
          dynamic body = jsonDecode(httpResponse.body);
          
          // Handle double-encoded JSON strings
          if (body is String) {
            if (body.startsWith('"') && body.endsWith('"')) {
              body = jsonDecode(body);
            }
            if (body is String && 
                ((body.startsWith('{') && body.endsWith('}')) ||
                 (body.startsWith('[') && body.endsWith(']')))) {
              body = jsonDecode(body);
            }
          }
          
          // Extract GuestID and message
          Map<String, dynamic> responseMap;
          if (body is Map<String, dynamic>) {
            responseMap = body;
          } else {
            responseMap = {};
          }
          
          dynamic guestIdValue = responseMap['GuestID'];
          int guestId = 0;
          
          // Handle different response formats
          if (guestIdValue is int) {
            guestId = guestIdValue;
          } else if (guestIdValue is String) {
            guestId = int.tryParse(guestIdValue) ?? 0;
          } else if (guestIdValue != null) {
            guestId = int.tryParse(guestIdValue.toString()) ?? 0;
          }

          final message = responseMap['sMessage'] as String? ?? '';

          if (guestId != 0) {
            // Clear OTP field only
            otpController.clear();
            
            // Start resend timer
            _startResendTimer();
            
            // Show success message
            Flushbar(
              flushbarPosition: FlushbarPosition.TOP,
              margin: const EdgeInsets.all(12),
              borderRadius: BorderRadius.circular(12),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
              icon: const Icon(Icons.check_circle, color: Colors.white),
              messageText: const Text(
                'A new OTP has been sent',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ).show(context);
          } else {
            // Show error if resend failed
            Flushbar(
              flushbarPosition: FlushbarPosition.TOP,
              margin: const EdgeInsets.all(12),
              borderRadius: BorderRadius.circular(12),
              backgroundColor: Colors.redAccent,
              duration: const Duration(seconds: 3),
              icon: const Icon(Icons.error, color: Colors.white),
              messageText: Text(
                message.isNotEmpty 
                    ? message 
                    : 'Failed to resend OTP. Please try again.',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ).show(context);
          }
        } else {
          // Handle non-200 status codes
          Flushbar(
            flushbarPosition: FlushbarPosition.TOP,
            margin: const EdgeInsets.all(12),
            borderRadius: BorderRadius.circular(12),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 3),
            icon: const Icon(Icons.error, color: Colors.white),
            messageText: const Text(
              'Failed to resend OTP. Please try again.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ).show(context);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        Flushbar(
          flushbarPosition: FlushbarPosition.TOP,
          margin: const EdgeInsets.all(12),
          borderRadius: BorderRadius.circular(12),
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 3),
          icon: const Icon(Icons.error, color: Colors.white),
          messageText: const Text(
            'Failed to resend OTP. Please try again.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ).show(context);
      }
    }
  }

  void _handleChangeEmail() {
    // Clear OTP and password fields
    otpController.clear();
    newPasswordController.clear();
    
    // Reset state to go back to email input screen
    setState(() {
      _showOtpFields = false;
      _emailLocked = false;
      _errorMessage = null;
      _successMessage = null;
      _resendTimer = 0;
      _timer?.cancel();
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (!didPop) {
          context.pop();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Back button
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
                      child: GestureDetector(
                        onTap: () {
                          context.pop();
                        },
                        child: const Icon(
                          Icons.arrow_back,
                          color: Colors.black,
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Title
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Forgot Password',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF000000),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Description text
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _showOtpFields
                              ? "Enter the OTP sent to your email and \n set your new password."
                              : "We'll send you an OTP to the email address \n you signed up with.",
                          maxLines: 2,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF666666),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    // Email input field with checkmark
                    TextFormField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      enabled: !_emailLocked,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Email is required";
                        }
                        if (!value.contains("@")) {
                          return "Enter a valid email";
                        }
                        return null;
                      },
                      onChanged: (value) {
                        if (!_emailLocked) {
                          _validateEmail(value);
                        }
                      },
                      decoration: InputDecoration(
                        labelText: "Email",
                        hintText: "Enter your email",
                        labelStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF333333),
                        ),
                        hintStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF333333),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 15,
                        ),
                        border: OutlineInputBorder(
                          borderSide: const BorderSide(
                            color: Color(0x1A000000),
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(
                            color: Color(0x1A000000),
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(
                            color: Colors.grey,
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderSide: const BorderSide(
                            color: Colors.redAccent,
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        suffixIcon: _isEmailValid && emailController.text.isNotEmpty
                            ? Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Container(
                                  width: 24,
                                  height: 24,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF4CAF50),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              )
                            : null,
                      ),
                    ),
                    // Error message with resend button
                    if (_errorMessage != null && !_showOtpFields) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _errorMessage!,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: _resendTimer > 0 ? null : _handleResend,
                                  child: Text(
                                    _resendTimer > 0
                                        ? 'Resend OTP (${_resendTimer}s)'
                                        : 'Resend OTP',
                                    style: TextStyle(
                                      color: _resendTimer > 0
                                          ? Colors.grey
                                          : const Color(0xFF4082F1),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                    // OTP and New Password fields
                    if (_showOtpFields) ...[
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: otpController,
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "OTP is required";
                          }
                          if (value.length < 4) {
                            return "Enter a valid OTP";
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          labelText: "OTP",
                          hintText: "Enter OTP",
                          labelStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF333333),
                          ),
                          hintStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF333333),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 15,
                          ),
                          border: OutlineInputBorder(
                            borderSide: const BorderSide(
                              color: Color(0x1A000000),
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: const BorderSide(
                              color: Color(0x1A000000),
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(
                              color: Colors.grey,
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderSide: const BorderSide(
                              color: Colors.redAccent,
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: newPasswordController,
                        obscureText: _obscurePassword,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "New password is required";
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          labelText: "New Password",
                          hintText: "Enter new password",
                          labelStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF333333),
                          ),
                          hintStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF333333),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 15,
                          ),
                          border: OutlineInputBorder(
                            borderSide: const BorderSide(
                              color: Color(0x1A000000),
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: const BorderSide(
                              color: Color(0x1A000000),
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(
                              color: Colors.grey,
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderSide: const BorderSide(
                              color: Colors.redAccent,
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: const Color(0xFF333333),
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                      ),
                      // Resend OTP and Change Email buttons
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Change Email button
                          TextButton(
                            onPressed: _isLoading ? null : _handleChangeEmail,
                            child: const Text(
                              'Change Email',
                              style: TextStyle(
                                color: Color(0xFF4082F1),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          // Resend OTP button
                          TextButton(
                            onPressed: (_resendTimer > 0 || _isLoading) 
                                ? null 
                                : _resendOtpFromOtpScreen,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (_isLoading)
                                  const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Color(0xFF4082F1),
                                    ),
                                  )
                                else
                                  Text(
                                    _resendTimer > 0
                                        ? 'Resend OTP (${_resendTimer}s)'
                                        : 'Resend OTP',
                                    style: TextStyle(
                                      color: (_resendTimer > 0 || _isLoading)
                                          ? Colors.grey
                                          : const Color(0xFF4082F1),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 40),
                    // Continue button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : () {
                          _handleContinue();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4082F1),
                          padding: const EdgeInsets.only(top: 14, right: 16, bottom: 14, left: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(39),
                            side: const BorderSide(color: Color(0xFFD9D9D9), width: 1),
                          ),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_isLoading)
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            else
                              Text(
                                _showOtpFields ? 'Reset Password' : 'Continue',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                          ],
                        ),
                      ),
                    )                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

