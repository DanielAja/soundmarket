import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// Removed unused import for portfolio_item.dart - Removing again
// Removed unused import for song.dart
import '../../../shared/providers/user_data_provider.dart'; // Corrected path
// Removed unused import for transaction_history_screen.dart
import '../../../core/navigation/route_constants.dart'; // Corrected path
import '../../../core/theme/app_spacing.dart'; // Corrected path

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/icon/app_icon.png',
              width: 28,
              height: 28,
            ),
            const SizedBox(width: 8),
            const Text('Sound Market'),
          ],
        ),
      ),
      body: Consumer<UserDataProvider>(
        builder: (context, userDataProvider, child) {
          // Show loading indicator when refreshing data
          if (userDataProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final userProfile = userDataProvider.userProfile;
          
          if (userProfile == null) {
            return const Center(child: CircularProgressIndicator());
          }
          
          return RefreshIndicator(
            onRefresh: () => userDataProvider.refreshData(),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.l), // Use AppSpacing.l
              children: [
                _buildProfileHeader(context, userProfile.displayName ?? 'User'),
                const SizedBox(height: AppSpacing.xl), // Use AppSpacing.xl
                _buildBalanceCard(context, userDataProvider),
                const SizedBox(height: AppSpacing.xl), // Use AppSpacing.xl
                _buildStatisticsSection(context),
                const SizedBox(height: AppSpacing.xl), // Use AppSpacing.xl
                // Note: _buildPortfolioSection is not currently used in the main ListView
                _buildActionButtons(context, userDataProvider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, String displayName) {
    return Column(
      children: [
        CircleAvatar(
          radius: 50.0,
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: const Icon(
            Icons.person,
            size: 50.0,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: AppSpacing.l), // Use AppSpacing.l
        Text(
          displayName,
          style: const TextStyle(
            fontSize: 24.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.s), // Use AppSpacing.s
        Text(
          'Member since April 2025',
          style: TextStyle(
            color: Colors.grey[400],
          ),
        ),
      ],
    );
  }

  Widget _buildBalanceCard(BuildContext context, UserDataProvider userDataProvider) {
    return Card(
      elevation: 4.0,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.l), // Use AppSpacing.l
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your Balance',
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
                    Text(
                      'Cash',
                      style: TextStyle(
                        color: Colors.grey[400],
                      ),
                    ),
                    Text(
                      '\$${userDataProvider.userProfile?.cashBalance.toStringAsFixed(2) ?? '0.00'}',
                      style: const TextStyle(
                        fontSize: 20.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
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
                      '\$${userDataProvider.totalPortfolioValue.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 20.0,
                        fontWeight: FontWeight.bold,
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
                Text(
                  '\$${userDataProvider.totalBalance.toStringAsFixed(2)}',
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

  Widget _buildStatisticsSection(BuildContext context) {
    return Consumer<UserDataProvider>(
      builder: (context, userDataProvider, child) {
        // Calculate statistics
        final songsOwned = userDataProvider.portfolio.length;
        
        // Calculate unique artists backed
        final artistsBacked = userDataProvider.portfolio
            .map((item) => item.artistName)
            .toSet()
            .length;
        
        // Calculate return percentage
        double returnPercentage = 0.0;
        if (userDataProvider.getTotalSpent() > 0) {
          final totalSpent = userDataProvider.getTotalSpent();
          final currentValue = userDataProvider.totalPortfolioValue;
          returnPercentage = ((currentValue / totalSpent) - 1) * 100;
        }
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your Statistics',
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.l), // Use AppSpacing.l
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(context, songsOwned.toString(), 'Songs Owned'),
                _buildStatItem(context, artistsBacked.toString(), 'Artists Backed'),
                _buildStatItem(
                  context, 
                  '${returnPercentage.toStringAsFixed(1)}%', 
                  'Return',
                  color: returnPercentage >= 0 ? Colors.green : Colors.red,
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatItem(
    BuildContext context, 
    String value, 
    String label, 
    {Color? color}
  ) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
            color: color ?? Theme.of(context).colorScheme.primary,
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

  // Removed unused method: _buildPortfolioSection
  /* // Commenting out the entire unused method
  Widget _buildPortfolioSection(BuildContext context, UserDataProvider userDataProvider) { 
    final portfolio = userDataProvider.portfolio;
    
    if (portfolio.isEmpty) {
      return Card(
        elevation: 2.0,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.l), // Use AppSpacing.l
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
              const SizedBox(height: AppSpacing.l), // Use AppSpacing.l
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.music_note,
                      size: 48.0,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: AppSpacing.s), // Use AppSpacing.s
                    Text(
                      'No songs in your portfolio yet',
                      style: TextStyle(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.l), // Use AppSpacing.l
                    ElevatedButton(
                      onPressed: () {
                        // Navigate to discover screen to buy songs
                        Navigator.pushNamed(context, RouteConstants.discover);
                      },
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
      elevation: 2.0,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.l), // Use AppSpacing.l
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
            const SizedBox(height: AppSpacing.s), // Use AppSpacing.s
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Songs',
                  style: TextStyle(
                    fontSize: 14.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, RouteConstants.portfolioDetails);
                  },
                  child: const Text('View Full Portfolio'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s), // Use AppSpacing.s
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: portfolio.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final item = portfolio[index];
                // Find the song in the list or use null
                Song? song;
                try {
                  song = userDataProvider.allSongs.firstWhere(
                    (s) => s.id == item.songId,
                  );
                } catch (e) {
                  song = null;
                }
                
                final currentPrice = song?.currentPrice ?? item.purchasePrice;
                final priceChange = song != null 
                    ? song.priceChangePercent 
                    : 0.0;
                
                final profitLoss = item.getProfitLoss(currentPrice);
                // Removed unused variable: final profitLossPercent = (profitLoss / item.totalPurchaseValue) * 100; // Unused
                
                return Column(
                  children: [
                    Row(
                      children: [
                        // Album art or placeholder
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(AppSpacing.xs), // Use AppSpacing.xs
                          ),
                          child: item.albumArtUrl != null
                              ? Image.network(
                                  item.albumArtUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(Icons.music_note);
                                  },
                                )
                              : const Icon(Icons.music_note),
                        ),
                        const SizedBox(width: AppSpacing.m), // Use AppSpacing.m
                        // Song details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.songName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                item.artistName,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12.0,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs), // Use AppSpacing.xs
                              Row(
                                children: [
                                  Text(
                                    'Qty: ${item.quantity}',
                                    style: const TextStyle(fontSize: 12.0),
                                  ),
                                  const SizedBox(width: AppSpacing.s), // Use AppSpacing.s
                                  Text(
                                    'Avg: \$${item.purchasePrice.toStringAsFixed(2)}',
                                    style: const TextStyle(fontSize: 12.0),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Price and profit/loss
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '\$${currentPrice.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Row(
                              children: [
                                Icon(
                                  priceChange >= 0
                                      ? Icons.arrow_upward
                                      : Icons.arrow_downward,
                                  size: 12.0,
                                  color: priceChange >= 0
                                      ? Colors.green
                                      : Colors.red,
                                ),
                                Text(
                                  '${priceChange.abs().toStringAsFixed(1)}%',
                                  style: TextStyle(
                                    fontSize: 12.0,
                                    color: priceChange >= 0
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.xs), // Use AppSpacing.xs
                            Text(
                              profitLoss >= 0
                                  ? '+\$${profitLoss.toStringAsFixed(2)}'
                                  : '-\$${profitLoss.abs().toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 12.0,
                                color: profitLoss >= 0
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.s), // Use AppSpacing.s
                    // Buy/Sell buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: () => _showBuySellDialog(
                            context,
                            item,
                            userDataProvider,
                            isBuy: true,
                            currentPrice: currentPrice,
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.green,
                            side: const BorderSide(color: Colors.green),
                            minimumSize: const Size(80, 36),
                          ),
                          child: const Text('Buy'),
                        ),
                        const SizedBox(width: AppSpacing.s), // Use AppSpacing.s
                        OutlinedButton(
                          onPressed: () => _showBuySellDialog(
                            context,
                            item,
                            userDataProvider,
                            isBuy: false,
                            currentPrice: currentPrice,
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            minimumSize: const Size(80, 36),
                          ),
                          child: const Text('Sell'),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
  */ // End of commented out unused method

  /* // Commenting out unused method _showBuySellDialog
  void _showBuySellDialog(
    BuildContext context,
    PortfolioItem item,
    UserDataProvider userDataProvider,
    {required bool isBuy, required double currentPrice}
  ) {
    final TextEditingController quantityController = TextEditingController(text: '1');
    final maxQuantity = isBuy 
        ? (userDataProvider.userProfile!.cashBalance / currentPrice).floor()
        : item.quantity;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isBuy ? 'Buy ${item.songName}' : 'Sell ${item.songName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current Price: \$${currentPrice.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.s), // Use AppSpacing.s
            if (isBuy)
              Text(
                'Available Cash: \$${userDataProvider.userProfile!.cashBalance.toStringAsFixed(2)}',
              )
            else
              Text('Quantity Owned: ${item.quantity}'),
            const SizedBox(height: AppSpacing.l), // Use AppSpacing.l
            TextField(
              controller: quantityController,
              decoration: const InputDecoration(
                labelText: 'Quantity',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: AppSpacing.s), // Use AppSpacing.s
            Text(
              isBuy
                  ? 'Max you can buy: $maxQuantity'
                  : 'Max you can sell: $maxQuantity',
              style: TextStyle(
                fontSize: 12.0,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: AppSpacing.l), // Use AppSpacing.l
            StatefulBuilder(
              builder: (context, setState) {
                final quantity = int.tryParse(quantityController.text) ?? 0;
                final totalCost = quantity * currentPrice;
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total ${isBuy ? 'Cost' : 'Proceeds'}: \$${totalCost.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    if (isBuy)
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
              
              if (isBuy && quantity > maxQuantity) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Not enough cash for this purchase')),
                );
                return;
              }
              
              if (!isBuy && quantity > maxQuantity) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('You don\'t own that many shares')),
                );
                return;
              }
              
              Navigator.pop(context);
              
              bool success;
              if (isBuy) {
                success = await userDataProvider.buySong(item.songId, quantity);
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Successfully bought $quantity shares of ${item.songName}')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to complete purchase')),
                  );
                }
              } else {
                success = await userDataProvider.sellSong(item.songId, quantity);
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Successfully sold $quantity shares of ${item.songName}')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to complete sale')),
                  );
                }
              }
            },
            child: Text(isBuy ? 'Buy' : 'Sell'),
          ),
        ],
      ),
    );
  }
  */ // End of commented out unused method

  // Show dialog to add funds
  Future<void> _showAddFundsDialog(BuildContext context, UserDataProvider userDataProvider) async {
    final virtualAmount = 100.0; // Amount of virtual dollars to add
    final realAmount = 0.99; // Amount in real dollars

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Funds'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add \$${virtualAmount.toStringAsFixed(2)} to your account',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16.0,
              ),
            ),
            const SizedBox(height: 16.0),
            const Text(
              'Add funds to your account to invest in more songs and expand your portfolio.',
              style: TextStyle(fontSize: 14.0),
            ),
            const SizedBox(height: 16.0),
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16.0,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8.0),
                const Expanded(
                  child: Text(
                    'Payment is processed securely through our payment provider.',
                    style: TextStyle(
                      fontSize: 12.0,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              
              // Show payment processing dialog
              _showLoadingDialog(context, 'Processing payment...');
              
              // Simulate payment processing delay
              await Future.delayed(const Duration(seconds: 1));
              
              // Close loading dialog
              Navigator.pop(context);
              
              // Add funds to user account
              final success = await userDataProvider.addFunds(virtualAmount);
              
              if (success) {
                // Show success message
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('\$${virtualAmount.toStringAsFixed(2)} added to your account'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } else {
                // Show error message
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to add funds. Please try again.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
            child: Text('\$${realAmount.toStringAsFixed(2)}'),
          ),
        ],
      ),
    );
  }
  
  // Show loading dialog while processing payment
  void _showLoadingDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16.0),
            Text(message),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, UserDataProvider userDataProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Actions',
          style: TextStyle(
            fontSize: 18.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.l), // Use AppSpacing.l
        ListTile(
          leading: const Icon(Icons.add_circle_outline),
          title: const Text('Add Funds'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            _showAddFundsDialog(context, userDataProvider);
          },
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.history),
          title: const Text('Transaction History'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            // Navigate to transaction history screen
            Navigator.pushNamed(context, RouteConstants.transactions);
          },
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.refresh),
          title: const Text('Reset Demo Data'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            // Show confirmation dialog before resetting
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Reset Demo Data'),
                content: const Text('Are you sure you want to reset all demo data? This action cannot be undone.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () {
                      // Reset user data for demo purposes
                      userDataProvider.resetData();
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Demo data has been reset')),
                      );
                    },
                    child: const Text('Reset'),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
