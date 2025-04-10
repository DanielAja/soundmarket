import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math';
import '../providers/user_data_provider.dart';
import '../models/portfolio_item.dart';
import '../models/song.dart';
import '../models/transaction.dart';

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
        title: const Text('Sound Market'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Trigger a manual refresh of the song service
              final userDataProvider = Provider.of<UserDataProvider>(context, listen: false);
              userDataProvider.refreshData();
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Refreshed market data')),
              );
            },
          ),
        ],
      ),
      body: Consumer<UserDataProvider>(
        builder: (context, userDataProvider, child) {
          // Show loading indicator when refreshing data
          if (userDataProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          
          final portfolio = userDataProvider.portfolio;
          final portfolioValue = userDataProvider.totalPortfolioValue;
          
          return RefreshIndicator(
            onRefresh: () async {
              // Pull to refresh functionality - actually refresh the data
              await userDataProvider.refreshData();
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Refreshed market data')),
              );
            },
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                _buildPortfolioChart(context),
                const SizedBox(height: 24.0),
                _buildPortfolioSummary(context, userDataProvider),
                const SizedBox(height: 24.0),
                _buildPortfolioList(context, portfolio, userDataProvider),
              ],
            ),
          );
        },
      ),
    );
  }

  // Helper method to build detail items
  Widget _buildDetailItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: Colors.grey[400],
          size: 24.0,
        ),
        const SizedBox(height: 8.0),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16.0,
          ),
        ),
        const SizedBox(height: 4.0),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 12.0,
          ),
        ),
      ],
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
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 500),
                      transitionBuilder: (Widget child, Animation<double> animation) {
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
                        '\$${portfolioValue.toStringAsFixed(2)}',
                        key: ValueKey<String>(portfolioValue.toStringAsFixed(2)),
                        style: const TextStyle(
                          fontSize: 24.0,
                          fontWeight: FontWeight.bold,
                        ),
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
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 500),
                      transitionBuilder: (Widget child, Animation<double> animation) {
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
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  transitionBuilder: (Widget child, Animation<double> animation) {
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

  // Generate chart data based on the selected time filter and user transactions
  List<FlSpot> _generateChartData(
    String timeFilter, 
    UserDataProvider userDataProvider
  ) {
    final spots = <FlSpot>[];
    final now = DateTime.now();
    final transactions = userDataProvider.transactions;
    final currentPortfolioValue = userDataProvider.totalPortfolioValue;
    final currentCashBalance = userDataProvider.userProfile?.cashBalance ?? 0.0;
    final currentTotalBalance = userDataProvider.totalBalance;
    
    // Determine start date based on time filter
    DateTime startDate;
    int numPoints;
    
    switch (timeFilter) {
      case '1D':
        startDate = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 1));
        numPoints = 24; // Hourly data for 1 day
        break;
      case '1W':
        startDate = now.subtract(const Duration(days: 7));
        numPoints = 7; // Daily data for 1 week
        break;
      case '1M':
        startDate = DateTime(now.year, now.month - 1, now.day);
        numPoints = 30; // Daily data for 1 month
        break;
      case '3M':
        startDate = DateTime(now.year, now.month - 3, now.day);
        numPoints = 12; // Weekly data for 3 months
        break;
      case '1Y':
        startDate = DateTime(now.year - 1, now.month, now.day);
        numPoints = 12; // Monthly data for 1 year
        break;
      case 'All':
        // Use the earliest transaction date or 2 years ago, whichever is earlier
        startDate = transactions.isNotEmpty 
            ? transactions.map((t) => t.timestamp).reduce((a, b) => a.isBefore(b) ? a : b)
            : DateTime(now.year - 2, now.month, now.day);
        numPoints = 24; // Monthly data for all time
        break;
      default:
        startDate = now.subtract(const Duration(days: 7));
        numPoints = 7; // Default to 1 week
    }
    
    // Filter transactions that occurred after the start date
    final relevantTransactions = transactions
        .where((t) => t.timestamp.isAfter(startDate))
        .toList();
    
    // If there are no transactions in the selected time period, use a simple linear progression
    if (relevantTransactions.isEmpty) {
      // Start with 80% of current value as a baseline
      final baseValue = currentTotalBalance * 0.8;
      
      for (int i = 0; i < numPoints; i++) {
        final progress = i / (numPoints - 1);
        final value = baseValue + (currentTotalBalance - baseValue) * progress;
        spots.add(FlSpot(i.toDouble(), value));
      }
      
      return spots;
    }
    
    // Sort transactions by timestamp (oldest first)
    relevantTransactions.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    
    // Calculate time intervals for data points
    final timeRange = now.difference(startDate).inMilliseconds;
    final intervalMs = timeRange / (numPoints - 1);
    
    // Initialize with starting balance (assume 80% of current if no transactions)
    double runningBalance = currentTotalBalance * 0.8;
    
    // If we have transactions, calculate a more accurate starting balance
    if (relevantTransactions.isNotEmpty) {
      // Start with current balance and work backwards through transactions
      runningBalance = currentTotalBalance;
      
      for (final transaction in transactions.reversed) {
        if (transaction.timestamp.isBefore(startDate)) {
          // Stop once we reach transactions before our start date
          break;
        }
        
        // Reverse the transaction effect
        if (transaction.type == TransactionType.buy) {
          // For buy: add the cost back to balance, remove the shares value
          runningBalance += transaction.totalValue;
          // We don't have historical prices, so use purchase price as an approximation
          runningBalance -= transaction.price * transaction.quantity;
        } else {
          // For sell: remove the proceeds, add the shares value
          runningBalance -= transaction.totalValue;
          // We don't have historical prices, so use sale price as an approximation
          runningBalance += transaction.price * transaction.quantity;
        }
      }
      
      // Ensure we don't go negative or too low
      runningBalance = runningBalance.clamp(currentTotalBalance * 0.5, double.infinity);
    }
    
    // Generate data points at regular intervals
    for (int i = 0; i < numPoints; i++) {
      final pointTime = startDate.add(Duration(milliseconds: (intervalMs * i).round()));
      double balance = runningBalance;
      
      // Apply all transactions that happened before this point
      for (final transaction in relevantTransactions) {
        if (transaction.timestamp.isAfter(pointTime)) {
          // Skip transactions that haven't happened yet at this point
          continue;
        }
        
        // Apply transaction effect
        if (transaction.type == TransactionType.buy) {
          // For buy: subtract the cost, add the shares value
          balance -= transaction.totalValue;
          // We don't have historical prices, so use purchase price as an approximation
          balance += transaction.price * transaction.quantity;
        } else {
          // For sell: add the proceeds, remove the shares value
          balance += transaction.totalValue;
          // We don't have historical prices, so use sale price as an approximation
          balance -= transaction.price * transaction.quantity;
        }
      }
      
      // Ensure the last point matches the current total balance
      if (i == numPoints - 1) {
        balance = currentTotalBalance;
      }
      
      spots.add(FlSpot(i.toDouble(), balance));
    }
    
    return spots;
  }

  Widget _buildPortfolioChart(BuildContext context) {
    return Consumer<UserDataProvider>(
      builder: (context, userDataProvider, child) {
        // Get portfolio data
        final portfolioValue = userDataProvider.totalPortfolioValue;
        final cashBalance = userDataProvider.userProfile?.cashBalance ?? 0.0;
        final totalBalance = userDataProvider.totalBalance;
        
        // Generate chart data based on user transactions and selected time filter
        final spots = _generateChartData(
          _selectedTimeFilter,
          userDataProvider
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
                            interval: max(1.0, (maxY - minY) / 4), // Ensure interval is not zero
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
                const SizedBox(height: 16.0),
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
          fontWeight: FontWeight.w600,
          fontFamily: 'Poppins',
        ),
        backgroundColor: const Color(0xFF1E1E1E),
        selectedColor: Theme.of(context).colorScheme.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      ),
    );
  }

  // Show portfolio item details in a bottom sheet with buy/sell options
  void _showPortfolioItemDetails(BuildContext context, PortfolioItem item, Song song) {
    final userDataProvider = Provider.of<UserDataProvider>(context, listen: false);
    
    // Calculate current value and profit/loss
    final currentValue = song.currentPrice * item.quantity;
    final purchaseValue = item.purchasePrice * item.quantity;
    final profitLoss = currentValue - purchaseValue;
    final profitLossPercent = (profitLoss / purchaseValue) * 100;
    final isProfit = profitLoss >= 0;
    
    // Controller for quantity input
    final TextEditingController quantityController = TextEditingController(text: '1');
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            // Parse quantity from controller
            int quantity = int.tryParse(quantityController.text) ?? 1;
            if (quantity < 1) quantity = 1;
            
            // Calculate transaction values
            final transactionValue = song.currentPrice * quantity;
            final cashBalance = userDataProvider.userProfile?.cashBalance ?? 0.0;
            final canBuy = cashBalance >= transactionValue;
            final canSell = item.quantity >= quantity;
            
            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 8),
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
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.grey[800],
                          backgroundImage: item.albumArtUrl != null ? NetworkImage(item.albumArtUrl!) : null,
                          child: item.albumArtUrl == null ? const Icon(Icons.music_note, size: 30) : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.songName,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                item.artistName,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[400],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.headphones, size: 14, color: Colors.grey[400]),
                                  const SizedBox(width: 4),
                                  Text(
                                    userDataProvider.getSongStreamCount(item.songId),
                                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                                  ),
                                  const SizedBox(width: 12),
                                  Icon(Icons.category, size: 14, color: Colors.grey[400]),
                                  const SizedBox(width: 4),
                                  Text(
                                    song.genre,
                                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const Divider(),
                  
                  // Current price and performance
                  Padding(
                    padding: const EdgeInsets.all(16.0),
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
                            const SizedBox(height: 4),
                            Text(
                              '\$${song.currentPrice.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  song.isPriceUp ? Icons.arrow_upward : Icons.arrow_downward,
                                  color: song.isPriceUp ? Colors.green : Colors.red,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${song.isPriceUp ? "+" : ""}${song.priceChangePercent.toStringAsFixed(2)}%',
                                  style: TextStyle(
                                    color: song.isPriceUp ? Colors.green : Colors.red,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
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
                            const SizedBox(height: 4),
                            Text(
                              '${item.quantity} ${item.quantity == 1 ? 'share' : 'shares'}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Avg. Price: \$${item.purchasePrice.toStringAsFixed(2)}',
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
                    padding: const EdgeInsets.all(16.0),
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
                            const SizedBox(height: 4),
                            Text(
                              '\$${currentValue.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
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
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  isProfit ? Icons.arrow_upward : Icons.arrow_downward,
                                  color: isProfit ? Colors.green : Colors.red,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${isProfit ? "+" : ""}${profitLoss.toStringAsFixed(2)} (${isProfit ? "+" : ""}${profitLossPercent.toStringAsFixed(2)}%)',
                                  style: TextStyle(
                                    color: isProfit ? Colors.green : Colors.red,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Transaction section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
                        const SizedBox(height: 16),
                        
                        // Quantity input
                        Row(
                          children: [
                            const Text(
                              'Quantity:',
                              style: TextStyle(fontSize: 16),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextField(
                                controller: quantityController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                                onChanged: (value) {
                                  setState(() {
                                    // Update UI when quantity changes
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Transaction value
                        Row(
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
                        
                        const SizedBox(height: 8),
                        
                        // Cash balance
                        Row(
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
                        
                        const SizedBox(height: 24),
                        
                        // Buy and sell buttons
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: canBuy ? () async {
                                  // Buy the song
                                  final success = await userDataProvider.buySong(song.id, quantity);
                                  
                                  if (success) {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Successfully bought $quantity ${quantity == 1 ? 'share' : 'shares'} of ${song.name}'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Failed to buy shares. Insufficient funds.'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                } : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                ),
                                child: const Text(
                                  'BUY',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: canSell ? () async {
                                  // Sell the song
                                  final success = await userDataProvider.sellSong(song.id, quantity);
                                  
                                  if (success) {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Successfully sold $quantity ${quantity == 1 ? 'share' : 'shares'} of ${song.name}'),
                                        backgroundColor: Colors.blue,
                                      ),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Failed to sell shares. Insufficient shares.'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                } : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                ),
                                child: const Text(
                                  'SELL',
                                  style: TextStyle(
                                    fontSize: 16,
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
                  
                  const Spacer(),
                  
                  // Close button
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[800],
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('CLOSE'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPortfolioList(BuildContext context, List<PortfolioItem> portfolio, UserDataProvider userDataProvider) {
    // Use Consumer to ensure real-time updates
    return Consumer<UserDataProvider>(
      builder: (context, provider, child) {
        // Get the latest portfolio data
        final latestPortfolio = provider.portfolio;
        
        if (latestPortfolio.isEmpty) {
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
                      '${latestPortfolio.length} ${latestPortfolio.length == 1 ? 'Song' : 'Songs'}',
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
                  itemCount: latestPortfolio.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final item = latestPortfolio[index];
                    // Get the latest song data to ensure current prices
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
                    
                    // Calculate values based on latest data
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
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${item.artistName}'),
                          Row(
                            children: [
                              Text('${item.quantity} ${item.quantity == 1 ? 'share' : 'shares'}'),
                              const SizedBox(width: 8),
                              Icon(Icons.headphones, size: 14, color: Colors.grey[400]),
                              const SizedBox(width: 2),
                              Text(
                                provider.getSongStreamCount(item.songId),
                                style: TextStyle(color: Colors.grey[400], fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),
                      trailing: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 500),
                            transitionBuilder: (Widget child, Animation<double> animation) {
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
                              '\$${currentValue.toStringAsFixed(2)}',
                              key: ValueKey<String>(currentValue.toStringAsFixed(2)),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 500),
                            transitionBuilder: (Widget child, Animation<double> animation) {
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
                              '${isProfit ? '+' : ''}${profitLoss.toStringAsFixed(2)} (${isProfit ? '+' : ''}${profitLossPercent.toStringAsFixed(2)}%)',
                              key: ValueKey<String>(profitLoss.toStringAsFixed(2)),
                              style: TextStyle(
                                color: isProfit ? Colors.green : Colors.red,
                                fontSize: 12.0,
                              ),
                            ),
                          ),
                        ],
                      ),
                      onTap: () {
                        _showPortfolioItemDetails(context, item, song);
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
