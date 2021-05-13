library horizontal_swipe_detector;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'dart:async';

class HorizontalSwipeDetector extends StatelessWidget {
  final Widget child;
  final Function onBack;
  final Function onForward;
  final double leftRightZone;

  const HorizontalSwipeDetector(
      {Key key,
        @required this.child,
        this.onBack,
        this.onForward,
        this.leftRightZone = 1})
      : assert(leftRightZone >= 0 && leftRightZone <= 1),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return RawGestureDetector(
      gestures: {
        _BackForwardRecognizer:
        GestureRecognizerFactoryWithHandlers<_BackForwardRecognizer>(
              () => _BackForwardRecognizer(
              onBack: onBack,
              onForward: onForward,
              context: context,
              leftRightZone: leftRightZone),
              (_BackForwardRecognizer instance) {},
        )
      },
      behavior: HitTestBehavior.opaque,
      child: child,
    );
  }
}

class _BackForwardRecognizer extends PrimaryPointerGestureRecognizer {
  final Function onBack;
  final Function onForward;
  final BuildContext context;
  final double leftRightZone;

  _BackForwardRecognizer(
      {this.onBack,
        this.onForward,
        @required this.context,
        @required this.leftRightZone});

  var _debouncer = _Debouncer(delay: Duration(milliseconds: 100));
  List<PointerEvent> events = [];

  @override
  void rejectGesture(int pointer) {
    acceptGesture(pointer);
  }

  @override
  String get debugDescription => "";

  @override
  void handlePrimaryPointer(PointerEvent event) {
    events = [...events, event];
    _debouncer(() {
      Future.delayed(Duration(milliseconds: 100), () {
        events.clear();
      });

      if (events.isEmpty || events.length <= 3) return;
      final firstEvent = events.first;
      final lastEvent = events.last;

      //check is in the leftRightZone
      final screenWidth = MediaQuery.of(context).size.width;
      final zone = screenWidth * leftRightZone;
      if (firstEvent.position.dx >= zone &&
          firstEvent.position.dx <= screenWidth - zone) return;

      //check onBack and onForward condition
      //onBack: x change more than 10, y change smaller than 5
      //onForward: x change more than -10, y change smaller than 5
      if ((lastEvent.position.dy - firstEvent.position.dy).abs() > 5) return;
      if ((lastEvent.position.dx - firstEvent.position.dx).abs() < 10) return;
      if (lastEvent.position.dx > firstEvent.position.dx) onBack?.call();
      if (lastEvent.position.dx < firstEvent.position.dx) onForward?.call();
    });
  }
}

class _Debouncer {
  final Duration delay;
  Timer _timer;

  _Debouncer({this.delay = const Duration(milliseconds: 300)});

  call(void Function() action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }
}