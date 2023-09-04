import 'package:ballistics_wallet_flutter/ui/pressing/split_check/split_check.dart';
import 'package:flutter/material.dart';

class SplitCheckMainTree extends StatefulWidget {
  const SplitCheckMainTree({super.key});

  @override
  _SplitCheckMainTreeState createState() =>
      _SplitCheckMainTreeState();
}

class _SplitCheckMainTreeState
    extends State<SplitCheckMainTree>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,  // Adjust this if you want the center elsewhere
              radius: 1.3,  // Adjust the radius as needed
              colors: const [
                Colors.red,
                Colors.orange,
                Colors.yellow,
                Colors.green,
                Colors.blue,
                Colors.indigo,
                Colors.purple,
                // Repeat the colors to make it loop seamlessly
                Colors.red,
                Colors.orange,
                Colors.yellow,
                Colors.green,
                Colors.blue,
                Colors.indigo,
                Colors.purple,
              ],
              stops: _generateStops(),
            ),
          ),
          child: child,
        );
      },
      child: SplitCheck(),
    );
  }

  List<double> _generateStops() {
    final progress = _controller.value;
    const offset = 1.0 / 14.0;  // Now divided by 14 as there are 14 colors
    return List.generate(14, (index) => (index * offset + progress) % 1.0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}