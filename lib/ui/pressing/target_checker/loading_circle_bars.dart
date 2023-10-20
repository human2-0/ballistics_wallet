import 'package:flutter/material.dart';
import 'dart:math';

class BonusCoin extends StatelessWidget {
  final double bonus;

  const BonusCoin({Key? key, required this.bonus}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colors = <Color>[
      const Color(0xFF002FA7),
      const Color(0xFF0039A6),
      const Color(0xFF0043A5),
      const Color(0xFF004EA3),
      const Color(0xFF005AA2),
      const Color(0xFF00659F),
      const Color(0xFF00719B),
      const Color(0xFF007D98),
      const Color(0xFF008994),
      const Color(0xFF009490),
      const Color(0xFF009E8C),
      const Color(0xFF00A987),
      const Color(0xFF00B483),
      const Color(0xFF00BD7E),
      const Color(0xFF00C779),
      const Color(0xFF00CF74),
      const Color(0xFF00D76E),
      const Color(0xFF00DE68),
      const Color(0xFF00E661),
      const Color(0xFF00ED5B),
      const Color(0xFF00F454),
    ];

    final index = (bonus.toInt() - 1).clamp(0, 20);
    final color = colors[index];

    final nextIndex = (index + 1).clamp(0, 20);
    final nextColor = colors[nextIndex];

    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.7),
            nextColor.withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.4),
            offset: const Offset(-4, -4),
            blurRadius: 6,
          ),
          BoxShadow(
            color: nextColor.withOpacity(0.4),
            offset: const Offset(4, 4),
            blurRadius: 6,
          ),
          BoxShadow(
            color: color.withOpacity(0.2),
            offset: const Offset(4, -4),
            blurRadius: 6,
          ),
          BoxShadow(
            color: nextColor.withOpacity(0.2),
            offset: const Offset(-4, 4),
            blurRadius: 6,
          ),
        ],
      ),
      child: Center(
        child: Text(
          '£${bonus.toStringAsFixed(2)}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class RainbowCircularProgressIndicator extends StatefulWidget {
  final double percentage;

  const RainbowCircularProgressIndicator({Key? key, required this.percentage})
      : super(key: key);

  @override
  _RainbowCircularProgressIndicatorState createState() =>
      _RainbowCircularProgressIndicatorState();
}

class _RainbowCircularProgressIndicatorState extends State<RainbowCircularProgressIndicator> with TickerProviderStateMixin {
  late AnimationController _colorRotationController;
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();

    _colorRotationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _progressController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _progressAnimation = Tween<double>(
      begin: 0,
      end: ((widget.percentage - 100) / 71.5).clamp(0.0, 1.0),
    ).animate(_progressController);

    _progressController.forward();
  }

  @override
  void didUpdateWidget(covariant RainbowCircularProgressIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.percentage != oldWidget.percentage) {
      _progressAnimation = Tween<double>(
        begin: _progressAnimation.value,
        end: ((widget.percentage - 100) / 71.5).clamp(0.0, 1.0),
      ).animate(_progressController);
      _progressController
        ..reset()
        ..forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_colorRotationController, _progressAnimation]),
      builder: (BuildContext context, Widget? child) {
        return CustomPaint(
          painter: _RainbowCirclePainter(
            progress: _progressAnimation.value,
            rotation: _colorRotationController.value,
          ),
          size: const Size(46, 46),
        );
      },
    );
  }

  @override
  void dispose() {
    _colorRotationController.dispose();
    _progressController.dispose();
    super.dispose();
  }
}


class _RainbowCirclePainter extends CustomPainter {
  const _RainbowCirclePainter({required this.progress, required this.rotation});

  final double progress;
  final double rotation;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 3;

    final gradient = SweepGradient(
      startAngle: 0.0,
      endAngle: 2 * pi,
      transform: GradientRotation(2 * pi * rotation),
      colors: const [
        Colors.red,
        Colors.deepOrange,
        Colors.orange,
        Colors.amber,
        Colors.yellow,
        Colors.lime,
        Colors.lightGreen,
        Colors.green,
        Colors.blue,
        Colors.indigo,
        Colors.purple,
        Colors.pink,
      ],
    );

    final paint = Paint()
      ..shader = gradient.createShader(Rect.fromCircle(center: center, radius: radius))
      ..strokeWidth = 6.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Start angle is -pi/2 to make the progress start from the top
    double startAngle = -pi / 2;
    // Sweep angle is 2*pi to make it a full circle
    double sweepAngle = 2 * pi * progress;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}



class MinimumCircle extends StatefulWidget {
  final double percentage;
  const MinimumCircle({Key? key, required this.percentage}) : super(key: key);

  @override
  _MinimumCircleState createState() => _MinimumCircleState();
}

class _MinimumCircleState extends State<MinimumCircle> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _progressAnimation = Tween<double>(
      begin: 0,
      end: (widget.percentage / 100).clamp(0.0, 1.0),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    ));
    _controller.forward();
  }

  @override
  void didUpdateWidget(MinimumCircle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.percentage != widget.percentage) {
      _progressAnimation = Tween<double>(
        begin: _progressAnimation.value,
        end: (widget.percentage / 100).clamp(0.0, 1.0),
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOutCubic,
      ));
      _controller.forward(from: 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        return CustomPaint(
          painter: _MinimumCirclePainter(
            progress: _progressAnimation.value,
            color: Colors.green,
            backgroundColor: Colors.pink[50]!,
          ),
          size: const Size(46, 46),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class _MinimumCirclePainter extends CustomPainter {
  const _MinimumCirclePainter({required this.progress, required this.color, required this.backgroundColor});

  final double progress;
  final Color color;
  final Color backgroundColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2;

    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, radius, backgroundPaint);

    final paint = Paint()
      ..color = color
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke;

    final angle = 2 * pi * progress;

    // Draw the arc
    canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2,
        angle,
        false,
        paint);

    // Draw the round caps
    final Paint roundPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final double strokeWidthHalf = paint.strokeWidth / 2;

    final Offset circleStartOffset = Offset(
      center.dx + radius * cos(-pi / 2),
      center.dy + radius * sin(-pi / 2),
    );

    final Offset circleEndOffset = Offset(
      center.dx + radius * cos(-pi / 2 + angle),
      center.dy + radius * sin(-pi / 2 + angle),
    );

    canvas.drawCircle(circleStartOffset, strokeWidthHalf, roundPaint);
    canvas.drawCircle(circleEndOffset, strokeWidthHalf, roundPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

