import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../shared/models/portfolio_item.dart'; // Corrected path
import '../shared/models/song.dart'; // Corrected path
import '../shared/providers/user_data_provider.dart'; // Corrected path
import '../features/portfolio/services/portfolio_service.dart'; // Corrected path

class RealTimePortfolioWidget extends StatefulWidget {
  final Function(PortfolioItem, Song)? onItemTap;

  const RealTimePortfolioWidget({
    super.key, // Use super parameter
    this.onItemTap,
  });

  @override
  State<RealTimePortfolioWidget> createState() =>
      _RealTimePortfolioWidgetState();
}

class _RealTimePortfolioWidgetState extends State<RealTimePortfolioWidget> {
  // Timer for updating the timestamp
  Timer? _timestampTimer;
  String _lastUpdated = '';

  @override
  void initState() {
    super.initState();
    _updateTimestamp();

    // Update timestamp every second
    _timestampTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateTimestamp();
    });
  }

  @override
  void dispose() {
    _timestampTimer?.cancel();
    super.dispose();
  }

  void _updateTimestamp() {
    if (mounted) {
      setState(() {
        final now = DateTime.now();
        _lastUpdated =
            '${now.hour}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserDataProvider>(
      builder: (context, provider, child) {
        final portfolio = provider.portfolio;

        if (portfolio.isEmpty) {
          return const SizedBox.shrink();
        }

        return Card(
          elevation: 4,
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Use Flexible to allow text to wrap or shrink
                    const Flexible(
                      child: Text(
                        'Real-Time Portfolio Updates',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Add some spacing
                    const SizedBox(width: 8),
                    // Use a more compact timestamp display
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.access_time, size: 12),
                        const SizedBox(width: 2),
                        Text(
                          _lastUpdated,
                          style: const TextStyle(fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...portfolio.map(
                  (item) => _buildPortfolioItemTile(context, item, provider),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPortfolioItemTile(
    BuildContext context,
    PortfolioItem item,
    UserDataProvider provider,
  ) {
    // Get the song to access current price and other details
    final song = provider.allSongs.firstWhere(
      (s) => s.id == item.songId,
      orElse:
          () => Song(
            id: item.songId,
            name: item.songName,
            artist: item.artistName,
            genre: 'Unknown',
            currentPrice: item.purchasePrice,
          ),
    );

    // Calculate values
    final currentValue = item.quantity * song.currentPrice;

    // Get price change indicator
    // Assuming PriceChange enum is now accessible via PortfolioService import
    final priceChange = provider.getPriceChangeIndicator(item.songId);

    // Determine indicator color
    Color indicatorColor = Colors.transparent;
    IconData indicatorIcon = Icons.remove;

    // Use the PriceChange enum from the imported PortfolioService
    if (priceChange == PriceChange.increase) {
      indicatorColor = Colors.green;
      indicatorIcon = Icons.arrow_upward;
    } else if (priceChange == PriceChange.decrease) {
      indicatorColor = Colors.red;
      indicatorIcon = Icons.arrow_downward;
    }

    return InkWell(
      onTap:
          widget.onItemTap != null ? () => widget.onItemTap!(item, song) : null,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            // Price change indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: indicatorColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            // Song info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.songName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    // Note: Corrected potential missing comma here from original read
                    item.artistName,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  // Removed Stream Count Row
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Price and quantity - with constraints to prevent overflow
            Container(
              constraints: const BoxConstraints(maxWidth: 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Use the PriceChange enum from the imported PortfolioService
                      if (priceChange != PriceChange.none)
                        Icon(indicatorIcon, color: indicatorColor, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '\$${song.currentPrice.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          // Use the PriceChange enum from the imported PortfolioService
                          color:
                              priceChange == PriceChange.none
                                  ? Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.color // Use theme color for 'none'
                                  : indicatorColor,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${item.quantity} ${item.quantity == 1 ? 'share' : 'shares'}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '\$${currentValue.toStringAsFixed(2)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
