import 'package:ballistics_wallet_flutter/providers/rive_file_provider.dart';
import 'package:ballistics_wallet_flutter/providers/wallet_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rive/rive.dart';

class RiveEllipses extends ConsumerStatefulWidget {
  const RiveEllipses({super.key});

  @override
  _RiveEllipsesState createState() => _RiveEllipsesState();
}

class _RiveEllipsesState extends ConsumerState<RiveEllipses> {
  final riveFileName = 'assets/rive/loading_minimum_circle.riv';
  Artboard? _artboard;
  SMIInput<double>? _inputControl;
  StateMachineController? _stateMachineController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async => _loadRiveFile());
  }

  Future<void> _loadRiveFile() async {
    final riveFile = await ref.read(riveFileProvider);
    final artboard = riveFile.artboardByName('Circles')!;
    final controller = StateMachineController.fromArtboard(artboard, 'Loading State')!;

    artboard.addController(controller);
    _inputControl = controller.findInput<double>('ratio');

    setState(() {
      _artboard = artboard;
      _stateMachineController = controller;
    });
  }

  @override
  void dispose() {
    _stateMachineController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Listen for changes to the ratio and update the Rive animation accordingly
    final ratio = ref.watch(bonusInfoListProvider).ratio * 100;
    if (_inputControl != null && _stateMachineController != null) {
      _stateMachineController!.setInputValue(_inputControl!.id, ratio);
    }

    return _artboard != null
        ? Rive(
      artboard: _artboard!,
      fit: BoxFit.contain,
    )
        : Container();
  }
}
