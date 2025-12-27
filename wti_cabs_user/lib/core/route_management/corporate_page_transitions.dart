import 'dart:io' show Platform;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../main.dart';

/// Professional page transitions inspired by Uber app
/// Provides smooth, modern animations for corporate screens
class CorporatePageTransitions {
  // Duration for transitions (Uber uses ~300ms)
  static const Duration _transitionDuration = Duration(milliseconds: 300);
  static const Curve _transitionCurve = Curves.easeInOutCubic;

  /// Slide transition from right (standard forward navigation)
  /// Similar to Uber's main navigation pattern
  static Page<T> slideFromRight<T extends Object?>(
    Widget child, {
    String? name,
    Object? arguments,
    String? restorationId,
  }) {
    return CustomTransitionPage<T>(
      child: child,
      name: name,
      arguments: arguments,
      restorationId: restorationId,
      transitionType: TransitionType.slideFromRight,
    );
  }

  /// Fade transition (for modal-like screens)
  /// Used for overlays and secondary screens
  static Page<T> fadeTransition<T extends Object?>(
    Widget child, {
    String? name,
    Object? arguments,
    String? restorationId,
  }) {
    return CustomTransitionPage<T>(
      child: child,
      name: name,
      arguments: arguments,
      restorationId: restorationId,
      transitionType: TransitionType.fade,
    );
  }

  /// Scale + fade transition (for special screens like confirmations)
  /// Creates a subtle zoom effect
  static Page<T> scaleFadeTransition<T extends Object?>(
    Widget child, {
    String? name,
    Object? arguments,
    String? restorationId,
  }) {
    return CustomTransitionPage<T>(
      child: child,
      name: name,
      arguments: arguments,
      restorationId: restorationId,
      transitionType: TransitionType.scaleFade,
    );
  }

  /// Slide from bottom (for bottom sheet style screens)
  static Page<T> slideFromBottom<T extends Object?>(
    Widget child, {
    String? name,
    Object? arguments,
    String? restorationId,
  }) {
    return CustomTransitionPage<T>(
      child: child,
      name: name,
      arguments: arguments,
      restorationId: restorationId,
      transitionType: TransitionType.slideFromBottom,
    );
  }

  /// Default transition for corporate screens (slide from right)
  static Page<T> defaultTransition<T extends Object?>(
    Widget child, {
    String? name,
    Object? arguments,
    String? restorationId,
  }) {
    return slideFromRight<T>(
      child,
      name: name,
      arguments: arguments,
      restorationId: restorationId,
    );
  }

  /// Helper for Navigator.push with custom transitions
  /// Use this instead of MaterialPageRoute or CupertinoPageRoute
  static Route<T> pushRoute<T extends Object?>(
    BuildContext context,
    Widget child, {
    TransitionType transitionType = TransitionType.slideFromRight,
  }) {
    return CustomTransitionPage<T>(
      child: child,
      transitionType: transitionType,
    ).createRoute(context);
  }
}

enum TransitionType {
  slideFromRight,
  fade,
  scaleFade,
  slideFromBottom,
}

class CustomTransitionPage<T> extends Page<T> {
  final Widget child;
  final TransitionType transitionType;

  const CustomTransitionPage({
    required this.child,
    required this.transitionType,
    super.name,
    super.arguments,
    super.restorationId,
    super.key,
  });

  @override
  Route<T> createRoute(BuildContext context) {
    if (Platform.isIOS) {
      return _createCupertinoRoute(context);
    } else {
      return _createMaterialRoute(context);
    }
  }

  Route<T> _createMaterialRoute(BuildContext context) {
    return PageRouteBuilder<T>(
      settings: this,
      pageBuilder: (context, animation, secondaryAnimation) => child,
      transitionDuration: CorporatePageTransitions._transitionDuration,
      reverseTransitionDuration: CorporatePageTransitions._transitionDuration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return _buildTransition(
          context,
          animation,
          secondaryAnimation,
          child,
        );
      },
    );
  }

  Route<T> _createCupertinoRoute(BuildContext context) {
    return CupertinoPageRoute<T>(
      settings: this,
      builder: (context) => child,
    );
  }

  Widget _buildTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    switch (transitionType) {
      case TransitionType.slideFromRight:
        return _slideFromRightTransition(animation, secondaryAnimation, child);
      case TransitionType.fade:
        return _fadeTransition(animation, secondaryAnimation, child);
      case TransitionType.scaleFade:
        return _scaleFadeTransition(animation, secondaryAnimation, child);
      case TransitionType.slideFromBottom:
        return _slideFromBottomTransition(animation, secondaryAnimation, child);
    }
  }

  /// Slide from right with fade - Uber's primary navigation style
  Widget _slideFromRightTransition(
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    const begin = Offset(1.0, 0.0);
    const end = Offset.zero;
    const curve = CorporatePageTransitions._transitionCurve;

    var slideAnimation = Tween<Offset>(begin: begin, end: end).animate(
      CurvedAnimation(
        parent: animation,
        curve: curve,
      ),
    );

    var fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: animation,
        curve: curve,
      ),
    );

    // Slide previous page slightly to the left
    var secondarySlideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-0.1, 0.0),
    ).animate(
      CurvedAnimation(
        parent: secondaryAnimation,
        curve: curve,
      ),
    );

    return SlideTransition(
      position: slideAnimation,
      child: FadeTransition(
        opacity: fadeAnimation,
        child: SlideTransition(
          position: secondarySlideAnimation,
          child: child,
        ),
      ),
    );
  }

  /// Fade transition for modal-like screens
  Widget _fadeTransition(
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: animation,
      child: child,
    );
  }

  /// Scale + fade for special screens
  Widget _scaleFadeTransition(
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    var scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(
        parent: animation,
        curve: CorporatePageTransitions._transitionCurve,
      ),
    );

    var fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: animation,
        curve: CorporatePageTransitions._transitionCurve,
      ),
    );

    return ScaleTransition(
      scale: scaleAnimation,
      child: FadeTransition(
        opacity: fadeAnimation,
        child: child,
      ),
    );
  }

  /// Slide from bottom for bottom sheet style
  Widget _slideFromBottomTransition(
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    const begin = Offset(0.0, 1.0);
    const end = Offset.zero;
    const curve = CorporatePageTransitions._transitionCurve;

    var slideAnimation = Tween<Offset>(begin: begin, end: end).animate(
      CurvedAnimation(
        parent: animation,
        curve: curve,
      ),
    );

    return SlideTransition(
      position: slideAnimation,
      child: child,
    );
  }
}

