import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math';
import '../providers/user_data_provider.dart';
import '../models/portfolio_item.dart';
import '../models/song.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedTimeFilter = '1W'; // Default to 1 week

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
    return Consumer<UserDataProvider>(
      builder: (context, userDataProvider, child) {
        // Generate chart data based on portfolio value
        final portfolioValue = userDataProvider.totalPortfolioValue;
        final cashBalance = userDataProvider.userProfile?.cashBalance ?? 0.0;
        final totalBalance = userDataProvider.totalBalance;
        
        // Create a more realistic chart with some variation
        // This simulates historical data for the portfolio
        final baseValue = totalBalance * 0.8; // Starting at 80% of current value
        final variance = totalBalance * 0.05; // 5% variance for fluctuations
        
        // Generate chart data based on selected time filter
        final spots = _generateChartData(
          _selectedTimeFilter, 
          baseValue, 
          totalBalance, 
          variance
        );
        
        // Calculate min and max values for the chart
        double minY = spots.map((spot) => spot.y).reduce(min);
        double maxY = spots.map((spot) => spot.y).reduce(max);
        
        // Add some padding to min and max
        minY = minY * 0.95;
        maxY = maxY * 1.05;
        
        // Determine if the trend is positive
        final isPositive = spots.last.y >= spots.first.y;
        final chartColor = isPositive ? Colors.green : Colors.red;
        
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
                      'Portfolio Performance',
                      style: TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        Icon(
                          isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                          color: chartColor,
                          size: 16.0,
                        ),
                        const SizedBox(width: 4.0),
                        Text(
                          '${isPositive ? "+" : ""}${((spots.last.y / spots.first.y - 1) * 100).toStringAsFixed(2)}%',
                          style: TextStyle(
                            color: chartColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8.0),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
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
                const SizedBox(height: 16.0),
                SizedBox(
                  height: 200.0,
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: max(1.0, (maxY - minY) / 4), // Ensure interval is not zero
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: Colors.grey[800]!,
                            strokeWidth: 0.5,
                            dashArray: [5, 5],
                          );
                        },
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            interval: 1,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              String label = '';
                              
                              // Get appropriate labels based on time filter
                              switch (_selectedTimeFilter) {
                                case '1D':
                                  // Hours
                                  if (index % 4 == 0 && index < 24) {
                                    final hour = index;
                                    label = '${hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour)}${hour >= 12 ? 'pm' : 'am'}';
                                  }
                                  break;
                                case '1W':
                                  // Days of week
                                  const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                                  if (index >= 0 && index < days.length) {
                                    label = days[index];
                                  }
                                  break;
                                case '1M':
                                  // Days of month
                                  if (index % 5 == 0) {
                                    label = '${index + 1}';
                                  }
                                  break;
                                case '3M':
                                  // Weeks
                                  if (index < 12) {
                                    label = 'W${index + 1}';
                                  }
                                  break;
                                case '1Y':
                                  // Months
                                  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
                                  if (index < months.length) {
                                    label = months[index];
                                  }
                                  break;
                                case 'All':
                                  // Quarters over years
                                  if (index % 4 == 0 && index < 24) {
                                    final year = 2023 + (index ~/ 4);
                                    final quarter = (index % 4) + 1;
                                    label = 'Q$quarter\n$year';
                                  }
                                  break;
                              }
                              
                              if (label.isEmpty) {
                                return const SizedBox();
                              }
                              
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  label,
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 12,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: (maxY - minY) / 4,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: Text(
                                  '\$${value.toInt()}',
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 12,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      minX: 0,
                      maxX: spots.length - 1,
                      minY: minY,
                      maxY: maxY,
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          color: chartColor,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) {
                              return FlDotCirclePainter(
                                radius: 3,
                                color: chartColor,
                                strokeWidth: 1,
                                strokeColor: Colors.white,
                              );
                            },
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            color: chartColor.withOpacity(0.2),
                            gradient: LinearGradient(
                              colors: [
                                chartColor.withOpacity(0.4),
                                chartColor.withOpacity(0.1),
                                chartColor.withOpacity(0.0),
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
                          getTooltipItems: (touchedSpots) {
                            return touchedSpots.map((touchedSpot) {
                              return LineTooltipItem(
                                '\$${touchedSpot.y.toStringAsFixed(2)}',
                                const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            }).toList();
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTimeFilterChip(String label, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) {
            setState(() {
              _selectedTimeFilter = label;
            });
            
            // Show a snackbar to indicate the time filter has changed
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Showing data for $label'),
                duration: const Duration(seconds: 1),
              ),
            );
          }
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
  
  // Generate chart data based on the selected time filter
  List<FlSpot> _generateChartData(
    String timeFilter, 
    double baseValue, 
    double currentValue, 
    double variance
  ) {
    final random = Random();
    final spots = <FlSpot>[];
    
    // Number of data points based on time filter
    int numPoints;
    switch (timeFilter) {
      case '1D':
        numPoints = 24; // Hourly data for 1 day
        break;
      case '1W':
        numPoints = 7; // Daily data for 1 week
        break;
      case '1M':
        numPoints = 30; // Daily data for 1 month
        break;
      case '3M':
        numPoints = 12; // Weekly data for 3 months
        break;
      case '1Y':
        numPoints = 12; // Monthly data for 1 year
        break;
      case 'All':
        numPoints = 24; // Monthly data for 2 years
        break;
      default:
        numPoints = 7; // Default to 1 week
    }
    
    // Generate different patterns based on time filter
    for (int i = 0; i < numPoints; i++) {
      double value;
      
      switch (timeFilter) {
        case '1D':
          // More volatile intraday pattern
          value = baseValue + (currentValue - baseValue) * (i / (numPoints - 1));
          value += (random.nextDouble() * 2 - 1) * variance * 0.5;
          break;
        case '1W':
          // Gradual increase with some fluctuation
          value = baseValue + (currentValue - baseValue) * (i / (numPoints - 1));
          value += (random.nextDouble() * 2 - 1) * variance;
          break;
        case '1M':
          // More pronounced ups and downs
          final progress = i / (numPoints - 1);
          value = baseValue + (currentValue - baseValue) * progress;
          // Add a sine wave pattern
          value += sin(progress * 3 * pi) * variance * 2;
          // Add some randomness
          value += (random.nextDouble() * 2 - 1) * variance * 0.5;
          break;
        case '3M':
          // Longer-term trend with market cycles
          final progress = i / (numPoints - 1);
          value = baseValue + (currentValue - baseValue) * progress;
          // Add a wave pattern
          value += sin(progress * 2 * pi) * variance * 3;
          // Add some randomness
          value += (random.nextDouble() * 2 - 1) * variance;
          break;
        case '1Y':
          // Annual pattern with seasonal effects
          final progress = i / (numPoints - 1);
          value = baseValue + (currentValue - baseValue) * progress;
          // Add a seasonal pattern
          value += sin(progress * pi) * variance * 4;
          // Add some randomness
          value += (random.nextDouble() * 2 - 1) * variance * 1.5;
          break;
        case 'All':
          // Long-term growth with market cycles
          final progress = i / (numPoints - 1);
          value = baseValue * pow(1.15, progress); // Compound growth
          // Add market cycles
          value += sin(progress * 3 * pi) * variance * 5;
          // Add some randomness
          value += (random.nextDouble() * 2 - 1) * variance * 2;
          break;
        default:
          // Default pattern (1W)
          value = baseValue + (currentValue - baseValue) * (i / (numPoints - 1));
          value += (random.nextDouble() * 2 - 1) * variance;
      }
      
      // Ensure the last point matches the current value
      if (i == numPoints - 1) {
        value = currentValue;
      }
      
      spots.add(FlSpot(i.toDouble(), value));
    }
    
    return spots;
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
