import 'package:flutter/material.dart';

/// Dismisses the active text field when the user taps outside it or when the
/// application leaves the foreground.
///
/// Releasing focus before iOS suspends the application lets Flutter close the
/// text-input connection normally. This avoids restoring a stale connection
/// (and any focus-driven overlays) when the application resumes.
class KeyboardDismissRegion extends StatefulWidget {
  const KeyboardDismissRegion({required this.child, super.key});

  final Widget child;

  @override
  State<KeyboardDismissRegion> createState() => _KeyboardDismissRegionState();
}

class _KeyboardDismissRegionState extends State<KeyboardDismissRegion>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      _dismissKeyboard();
    }
  }

  void _dismissKeyboard() {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.translucent,
    onTap: _dismissKeyboard,
    child: widget.child,
  );

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
