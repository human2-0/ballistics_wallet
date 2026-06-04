import 'dart:async';
import 'dart:math';

import 'package:ballistics_wallet_flutter/custom_widgets/app_notification.dart';
import 'package:ballistics_wallet_flutter/providers/router_provider.dart';
import 'package:ballistics_wallet_flutter/providers/target_check_provider.dart';
import 'package:ballistics_wallet_flutter/ui/pressing/target_check/basic_shift/basic_shift.dart';
import 'package:ballistics_wallet_flutter/ui/pressing/target_check/work_timeline_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final workTimelineOpenProvider = StateProvider<bool>((ref) => false);

class TargetChecker extends ConsumerStatefulWidget {
  const TargetChecker({super.key});

  @override
  TargetCheckerCard createState() => TargetCheckerCard();
}

class TargetCheckerCard extends ConsumerState<TargetChecker>
    with TickerProviderStateMixin {
  final allowanceController = TextEditingController();
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;
  bool _timelineSheetOpen = false;

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
    ref.listen<bool>(workTimelineOpenProvider, (previous, next) {
      if (!next || _timelineSheetOpen) return;
      _timelineSheetOpen = true;
      unawaited(_showWorkTimelineSheet(context));
    });

    final message = ref.watch(toastMessageProvider);
    if (message.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showAppNotification(
          context,
          message,
          type: AppNotificationType.success,
        );
        ref.read(toastMessageProvider.notifier).state = '';
      });
    }

    return GestureDetector(
      onTap: () {
        focusNode.unfocus();
        ref.read(showListProvider.notifier).state = false;
      },
      // onHorizontalDragStart: (details) {
      //   _startPosition = details.globalPosition.dx;
      // },
      // onHorizontalDragUpdate: (details) {
      //   setState(() {
      //     final dx = details.globalPosition.dx - _startPosition;
      //     _flipController.value += dx / containerWidth;
      //     _startPosition = details.globalPosition.dx;
      //   });
      // },
      // onHorizontalDragEnd: (details) async {
      //   if (_flipController.value >= 0.5) {
      //     await _flipController.forward();
      //
      //     ref.read(targetProvider.notifier).state = 0;
      //     ref.read(textEditingControllerProvider).clear();
      //   } else {
      //     ref.read(targetProvider.notifier).state = 0;
      //     ref.read(textEditingControllerProvider).clear();
      //     await _flipController.reverse();
      //   }
      // },
      child: AnimatedBuilder(
        animation: _flipAnimation,
        builder:
            (context, child) => Transform(
              alignment: Alignment.topCenter,
              transform:
                  Matrix4.identity()
                    ..setEntry(3, 2, 0.001)
                    ..rotateY(pi * _flipController.value),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: IndexedStack(
                  alignment: Alignment.topCenter,
                  index: (_flipController.value < 0.5) ? 0 : 1,
                  children: const [
                    BasicShift(),
                    // Transform(
                    //   alignment: Alignment.center,
                    //   transform: Matrix4.identity()..rotateY(pi),
                    //   child: const OvertimeShift(),
                    // ),
                    // BackFlipCard
                  ],
                ),
              ),
            ),
      ),
    );
  }

  Future<void> _showWorkTimelineSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => FractionallySizedBox(
            heightFactor: 0.9,
            child: WorkTimelinePanel(
              onClose: () => Navigator.of(context).pop(),
            ),
          ),
    );

    _timelineSheetOpen = false;
    if (mounted) {
      ref.read(workTimelineOpenProvider.notifier).state = false;
    }
  }
}
