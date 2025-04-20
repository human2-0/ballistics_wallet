import 'package:flutter/material.dart';

class ToastWidget extends StatefulWidget {
  const ToastWidget(
      {required this.message,
      this.colors,
      this.backgroundShadow,
      this.textColor,
      super.key,});
  final String message;
  final List<Color>? colors;
  final Color? backgroundShadow;
  final Color? textColor;

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
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        child: AnimatedBuilder(
          animation: _opacityAnimation,
          builder: (context, child) => Opacity(
            opacity: _opacityAnimation.value,
            child: child,
          ),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 50),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: widget.backgroundShadow?.withValues(alpha: 0.4) ??
                      Colors.green[500]!.withValues(alpha: 0.4),
                  offset: const Offset(-10, -10),
                  blurRadius: 10,
                  spreadRadius: -5,
                ),
                BoxShadow(
                  color: widget.backgroundShadow?.withValues(alpha: 0.4) ??
                      Colors.green.withValues(alpha: 0.4),
                  offset: const Offset(5, 5),
                  blurRadius: 15,
                  spreadRadius: -5,
                ),
              ],
              borderRadius: BorderRadius.circular(25),
              gradient: LinearGradient(
                colors: widget.colors ??
                    [
                      Colors.black.withValues(alpha: 0.7),
                      Colors.black.withValues(alpha: 0.7),
                    ],
              ),
            ),
            child: Center(
              child: Text(
                widget.message,
                style: TextStyle(
                    color: widget.textColor ?? Colors.green[900],
                    fontSize: 16,
                    fontWeight: FontWeight.bold,),
              ),
            ),
          ),
        ),
      );
}

void showToast(BuildContext context, String message,
    {List<Color>? colors, Color? textColor, Color? backgroundShadow,}) {
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
        backgroundShadow: backgroundShadow,
        textColor: textColor,
      ),
    ),
  );

  overlay.insert(overlayEntry);
}

extension AnimationControllerExtension on AnimationController {
  bool get isDisposed => status == AnimationStatus.dismissed;
}
