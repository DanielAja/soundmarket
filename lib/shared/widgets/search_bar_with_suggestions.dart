import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/song.dart'; // Corrected path
import '../providers/user_data_provider.dart'; // Corrected path

class SearchBarWithSuggestions extends StatefulWidget {
  final Function(Song) onSongSelected;
  final Function(String) onSubmitted;
  final String? initialQuery;

  const SearchBarWithSuggestions({
    super.key,
    required this.onSongSelected,
    required this.onSubmitted,
    this.initialQuery,
  });

  @override
  State<SearchBarWithSuggestions> createState() => _SearchBarWithSuggestionsState();
}

class _SearchBarWithSuggestionsState extends State<SearchBarWithSuggestions> {
  late final TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  bool _showSuggestions = false;
  late String _searchQuery;
  
  @override
  void initState() {
    super.initState();
    // Initialize with the provided query if available
    _searchQuery = widget.initialQuery ?? '';
    _controller = TextEditingController(text: _searchQuery);
    
    _focusNode.addListener(() {
      setState(() {
        _showSuggestions = _focusNode.hasFocus && _searchQuery.isNotEmpty;
      });
    });
  }
  
  @override
  void didUpdateWidget(SearchBarWithSuggestions oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update controller text if initialQuery changes
    if (widget.initialQuery != oldWidget.initialQuery && widget.initialQuery != null) {
      _searchQuery = widget.initialQuery!;
      // Update the controller text without triggering the onChanged event
      _controller.value = TextEditingValue(
        text: _searchQuery,
        selection: TextSelection.collapsed(offset: _searchQuery.length),
      );
    }
  }
  
  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: _controller,
          focusNode: _focusNode,
          decoration: InputDecoration(
            hintText: 'Search for artists, songs...',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30.0),
            ),
            filled: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 4.0),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      setState(() {
                        _controller.clear();
                        _searchQuery = '';
                        _showSuggestions = false;
                      });
                    },
                  )
                : null,
          ),
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
              _showSuggestions = _focusNode.hasFocus && value.isNotEmpty;
            });
          },
          onSubmitted: (value) {
            if (value.isNotEmpty) {
              widget.onSubmitted(value);
              setState(() {
                _showSuggestions = false;
              });
            }
          },
        ),
        if (_showSuggestions) _buildSuggestions(),
      ],
    );
  }
  
  Widget _buildSuggestions() {
    final userDataProvider = Provider.of<UserDataProvider>(context, listen: false);
    final allSongs = userDataProvider.allSongs;
    
    // Filter songs based on search query
    final filteredSongs = allSongs.where((song) {
      final songNameLower = song.name.toLowerCase();
      final artistNameLower = song.artist.toLowerCase();
      final queryLower = _searchQuery.toLowerCase();
      
      return songNameLower.contains(queryLower) || 
             artistNameLower.contains(queryLower);
    }).toList();
    
    // Sort by relevance (exact matches first)
    filteredSongs.sort((a, b) {
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
      
      // Default to alphabetical by name
      return aNameLower.compareTo(bNameLower);
    });
    
    // Limit to top 5 results
    final suggestedSongs = filteredSongs.take(5).toList();
    
    if (suggestedSongs.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(8.0),
            bottomRight: Radius.circular(8.0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha((255 * 0.2).round()), // Replaced withOpacity
              blurRadius: 5.0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16.0),
        child: const Text('No results found'),
      );
    }
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(8.0),
          bottomRight: Radius.circular(8.0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha((255 * 0.2).round()), // Replaced withOpacity
              blurRadius: 5.0,
              offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: suggestedSongs.length,
        itemBuilder: (context, index) {
          final song = suggestedSongs[index];
          return ListTile(
            leading: song.albumArtUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(4.0),
                    child: Image.network(
                      song.albumArtUrl!,
                      width: 40.0,
                      height: 40.0,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 40.0,
                          height: 40.0,
                          color: Colors.grey[700],
                          child: const Icon(Icons.music_note, size: 20.0),
                        );
                      },
                    ),
                  )
                : Container(
                    width: 40.0,
                    height: 40.0,
                    color: Colors.grey[700],
                    child: const Icon(Icons.music_note, size: 20.0),
                  ),
            title: Text(
              song.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              song.artist,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Text('\$${song.currentPrice.toStringAsFixed(2)}'),
            onTap: () {
              widget.onSongSelected(song);
              setState(() {
                _controller.text = '${song.name} - ${song.artist}';
                _searchQuery = _controller.text;
                _showSuggestions = false;
                _focusNode.unfocus();
              });
            },
          );
        },
      ),
    );
  }
}
