import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

enum NotificationType {
  success,
  error,
  info,
  warning,
}

class CustomNotification extends StatelessWidget {
  final String message;
  final NotificationType type;
  final VoidCallback? onAction;
  final String? actionLabel;
  final VoidCallback onClose;
  
  const CustomNotification({
    Key? key,
    required this.message,
    this.type = NotificationType.info,
    this.onAction,
    this.actionLabel,
    required this.onClose,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Align(
          alignment: Alignment.topRight,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 300),
            decoration: BoxDecoration(
              color: _getBackgroundColor(),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      _getIcon(),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getTitle(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              message,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white, size: 18),
                        onPressed: onClose,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
                if (onAction != null && actionLabel != null)
                  InkWell(
                    onTap: onAction,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.1),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(12),
                          bottomRight: Radius.circular(12),
                        ),
                      ),
                      child: Text(
                        actionLabel!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getBackgroundColor() {
    switch (type) {
      case NotificationType.success:
        return const Color(0xFF4CAF50); // Green
      case NotificationType.error:
        return const Color(0xFFE53935); // Red
      case NotificationType.warning:
        return const Color(0xFFFF9800); // Orange
      case NotificationType.info:
      default:
        return const Color(0xFF64B5F6); // Blue
    }
  }

  String _getTitle() {
    switch (type) {
      case NotificationType.success:
        return 'Berhasil';
      case NotificationType.error:
        return 'Gagal';
      case NotificationType.warning:
        return 'Perhatian';
      case NotificationType.info:
      default:
        return 'Informasi';
    }
  }

  Widget _getIcon() {
    IconData iconData;
    switch (type) {
      case NotificationType.success:
        iconData = Icons.check_circle;
        break;
      case NotificationType.error:
        iconData = Icons.error;
        break;
      case NotificationType.warning:
        iconData = Icons.warning;
        break;
      case NotificationType.info:
      default:
        iconData = Icons.info;
    }
    
    return Icon(
      iconData,
      color: Colors.white,
      size: 24,
    );
  }
}

// Function to show notification overlay
void showCustomNotification({
  required BuildContext context,
  required String message,
  NotificationType type = NotificationType.info,
  VoidCallback? onAction,
  String? actionLabel,
  Duration duration = const Duration(seconds: 3),
}) {
  OverlayEntry? overlayEntry;
  
  overlayEntry = OverlayEntry(
    builder: (context) => Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      right: 0,
      child: CustomNotification(
        message: message,
        type: type,
        onAction: onAction,
        actionLabel: actionLabel,
        onClose: () {
          overlayEntry?.remove();
        },
      )
      .animate()
      .slideX(begin: 1, end: 0, duration: 300.ms, curve: Curves.easeOutCirc)
      .fadeIn(duration: 300.ms),
    ),
  );

  Overlay.of(context).insert(overlayEntry);

  Future.delayed(duration, () {
    if (overlayEntry?.mounted ?? false) {
      overlayEntry?.remove();
    }
  });
} 