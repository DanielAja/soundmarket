import 'package:flutter/material.dart';
import '../../core/theme/color_palette.dart';
import '../../core/theme/text_styles.dart';
import '../../core/constants/string_constants.dart';

/// Error display components
class ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final IconData icon;
  final double iconSize;
  final Color? iconColor;
  
  const ErrorView({
    super.key,
    this.message = 'An error occurred',
    this.onRetry,
    this.icon = Icons.error_outline,
    this.iconSize = 64.0,
    this.iconColor,
  });
  
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: iconSize,
              color: iconColor ?? ColorPalette.error,
            ),
            const SizedBox(height: 16.0),
            Text(
              message,
              style: AppTextStyles.bodyLarge,
              textAlign: TextAlign.center,
            ),
            if (onRetry != null)
              Padding(
                padding: const EdgeInsets.only(top: 24.0),
                child: ElevatedButton(
                  onPressed: onRetry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorPalette.primary,
                    foregroundColor: ColorPalette.onPrimary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24.0,
                      vertical: 12.0,
                    ),
                  ),
                  child: Text(StringConstants.retry),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Network error view
class NetworkErrorView extends StatelessWidget {
  final VoidCallback? onRetry;
  
  const NetworkErrorView({
    super.key,
    this.onRetry,
  });
  
  @override
  Widget build(BuildContext context) {
    return ErrorView(
      message: StringConstants.networkError,
      icon: Icons.wifi_off,
      onRetry: onRetry,
    );
  }
}

/// Empty state view
class EmptyStateView extends StatelessWidget {
  final String message;
  final IconData icon;
  final double iconSize;
  final Color? iconColor;
  final VoidCallback? onAction;
  final String? actionLabel;
  
  const EmptyStateView({
    super.key,
    required this.message,
    this.icon = Icons.inbox,
    this.iconSize = 64.0,
    this.iconColor,
    this.onAction,
    this.actionLabel,
  });
  
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: iconSize,
              color: iconColor ?? ColorPalette.neutral500,
            ),
            const SizedBox(height: 16.0),
            Text(
              message,
              style: AppTextStyles.bodyLarge,
              textAlign: TextAlign.center,
            ),
            if (onAction != null && actionLabel != null)
              Padding(
                padding: const EdgeInsets.only(top: 24.0),
                child: ElevatedButton(
                  onPressed: onAction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorPalette.primary,
                    foregroundColor: ColorPalette.onPrimary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24.0,
                      vertical: 12.0,
                    ),
                  ),
                  child: Text(actionLabel!),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Error dialog
class ErrorDialog extends StatelessWidget {
  final String title;
  final String message;
  final String? buttonText;
  final VoidCallback? onButtonPressed;
  
  const ErrorDialog({
    super.key,
    this.title = 'Error',
    required this.message,
    this.buttonText,
    this.onButtonPressed,
  });
  
  // Show the dialog
  static Future<void> show(
    BuildContext context, {
    String title = 'Error',
    required String message,
    String? buttonText,
    VoidCallback? onButtonPressed,
  }) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return ErrorDialog(
          title: title,
          message: message,
          buttonText: buttonText,
          onButtonPressed: onButtonPressed,
        );
      },
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        title,
        style: AppTextStyles.titleMedium,
      ),
      content: SingleChildScrollView(
        child: Text(
          message,
          style: AppTextStyles.bodyMedium,
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: onButtonPressed ?? () => Navigator.of(context).pop(),
          child: Text(
            buttonText ?? StringConstants.confirm,
            style: AppTextStyles.buttonMedium.copyWith(
              color: ColorPalette.primary,
            ),
          ),
        ),
      ],
    );
  }
}
