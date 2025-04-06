import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/portfolio_item.dart';
import '../models/song.dart';
import '../providers/user_data_provider.dart';

class PortfolioDetailScreen extends StatelessWidget {
  const PortfolioDetailScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
                const Text(
                  'Your Songs',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
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
            const Text(
              'Portfolio Summary',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
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
    final profitLossPercent = (profitLoss / purchaseValue) * 100;
    
    // Get stream count
    final streamCount = provider.getSongStreamCount(item.songId);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
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
                      const SizedBox(height: 4),
                      Text(
                        'Streams: $streamCount',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
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
            _buildDetailRow('Current Price', '\$${song.currentPrice.toStringAsFixed(2)}'),
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
    );
  }
  
  Widget _buildDetailRow(String label, String value, {Color? textColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
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
                  onPressed: canAfford
                      ? () {
                          provider.buySong(item.songId, quantity);
                          Navigator.pop(context);
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
                  onPressed: () {
                    provider.sellSong(item.songId, quantity);
                    Navigator.pop(context);
                  },
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
