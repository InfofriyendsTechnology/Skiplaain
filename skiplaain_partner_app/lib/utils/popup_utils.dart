import 'package:flutter/material.dart';

/// Google Material Design 3 inspired centralized popup system
/// Provides consistent, beautiful, and accessible dialogs across the app
class PopupUtils {
  // Private constructor to prevent instantiation
  PopupUtils._();

  /// Show success popup with checkmark animation
  static Future<void> showSuccess(
    BuildContext context, {
    required String message,
    String? title,
    Duration duration = const Duration(seconds: 3),
  }) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _SuccessDialog(
        title: title,
        message: message,
        duration: duration,
      ),
    );
  }

  /// Show error popup with clear error message
  static Future<void> showError(
    BuildContext context, {
    required String message,
    String? title,
    VoidCallback? onRetry,
  }) async {
    return showDialog(
      context: context,
      builder: (ctx) => _ErrorDialog(
        title: title,
        message: message,
        onRetry: onRetry,
      ),
    );
  }

  /// Show warning popup for important but non-critical messages
  static Future<void> showWarning(
    BuildContext context, {
    required String message,
    String? title,
    VoidCallback? onConfirm,
  }) async {
    return showDialog(
      context: context,
      builder: (ctx) => _WarningDialog(
        title: title,
        message: message,
        onConfirm: onConfirm,
      ),
    );
  }

  /// Show info popup for general information
  static Future<void> showInfo(
    BuildContext context, {
    required String message,
    String? title,
    VoidCallback? onOk,
  }) async {
    return showDialog(
      context: context,
      builder: (ctx) => _InfoDialog(
        title: title,
        message: message,
        onOk: onOk,
      ),
    );
  }

  /// Show confirmation dialog with yes/no actions
  static Future<bool> showConfirmation(
    BuildContext context, {
    required String message,
    String? title,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    bool isDangerous = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => _ConfirmationDialog(
        title: title,
        message: message,
        confirmText: confirmText,
        cancelText: cancelText,
        isDangerous: isDangerous,
      ),
    );
    return result ?? false;
  }

  /// Show loading dialog (non-dismissible)
  static void showLoading(
    BuildContext context, {
    String message = 'Please wait...',
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _LoadingDialog(message: message),
    );
  }

  /// Hide loading dialog
  static void hideLoading(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pop();
  }

  /// Show custom modal with custom content
  static Future<T?> showCustomModal<T>(
    BuildContext context, {
    required Widget child,
    bool barrierDismissible = true,
  }) async {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF141414),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFF262626), width: 1),
        ),
        child: child,
      ),
    );
  }

  // ========== TOP NOTIFICATION SYSTEM ==========

  /// Show success notification from top (Toast-like)
  static void showSuccessNotification(
    BuildContext context,
    String message, {
    String? title,
    Duration duration = const Duration(seconds: 3),
  }) {
    _showTopNotification(
      context,
      message: message,
      title: title,
      icon: Icons.check_circle_rounded,
      backgroundColor: const Color(0xFF00FF00),
      textColor: Colors.black,
      duration: duration,
    );
  }

  /// Show error notification from top
  static void showErrorNotification(
    BuildContext context,
    String message, {
    String? title,
    Duration duration = const Duration(seconds: 4),
  }) {
    _showTopNotification(
      context,
      message: message,
      title: title,
      icon: Icons.error_rounded,
      backgroundColor: const Color(0xFFEF4444),
      textColor: Colors.white,
      duration: duration,
    );
  }

  /// Show warning notification from top
  static void showWarningNotification(
    BuildContext context,
    String message, {
    String? title,
    Duration duration = const Duration(seconds: 3),
  }) {
    _showTopNotification(
      context,
      message: message,
      title: title,
      icon: Icons.warning_rounded,
      backgroundColor: const Color(0xFFFFA500),
      textColor: Colors.black,
      duration: duration,
    );
  }

  /// Show info notification from top
  static void showInfoNotification(
    BuildContext context,
    String message, {
    String? title,
    Duration duration = const Duration(seconds: 3),
  }) {
    _showTopNotification(
      context,
      message: message,
      title: title,
      icon: Icons.info_rounded,
      backgroundColor: const Color(0xFF3B82F6),
      textColor: Colors.white,
      duration: duration,
    );
  }

  /// Internal method to show top notification
  static void _showTopNotification(
    BuildContext context, {
    required String message,
    String? title,
    required IconData icon,
    required Color backgroundColor,
    required Color textColor,
    required Duration duration,
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => _TopNotification(
        message: message,
        title: title,
        icon: icon,
        backgroundColor: backgroundColor,
        textColor: textColor,
        duration: duration,
        onDismiss: () => overlayEntry.remove(),
      ),
    );

    overlay.insert(overlayEntry);
  }
}

// ========== TOP NOTIFICATION WIDGET ==========
class _TopNotification extends StatefulWidget {
  final String message;
  final String? title;
  final IconData icon;
  final Color backgroundColor;
  final Color textColor;
  final Duration duration;
  final VoidCallback onDismiss;

