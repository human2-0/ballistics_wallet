import 'package:ballistics_wallet_flutter/providers/controllers.dart';
import 'package:ballistics_wallet_flutter/providers/split_provider.dart';
import 'package:ballistics_wallet_flutter/utilities.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class MinimumAnimatedTile extends ConsumerStatefulWidget {
  const MinimumAnimatedTile({
    required this.target,
    required this.onLongPressComplete,
    super.key,
  });
  final int target;
  final VoidCallback onLongPressComplete;

  @override
  _MinimumAnimatedTileState createState() => _MinimumAnimatedTileState();
}

class _MinimumAnimatedTileState extends ConsumerState<MinimumAnimatedTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(
        seconds: 2,
      ), // Adjust the duration to control the speed of the color change
    );
    _colorAnimation = ColorTween(
      begin: Colors.orange[200],
      end: Colors.green,
    ).animate(_controller)..addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onLongPressComplete();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () async {
      ref.read(amountPerBatchProvider.notifier).state = widget.target;
      ref.read(activeIndexTabProvider.notifier).activeIndex = 1;
      context.pop();
    },
    onLongPress: () {
      _controller.forward();
    },
    onLongPressUp: () {
      _controller.reset();
    },
    child: AnimatedBuilder(
      animation: _colorAnimation,
      builder:
          (context, child) => Container(
            margin: const EdgeInsets.all(16),
            width: MediaQuery.of(context).size.width * 0.5,
            height: MediaQuery.of(context).size.height * 0.25,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [
                  _colorAnimation.value ?? Colors.orange[200]!,
                  Colors.white,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.5),
                  spreadRadius: 5,
                  blurRadius: 7,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  color: Colors.orange.withValues(alpha: 0.5),
                  gradient: LinearGradient(
                    colors: [
                      _colorAnimation.value ?? Colors.orange[200]!,
                      Colors.white,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.5),
                      spreadRadius: 2,
                      blurRadius: 3,
                      offset: const Offset(2, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Minimum',
                      style: TextStyle(fontSize: 16, color: Colors.black54),
                    ),
                    Text(
                      '${widget.target}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
    ),
  );
}

class BonusAnimatedTile extends ConsumerStatefulWidget {
  const BonusAnimatedTile({
    required this.bonus,
    required this.requiredAmount,
    required this.onLongPressComplete,
    super.key,
  });
  final double bonus;
  final int requiredAmount;
  final VoidCallback onLongPressComplete;

  @override
  _BonusAnimatedTileState createState() => _BonusAnimatedTileState();
}

class _BonusAnimatedTileState extends ConsumerState<BonusAnimatedTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _colorAnimation = ColorTween(
      begin: Colors.orange[200],
      end: Colors.green,
    ).animate(_controller)..addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onLongPressComplete();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () async {
      // await context.push('/split');
      ref.read(requiredAmountProvider.notifier).state = widget.requiredAmount;
      ref.read(amountPerBatchProvider.notifier).state = widget.requiredAmount;
      ref.read(activeIndexTabProvider.notifier).activeIndex = 1;
      context.pop();
    },
    onLongPress: () {
      _controller.forward();
    },
    onLongPressUp: () {
      _controller.reset();
    },
    child: AnimatedBuilder(
      animation: _controller,
      builder:
          (_, child) => Container(
            margin: const EdgeInsets.all(16),
            height: MediaQuery.of(context).size.height * 0.25,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [
                  _colorAnimation.value ?? Colors.orange[200]!,
                  Colors.white,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.5),
                  spreadRadius: 5,
                  blurRadius: 7,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        color: Colors.orange.withValues(alpha: 0.5),
                        gradient: LinearGradient(
                          colors: [
                            _colorAnimation.value ?? Colors.orange[200]!,
                            Colors.white,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withValues(alpha: 0.5),
                            spreadRadius: 2,
                            blurRadius: 3,
                            offset: const Offset(2, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'to earn',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black54,
                            ),
                          ),
                          Text(
                            '£${formatDouble(widget.bonus)}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        color: Colors.orange.withValues(alpha: 0.5),
                        gradient: LinearGradient(
                          colors: [
                            _colorAnimation.value ?? Colors.orange[200]!,
                            Colors.white,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withValues(alpha: 0.5),
                            spreadRadius: 2,
                            blurRadius: 3,
                            offset: const Offset(2, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${widget.requiredAmount}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            'more to do',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    ),
  );
}
