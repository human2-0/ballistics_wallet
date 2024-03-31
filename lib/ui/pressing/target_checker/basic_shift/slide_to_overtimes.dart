import 'package:flutter/material.dart';

class SlideToOvertime extends StatefulWidget {
  const SlideToOvertime({super.key});

  @override
  SlideToOvertimeState createState() => SlideToOvertimeState();
}

class SlideToOvertimeState extends State<SlideToOvertime>
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
              color: Colors.orange[200],
              borderRadius: BorderRadius.circular(33),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  offset: const Offset(0, 2),
                  blurRadius: 5,
                ),
              ],
            ),
            child: Center(
              child: Column(
                children: [
                  const Text('Slide for overtime card'),
                  SlideTransition(
                    position: _slideAnimation,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: <Widget>[
                        Icon(Icons.arrow_forward_ios_rounded, color: Colors.orange, size: MediaQuery.of(context).size.aspectRatio * 30),
                        Icon(Icons.arrow_forward_ios_rounded, color: Colors.orange, size: MediaQuery.of(context).size.aspectRatio * 30),
                        Icon(Icons.arrow_forward_ios_rounded, color: Colors.orange, size: MediaQuery.of(context).size.aspectRatio * 30),
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
