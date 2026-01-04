import 'package:flutter/material.dart';

/// Custom Success Snackbar matching the design
/// - Light green background
/// - Dark green circle with white checkmark on the left
/// - Medium green text
/// - Black X close icon on the right
class CustomSuccessSnackbar extends StatelessWidget {
  final String message;
  final VoidCallback? onClose;

  const CustomSuccessSnackbar({
    super.key,
    required this.message,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9), // Light green background
        borderRadius: BorderRadius.circular(24), // Heavily rounded corners
      ),
      child: Row(
        children: [
          // Dark green circle with white checkmark
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              color: Color(0xFF2E7D32), // Dark green circle
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          // Text message
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFF4CAF50), // Medium green text
                fontSize: 14,
                fontWeight: FontWeight.w500,
                fontFamily: 'Roboto', // Sans-serif font
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Black X close icon
          GestureDetector(
            onTap: onClose,
            child: const Icon(
              Icons.close,
              color: Colors.black,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }

  /// Static method to show success snackbar
  static void show(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    scaffoldMessenger.hideCurrentSnackBar();
    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: CustomSuccessSnackbar(
          message: message,
          onClose: () => scaffoldMessenger.hideCurrentSnackBar(),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        duration: duration,
        padding: EdgeInsets.zero,
      ),
    );
  }
}

/// Custom Failure Snackbar matching the design
/// - Light red/pinkish-red background
/// - Dark red circle with white exclamation mark on the left
/// - Dark red text
/// - Dark red X close icon on the right
class CustomFailureSnackbar extends StatelessWidget {
  final String message;
  final VoidCallback? onClose;

  const CustomFailureSnackbar({
    super.key,
    required this.message,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE), // Light red/pinkish-red background
        borderRadius: BorderRadius.circular(24), // Pill-shaped with rounded corners
      ),
      child: Row(
        children: [
          // Dark red circle with white exclamation mark
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              color: Color(0xFFC62828), // Dark red circle
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.error,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          // Text message
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFFC62828), // Dark red text
                fontSize: 14,
                fontWeight: FontWeight.w500,
                fontFamily: 'Roboto', // Sans-serif font
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Dark red X close icon
          GestureDetector(
            onTap: onClose,
            child: const Icon(
              Icons.close,
              color: Color(0xFFC62828), // Dark red X
              size: 18,
            ),
          ),
        ],
      ),
    );
  }

  /// Static method to show failure snackbar
  static void show(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    scaffoldMessenger.hideCurrentSnackBar();
    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: CustomFailureSnackbar(
          message: message,
          onClose: () => scaffoldMessenger.hideCurrentSnackBar(),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        duration: duration,
        padding: EdgeInsets.zero,
      ),
    );
  }
}

