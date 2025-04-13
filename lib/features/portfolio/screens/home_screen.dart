import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math';
import 'dart:async'; // Import Timer (Moved to top)
import '../../../shared/providers/user_data_provider.dart'; // Corrected path
import '../../../shared/models/portfolio_item.dart'; // Corrected path
import '../../../shared/models/song.dart'; // Corrected path
import '../../../shared/models/transaction.dart'; // Corrected path
import '../../../shared/models/portfolio_snapshot.dart'; // Import Snapshot model
import '../../../shared/widgets/real_time_portfolio_widget.dart'; // Corrected path
import '../../../core/theme/app_spacing.dart'; // Corrected path


class HomeScreen extends StatefulWidget {
  HomeScreen({super.key}); // Removed const

  @override
  State<HomeScreen> createState() => _HomeScreenState();
} // Moved closing brace

class _HomeScreenState extends State<HomeScreen> {
  String _selectedTimeFilter = '1W'; // Default to 1 week
  List<PortfolioSnapshot> _chartData = []; // Store fetched snapshots
  bool _isChartLoading = true;
  Timer? _liveUpdateTimer; // Timer for 1D updates

  @override
  void initState() {
    super.initState();
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
    super.dispose();
  }

  // Stop existing timer and start a new one if filter is '1D'
  void _manageLiveUpdateTimer(String timeFilter) {
    _liveUpdateTimer?.cancel();
    if (timeFilter == '1D') {
      _liveUpdateTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
         // Periodically refresh 1D data if the widget is still mounted
         if (mounted && _selectedTimeFilter == '1D') {
            _updateChartData('1D', isLiveUpdate: true); // Pass flag to avoid full loading indicator
         } else {
            timer.cancel(); // Cancel if filter changed or widget disposed
         }
      });
    }
  }


  // Method to update chart data asynchronously by fetching from provider
  Future<void> _updateChartData(String timeFilter, {bool isLiveUpdate = false}) async {
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

    final userDataProvider = Provider.of<UserDataProvider>(context, listen: false);
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
        startDate = earliestTimestamp ?? now.subtract(const Duration(days: 365));
        break;
    }

    try {
      // Fetch the data for the calculated range
      final newChartData = await userDataProvider.fetchPortfolioHistory(startDate, endDate);

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
        title: const Text('Sound Market'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Trigger a manual refresh of the song service and chart
              final userDataProvider = Provider.of<UserDataProvider>(context, listen: false);
              // Use then() to ensure chart update happens after data refresh completes
              userDataProvider.refreshData().then((_) {
                 if (mounted) {
                   _updateChartData(_selectedTimeFilter); // Refresh chart after data refresh
                 }
              }).catchError((error) {
                 // Handle potential errors during refresh
                 if (mounted) {
                   ScaffoldMessenger.of(context).showSnackBar(
                     SnackBar(content: Text('Error refreshing data: $error')),
                   );
                 }
              });

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Refreshing market data...')),
              );
            },
          ),
        ],
      ),
      body: Consumer<UserDataProvider>(
        builder: (context, userDataProvider, child) {
          // Show loading indicator only if the provider itself is loading initial data
          // OR if the chart data is specifically being loaded
          if (userDataProvider.isLoading || _isChartLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
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
                _buildPortfolioSummary(context, userDataProvider, _chartData), // Pass fetched data
                const SizedBox(height: AppSpacing.l),
                RealTimePortfolioWidget(
                  // Ensure song data is available before showing details
                  onItemTap: (item, song) {
                     if (song != null) {
                       _showPortfolioItemDetails(context, item, song);
                     } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Song data not available for ${item.songName}')),
                        );
                     }
                  }
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
      if (initialValue.abs() > 0.001) { // Avoid division by near-zero
        rangeGainLoss = currentPortfolioValue - initialValue;
        rangeGainLossPercent = (rangeGainLoss / initialValue) * 100;
      } else if (currentPortfolioValue > 0) {
        // Handle case where initial value was zero but current is positive
        rangeGainLoss = currentPortfolioValue;
        rangeGainLossPercent = double.infinity; // Or a large number/special display
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
        case '1D': rangeLabel = 'Today'; break;
        case '1W': rangeLabel = 'Past Week'; break;
        case '1M': rangeLabel = 'Past Month'; break;
        case '3M': rangeLabel = 'Past 3 Months'; break;
        case '1Y': rangeLabel = 'Past Year'; break;
        case 'All': rangeLabel = 'All Time'; break;
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
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.l), // Use AppSpacing.l
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start, // Align columns to top
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
                          '\$${currentPortfolioValue.toStringAsFixed(2)}', // Use currentPortfolioValue
                          key: ValueKey<String>(currentPortfolioValue.toStringAsFixed(2)), // Use currentPortfolioValue
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
                          Expanded( // Wrap the Text with Expanded
                            child: Text(
                              // Display total gain/loss since beginning
                              // Display gain/loss for the selected range
                              '${isPositiveGain ? "+" : ""}${rangeGainLoss.toStringAsFixed(2)} (${isPositiveGain ? "+" : ""}${rangeGainLossPercent.isFinite ? rangeGainLossPercent.toStringAsFixed(2) + "%" : "N/A"}) $rangeLabel',
                              style: TextStyle(
                                color: isPositiveGain ? Colors.green : Colors.red,
                              ),
                              overflow: TextOverflow.ellipsis, // Prevent overflow
                              maxLines: 1, // Ensure it stays on one line
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Add some spacing between the columns
                const SizedBox(width: AppSpacing.m),
                // Right Column (Cash Balance) - Keep it fixed size or less flexible
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start, // Changed to start for alignment
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

    // --- Data Aggregation (Example for 1Y/All) ---
    List<PortfolioSnapshot> processedSnapshots = snapshots;
    if ((timeFilter == '1Y' || timeFilter == 'All') && snapshots.length > 150) {
      processedSnapshots = _aggregateDailyAverage(snapshots);
      if (processedSnapshots.isEmpty) processedSnapshots = snapshots; // Revert if aggregation empties list
    }

    // --- Generate FlSpots ---
    final spots = <FlSpot>[];
    if (processedSnapshots.isEmpty) {
       return [FlSpot(0, currentPortfolioValue), FlSpot(1, currentPortfolioValue)]; // Fallback
    }
    final firstTimestampMillis = processedSnapshots.first.timestamp.millisecondsSinceEpoch;

    for (int i = 0; i < processedSnapshots.length; i++) {
      final snapshot = processedSnapshots[i];
      final double xValue = (snapshot.timestamp.millisecondsSinceEpoch - firstTimestampMillis).toDouble();
      spots.add(FlSpot(xValue, snapshot.value));
    }

    // Add a final spot representing the current time and value
    final now = DateTime.now();
    final lastTimestamp = processedSnapshots.last.timestamp;
    final Duration timeSinceLastSnapshot = now.difference(lastTimestamp);

    bool addCurrentValuePoint = true;
    Duration threshold = const Duration(minutes: 5);
    if (timeFilter == '1D') threshold = const Duration(seconds: 10);
    if (timeSinceLastSnapshot < threshold) {
        addCurrentValuePoint = false;
    }

    if (addCurrentValuePoint) {
       final double currentXValue = (now.millisecondsSinceEpoch - firstTimestampMillis).toDouble();
       if (spots.isNotEmpty && currentXValue > spots.last.x) {
          spots.add(FlSpot(currentXValue, currentPortfolioValue));
       } else if (spots.isEmpty) {
         spots.add(FlSpot(0, currentPortfolioValue));
         spots.add(FlSpot(1, currentPortfolioValue));
       }
    }

    // Ensure at least two spots exist
    if (spots.length == 1) {
       spots.add(FlSpot(spots.first.x + 1, spots.first.y));
    } else if (spots.isEmpty) {
       spots.add(FlSpot(0, currentPortfolioValue));
       spots.add(FlSpot(1, currentPortfolioValue));
    }

    // Ensure distinct x-values for flat lines
    if (spots.length > 1 && spots.every((s) => s.y == spots.first.y)) {
        bool distinctX = true;
        for (int i = 1; i < spots.length; i++) {
            if (spots[i].x <= spots[i-1].x) {
                distinctX = false;
                break;
            }
        }
        if (!distinctX) {
            return [FlSpot(0, spots.first.y), FlSpot(1, spots.first.y)];
        }
    }

    return spots;
  }

  // Helper for basic daily aggregation
  List<PortfolioSnapshot> _aggregateDailyAverage(List<PortfolioSnapshot> snapshots) {
    if (snapshots.isEmpty) return [];
    Map<DateTime, List<double>> dailyValues = {};
    for (var snapshot in snapshots) {
      final day = DateTime(snapshot.timestamp.year, snapshot.timestamp.month, snapshot.timestamp.day);
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


  Widget _buildPortfolioChart(BuildContext context, List<PortfolioSnapshot> chartData) {
    final userDataProvider = Provider.of<UserDataProvider>(context, listen: false);
    final currentPortfolioValue = userDataProvider.totalPortfolioValue;
    final spots = _generateChartSpots(chartData, _selectedTimeFilter, currentPortfolioValue);

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

      if ((maxY - minY).abs() < 0.01) {
        final center = (maxY + minY) / 2;
        minY = center - max(0.1, center.abs() * 0.1);
        maxY = center + max(0.1, center.abs() * 0.1);
        if (spots.every((s) => s.y >= 0) && minY < 0) {
           minY = 0;
           if ((maxY - minY).abs() < 0.1) maxY = minY + 0.1;
        }
      } else {
        final padding = (maxY - minY) * 0.05;
        final potentialMinY = minY - padding;
        minY = spots.every((s) => s.y >= 0) && potentialMinY < 0 ? 0 : potentialMinY;
        maxY += padding;
      }
      if (maxY <= minY) {
         maxY = minY + 0.1;
      }

      isPositive = endValue >= startValue;
      if (startValue.abs() > 0.001) {
        percentageChange = ((endValue / startValue) - 1) * 100;
      } else if (endValue > startValue) {
        percentageChange = double.infinity;
      } else {
        percentageChange = 0.0;
      }
    } else if (!_isChartLoading) {
      minY = currentPortfolioValue - max(0.1, currentPortfolioValue.abs() * 0.1);
      maxY = currentPortfolioValue + max(0.1, currentPortfolioValue.abs() * 0.1);
      if (currentPortfolioValue >= 0 && minY < 0) minY = 0;
      if (maxY <= minY) maxY = minY + 0.1;
      isPositive = true;
      percentageChange = 0.0;
      startValue = currentPortfolioValue;
      endValue = currentPortfolioValue;
    }

    final chartColor = isPositive ? Colors.green : Colors.red;

    return Card(
      elevation: 4.0,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Portfolio Performance',
                    style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(isPositive ? Icons.arrow_upward : Icons.arrow_downward, color: chartColor, size: 16.0),
                    const SizedBox(width: AppSpacing.xs),
                    if (spots.isNotEmpty || !_isChartLoading)
                      Text(
                        '${isPositive ? "+" : ""}${percentageChange.isFinite ? percentageChange.toStringAsFixed(2) + "%" : "N/A"}',
                        style: TextStyle(color: chartColor, fontWeight: FontWeight.bold),
                      )
                    else
                       const SizedBox(),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.l),
            SizedBox(
              height: 200.0,
              child: _isChartLoading
                  ? const Center(child: CircularProgressIndicator())
                  : spots.isEmpty
                      ? Center(child: Text('No data available for this period.', style: TextStyle(color: Colors.grey[400])))
                      : LineChart(
                          LineChartData(
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              horizontalInterval: (maxY > minY) ? max(0.1, (maxY - minY) / 4) : 1.0,
                              getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey[800] ?? Colors.grey, strokeWidth: 0.5, dashArray: [5, 5]),
                            ),
                            titlesData: FlTitlesData(
                              show: true,
                              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 30,
                                  interval: spots.length > 1 && spots.last.x > spots.first.x ? max(1, (spots.last.x - spots.first.x) / 5) : 1,
                                  getTitlesWidget: (value, meta) {
                                    if (spots.isEmpty || chartData.isEmpty) return const SizedBox();
                                    final firstTimestampMillis = chartData.first.timestamp.millisecondsSinceEpoch;
                                    final timestampMillis = firstTimestampMillis + value.toInt();
                                    final timestamp = DateTime.fromMillisecondsSinceEpoch(timestampMillis);
                                    String label = '';
                                    final Duration totalDuration = chartData.length > 1 ? chartData.last.timestamp.difference(chartData.first.timestamp) : Duration.zero;
                                    final bool isLastPoint = (value - meta.max).abs() < (meta.max - meta.min) * 0.01;

                                    // Simplified Label Logic (Add more cases as needed)
                                    switch (_selectedTimeFilter) {
                                      case '1D': label = isLastPoint ? 'Now' : (timestamp.minute == 0 && timestamp.hour % 3 == 0 ? '${timestamp.hour}:00' : ''); break;
                                      case '1W': const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']; label = isLastPoint || (timestamp.hour < 1 && timestamp.minute < 15) ? days[timestamp.weekday - 1] : ''; break;
                                      case '1M': label = isLastPoint || timestamp.day % 7 == 1 || timestamp.day == 1 ? timestamp.day.toString() : ''; break;
                                      // Add cases for 3M, 1Y, All similarly
                                      default: label = ''; // Default empty
                                    }

                                    if (label.isEmpty) return const SizedBox();
                                    return SideTitleWidget(
                                      meta: meta, // **FIXED: Added meta**
                                      // **FIXED: Removed axisSide**
                                      space: AppSpacing.s,
                                      child: Text(label, style: TextStyle(color: Colors.grey[400], fontSize: 10)),
                                    );
                                  },
                                ),
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  interval: (maxY > minY) ? max(0.1, (maxY - minY) / 4) : 1.0,
                                  reservedSize: 45,
                                  getTitlesWidget: (value, meta) {
                                    if (value < meta.min || value > meta.max) return const SizedBox();
                                    String formattedValue;
                                    double range = meta.max - meta.min; if (range <= 0) range = 1.0;
                                    int decimalPlaces = (range < 1) ? 2 : ((range < 10) ? 1 : 0);
                                    if (value.abs() >= 1000000) formattedValue = '\$${(value / 1000000).toStringAsFixed(1)}M';
                                    else if (value.abs() >= 1000) formattedValue = '\$${(value / 1000).toStringAsFixed(value.abs() >= 10000 ? 0 : 1)}k';
                                    else formattedValue = '\$${value.toStringAsFixed(decimalPlaces)}';
                                    if (value == 0 && (meta.min < -0.01 || meta.max > 0.01) && meta.max != meta.min) { /* Optionally hide 0 */ }

                                    return SideTitleWidget(
                                      meta: meta, // **FIXED: Added meta**
                                      // **FIXED: Removed axisSide**
                                      space: AppSpacing.s,
                                      child: Text(formattedValue, style: TextStyle(color: Colors.grey[400], fontSize: 10), textAlign: TextAlign.right),
                                    );
                                  },
                                ),
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            minX: spots.isNotEmpty ? spots.first.x : 0,
                            maxX: spots.length > 1 ? spots.last.x : (spots.isNotEmpty ? spots.first.x + 1 : 1),
                            minY: minY,
                            maxY: maxY,
                            lineBarsData: [
                              LineChartBarData(
                                spots: spots, isCurved: true, curveSmoothness: 0.35, color: chartColor, barWidth: 2, isStrokeCapRound: true,
                                dotData: const FlDotData(show: false),
                                belowBarData: BarAreaData(show: true, gradient: LinearGradient(colors: [chartColor.withOpacity(0.3), chartColor.withOpacity(0.0)], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
                              ),
                            ],
                            lineTouchData: LineTouchData(
                              enabled: true,
                              touchTooltipData: LineTouchTooltipData(
                                // **FIXED: Removed invalid tooltipBgColor**
                                tooltipRoundedRadius: 4,
                                getTooltipItems: (touchedSpots) => touchedSpots.map((spot) {
                                  String formattedTime = '';
                                  // ... (tooltip time formatting logic remains the same) ...
                                   if (chartData.isNotEmpty) {
                                        final firstTimestampMillis = chartData.first.timestamp.millisecondsSinceEpoch;
                                        final targetMillis = firstTimestampMillis + spot.x.toInt();
                                        PortfolioSnapshot? closestSnapshot;
                                        int minDiff = -1;
                                        for (final snapshot in chartData) {
                                           final diff = (snapshot.timestamp.millisecondsSinceEpoch - targetMillis).abs();
                                           if (closestSnapshot == null || diff < minDiff) {
                                              minDiff = diff;
                                              closestSnapshot = snapshot;
                                           }
                                        }
                                        if (closestSnapshot != null) {
                                           final timestamp = closestSnapshot.timestamp;
                                           if (_selectedTimeFilter == '1D') formattedTime = '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
                                           else formattedTime = '${timestamp.month}/${timestamp.day}';
                                        }
                                     }
                                  return LineTooltipItem(
                                    '\$${spot.y.toStringAsFixed(2)} ${formattedTime.isNotEmpty ? '\n$formattedTime' : ''}',
                                    const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                    textAlign: TextAlign.center,
                                  );
                                }).toList(),
                              ),
                              getTouchedSpotIndicator: (barData, spotIndexes) => spotIndexes.map((index) => TouchedSpotIndicatorData(
                                FlLine(color: chartColor.withOpacity(0.5), strokeWidth: 1),
                                FlDotData(show: true, getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(radius: 4, color: chartColor, strokeWidth: 1, strokeColor: Colors.black)),
                              )).toList(),
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

  Widget _buildTimeFilterChip(String label, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          if (selected && _selectedTimeFilter != label) {
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
        labelStyle: TextStyle(color: isSelected ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).textTheme.bodyLarge?.color, fontSize: 12.0, fontWeight: FontWeight.w600, fontFamily: 'Poppins'),
        backgroundColor: Theme.of(context).chipTheme.backgroundColor,
        selectedColor: Theme.of(context).colorScheme.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
          side: BorderSide(color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey[700] ?? Colors.grey, width: 1), // **FIXED: Added null fallback**
        ),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: AppSpacing.s),
        showCheckmark: false,
      ),
    );
  }

  // Show portfolio item details in a bottom sheet with buy/sell options
  void _showPortfolioItemDetails(BuildContext context, PortfolioItem item, Song song) {
    final userDataProvider = Provider.of<UserDataProvider>(context, listen: false);
    final currentValue = song.currentPrice * item.quantity;
    final purchaseValue = item.purchasePrice * item.quantity;
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

    // **FIXED: Define controllers outside builder**
    final TextEditingController quantityController = TextEditingController(text: '1');
    final ValueNotifier<int> quantityNotifier = ValueNotifier<int>(1);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            final currentQuantity = quantityNotifier.value; // Read from notifier
            final transactionValue = song.currentPrice * currentQuantity;
            final cashBalance = userDataProvider.userProfile?.cashBalance ?? 0.0;
            final canBuy = cashBalance >= transactionValue;
            final canSell = item.quantity >= currentQuantity && currentQuantity > 0;

            return Container(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.l, left: AppSpacing.l, right: AppSpacing.l, top: AppSpacing.s),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Handle bar, Header, Listen Button, Divider, Price/Performance, Value/ProfitLoss...
                      // (Code for these sections remains largely the same as before)
                       // Handle bar
                      Center(
                        child: Container(
                          margin: const EdgeInsets.only(top: AppSpacing.s, bottom: AppSpacing.m), // Adjusted margin
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
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.m), // Vertical padding
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
                                  Text(item.songName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis, maxLines: 1),
                                  Text(item.artistName, style: TextStyle(fontSize: 16, color: Colors.grey[400]), overflow: TextOverflow.ellipsis, maxLines: 1),
                                  const SizedBox(height: AppSpacing.xs),
                                  Row(
                                    children: [
                                      Icon(Icons.headphones, size: 14, color: Colors.grey[400]),
                                      const SizedBox(width: AppSpacing.xs),
                                      Text(userDataProvider.getSongStreamCount(item.songId), style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                                      const SizedBox(width: AppSpacing.m),
                                      Icon(Icons.category, size: 14, color: Colors.grey[400]),
                                      const SizedBox(width: AppSpacing.xs),
                                      Expanded(child: Text(song.genre, style: TextStyle(color: Colors.grey[400], fontSize: 12), overflow: TextOverflow.ellipsis)),
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
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.m),
                        child: ElevatedButton.icon(
                          onPressed: () { /* Playback logic */ ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Opening ${item.songName}... (Not implemented)'))); },
                          icon: const Icon(Icons.play_circle_filled, color: Colors.white),
                          label: const Text('LISTEN TO SONG'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 48)),
                        ),
                      ),

                      const Divider(),

                      // Current price and performance
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.l),
                        child: Row( /* ... Price details ... */
                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column( crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text('Current Price', style: TextStyle(color: Colors.grey[400], fontSize: 14)),
                                const SizedBox(height: AppSpacing.xs),
                                Text('\$${song.currentPrice.toStringAsFixed(2)}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                                const SizedBox(height: AppSpacing.xs),
                                Row(children: [ Icon(song.isPriceUp ? Icons.arrow_upward : Icons.arrow_downward, color: song.isPriceUp ? Colors.green : Colors.red, size: 14), const SizedBox(width: AppSpacing.xs), Text('${song.isPriceUp ? "+" : ""}${song.priceChangePercent.toStringAsFixed(2)}%', style: TextStyle(color: song.isPriceUp ? Colors.green : Colors.red, fontSize: 14))])
                            ]),
                            Column( crossAxisAlignment: CrossAxisAlignment.end, children: [
                                Text('Your Position', style: TextStyle(color: Colors.grey[400], fontSize: 14)),
                                const SizedBox(height: AppSpacing.xs),
                                Text('${item.quantity} ${item.quantity == 1 ? 'share' : 'shares'}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                const SizedBox(height: AppSpacing.xs),
                                Text('Avg. Price: \$${item.purchasePrice.toStringAsFixed(2)}', style: TextStyle(color: Colors.grey[400], fontSize: 14))
                            ])
                          ]
                        ),
                      ),

                      // Portfolio value and profit/loss
                      Container( /* ... Value/Profit details ... */
                        color: Colors.grey[900], padding: const EdgeInsets.all(AppSpacing.l),
                        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [ Text('Current Value', style: TextStyle(color: Colors.grey[400], fontSize: 14)), const SizedBox(height: AppSpacing.xs), Text('\$${currentValue.toStringAsFixed(2)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)) ]),
                            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [ Text('Profit/Loss', style: TextStyle(color: Colors.grey[400], fontSize: 14)), const SizedBox(height: AppSpacing.xs), Row(children: [ Icon(isProfit ? Icons.arrow_upward : Icons.arrow_downward, color: isProfit ? Colors.green : Colors.red, size: 14), const SizedBox(width: AppSpacing.xs), Text('${isProfit ? "+" : ""}${profitLoss.toStringAsFixed(2)} (${isProfit ? "+" : ""}${profitLossPercent.isFinite ? profitLossPercent.toStringAsFixed(2) + "%" : "N/A"})', style: TextStyle(color: isProfit ? Colors.green : Colors.red, fontSize: 16, fontWeight: FontWeight.bold)) ]) ])
                        ])
                      ),

                      const SizedBox(height: AppSpacing.l),

                      // Transaction section
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.m),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Trade', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: AppSpacing.l),
                            Row( // Quantity Input
                              children: [
                                const Text('Quantity:', style: TextStyle(fontSize: 16)),
                                const SizedBox(width: AppSpacing.l),
                                Expanded(
                                  child: TextField(
                                    controller: quantityController, // Use the controller defined outside
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                                    onChanged: (value) {
                                      int newQuantity = int.tryParse(value) ?? 0;
                                      if (newQuantity < 0) newQuantity = 0;
                                      quantityNotifier.value = newQuantity; // Update notifier
                                      setStateModal(() {}); // Trigger rebuild for button states
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.l),
                            Row( // Transaction Value
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [ const Text('Transaction Value:', style: TextStyle(fontSize: 16)), Text('\$${transactionValue.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)) ],
                            ),
                            const SizedBox(height: AppSpacing.s),
                            Row( // Cash Balance
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [ const Text('Cash Balance:', style: TextStyle(fontSize: 16)), Text('\$${cashBalance.toStringAsFixed(2)}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: canBuy ? Colors.white : Colors.red)) ],
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            Row( // Buy/Sell Buttons
                              children: [
                                Expanded(child: ElevatedButton(
                                  onPressed: canBuy && currentQuantity > 0 ? () async { /* Buy Logic */
                                     final success = await userDataProvider.buySong(song.id, currentQuantity);
                                     if(mounted && success) {
                                        Navigator.pop(context);
                                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Successfully bought $currentQuantity ${currentQuantity == 1 ? 'share' : 'shares'} of ${song.name}'), backgroundColor: Colors.green));
                                     } else if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to buy shares. Insufficient funds or error occurred.'), backgroundColor: Colors.red));
                                     }
                                  } : null,
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(vertical: 16), disabledBackgroundColor: Colors.green.withOpacity(0.5)),
                                  child: const Text('BUY', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                                )),
                                const SizedBox(width: AppSpacing.l),
                                Expanded(child: ElevatedButton(
                                  onPressed: canSell ? () async { /* Sell Logic */
                                     final success = await userDataProvider.sellSong(song.id, currentQuantity);
                                     if(mounted && success) {
                                        Navigator.pop(context);
                                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Successfully sold $currentQuantity ${currentQuantity == 1 ? 'share' : 'shares'} of ${song.name}'), backgroundColor: Colors.blue));
                                     } else if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to sell shares. Insufficient shares or error occurred.'), backgroundColor: Colors.red));
                                     }
                                  } : null,
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red, padding: const EdgeInsets.symmetric(vertical: 16), disabledBackgroundColor: Colors.red.withOpacity(0.5)),
                                  child: const Text('SELL', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                                )),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Padding( // Close Button
                        padding: const EdgeInsets.only(top: AppSpacing.l),
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[800], padding: const EdgeInsets.symmetric(vertical: 16)),
                          child: const Text('CLOSE'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() {
       // **FIXED: Dispose controllers here**
       quantityNotifier.dispose();
       quantityController.dispose();
    });
  }

  // Show full album art in a dialog
  void _showFullAlbumArt(BuildContext context, String albumArtUrl, String songName, String artistName) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(AppSpacing.l),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect( // Album Art
              borderRadius: BorderRadius.circular(12),
              child: Container(
                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.9, maxHeight: MediaQuery.of(context).size.height * 0.6),
                child: Image.network(
                  albumArtUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      width: MediaQuery.of(context).size.width * 0.9, height: MediaQuery.of(context).size.width * 0.9, color: Colors.grey[900],
                      child: Center(child: CircularProgressIndicator(
                        // **FIXED: Added null check and > 0 check for expectedTotalBytes**
                        value: loadingProgress.expectedTotalBytes != null && loadingProgress.expectedTotalBytes! > 0
                            ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                            : null,
                      )),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => Container(width: MediaQuery.of(context).size.width * 0.9, height: MediaQuery.of(context).size.width * 0.9, color: Colors.grey[900], child: const Center(child: Icon(Icons.error_outline, size: 50, color: Colors.white))),
                ),
              ),
            ),
            Container( // Song Info
              padding: const EdgeInsets.all(AppSpacing.l), margin: const EdgeInsets.only(top: AppSpacing.l),
              decoration: BoxDecoration(color: Colors.black.withAlpha(180), borderRadius: BorderRadius.circular(12)), // Adjusted alpha
              child: Column(children: [
                Text(songName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white), textAlign: TextAlign.center),
                const SizedBox(height: AppSpacing.xs),
                Text(artistName, style: TextStyle(fontSize: 16, color: Colors.grey[300]), textAlign: TextAlign.center),
              ]),
            ),
            Padding( // Close Button
              padding: const EdgeInsets.only(top: AppSpacing.l),
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[800], foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
                child: const Text('CLOSE'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
