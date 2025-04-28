import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class AnimationConfigs {
  // Durations
  static const Duration fast = Duration(milliseconds: 300);
  static const Duration medium = Duration(milliseconds: 500);
  static const Duration slow = Duration(milliseconds: 800);
  
  // Curves
  static const Curve defaultCurve = Curves.easeInOut;
  static const Curve bouncyCurve = Curves.elasticOut;
  static const Curve sharpCurve = Curves.easeOutQuart;
  
  // Animation distances
  static const double smallDistance = 30.0;
  static const double mediumDistance = 60.0;
  static const double largeDistance = 100.0;
}

class AnimatedListItem extends StatelessWidget {
  final Widget child;
  final int index;
  final bool horizontalAnimation;
  final Duration duration;
  final double verticalOffset;
  final double horizontalOffset;

  const AnimatedListItem({
    Key? key,
    required this.child,
    required this.index,
    this.horizontalAnimation = false,
    this.duration = const Duration(milliseconds: 375),
    this.verticalOffset = 50.0,
    this.horizontalOffset = 50.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimationConfiguration.staggeredList(
      position: index,
      duration: duration,
      child: horizontalAnimation
          ? SlideAnimation(
              horizontalOffset: horizontalOffset,
              child: FadeInAnimation(
                child: child,
              ),
            )
          : SlideAnimation(
              verticalOffset: verticalOffset,
              child: FadeInAnimation(
                child: child,
              ),
            ),
    );
  }
}

class AnimatedGridItem extends StatelessWidget {
  final Widget child;
  final int index;
  final int columnCount;
  final Duration duration;

  const AnimatedGridItem({
    Key? key,
    required this.child,
    required this.index,
    this.columnCount = 2,
    this.duration = const Duration(milliseconds: 375),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimationConfiguration.staggeredGrid(
      position: index,
      duration: duration,
      columnCount: columnCount,
      child: ScaleAnimation(
        child: FadeInAnimation(
          child: child,
        ),
      ),
    );
  }
}

// Extension methods for easy animation
extension AnimatedWidgetExtension on Widget {
  Widget fadeIn({
    Duration duration = const Duration(milliseconds: 500),
    Curve curve = Curves.easeInOut,
    double from = 0.0,
  }) {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: AlwaysStoppedAnimation(from),
        curve: Interval(from, 1.0, curve: curve),
      ),
      child: this,
    );
  }
  
  Widget slideIn({
    Duration duration = const Duration(milliseconds: 500),
    Curve curve = Curves.easeInOut,
    Offset offset = const Offset(0.0, 50.0),
  }) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: offset,
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: AlwaysStoppedAnimation(1.0),
        curve: curve,
      )),
      child: this,
    );
  }
}
