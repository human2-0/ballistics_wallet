import 'package:ballistics_wallet_flutter/providers/wallet_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


class TargetButton extends ConsumerStatefulWidget {
  const TargetButton({required this.productName, super.key, this.overtimes = false});
  final String productName;
  final bool overtimes;

  @override
  TargetButtonState createState() => TargetButtonState();
}

class TargetButtonState extends ConsumerState<TargetButton>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _colorAnimation = ColorTween(
      begin: widget.productName.isEmpty ? Colors.grey : Colors.orange,
      end: Colors.yellow,
    ).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.linear),
    );



    if (widget.productName.isNotEmpty) {
      _rotationController.repeat();
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant TargetButton oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.productName != oldWidget.productName) {
      _colorAnimation = ColorTween(
        begin: widget.productName.isEmpty ? Colors.grey : Colors.orange,
        end: Colors.brown,
      ).animate(
        CurvedAnimation(parent: _pulseController, curve: Curves.linear),
      );

      if (widget.productName.isNotEmpty) {
        if (!_rotationController.isAnimating) {
          _rotationController.repeat();
        }
        if (!_pulseController.isAnimating) {
          _pulseController.repeat();
        }
      } else {
        _rotationController.stop();
        _pulseController.stop();
      }
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.all(16),
      child: GestureDetector(
        onTap: () {
          ref.read(bonusTableSelectorProvider.notifier).state = widget.overtimes;
          Scaffold.of(context).openEndDrawer();
        },
        child: AnimatedBuilder(
          animation: _colorAnimation,
          builder: (context, child) => RotationTransition(
            turns: _rotationController,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.8, end: 1.2).animate(
                CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
              ),
              child: Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: _colorAnimation.value,
                  borderRadius: BorderRadius.circular(22.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      offset: const Offset(0, 2),
                      blurRadius: 5,
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.gps_fixed_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
}
