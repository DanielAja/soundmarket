import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../shared/providers/user_data_provider.dart'; // Corrected path
import '../../../shared/models/transaction.dart'; // Corrected path

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
        centerTitle: true,
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
          // Show loading indicator when refreshing data
          if (userDataProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          
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
          
          return RefreshIndicator(
            onRefresh: () => userDataProvider.refreshData(),
            child: ListView.builder(
              itemCount: transactions.length,
              itemBuilder: (context, index) {
                final transaction = transactions[index];
                return _buildTransactionItem(transaction);
              },
            ),
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
                  color: Colors.black.withAlpha((255 * 0.1).round()), // Replaced withOpacity
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
                    color: isBuy ? Colors.green.withAlpha((255 * 0.2).round()) : Colors.red.withAlpha((255 * 0.2).round()),
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
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
                _buildActionButtons(transaction),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildActionButtons(Transaction transaction) {
    return Consumer<UserDataProvider>(
      builder: (context, userDataProvider, child) {
        try {
          final song = userDataProvider.allSongs
              .firstWhere((s) => s.id == transaction.songId);
          
          final isBuy = transaction.type == TransactionType.buy;
          final currentPrice = song.currentPrice;
          final priceChange = (currentPrice - transaction.price) / transaction.price * 100;
          
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Show the current price change from transaction price
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                decoration: BoxDecoration(
                  color: priceChange >= 0 
                      ? Colors.green.withAlpha((255 * 0.1).round()) 
                      : Colors.red.withAlpha((255 * 0.1).round()),
                  borderRadius: BorderRadius.circular(4.0),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      priceChange >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                      size: 12.0,
                      color: priceChange >= 0 ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 2.0),
                    Text(
                      '${priceChange.abs().toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 12.0,
                        color: priceChange >= 0 ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8.0),
              // If price has changed, show appropriate action button
              if (isBuy && priceChange > 0)
                InkWell(
                  onTap: () => _showSellDialog(context, transaction, userDataProvider, currentPrice),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                    decoration: BoxDecoration(
                      color: Colors.green.withAlpha((255 * 0.2).round()),
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.sell, size: 14.0, color: Colors.green),
                        SizedBox(width: 2.0),
                        Text(
                          'SELL',
                          style: TextStyle(
                            fontSize: 12.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else if (isBuy && priceChange < 0)
                InkWell(
                  onTap: () => _showBuyDialog(context, transaction, userDataProvider, currentPrice),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                    decoration: BoxDecoration(
                      color: Colors.green.withAlpha((255 * 0.2).round()),
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_shopping_cart, size: 14.0, color: Colors.green),
                        SizedBox(width: 2.0),
                        Text(
                          'BUY',
                          style: TextStyle(
                            fontSize: 12.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else if (!isBuy && priceChange < 0)
                InkWell(
                  onTap: () => _showBuyDialog(context, transaction, userDataProvider, currentPrice),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                    decoration: BoxDecoration(
                      color: Colors.green.withAlpha((255 * 0.2).round()),
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_shopping_cart, size: 14.0, color: Colors.green),
                        SizedBox(width: 2.0),
                        Text(
                          'BUY',
                          style: TextStyle(
                            fontSize: 12.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        } catch (e) {
          // If song is not found, or there's any other error, return an empty widget
          return const SizedBox.shrink();
        }
      },
    );
  }
  
  Future<void> _showSellDialog(
    BuildContext context, 
    Transaction transaction, 
    UserDataProvider userDataProvider,
    double currentPrice
  ) async {
    final TextEditingController quantityController = TextEditingController(text: '1');
    final maxQuantity = userDataProvider.getQuantityOwned(transaction.songId);
    
    if (maxQuantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You don\'t own any shares of this song to sell')),
      );
      return;
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Sell ${transaction.songName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current Price: \$${currentPrice.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8.0),
            Text('Quantity Owned: $maxQuantity'),
            const SizedBox(height: 16.0),
            TextField(
              controller: quantityController,
              decoration: const InputDecoration(
                labelText: 'Quantity to Sell',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8.0),
            Text(
              'Max you can sell: $maxQuantity',
              style: TextStyle(
                fontSize: 12.0,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16.0),
            StatefulBuilder(
              builder: (context, setState) {
                final quantity = int.tryParse(quantityController.text) ?? 0;
                final totalProceeds = quantity * currentPrice;
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Proceeds: \$${totalProceeds.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final quantity = int.tryParse(quantityController.text) ?? 0;
              
              if (quantity <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid quantity')),
                );
                return;
              }
              
              if (quantity > maxQuantity) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('You don\'t own that many shares')),
                );
                return;
              }
              
              Navigator.pop(context);
              
              final success = await userDataProvider.sellSong(transaction.songId, quantity);
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Successfully sold $quantity shares of ${transaction.songName}')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Failed to complete sale')),
                );
              }
            },
            child: const Text('Sell'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _showBuyDialog(
    BuildContext context, 
    Transaction transaction, 
    UserDataProvider userDataProvider,
    double currentPrice
  ) async {
    final TextEditingController quantityController = TextEditingController(text: '1');
    final maxQuantity = (userDataProvider.userProfile!.cashBalance / currentPrice).floor();
    
    if (maxQuantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You don\'t have enough cash to buy this song')),
      );
      return;
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Buy ${transaction.songName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current Price: \$${currentPrice.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8.0),
            Text(
              'Available Cash: \$${userDataProvider.userProfile!.cashBalance.toStringAsFixed(2)}',
            ),
            const SizedBox(height: 16.0),
            TextField(
              controller: quantityController,
              decoration: const InputDecoration(
                labelText: 'Quantity to Buy',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8.0),
            Text(
              'Max you can buy: $maxQuantity',
              style: TextStyle(
                fontSize: 12.0,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16.0),
            StatefulBuilder(
              builder: (context, setState) {
                final quantity = int.tryParse(quantityController.text) ?? 0;
                final totalCost = quantity * currentPrice;
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Cost: \$${totalCost.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Remaining Cash: \$${(userDataProvider.userProfile!.cashBalance - totalCost).toStringAsFixed(2)}',
                    ),
                  ],
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final quantity = int.tryParse(quantityController.text) ?? 0;
              
              if (quantity <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid quantity')),
                );
                return;
              }
              
              if (quantity > maxQuantity) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Not enough cash for this purchase')),
                );
                return;
              }
              
              Navigator.pop(context);
              
              final success = await userDataProvider.buySong(transaction.songId, quantity);
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Successfully bought $quantity shares of ${transaction.songName}')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Failed to complete purchase')),
                );
              }
            },
            child: const Text('Buy'),
          ),
        ],
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
