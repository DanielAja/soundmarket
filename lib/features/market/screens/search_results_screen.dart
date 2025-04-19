import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/models/song.dart'; // Corrected path
import '../../../shared/providers/user_data_provider.dart'; // Corrected path
import '../../../shared/services/search_state_service.dart';
import '../../../shared/widgets/search_bar_with_suggestions.dart'; // Corrected path
import '../../../shared/services/music_data_api_service.dart'; // Added import

class SearchResultsScreen extends StatefulWidget {
  final String initialQuery;

  const SearchResultsScreen({super.key, required this.initialQuery});

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  late String _searchQuery;
  List<Song> _searchResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    // Get the initial query and update the shared search state
    _searchQuery = widget.initialQuery;

    // Update shared search state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final searchStateService = Provider.of<SearchStateService>(
          context,
          listen: false,
        );
        searchStateService.updateQuery(_searchQuery);
      }
    });

    _performSearch();
  }

  Future<void> _performSearch() async {
    setState(() {
      _isSearching = true;
    });

    try {
      final userDataProvider = Provider.of<UserDataProvider>(
        context,
        listen: false,
      );

      // Combine results from two sources:
      List<Song> combinedResults = [];

      // 1. First search for real-time API results from Spotify
      final musicDataService = Provider.of<MusicDataApiService>(
        context,
        listen: false,
      );
      final apiResults = await musicDataService.searchSongs(_searchQuery);
      if (apiResults.isNotEmpty) {
        combinedResults.addAll(apiResults);

        // Add API results to the song pool for future reference
        userDataProvider.addSongsToPool(apiResults);
      }

      // 2. Then search existing songs in the catalog
      final allSongs = userDataProvider.allSongs;
      final localFilteredSongs =
          allSongs.where((song) {
            final songNameLower = song.name.toLowerCase();
            final artistNameLower = song.artist.toLowerCase();
            final genreLower = song.genre.toLowerCase();
            final queryLower = _searchQuery.toLowerCase();

            return songNameLower.contains(queryLower) ||
                artistNameLower.contains(queryLower) ||
                genreLower.contains(queryLower);
          }).toList();

      // Add local results (avoiding duplicates)
      for (final song in localFilteredSongs) {
        if (!combinedResults.any((s) => s.id == song.id)) {
          combinedResults.add(song);
        }
      }

      // Sort by relevance (exact matches first)
      combinedResults.sort((a, b) {
        final aNameLower = a.name.toLowerCase();
        final bNameLower = b.name.toLowerCase();
        final aArtistLower = a.artist.toLowerCase();
        final bArtistLower = b.artist.toLowerCase();
        final queryLower = _searchQuery.toLowerCase();

        // Exact matches first
        final aExactNameMatch = aNameLower == queryLower;
        final bExactNameMatch = bNameLower == queryLower;
        if (aExactNameMatch && !bExactNameMatch) return -1;
        if (!aExactNameMatch && bExactNameMatch) return 1;

        // Then starts with matches
        final aStartsWithName = aNameLower.startsWith(queryLower);
        final bStartsWithName = bNameLower.startsWith(queryLower);
        if (aStartsWithName && !bStartsWithName) return -1;
        if (!aStartsWithName && bStartsWithName) return 1;

        // Then artist exact matches
        final aExactArtistMatch = aArtistLower == queryLower;
        final bExactArtistMatch = bArtistLower == queryLower;
        if (aExactArtistMatch && !bExactArtistMatch) return -1;
        if (!aExactArtistMatch && bExactArtistMatch) return 1;

        // Then artist starts with matches
        final aStartsWithArtist = aArtistLower.startsWith(queryLower);
        final bStartsWithArtist = bArtistLower.startsWith(queryLower);
        if (aStartsWithArtist && !bStartsWithArtist) return -1;
        if (!aStartsWithArtist && bStartsWithArtist) return 1;

        // Default to popularity (price) for API results
        return b.currentPrice.compareTo(a.currentPrice);
      });

      setState(() {
        _searchResults = combinedResults;
        _isSearching = false;
      });
    } catch (e) {
      // Fallback to local search if API search fails
      final userDataProvider = Provider.of<UserDataProvider>(
        context,
        listen: false,
      );
      final allSongs = userDataProvider.allSongs;

      final filteredSongs =
          allSongs.where((song) {
            final songNameLower = song.name.toLowerCase();
            final artistNameLower = song.artist.toLowerCase();
            final genreLower = song.genre.toLowerCase();
            final queryLower = _searchQuery.toLowerCase();

            return songNameLower.contains(queryLower) ||
                artistNameLower.contains(queryLower) ||
                genreLower.contains(queryLower);
          }).toList();

      setState(() {
        _searchResults = filteredSongs;
        _isSearching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Handle back button press to pass data back to previous screen
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          // Get the latest search state before popping
          final searchStateService = Provider.of<SearchStateService>(
            context,
            listen: false,
          );
          searchStateService.updateQuery(_searchQuery);

          // Return the current search query when navigating back for compatibility
          Navigator.pop(context, _searchQuery);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('assets/icon/app_icon.png', width: 28, height: 28),
              const SizedBox(width: 8),
              const Text('Sound Market'),
            ],
          ),
          centerTitle: true,
          // Add a custom back button to handle returning with search data
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              // Get the latest search state before popping
              final searchStateService = Provider.of<SearchStateService>(
                context,
                listen: false,
              );
              searchStateService.updateQuery(_searchQuery);

              // Pass the current query back to the previous screen for compatibility
              Navigator.pop(context, _searchQuery);
            },
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SearchBarWithSuggestions(
                initialQuery: _searchQuery,
                onSongSelected: (song) {
                  _showSongActions(context, song);
                },
                onSubmitted: (query) {
                  // Update local state and search
                  setState(() {
                    _searchQuery = query;
                  });

                  // Update shared search state
                  final searchStateService = Provider.of<SearchStateService>(
                    context,
                    listen: false,
                  );
                  searchStateService.updateQuery(query);

                  // Perform search with new query
                  _performSearch();
                },
              ),
            ),
            Expanded(
              child:
                  _isSearching
                      ? const Center(child: CircularProgressIndicator())
                      : _searchResults.isEmpty
                      ? Center(
                        child: Text(
                          'No results found for "$_searchQuery"',
                          style: TextStyle(color: Colors.grey[400]),
                        ),
                      )
                      : ListView.builder(
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final song = _searchResults[index];
                          return _buildSongListItem(context, song);
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSongListItem(BuildContext context, Song song) {
    final userDataProvider = Provider.of<UserDataProvider>(context);
    final isOwned = userDataProvider.ownsSong(song.id);
    final priceChangePercent = song.priceChangePercent;
    final isPriceUp = song.isPriceUp;

    return ListTile(
      leading:
          song.albumArtUrl != null
              ? ClipRRect(
                borderRadius: BorderRadius.circular(4.0),
                child: Image.network(
                  song.albumArtUrl!,
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 50.0,
                      height: 50.0,
                      color: Colors.grey[700],
                      child: const Icon(Icons.music_note, size: 25.0),
                    );
                  },
                ),
              )
              : Container(
                width: 50.0,
                height: 50.0,
                color: Colors.grey[700],
                child: const Icon(Icons.music_note, size: 25.0),
              ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              song.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isOwned)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 6.0,
                vertical: 2.0,
              ),
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
        ],
      ),
      subtitle: Text(
        '${song.artist} • ${song.genre}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
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
                ),
              ),
            ],
          ),
        ],
      ),
      onTap: () => _showSongActions(context, song),
    );
  }

  void _showSongActions(BuildContext context, Song song) {
    final userDataProvider = Provider.of<UserDataProvider>(
      context,
      listen: false,
    );
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
                    backgroundImage:
                        song.albumArtUrl != null
                            ? NetworkImage(song.albumArtUrl!)
                            : null,
                    child:
                        song.albumArtUrl == null
                            ? const Icon(Icons.music_note)
                            : null,
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
                          style: TextStyle(color: Colors.grey[400]),
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
                              song.isPriceUp
                                  ? Icons.arrow_upward
                                  : Icons.arrow_downward,
                              color: song.isPriceUp ? Colors.green : Colors.red,
                              size: 14.0,
                            ),
                            Text(
                              '${song.priceChangePercent.toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontSize: 12.0,
                                color:
                                    song.isPriceUp ? Colors.green : Colors.red,
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
                style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8.0),
              Text('Genre: ${song.genre}'),
              const SizedBox(height: 4.0),
              Text(
                'Previous Price: \$${song.previousPrice.toStringAsFixed(2)}',
              ),
              const SizedBox(height: 16.0),
              if (ownedQuantity > 0)
                Text(
                  'You own: $ownedQuantity ${ownedQuantity == 1 ? 'share' : 'shares'}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
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
                          _showSellSongDialog(
                            context,
                            song,
                            userDataProvider,
                            ownedQuantity,
                          );
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

  // Show dialog to buy a song
  void _showBuySongDialog(
    BuildContext context,
    Song song,
    UserDataProvider provider,
  ) {
    int quantity = 1;
    final cashBalance = provider.userProfile?.cashBalance ?? 0.0;
    final maxAffordable = (cashBalance / song.currentPrice).floor();

    if (maxAffordable < 1) {
      // Show insufficient funds message
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
              backgroundColor: Colors.grey[900],
              title: Text('Buy ${song.name}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Artist: ${song.artist}'),
                  const SizedBox(height: 8.0),
                  Text(
                    'Current Price: \$${song.currentPrice.toStringAsFixed(2)}',
                  ),
                  const SizedBox(height: 8.0),
                  Text('Cash Balance: \$${cashBalance.toStringAsFixed(2)}'),
                  const SizedBox(height: 16.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Quantity: '),
                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed:
                            quantity > 1
                                ? () => setState(() => quantity--)
                                : null,
                      ),
                      Text('$quantity'),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed:
                            quantity < maxAffordable
                                ? () => setState(() => quantity++)
                                : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8.0),
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
                  onPressed:
                      canAfford
                          ? () async {
                            final success = await provider.buySong(
                              song.id,
                              quantity,
                            );
                            Navigator.pop(context);

                            if (success) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Successfully purchased $quantity ${quantity == 1 ? 'share' : 'shares'} of ${song.name}',
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );
                              // Refresh search results to show updated ownership status
                              setState(() {});
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Failed to buy shares'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                          : null,
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

  // Show dialog to sell a song
  void _showSellSongDialog(
    BuildContext context,
    Song song,
    UserDataProvider provider,
    int quantityOwned,
  ) {
    int quantity = 1;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final totalValue = quantity * song.currentPrice;

            return AlertDialog(
              backgroundColor: Colors.grey[900],
              title: Text('Sell ${song.name}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Artist: ${song.artist}'),
                  const SizedBox(height: 8.0),
                  Text(
                    'Current Price: \$${song.currentPrice.toStringAsFixed(2)}',
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    'You Own: $quantityOwned ${quantityOwned == 1 ? 'share' : 'shares'}',
                  ),
                  const SizedBox(height: 16.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Quantity to Sell: '),
                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed:
                            quantity > 1
                                ? () => setState(() => quantity--)
                                : null,
                      ),
                      Text('$quantity'),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed:
                            quantity < quantityOwned
                                ? () => setState(() => quantity++)
                                : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8.0),
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
                  onPressed: () async {
                    final success = await provider.sellSong(song.id, quantity);
                    Navigator.pop(context);

                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Successfully sold $quantity ${quantity == 1 ? 'share' : 'shares'} of ${song.name}',
                          ),
                          backgroundColor: Colors.green,
                        ),
                      );
                      // Refresh search results to show updated ownership status
                      setState(() {});
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Failed to sell shares'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
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
