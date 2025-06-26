import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import '../models/song.dart';

class AudioPlayerService {
  // Singleton pattern
  static final AudioPlayerService _instance = AudioPlayerService._internal();
  factory AudioPlayerService() => _instance;

  // Audio player instance
  final AudioPlayer _audioPlayer = AudioPlayer();

  // Current state
  Song? _currentSong;
  bool _isPlaying = false;
  bool _isLoading = false;

  // Stream controllers for state updates
  final StreamController<bool> _playingStateController =
      StreamController<bool>.broadcast();
  final StreamController<bool> _loadingStateController =
      StreamController<bool>.broadcast();
  final StreamController<Song?> _currentSongController =
      StreamController<Song?>.broadcast();
  final StreamController<String?> _errorController =
      StreamController<String?>.broadcast();

  AudioPlayerService._internal() {
    _setupPlayerListeners();
  }

  // Getters for current state
  Song? get currentSong => _currentSong;
  bool get isPlaying => _isPlaying;
  bool get isLoading => _isLoading;

  // Stream getters for UI updates
  Stream<bool> get playingStateStream => _playingStateController.stream;
  Stream<bool> get loadingStateStream => _loadingStateController.stream;
  Stream<Song?> get currentSongStream => _currentSongController.stream;
  Stream<String?> get errorStream => _errorController.stream;

  void _setupPlayerListeners() {
    _audioPlayer.onPlayerStateChanged.listen((PlayerState state) {
      final wasPlaying = _isPlaying;
      _isPlaying = state == PlayerState.playing;

      if (wasPlaying != _isPlaying) {
        _playingStateController.add(_isPlaying);
      }

      // Handle loading state
      final wasLoading = _isLoading;
      _isLoading = state == PlayerState.playing || state == PlayerState.paused;

      if (wasLoading != _isLoading && state != PlayerState.playing) {
        _isLoading = false;
        _loadingStateController.add(_isLoading);
      }
    });

    _audioPlayer.onPlayerComplete.listen((_) {
      _isPlaying = false;
      _playingStateController.add(false);
    });
  }

  // Play a song
  Future<bool> playSong(Song song) async {
    try {
      print('🎵 Attempting to play: "${song.name}" by ${song.artist}');
      print('🎵 Preview URL: ${song.previewUrl ?? "NULL"}');

      // Check if song has a preview URL
      if (song.previewUrl == null || song.previewUrl!.isEmpty) {
        print('❌ No preview URL available for "${song.name}"');
        _errorController.add('No preview available for this song');
        return false;
      }

      // Set loading state
      _isLoading = true;
      _loadingStateController.add(true);

      // Stop current playback if any
      await _audioPlayer.stop();

      // Set current song
      _currentSong = song;
      _currentSongController.add(song);

      // Play the preview
      print('🎵 Starting audio playback for: ${song.previewUrl}');
      await _audioPlayer.play(UrlSource(song.previewUrl!));

      print('✅ Successfully started playing "${song.name}"');
      _isLoading = false;
      _loadingStateController.add(false);

      return true;
    } catch (e) {
      print('❌ Failed to play "${song.name}": ${e.toString()}');
      _isLoading = false;
      _loadingStateController.add(false);
      _errorController.add('Failed to play song: ${e.toString()}');
      return false;
    }
  }

  // Pause current playback
  Future<void> pause() async {
    try {
      await _audioPlayer.pause();
    } catch (e) {
      _errorController.add('Failed to pause: ${e.toString()}');
    }
  }

  // Resume current playback
  Future<void> resume() async {
    try {
      await _audioPlayer.resume();
    } catch (e) {
      _errorController.add('Failed to resume: ${e.toString()}');
    }
  }

  // Stop current playback
  Future<void> stop() async {
    try {
      await _audioPlayer.stop();
      _currentSong = null;
      _currentSongController.add(null);
    } catch (e) {
      _errorController.add('Failed to stop: ${e.toString()}');
    }
  }

  // Toggle play/pause
  Future<void> togglePlayPause() async {
    if (_isPlaying) {
      await pause();
    } else if (_currentSong != null) {
      await resume();
    }
  }

  // Check if a specific song is currently playing
  bool isSongPlaying(Song song) {
    return _currentSong?.id == song.id && _isPlaying;
  }

  // Check if a specific song is currently loaded (playing or paused)
  bool isSongLoaded(Song song) {
    return _currentSong?.id == song.id;
  }

  // Dispose resources
  void dispose() {
    _audioPlayer.dispose();
    _playingStateController.close();
    _loadingStateController.close();
    _currentSongController.close();
    _errorController.close();
  }
}
