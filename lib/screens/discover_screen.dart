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
import '../core/theme/app_spacing.dart'; // Import AppSpacing

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> with TickerProviderStateMixin {
  final Map<String, double> _previousPrices = {};
  final Map<String, AnimationController> _priceAnimationControllers = {};
  final Map<String, Animation<double>> _priceAnimations = {};
  late final MusicDataApiService _musicDataApi;
  String? _selectedGenre;
  
  @override
  void initState() {
    super.initState();
    _musicDataApi = MusicDataApiService();
    _musicDataApi.setDiscoverTabActive(true);
    
    Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    for (final controller in _priceAnimationControllers.values) {
      controller.dispose();
    }
    _musicDataApi.setDiscoverTabActive(false);
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sound Market'),
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
          if (userDataProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          
          final topSongs = userDataProvider.getTopSongs(limit: 50);
          final topMovers = userDataProvider.getTopMovers(limit: 50);
          final risingArtists = userDataProvider.risingArtists;
          final genreSongs = _selectedGenre != null 
              ? userDataProvider.getSongsByGenre(_selectedGenre!)
              : <Song>[];
          
          for (final song in [...topSongs, ...topMovers, ...genreSongs]) {
            if (!_previousPrices.containsKey(song.id)) {
              _previousPrices[song.id] = song.currentPrice;
            }
          }
          
          return RefreshIndicator(
            onRefresh: () async {
              final random = Random();
              for (final song in [...topSongs, ...topMovers, ...genreSongs]) {
                if (random.nextBool()) {
                  final oldPrice = song.currentPrice;
                  final change = oldPrice * (0.05 * (random.nextDouble() * 2 - 1));
                  final newPrice = max(0.01, oldPrice + change);
                  
                  song.previousPrice = oldPrice;
                  song.currentPrice = double.parse(newPrice.toStringAsFixed(2));
                  
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
              padding: const EdgeInsets.all(AppSpacing.l), // Use AppSpacing.l
              children: [
                _buildSearchBar(),
                const SizedBox(height: AppSpacing.l), // Use AppSpacing.l
                _buildTopSongsSection(context, topSongs, userDataProvider),
                const SizedBox(height: AppSpacing.xl), // Use AppSpacing.xl
                _buildTopMoversSection(context, topMovers, userDataProvider),
                const SizedBox(height: AppSpacing.xl), // Use AppSpacing.xl
                _buildRisingArtistsSection(context, risingArtists),
                if (_selectedGenre != null) ...[
                  const SizedBox(height: AppSpacing.xl), // Use AppSpacing.xl
                  _buildGenreSongsSection(context, genreSongs, userDataProvider),
                ],
                const SizedBox(height: AppSpacing.xl), // Use AppSpacing.xl
                _buildBrowseByGenreSection(context, userDataProvider),
              ],
            ),
          );
        },
      ),
    );
  }
  
  void _initOrUpdatePriceAnimation(String songId, double oldPrice, double newPrice) {
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
      _priceAnimations[songId] = Tween<double>(
        begin: oldPrice,
        end: newPrice,
      ).animate(CurvedAnimation(
        parent: _priceAnimationControllers[songId]!,
        curve: Curves.easeInOut,
      ));
      
      _priceAnimationControllers[songId]!.reset();
    }
    
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
        contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.xs), // Use AppSpacing.xs
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
        const SizedBox(height: AppSpacing.m), // Use AppSpacing.m
        SizedBox( 
          height: 260.0, // Height for the horizontal list container
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
        const SizedBox(height: AppSpacing.m), // Use AppSpacing.m
        SizedBox( 
          height: 260.0, // Height for the horizontal list container
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: songs.length,
            itemBuilder: (context, index) {
              final song = songs[index];
              return _buildSongCard(context, song, userDataProvider, showPriceChange: true); // Pass showPriceChange here
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
        const SizedBox(height: AppSpacing.m), // Use AppSpacing.m
        SizedBox( 
          height: 260.0, // Height for the horizontal list container
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
        const SizedBox(height: AppSpacing.m), // Use AppSpacing.m
        Wrap(
          spacing: AppSpacing.s, // Use AppSpacing.s
          runSpacing: AppSpacing.s, // Use AppSpacing.s
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
        const SizedBox(height: AppSpacing.m), // Use AppSpacing.m
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
                      margin: const EdgeInsets.only(right: AppSpacing.m), // Use AppSpacing.m
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.m), // Use AppSpacing.m
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
                            const SizedBox(height: AppSpacing.s), // Use AppSpacing.s
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
    final hasAnimation = _priceAnimationControllers.containsKey(song.id) && 
                         _priceAnimations.containsKey(song.id);
    
    final priceChangePercent = song.previousPrice > 0 
        ? ((song.currentPrice - song.previousPrice) / song.previousPrice) * 100
        : 0.0;
    
    final priceChangeColor = priceChangePercent > 0 
        ? Colors.green 
        : priceChangePercent < 0 
            ? Colors.red 
            : Colors.grey;
    
    final quantityOwned = userDataProvider.getQuantityOwned(song.id);
    final ownsSong = quantityOwned > 0;
    
    return GestureDetector(
      onTap: () => _showSongActions(context, song, userDataProvider),
      child: Card(
        margin: const EdgeInsets.only(right: AppSpacing.l), // Use AppSpacing.l
        child: SizedBox( 
          width: 120.0, 
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.s), // Use AppSpacing.s
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              // Removed mainAxisSize: MainAxisSize.min
              children: [
                ClipRRect( // Use ClipRRect to ensure the image respects the border radius
                  borderRadius: BorderRadius.circular(AppSpacing.xs), // Use AppSpacing.xs
                  child: SizedBox( // Use SizedBox to constrain the image size
                    height: 120.0, // Increased from 90.0
                    width: 120.0, // Increased from 90.0
                    child: song.albumArtUrl != null && song.albumArtUrl!.isNotEmpty
                        ? Image.network(
                            song.albumArtUrl!,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                      : null,
                                  strokeWidth: AppSpacing.xxs, // Use AppSpacing.xxs
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              // Fallback to placeholder icon on error
                              return Container(
                                color: Colors.grey[800],
                                child: Center(
                                  child: Icon(
                                    Icons.music_note,
                                    size: 40.0,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              );
                            },
                          )
                        : Container( // Fallback for null/empty URL
                            color: Colors.grey[800],
                            child: Center(
                              child: Icon(
                                Icons.music_note,
                                size: 40.0,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                  ),
                ),
                Expanded( // Wrap the text content below the image with Expanded
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Adjust alignment if needed
                    children: [
                      Text(
                        song.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14.0,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        song.artist,
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 12.0,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
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
                                          horizontal: AppSpacing.xs, // Use AppSpacing.xs
                                          vertical: AppSpacing.xxs, // Use AppSpacing.xxs
                                        ),
                                        decoration: BoxDecoration(
                                          color: priceChangeColor.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(AppSpacing.xs), // Use AppSpacing.xs
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
                                      horizontal: AppSpacing.xs, // Use AppSpacing.xs
                                      vertical: AppSpacing.xxs, // Use AppSpacing.xxs
                                    ),
                                    decoration: BoxDecoration(
                                      color: priceChangeColor.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(AppSpacing.xs), // Use AppSpacing.xs
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
                 Spacer(), // Add Spacer to push content up
              ],
            ),
                      
                      if (ownsSong)
                        Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.xs), // Use AppSpacing.xs
                          child: Text(
                            'Owned: $quantityOwned',
                            style: TextStyle(
                              fontSize: 12.0,
                              color: Colors.blue[400],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  void _showSongActions(BuildContext context, Song song, UserDataProvider userDataProvider) {
    final quantityOwned = userDataProvider.getQuantityOwned(song.id);
    final ownsSong = quantityOwned > 0;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(AppSpacing.l), // Use AppSpacing.l
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
                    radius: 60.0, // Increased from 45.0 (to match 120x120)
                  ),
                  const SizedBox(width: AppSpacing.l), // Use AppSpacing.l
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
                        const SizedBox(height: AppSpacing.xs), // Use AppSpacing.xs
                        Row(
                          children: [
                            Text(
                              'Current Price: \$${song.currentPrice.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.s), // Use AppSpacing.s
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
              const SizedBox(height: AppSpacing.l), // Use AppSpacing.l
              const Text(
                'Song Details',
                style: TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.s), // Use AppSpacing.s
              Text('Genre: ${song.genre}'),
              const SizedBox(height: AppSpacing.xs), // Use AppSpacing.xs
              Text('Previous Price: \$${song.previousPrice.toStringAsFixed(2)}'),
              const SizedBox(height: AppSpacing.l), // Use AppSpacing.l
              if (ownsSong)
                Text(
                  'You own: $quantityOwned ${quantityOwned == 1 ? 'share' : 'shares'}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              const SizedBox(height: AppSpacing.l), // Use AppSpacing.l
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _showBuyDialog(context, song, userDataProvider);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      child: Text(ownsSong ? 'Buy More' : 'Buy'),
                    ),
                  ),
                  if (ownsSong) ...[
                    const SizedBox(width: AppSpacing.l), // Use AppSpacing.l
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _showSellDialog(context, song, userDataProvider, quantityOwned);
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
  
  void _showBuyDialog(BuildContext context, Song song, UserDataProvider provider) {
    int quantity = 1;
    final cashBalance = provider.userProfile?.cashBalance ?? 0.0;
    final maxAffordable = (cashBalance / song.currentPrice).floor();
    
    if (maxAffordable < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Insufficient funds to buy this song'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final totalCost = quantity * song.currentPrice;
            final canAfford = totalCost <= cashBalance;
            
            return AlertDialog(
              title: Text('Buy ${song.name}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Artist: ${song.artist}'),
                  const SizedBox(height: AppSpacing.s), // Use AppSpacing.s
                  Text('Current Price: \$${song.currentPrice.toStringAsFixed(2)}'),
                  const SizedBox(height: AppSpacing.s), // Use AppSpacing.s
                  Text('Cash Balance: \$${cashBalance.toStringAsFixed(2)}'),
                  const SizedBox(height: AppSpacing.l), // Use AppSpacing.l
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Quantity: '),
                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: quantity > 1
                            ? () => setState(() => quantity--)
                            : null,
                      ),
                      Text('$quantity'),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: quantity < maxAffordable
                            ? () => setState(() => quantity++)
                            : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s), // Use AppSpacing.s
                  Text(
                    'Total Cost: \$${totalCost.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (!canAfford)
                    const Text(
                      'Insufficient funds',
                      style: TextStyle(color: Colors.red),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: canAfford
                      ? () {
                          provider.buySong(song.id, quantity);
                          Navigator.pop(context);
                          
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Successfully purchased $quantity ${quantity == 1 ? 'share' : 'shares'} of ${song.name}'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      : null,
                  child: const Text('Buy'),
                ),
              ],
            );
          },
        );
      },
    );
  }
  
  void _showSellDialog(BuildContext context, Song song, UserDataProvider provider, int quantityOwned) {
    int quantity = 1;
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final totalValue = quantity * song.currentPrice;
            
            return AlertDialog(
              title: Text('Sell ${song.name}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Artist: ${song.artist}'),
                  const SizedBox(height: AppSpacing.s), // Use AppSpacing.s
                  Text('Current Price: \$${song.currentPrice.toStringAsFixed(2)}'),
                  const SizedBox(height: AppSpacing.s), // Use AppSpacing.s
                  Text('You Own: $quantityOwned ${quantityOwned == 1 ? 'share' : 'shares'}'),
                  const SizedBox(height: AppSpacing.l), // Use AppSpacing.l
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Quantity to Sell: '),
                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: quantity > 1
                            ? () => setState(() => quantity--)
                            : null,
                      ),
                      Text('$quantity'),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: quantity < quantityOwned
                            ? () => setState(() => quantity++)
                            : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s), // Use AppSpacing.s
                  Text(
                    'Total Value: \$${totalValue.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    provider.sellSong(song.id, quantity);
                    Navigator.pop(context);
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Successfully sold $quantity ${quantity == 1 ? 'share' : 'shares'} of ${song.name}'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
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
