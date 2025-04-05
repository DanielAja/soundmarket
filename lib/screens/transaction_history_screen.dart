import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/user_data_provider.dart';
import '../models/transaction.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  TransactionFilter _currentFilter = TransactionFilter.all;
  final DateFormat _dateFormat = DateFormat('MMM d, yyyy');
  final DateFormat _timeFormat = DateFormat('h:mm a');
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction History'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Buys'),
            Tab(text: 'Sells'),
          ],
          onTap: (index) {
            setState(() {
              _currentFilter = TransactionFilter.values[index];
            });
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              _showFilterOptions(context);
            },
          ),
        ],
      ),
      body: Consumer<UserDataProvider>(
        builder: (context, userDataProvider, child) {
          final transactions = _getFilteredTransactions(userDataProvider);
          
          if (transactions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history,
                    size: 64.0,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(height: 16.0),
                  const Text(
                    'No transactions yet',
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    'Your transaction history will appear here',
                    style: TextStyle(
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
            );
          }
          
          return ListView.builder(
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              final transaction = transactions[index];
              return _buildTransactionItem(transaction);
            },
          );
        },
      ),
      bottomSheet: Consumer<UserDataProvider>(
        builder: (context, userDataProvider, child) {
          final totalSpent = userDataProvider.getTotalSpent();
          final totalEarned = userDataProvider.getTotalEarned();
          final netResult = totalEarned - totalSpent;
          final isProfit = netResult >= 0;
          
          return Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4.0,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total Summary',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      'Spent: \$${totalSpent.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 12.0,
                      ),
                    ),
                    Text(
                      'Earned: \$${totalEarned.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 12.0,
                      ),
                    ),
                  ],
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Net Result',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4.0),
                    Row(
                      children: [
                        Icon(
                          isProfit ? Icons.arrow_upward : Icons.arrow_downward,
                          color: isProfit ? Colors.green : Colors.red,
                          size: 14.0,
                        ),
                        const SizedBox(width: 4.0),
                        Text(
                          '\$${netResult.abs().toStringAsFixed(2)}',
                          style: TextStyle(
                            color: isProfit ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
  
  List<Transaction> _getFilteredTransactions(UserDataProvider provider) {
    switch (_currentFilter) {
      case TransactionFilter.all:
        return provider.transactions;
      case TransactionFilter.buy:
        return provider.getTransactionsByType(TransactionType.buy);
      case TransactionFilter.sell:
        return provider.getTransactionsByType(TransactionType.sell);
      case TransactionFilter.lastWeek:
        final now = DateTime.now();
        final weekAgo = now.subtract(const Duration(days: 7));
        return provider.getTransactionsInDateRange(weekAgo, now);
      case TransactionFilter.lastMonth:
        final now = DateTime.now();
        final monthAgo = DateTime(now.year, now.month - 1, now.day);
        return provider.getTransactionsInDateRange(monthAgo, now);
    }
  }
  
  Widget _buildTransactionItem(Transaction transaction) {
    final isBuy = transaction.type == TransactionType.buy;
    final formattedDate = _dateFormat.format(transaction.timestamp);
    final formattedTime = _timeFormat.format(transaction.timestamp);
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.grey[800],
                  backgroundImage: transaction.albumArtUrl != null 
                      ? NetworkImage(transaction.albumArtUrl!) 
                      : null,
                  child: transaction.albumArtUrl == null 
                      ? const Icon(Icons.music_note) 
                      : null,
                ),
                const SizedBox(width: 12.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transaction.songName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        transaction.artistName,
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 12.0,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  decoration: BoxDecoration(
                    color: isBuy ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                  child: Text(
                    isBuy ? 'BUY' : 'SELL',
                    style: TextStyle(
                      color: isBuy ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 12.0,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$formattedDate at $formattedTime',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12.0,
                  ),
                ),
                Text(
                  '${transaction.quantity} ${transaction.quantity == 1 ? 'share' : 'shares'} @ \$${transaction.price.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Total: ',
                  style: TextStyle(
                    color: Colors.grey[400],
                  ),
                ),
                Text(
                  '\$${transaction.totalValue.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isBuy ? Colors.red : Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  void _showFilterOptions(BuildContext context) {
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
              const Text(
                'Filter Transactions',
                style: TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16.0),
              _buildFilterOption(
                context,
                'All Transactions',
                TransactionFilter.all,
              ),
              _buildFilterOption(
                context,
                'Buy Transactions',
                TransactionFilter.buy,
              ),
              _buildFilterOption(
                context,
                'Sell Transactions',
                TransactionFilter.sell,
              ),
              _buildFilterOption(
                context,
                'Last 7 Days',
                TransactionFilter.lastWeek,
              ),
              _buildFilterOption(
                context,
                'Last 30 Days',
                TransactionFilter.lastMonth,
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildFilterOption(
    BuildContext context,
    String title,
    TransactionFilter filter,
  ) {
    final isSelected = _currentFilter == filter;
    
    return ListTile(
      title: Text(title),
      trailing: isSelected
          ? Icon(
              Icons.check_circle,
              color: Theme.of(context).colorScheme.primary,
            )
          : null,
      onTap: () {
        setState(() {
          _currentFilter = filter;
          
          // Update tab controller if filter corresponds to a tab
          if (filter == TransactionFilter.all) {
            _tabController.animateTo(0);
          } else if (filter == TransactionFilter.buy) {
            _tabController.animateTo(1);
          } else if (filter == TransactionFilter.sell) {
            _tabController.animateTo(2);
          }
        });
        Navigator.pop(context);
      },
    );
  }
}

enum TransactionFilter {
  all,
  buy,
  sell,
  lastWeek,
  lastMonth,
}
