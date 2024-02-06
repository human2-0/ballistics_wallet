import 'package:flutter/material.dart';

class ToastWidget extends StatefulWidget {
  const ToastWidget({required this.message, super.key});
  final String message;

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

    // Start the animation
    _controller.forward();

    // Hide the toast message after some time
    Future.delayed(const Duration(seconds: 2), () async {
      if (mounted && !_controller.isDisposed) {
        await _reverseAnimation(); // Reverse the animation
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
            color: Colors.black.withOpacity(0.7),
          ),
          child: Center(
            child: Text(
              widget.message,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ),
      ),
    );
  }
}

void showToast(BuildContext context, String message) {
  final overlay = Overlay.of(context);

  // Use MediaQuery to get screen width and height
  final screenWidth = MediaQuery.of(context).size.width;
  final screenHeight = MediaQuery.of(context).size.height;

  // Calculate positions based on screen size
  // Place it at the center of the screen horizontally
  const toastWidth = 350.0; // Assuming your ToastWidget has a fixed width
  final left = (screenWidth - toastWidth) / 2; // Center horizontally
  // Adjust the top position as needed, for example, 1/6th from the top of the screen
  final top = screenHeight / 6;

  final overlayEntry = OverlayEntry(
    builder: (context) => Positioned(
      top: top,
      left: left,
      width: toastWidth,
      child: ToastWidget(message: message), // Set the width of the ToastWidget
    ),
  );

  overlay.insert(overlayEntry);

  // Removal of overlay entry should be handled where you manage the lifecycle of the toast
}


extension AnimationControllerExtension on AnimationController {
  bool get isDisposed => status == AnimationStatus.dismissed;
}
