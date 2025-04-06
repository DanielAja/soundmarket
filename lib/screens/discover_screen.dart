import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_data_provider.dart';
import '../models/song.dart';
import '../services/song_service.dart';
import '../services/music_data_api_service.dart';
import '../screens/top_songs_list_screen.dart';
import '../screens/search_results_screen.dart';
import '../shared/widgets/search_bar_with_suggestions.dart';

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
  void initState() {
    super.initState();
    // Initialize the MusicDataApiService
    _musicDataApi = MusicDataApiService();
    
    // Set discover tab as active to enable price updates
    _musicDataApi.setDiscoverTabActive(true);
    
    // Start a timer to refresh the UI every second to show real-time price changes
    Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          // This will trigger a rebuild to show updated prices
        });
      }
    });
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
          // Show loading indicator when refreshing data
          if (userDataProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          
          final topSongs = userDataProvider.getTopSongs(limit: 50);
          final topMovers = userDataProvider.getTopMovers(limit: 50);
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
        if (value.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SearchResultsScreen(
                initialQuery: value,
              ),
            ),
          );
        }
      },
    );
  }

  Widget _buildTopSongsSection(BuildContext context, List<Song> songs, UserDataProvider userDataProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Top Songs',
              style: TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TopSongsListScreen(
                      listType: ListType.topSongs,
                      title: 'Top 100 Songs',
                    ),
                  ),
                );
              },
              child: const Text('View Top 100'),
            ),
          ],
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Top Movers',
              style: TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TopSongsListScreen(
                      listType: ListType.topMovers,
                      title: 'Top 100 Movers',
                    ),
                  ),
                );
              },
              child: const Text('View Top 100'),
            ),
          ],
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
          height: 120.0,
          child: artists.isEmpty
              ? Center(
                  child: Text(
                    'No rising artists found',
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                )
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: artists.length,
                  itemBuilder: (context, index) {
                    final artist = artists[index];
                    return Card(
                      margin: const EdgeInsets.only(right: 12.0),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              radius: 30.0,
                              backgroundColor: Colors.grey[800],
                              child: Text(
                                artist.substring(0, 1).toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 24.0,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8.0),
                            Text(
                              artist,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
  
  Widget _buildSongCard(BuildContext context, Song song, UserDataProvider userDataProvider, {bool showPriceChange = false}) {
    // Get the animation controller and animation for this song if available
    final hasAnimation = _priceAnimationControllers.containsKey(song.id) && 
                         _priceAnimations.containsKey(song.id);
    
    // Calculate price change percentage
    final priceChangePercent = song.previousPrice > 0 
        ? ((song.currentPrice - song.previousPrice) / song.previousPrice) * 100
        : 0.0;
    
    // Determine color based on price change
    final priceChangeColor = priceChangePercent > 0 
        ? Colors.green 
        : priceChangePercent < 0 
            ? Colors.red 
            : Colors.grey;
    
    return Card(
      margin: const EdgeInsets.only(right: 16.0),
      child: Container(
        width: 160.0,
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Album art placeholder
            Container(
              height: 100.0,
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(4.0),
              ),
              child: Center(
                child: Icon(
                  Icons.music_note,
                  size: 40.0,
                  color: Colors.grey[600],
                ),
              ),
            ),
            const SizedBox(height: 8.0),
            // Song title
            Text(
              song.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14.0,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            // Artist name
            Text(
              song.artist,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 12.0,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8.0),
            // Price with animation if available
            hasAnimation
                ? AnimatedBuilder(
                    animation: _priceAnimations[song.id]!,
                    builder: (context, child) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '\$${_priceAnimations[song.id]!.value.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16.0,
                            ),
                          ),
                          if (showPriceChange && song.previousPrice > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6.0,
                                vertical: 2.0,
                              ),
                              decoration: BoxDecoration(
                                color: priceChangeColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4.0),
                              ),
                              child: Text(
                                '${priceChangePercent >= 0 ? '+' : ''}${priceChangePercent.toStringAsFixed(1)}%',
                                style: TextStyle(
                                  color: priceChangeColor,
                                  fontSize: 12.0,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '\$${song.currentPrice.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16.0,
                        ),
                      ),
                      if (showPriceChange && song.previousPrice > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6.0,
                            vertical: 2.0,
                          ),
                          decoration: BoxDecoration(
                            color: priceChangeColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                          child: Text(
                            '${priceChangePercent >= 0 ? '+' : ''}${priceChangePercent.toStringAsFixed(1)}%',
                            style: TextStyle(
                              color: priceChangeColor,
                              fontSize: 12.0,
                              fontWeight: FontWeight.bold,
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
}
