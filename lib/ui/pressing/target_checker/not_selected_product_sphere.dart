import 'package:flutter/material.dart';

class SphereQuestionMark extends StatelessWidget{
  const SphereQuestionMark({super.key});

  @override
  Widget build(BuildContext context)
  => Container(
      width: 256,
      height: 256,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            Colors.orange[100]!,
            Colors.orange[200]!,
            Colors.orange[300]!,
            Colors.orange[400]!,
            Colors.black,
          ],
          stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
          // controls the color transition positions
          center: const Alignment(-0.5, -0.5),
          // shift the center alignment to mimic light reflection
          radius: 1.5,
          // controls the overall radius of the gradient
          focal: const Alignment(-0.5, -0.5),
          // controls the focal point of the gradient
          focalRadius:
          0.1, // controls the radius of the focal point
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            spreadRadius: 5,
            blurRadius: 12,
            offset: const Offset(
                4, 4,), // changes position of shadow
          ),
        ],
      ),
      child: const Center(
        child: Text(
          '?',
          style: TextStyle(
            fontSize: 75,
            color: Colors.orange,
          ),
        ),
      ),
    );
}
