import 'package:flutter/material.dart';

class CustomPageTransitions {
  // Slide from right transition
  static PageRouteBuilder<T> slideFromRight<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: Duration(milliseconds: 300),
      reverseTransitionDuration: Duration(milliseconds: 300),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        var begin = Offset(1.0, 0.0);
        var end = Offset.zero;
        var curve = Curves.easeInOut;

        var tween = Tween(
          begin: begin,
          end: end,
        ).chain(CurveTween(curve: curve));

        return SlideTransition(position: animation.drive(tween), child: child);
      },
    );
  }

  // Fade transition
  static PageRouteBuilder<T> fadeTransition<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: Duration(milliseconds: 400),
      reverseTransitionDuration: Duration(milliseconds: 400),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );
  }

  // Scale transition
  static PageRouteBuilder<T> scaleTransition<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: Duration(milliseconds: 300),
      reverseTransitionDuration: Duration(milliseconds: 300),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        var begin = 0.0;
        var end = 1.0;
        var curve = Curves.fastOutSlowIn;

        var tween = Tween(
          begin: begin,
          end: end,
        ).chain(CurveTween(curve: curve));

        return ScaleTransition(scale: animation.drive(tween), child: child);
      },
    );
  }

  // Slide up transition
  static PageRouteBuilder<T> slideUpTransition<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: Duration(milliseconds: 300),
      reverseTransitionDuration: Duration(milliseconds: 300),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        var begin = Offset(0.0, 1.0);
        var end = Offset.zero;
        var curve = Curves.easeInOut;

        var tween = Tween(
          begin: begin,
          end: end,
        ).chain(CurveTween(curve: curve));

        return SlideTransition(position: animation.drive(tween), child: child);
      },
    );
  }

  // Combined fade and slide transition
  static PageRouteBuilder<T> fadeSlideTransition<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: Duration(milliseconds: 400),
      reverseTransitionDuration: Duration(milliseconds: 400),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        var slideBegin = Offset(0.3, 0.0);
        var slideEnd = Offset.zero;
        var curve = Curves.easeInOut;

        var slideTween = Tween(
          begin: slideBegin,
          end: slideEnd,
        ).chain(CurveTween(curve: curve));

        return SlideTransition(
          position: animation.drive(slideTween),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
    );
  }
}

// Extension to make navigation with custom transitions easier
extension CustomNavigation on BuildContext {
  Future<T?> pushWithSlide<T>(Widget page) {
    return Navigator.of(
      this,
    ).push<T>(CustomPageTransitions.slideFromRight(page));
  }

  Future<T?> pushWithFade<T>(Widget page) {
    return Navigator.of(
      this,
    ).push<T>(CustomPageTransitions.fadeTransition(page));
  }

  Future<T?> pushWithScale<T>(Widget page) {
    return Navigator.of(
      this,
    ).push<T>(CustomPageTransitions.scaleTransition(page));
  }

  Future<T?> pushReplacementWithFade<T, TO>(Widget page) {
    return Navigator.of(
      this,
    ).pushReplacement<T, TO>(CustomPageTransitions.fadeTransition(page));
  }

  Future<T?> pushReplacementWithSlide<T, TO>(Widget page) {
    return Navigator.of(
      this,
    ).pushReplacement<T, TO>(CustomPageTransitions.slideFromRight(page));
  }
}
