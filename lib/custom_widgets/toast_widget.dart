import 'package:flutter/material.dart';


class ToastWidget extends StatefulWidget {
  const ToastWidget({required this.message, this.colors, super.key});
  final String message;
  final List<Color>? colors;

  @override
  _ToastWidgetState createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<ToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _opacityAnimation = Tween<double>(begin: 0, end: 1).animate(_controller);

    _controller.forward();

    Future.delayed(const Duration(seconds: 2), () async {
      if (mounted && !_controller.isDisposed) {
        await _reverseAnimation();
      }
    });
  }

  Future<void> _reverseAnimation() async {
    await _controller.reverse();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: AnimatedBuilder(
        animation: _opacityAnimation,
        builder: (context, child) {
          return Opacity(
            opacity: _opacityAnimation.value,
            child: child,
          );
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 50),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            gradient: LinearGradient(
              colors: widget.colors ?? [Colors.black.withOpacity(0.7), Colors.black.withOpacity(0.7)],
            ),
          ),
          child: Center(
            child: Text(
              widget.message,
              style: const TextStyle(color: Colors.black, fontSize: 16,fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }
}

void showToast(BuildContext context, String message, {List<Color>? colors}) {
  final overlay = Overlay.of(context);

  final screenWidth = MediaQuery.of(context).size.width;
  final screenHeight = MediaQuery.of(context).size.height;

  const toastWidth = 350.0;
  final left = (screenWidth - toastWidth) / 2;
  final top = screenHeight / 6;

  final overlayEntry = OverlayEntry(
    builder: (context) => Positioned(
      top: top,
      left: left,
      width: toastWidth,
      child: ToastWidget(
        message: message,
        colors: colors,
      ),
    ),
  );

  overlay.insert(overlayEntry);
}

extension AnimationControllerExtension on AnimationController {
  bool get isDisposed => status == AnimationStatus.dismissed;
}
