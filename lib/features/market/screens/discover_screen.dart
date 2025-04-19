import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/providers/user_data_provider.dart';
import '../../../shared/models/song.dart';
import '../../../shared/services/music_data_api_service.dart';
import '../../../shared/services/search_state_service.dart';
import '../../../shared/widgets/search_bar_with_suggestions.dart';
import 'top_songs_list_screen.dart';
import 'search_results_screen.dart';
import '../../../core/theme/app_spacing.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen>
    with TickerProviderStateMixin {
  final Map<String, double> _previousPrices = {};
  final Map<String, AnimationController> _priceAnimationControllers = {};
  final Map<String, Animation<double>> _priceAnimations = {};
  late final MusicDataApiService _musicDataApi;
  String _selectedGenre = 'pop'; // Set Pop as the default genre

  // Flag to limit how often we make API calls
  static bool _apiDataLoaded = false;

  @override
  void initState() {
    super.initState();
    _musicDataApi = MusicDataApiService();
    _musicDataApi.setDiscoverTabActive(true);

    // Use the static flag to prevent multiple API calls when navigating back to this screen
    if (!_apiDataLoaded) {
      // Set the flag to true to prevent future unnecessary API calls
      _apiDataLoaded = true;

      // Give the UI a chance to render before making API calls
      Future.delayed(Duration(milliseconds: 500), () {
        // Load top songs first and only once
        if (_cachedTopSongs == null) {
          _loadTopSongsData();
        }

        // Load data for other sections after top songs
        _loadNewReleasesData();

        // Always load pop genre songs by default
        Future.delayed(Duration(milliseconds: 800), () {
          if (mounted) {
            final userDataProvider = Provider.of<UserDataProvider>(
              context,
              listen: false,
            );
            // Ensure we load pop songs by default
            userDataProvider.getSongsByGenre(_selectedGenre);
          }
        });
      });
    } else {
      // Even if API data was already loaded, ensure pop songs are loaded when returning to this screen
      Future.delayed(Duration(milliseconds: 300), () {
        if (mounted) {
          final userDataProvider = Provider.of<UserDataProvider>(
            context,
            listen: false,
          );
          userDataProvider.getSongsByGenre(_selectedGenre);
        }
      });
    }
  }

  // Load data for each section with delays between API calls to prevent rate limiting
  void _loadNewReleasesData() {
    if (_cachedNewSongs == null && !_loadingNewReleases) {
      _loadingNewReleases = true;
      _musicDataApi
          .getNewReleases(limit: 10)
          .then((newReleases) {
            if (mounted) {
              setState(() {
                _cachedNewSongs = newReleases;
                _loadingNewReleases = false;

                if (newReleases.isNotEmpty) {
                  final userDataProvider = Provider.of<UserDataProvider>(
                    context,
                    listen: false,
                  );
                  userDataProvider.addSongsToPool(newReleases);
                }

                // Load next section after a delay
                Future.delayed(Duration(seconds: 2), _loadTopMoversData);
              });
            }
          })
          .catchError((error) {
            if (mounted) {
              setState(() {
                // Create fallback data on error - use random songs from the user's data
                final userDataProvider = Provider.of<UserDataProvider>(
                  context,
                  listen: false,
                );
                final allSongs = userDataProvider.allSongs;

                if (allSongs.isNotEmpty) {
                  final random = Random();
                  final songsWithNewness =
                      allSongs.map((song) {
                        return {'song': song, 'newness': random.nextDouble()};
                      }).toList();

                  songsWithNewness.sort(
                    (a, b) => (b['newness'] as double).compareTo(
                      a['newness'] as double,
                    ),
                  );
                  _cachedNewSongs =
                      songsWithNewness
                          .take(10)
                          .map((item) => item['song'] as Song)
                          .toList();
                } else {
                  // If there are no songs available, use an empty list
                  _cachedNewSongs = [];
                }

                _loadingNewReleases = false;
                // Skip loading top songs to keep them consistent
                // Go directly to loading top movers section
                Future.delayed(Duration(seconds: 2), _loadTopMoversData);
              });
            }
          });
    } else {
      // If this section is already loaded, move to the next one
      // Skip top songs and go directly to top movers
      _loadTopMoversData();
    }
  }

  void _loadTopSongsData() {
    if ((_cachedTopSongs == null || _cachedTopSongs!.isEmpty) &&
        !_loadingTopSongs) {
      _loadingTopSongs = true;
      // Get the most popular songs across all genres for the Top Songs section
      // Explicitly exclude songs with title "Price tag" which seem to appear erroneously
      _musicDataApi
          .searchSongs(
            "tag:popular year:2023-2024 NOT title:\"Price tag\"",
            limit: 10,
          ) // More specific query to avoid the Price tag songs
          .then((topTracks) {
            if (mounted) {
              setState(() {
                // Only update if we got valid data and filter out any "Price tag" songs that might have slipped through
                if (topTracks.isNotEmpty) {
                  // Check if we have any "Price tag" songs in the results
                  final priceTagSongs =
                      topTracks
                          .where(
                            (song) => song.name.toLowerCase() == "price tag",
                          )
                          .toList();

                  if (priceTagSongs.isNotEmpty) {
                    print(
                      'WARNING: Found ${priceTagSongs.length} "Price tag" songs in search results',
                    );
                  }

                  // Filter out any "Price tag" songs that might have slipped through the query
                  final filteredTracks =
                      topTracks
                          .where(
                            (song) => song.name.toLowerCase() != "price tag",
                          )
                          .toList();

                  // Only use the results if we still have songs after filtering
                  if (filteredTracks.isNotEmpty) {
                    _cachedTopSongs = filteredTracks;

                    // Add songs to pool
                    final userDataProvider = Provider.of<UserDataProvider>(
                      context,
                      listen: false,
                    );
                    userDataProvider.addSongsToPool(filteredTracks);
                  } else if (_cachedTopSongs == null) {
                    // If filtering removed all songs and we have no cached data, create empty list
                    _cachedTopSongs = [];
                  }
                } else if (_cachedTopSongs == null) {
                  // If no data returned and we have no cached data, create an empty list
                  // but not null, so we'll show placeholders instead of loading indicators
                  _cachedTopSongs = [];
                }

                _loadingTopSongs = false;

                // Load next section after a delay
                Future.delayed(Duration(seconds: 2), _loadTopMoversData);
              });
            }
          })
          .catchError((error) {
            if (mounted) {
              setState(() {
                // On error, keep any existing data (_cachedTopSongs is unchanged)
                // If _cachedTopSongs was null, set it to empty list to show placeholders
                if (_cachedTopSongs == null) {
                  _cachedTopSongs = [];
                }

                _loadingTopSongs = false;
                // Still load the next section even on error
                Future.delayed(Duration(seconds: 2), _loadTopMoversData);
              });
            }
          });
    } else {
      // If this section is already loaded, move to the next one
      _loadTopMoversData();
    }
  }

  void _loadTopMoversData() {
    if (_cachedTopMovers == null && !_loadingTopMovers) {
      _loadingTopMovers = true;
      _musicDataApi
          .searchSongs("genre:hip-hop year:2023-2024", limit: 10)
          .then((hipHopTracks) {
            if (mounted) {
              setState(() {
                _cachedTopMovers = hipHopTracks;
                _loadingTopMovers = false;

                if (hipHopTracks.isNotEmpty) {
                  final userDataProvider = Provider.of<UserDataProvider>(
                    context,
                    listen: false,
                  );
                  userDataProvider.addSongsToPool(hipHopTracks);
                }

                // Load final section after a delay
                Future.delayed(Duration(seconds: 2), _loadRisingArtistsData);
              });
            }
          })
          .catchError((error) {
            if (mounted) {
              setState(() {
                _loadingTopMovers = false;
                // Still load the next section even on error
                Future.delayed(Duration(seconds: 2), _loadRisingArtistsData);
              });
            }
          });
    } else {
      // If this section is already loaded, move to the next one
      _loadRisingArtistsData();
    }
  }

  void _loadRisingArtistsData() {
    if (_cachedRisingArtists == null && !_loadingRisingArtists) {
      _loadingRisingArtists = true;
      _musicDataApi
          .searchSongs("genre:indie tag:new", limit: 15)
          .then((indieTracks) {
            if (mounted) {
              setState(() {
                final uniqueArtists =
                    indieTracks.map((song) => song.artist).toSet().toList();

                _cachedRisingArtists = uniqueArtists.take(10).toList();
                _loadingRisingArtists = false;

                if (indieTracks.isNotEmpty) {
                  final userDataProvider = Provider.of<UserDataProvider>(
                    context,
                    listen: false,
                  );
                  userDataProvider.addSongsToPool(indieTracks);
                }
              });
            }
          })
          .catchError((error) {
            if (mounted) {
              setState(() {
                _loadingRisingArtists = false;
              });
            }
          });
    }
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
        title: Row(
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
            return const Center(child: CircularProgressIndicator());
          }

          final topSongs = userDataProvider.getTopSongs(limit: 50);
          final topMovers = userDataProvider.getTopMovers(limit: 50);
          final risingArtists = userDataProvider.risingArtists;
          final genreSongs = userDataProvider.getSongsByGenre(_selectedGenre);

          for (final song in [...topSongs, ...topMovers, ...genreSongs]) {
            if (!_previousPrices.containsKey(song.id)) {
              _previousPrices[song.id] = song.currentPrice;
            }
          }

          return RefreshIndicator(
            onRefresh: () async {
              final random = Random();

              // Update prices randomly for all song categories
              for (final song in [...topSongs, ...topMovers, ...genreSongs]) {
                if (random.nextBool()) {
                  final oldPrice = song.currentPrice;
                  final change =
                      oldPrice * (0.05 * (random.nextDouble() * 2 - 1));
                  final newPrice = max(0.01, oldPrice + change);

                  song.previousPrice = oldPrice;
                  song.currentPrice = double.parse(newPrice.toStringAsFixed(2));

                  if (_previousPrices.containsKey(song.id) &&
                      _previousPrices[song.id] != song.currentPrice) {
                    _initOrUpdatePriceAnimation(
                      song.id,
                      _previousPrices[song.id]!,
                      song.currentPrice,
                    );
                    _previousPrices[song.id] = song.currentPrice;
                  }
                }
              }

              // Reset all cached data to refresh everything on pull-to-refresh
              _cachedTopSongs = null;
              _loadingTopSongs = false;

              _cachedTopMovers = null;
              _loadingTopMovers = false;

              _cachedRisingArtists = null;
              _loadingRisingArtists = false;

              _cachedNewSongs = null;
              _loadingNewReleases = false;

              // Reset the API loading flag to allow reloading all sections
              _apiDataLoaded = false;

              // Restart the sequential loading process with all sections
              Future.delayed(Duration(milliseconds: 500), () {
                // Load top songs first since it was reset
                _loadTopSongsData();
              });

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
                _buildNewSongsSection(context, userDataProvider),
                const SizedBox(height: AppSpacing.xl), // Use AppSpacing.xl
                _buildRisingArtistsSection(context, risingArtists),
                const SizedBox(height: AppSpacing.xl), // Use AppSpacing.xl
                _buildBrowseByGenreSection(context, userDataProvider),
                const SizedBox(height: AppSpacing.xl), // Use AppSpacing.xl
                _buildGenreSongsSection(context, genreSongs, userDataProvider),
              ],
            ),
          );
        },
      ),
    );
  }

  void _initOrUpdatePriceAnimation(
    String songId,
    double oldPrice,
    double newPrice,
  ) {
    if (!_priceAnimationControllers.containsKey(songId)) {
      _priceAnimationControllers[songId] = AnimationController(
        duration: const Duration(milliseconds: 500),
        vsync: this,
      );

      _priceAnimations[songId] = Tween<double>(
        begin: oldPrice,
        end: newPrice,
      ).animate(
        CurvedAnimation(
          parent: _priceAnimationControllers[songId]!,
          curve: Curves.easeInOut,
        ),
      );
    } else {
      _priceAnimations[songId] = Tween<double>(
        begin: oldPrice,
        end: newPrice,
      ).animate(
        CurvedAnimation(
          parent: _priceAnimationControllers[songId]!,
          curve: Curves.easeInOut,
        ),
      );

      _priceAnimationControllers[songId]!.reset();
    }

    _priceAnimationControllers[songId]!.forward();
  }

  void _showGenreFilterDialog(BuildContext context) {
    final userDataProvider = Provider.of<UserDataProvider>(
      context,
      listen: false,
    );
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
                  selected:
                      false, // Pop is default, so All Genres is never selected
                  onTap: () {
                    setState(() {
                      _selectedGenre =
                          'pop'; // Default to 'pop' instead of null
                    });
                    Navigator.pop(context);
                  },
                ),
                ...genres.map(
                  (genre) => ListTile(
                    title: Text(genre),
                    selected: _selectedGenre == genre,
                    onTap: () {
                      setState(() {
                        _selectedGenre = genre;
                      });
                      Navigator.pop(context);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchBar() {
    // Get the shared search state service
    final searchStateService = Provider.of<SearchStateService>(
      context,
      listen: true,
    );

    return Column(
      children: [
        SearchBarWithSuggestions(
          initialQuery: searchStateService.currentQuery,
          onSongSelected: (song) {
            _showSongActions(
              context,
              song,
              Provider.of<UserDataProvider>(context, listen: false),
            );
          },
          onSubmitted: (value) async {
            if (value.isNotEmpty) {
              final searchQuery = value.trim();

              // Update the shared search state immediately
              searchStateService.updateQuery(searchQuery);

              // Reset to default genre (pop)
              setState(() {
                _selectedGenre = 'pop';
              });

              // Navigate directly to search results screen without showing results in the discover tab
              final returnedQuery = await Navigator.push<String>(
                context,
                MaterialPageRoute(
                  builder:
                      (context) =>
                          SearchResultsScreen(initialQuery: searchQuery),
                ),
              );

              // Update search query if one was returned
              if (returnedQuery != null && mounted) {
                searchStateService.updateQuery(returnedQuery);
              }
            }
          },
        ),
        // Removed search results section that used to appear here
      ],
    );
  }

  // Using shared search state instead of a local query

  /* 
  // REMOVED: No longer showing search results section within the discover tab
  // This function has been removed as per requirement to not show search results
  // as a section after searching.
  
  Widget _buildSearchResultsSection(BuildContext context) {
    // Original implementation removed
  }
  */

  // Store cached songs for top songs section
  List<Song>? _cachedTopSongs;
  bool _loadingTopSongs = false;

  Widget _buildTopSongsSection(
    BuildContext context,
    List<Song> songs,
    UserDataProvider userDataProvider,
  ) {
    // Initialize with provided songs if needed, but filter out any "Price tag" songs
    if (_cachedTopSongs == null) {
      // Filter out Price tag songs which seem to appear erroneously
      final filteredSongs =
          songs
              .where((song) => song.name.toLowerCase() != "price tag")
              .toList();
      _cachedTopSongs = filteredSongs.isNotEmpty ? filteredSongs : [];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Top Songs',
              style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => const TopSongsListScreen(
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
          child:
              _loadingTopSongs
                  ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 10),
                        Text(
                          'Loading top songs...',
                          style: TextStyle(color: Colors.grey[400]),
                        ),
                      ],
                    ),
                  )
                  : _cachedTopSongs!.isEmpty
                  ? ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: 10, // Show 10 placeholder cards
                    itemBuilder: (context, index) {
                      return _buildPlaceholderCard(context);
                    },
                  )
                  : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _cachedTopSongs!.length,
                    itemBuilder: (context, index) {
                      final song = _cachedTopSongs![index];
                      return _buildSongCard(context, song, userDataProvider);
                    },
                  ),
        ),
      ],
    );
  }

  // Store cached songs for top movers section
  List<Song>? _cachedTopMovers;
  bool _loadingTopMovers = false;

  Widget _buildTopMoversSection(
    BuildContext context,
    List<Song> songs,
    UserDataProvider userDataProvider,
  ) {
    // Initialize with provided songs if needed
    if (_cachedTopMovers == null) {
      _cachedTopMovers = List<Song>.from(songs);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Top Movers',
              style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => const TopSongsListScreen(
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
          child:
              _loadingTopMovers
                  ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 10),
                        Text(
                          'Loading top movers...',
                          style: TextStyle(color: Colors.grey[400]),
                        ),
                      ],
                    ),
                  )
                  : _cachedTopMovers!.isEmpty
                  ? Center(
                    child: Text(
                      'No top movers found',
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                  )
                  : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _cachedTopMovers!.length,
                    itemBuilder: (context, index) {
                      final song = _cachedTopMovers![index];
                      return _buildSongCard(
                        context,
                        song,
                        userDataProvider,
                        showPriceChange: true,
                      ); // Pass showPriceChange here
                    },
                  ),
        ),
      ],
    );
  }

  Widget _buildGenreSongsSection(
    BuildContext context,
    List<Song> songs,
    UserDataProvider userDataProvider,
  ) {
    final displayGenre =
        _selectedGenre.substring(0, 1).toUpperCase() +
        _selectedGenre.substring(1);

    // Ensure songs are loaded for the current genre (pop by default)
    if (songs.isEmpty) {
      // Trigger a load of songs for this genre if none are available
      userDataProvider.getSongsByGenre(_selectedGenre);
    }

    // Format display title based on genre
    final displayTitle =
        displayGenre.toLowerCase() == "pop" ? "Popular" : displayGenre;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'More $displayTitle Songs',
          style: const TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppSpacing.m), // Use AppSpacing.m
        SizedBox(
          height: 260.0, // Height for the horizontal list container
          child:
              songs.isEmpty
                  ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.s),
                        Text(
                          'Finding more ${_selectedGenre.toLowerCase()} songs...',
                          style: TextStyle(color: Colors.grey[400]),
                        ),
                      ],
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

  Widget _buildBrowseByGenreSection(
    BuildContext context,
    UserDataProvider userDataProvider,
  ) {
    final genres = userDataProvider.allGenres;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Browse by Genre',
          style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppSpacing.m), // Use AppSpacing.m
        SizedBox(
          height: 50.0, // Height for the horizontal scrolling list
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: genres.length,
            itemBuilder: (context, index) {
              final genre = genres[index];
              // Check if this genre matches the current selected genre (which is 'pop' by default)
              final isSelected =
                  genre.toLowerCase() == _selectedGenre.toLowerCase();
              return Padding(
                padding: const EdgeInsets.only(right: AppSpacing.s),
                child: InkWell(
                  onTap: () {
                    // Only change genre if not already selected
                    if (!isSelected) {
                      setState(() {
                        _selectedGenre = genre.toLowerCase();
                        // Don't reset top songs when genre changes
                        // Only reload genre-specific songs

                        // Reload genre-specific songs too
                        // This will trigger a reload of genreSongs in the build method
                        userDataProvider.getSongsByGenre(_selectedGenre);
                      });
                    }
                    // No action needed when tapping an already selected genre
                  },
                  child: Chip(
                    label: Text(genre),
                    backgroundColor:
                        isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey[800],
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.black : Colors.white,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.m,
                      vertical: AppSpacing.xs,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // Store cached new songs
  List<Song>? _cachedNewSongs;
  bool _loadingNewReleases = false;

  // New section for new songs using API query
  Widget _buildNewSongsSection(
    BuildContext context,
    UserDataProvider userDataProvider,
  ) {
    // Initialize fallback if needed
    if (_cachedNewSongs == null) {
      // If no data loaded yet, get some fallback songs to show
      final allSongs = userDataProvider.allSongs;
      if (allSongs.isNotEmpty) {
        // Get a random subset of songs to display temporarily
        final random = Random();
        final songsWithNewness =
            allSongs.map((song) {
              return {'song': song, 'newness': random.nextDouble()};
            }).toList();

        songsWithNewness.sort(
          (a, b) => (b['newness'] as double).compareTo(a['newness'] as double),
        );
        _cachedNewSongs =
            songsWithNewness
                .take(10)
                .map((item) => item['song'] as Song)
                .toList();
      } else {
        _cachedNewSongs = [];
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'New Releases',
              style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () {
                // For now, just show a message that this feature is coming soon
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Coming soon: View all new releases'),
                  ),
                );
              },
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.m),
        SizedBox(
          height: 260.0,
          child:
              _loadingNewReleases
                  ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 10),
                        Text(
                          'Loading new releases...',
                          style: TextStyle(color: Colors.grey[400]),
                        ),
                      ],
                    ),
                  )
                  : _cachedNewSongs!.isEmpty
                  ? Center(
                    child: Text(
                      'No new releases found',
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                  )
                  : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _cachedNewSongs!.length,
                    itemBuilder: (context, index) {
                      final song = _cachedNewSongs![index];
                      return _buildSongCard(
                        context,
                        song,
                        userDataProvider,
                        showPriceChange: false,
                      );
                    },
                  ),
        ),
      ],
    );
  }

  // Store cached rising artists
  List<String>? _cachedRisingArtists;
  bool _loadingRisingArtists = false;

  Widget _buildRisingArtistsSection(
    BuildContext context,
    List<String> artists,
  ) {
    // Initialize with provided artists if needed
    if (_cachedRisingArtists == null) {
      _cachedRisingArtists = List<String>.from(artists);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Indie Artists on the Rise',
          style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppSpacing.m), // Use AppSpacing.m
        SizedBox(
          height: 120.0,
          child:
              _loadingRisingArtists
                  ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 10),
                        Text(
                          'Loading indie artists...',
                          style: TextStyle(color: Colors.grey[400]),
                        ),
                      ],
                    ),
                  )
                  : _cachedRisingArtists!.isEmpty
                  ? Center(
                    child: Text(
                      'No rising artists found',
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                  )
                  : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _cachedRisingArtists!.length,
                    itemBuilder: (context, index) {
                      final artist = _cachedRisingArtists![index];
                      return Card(
                        margin: const EdgeInsets.only(
                          right: AppSpacing.m,
                        ), // Use AppSpacing.m
                        child: Padding(
                          padding: const EdgeInsets.all(
                            AppSpacing.m,
                          ), // Use AppSpacing.m
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
                              const SizedBox(
                                height: AppSpacing.s,
                              ), // Use AppSpacing.s
                              Text(
                                // Move child property last
                                artist,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
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

  Widget _buildSongCard(
    BuildContext context,
    Song song,
    UserDataProvider userDataProvider, {
    bool showPriceChange = false,
  }) {
    final hasAnimation =
        _priceAnimationControllers.containsKey(song.id) &&
        _priceAnimations.containsKey(song.id);

    final priceChangePercent =
        song.previousPrice > 0
            ? ((song.currentPrice - song.previousPrice) / song.previousPrice) *
                100
            : 0.0;

    final priceChangeColor =
        priceChangePercent > 0
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
        clipBehavior:
            Clip.antiAlias, // Add this to clip the image to the card's shape
        child: SizedBox(
          width: 120.0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                // Use SizedBox to constrain the image size
                height: 120.0, // Increased from 90.0
                width: 120.0, // Increased from 90.0
                child:
                    song.albumArtUrl != null && song.albumArtUrl!.isNotEmpty
                        ? Image.network(
                          song.albumArtUrl!,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value:
                                    loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress
                                                .cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                strokeWidth:
                                    AppSpacing.xxs, // Use AppSpacing.xxs
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
                        : Container(
                          // Fallback for null/empty URL
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
              Expanded(
                // Wrap the text content below the image with Expanded
                child: Padding(
                  // Add padding only around the text content
                  padding: const EdgeInsets.all(
                    AppSpacing.s,
                  ), // Use AppSpacing.s
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment:
                        MainAxisAlignment
                            .spaceEvenly, // Adjust alignment if needed
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    child: Text(
                                      '\$${_priceAnimations[song.id]!.value.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16.0,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (showPriceChange && song.previousPrice > 0)
                                    Flexible(
                                      child: Padding(
                                        padding: const EdgeInsets.only(
                                          left: AppSpacing.xs,
                                        ),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: AppSpacing.xs,
                                            vertical: AppSpacing.xxs,
                                          ),
                                          decoration: BoxDecoration(
                                            color: priceChangeColor.withAlpha(
                                              (255 * 0.2).round(),
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              AppSpacing.xs,
                                            ),
                                          ),
                                          child: Text(
                                            '${priceChangePercent >= 0 ? '+' : ''}${priceChangePercent.toStringAsFixed(1)}%',
                                            style: TextStyle(
                                              color: priceChangeColor,
                                              fontSize: 12.0,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
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
                              Flexible(
                                child: Text(
                                  '\$${song.currentPrice.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16.0,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (showPriceChange && song.previousPrice > 0)
                                Flexible(
                                  child: Padding(
                                    padding: const EdgeInsets.only(
                                      left: AppSpacing.xs,
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppSpacing.xs,
                                        vertical: AppSpacing.xxs,
                                      ),
                                      decoration: BoxDecoration(
                                        color: priceChangeColor.withAlpha(
                                          (255 * 0.2).round(),
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          AppSpacing.xs,
                                        ),
                                      ),
                                      child: Text(
                                        '${priceChangePercent >= 0 ? '+' : ''}${priceChangePercent.toStringAsFixed(1)}%',
                                        style: TextStyle(
                                          color: priceChangeColor,
                                          fontSize: 12.0,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),

                      if (ownsSong)
                        Padding(
                          padding: const EdgeInsets.only(
                            top: AppSpacing.xs,
                          ), // Use AppSpacing.xs
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
                ), // Close Padding
              ),
            ],
          ),
          // Removed Padding wrapper
        ),
      ),
    );
  }

  void _showSongActions(
    BuildContext context,
    Song song,
    UserDataProvider userDataProvider,
  ) {
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
                    backgroundImage:
                        song.albumArtUrl != null
                            ? NetworkImage(song.albumArtUrl!)
                            : null,
                    child:
                        song.albumArtUrl == null
                            ? const Icon(Icons.music_note)
                            : null,
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
                          style: TextStyle(color: Colors.grey[400]),
                        ),
                        const SizedBox(
                          height: AppSpacing.xs,
                        ), // Use AppSpacing.xs
                        Row(
                          children: [
                            Text(
                              'Current Price: \$${song.currentPrice.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(
                              width: AppSpacing.s,
                            ), // Use AppSpacing.s
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
              const SizedBox(height: AppSpacing.l), // Use AppSpacing.l
              const Text(
                'Song Details',
                style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSpacing.s), // Use AppSpacing.s
              Text('Genre: ${song.genre}'),
              const SizedBox(height: AppSpacing.xs), // Use AppSpacing.xs
              Text(
                'Previous Price: \$${song.previousPrice.toStringAsFixed(2)}',
              ),
              const SizedBox(height: AppSpacing.l), // Use AppSpacing.l
              if (ownsSong)
                Text(
                  'You own: $quantityOwned ${quantityOwned == 1 ? 'share' : 'shares'}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
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
                          _showSellDialog(
                            context,
                            song,
                            userDataProvider,
                            quantityOwned,
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

  void _showBuyDialog(
    BuildContext context,
    Song song,
    UserDataProvider provider,
  ) {
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
                  Text(
                    'Current Price: \$${song.currentPrice.toStringAsFixed(2)}',
                  ),
                  const SizedBox(height: AppSpacing.s), // Use AppSpacing.s
                  Text('Cash Balance: \$${cashBalance.toStringAsFixed(2)}'),
                  const SizedBox(height: AppSpacing.l), // Use AppSpacing.l
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
                  onPressed:
                      canAfford
                          ? () {
                            provider.buySong(song.id, quantity);
                            Navigator.pop(context);

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Successfully purchased $quantity ${quantity == 1 ? 'share' : 'shares'} of ${song.name}',
                                ),
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

  void _showSellDialog(
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
              title: Text('Sell ${song.name}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Artist: ${song.artist}'),
                  const SizedBox(height: AppSpacing.s), // Use AppSpacing.s
                  Text(
                    'Current Price: \$${song.currentPrice.toStringAsFixed(2)}',
                  ),
                  const SizedBox(height: AppSpacing.s), // Use AppSpacing.s
                  Text(
                    'You Own: $quantityOwned ${quantityOwned == 1 ? 'share' : 'shares'}',
                  ),
                  const SizedBox(height: AppSpacing.l), // Use AppSpacing.l
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
                        content: Text(
                          'Successfully sold $quantity ${quantity == 1 ? 'share' : 'shares'} of ${song.name}',
                        ),
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

  // Build a placeholder card for when no song data is available
  Widget _buildPlaceholderCard(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(right: AppSpacing.l),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: 120.0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Animated shimmer effect for album art placeholder
            Container(
              height: 120.0,
              width: 120.0,
              color: Colors.grey[800],
              child: Center(
                child: Icon(
                  Icons.music_note,
                  size: 40.0,
                  color: Colors.grey[700],
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.s),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Title placeholder
                    Container(
                      height: 14.0,
                      width: 80.0,
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(2.0),
                      ),
                    ),
                    // Artist placeholder
                    Container(
                      height: 12.0,
                      width: 60.0,
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(2.0),
                      ),
                    ),
                    // Price placeholder
                    Container(
                      height: 16.0,
                      width: 40.0,
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(2.0),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