  const _TopNotification({
    required this.message,
    this.title,
    required this.icon,
    required this.backgroundColor,
    required this.textColor,
    required this.duration,
    required this.onDismiss,
  });

  @override
  State<_TopNotification> createState() => _TopNotificationState();
}

class _TopNotificationState extends State<_TopNotification>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();

    // Auto dismiss
    Future.delayed(widget.duration, () async {
      if (mounted) {
        await _controller.reverse();
        widget.onDismiss();
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
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: widget.backgroundColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(
                        widget.icon,
                        color: widget.textColor,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (widget.title != null)
                              Text(
                                widget.title!,
                                style: TextStyle(
                                  color: widget.textColor,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            if (widget.title != null) const SizedBox(height: 4),
                            Text(
                              widget.message,
                              style: TextStyle(
                                color: widget.textColor.withOpacity(0.9),
                                fontSize: 14,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () async {
                          await _controller.reverse();
                          widget.onDismiss();
                        },
                        child: Icon(
                          Icons.close_rounded,
                          color: widget.textColor.withOpacity(0.7),
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ========== SUCCESS DIALOG ==========
class _SuccessDialog extends StatefulWidget {
  final String? title;
  final String message;
  final Duration duration;

  const _SuccessDialog({
    this.title,
    required this.message,
    required this.duration,
  });

  @override
  State<_SuccessDialog> createState() => _SuccessDialogState();
}

class _SuccessDialogState extends State<_SuccessDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );
    _controller.forward();

    // Auto dismiss after duration
    Future.delayed(widget.duration, () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Dialog(
        backgroundColor: const Color(0xFF141414),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFF00FF00), width: 2),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFF00FF00).withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF00FF00),
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),
              if (widget.title != null)
                Text(
                  widget.title!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              if (widget.title != null) const SizedBox(height: 8),
              Text(
                widget.message,
                style: const TextStyle(
                  color: Color(0xFFA0A0A0),
                  fontSize: 15,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ========== ERROR DIALOG ==========
class _ErrorDialog extends StatelessWidget {
  final String? title;
  final String message;
  final VoidCallback? onRetry;

  const _ErrorDialog({
    this.title,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF141414),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFEF4444), width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_rounded,
                color: Color(0xFFEF4444),
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title ?? 'Error',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(
                color: Color(0xFFA0A0A0),
                fontSize: 15,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (onRetry != null) ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        onRetry?.call();
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Color(0xFF00FF00)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Retry',
                        style: TextStyle(
                          color: Color(0xFF00FF00),
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00FF00),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'OK',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ========== WARNING DIALOG ==========
class _WarningDialog extends StatelessWidget {
  final String? title;
  final String message;
  final VoidCallback? onConfirm;

  const _WarningDialog({
    this.title,
    required this.message,
    this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF141414),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFFFA500), width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFFFA500).withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.warning_rounded,
                color: Color(0xFFFFA500),
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title ?? 'Warning',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(
                color: Color(0xFFA0A0A0),
                fontSize: 15,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  onConfirm?.call();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00FF00),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Got it',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ========== INFO DIALOG ==========
class _InfoDialog extends StatelessWidget {
  final String? title;
  final String message;
  final VoidCallback? onOk;

  const _InfoDialog({
    this.title,
    required this.message,
    this.onOk,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF141414),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFF3B82F6), width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.info_rounded,
                color: Color(0xFF3B82F6),
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            if (title != null)
              Text(
                title!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            if (title != null) const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(
                color: Color(0xFFA0A0A0),
                fontSize: 15,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  onOk?.call();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00FF00),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'OK',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ========== CONFIRMATION DIALOG ==========
class _ConfirmationDialog extends StatelessWidget {
  final String? title;
  final String message;
  final String confirmText;
  final String cancelText;
  final bool isDangerous;

  const _ConfirmationDialog({
    this.title,
    required this.message,
    required this.confirmText,
    required this.cancelText,
    required this.isDangerous,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF141414),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isDangerous ? const Color(0xFFEF4444) : const Color(0xFF262626),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: (isDangerous ? const Color(0xFFEF4444) : const Color(0xFF3B82F6))
                    .withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isDangerous ? Icons.warning_rounded : Icons.help_rounded,
                color: isDangerous ? const Color(0xFFEF4444) : const Color(0xFF3B82F6),
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            if (title != null)
              Text(
                title!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            if (title != null) const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(
                color: Color(0xFFA0A0A0),
                fontSize: 15,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: Color(0xFF666666)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      cancelText,
                      style: const TextStyle(
                        color: Color(0xFFFFFFFF),
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isDangerous ? const Color(0xFFEF4444) : const Color(0xFF00FF00),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      confirmText,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ========== LOADING DIALOG ==========
class _LoadingDialog extends StatelessWidget {
  final String message;

  const _LoadingDialog({required this.message});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF141414),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFF262626), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00FF00)),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              message,
              style: const TextStyle(
                color: Color(0xFFFFFFFF),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
