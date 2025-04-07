import 'package:flutter/material.dart';
import '../../core/theme/color_palette.dart';
import '../../core/theme/text_styles.dart';

/// Empty state displays
class EmptyState extends StatelessWidget {
  final String message;
  final String? subMessage;
  final IconData icon;
  final double iconSize;
  final Color? iconColor;
  final VoidCallback? onActionPressed;
  final String? actionLabel;
  final Widget? customAction;
  
  const EmptyState({
    super.key,
    required this.message,
    this.subMessage,
    this.icon = Icons.inbox,
    this.iconSize = 80.0,
    this.iconColor,
    this.onActionPressed,
    this.actionLabel,
    this.customAction,
  });
  
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: iconSize,
              color: iconColor ?? ColorPalette.neutral400,
            ),
            const SizedBox(height: 24.0),
            Text(
              message,
              style: AppTextStyles.titleMedium,
              textAlign: TextAlign.center,
            ),
            if (subMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  subMessage!,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: ColorPalette.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            if (onActionPressed != null && actionLabel != null)
              Padding(
                padding: const EdgeInsets.only(top: 32.0),
                child: ElevatedButton(
                  onPressed: onActionPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorPalette.primary,
                    foregroundColor: ColorPalette.onPrimary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32.0,
                      vertical: 16.0,
                    ),
                  ),
                  child: Text(actionLabel!),
                ),
              ),
            if (customAction != null)
              Padding(
                padding: const EdgeInsets.only(top: 32.0),
                child: customAction!,
              ),
          ],
        ),
      ),
    );
  }
}

/// Empty portfolio state
class EmptyPortfolioState extends StatelessWidget {
  final VoidCallback? onExplorePressed;
  
  const EmptyPortfolioState({
    super.key,
    this.onExplorePressed,
  });
  
  @override
  Widget build(BuildContext context) {
    return EmptyState(
      message: 'Your portfolio is empty',
      subMessage: 'Start investing in songs you love',
      icon: Icons.library_music,
      iconColor: ColorPalette.primary.withAlpha((255 * 0.7).round()), // Replaced withOpacity
      onActionPressed: onExplorePressed,
      actionLabel: 'Explore Songs',
    );
  }
}

/// Empty transactions state
class EmptyTransactionsState extends StatelessWidget {
  final VoidCallback? onExplorePressed;
  
  const EmptyTransactionsState({
    super.key,
    this.onExplorePressed,
  });
  
  @override
  Widget build(BuildContext context) {
    return EmptyState(
      message: 'No transactions yet',
      subMessage: 'Your transaction history will appear here',
      icon: Icons.receipt_long,
      iconColor: ColorPalette.neutral500,
      onActionPressed: onExplorePressed,
      actionLabel: 'Start Trading',
    );
  }
}

/// No search results state
class NoSearchResultsState extends StatelessWidget {
  final String searchTerm;
  final VoidCallback? onClearSearch;
  
  const NoSearchResultsState({
    super.key,
    required this.searchTerm,
    this.onClearSearch,
  });
  
  @override
  Widget build(BuildContext context) {
    return EmptyState(
      message: 'No results found',
      subMessage: 'We couldn\'t find any songs matching "$searchTerm"',
      icon: Icons.search_off,
      iconColor: ColorPalette.neutral500,
      onActionPressed: onClearSearch,
      actionLabel: 'Clear Search',
    );
  }
}

/// Coming soon state
class ComingSoonState extends StatelessWidget {
  final String feature;
  final VoidCallback? onBackPressed;
  
  const ComingSoonState({
    super.key,
    required this.feature,
    this.onBackPressed,
  });
  
  @override
  Widget build(BuildContext context) {
    return EmptyState(
      message: 'Coming Soon',
      subMessage: '$feature will be available in a future update',
      icon: Icons.rocket_launch,
      iconColor: ColorPalette.secondary,
      onActionPressed: onBackPressed ?? () => Navigator.of(context).pop(),
      actionLabel: 'Go Back',
    );
  }
}
