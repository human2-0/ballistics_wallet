import 'package:flutter/material.dart';

class SlideToBasicShift extends StatefulWidget {
  const SlideToBasicShift({super.key});

  @override
  SlideToBasicShiftState createState() => SlideToBasicShiftState();
}

class SlideToBasicShiftState extends State<SlideToBasicShift>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _slideController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(-0.15, 0),
      end: const Offset(0.15, 0),
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeInOut),
    )..addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _slideController.reverse();
      } else if (status == AnimationStatus.dismissed) {
        _slideController.forward();
      }
    });

    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: <Widget>[
          Container(
            width: MediaQuery.of(context).size.width * 0.70,
            height: MediaQuery.of(context).size.height * 0.05,
            decoration: BoxDecoration(
              color: Colors.lightBlue,
              borderRadius: BorderRadius.circular(33),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  offset: const Offset(0, 2),
                  blurRadius: 5,
                ),
              ],
            ),
            child: Center(
              child: Column(
                children: [
                  const Text('Slide to return'),
                  SlideTransition(
                    position: _slideAnimation,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: <Widget>[
                        Icon(Icons.keyboard_arrow_left_rounded, color: Colors.orange, size: MediaQuery.of(context).size.aspectRatio * 40),
                        Icon(Icons.keyboard_arrow_left_rounded, color: Colors.orange, size: MediaQuery.of(context).size.aspectRatio * 40),
                        Icon(Icons.keyboard_arrow_left_rounded, color: Colors.orange, size: MediaQuery.of(context).size.aspectRatio * 40),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
}
