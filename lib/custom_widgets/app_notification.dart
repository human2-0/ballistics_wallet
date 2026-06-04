import 'package:flutter/material.dart';

/// Visual category for short user-facing app notifications.
enum AppNotificationType {
  /// A completed action or successful result.
  success,

  /// A failed action or validation problem.
  error,

  /// A completed action with a caveat or recoverable issue.
  warning,

  /// Neutral information that does not indicate success or failure.
  info,
}

/// Shows one consistent floating snackbar for short action feedback.
void showAppNotification(
  BuildContext context,
  String message, {
  AppNotificationType type = AppNotificationType.info,
  Duration duration = const Duration(seconds: 4),
}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null || message.trim().isEmpty) return;

  final visual = _notificationVisualForType(type);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(visual.icon, color: visual.foreground, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: visual.foreground,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: visual.background,
        duration: duration,
      ),
    );
}

/// Shared snackbar shape and placement for the app.
SnackBarThemeData appSnackBarTheme() => SnackBarThemeData(
  behavior: SnackBarBehavior.floating,
  elevation: 8,
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
  insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
  contentTextStyle: const TextStyle(fontWeight: FontWeight.w600),
);

class _NotificationVisual {
  const _NotificationVisual({
    required this.icon,
    required this.background,
    required this.foreground,
  });

  final IconData icon;
  final Color background;
  final Color foreground;
}

_NotificationVisual _notificationVisualForType(AppNotificationType type) {
  switch (type) {
    case AppNotificationType.success:
      return const _NotificationVisual(
        icon: Icons.check_circle_outline,
        background: Color(0xFF1B5E20),
        foreground: Colors.white,
      );
    case AppNotificationType.error:
      return const _NotificationVisual(
        icon: Icons.error_outline,
        background: Color(0xFFB3261E),
        foreground: Colors.white,
      );
    case AppNotificationType.warning:
      return const _NotificationVisual(
        icon: Icons.warning_amber_rounded,
        background: Color(0xFF6D4C00),
        foreground: Colors.white,
      );
    case AppNotificationType.info:
      return const _NotificationVisual(
        icon: Icons.info_outline,
        background: Color(0xFF263238),
        foreground: Colors.white,
      );
  }
}
