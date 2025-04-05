import '../models/song.dart';

class SongService {
  // Mock song data
  static final List<Song> _mockSongs = [
    Song(
      id: '1',
      name: 'Blinding Lights',
      artist: 'The Weeknd',
      genre: 'Pop',
      currentPrice: 45.0,
      previousPrice: 42.5,
      albumArtUrl: 'https://via.placeholder.com/150',
    ),
    Song(
      id: '2',
      name: 'Levitating',
      artist: 'Dua Lipa',
      genre: 'Pop',
      currentPrice: 38.75,
      previousPrice: 40.0,
      albumArtUrl: 'https://via.placeholder.com/150',
    ),
    Song(
      id: '3',
      name: 'Save Your Tears',
      artist: 'The Weeknd',
      genre: 'Pop',
      currentPrice: 32.5,
      previousPrice: 30.0,
      albumArtUrl: 'https://via.placeholder.com/150',
    ),
    Song(
      id: '4',
      name: 'Montero (Call Me By Your Name)',
      artist: 'Lil Nas X',
      genre: 'Hip-Hop',
      currentPrice: 55.0,
      previousPrice: 48.0,
      albumArtUrl: 'https://via.placeholder.com/150',
    ),
    Song(
      id: '5',
      name: 'Peaches',
      artist: 'Justin Bieber',
      genre: 'Pop',
      currentPrice: 28.5,
      previousPrice: 30.0,
      albumArtUrl: 'https://via.placeholder.com/150',
    ),
    Song(
      id: '6',
      name: 'Leave The Door Open',
      artist: 'Silk Sonic',
      genre: 'R&B',
      currentPrice: 42.0,
      previousPrice: 38.5,
      albumArtUrl: 'https://via.placeholder.com/150',
    ),
    Song(
      id: '7',
      name: 'Drivers License',
      artist: 'Olivia Rodrigo',
      genre: 'Pop',
      currentPrice: 60.0,
      previousPrice: 52.5,
      albumArtUrl: 'https://via.placeholder.com/150',
    ),
    Song(
      id: '8',
      name: 'Good 4 U',
      artist: 'Olivia Rodrigo',
      genre: 'Pop Rock',
      currentPrice: 58.25,
      previousPrice: 55.0,
      albumArtUrl: 'https://via.placeholder.com/150',
    ),
    Song(
      id: '9',
      name: 'Kiss Me More',
      artist: 'Doja Cat ft. SZA',
      genre: 'Pop',
      currentPrice: 35.75,
      previousPrice: 33.0,
      albumArtUrl: 'https://via.placeholder.com/150',
    ),
    Song(
      id: '10',
      name: 'Astronaut In The Ocean',
      artist: 'Masked Wolf',
      genre: 'Hip-Hop',
      currentPrice: 25.0,
      previousPrice: 28.0,
      albumArtUrl: 'https://via.placeholder.com/150',
    ),
    Song(
      id: '11',
      name: 'Butter',
      artist: 'BTS',
      genre: 'K-Pop',
      currentPrice: 65.0,
      previousPrice: 58.0,
      albumArtUrl: 'https://via.placeholder.com/150',
    ),
    Song(
      id: '12',
      name: 'Mood',
      artist: '24kGoldn ft. iann dior',
      genre: 'Hip-Hop',
      currentPrice: 30.0,
      previousPrice: 32.5,
      albumArtUrl: 'https://via.placeholder.com/150',
    ),
    Song(
      id: '13',
      name: 'Heartbreak Anniversary',
      artist: 'Giveon',
      genre: 'R&B',
      currentPrice: 40.0,
      previousPrice: 35.0,
      albumArtUrl: 'https://via.placeholder.com/150',
    ),
    Song(
      id: '14',
      name: 'Deja Vu',
      artist: 'Olivia Rodrigo',
      genre: 'Pop',
      currentPrice: 48.0,
      previousPrice: 45.0,
      albumArtUrl: 'https://via.placeholder.com/150',
    ),
    Song(
      id: '15',
      name: 'Dynamite',
      artist: 'BTS',
      genre: 'K-Pop',
      currentPrice: 62.5,
      previousPrice: 60.0,
      albumArtUrl: 'https://via.placeholder.com/150',
    ),
  ];

  // Get all songs
  List<Song> getAllSongs() {
    return List.from(_mockSongs);
  }
  
  // Get song by ID
  Song? getSongById(String id) {
    try {
      return _mockSongs.firstWhere((song) => song.id == id);
    } catch (e) {
      return null;
    }
  }
  
  // Get top songs (by price)
  List<Song> getTopSongs({int limit = 5}) {
    final sortedSongs = List<Song>.from(_mockSongs);
    sortedSongs.sort((a, b) => b.currentPrice.compareTo(a.currentPrice));
    return sortedSongs.take(limit).toList();
  }
  
  // Get top movers (by percentage change)
  List<Song> getTopMovers({int limit = 5}) {
    final sortedSongs = List<Song>.from(_mockSongs);
    sortedSongs.sort((a, b) => b.priceChangePercent.abs().compareTo(a.priceChangePercent.abs()));
    return sortedSongs.take(limit).toList();
  }
  
  // Get songs by artist
  List<Song> getSongsByArtist(String artist) {
    return _mockSongs.where((song) => song.artist == artist).toList();
  }
  
  // Get unique artists
  List<String> getUniqueArtists() {
    final artists = _mockSongs.map((song) => song.artist).toSet().toList();
    return artists;
  }
  
  // Get rising artists (artists with highest average price increase)
  List<String> getRisingArtists({int limit = 5}) {
    final artistMap = <String, List<Song>>{};
    
    // Group songs by artist
    for (final song in _mockSongs) {
      if (!artistMap.containsKey(song.artist)) {
        artistMap[song.artist] = [];
      }
      artistMap[song.artist]!.add(song);
    }
    
    // Calculate average price change for each artist
    final artistChanges = <String, double>{};
    artistMap.forEach((artist, songs) {
      double totalChange = 0;
      for (final song in songs) {
        totalChange += song.priceChangePercent;
      }
      artistChanges[artist] = totalChange / songs.length;
    });
    
    // Sort artists by average price change
    final sortedArtists = artistChanges.keys.toList();
    sortedArtists.sort((a, b) => artistChanges[b]!.compareTo(artistChanges[a]!));
    
    return sortedArtists.take(limit).toList();
  }
}
