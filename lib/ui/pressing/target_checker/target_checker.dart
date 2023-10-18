import 'dart:math';

import 'package:ballistics_wallet_flutter/ui/pressing/target_checker/slide_to_overtimes.dart';
import 'package:ballistics_wallet_flutter/ui/pressing/target_checker/target_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';

import '../../../providers/auth_providers/auth_provider.dart';
import '../../../providers/target_check_provider.dart';
import '../../../repository/target_check_repository.dart';
import '../../../repository/users_repository.dart';
import 'basic_shift.dart';
import 'circles.dart';
import 'overtime_shift.dart';

class TargetChecker extends ConsumerStatefulWidget {
  const TargetChecker({Key? key}) : super(key: key);

  @override
  TargetCheckerCard createState() => TargetCheckerCard();
}

class TargetCheckerCard extends ConsumerState<TargetChecker>
    with TickerProviderStateMixin {
  final allowanceController = TextEditingController();
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;
  double _startPosition = 0.0;




  @override
  void initState() {
    super.initState();

    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _flipAnimation = Tween(begin: 0.0, end: 3.14).animate(_flipController);
  }


  @override
  void dispose() {
    _flipController.dispose();
    allowanceController.dispose();

    super.dispose();
  }



  @override
  Widget build(BuildContext context) {

    final userId = ref.watch(authRepositoryProvider).currentUserId;
    final updated = ref.watch(productUpdateProvider);
    final products = ref.watch(productsProvider(updated));
    final productName =
        ref.watch(selectedProductProvider).state.toLowerCase().trimRight();

    final double percentage = ref.watch(targetRatioProvider(userId)) * 100;
    final int amount = ref.watch(numberProvider);
    int productTarget = ref.watch(targetProvider);

    final double targetRatio = ref.watch(targetRatioProvider(userId));
    ref.read(userNotifierProvider.notifier).loadUser(userId);
    final userState = ref.watch(userNotifierProvider.notifier).state;
    final allowance = ref.watch(allowanceProvider);
    final double workingHours = userState.workingHours ?? 0.0;

    final focusNode = ref.watch(focusNodeProvider);

    return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
      bool isWideScreen = constraints.maxWidth > 500;
      double containerWidth = isWideScreen
          ? MediaQuery.of(context).size.width * 0.33
          : MediaQuery.of(context).size.width * 0.85;
      double containerHeight = MediaQuery.of(context).size.height * 0.82;

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
            double dx = details.globalPosition.dx - _startPosition;
            _flipController.value += dx / (containerWidth ?? 1);
            _startPosition = details.globalPosition.dx;
          });
        },
        onHorizontalDragEnd: (details) {
          if (_flipController.value >= 0.5) {
            _flipController.forward();

            ref.read(selectedProductProvider).state = '';
            ref.read(searchTermProvider.notifier).state = "";
            ref.read(targetProvider.notifier).updateTarget(0);
            ref.read(textEditingControllerProvider).clear();
          } else {
            ref.read(selectedProductProvider).state = '';
            ref.read(searchTermProvider.notifier).state = "";
            ref.read(targetProvider.notifier).updateTarget(0);
            ref.read(textEditingControllerProvider).clear();
            _flipController.reverse();
          }
        },
        child: AnimatedBuilder(
            animation: _flipAnimation,
            builder: (context, child) {
              return Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001)
                    ..rotateY(pi * _flipController.value)
                    ..setEntry(
                        3, 2, _flipController.value > 0.5 ? -0.001 : 0.001),
                  child: IndexedStack(
                      alignment: Alignment.center,
                      index: (_flipController.value < 0.5) ? 0 : 1,
                      children: [
                        BasicShift(), // FrontFlipCard
                        Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.identity()..rotateY(pi),
                          child: OvertimeShift(),
                        ),
                        // BackFlipCard
                      ]));
            }),
      );
    });
  }
}
