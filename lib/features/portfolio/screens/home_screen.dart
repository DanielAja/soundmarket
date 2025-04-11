import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math';
import '../../../shared/providers/user_data_provider.dart'; // Corrected path
import '../../../shared/models/portfolio_item.dart'; // Corrected path
import '../../../shared/models/song.dart'; // Corrected path
import '../../../shared/models/transaction.dart'; // Corrected path
import '../../../shared/widgets/real_time_portfolio_widget.dart'; // Corrected path
import '../../../core/theme/app_spacing.dart'; // Corrected path

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
          
          // Removed unused variable: final portfolio = userDataProvider.portfolio;
          // Removed unused variable: final portfolioValue = userDataProvider.totalPortfolioValue;
          
          return RefreshIndicator(
            onRefresh: () async {
              // Pull to refresh functionality - actually refresh the data
              await userDataProvider.refreshData();
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Refreshed market data')),
              );
            },
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.l), // Use AppSpacing.l
              children: [
                _buildPortfolioChart(context),
                const SizedBox(height: AppSpacing.xl), // Use AppSpacing.xl
                _buildPortfolioSummary(context, userDataProvider),
                const SizedBox(height: AppSpacing.l), // Use AppSpacing.l
                // Add real-time portfolio widget with buy/sell functionality
                RealTimePortfolioWidget(
                  onItemTap: (item, song) => _showPortfolioItemDetails(context, item, song),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Removed unused method: _buildDetailItem
  /*
  Widget _buildDetailItem(String label, String value, IconData icon) { // This method is unused
    return Column(
      children: [
        Icon(
          icon,
          color: Colors.grey[400],
          size: 24.0,
        ),
        const SizedBox(height: AppSpacing.s), // Use AppSpacing.s
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16.0,
          ),
        ),
        const SizedBox(height: AppSpacing.xs), // Use AppSpacing.xs
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
  */

  Widget _buildPortfolioSummary(BuildContext context, UserDataProvider userDataProvider) {
    final portfolioValue = userDataProvider.totalPortfolioValue;
    final cashBalance = userDataProvider.userProfile?.cashBalance ?? 0.0;
    final totalBalance = userDataProvider.totalBalance;
    final history = userDataProvider.portfolioHistory;

    // Calculate cumulative statistics from history
    double totalGainLoss = 0.0;
    double totalGainLossPercent = 0.0;
    double highestValue = portfolioValue; // Start with current
    double lowestValue = portfolioValue; // Start with current

    if (history.isNotEmpty) {
      final initialValue = history.first.value;
      totalGainLoss = portfolioValue - initialValue;
      if (initialValue != 0) {
        totalGainLossPercent = (totalGainLoss / initialValue) * 100;
      }
      // Find highest and lowest from history, including current value
      highestValue = history.map((s) => s.value).reduce(max);
      highestValue = max(highestValue, portfolioValue);
      lowestValue = history.map((s) => s.value).reduce(min);
      lowestValue = min(lowestValue, portfolioValue);
    }

    final isPositiveGain = totalGainLoss >= 0;

    return Card(
      elevation: 4.0,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.l), // Use AppSpacing.l
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
            const SizedBox(height: AppSpacing.l), // Use AppSpacing.l
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Portfolio Value',
                          style: TextStyle(
                            color: Colors.grey[400],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.s), // Use AppSpacing.s
                        Icon(Icons.headphones, size: 14, color: Colors.grey[400]),
                        const SizedBox(width: AppSpacing.xxs), // Use AppSpacing.xxs
                        Text(
                          userDataProvider.getFormattedTotalPortfolioStreamCount(),
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12,
                          ),
                        ),
                      ],
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
                    const SizedBox(height: AppSpacing.xs), // Use AppSpacing.xs
                    Row(
                      children: [
                        Icon(
                          isPositiveGain ? Icons.arrow_upward : Icons.arrow_downward,
                          color: isPositiveGain ? Colors.green : Colors.red,
                          size: 16.0,
                        ),
                        const SizedBox(width: AppSpacing.xs), // Use AppSpacing.xs
                        Text(
                          // Display total gain/loss since beginning
                          '${isPositiveGain ? "+" : ""}${totalGainLoss.toStringAsFixed(2)} (${isPositiveGain ? "+" : ""}${totalGainLossPercent.toStringAsFixed(2)}%) All Time',
                          style: TextStyle(
                            color: isPositiveGain ? Colors.green : Colors.red,
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
            const SizedBox(height: AppSpacing.l), // Use AppSpacing.l
            const Divider(),
            const SizedBox(height: AppSpacing.s), // Use AppSpacing.s
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

  // Generate chart data based on the selected time filter and portfolio history
  List<FlSpot> _generateChartData(
    String timeFilter,
    UserDataProvider userDataProvider,
  ) {
    final now = DateTime.now();
    final history = userDataProvider.portfolioHistory;
    final currentPortfolioValue = userDataProvider.totalPortfolioValue; // Get current value

    if (history.isEmpty) {
      // If no history, show a flat line at the current value (or starting value if available)
      final startValue = history.isNotEmpty ? history.first.value : currentPortfolioValue;
      return [
        FlSpot(0, startValue),
        FlSpot(1, currentPortfolioValue), // Show current value as the end point
      ];
    }

    // Determine start date based on time filter
    DateTime startDate;

    switch (timeFilter) {
      case '1D':
        startDate = now.subtract(const Duration(days: 1));
        break;
      case '1W':
        startDate = now.subtract(const Duration(days: 7));
        break;
      case '1M':
        startDate = now.subtract(const Duration(days: 30)); // Approx
        break;
      case '3M':
        startDate = now.subtract(const Duration(days: 90)); // Approx
        break;
      case '1Y':
        startDate = now.subtract(const Duration(days: 365)); // Approx
        break;
      case 'All':
      default:
        startDate = history.first.timestamp; // Use the earliest record
        break;
    }

    // Find the snapshot just before the start date to anchor the graph start
    final startSnapshotIndex = history.lastIndexWhere((s) => s.timestamp.isBefore(startDate));
    final startSnapshot = startSnapshotIndex >= 0 ? history[startSnapshotIndex] : history.first;

    // Filter history to the relevant period, including the start snapshot
    final relevantHistory = history
        .where((s) => s.timestamp.isAfter(startSnapshot.timestamp) || s.timestamp == startSnapshot.timestamp)
        .toList();

    // If only the start snapshot exists in the relevant period, add the current value
    if (relevantHistory.length <= 1) {
       return [
         FlSpot(0, startSnapshot.value),
         FlSpot(1, currentPortfolioValue), // Show current value as the end point
       ];
    }

    // Generate spots
    final spots = <FlSpot>[];
    final totalDuration = now.difference(startSnapshot.timestamp);

    for (int i = 0; i < relevantHistory.length; i++) {
      final snapshot = relevantHistory[i];
      // Calculate X based on time progression relative to the start snapshot
      final timeDiff = snapshot.timestamp.difference(startSnapshot.timestamp);
      final xValue = totalDuration.inMilliseconds > 0
          ? (timeDiff.inMilliseconds / totalDuration.inMilliseconds) * (relevantHistory.length -1) // Scale x across the number of points
          : i.toDouble(); // Fallback if duration is zero

      spots.add(FlSpot(xValue, snapshot.value));
    }

     // Ensure the very last spot reflects the current portfolio value accurately
     // Replace the last generated spot's value or add a new one if needed
     final lastSnapshotTimeDiff = relevantHistory.last.timestamp.difference(startSnapshot.timestamp);
     final lastXValue = totalDuration.inMilliseconds > 0
         ? (lastSnapshotTimeDiff.inMilliseconds / totalDuration.inMilliseconds) * (relevantHistory.length -1)
         : (relevantHistory.length - 1).toDouble();

     if (spots.isNotEmpty && spots.last.x == lastXValue) {
       spots[spots.length - 1] = FlSpot(lastXValue, currentPortfolioValue);
     } else {
       // Add a final spot for the current time/value if it's significantly different
       final nowTimeDiff = now.difference(startSnapshot.timestamp);
       final nowXValue = totalDuration.inMilliseconds > 0
           ? (nowTimeDiff.inMilliseconds / totalDuration.inMilliseconds) * (relevantHistory.length -1)
           : relevantHistory.length.toDouble();
       spots.add(FlSpot(nowXValue, currentPortfolioValue));
     }


    // Optional: Implement data aggregation for older periods ('1Y', 'All') here
    // to improve performance if history becomes very large.
    // For now, we plot all points in the filtered range.

    return spots;
  }

  Widget _buildPortfolioChart(BuildContext context) {
    return Consumer<UserDataProvider>(
      builder: (context, userDataProvider, child) {
        // Get portfolio data
        // Removed unused variable: final portfolioValue = userDataProvider.totalPortfolioValue; // Unused
        // Removed unused variable: final cashBalance = userDataProvider.userProfile?.cashBalance ?? 0.0; // Unused
        // Removed unused variable: final totalBalance = userDataProvider.totalBalance; // Unused
        // Removed unused variable: final currentPortfolioValue = userDataProvider.totalPortfolioValue; // Unused - Removing again
        // Removed unused variable: final currentCashBalance = userDataProvider.userProfile?.cashBalance ?? 0.0; // Unused - Removing again
        
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
        padding: const EdgeInsets.all(AppSpacing.l), // Use AppSpacing.l
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
                        const SizedBox(width: AppSpacing.xs), // Use AppSpacing.xs
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
                const SizedBox(height: AppSpacing.l), // Use AppSpacing.l
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
                            interval: 1, // Adjust interval based on range later if needed
                            getTitlesWidget: (value, meta) {
                              // value corresponds to the x-value of the FlSpot
                              // We need to map this back to a timestamp from the relevant history
                              final history = userDataProvider.portfolioHistory;
                              if (history.isEmpty || spots.isEmpty) return const SizedBox();

                              // Determine the start date based on the filter
                              final now = DateTime.now();
                              DateTime filterStartDate;
                              switch (_selectedTimeFilter) {
                                case '1D': filterStartDate = now.subtract(const Duration(days: 1)); break;
                                case '1W': filterStartDate = now.subtract(const Duration(days: 7)); break;
                                case '1M': filterStartDate = now.subtract(const Duration(days: 30)); break;
                                case '3M': filterStartDate = now.subtract(const Duration(days: 90)); break;
                                case '1Y': filterStartDate = now.subtract(const Duration(days: 365)); break;
                                case 'All':
                                default: filterStartDate = history.first.timestamp; break;
                              }

                              // Find the actual start snapshot used for the graph
                              final startSnapshotIndex = history.lastIndexWhere((s) => s.timestamp.isBefore(filterStartDate));
                              final startSnapshot = startSnapshotIndex >= 0 ? history[startSnapshotIndex] : history.first;
                              final relevantHistory = history.where((s) => !s.timestamp.isBefore(startSnapshot.timestamp)).toList();

                              if (relevantHistory.isEmpty || value < 0 || value >= spots.length) {
                                 return const SizedBox(); // Avoid index errors
                              }

                              // Find the approximate timestamp for the given spot 'value' (x-axis index)
                              // This requires knowing how the x-values were calculated in _generateChartData
                              // Let's approximate by finding the corresponding snapshot in relevantHistory
                              final index = value.round().clamp(0, relevantHistory.length - 1);
                              final timestamp = relevantHistory[index].timestamp;

                              // --- Generate Label based on Filter ---
                              String label = '';
                              int maxLabels = 5; // Limit number of labels shown

                              // Simple labeling based on index for now, needs refinement based on actual timestamps
                              if (spots.length > 1 && value.toInt() % (spots.length ~/ maxLabels).clamp(1, spots.length) == 0) {
                                switch (_selectedTimeFilter) {
                                  case '1D': // Show Hour:Minute
                                    label = '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
                                    break;
                                  case '1W': // Show Day (e.g., Mon)
                                  case '1M': // Show Day (e.g., 15)
                                    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                                    label = days[timestamp.weekday - 1]; // Or timestamp.day.toString(); for 1M
                                    break;
                                  case '3M': // Show Month/Day (e.g., 4/11)
                                  case '1Y': // Show Month (e.g., Apr)
                                    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
                                    label = months[timestamp.month - 1];
                                    break;
                                  case 'All': // Show Year or Month/Year
                                  default:
                                    label = timestamp.year.toString(); // Simplistic, show year
                                    break;
                                }
                              }

                              if (label.isEmpty) return const SizedBox();

                              return Padding(
                                padding: const EdgeInsets.only(top: AppSpacing.s), // Use AppSpacing.s
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
                                padding: const EdgeInsets.only(right: AppSpacing.s), // Use AppSpacing.s
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
                            color: chartColor.withAlpha((255 * 0.2).round()), // Replaced withOpacity
                            gradient: LinearGradient(
                              colors: [
                                chartColor.withAlpha((255 * 0.4).round()), // Replaced withOpacity
                                chartColor.withAlpha((255 * 0.1).round()), // Replaced withOpacity
                                chartColor.withAlpha(0), // Replaced withOpacity
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
                const SizedBox(height: AppSpacing.l), // Use AppSpacing.l
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
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs), // Use AppSpacing.xs
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
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: AppSpacing.s), // Use AppSpacing.m and AppSpacing.s
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
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Handle bar
                    Center(
                      child: Container(
                        margin: const EdgeInsets.only(top: AppSpacing.m, bottom: AppSpacing.s), // Use AppSpacing.m and AppSpacing.s
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
                      padding: const EdgeInsets.all(AppSpacing.l), // Use AppSpacing.l
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              if (item.albumArtUrl != null) {
                                _showFullAlbumArt(context, item.albumArtUrl!, item.songName, item.artistName);
                              }
                            },
                            child: CircleAvatar(
                              radius: 30,
                              backgroundColor: Colors.grey[800],
                              backgroundImage: item.albumArtUrl != null ? NetworkImage(item.albumArtUrl!) : null,
                              child: item.albumArtUrl == null ? const Icon(Icons.music_note, size: 30) : null,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.l), // Use AppSpacing.l
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
                                const SizedBox(height: AppSpacing.xs), // Use AppSpacing.xs
                                Row(
                                  children: [
                                    Icon(Icons.headphones, size: 14, color: Colors.grey[400]),
                                    const SizedBox(width: AppSpacing.xs), // Use AppSpacing.xs
                                    Text(
                                      userDataProvider.getSongStreamCount(item.songId),
                                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                                    ),
                                    const SizedBox(width: AppSpacing.m), // Use AppSpacing.m
                                    Icon(Icons.category, size: 14, color: Colors.grey[400]),
                                    const SizedBox(width: AppSpacing.xs), // Use AppSpacing.xs
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
                    
                    // Listen button
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l), // Use AppSpacing.l
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // Launch music player or streaming service with this song
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Opening ${item.songName} in music player...'),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                        icon: const Icon(Icons.play_circle_filled, color: Colors.white),
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
                      padding: const EdgeInsets.all(AppSpacing.l), // Use AppSpacing.l
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
                              const SizedBox(height: AppSpacing.xs), // Use AppSpacing.xs
                              Text(
                                '\$${song.currentPrice.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs), // Use AppSpacing.xs
                              Row(
                                children: [
                                  Icon(
                                    song.isPriceUp ? Icons.arrow_upward : Icons.arrow_downward,
                                    color: song.isPriceUp ? Colors.green : Colors.red,
                                    size: 14,
                                  ),
                                  const SizedBox(width: AppSpacing.xs), // Use AppSpacing.xs
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
                              const SizedBox(height: AppSpacing.xs), // Use AppSpacing.xs
                              Text(
                                '${item.quantity} ${item.quantity == 1 ? 'share' : 'shares'}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs), // Use AppSpacing.xs
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
                      padding: const EdgeInsets.all(AppSpacing.l), // Use AppSpacing.l
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
                              const SizedBox(height: AppSpacing.xs), // Use AppSpacing.xs
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
                              const SizedBox(height: AppSpacing.xs), // Use AppSpacing.xs
                              Row(
                                children: [
                                  Icon(
                                    isProfit ? Icons.arrow_upward : Icons.arrow_downward,
                                    color: isProfit ? Colors.green : Colors.red,
                                    size: 14,
                                  ),
                                  const SizedBox(width: AppSpacing.xs), // Use AppSpacing.xs
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
                    
                    const SizedBox(height: AppSpacing.l), // Use AppSpacing.l
                    
                    // Transaction section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l), // Use AppSpacing.l
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
                          const SizedBox(height: AppSpacing.l), // Use AppSpacing.l
                          
                          // Quantity input
                          Row(
                            children: [
                              const Text(
                                'Quantity:',
                                style: TextStyle(fontSize: 16),
                              ),
                              const SizedBox(width: AppSpacing.l), // Use AppSpacing.l
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
                          
                          const SizedBox(height: AppSpacing.l), // Use AppSpacing.l
                          
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
                          
                          const SizedBox(height: AppSpacing.s), // Use AppSpacing.s
                          
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
                          
                          const SizedBox(height: AppSpacing.xl), // Use AppSpacing.xl
                          
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
                              const SizedBox(width: AppSpacing.l), // Use AppSpacing.l
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
                    
                    // Close button
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.l), // Use AppSpacing.l
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
              ),
            );
          },
        );
      },
    );
  }

  // Show full album art in a dialog
  void _showFullAlbumArt(BuildContext context, String albumArtUrl, String songName, String artistName) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(AppSpacing.l), // Use AppSpacing.l
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Album art container with rounded corners
            ClipRRect(
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
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded / 
                                loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: MediaQuery.of(context).size.width * 0.9,
                      height: MediaQuery.of(context).size.width * 0.9,
                      color: Colors.grey[900],
                      child: const Center(
                        child: Icon(Icons.error_outline, size: 50, color: Colors.white),
                      ),
                    );
                  },
                ),
              ),
            ),
            
            // Song info
            Container(
              padding: const EdgeInsets.all(AppSpacing.l), // Use AppSpacing.l
              margin: const EdgeInsets.only(top: AppSpacing.l), // Use AppSpacing.l
              decoration: BoxDecoration(
                color: Colors.black.withAlpha((255 * 0.7).round()), // Replaced withOpacity
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
                  const SizedBox(height: AppSpacing.xs), // Use AppSpacing.xs
                  Text(
                    artistName,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[300],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            
            // Close button
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.l), // Use AppSpacing.l
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[800],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
