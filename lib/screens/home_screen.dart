import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/user_data_provider.dart';
import '../models/portfolio_item.dart';
import '../models/song.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Refresh data (for demo purposes)
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Refreshed market data')),
              );
            },
          ),
        ],
      ),
      body: Consumer<UserDataProvider>(
        builder: (context, userDataProvider, child) {
          final portfolio = userDataProvider.portfolio;
          final portfolioValue = userDataProvider.totalPortfolioValue;
          
          return RefreshIndicator(
            onRefresh: () async {
              // Pull to refresh functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Refreshed market data')),
              );
            },
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                _buildPortfolioSummary(context, userDataProvider),
                const SizedBox(height: 24.0),
                _buildPortfolioChart(context),
                const SizedBox(height: 24.0),
                _buildPortfolioList(context, portfolio, userDataProvider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPortfolioSummary(BuildContext context, UserDataProvider userDataProvider) {
    final portfolioValue = userDataProvider.totalPortfolioValue;
    final cashBalance = userDataProvider.userProfile?.cashBalance ?? 0.0;
    final totalBalance = userDataProvider.totalBalance;
    
    // Calculate a mock daily change (would be calculated from real data)
    final dailyChange = portfolioValue * 0.02; // 2% daily change for demo
    final isPositive = dailyChange >= 0;
    
    return Card(
      elevation: 4.0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Portfolio Summary',
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Portfolio Value',
                      style: TextStyle(
                        color: Colors.grey[400],
                      ),
                    ),
                    Text(
                      '\$${portfolioValue.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 24.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4.0),
                    Row(
                      children: [
                        Icon(
                          isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                          color: isPositive ? Colors.green : Colors.red,
                          size: 16.0,
                        ),
                        const SizedBox(width: 4.0),
                        Text(
                          '${isPositive ? "+" : ""}${dailyChange.toStringAsFixed(2)} (${(dailyChange / (portfolioValue - dailyChange) * 100).toStringAsFixed(2)}%)',
                          style: TextStyle(
                            color: isPositive ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cash Balance',
                      style: TextStyle(
                        color: Colors.grey[400],
                      ),
                    ),
                    Text(
                      '\$${cashBalance.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 20.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            const Divider(),
            const SizedBox(height: 8.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Balance',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '\$${totalBalance.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPortfolioChart(BuildContext context) {
    // Mock data for the chart
    final spots = [
      const FlSpot(0, 100),
      const FlSpot(1, 105),
      const FlSpot(2, 102),
      const FlSpot(3, 110),
      const FlSpot(4, 108),
      const FlSpot(5, 115),
      const FlSpot(6, 120),
    ];
    
    return Card(
      elevation: 4.0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Portfolio Performance',
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8.0),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _buildTimeFilterChip('1D', true),
                  _buildTimeFilterChip('1W', false),
                  _buildTimeFilterChip('1M', false),
                  _buildTimeFilterChip('3M', false),
                  _buildTimeFilterChip('1Y', false),
                  _buildTimeFilterChip('All', false),
                ],
              ),
            ),
            const SizedBox(height: 16.0),
            SizedBox(
              height: 200.0,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: false),
                  titlesData: FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: Theme.of(context).colorScheme.primary,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                      ),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (_) => Colors.grey[800]!,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeFilterChip(String label, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          // Would update chart data based on time filter
        },
        labelStyle: TextStyle(
          color: isSelected ? Colors.black : Colors.white,
          fontSize: 12.0,
        ),
        backgroundColor: Colors.grey[800],
        selectedColor: Colors.green,
      ),
    );
  }

  Widget _buildPortfolioList(BuildContext context, List<PortfolioItem> portfolio, UserDataProvider userDataProvider) {
    if (portfolio.isEmpty) {
      return Card(
        elevation: 4.0,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your Portfolio',
                style: TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16.0),
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.music_note,
                      size: 48.0,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(height: 16.0),
                    const Text(
                      'Your portfolio is empty',
                      style: TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    const Text(
                      'Start investing in songs to build your portfolio',
                      style: TextStyle(
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16.0),
                    ElevatedButton(
                      onPressed: () {
                        // Navigate to Discover tab
                        DefaultTabController.of(context)?.animateTo(1);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                      ),
                      child: const Text('Discover Songs'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    return Card(
      elevation: 4.0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Your Portfolio',
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${portfolio.length} ${portfolio.length == 1 ? 'Song' : 'Songs'}',
                  style: TextStyle(
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: portfolio.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final item = portfolio[index];
                final song = userDataProvider.allSongs.firstWhere(
                  (s) => s.id == item.songId,
                  orElse: () => Song(
                    id: item.songId,
                    name: item.songName,
                    artist: item.artistName,
                    genre: 'Unknown',
                    currentPrice: item.purchasePrice,
                  ),
                );
                
                final currentValue = song.currentPrice * item.quantity;
                final purchaseValue = item.purchasePrice * item.quantity;
                final profitLoss = currentValue - purchaseValue;
                final profitLossPercent = (profitLoss / purchaseValue) * 100;
                final isProfit = profitLoss >= 0;
                
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: Colors.grey[800],
                    backgroundImage: item.albumArtUrl != null ? NetworkImage(item.albumArtUrl!) : null,
                    child: item.albumArtUrl == null ? const Icon(Icons.music_note) : null,
                  ),
                  title: Text(
                    item.songName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    '${item.artistName} • ${item.quantity} ${item.quantity == 1 ? 'share' : 'shares'}',
                  ),
                  trailing: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '\$${currentValue.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${isProfit ? '+' : ''}${profitLoss.toStringAsFixed(2)} (${isProfit ? '+' : ''}${profitLossPercent.toStringAsFixed(2)}%)',
                        style: TextStyle(
                          color: isProfit ? Colors.green : Colors.red,
                          fontSize: 12.0,
                        ),
                      ),
                    ],
                  ),
                  onTap: () {
                    // TODO: Navigate to song detail page
                    _showSongActions(context, song, userDataProvider);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
  
  void _showSongActions(BuildContext context, Song song, UserDataProvider userDataProvider) {
    final ownedQuantity = userDataProvider.getQuantityOwned(song.id);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.grey[800],
                    backgroundImage: song.albumArtUrl != null ? NetworkImage(song.albumArtUrl!) : null,
                    child: song.albumArtUrl == null ? const Icon(Icons.music_note) : null,
                    radius: 30.0,
                  ),
                  const SizedBox(width: 16.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          song.name,
                          style: const TextStyle(
                            fontSize: 18.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          song.artist,
                          style: TextStyle(
                            color: Colors.grey[400],
                          ),
                        ),
                        const SizedBox(height: 4.0),
                        Text(
                          'Current Price: \$${song.currentPrice.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24.0),
              Text(
                'You own: $ownedQuantity ${ownedQuantity == 1 ? 'share' : 'shares'}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16.0),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _showBuySongDialog(context, song, userDataProvider);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      child: const Text('Buy More'),
                    ),
                  ),
                  const SizedBox(width: 16.0),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: ownedQuantity > 0 ? () {
                        Navigator.pop(context);
                        _showSellSongDialog(context, song, userDataProvider, ownedQuantity);
                      } : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      child: const Text('Sell'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
  
  void _showBuySongDialog(BuildContext context, Song song, UserDataProvider userDataProvider) {
    int quantity = 1;
    final cashBalance = userDataProvider.userProfile?.cashBalance ?? 0.0;
    final maxAffordable = (cashBalance / song.currentPrice).floor();
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final totalCost = song.currentPrice * quantity;
            final canAfford = totalCost <= cashBalance;
            
            return AlertDialog(
              backgroundColor: Colors.grey[900],
              title: const Text('Buy Song Shares'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Song: ${song.name} by ${song.artist}'),
                  const SizedBox(height: 8.0),
                  Text('Price per share: \$${song.currentPrice.toStringAsFixed(2)}'),
                  const SizedBox(height: 16.0),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: quantity > 1 ? () {
                          setState(() {
                            quantity--;
                          });
                        } : null,
                      ),
                      Expanded(
                        child: Text(
                          '$quantity ${quantity == 1 ? 'share' : 'shares'}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 18.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: quantity < maxAffordable ? () {
                          setState(() {
                            quantity++;
                          });
                        } : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16.0),
                  Text(
                    'Total Cost: \$${totalCost.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (!canAfford)
                    const Text(
                      'Insufficient funds',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: canAfford ? () async {
                    final success = await userDataProvider.buySong(song.id, quantity);
                    Navigator.pop(context);
                    
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Successfully bought $quantity ${quantity == 1 ? 'share' : 'shares'} of ${song.name}'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Failed to buy shares'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  } : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  child: const Text('Buy'),
                ),
              ],
            );
          },
        );
      },
    );
  }
  
  void _showSellSongDialog(BuildContext context, Song song, UserDataProvider userDataProvider, int maxQuantity) {
    int quantity = 1;
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final totalValue = song.currentPrice * quantity;
            
            return AlertDialog(
              backgroundColor: Colors.grey[900],
              title: const Text('Sell Song Shares'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Song: ${song.name} by ${song.artist}'),
                  const SizedBox(height: 8.0),
                  Text('Current price per share: \$${song.currentPrice.toStringAsFixed(2)}'),
                  const SizedBox(height: 16.0),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: quantity > 1 ? () {
                          setState(() {
                            quantity--;
                          });
                        } : null,
                      ),
                      Expanded(
                        child: Text(
                          '$quantity ${quantity == 1 ? 'share' : 'shares'}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 18.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: quantity < maxQuantity ? () {
                          setState(() {
                            quantity++;
                          });
                        } : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16.0),
                  Text(
                    'Total Value: \$${totalValue.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final success = await userDataProvider.sellSong(song.id, quantity);
                    Navigator.pop(context);
                    
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Successfully sold $quantity ${quantity == 1 ? 'share' : 'shares'} of ${song.name}'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Failed to sell shares'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
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
