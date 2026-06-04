import 'package:ballistics_wallet_flutter/providers/rive_file_provider.dart';
import 'package:ballistics_wallet_flutter/providers/wallet_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rive/rive.dart';

/// Renders the circular ratio Rive animation.
class RiveEllipses extends ConsumerStatefulWidget {
  /// Creates the circular ratio Rive animation widget.
  const RiveEllipses({super.key});

  @override
  ConsumerState<RiveEllipses> createState() => _RiveEllipsesState();
}

class _RiveEllipsesState extends ConsumerState<RiveEllipses> {
  final riveFileName = 'assets/rive/loading_minimum_circle.riv';
  NumberInput? _inputControl;
  RiveWidgetController? _riveController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadRiveFile());
  }

  Future<void> _loadRiveFile() async {
    try {
      final riveFile = await ref.read(riveFileProvider);
      final controller = RiveWidgetController(
        riveFile,
        artboardSelector: ArtboardSelector.byName('Circles'),
        stateMachineSelector: StateMachineSelector.byName('Loading State'),
      );
      // Rive 0.14 still supports legacy state machine inputs used by this asset.
      // ignore: deprecated_member_use
      final inputControl = controller.stateMachine.number('ratio');
      if (!mounted) {
        inputControl?.dispose();
        controller.dispose();
        return;
      }

      setState(() {
        _inputControl = inputControl;
        _riveController = controller;
      });
    } on Object catch (error, stackTrace) {
      debugPrint('Failed to load Rive circles animation: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  @override
  void dispose() {
    _inputControl?.dispose();
    _riveController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Listen for changes to the ratio and update the Rive animation accordingly
    final ratio = ref.watch(bonusInfoListProvider).ratio * 100;
    _inputControl?.value = ratio;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width =
            constraints.maxWidth.isFinite ? constraints.maxWidth : 180.0;
        final height =
            constraints.maxHeight.isFinite ? constraints.maxHeight : width;

        return SizedBox(
          width: width,
          height: height,
          child:
              _riveController != null
                  ? RiveWidget(controller: _riveController!)
                  : const SizedBox.shrink(),
        );
      },
    );
  }
}
