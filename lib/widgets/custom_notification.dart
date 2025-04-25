import 'package:flutter/material.dart';

enum NotificationType { success, error, warning, info }

void showCustomNotification({
  required BuildContext context,
  required String message,
  NotificationType type = NotificationType.info,
  VoidCallback? onAction,
  String? actionLabel,
  Duration duration = const Duration(seconds: 3),
}) {
  final overlay = Overlay.of(context);

  // Tampilkan hanya satu notifikasi dalam satu waktu
  // Perlu variabel statis untuk melacak notifikasi yang aktif
  if (_NotificationManager.isShowing) {
    // Hapus notifikasi sebelumnya
    _NotificationManager.hideCurrentNotification();
  }

  // Dapatkan warna berdasarkan tipe
  final Color backgroundColor;
  final IconData iconData;

  switch (type) {
    case NotificationType.success:
      backgroundColor = Colors.green.shade600;
      iconData = Icons.check_circle;
      break;
    case NotificationType.error:
      backgroundColor = Colors.red.shade600;
      iconData = Icons.error;
      break;
    case NotificationType.warning:
      backgroundColor = Colors.orange.shade600;
      iconData = Icons.warning;
      break;
    case NotificationType.info:
      backgroundColor = Colors.blue.shade600;
      iconData = Icons.info;
      break;
  }

  final overlayEntry = OverlayEntry(
    builder:
        (context) => _NotificationWidget(
          message: message,
          backgroundColor: backgroundColor,
          iconData: iconData,
          onAction: onAction,
          actionLabel: actionLabel,
          duration: duration,
        ),
  );

  // Simpan overlayEntry saat ini
  _NotificationManager.currentNotification = overlayEntry;
  _NotificationManager.isShowing = true;

  overlay.insert(overlayEntry);

  // Hapus otomatis setelah durasi
  Future.delayed(duration, () {
    if (_NotificationManager.currentNotification == overlayEntry) {
      overlayEntry.remove();
      _NotificationManager.isShowing = false;
      _NotificationManager.currentNotification = null;
    }
  });
}

// Class untuk mengelola notifikasi yang ditampilkan
class _NotificationManager {
  static bool isShowing = false;
  static OverlayEntry? currentNotification;

  static void hideCurrentNotification() {
    if (currentNotification != null) {
      currentNotification!.remove();
      isShowing = false;
      currentNotification = null;
    }
  }
}

// Widget untuk menampilkan notifikasi - mutable state
class _NotificationWidget extends StatefulWidget {
  final String message;
  final Color backgroundColor;
  final IconData iconData;
  final VoidCallback? onAction;
  final String? actionLabel;
  final Duration duration;

  const _NotificationWidget({
    required this.message,
    required this.backgroundColor,
    required this.iconData,
    this.onAction,
    this.actionLabel,
    required this.duration,
  });

  @override
  _NotificationWidgetState createState() => _NotificationWidgetState();
}

class _NotificationWidgetState extends State<_NotificationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, -1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();

    // Setup exit animation
    Future.delayed(widget.duration - const Duration(milliseconds: 300), () {
      if (mounted) {
        _controller.reverse();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final hasAction = widget.onAction != null && widget.actionLabel != null;

    // Use AnimatedBuilder to optimize rendering
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Positioned(
          top: mediaQuery.viewPadding.top + 10.0,
          left: 10.0,
          right: 10.0,
          child: SlideTransition(
            position: _offsetAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Material(
                elevation: 4.0,
                borderRadius: BorderRadius.circular(12.0),
                color: widget.backgroundColor,
                child: Padding(
                  padding: EdgeInsets.only(
                    left: 16.0,
                    top: 12.0,
                    bottom: 12.0,
                    right: hasAction ? 8.0 : 16.0,
                  ),
                  child: Row(
                    children: [
                      Icon(widget.iconData, color: Colors.white, size: 24.0),
                      const SizedBox(width: 12.0),
                      Expanded(
                        child: Text(
                          widget.message,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14.0,
                          ),
                        ),
                      ),
                      if (hasAction)
                        TextButton(
                          onPressed: () {
                            _NotificationManager.hideCurrentNotification();
                            widget.onAction!();
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.white.withOpacity(0.2),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12.0,
                              vertical: 6.0,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20.0),
                            ),
                          ),
                          child: Text(
                            widget.actionLabel!,
                            style: const TextStyle(
                              fontSize: 12.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
