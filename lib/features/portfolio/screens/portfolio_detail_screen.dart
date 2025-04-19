import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/models/portfolio_item.dart'; // Corrected path
import '../../../shared/models/song.dart'; // Corrected path
import '../../../shared/providers/user_data_provider.dart'; // Corrected path
import '../services/portfolio_service.dart'; // Corrected path to new service location

class PortfolioDetailScreen extends StatefulWidget {
  const PortfolioDetailScreen({super.key}); // Use super parameter

  @override
  State<PortfolioDetailScreen> createState() => _PortfolioDetailScreenState();
}

class _PortfolioDetailScreenState extends State<PortfolioDetailScreen> {
  // Auto-refresh state
  bool _autoRefreshEnabled = true;

  // Auto-refresh timer
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    // Start auto-refresh when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startAutoRefresh(context);
    });
  }

  @override
  void dispose() {
    _stopAutoRefresh();
    super.dispose();
  }

  void _startAutoRefresh(BuildContext context) {
    // Cancel any existing timer
    _refreshTimer?.cancel();

    // Create a new timer that refreshes data every 30 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_autoRefreshEnabled && mounted) {
        // Use read here as we don't need to listen in the timer callback
        context.read<UserDataProvider>().refreshData();
      }
    });
  }

  void _stopAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('My Portfolio'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Refresh data to get latest prices
              context.read<UserDataProvider>().refreshData();
            },
          ),
        ],
      ),
      body: Consumer<UserDataProvider>(
        builder: (context, provider, child) {
          // Show loading indicator when refreshing data
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final portfolio = provider.portfolio;

          if (portfolio.isEmpty) {
            return const Center(
              child: Text(
                'Your portfolio is empty.\nStart investing in songs!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.refreshData(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildPortfolioSummary(context, provider),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Your Songs',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    // Auto-refresh toggle
                    _buildAutoRefreshToggle(context),
                  ],
                ),
                const SizedBox(height: 16),
                ...portfolio.map((item) => _buildPortfolioItemCard(context, item, provider)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAutoRefreshToggle(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Auto-refresh'),
        Switch(
          value: _autoRefreshEnabled,
          onChanged: (value) {
            setState(() {
              _autoRefreshEnabled = value;
            });

            // Start or stop auto-refresh timer
            if (_autoRefreshEnabled) {
              _startAutoRefresh(context);
            } else {
              _stopAutoRefresh();
            }
          },
        ),
      ],
    );
  }

  Widget _buildPortfolioSummary(BuildContext context, UserDataProvider provider) {
    final totalValue = provider.totalPortfolioValue;
    final cashBalance = provider.userProfile?.cashBalance ?? 0.0;

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Portfolio Summary',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // Last updated indicator
                Text(
                  'Updated: ${_getFormattedTime()}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSummaryRow('Total Portfolio Value', '\$${totalValue.toStringAsFixed(2)}'),
            const Divider(),
            _buildSummaryRow('Cash Balance', '\$${cashBalance.toStringAsFixed(2)}'),
            const Divider(),
            _buildSummaryRow(
              'Total Balance',
              '\$${(totalValue + cashBalance).toStringAsFixed(2)}',
              isBold: true,
            ),
          ],
        ),
      ),
    );
  }

  String _getFormattedTime() {
    final now = DateTime.now();
    return '${now.hour}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPortfolioItemCard(
    BuildContext context,
    PortfolioItem item,
    UserDataProvider provider
  ) {
    // Get the song to access current price and other details
    final song = provider.allSongs.firstWhere(
      (s) => s.id == item.songId,
      orElse: () => Song(
        id: item.songId,
        name: item.songName,
        artist: item.artistName,
        genre: 'Unknown',
        currentPrice: item.purchasePrice,
      ),
    );

    // Calculate values
    final currentValue = item.quantity * song.currentPrice;
    final purchaseValue = item.totalPurchaseValue;
    final profitLoss = currentValue - purchaseValue;
    // Avoid division by zero for percentage calculation
    final profitLossPercent = purchaseValue.abs() > 0.001 ? (profitLoss / purchaseValue) * 100 : 0.0;

    // Get price change indicator
    final priceChange = provider.getPriceChangeIndicator(item.songId);

    // Determine card color based on price change
    Color? cardColor;
    if (priceChange == PriceChange.increase) {
      cardColor = Colors.green[50]; // Light green for price increase
    } else if (priceChange == PriceChange.decrease) {
      cardColor = Colors.red[50]; // Light red for price decrease
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: 2,
        color: cardColor,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Album art or placeholder
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                      image: item.albumArtUrl != null
                          ? DecorationImage(
                              image: NetworkImage(item.albumArtUrl!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: item.albumArtUrl == null
                        ? const Icon(Icons.music_note, size: 40, color: Colors.grey)
                        : null,
                  ),
                  const SizedBox(width: 16),
                  // Song details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.songName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.artistName,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[700],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Genre: ${song.genre}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        // Removed Stream Count Display
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              // Financial details
              _buildDetailRow('Quantity', '${item.quantity}'),
              _buildDetailRow('Purchase Price', '\$${item.purchasePrice.toStringAsFixed(2)}'),
              _buildDetailRow(
                'Current Price',
                '\$${song.currentPrice.toStringAsFixed(2)}',
                suffix: _buildPriceChangeIndicator(priceChange),
              ),
              _buildDetailRow('Total Purchase Value', '\$${purchaseValue.toStringAsFixed(2)}'),
              _buildDetailRow('Current Value', '\$${currentValue.toStringAsFixed(2)}'),
              _buildDetailRow(
                'Profit/Loss',
                '\$${profitLoss.toStringAsFixed(2)} (${profitLossPercent.toStringAsFixed(2)}%)',
                textColor: profitLoss >= 0 ? Colors.green : Colors.red,
              ),
              const SizedBox(height: 16),
              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () {
                      _showSellDialog(context, item, song, provider);
                    },
                    child: const Text('Sell'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () {
                      _showBuyDialog(context, item, song, provider);
                    },
                    child: const Text('Buy More'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriceChangeIndicator(PriceChange priceChange) {
    if (priceChange == PriceChange.increase) {
      return const Icon(Icons.arrow_upward, color: Colors.green, size: 16);
    } else if (priceChange == PriceChange.decrease) {
      return const Icon(Icons.arrow_downward, color: Colors.red, size: 16);
    } else {
      return const SizedBox.shrink();
    }
  }

  Widget _buildDetailRow(String label, String value, {Color? textColor, Widget? suffix}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14),
          ),
          Row(
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              if (suffix != null) ...[
                const SizedBox(width: 4),
                suffix,
              ],
            ],
          ),
        ],
      ),
    );
  }

  void _showBuyDialog(
    BuildContext context,
    PortfolioItem item,
    Song song,
    UserDataProvider provider
  ) {
    int quantity = 1;
    final cashBalance = provider.userProfile?.cashBalance ?? 0.0;
    final maxAffordable = (cashBalance / song.currentPrice).floor();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final totalCost = quantity * song.currentPrice;
            final canAfford = totalCost <= cashBalance;

            return AlertDialog(
              title: Text('Buy ${item.songName}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Current Price: \$${song.currentPrice.toStringAsFixed(2)}'),
                  const SizedBox(height: 8),
                  Text('Cash Balance: \$${cashBalance.toStringAsFixed(2)}'),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text('Quantity: '),
                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: quantity > 1
                            ? () => setState(() => quantity--)
                            : null,
                      ),
                      Text('$quantity'),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: quantity < maxAffordable
                            ? () => setState(() => quantity++)
                            : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Total Cost: \$${totalCost.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (!canAfford)
                    const Text(
                      'Insufficient funds',
                      style: TextStyle(color: Colors.red),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: canAfford && quantity > 0 // Ensure quantity is positive
                      ? () async { // Make async
                          final success = await provider.buySong(item.songId, quantity);
                          Navigator.pop(context); // Pop regardless of success
                          if (mounted && success) {
                             ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Successfully bought $quantity shares'), backgroundColor: Colors.green));
                          } else if (mounted) {
                             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Buy failed'), backgroundColor: Colors.red));
                          }
                        }
                      : null,
                  child: const Text('Buy'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showSellDialog(
    BuildContext context,
    PortfolioItem item,
    Song song,
    UserDataProvider provider
  ) {
    int quantity = 1;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final totalValue = quantity * song.currentPrice;

            return AlertDialog(
              title: Text('Sell ${item.songName}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Current Price: \$${song.currentPrice.toStringAsFixed(2)}'),
                  const SizedBox(height: 8),
                  Text('You Own: ${item.quantity}'),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text('Quantity to Sell: '),
                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: quantity > 1
                            ? () => setState(() => quantity--)
                            : null,
                      ),
                      Text('$quantity'),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: quantity < item.quantity
                            ? () => setState(() => quantity++)
                            : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Total Value: \$${totalValue.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: quantity > 0 // Ensure quantity is positive
                      ? () async { // Make async
                          final success = await provider.sellSong(item.songId, quantity);
                           Navigator.pop(context); // Pop regardless of success
                          if (mounted && success) {
                             ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Successfully sold $quantity shares'), backgroundColor: Colors.blue));
                          } else if (mounted) {
                             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sell failed'), backgroundColor: Colors.red));
                          }
                        }
                      : null,
                  child: const Text('Sell'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
