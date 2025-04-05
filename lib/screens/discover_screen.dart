import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_data_provider.dart';
import '../models/song.dart';

class DiscoverScreen extends StatelessWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // Filter functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Filters coming soon!')),
              );
            },
          ),
        ],
      ),
      body: Consumer<UserDataProvider>(
        builder: (context, userDataProvider, child) {
          final topSongs = userDataProvider.topSongs;
          final topMovers = userDataProvider.topMovers;
          final risingArtists = userDataProvider.risingArtists;
          
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
                _buildSearchBar(),
                const SizedBox(height: 16.0),
                _buildTopSongsSection(context, topSongs, userDataProvider),
                const SizedBox(height: 24.0),
                _buildTopMoversSection(context, topMovers, userDataProvider),
                const SizedBox(height: 24.0),
                _buildRisingArtistsSection(context, risingArtists),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      decoration: InputDecoration(
        hintText: 'Search for artists, songs...',
        prefixIcon: const Icon(Icons.search),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30.0),
        ),
        filled: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 4.0),
      ),
      onSubmitted: (value) {
        // Search functionality would be implemented here
      },
    );
  }

  Widget _buildTopSongsSection(BuildContext context, List<Song> songs, UserDataProvider userDataProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Top Songs',
          style: TextStyle(
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12.0),
        SizedBox(
          height: 220.0,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: songs.length,
            itemBuilder: (context, index) {
              final song = songs[index];
              return _buildSongCard(context, song, userDataProvider);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTopMoversSection(BuildContext context, List<Song> songs, UserDataProvider userDataProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Top Movers',
          style: TextStyle(
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12.0),
        SizedBox(
          height: 220.0,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: songs.length,
            itemBuilder: (context, index) {
              final song = songs[index];
              return _buildSongCard(context, song, userDataProvider, showPriceChange: true);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRisingArtistsSection(BuildContext context, List<String> artists) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Artists on the Rise',
          style: TextStyle(
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12.0),
        SizedBox(
          height: 180.0,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: artists.length,
            itemBuilder: (context, index) {
              final artist = artists[index];
              return _buildArtistCard(context, artist, index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSongCard(BuildContext context, Song song, UserDataProvider userDataProvider, {bool showPriceChange = false}) {
    final isOwned = userDataProvider.ownsSong(song.id);
    final priceChangePercent = song.priceChangePercent;
    final isPriceUp = song.isPriceUp;
    
    return GestureDetector(
      onTap: () {
        _showSongActions(context, song, userDataProvider);
      },
      child: Container(
        width: 160.0,
        margin: const EdgeInsets.only(right: 12.0),
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8.0),
                    topRight: Radius.circular(8.0),
                  ),
                  child: song.albumArtUrl != null
                      ? Image.network(
                          song.albumArtUrl!,
                          height: 120.0,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 120.0,
                              color: Colors.grey[700],
                              child: Center(
                                child: Icon(
                                  Icons.music_note,
                                  size: 40.0,
                                  color: Colors.grey[500],
                                ),
                              ),
                            );
                          },
                        )
                      : Container(
                          height: 120.0,
                          color: Colors.grey[700],
                          child: Center(
                            child: Icon(
                              Icons.music_note,
                              size: 40.0,
                              color: Colors.grey[500],
                            ),
                          ),
                        ),
                ),
                if (isOwned)
                  Positioned(
                    top: 8.0,
                    right: 8.0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                      child: const Text(
                        'Owned',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 10.0,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    song.artist,
                    style: TextStyle(
                      fontSize: 12.0,
                      color: Colors.grey[400],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '\$${song.currentPrice.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (showPriceChange)
                        Row(
                          children: [
                            Icon(
                              isPriceUp ? Icons.arrow_upward : Icons.arrow_downward,
                              color: isPriceUp ? Colors.green : Colors.red,
                              size: 12.0,
                            ),
                            const SizedBox(width: 2.0),
                            Text(
                              '${priceChangePercent.toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontSize: 12.0,
                                color: isPriceUp ? Colors.green : Colors.red,
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
          ],
        ),
      ),
    );
  }

  Widget _buildArtistCard(BuildContext context, String artist, int index) {
    // Use a different color for each artist card
    final colors = [
      Colors.purple[700],
      Colors.blue[700],
      Colors.teal[700],
      Colors.amber[700],
      Colors.deepOrange[700],
    ];
    final color = colors[index % colors.length];
    
    return Container(
      width: 150.0,
      margin: const EdgeInsets.only(right: 12.0),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8.0),
              topRight: Radius.circular(8.0),
            ),
            child: Container(
              height: 120.0,
              color: color,
              child: Center(
                child: Text(
                  artist.substring(0, 1),
                  style: const TextStyle(
                    fontSize: 48.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  artist,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4.0),
                Row(
                  children: [
                    const Icon(
                      Icons.trending_up,
                      color: Colors.green,
                      size: 16.0,
                    ),
                    const SizedBox(width: 4.0),
                    Text(
                      'Rising Star',
                      style: TextStyle(
                        fontSize: 12.0,
                        color: Colors.grey[400],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
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
                        Row(
                          children: [
                            Text(
                              'Current Price: \$${song.currentPrice.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8.0),
                            Icon(
                              song.isPriceUp ? Icons.arrow_upward : Icons.arrow_downward,
                              color: song.isPriceUp ? Colors.green : Colors.red,
                              size: 14.0,
                            ),
                            Text(
                              '${song.priceChangePercent.toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontSize: 12.0,
                                color: song.isPriceUp ? Colors.green : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16.0),
              const Text(
                'Song Details',
                style: TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8.0),
              Text('Genre: ${song.genre}'),
              const SizedBox(height: 4.0),
              Text('Previous Price: \$${song.previousPrice.toStringAsFixed(2)}'),
              const SizedBox(height: 16.0),
              if (ownedQuantity > 0)
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
                      child: Text(ownedQuantity > 0 ? 'Buy More' : 'Buy'),
                    ),
                  ),
                  if (ownedQuantity > 0) ...[
                    const SizedBox(width: 16.0),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _showSellSongDialog(context, song, userDataProvider, ownedQuantity);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        child: const Text('Sell'),
                      ),
                    ),
                  ],
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
