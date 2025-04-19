import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For HapticFeedback
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math';
import 'dart:async'; // Import Timer (Moved to top)
import '../../../shared/providers/user_data_provider.dart'; // Corrected path
import '../../../shared/models/portfolio_item.dart'; // Corrected path
import '../../../shared/models/song.dart'; // Corrected path
// Removed unused import: import '../../../shared/models/transaction.dart';
import '../../../shared/models/portfolio_snapshot.dart'; // Import Snapshot model
import '../../../shared/widgets/real_time_portfolio_widget.dart'; // Corrected path
import '../../../core/theme/app_spacing.dart'; // Corrected path

// New StatefulWidget to manage the state and controllers for the bottom sheet content
class _PortfolioItemDetailsSheetContent extends StatefulWidget {
  final PortfolioItem item;
  final Song song;
  final UserDataProvider userDataProvider;

  const _PortfolioItemDetailsSheetContent({
    // Removed Key key parameter as it's implicitly handled by StatefulWidget
    required this.item,
    required this.song,
    required this.userDataProvider,
  });

  @override
  _PortfolioItemDetailsSheetContentState createState() =>
      _PortfolioItemDetailsSheetContentState();
}

class _PortfolioItemDetailsSheetContentState
    extends State<_PortfolioItemDetailsSheetContent> {
  late final TextEditingController _quantityController;
  late final ValueNotifier<int> _quantityNotifier;

  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController(text: '1');
    _quantityNotifier = ValueNotifier<int>(1);

    // Add listener to update notifier when text changes
    _quantityController.addListener(() {
      final newQuantity = int.tryParse(_quantityController.text) ?? 0;
      if (newQuantity >= 0 && _quantityNotifier.value != newQuantity) {
        _quantityNotifier.value = newQuantity;
      } else if (newQuantity < 0 && _quantityController.text.isNotEmpty) {
        // Reset to 0 if negative input
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _quantityController.text = '0';
            _quantityController.selection = TextSelection.fromPosition(
              TextPosition(offset: _quantityController.text.length),
            );
            if (_quantityNotifier.value != 0) {
              _quantityNotifier.value = 0;
            }
          }
        });
      } else if (_quantityController.text.isEmpty &&
          _quantityNotifier.value != 0) {
        // Handle empty text field case: set notifier to 0
        _quantityNotifier.value = 0;
      }
    });

    // Add listener to update text field when notifier changes
    _quantityNotifier.addListener(() {
      final currentText = _quantityController.text;
      final notifierValueString = _quantityNotifier.value.toString();
      if (currentText != notifierValueString) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _quantityController.text = notifierValueString;
            _quantityController.selection = TextSelection.fromPosition(
              TextPosition(offset: _quantityController.text.length),
            );
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _quantityNotifier.dispose();
    super.dispose();
  }

  // Redefined dialog logic here for encapsulation
  void _showFullAlbumArtDialog(
    BuildContext context,
    String albumArtUrl,
    String songName,
    String artistName,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(AppSpacing.l),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  // Album Art
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.9,
                      maxHeight: MediaQuery.of(context).size.height * 0.6,
                    ),
                    child: Image.network(
                      albumArtUrl,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          width: MediaQuery.of(context).size.width * 0.9,
                          height: MediaQuery.of(context).size.width * 0.9,
                          color: Colors.grey[900],
                          child: Center(
                            child: CircularProgressIndicator(
                              value:
                                  loadingProgress.expectedTotalBytes != null &&
                                          loadingProgress.expectedTotalBytes! >
                                              0
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                            ),
                          ),
                        );
                      },
                      errorBuilder:
                          (context, error, stackTrace) => Container(
                            width: MediaQuery.of(context).size.width * 0.9,
                            height: MediaQuery.of(context).size.width * 0.9,
                            color: Colors.grey[900],
                            child: const Center(
                              child: Icon(
                                Icons.error_outline,
                                size: 50,
                                color: Colors.white,
                              ),
                            ),
                          ),
                    ),
                  ),
                ),
                Container(
                  // Song Info
                  padding: const EdgeInsets.all(AppSpacing.l),
                  margin: const EdgeInsets.only(top: AppSpacing.l),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(180),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        songName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        artistName,
                        style: TextStyle(fontSize: 16, color: Colors.grey[300]),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                Padding(
                  // Close Button
                  padding: const EdgeInsets.only(top: AppSpacing.l),
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[800],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: const Text('CLOSE'),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Calculate values based on widget properties
    final currentValue = widget.song.currentPrice * widget.item.quantity;
    final purchaseValue = widget.item.purchasePrice * widget.item.quantity;
    double profitLoss = 0.0;
    double profitLossPercent = 0.0;
    if (purchaseValue.abs() > 0.001) {
      profitLoss = currentValue - purchaseValue;
      profitLossPercent = (profitLoss / purchaseValue) * 100;
    } else if (currentValue > 0) {
      profitLoss = currentValue;
      profitLossPercent = double.infinity;
    }
    final isProfit = profitLoss >= 0;

    // Use ValueListenableBuilder to react to quantity changes for button states etc.
    return ValueListenableBuilder<int>(
      valueListenable: _quantityNotifier,
      builder: (context, currentQuantity, child) {
        final transactionValue = widget.song.currentPrice * currentQuantity;
        final cashBalance =
            widget.userDataProvider.userProfile?.cashBalance ?? 0.0;
        final canBuy = cashBalance >= transactionValue && currentQuantity > 0;
        final canSell =
            widget.item.quantity >= currentQuantity && currentQuantity > 0;

        // Wrap with Padding to handle keyboard overlap
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.9,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: SingleChildScrollView(
              child: Padding(
                // Keep original padding for content, outer padding handles keyboard
                padding: const EdgeInsets.only(
                  bottom: AppSpacing.l,
                  left: AppSpacing.l,
                  right: AppSpacing.l,
                  top: AppSpacing.s,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle bar
                    Center(
                      child: Container(
                        margin: const EdgeInsets.only(
                          top: AppSpacing.s,
                          bottom: AppSpacing.m,
                        ),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[600],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                    // Header with song info
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.m,
                      ),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              if (widget.item.albumArtUrl != null) {
                                _showFullAlbumArtDialog(
                                  context,
                                  widget.item.albumArtUrl!,
                                  widget.item.songName,
                                  widget.item.artistName,
                                );
                              }
                            },
                            child: CircleAvatar(
                              radius: 30,
                              backgroundColor: Colors.grey[800],
                              backgroundImage:
                                  widget.item.albumArtUrl != null
                                      ? NetworkImage(widget.item.albumArtUrl!)
                                      : null,
                              child:
                                  widget.item.albumArtUrl == null
                                      ? const Icon(Icons.music_note, size: 30)
                                      : null,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.l),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.item.songName,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                                Text(
                                  widget.item.artistName,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[400],
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.category,
                                      size: 14,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(width: AppSpacing.xs),
                                    Expanded(
                                      child: Text(
                                        widget.song.genre,
                                        style: TextStyle(
                                          color: Colors.grey[400],
                                          fontSize: 12,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Listen button
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.m,
                      ),
                      child: ElevatedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Opening ${widget.item.songName}... (Not implemented)',
                              ),
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.play_circle_filled,
                          color: Colors.white,
                        ),
                        label: const Text('LISTEN TO SONG'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 48),
                        ),
                      ),
                    ),

                    const Divider(),

                    // Current price and performance
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.l,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Current Price',
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              StreamBuilder<List<Song>>(
                                stream:
                                    Provider.of<UserDataProvider>(
                                      context,
                                      listen: false,
                                    ).songUpdatesStream,
                                initialData: const [],
                                builder: (context, snapshot) {
                                  // Find the current song in the updates if available
                                  Song? updatedSong;
                                  if (snapshot.hasData) {
                                    updatedSong = snapshot.data!.firstWhere(
                                      (s) => s.id == widget.song.id,
                                      orElse: () => widget.song,
                                    );
                                  }

                                  // Use updated song data if available, otherwise use widget.song
                                  final displaySong =
                                      updatedSong ?? widget.song;

                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '\$${displaySong.currentPrice.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: AppSpacing.xs),
                                      Row(
                                        children: [
                                          Icon(
                                            displaySong.isPriceUp
                                                ? Icons.arrow_upward
                                                : Icons.arrow_downward,
                                            color:
                                                displaySong.isPriceUp
                                                    ? Colors.green
                                                    : Colors.red,
                                            size: 14,
                                          ),
                                          const SizedBox(width: AppSpacing.xs),
                                          Text(
                                            '${displaySong.isPriceUp ? "+" : ""}${displaySong.priceChangePercent.toStringAsFixed(2)}%',
                                            style: TextStyle(
                                              color:
                                                  displaySong.isPriceUp
                                                      ? Colors.green
                                                      : Colors.red,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Your Position',
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                '${widget.item.quantity} ${widget.item.quantity == 1 ? 'share' : 'shares'}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                'Avg. Price: \$${widget.item.purchasePrice.toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Portfolio value and profit/loss
                    Container(
                      color: Colors.grey[900],
                      padding: const EdgeInsets.all(AppSpacing.l),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Current Value',
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              // Use StreamBuilder here to update current value in real-time
                              StreamBuilder<List<Song>>(
                                stream:
                                    Provider.of<UserDataProvider>(
                                      context,
                                      listen: false,
                                    ).songUpdatesStream,
                                initialData: const [],
                                builder: (context, snapshot) {
                                  // Recalculate the current value using the latest song prices
                                  double updatedCurrentValue = currentValue;
                                  if (snapshot.hasData &&
                                      snapshot.data!.isNotEmpty) {
                                    // Find the current song in the updates if available
                                    Song? updatedSong = snapshot.data!
                                        .firstWhere(
                                          (s) => s.id == widget.song.id,
                                          orElse: () => widget.song,
                                        );

                                    // Recalculate current value with updated price
                                    updatedCurrentValue =
                                        updatedSong.currentPrice *
                                        widget.item.quantity;
                                  }

                                  return AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 300),
                                    child: Text(
                                      '\$${updatedCurrentValue.toStringAsFixed(2)}',
                                      key: ValueKey<String>(
                                        updatedCurrentValue.toStringAsFixed(2),
                                      ),
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Profit/Loss',
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              // Use StreamBuilder here to update profit/loss in real-time
                              StreamBuilder<List<Song>>(
                                stream:
                                    Provider.of<UserDataProvider>(
                                      context,
                                      listen: false,
                                    ).songUpdatesStream,
                                initialData: const [],
                                builder: (context, snapshot) {
                                  // Recalculate profit/loss with updated prices
                                  double updatedCurrentValue = currentValue;
                                  double updatedProfitLoss = profitLoss;
                                  double updatedProfitLossPercent =
                                      profitLossPercent;
                                  bool updatedIsProfit = isProfit;

                                  if (snapshot.hasData &&
                                      snapshot.data!.isNotEmpty) {
                                    // Find the current song in the updates if available
                                    Song? updatedSong = snapshot.data!
                                        .firstWhere(
                                          (s) => s.id == widget.song.id,
                                          orElse: () => widget.song,
                                        );

                                    // Recalculate with updated price
                                    updatedCurrentValue =
                                        updatedSong.currentPrice *
                                        widget.item.quantity;
                                    updatedProfitLoss =
                                        updatedCurrentValue - purchaseValue;
                                    if (purchaseValue.abs() > 0.001) {
                                      updatedProfitLossPercent =
                                          (updatedProfitLoss / purchaseValue) *
                                          100;
                                    } else if (updatedCurrentValue > 0) {
                                      updatedProfitLossPercent =
                                          double.infinity;
                                    }
                                    updatedIsProfit = updatedProfitLoss >= 0;
                                  }

                                  return AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 300),
                                    child: Row(
                                      key: ValueKey<String>(
                                        '${updatedProfitLoss.toStringAsFixed(2)}_${updatedProfitLossPercent.toStringAsFixed(2)}',
                                      ),
                                      children: [
                                        Icon(
                                          updatedIsProfit
                                              ? Icons.arrow_upward
                                              : Icons.arrow_downward,
                                          color:
                                              updatedIsProfit
                                                  ? Colors.green
                                                  : Colors.red,
                                          size: 14,
                                        ),
                                        const SizedBox(width: AppSpacing.xs),
                                        Text(
                                          '${updatedIsProfit ? "+" : ""}${updatedProfitLoss.toStringAsFixed(2)} (${updatedIsProfit ? "+" : ""}${updatedProfitLossPercent.isFinite ? updatedProfitLossPercent.toStringAsFixed(2) + "%" : "0.00%"})',
                                          style: TextStyle(
                                            color:
                                                updatedIsProfit
                                                    ? Colors.green
                                                    : Colors.red,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.l),

                    // Transaction section
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.m,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Trade',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.l),
                          Row(
                            // Quantity Input
                            children: [
                              const Text(
                                'Quantity:',
                                style: TextStyle(fontSize: 16),
                              ),
                              const SizedBox(width: AppSpacing.l),
                              Expanded(
                                child: TextField(
                                  controller:
                                      _quantityController, // Use the state's controller
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                  ),
                                  // onChanged is handled by the controller listener
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.l),
                          Row(
                            // Transaction Value
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Transaction Value:',
                                style: TextStyle(fontSize: 16),
                              ),
                              Text(
                                '\$${transactionValue.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.s),
                          Row(
                            // Cash Balance
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Cash Balance:',
                                style: TextStyle(fontSize: 16),
                              ),
                              Text(
                                '\$${cashBalance.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: canBuy ? Colors.white : Colors.red,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          Row(
                            // Buy/Sell Buttons
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed:
                                      canBuy
                                          ? () async {
                                            final success = await widget
                                                .userDataProvider
                                                .buySong(
                                                  widget.song.id,
                                                  currentQuantity,
                                                );
                                            if (!mounted)
                                              return; // Check mounted after await
                                            if (success) {
                                              Navigator.pop(context);
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    'Successfully bought $currentQuantity ${currentQuantity == 1 ? 'share' : 'shares'} of ${widget.song.name}',
                                                  ),
                                                  backgroundColor: Colors.green,
                                                ),
                                              );
                                            } else {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Failed to buy shares. Insufficient funds or error occurred.',
                                                  ),
                                                  backgroundColor: Colors.red,
                                                ),
                                              );
                                            }
                                          }
                                          : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    disabledBackgroundColor: Colors.green
                                        .withOpacity(0.5),
                                  ),
                                  child: const Text(
                                    'BUY',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.l),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed:
                                      canSell
                                          ? () async {
                                            final success = await widget
                                                .userDataProvider
                                                .sellSong(
                                                  widget.song.id,
                                                  currentQuantity,
                                                );
                                            if (!mounted)
                                              return; // Check mounted after await
                                            if (success) {
                                              Navigator.pop(context);
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    'Successfully sold $currentQuantity ${currentQuantity == 1 ? 'share' : 'shares'} of ${widget.song.name}',
                                                  ),
                                                  backgroundColor: Colors.blue,
                                                ),
                                              );
                                            } else {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Failed to sell shares. Insufficient shares or error occurred.',
                                                  ),
                                                  backgroundColor: Colors.red,
                                                ),
                                              );
                                            }
                                          }
                                          : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    disabledBackgroundColor: Colors.red
                                        .withOpacity(0.5),
                                  ),
                                  child: const Text(
                                    'SELL',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      // Close Button
                      padding: const EdgeInsets.only(top: AppSpacing.l),
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[800],
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('CLOSE'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class HomeScreen extends StatefulWidget {
  HomeScreen({super.key}); // Removed const

  @override
  State<HomeScreen> createState() => _HomeScreenState();
} // Moved closing brace

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  String _selectedTimeFilter = '1W'; // Default to 1 week
  List<PortfolioSnapshot> _chartData = []; // Store fetched snapshots
  bool _isChartLoading = true;
  Timer? _liveUpdateTimer; // Timer for 1D updates

  // Animation controllers for live price pulse effect
  late AnimationController _pulseAnimationController;

  @override
  void initState() {
    super.initState();

    // Initialize animation controller for pulse effect
    _pulseAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    // Fetch initial chart data after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _updateChartData(_selectedTimeFilter);
      }
    });
  }

  @override
  void dispose() {
    _liveUpdateTimer?.cancel(); // Cancel timer on dispose
    _pulseAnimationController.dispose(); // Dispose animation controller
    super.dispose();
  }

  // Stop existing timer and start a new one if filter is '1D'
  void _manageLiveUpdateTimer(String timeFilter) {
    _liveUpdateTimer?.cancel();
    if (timeFilter == '1D') {
      _liveUpdateTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
        // Periodically refresh 1D data if the widget is still mounted
        if (mounted && _selectedTimeFilter == '1D') {
          _updateChartData(
            '1D',
            isLiveUpdate: true,
          ); // Pass flag to avoid full loading indicator
        } else {
          timer.cancel(); // Cancel if filter changed or widget disposed
        }
      });
    }
  }

  // Method to update chart data asynchronously by fetching from provider
  Future<void> _updateChartData(
    String timeFilter, {
    bool isLiveUpdate = false,
  }) async {
    if (!mounted) return;

    // Manage the live update timer based on the selected filter
    _manageLiveUpdateTimer(timeFilter);

    // Show full loading indicator only if it's not a background live update
    if (!isLiveUpdate) {
      // Use post frame callback to avoid calling setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _isChartLoading = true;
            _chartData = []; // Clear data immediately for loading effect
          });
        }
      });
    }

    final userDataProvider = Provider.of<UserDataProvider>(
      context,
      listen: false,
    );
    final now = DateTime.now();
    DateTime startDate;
    final endDate = now; // End date is always now

    // Determine start date based on time filter
    switch (timeFilter) {
      case '1D':
        startDate = DateTime(now.year, now.month, now.day); // Midnight today
        break;
      case '1W':
        startDate = now.subtract(const Duration(days: 7));
        break;
      case '1M':
        startDate = now.subtract(const Duration(days: 30));
        break;
      case '3M':
        startDate = now.subtract(const Duration(days: 90));
        break;
      case '1Y':
        startDate = now.subtract(const Duration(days: 365));
        break;
      case 'All':
      default:
        // Fetch the earliest timestamp from the database
        final earliestTimestamp = await userDataProvider.getEarliestTimestamp();
        // Use earliest timestamp or a default fallback (e.g., a year ago)
        startDate =
            earliestTimestamp ?? now.subtract(const Duration(days: 365));
        break;
    }

    try {
      // Fetch the data for the calculated range
      final newChartData = await userDataProvider.fetchPortfolioHistory(
        startDate,
        endDate,
      );

      // Ensure widget is still mounted before updating state
      if (mounted) {
        // Use post frame callback to avoid calling setState during build/layout phases
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _chartData = newChartData;
              _isChartLoading = false; // Loading finished
            });
          }
        });
      }
    } catch (error) {
      // Handle errors during data fetching
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _isChartLoading = false; // Stop loading indicator on error
              _chartData = []; // Clear potentially partial data
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error fetching chart data: $error')),
            );
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/icon/app_icon.png', width: 28, height: 28),
            const SizedBox(width: 8),
            const Text('Sound Market'),
          ],
        ),
      ),
      body: Consumer<UserDataProvider>(
        builder: (context, userDataProvider, child) {
          // Show loading indicator only if the provider itself is loading initial data
          // OR if the chart data is specifically being loaded
          if (userDataProvider.isLoading || _isChartLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          // **FIXED: Removed check for non-existent errorMessage**
          // if (userDataProvider.errorMessage != null) {
          //    return Center(child: Text('Error: ${userDataProvider.errorMessage}'));
          // }

          return RefreshIndicator(
            onRefresh: () async {
              // Pull to refresh functionality - refresh data and chart
              try {
                await userDataProvider.refreshData();
                if (mounted) {
                  await _updateChartData(_selectedTimeFilter); // Refresh chart
                }
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Refreshed market data')),
                  );
                }
              } catch (error) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error refreshing data: $error')),
                  );
                }
              }
            },
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.l),
              children: [
                _buildPortfolioChart(context, _chartData), // Pass fetched data
                const SizedBox(height: AppSpacing.xl),
                _buildPortfolioSummary(
                  context,
                  userDataProvider,
                  _chartData,
                ), // Pass fetched data
                const SizedBox(height: AppSpacing.l),
                RealTimePortfolioWidget(
                  // Ensure song data is available before showing details
                  onItemTap: (item, song) {
                    if (song != null) {
                      _showPortfolioItemDetails(context, item, song);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Song data not available for ${item.songName}',
                          ),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPortfolioSummary(
    BuildContext context,
    UserDataProvider userDataProvider,
    List<PortfolioSnapshot> currentChartData, // Use fetched data
  ) {
    final currentPortfolioValue = userDataProvider.totalPortfolioValue;
    // Use null-aware operator with default value for cashBalance
    final cashBalance = userDataProvider.userProfile?.cashBalance ?? 0.0;
    final totalBalance = userDataProvider.totalBalance;

    // Calculate gain/loss based on the *selected time range* using currentChartData
    double rangeGainLoss = 0.0;
    double rangeGainLossPercent = 0.0;
    String rangeLabel = _selectedTimeFilter; // Default label

    if (currentChartData.isNotEmpty) {
      final initialValue = currentChartData.first.value;
      if (initialValue.abs() > 0.001) {
        // Avoid division by near-zero
        rangeGainLoss = currentPortfolioValue - initialValue;
        rangeGainLossPercent = (rangeGainLoss / initialValue) * 100;
      } else if (currentPortfolioValue > 0) {
        // Handle case where initial value was zero but current is positive
        rangeGainLoss = currentPortfolioValue;
        rangeGainLossPercent =
            double.infinity; // Or a large number/special display
      }
      // If initial and current are both zero, gain/loss remains 0.0
    } else {
      // If no data for the range, but we have a current value, gain/loss is undefined relative to range start
      // We could show "N/A" or just the current value without change figures.
      // For simplicity, let's keep it 0 if no range data.
      rangeGainLoss = 0.0;
      rangeGainLossPercent = 0.0;
    }

    // Adjust label for clarity
    switch (_selectedTimeFilter) {
      case '1D':
        rangeLabel = 'Today';
        break;
      case '1W':
        rangeLabel = 'Past Week';
        break;
      case '1M':
        rangeLabel = 'Past Month';
        break;
      case '3M':
        rangeLabel = 'Past 3 Months';
        break;
      case '1Y':
        rangeLabel = 'Past Year';
        break;
      case 'All':
        rangeLabel = 'All Time';
        break;
    }

    final isPositiveGain = rangeGainLoss >= 0;

    return Card(
      elevation: 4.0,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.l), // Use AppSpacing.l
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Portfolio Summary',
              style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.l), // Use AppSpacing.l
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment:
                  CrossAxisAlignment.start, // Align columns to top
              children: [
                // Left Column (Portfolio Value & Gain/Loss) - Make it flexible
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Portfolio Value',
                            style: TextStyle(color: Colors.grey[400]),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          // Stream count icon/indicator for real-time updates with pulse animation
                        ],
                      ),
                      // Corrected: Removed the duplicate AnimatedSwitcher
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 500),
                        transitionBuilder: (
                          Widget child,
                          Animation<double> animation,
                        ) {
                          return FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0.0, 0.5),
                                end: Offset.zero,
                              ).animate(animation),
                              child: child,
                            ),
                          );
                        },
                        child: Text(
                          '\$${currentPortfolioValue.toStringAsFixed(2)}', // Use currentPortfolioValue
                          key: ValueKey<String>(
                            currentPortfolioValue.toStringAsFixed(2),
                          ), // Use currentPortfolioValue
                          style: const TextStyle(
                            fontSize: 24.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: AppSpacing.xs,
                      ), // Use AppSpacing.xs
                      // Use StreamBuilder to update the gain/loss in real-time
                      StreamBuilder<List<Song>>(
                        stream:
                            Provider.of<UserDataProvider>(
                              context,
                              listen: false,
                            ).songUpdatesStream,
                        initialData: const [],
                        builder: (context, snapshot) {
                          // Re-calculate with latest data
                          double updatedCurrentPortfolioValue =
                              currentPortfolioValue;
                          double updatedRangeGainLoss = rangeGainLoss;
                          double updatedRangeGainLossPercent =
                              rangeGainLossPercent;
                          bool updatedIsPositiveGain = isPositiveGain;

                          // If we have fresh data and at least one portfolio snapshot
                          if (snapshot.hasData &&
                              snapshot.data!.isNotEmpty &&
                              currentChartData.isNotEmpty) {
                            // Get the latest portfolio value by recalculating based on updated song prices
                            updatedCurrentPortfolioValue = userDataProvider
                                .calculatePortfolioValue(
                                  snapshot.data!, // Use updated song prices
                                  userDataProvider
                                      .portfolio, // Use existing portfolio items
                                );

                            // Recalculate gain/loss with the updated portfolio value
                            final initialValue = currentChartData.first.value;
                            if (initialValue.abs() > 0.001) {
                              updatedRangeGainLoss =
                                  updatedCurrentPortfolioValue - initialValue;
                              updatedRangeGainLossPercent =
                                  (updatedRangeGainLoss / initialValue) * 100;
                            } else if (updatedCurrentPortfolioValue > 0) {
                              updatedRangeGainLoss =
                                  updatedCurrentPortfolioValue;
                              updatedRangeGainLossPercent = double.infinity;
                            }
                            updatedIsPositiveGain = updatedRangeGainLoss >= 0;
                          }

                          return AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: Row(
                              key: ValueKey<String>(
                                '${updatedRangeGainLoss.toStringAsFixed(2)}_${updatedRangeGainLossPercent.toStringAsFixed(2)}',
                              ),
                              children: [
                                Icon(
                                  updatedIsPositiveGain
                                      ? Icons.arrow_upward
                                      : Icons.arrow_downward,
                                  color:
                                      updatedIsPositiveGain
                                          ? Colors.green
                                          : Colors.red,
                                  size: 16.0,
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                Expanded(
                                  child: Text(
                                    '${updatedIsPositiveGain ? "+" : ""}${updatedRangeGainLoss.toStringAsFixed(2)} (${updatedIsPositiveGain ? "+" : ""}${updatedRangeGainLossPercent.isFinite ? updatedRangeGainLossPercent.toStringAsFixed(2) + "%" : "0.00%"}) $rangeLabel',
                                    style: TextStyle(
                                      color:
                                          updatedIsPositiveGain
                                              ? Colors.green
                                              : Colors.red,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                // Add some spacing between the columns
                const SizedBox(width: AppSpacing.m),
                // Right Column (Cash Balance) - Keep it fixed size or less flexible
                Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start, // Changed to start for alignment
                  children: [
                    Text(
                      'Cash Balance',
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 500),
                      transitionBuilder: (
                        Widget child,
                        Animation<double> animation,
                      ) {
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0.0, 0.5),
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        );
                      },
                      child: Text(
                        '\$${cashBalance.toStringAsFixed(2)}',
                        key: ValueKey<String>(cashBalance.toStringAsFixed(2)),
                        style: const TextStyle(
                          fontSize: 20.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    // Add SizedBox to align with the bottom of the left column if needed
                    const SizedBox(height: 20), // Adjust height as necessary
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.l), // Use AppSpacing.l
            const Divider(),
            const SizedBox(height: AppSpacing.s), // Use AppSpacing.s
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Balance',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  transitionBuilder: (
                    Widget child,
                    Animation<double> animation,
                  ) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.0, 0.5),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: Text(
                    '\$${totalBalance.toStringAsFixed(2)}',
                    key: ValueKey<String>(totalBalance.toStringAsFixed(2)),
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
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

  // Generate FlSpot data from PortfolioSnapshots, applying aggregation if needed
  List<FlSpot> _generateChartSpots(
    List<PortfolioSnapshot> snapshots,
    String timeFilter,
    double currentPortfolioValue, // Pass current value for final point
  ) {
    if (snapshots.isEmpty) {
      // If no history for the range, show a flat line at the current value
      final startX = 0.0;
      final endX = 1.0;
      return [
        FlSpot(startX, currentPortfolioValue),
        FlSpot(endX, currentPortfolioValue),
      ];
    }

    // --- Data Aggregation based on timeFilter ---
    List<PortfolioSnapshot> processedSnapshots = snapshots;

    // Apply different aggregation strategies based on time filter
    if (timeFilter == '1Y' && snapshots.length > 300) {
      // For 1 year, aggregate weekly
      processedSnapshots = _aggregateWeeklyAverage(snapshots);
    } else if (timeFilter == 'All' && snapshots.length > 500) {
      // For all time, aggregate monthly
      processedSnapshots = _aggregateMonthlyAverage(snapshots);
    } else if ((timeFilter == '3M' || timeFilter == '1M') &&
        snapshots.length > 150) {
      // For 3 months or 1 month, aggregate daily
      processedSnapshots = _aggregateDailyAverage(snapshots);
    } else if (timeFilter == '1D' && snapshots.length > 60) {
      // For 1 day, take samples every 5 minutes
      processedSnapshots = _sampleData(snapshots, 5); // Sample every 5 points
    }

    if (processedSnapshots.isEmpty) {
      processedSnapshots = snapshots; // Revert if aggregation empties list
    }

    // --- Generate normalized FlSpots (x values between 0.0 and 1.0) ---
    final spots = <FlSpot>[];
    if (processedSnapshots.isEmpty) {
      return [
        FlSpot(0, currentPortfolioValue),
        FlSpot(1, currentPortfolioValue),
      ]; // Fallback
    }

    final firstTimestamp = processedSnapshots.first.timestamp;
    final lastTimestamp = processedSnapshots.last.timestamp;
    final totalDuration =
        lastTimestamp.difference(firstTimestamp).inMilliseconds;

    // If duration is 0 (only one data point), handle it specially
    if (totalDuration == 0) {
      return [
        FlSpot(0, processedSnapshots.first.value),
        FlSpot(1, currentPortfolioValue),
      ];
    }

    // Create normalized spots
    for (int i = 0; i < processedSnapshots.length; i++) {
      final snapshot = processedSnapshots[i];
      // Normalize x value to range 0.0-1.0 for better scaling
      final double xValue =
          (snapshot.timestamp.difference(firstTimestamp).inMilliseconds) /
          totalDuration;
      spots.add(FlSpot(xValue, snapshot.value));
    }

    // Add current value as last point if needed
    final now = DateTime.now();
    if (now.isAfter(lastTimestamp)) {
      // Only add if current time is after last snapshot
      final double currentXValue;
      if (now.difference(lastTimestamp).inMinutes < 10) {
        // If last point is very recent, place current value just a bit after
        currentXValue = 1.0;
      } else {
        // Otherwise normalize based on actual time difference
        currentXValue =
            (now.difference(firstTimestamp).inMilliseconds) / totalDuration;
      }
      // Only add if it doesn't create a duplicate x value
      if (spots.isEmpty || currentXValue > spots.last.x) {
        spots.add(FlSpot(currentXValue.clamp(0, 1), currentPortfolioValue));
      }
    }

    // Ensure we have at least two points
    if (spots.isEmpty) {
      spots.add(FlSpot(0, currentPortfolioValue));
      spots.add(FlSpot(1, currentPortfolioValue));
    } else if (spots.length == 1) {
      spots.add(FlSpot(1, spots.first.y));
    }

    return spots;
  }

  // Sample data by taking every nth point
  List<PortfolioSnapshot> _sampleData(
    List<PortfolioSnapshot> snapshots,
    int sampleRate,
  ) {
    if (snapshots.isEmpty || sampleRate <= 1) return snapshots;

    final List<PortfolioSnapshot> sampled = [];
    for (int i = 0; i < snapshots.length; i += sampleRate) {
      if (i < snapshots.length) {
        sampled.add(snapshots[i]);
      }
    }

    // Always include the last point
    if (sampled.isEmpty || sampled.last != snapshots.last) {
      sampled.add(snapshots.last);
    }

    return sampled;
  }

  // Weekly aggregation for longer timeframes
  List<PortfolioSnapshot> _aggregateWeeklyAverage(
    List<PortfolioSnapshot> snapshots,
  ) {
    if (snapshots.isEmpty) return [];
    Map<int, List<double>> weeklyValues = {};

    for (var snapshot in snapshots) {
      // Get year and week number
      final date = snapshot.timestamp;
      final int year = date.year;
      final int weekNumber =
          (date.difference(DateTime(date.year, 1, 1)).inDays / 7).floor();
      final int weekKey = year * 100 + weekNumber; // Unique key: YYYYWW

      weeklyValues.putIfAbsent(weekKey, () => []).add(snapshot.value);
    }

    List<PortfolioSnapshot> aggregated = [];
    final sortedWeeks = weeklyValues.keys.toList()..sort();

    for (var weekKey in sortedWeeks) {
      final values = weeklyValues[weekKey]!;
      if (values.isNotEmpty) {
        final average = values.reduce((a, b) => a + b) / values.length;

        // Create a date for this week - approximate to middle of week
        final year = weekKey ~/ 100;
        final week = weekKey % 100;
        final weekDate = DateTime(year, 1, 1).add(Duration(days: week * 7 + 3));

        aggregated.add(PortfolioSnapshot(timestamp: weekDate, value: average));
      }
    }

    return aggregated;
  }

  // Monthly aggregation for very long timeframes
  List<PortfolioSnapshot> _aggregateMonthlyAverage(
    List<PortfolioSnapshot> snapshots,
  ) {
    if (snapshots.isEmpty) return [];
    Map<int, List<double>> monthlyValues = {};

    for (var snapshot in snapshots) {
      final date = snapshot.timestamp;
      final int monthKey = date.year * 100 + date.month; // YYYYMM

      monthlyValues.putIfAbsent(monthKey, () => []).add(snapshot.value);
    }

    List<PortfolioSnapshot> aggregated = [];
    final sortedMonths = monthlyValues.keys.toList()..sort();

    for (var monthKey in sortedMonths) {
      final values = monthlyValues[monthKey]!;
      if (values.isNotEmpty) {
        final average = values.reduce((a, b) => a + b) / values.length;

        // Create a date for middle of this month
        final year = monthKey ~/ 100;
        final month = monthKey % 100;
        final monthDate = DateTime(year, month, 15); // Middle of month

        aggregated.add(PortfolioSnapshot(timestamp: monthDate, value: average));
      }
    }

    return aggregated;
  }

  // Helper for basic daily aggregation
  List<PortfolioSnapshot> _aggregateDailyAverage(
    List<PortfolioSnapshot> snapshots,
  ) {
    if (snapshots.isEmpty) return [];
    Map<DateTime, List<double>> dailyValues = {};
    for (var snapshot in snapshots) {
      final day = DateTime(
        snapshot.timestamp.year,
        snapshot.timestamp.month,
        snapshot.timestamp.day,
      );
      dailyValues.putIfAbsent(day, () => []).add(snapshot.value);
    }
    List<PortfolioSnapshot> aggregated = [];
    final sortedDays = dailyValues.keys.toList()..sort();
    for (var day in sortedDays) {
      final values = dailyValues[day]!;
      if (values.isNotEmpty) {
        final average = values.reduce((a, b) => a + b) / values.length;
        aggregated.add(PortfolioSnapshot(timestamp: day, value: average));
      }
    }
    return aggregated;
  }

  Widget _buildPortfolioChart(
    BuildContext context,
    List<PortfolioSnapshot> chartData,
  ) {
    final userDataProvider = Provider.of<UserDataProvider>(
      context,
      listen: false,
    );
    final currentPortfolioValue = userDataProvider.totalPortfolioValue;
    final spots = _generateChartSpots(
      chartData,
      _selectedTimeFilter,
      currentPortfolioValue,
    );

    double minY = 0.0;
    double maxY = 1.0;
    bool isPositive = true;
    double percentageChange = 0.0;
    double startValue = 0.0;
    double endValue = currentPortfolioValue;

    if (spots.isNotEmpty) {
      minY = spots.map((spot) => spot.y).fold(double.infinity, min);
      maxY = spots.map((spot) => spot.y).fold(double.negativeInfinity, max);
      startValue = spots.first.y;
      endValue = spots.last.y;

      // Add decent padding for better visualization
      if ((maxY - minY).abs() < 0.01) {
        // For very flat charts, create some visual range
        final center = (maxY + minY) / 2;
        minY = center - max(0.1, center.abs() * 0.1);
        maxY = center + max(0.1, center.abs() * 0.1);
        if (spots.every((s) => s.y >= 0) && minY < 0) {
          minY = 0;
          if ((maxY - minY).abs() < 0.1) maxY = minY + 0.1;
        }
      } else {
        // Add percentage padding for normal charts
        final padding =
            (maxY - minY) * 0.1; // Increased padding for better visualization
        final potentialMinY = minY - padding;
        minY =
            spots.every((s) => s.y >= 0) && potentialMinY < 0
                ? 0
                : potentialMinY;
        maxY += padding;
      }

      // Ensure maxY is always greater than minY
      if (maxY <= minY) {
        maxY = minY + 0.1;
      }

      // Calculate percentage change for display
      isPositive = endValue >= startValue;
      if (startValue.abs() > 0.001) {
        percentageChange = ((endValue / startValue) - 1) * 100;
      } else if (endValue > startValue) {
        percentageChange = double.infinity;
      } else {
        percentageChange = 0.0;
      }
    } else if (!_isChartLoading) {
      // Default values when no data but not loading
      minY = max(
        0,
        currentPortfolioValue - max(0.1, currentPortfolioValue.abs() * 0.1),
      );
      maxY =
          currentPortfolioValue + max(0.1, currentPortfolioValue.abs() * 0.1);
      if (maxY <= minY) maxY = minY + 0.1;
      isPositive = true;
      percentageChange = 0.0;
      startValue = currentPortfolioValue;
      endValue = currentPortfolioValue;
    }

    final chartColor = isPositive ? Colors.green : Colors.red;

    // Get period label for display
    String periodLabel = _getPeriodLabel();

    return Card(
      elevation: 6.0, // Increased elevation for more depth
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0), // Consistent rounded corners
        side: BorderSide(
          color: Colors.grey.withOpacity(0.1), // Subtle border
          width: 0.5,
        ),
      ),
      // Apply very subtle gradient background to the card
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.0),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).cardTheme.color ?? Colors.black,
              Theme.of(context).cardTheme.color?.withOpacity(0.95) ??
                  Colors.black.withOpacity(0.95),
            ],
          ),
        ),
        padding: const EdgeInsets.all(AppSpacing.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Portfolio Performance',
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                      color: chartColor,
                      size: 16.0,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    if (spots.isNotEmpty || !_isChartLoading)
                      StreamBuilder<List<Song>>(
                        stream:
                            Provider.of<UserDataProvider>(
                              context,
                              listen: false,
                            ).songUpdatesStream,
                        initialData: const [],
                        builder: (context, snapshot) {
                          // Default to the existing values
                          double updatedPercentageChange = percentageChange;
                          bool updatedIsPositive = isPositive;
                          Color updatedChartColor = chartColor;

                          // Recalculate with latest prices if available
                          if (snapshot.hasData &&
                              snapshot.data!.isNotEmpty &&
                              spots.isNotEmpty) {
                            // Get updated portfolio value based on latest song prices
                            final updatedEndValue = userDataProvider
                                .calculatePortfolioValue(
                                  snapshot.data!,
                                  userDataProvider.portfolio,
                                );

                            // Use the same start value from the chart data
                            final startValue = spots.first.y;

                            // Recalculate percentage change
                            updatedIsPositive = updatedEndValue >= startValue;
                            if (startValue.abs() > 0.001) {
                              updatedPercentageChange =
                                  ((updatedEndValue / startValue) - 1) * 100;
                            } else if (updatedEndValue > startValue) {
                              updatedPercentageChange = double.infinity;
                            } else {
                              updatedPercentageChange = 0.0;
                            }

                            updatedChartColor =
                                updatedIsPositive ? Colors.green : Colors.red;
                          }

                          return AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: Text(
                              '${updatedIsPositive ? "+" : ""}${updatedPercentageChange.isFinite ? updatedPercentageChange.toStringAsFixed(2) + "%" : "0.00%"}',
                              key: ValueKey<String>(
                                updatedPercentageChange.toStringAsFixed(2),
                              ),
                              style: TextStyle(
                                color: updatedChartColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        },
                      )
                    else
                      const SizedBox(),
                  ],
                ),
              ],
            ),
            // Show selected time period
            Text(
              periodLabel,
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
            const SizedBox(height: AppSpacing.l),
            Container(
              height: 220.0, // Slightly taller chart
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.black.withOpacity(
                  0.2,
                ), // Subtle background for chart area
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 2,
                    spreadRadius: 0.1,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              margin: const EdgeInsets.symmetric(vertical: AppSpacing.s),
              padding: const EdgeInsets.all(AppSpacing.s),
              child:
                  _isChartLoading
                      ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Theme.of(context).colorScheme.primary,
                              ),
                              strokeWidth: 2.5,
                            ),
                            const SizedBox(height: AppSpacing.m),
                            Text(
                              'Loading chart data...',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      )
                      : spots.isEmpty
                      ? Center(
                        child: Text(
                          'No data available for this period.',
                          style: TextStyle(color: Colors.grey[400]),
                        ),
                      )
                      : LineChart(
                        LineChartData(
                          backgroundColor:
                              Colors.transparent, // Transparent background
                          clipData:
                              FlClipData.all(), // Clip data to avoid overflow
                          // Removed extraLinesData as it might cause compatibility issues
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine:
                                true, // Show vertical grid lines for a stock chart look
                            verticalInterval:
                                0.25, // Show 4 vertical grid lines (at 0.0, 0.25, 0.5, 0.75, 1.0)
                            horizontalInterval:
                                (maxY > minY)
                                    ? max(0.1, (maxY - minY) / 4)
                                    : 1.0,
                            getDrawingHorizontalLine:
                                (value) => FlLine(
                                  color:
                                      Colors.grey[850]?.withOpacity(0.15) ??
                                      Colors.grey.withOpacity(0.15),
                                  strokeWidth: 0.5,
                                  dashArray: [5, 5],
                                ),
                            getDrawingVerticalLine:
                                (value) => FlLine(
                                  color:
                                      Colors.grey[850]?.withOpacity(0.1) ??
                                      Colors.grey.withOpacity(0.1),
                                  strokeWidth: 0.5,
                                  dashArray: [5, 5],
                                ),
                            checkToShowHorizontalLine: (value) => true,
                            checkToShowVerticalLine:
                                (value) =>
                                    value % 0.25 ==
                                    0, // Only at 0.0, 0.25, 0.5, 0.75, 1.0
                          ),
                          titlesData: FlTitlesData(
                            show: true,
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 30,
                                interval:
                                    0.2, // Fixed interval for normalized x values (0.0-1.0)
                                getTitlesWidget: (value, meta) {
                                  if (spots.isEmpty || chartData.isEmpty)
                                    return const SizedBox();

                                  // Skip most labels for cleaner look
                                  if (value != 0.0 &&
                                      value != 0.5 &&
                                      value != 1.0) {
                                    return const SizedBox();
                                  }

                                  // Get labels based on time filter
                                  String label = _getAxisLabel(
                                    value,
                                    chartData,
                                  );

                                  if (label.isEmpty) return const SizedBox();
                                  return SideTitleWidget(
                                    meta: meta,
                                    space: AppSpacing.s,
                                    child: Text(
                                      label,
                                      style: TextStyle(
                                        color: Colors.grey[400],
                                        fontSize: 10,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                interval:
                                    (maxY > minY)
                                        ? max(0.1, (maxY - minY) / 4)
                                        : 1.0,
                                reservedSize: 45,
                                getTitlesWidget: (value, meta) {
                                  if (value < meta.min || value > meta.max)
                                    return const SizedBox();

                                  // Format currency values
                                  String formattedValue;
                                  double range = meta.max - meta.min;
                                  if (range <= 0) range = 1.0;

                                  // Format with appropriate scale and precision
                                  int decimalPlaces =
                                      (range < 1) ? 2 : ((range < 10) ? 1 : 0);
                                  if (value.abs() >= 1000000) {
                                    formattedValue =
                                        '\$${(value / 1000000).toStringAsFixed(1)}M';
                                  } else if (value.abs() >= 1000) {
                                    formattedValue =
                                        '\$${(value / 1000).toStringAsFixed(value.abs() >= 10000 ? 0 : 1)}k';
                                  } else {
                                    formattedValue =
                                        '\$${value.toStringAsFixed(decimalPlaces)}';
                                  }

                                  return SideTitleWidget(
                                    meta: meta,
                                    space: AppSpacing.s,
                                    child: Text(
                                      formattedValue,
                                      style: TextStyle(
                                        color: Colors.grey[400],
                                        fontSize: 10,
                                      ),
                                      textAlign: TextAlign.right,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          minX: 0, // Always 0.0 for normalized values
                          maxX: 1, // Always 1.0 for normalized values
                          minY: minY,
                          maxY: maxY,
                          lineBarsData: [
                            LineChartBarData(
                              spots: spots,
                              isCurved: true,
                              curveSmoothness:
                                  0.5, // Increased smoothness for more professional look
                              color: chartColor,
                              barWidth:
                                  1.8, // Slightly thinner line for clean appearance
                              isStrokeCapRound: true,
                              preventCurveOverShooting:
                                  true, // Prevents extreme curves
                              preventCurveOvershootingThreshold:
                                  10.0, // Controls curve extremes
                              dotData: const FlDotData(show: false),
                              // Removed shadowColor as it's not available in this version
                              belowBarData: BarAreaData(
                                show: true,
                                // Removed spotsLine as it might not be available in this version
                                gradient: LinearGradient(
                                  colors: [
                                    chartColor.withOpacity(
                                      0.25,
                                    ), // Lighter gradient start
                                    chartColor.withOpacity(
                                      0.0,
                                    ), // Transparent end
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                              ),
                            ),
                          ],
                          lineTouchData: LineTouchData(
                            enabled: true,
                            touchTooltipData: LineTouchTooltipData(
                              tooltipRoundedRadius: 8,
                              fitInsideHorizontally: true,
                              getTooltipItems:
                                  (touchedSpots) =>
                                      touchedSpots.map((spot) {
                                        // Format date/time for tooltip
                                        String formattedTime =
                                            _getTooltipDateTime(
                                              spot,
                                              chartData,
                                            );

                                        return LineTooltipItem(
                                          '\$${spot.y.toStringAsFixed(2)}${formattedTime.isNotEmpty ? '\n$formattedTime' : ''}',
                                          const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                          textAlign: TextAlign.center,
                                        );
                                      }).toList(),
                            ),
                            getTouchedSpotIndicator:
                                (barData, spotIndexes) =>
                                    spotIndexes
                                        .map(
                                          (index) => TouchedSpotIndicatorData(
                                            FlLine(
                                              color: Colors.grey.withOpacity(
                                                0.3,
                                              ),
                                              strokeWidth: 1,
                                              dashArray: [
                                                3,
                                                3,
                                              ], // Dashed vertical line
                                            ),
                                            FlDotData(
                                              show: true,
                                              getDotPainter:
                                                  (
                                                    spot,
                                                    percent,
                                                    bar,
                                                    index,
                                                  ) => FlDotCirclePainter(
                                                    radius:
                                                        5, // Slightly larger dot
                                                    color:
                                                        Colors
                                                            .white, // White center
                                                    strokeWidth:
                                                        2, // Thicker border
                                                    strokeColor:
                                                        chartColor, // Colored border
                                                  ),
                                            ),
                                          ),
                                        )
                                        .toList(),
                            // Removed touchCallback as it might not be supported in this version
                          ),
                        ),
                      ),
            ),
            const SizedBox(height: AppSpacing.l),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildTimeFilterChip('1D', _selectedTimeFilter == '1D'),
                  _buildTimeFilterChip('1W', _selectedTimeFilter == '1W'),
                  _buildTimeFilterChip('1M', _selectedTimeFilter == '1M'),
                  _buildTimeFilterChip('3M', _selectedTimeFilter == '3M'),
                  _buildTimeFilterChip('1Y', _selectedTimeFilter == '1Y'),
                  _buildTimeFilterChip('All', _selectedTimeFilter == 'All'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Get human-readable period label
  String _getPeriodLabel() {
    switch (_selectedTimeFilter) {
      case '1D':
        return 'Today';
      case '1W':
        return 'Past Week';
      case '1M':
        return 'Past Month';
      case '3M':
        return 'Past 3 Months';
      case '1Y':
        return 'Past Year';
      case 'All':
        return 'All Time';
      default:
        return '';
    }
  }

  // Get axis labels based on time filter
  String _getAxisLabel(double normalizedValue, List<PortfolioSnapshot> data) {
    if (data.isEmpty) return '';

    // Convert normalized value (0.0-1.0) back to an actual timestamp
    final firstTimestamp = data.first.timestamp;
    final lastTimestamp = data.last.timestamp;
    final duration = lastTimestamp.difference(firstTimestamp);
    final offset = Duration(
      milliseconds: (duration.inMilliseconds * normalizedValue).round(),
    );
    final timestamp = firstTimestamp.add(offset);

    // Format based on time filter
    switch (_selectedTimeFilter) {
      case '1D':
        // For 1 day, show hour
        if (normalizedValue == 0.0) return '${timestamp.hour}:00';
        if (normalizedValue == 0.5)
          return '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
        if (normalizedValue == 1.0) return 'Now';
        return '';

      case '1W':
        // For 1 week, show weekday
        if (normalizedValue == 0.0) return _getWeekdayName(timestamp.weekday);
        if (normalizedValue == 0.5) return _getWeekdayName(timestamp.weekday);
        if (normalizedValue == 1.0) return 'Today';
        return '';

      case '1M':
        // For 1 month, show day of month
        if (normalizedValue == 0.0)
          return '${timestamp.month}/${timestamp.day}';
        if (normalizedValue == 0.5)
          return '${timestamp.month}/${timestamp.day}';
        if (normalizedValue == 1.0) return 'Now';
        return '';

      case '3M':
        // For 3 months, show month abbreviation
        if (normalizedValue == 0.0) return _getMonthAbbr(timestamp.month);
        if (normalizedValue == 0.5) return _getMonthAbbr(timestamp.month);
        if (normalizedValue == 1.0) return 'Now';
        return '';

      case '1Y':
      case 'All':
        // For year or all time, show month/year
        if (normalizedValue == 0.0)
          return '${_getMonthAbbr(timestamp.month)}/${timestamp.year.toString().substring(2)}';
        if (normalizedValue == 0.5)
          return '${_getMonthAbbr(timestamp.month)}/${timestamp.year.toString().substring(2)}';
        if (normalizedValue == 1.0) return 'Now';
        return '';

      default:
        return '';
    }
  }

  // Get tooltip formatting for datetime
  String _getTooltipDateTime(FlSpot spot, List<PortfolioSnapshot> data) {
    if (data.isEmpty) return '';

    // Find closest timestamp to the spot's x value
    final firstTimestamp = data.first.timestamp;
    final lastTimestamp = data.last.timestamp;
    final duration = lastTimestamp.difference(firstTimestamp);

    // Convert normalized x to actual time
    final offset = Duration(
      milliseconds: (duration.inMilliseconds * spot.x).round(),
    );
    final timestamp = firstTimestamp.add(offset);

    // Format based on time filter
    switch (_selectedTimeFilter) {
      case '1D':
        return '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
      case '1W':
        return '${_getWeekdayName(timestamp.weekday)} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
      case '1M':
      case '3M':
        return '${_getMonthAbbr(timestamp.month)} ${timestamp.day}';
      case '1Y':
      case 'All':
        return '${_getMonthAbbr(timestamp.month)} ${timestamp.day}, ${timestamp.year}';
      default:
        return '';
    }
  }

  // Helper to get weekday name
  String _getWeekdayName(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }

  // Helper to get month abbreviation
  String _getMonthAbbr(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }

  Widget _buildTimeFilterChip(String label, bool isSelected) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (!isSelected) {
              // Add haptic feedback on tap
              HapticFeedback.lightImpact();

              // Update state and reload chart data
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() {
                    _selectedTimeFilter = label;
                    _isChartLoading = true;
                    _chartData = [];
                  });
                  _updateChartData(label);
                }
              });
            }
          },
          borderRadius: BorderRadius.circular(20.0),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutQuart,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.l,
              vertical: AppSpacing.s,
            ),
            decoration: BoxDecoration(
              color:
                  isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(20.0),
              border: Border.all(
                color:
                    isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey[700] ?? Colors.grey,
                width: 1.0,
              ),
              boxShadow:
                  isSelected
                      ? [
                        BoxShadow(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.3),
                          spreadRadius: 1,
                          blurRadius: 3,
                          offset: const Offset(0, 1),
                        ),
                      ]
                      : null,
            ),
            child: Text(
              label,
              style: TextStyle(
                color:
                    isSelected
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).textTheme.bodyLarge?.color,
                fontSize: 13.0,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Show portfolio item details in a bottom sheet with buy/sell options
  void _showPortfolioItemDetails(
    BuildContext context,
    PortfolioItem item,
    Song song,
  ) {
    final userDataProvider = Provider.of<UserDataProvider>(
      context,
      listen: false,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Important for keyboard avoidance
      backgroundColor: Colors.transparent,
      builder: (context) {
        // Use the dedicated StatefulWidget for the sheet content
        return _PortfolioItemDetailsSheetContent(
          item: item,
          song: song,
          userDataProvider: userDataProvider,
        );
      },
      // Removed whenComplete disposal as it's handled by _PortfolioItemDetailsSheetContent's State
    );
  }

  // Show full album art in a dialog
  void _showFullAlbumArt(
    BuildContext context,
    String albumArtUrl,
    String songName,
    String artistName,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(AppSpacing.l),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  // Album Art
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.9,
                      maxHeight: MediaQuery.of(context).size.height * 0.6,
                    ),
                    child: Image.network(
                      albumArtUrl,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          width: MediaQuery.of(context).size.width * 0.9,
                          height: MediaQuery.of(context).size.width * 0.9,
                          color: Colors.grey[900],
                          child: Center(
                            child: CircularProgressIndicator(
                              // **FIXED: Added null check and > 0 check for expectedTotalBytes**
                              value:
                                  loadingProgress.expectedTotalBytes != null &&
                                          loadingProgress.expectedTotalBytes! >
                                              0
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                            ),
                          ),
                        );
                      },
                      errorBuilder:
                          (context, error, stackTrace) => Container(
                            width: MediaQuery.of(context).size.width * 0.9,
                            height: MediaQuery.of(context).size.width * 0.9,
                            color: Colors.grey[900],
                            child: const Center(
                              child: Icon(
                                Icons.error_outline,
                                size: 50,
                                color: Colors.white,
                              ),
                            ),
                          ),
                    ),
                  ),
                ),
                Container(
                  // Song Info
                  padding: const EdgeInsets.all(AppSpacing.l),
                  margin: const EdgeInsets.only(top: AppSpacing.l),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(180),
                    borderRadius: BorderRadius.circular(12),
                  ), // Adjusted alpha
                  child: Column(
                    children: [
                      Text(
                        songName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        artistName,
                        style: TextStyle(fontSize: 16, color: Colors.grey[300]),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                Padding(
                  // Close Button
                  padding: const EdgeInsets.only(top: AppSpacing.l),
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[800],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: const Text('CLOSE'),
                  ),
                ),
              ],
            ),
          ),
    );
  }
}
