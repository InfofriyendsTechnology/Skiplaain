import 'package:flutter/material.dart';

/// A premium page transition that mimics iOS-like or web-like motion.
/// It provides a smooth fade-in combined with a slide from the right.
class PremiumTransition extends PageRouteBuilder {
  final Widget page;

  PremiumTransition({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Smooth curve
            var curve = CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOutCubic,
            );

            // Slide from right
            var slideAnimation = Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(curve);

            // Smooth fade
            var fadeAnimation = Tween<double>(
              begin: 0.0,
              end: 1.0,
            ).animate(curve);

            return FadeTransition(
              opacity: fadeAnimation,
              child: SlideTransition(
                position: slideAnimation,
                child: child,
              ),
            );
          },
        );
}
