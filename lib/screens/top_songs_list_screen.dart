import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/song.dart';
import '../providers/user_data_provider.dart';

enum ListType {
  topSongs,
  topMovers,
  byGenre,
}

class TopSongsListScreen extends StatelessWidget {
  final ListType listType;
  final String? genre;
  final String title;

  const TopSongsListScreen({
    super.key,
    required this.listType,
    this.genre,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Consumer<UserDataProvider>(
        builder: (context, userDataProvider, child) {
          List<Song> songs = [];
          
          switch (listType) {
            case ListType.topSongs:
              songs = userDataProvider.getTopSongs(limit: 100);
              break;
            case ListType.topMovers:
              songs = userDataProvider.getTopMovers(limit: 100);
              break;
            case ListType.byGenre:
              if (genre != null) {
                songs = userDataProvider.getSongsByGenre(genre!);
              }
              break;
          }
          
          if (songs.isEmpty) {
            return Center(
              child: Text(
                'No songs found',
                style: TextStyle(color: Colors.grey[600]),
              ),
            );
          }
          
          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: songs.length,
            itemBuilder: (context, index) {
              final song = songs[index];
              final isOwned = userDataProvider.ownsSong(song.id);
              
              return Card(
                margin: const EdgeInsets.only(bottom: 12.0),
                child: ListTile(
                  leading: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.grey[700],
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                    child: song.albumArtUrl != null
                        ? Image.network(
                            song.albumArtUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(Icons.music_note);
                            },
                          )
                        : const Icon(Icons.music_note),
                  ),
                  title: Text(
                    song.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(song.artist),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '\$${song.currentPrice.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            song.isPriceUp ? Icons.arrow_upward : Icons.arrow_downward,
                            size: 12.0,
                            color: song.isPriceUp ? Colors.green : Colors.red,
                          ),
                          Text(
                            '${song.priceChangePercent.abs().toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 12.0,
                              color: song.isPriceUp ? Colors.green : Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  onTap: () {
                    _showSongActions(context, song, userDataProvider);
                  },
                ),
              );
            },
          );
        },
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
