import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';

class AppPageTransition {
  static Route createRoute(Widget page, {PageTransitionType type = PageTransitionType.fade}) {
    return PageTransition(
      type: type,
      child: page,
      duration: const Duration(milliseconds: 300),
      reverseDuration: const Duration(milliseconds: 300),
    );
  }

  static Route slideUpTransition(Widget page) {
    return createRoute(page, type: PageTransitionType.bottomToTop);
  }

  static Route slideRightTransition(Widget page) {
    return createRoute(page, type: PageTransitionType.rightToLeft);
  }

  static Route fadeTransition(Widget page) {
    return createRoute(page, type: PageTransitionType.fade);
  }

  static Route scaleTransition(Widget page) {
    return createRoute(page, type: PageTransitionType.scale);
  }
}

// Custom route for hero animations with page transitions
class HeroPageRoute<T> extends PageRoute<T> {
  final Widget Function(BuildContext) builder;
  final Duration transitionDuration;
  final Duration reverseTransitionDuration;
  final bool fullscreenDialog;

  HeroPageRoute({
    required this.builder,
    this.transitionDuration = const Duration(milliseconds: 300),
    this.reverseTransitionDuration = const Duration(milliseconds: 300),
    this.fullscreenDialog = false,
  });

  @override
  bool get opaque => false;

  @override
  bool get barrierDismissible => false;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return builder(context);
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: animation,
      child: child,
    );
  }
}
