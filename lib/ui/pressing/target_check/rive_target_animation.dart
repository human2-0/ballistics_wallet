import 'package:ballistics_wallet_flutter/providers/rive_file_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rive/rive.dart';

/// Renders the target board Rive artboard at a stable square size.
class TargetBoard extends ConsumerStatefulWidget {
  /// Creates a target board for the selected product state.
  const TargetBoard({required this.productName, this.size = 220, super.key});

  /// Current product name used to drive the selected/unselected Rive state.
  final String productName;

  /// Square side length for the board.
  final double size;

  @override
  ConsumerState<TargetBoard> createState() => _RiveEllipsesState();
}

class _RiveEllipsesState extends ConsumerState<TargetBoard> {
  final riveFileName = 'assets/rive/loading_minimum_circle.riv';
  BooleanInput? _inputControl;
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
        artboardSelector: ArtboardSelector.byName('target'),
        stateMachineSelector: StateMachineSelector.byName('Target Check'),
      );
      // Rive 0.14 still supports legacy state machine inputs used by this asset.
      // ignore: deprecated_member_use
      final inputControl = controller.stateMachine.boolean('productSelected');
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
      debugPrint('Failed to load Rive target animation: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  void _openEndDrawer() {
    Scaffold.of(context).openEndDrawer();
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
    final productSelected = widget.productName.isNotEmpty;
    _inputControl?.value = productSelected;
    final tapTargetSize = widget.size * 0.5;

    return SizedBox.square(
      dimension: widget.size,
      child:
          _riveController != null
              ? Stack(
                fit: StackFit.expand,
                children: [
                  RiveWidget(controller: _riveController!),
                  Positioned(
                    right: 0,
                    top: widget.size * 0.05,
                    width: tapTargetSize,
                    height: tapTargetSize,
                    child: GestureDetector(
                      onTap: () {
                        if (productSelected) {
                          _openEndDrawer();
                        }
                      },
                      child: Container(color: Colors.transparent),
                    ),
                  ),
                ],
              )
              : const SizedBox.shrink(),
    );
  }
}
