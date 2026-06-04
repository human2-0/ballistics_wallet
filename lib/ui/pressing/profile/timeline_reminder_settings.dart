// Profile settings widgets are app screens, not package API.
// ignore_for_file: public_member_api_docs

import 'dart:async';

import 'package:ballistics_wallet_flutter/providers/work_timeline_provider.dart';
import 'package:ballistics_wallet_flutter/services/work_timeline_notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TimelineReminderSettings extends ConsumerWidget {
  const TimelineReminderSettings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(workTimelineSettingsProvider);
    final targetLabel =
        settings.targetBonus > 0
            ? 'Default target: £${settings.targetBonus.toStringAsFixed(2)}'
            : 'Default target not set';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50]!.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue[100]!),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.view_timeline_outlined, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  targetLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              IconButton(
                tooltip: 'Edit timeline target',
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => _showTargetDialog(context, ref, settings),
              ),
            ],
          ),
          _ReminderRow(
            icon: Icons.coffee_outlined,
            label: 'Break score reminder',
            value: settings.breakReminderEnabled,
            onChanged: (value) {
              unawaited(_setBreakReminder(ref, value));
            },
          ),
          _ReminderRow(
            icon: Icons.notifications_active_outlined,
            label: 'Batch start reminder',
            value: settings.batchReminderEnabled,
            onChanged: (value) {
              unawaited(_setBatchReminder(ref, value));
            },
          ),
        ],
      ),
    );
  }

  Future<void> _showTargetDialog(
    BuildContext context,
    WidgetRef ref,
    WorkTimelineSettings settings,
  ) async {
    final target = await showDialog<int>(
      context: context,
      builder:
          (context) => _TimelineTargetDialog(
            initialTarget: settings.targetBonus.floor(),
          ),
    );
    if (target != null) {
      await ref
          .read(workTimelineSettingsProvider.notifier)
          .setTargetBonus(target.toDouble());
    }
  }

  Future<void> _setBreakReminder(WidgetRef ref, bool value) async {
    if (value) {
      await WorkTimelineNotificationService.instance.requestPermissions();
    }
    await ref
        .read(workTimelineSettingsProvider.notifier)
        .setBreakReminderEnabled(value);
  }

  Future<void> _setBatchReminder(WidgetRef ref, bool value) async {
    if (value) {
      await WorkTimelineNotificationService.instance.requestPermissions();
    }
    await ref
        .read(workTimelineSettingsProvider.notifier)
        .setBatchReminderEnabled(value);
  }
}

class _TimelineTargetDialog extends StatefulWidget {
  const _TimelineTargetDialog({required this.initialTarget});

  final int initialTarget;

  @override
  State<_TimelineTargetDialog> createState() => _TimelineTargetDialogState();
}

class _TimelineTargetDialogState extends State<_TimelineTargetDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.initialTarget > 0 ? widget.initialTarget.toString() : '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Timeline target'),
    content: TextField(
      controller: _controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: const InputDecoration(
        labelText: 'Target £',
        prefixIcon: Icon(Icons.flag_outlined),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Cancel'),
      ),
      TextButton(
        onPressed: () {
          Navigator.of(context).pop(int.tryParse(_controller.text.trim()) ?? 0);
        },
        child: const Text('Save'),
      ),
    ],
  );
}

class _ReminderRow extends StatelessWidget {
  const _ReminderRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 18, color: Colors.blueGrey[700]),
      const SizedBox(width: 8),
      Expanded(
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
      Switch(value: value, onChanged: onChanged),
    ],
  );
}
