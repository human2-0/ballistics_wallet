import 'dart:math';

import 'package:ballistics_wallet_flutter/providers/target_check_provider.dart';
import 'package:ballistics_wallet_flutter/ui/pressing/target_checker/basic_shift/basic_shift.dart';
import 'package:ballistics_wallet_flutter/ui/pressing/target_checker/overtime_shift/overtime_shift.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TargetChecker extends ConsumerStatefulWidget {
  const TargetChecker({required this.onNotification, super.key});
  final void Function(ScrollNotification) onNotification;

  @override
  TargetCheckerCard createState() => TargetCheckerCard();
}

class TargetCheckerCard extends ConsumerState<TargetChecker>
    with TickerProviderStateMixin {
  final allowanceController = TextEditingController();
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;
  double _startPosition = 0;

  @override
  void initState() {
    super.initState();

    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _flipAnimation = Tween(end: 3.14).animate(_flipController);
  }

  @override
  void dispose() {
    _flipController.dispose();
    allowanceController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final focusNode = ref.watch(focusNodeProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWideScreen = constraints.maxWidth > 500;
        final containerWidth = isWideScreen
            ? MediaQuery.of(context).size.width * 0.40
            : MediaQuery.of(context).size.width * 0.85;

        return GestureDetector(
          onTap: () {
            focusNode.unfocus();
            ref.read(showListProvider.notifier).state = false;
          },
          onHorizontalDragStart: (details) {
            _startPosition = details.globalPosition.dx;
          },
          onHorizontalDragUpdate: (details) {
            setState(() {
              final dx = details.globalPosition.dx - _startPosition;
              _flipController.value += dx / containerWidth;
              _startPosition = details.globalPosition.dx;
            });
          },
          onHorizontalDragEnd: (details) async {
            if (_flipController.value >= 0.5) {
              await _flipController.forward();

              ref.read(selectedProductProvider).state = '';
              ref.read(searchTermProvider.notifier).state = '';
              await ref.read(targetProvider.notifier).updateTarget(0);
              ref.read(textEditingControllerProvider).clear();
            } else {
              ref.read(selectedProductProvider).state = '';
              ref.read(searchTermProvider.notifier).state = '';
              await ref.read(targetProvider.notifier).updateTarget(0);
              ref.read(textEditingControllerProvider).clear();
              await _flipController.reverse();
            }
          },
          child: AnimatedBuilder(
            animation: _flipAnimation,
            builder: (context, child) => Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateY(pi * _flipController.value),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: IndexedStack(
                  alignment: Alignment.center,
                  index: (_flipController.value < 0.5) ? 0 : 1,
                  children: [
                    Center(
                      child: BasicShift(
                        onNotification: widget.onNotification,
                      ),
                    ), // FrontFlipCard
                    Center(
                      child: Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()..rotateY(pi),
                        child: const OvertimeShift(),
                      ),
                    ),
                    // BackFlipCard
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
