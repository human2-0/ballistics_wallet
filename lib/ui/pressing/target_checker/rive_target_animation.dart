import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rive/rive.dart';

class TargetBoard extends ConsumerStatefulWidget {
  const TargetBoard({required this.productName, super.key});
  final String productName;

  @override
  _RiveEllipsesState createState() => _RiveEllipsesState();
}

class _RiveEllipsesState extends ConsumerState<TargetBoard> {
  final riveFileName = 'assets/rive/loading_minimum_circle.riv';
  Artboard? _artboard;
  SMIInput<bool>? _inputControl;
  StateMachineController? _stateMachineController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async => _loadRiveFile());
  }

  Future<void> _loadRiveFile() async {
    final data = await rootBundle.load(riveFileName);
    final file = RiveFile.import(data);
    final artboard = file.artboardByName('target')!;
    final controller = StateMachineController.fromArtboard(
      artboard,
      'Target Check',
    )!;

    artboard.addController(controller);
    _inputControl = controller.findInput<bool>('productSelected');
    setState(() {
      _artboard = artboard;
      _stateMachineController = controller;
    });
  }

  void _openEndDrawer() {
    Scaffold.of(context).openEndDrawer();
  }

  @override
  void dispose() {
    _stateMachineController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Listen for changes to the ratio and update the Rive animation accordingly
    final productSelected = widget.productName.isNotEmpty;
    if (_inputControl != null && _stateMachineController != null) {
      _stateMachineController!
          .setInputValue(_inputControl!.id, productSelected);
    }
    return _artboard != null
        ? Stack(
            children: [
              Rive(
                useArtboardSize: true,
                artboard: _artboard!,
                fit: BoxFit.contain,
              ),
              Positioned(
                right: 0,
                top: 10,
                child: GestureDetector(
                  onTap: () {
                    if (productSelected) {
                      _openEndDrawer();
                    }
                  },
                  child: Container(
                    color: Colors.transparent,
                    width: 110,
                    height: 110,
                  ),
                ),
              ),
            ],
          )
        : Container();
  }
}
