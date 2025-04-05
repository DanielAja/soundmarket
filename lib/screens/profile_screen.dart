import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_data_provider.dart';
import 'transaction_history_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // TODO: Navigate to settings screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Settings coming soon!')),
              );
            },
          ),
        ],
      ),
      body: Consumer<UserDataProvider>(
        builder: (context, userDataProvider, child) {
          final userProfile = userDataProvider.userProfile;
          
          if (userProfile == null) {
            return const Center(child: CircularProgressIndicator());
          }
          
          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              _buildProfileHeader(context, userProfile.displayName ?? 'User'),
              const SizedBox(height: 24.0),
              _buildBalanceCard(context, userDataProvider),
              const SizedBox(height: 24.0),
              _buildStatisticsSection(context),
              const SizedBox(height: 24.0),
              _buildActionButtons(context, userDataProvider),
            ],
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
        const SizedBox(height: 16.0),
        Text(
          displayName,
          style: const TextStyle(
            fontSize: 24.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8.0),
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
        padding: const EdgeInsets.all(16.0),
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
            const SizedBox(height: 16.0),
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
            const SizedBox(height: 16.0),
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
        const SizedBox(height: 16.0),
        ListTile(
          leading: const Icon(Icons.add_circle_outline),
          title: const Text('Add Funds'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            // TODO: Implement add funds functionality
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Add funds coming soon!')),
            );
          },
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.history),
          title: const Text('Transaction History'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            // Navigate to transaction history screen
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const TransactionHistoryScreen(),
              ),
            );
          },
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.refresh),
          title: const Text('Reset Demo Data'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            // Reset user data for demo purposes
            userDataProvider.resetData();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Demo data has been reset')),
            );
          },
        ),
      ],
    );
  }
}
