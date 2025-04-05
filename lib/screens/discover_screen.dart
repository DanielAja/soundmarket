import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_data_provider.dart';
import '../models/song.dart';
import '../services/song_service.dart';
import '../services/music_data_api_service.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> with TickerProviderStateMixin {
  // Map to store the previous prices for comparison
  final Map<String, double> _previousPrices = {};
  
  // Map to store animation controllers for each song
  final Map<String, AnimationController> _priceAnimationControllers = {};
  
  // Map to store animations for each song
  final Map<String, Animation<double>> _priceAnimations = {};
  
  // Reference to the MusicDataApiService
  late final MusicDataApiService _musicDataApi;

  // Selected genre for filtering
  String? _selectedGenre;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              _showGenreFilterDialog(context);
            },
          ),
        ],
      ),
      body: Consumer<UserDataProvider>(
        builder: (context, userDataProvider, child) {
          final topSongs = userDataProvider.topSongs;
          final topMovers = userDataProvider.topMovers;
          final risingArtists = userDataProvider.risingArtists;
          
          // Get songs by genre if a genre is selected
          final genreSongs = _selectedGenre != null 
              ? userDataProvider.getSongsByGenre(_selectedGenre!)
              : <Song>[];
          
          // Initialize previous prices for new songs
          for (final song in [...topSongs, ...topMovers, ...genreSongs]) {
            if (!_previousPrices.containsKey(song.id)) {
              _previousPrices[song.id] = song.currentPrice;
            }
          }
          
          return RefreshIndicator(
            onRefresh: () async {
              // Simulate a refresh by triggering price updates
              // In a real app, this would fetch new data from the API
              final random = Random();
              for (final song in [...topSongs, ...topMovers, ...genreSongs]) {
                // Only update some songs to simulate market changes
                if (random.nextBool()) {
                  final oldPrice = song.currentPrice;
                  // Simulate a price change (±5%)
                  final change = oldPrice * (0.05 * (random.nextDouble() * 2 - 1));
                  final newPrice = max(0.01, oldPrice + change);
                  
                  // Update the song price
                  song.previousPrice = oldPrice;
                  song.currentPrice = double.parse(newPrice.toStringAsFixed(2));
                  
                  // Trigger animation if the price changed
                  if (_previousPrices.containsKey(song.id) && _previousPrices[song.id] != song.currentPrice) {
                    _initOrUpdatePriceAnimation(song.id, _previousPrices[song.id]!, song.currentPrice);
                    _previousPrices[song.id] = song.currentPrice;
                  }
                }
              }
              
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
                if (_selectedGenre != null) ...[
                  const SizedBox(height: 24.0),
                  _buildGenreSongsSection(context, genreSongs, userDataProvider),
                ],
                const SizedBox(height: 24.0),
                _buildBrowseByGenreSection(context, userDataProvider),
              ],
            ),
          );
        },
      ),
    );
  }
  
  void _showGenreFilterDialog(BuildContext context) {
    final userDataProvider = Provider.of<UserDataProvider>(context, listen: false);
    final genres = userDataProvider.allGenres;
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Filter by Genre'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: [
                ListTile(
                  title: const Text('All Genres'),
                  selected: _selectedGenre == null,
                  onTap: () {
                    setState(() {
                      _selectedGenre = null;
                    });
                    Navigator.pop(context);
                  },
                ),
                ...genres.map((genre) => ListTile(
                  title: Text(genre),
                  selected: _selectedGenre == genre,
                  onTap: () {
                    setState(() {
                      _selectedGenre = genre;
                    });
                    Navigator.pop(context);
                  },
                )),
              ],
            ),
          ),
        );
      },
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

  Widget _buildGenreSongsSection(BuildContext context, List<Song> songs, UserDataProvider userDataProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Songs in $_selectedGenre',
          style: const TextStyle(
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12.0),
        SizedBox(
          height: 220.0,
          child: songs.isEmpty
              ? Center(
                  child: Text(
                    'No songs found in this genre',
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                )
              : ListView.builder(
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
  
  Widget _buildBrowseByGenreSection(BuildContext context, UserDataProvider userDataProvider) {
    final genres = userDataProvider.allGenres;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Browse by Genre',
          style: TextStyle(
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12.0),
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: genres.map((genre) {
            final isSelected = _selectedGenre == genre;
            return InkWell(
              onTap: () {
                setState(() {
                  _selectedGenre = isSelected ? null : genre;
                });
              },
              child: Chip(
                label: Text(genre),
                backgroundColor: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey[800],
                labelStyle: TextStyle(
                  color: isSelected ? Colors.black : Colors.white,
                ),
              ),
            );
          }).toList(),
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

  @override
  void initState() {
    super.initState();
    // Initialize the MusicDataApiService
    _musicDataApi = MusicDataApiService();
    
    // Set discover tab as active to enable price updates
    _musicDataApi.setDiscoverTabActive(true);
  }

  @override
  void dispose() {
    // Dispose all animation controllers
    for (final controller in _priceAnimationControllers.values) {
      controller.dispose();
    }
    
    // Set discover tab as inactive when leaving the screen
    _musicDataApi.setDiscoverTabActive(false);
        
    super.dispose();
  }

  // Initialize or update animation for a song
  void _initOrUpdatePriceAnimation(String songId, double oldPrice, double newPrice) {
    // If we don't have a controller for this song yet, create one
    if (!_priceAnimationControllers.containsKey(songId)) {
      _priceAnimationControllers[songId] = AnimationController(
        duration: const Duration(milliseconds: 500),
        vsync: this,
      );
      
      _priceAnimations[songId] = Tween<double>(
        begin: oldPrice,
        end: newPrice,
      ).animate(CurvedAnimation(
        parent: _priceAnimationControllers[songId]!,
        curve: Curves.easeInOut,
      ));
    } else {
      // Update the existing animation
      _priceAnimations[songId] = Tween<double>(
        begin: oldPrice,
        end: newPrice,
      ).animate(CurvedAnimation(
        parent: _priceAnimationControllers[songId]!,
        curve: Curves.easeInOut,
      ));
      
      // Reset and start the animation
      _priceAnimationControllers[songId]!.reset();
    }
    
    // Start the animation
    _priceAnimationControllers[songId]!.forward();
  }

  Widget _buildSongCard(BuildContext context, Song song, UserDataProvider userDataProvider, {bool showPriceChange = false}) {
    final isOwned = userDataProvider.ownsSong(song.id);
    final priceChangePercent = song.priceChangePercent;
    final isPriceUp = song.isPriceUp;
    
    // Check if price has changed
    if (_previousPrices.containsKey(song.id) && _previousPrices[song.id] != song.currentPrice) {
      _initOrUpdatePriceAnimation(song.id, _previousPrices[song.id]!, song.currentPrice);
    }
    
    // Store current price for next comparison
    _previousPrices[song.id] = song.currentPrice;
    
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
                      // Animated price display
                      _priceAnimationControllers.containsKey(song.id) && _priceAnimationControllers[song.id]!.isAnimating
                          ? AnimatedBuilder(
                              animation: _priceAnimationControllers[song.id]!,
                              builder: (context, child) {
                                final animatedPrice = _priceAnimations[song.id]!.value;
                                final color = _previousPrices[song.id]! < song.currentPrice
                                    ? Colors.green
                                    : _previousPrices[song.id]! > song.currentPrice
                                        ? Colors.red
                                        : null;
                                
                                return Text(
                                  '\$${animatedPrice.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: color,
                                  ),
                                );
                              },
                            )
                          : Text(
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
                            // Animated price display in modal
                            _priceAnimationControllers.containsKey(song.id) && _priceAnimationControllers[song.id]!.isAnimating
                                ? AnimatedBuilder(
                                    animation: _priceAnimationControllers[song.id]!,
                                    builder: (context, child) {
                                      final animatedPrice = _priceAnimations[song.id]!.value;
                                      final color = _previousPrices[song.id]! < song.currentPrice
                                          ? Colors.green
                                          : _previousPrices[song.id]! > song.currentPrice
                                              ? Colors.red
                                              : null;
                                      
                                      return Text(
                                        'Current Price: \$${animatedPrice.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: color,
                                        ),
                                      );
                                    },
                                  )
                                : Text(
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
            // Calculate total cost with animated price if available
            final price = _priceAnimationControllers.containsKey(song.id) && 
                         _priceAnimationControllers[song.id]!.isAnimating ? 
                         _priceAnimations[song.id]!.value : song.currentPrice;
            final totalCost = price * quantity;
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
                  // Animated price display in buy dialog
                  _priceAnimationControllers.containsKey(song.id) && _priceAnimationControllers[song.id]!.isAnimating
                      ? AnimatedBuilder(
                          animation: _priceAnimationControllers[song.id]!,
                          builder: (context, child) {
                            final animatedPrice = _priceAnimations[song.id]!.value;
                            final color = _previousPrices[song.id]! < song.currentPrice
                                ? Colors.green
                                : _previousPrices[song.id]! > song.currentPrice
                                    ? Colors.red
                                    : null;
                            
                            return Text(
                              'Price per share: \$${animatedPrice.toStringAsFixed(2)}',
                              style: TextStyle(
                                color: color,
                              ),
                            );
                          },
                        )
                      : Text('Price per share: \$${song.currentPrice.toStringAsFixed(2)}'),
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
                  // Animated total cost
                  _priceAnimationControllers.containsKey(song.id) && _priceAnimationControllers[song.id]!.isAnimating
                      ? AnimatedBuilder(
                          animation: _priceAnimationControllers[song.id]!,
                          builder: (context, child) {
                            final animatedPrice = _priceAnimations[song.id]!.value;
                            final animatedTotalCost = animatedPrice * quantity;
                            final color = _previousPrices[song.id]! < song.currentPrice
                                ? Colors.green
                                : _previousPrices[song.id]! > song.currentPrice
                                    ? Colors.red
                                    : null;
                            
                            return Text(
                              'Total Cost: \$${animatedTotalCost.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            );
                          },
                        )
                      : Text(
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
            // Calculate total value with animated price if available
            final price = _priceAnimationControllers.containsKey(song.id) && 
                         _priceAnimationControllers[song.id]!.isAnimating ? 
                         _priceAnimations[song.id]!.value : song.currentPrice;
            final totalValue = price * quantity;
            
            return AlertDialog(
              backgroundColor: Colors.grey[900],
              title: const Text('Sell Song Shares'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Song: ${song.name} by ${song.artist}'),
                  const SizedBox(height: 8.0),
                  // Animated price display in sell dialog
                  _priceAnimationControllers.containsKey(song.id) && _priceAnimationControllers[song.id]!.isAnimating
                      ? AnimatedBuilder(
                          animation: _priceAnimationControllers[song.id]!,
                          builder: (context, child) {
                            final animatedPrice = _priceAnimations[song.id]!.value;
                            final color = _previousPrices[song.id]! < song.currentPrice
                                ? Colors.green
                                : _previousPrices[song.id]! > song.currentPrice
                                    ? Colors.red
                                    : null;
                            
                            return Text(
                              'Current price per share: \$${animatedPrice.toStringAsFixed(2)}',
                              style: TextStyle(
                                color: color,
                              ),
                            );
                          },
                        )
                      : Text('Current price per share: \$${song.currentPrice.toStringAsFixed(2)}'),
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
                  // Animated total value
                  _priceAnimationControllers.containsKey(song.id) && _priceAnimationControllers[song.id]!.isAnimating
                      ? AnimatedBuilder(
                          animation: _priceAnimationControllers[song.id]!,
                          builder: (context, child) {
                            final animatedPrice = _priceAnimations[song.id]!.value;
                            final animatedTotalValue = animatedPrice * quantity;
                            final color = _previousPrices[song.id]! < song.currentPrice
                                ? Colors.green
                                : _previousPrices[song.id]! > song.currentPrice
                                    ? Colors.red
                                    : null;
                            
                            return Text(
                              'Total Value: \$${animatedTotalValue.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            );
                          },
                        )
                      : Text(
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
