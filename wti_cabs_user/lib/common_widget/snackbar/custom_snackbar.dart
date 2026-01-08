import 'package:flutter/material.dart';

/// Helper widget for animated snackbar overlay
class _AnimatedSnackbarOverlay extends StatefulWidget {
  final Widget Function(VoidCallback closeHandler) childBuilder;
  final VoidCallback? onClose;
  final Duration duration;

  const _AnimatedSnackbarOverlay({
    required this.childBuilder,
    this.onClose,
    required this.duration,
  });

  @override
  State<_AnimatedSnackbarOverlay> createState() => _AnimatedSnackbarOverlayState();
}

class _AnimatedSnackbarOverlayState extends State<_AnimatedSnackbarOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      reverseDuration: const Duration(milliseconds: 200),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    ));

    _controller.forward();

    // Auto remove after duration
    Future.delayed(widget.duration, () {
      if (mounted) {
        _handleClose();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleClose() {
    _controller.reverse().then((_) {
      widget.onClose?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: widget.childBuilder(_handleClose),
    );
  }
}

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
    final overlay = Overlay.of(context);
    final mediaQuery = MediaQuery.of(context);
    
    OverlayEntry? overlayEntryRef;
    
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: mediaQuery.padding.top + 16,
        left: 16,
        right: 16,
        child: _AnimatedSnackbarOverlay(
          duration: duration,
          onClose: () {
            overlayEntryRef?.remove();
            overlayEntryRef = null;
          },
          childBuilder: (closeHandler) => Material(
            color: Colors.transparent,
            child: CustomSuccessSnackbar(
              message: message,
              onClose: closeHandler,
            ),
          ),
        ),
      ),
    );
    
    overlayEntryRef = overlayEntry;
    overlay.insert(overlayEntry);
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
    final overlay = Overlay.of(context);
    final mediaQuery = MediaQuery.of(context);
    
    OverlayEntry? overlayEntryRef;
    
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: mediaQuery.padding.top + 16,
        left: 16,
        right: 16,
        child: _AnimatedSnackbarOverlay(
          duration: duration,
          onClose: () {
            overlayEntryRef?.remove();
            overlayEntryRef = null;
          },
          childBuilder: (closeHandler) => Material(
            color: Colors.transparent,
            child: CustomFailureSnackbar(
              message: message,
              onClose: closeHandler,
            ),
          ),
        ),
      ),
    );
    
    overlayEntryRef = overlayEntry;
    overlay.insert(overlayEntry);
  }
}

