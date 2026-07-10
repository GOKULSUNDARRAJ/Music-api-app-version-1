import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/playlist_section.dart';
import 'models/artist_category.dart';
import 'models/audio_model.dart';
import 'playlist_screen.dart';
import 'services/audio_service.dart';
import 'services/database_service.dart';
import 'widgets/song_options_sheet.dart';
import 'package:cached_network_image/cached_network_image.dart';

class LikedScreen extends StatefulWidget {
  const LikedScreen({super.key});

  @override
  State<LikedScreen> createState() => _LikedScreenState();
}

class _LikedScreenState extends State<LikedScreen> {
  bool _isLoadingPlaylists = true;
  bool _isLoadingSongs = true;
  List<ArtistCategory> _likedPlaylists = [];
  List<AudioModel> _likedSongs = [];

  @override
  void initState() {
    super.initState();
    _fetchLikedPlaylists();
    _fetchLikedSongs();
  }

  Future<void> _fetchLikedPlaylists() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final likedListStr = prefs.getStringList('local_liked_playlists_data') ?? [];
      
      final List<ArtistCategory> loadedItems = [];
      for (var item in likedListStr) {
        try {
          final decoded = json.decode(item);
          final category = ArtistCategory.fromJson(decoded);
          if (category.adapterType != 2) {
            loadedItems.add(category);
          }
        } catch (e) {
          debugPrint('Error parsing liked item: $e');
        }
      }

      if (mounted) {
        setState(() {
          _likedPlaylists = loadedItems.reversed.toList(); // Newest first
          _isLoadingPlaylists = false;
        });
      }
    } catch (e) {
      debugPrint('Failed to load local liked items: $e');
      if (mounted) setState(() => _isLoadingPlaylists = false);
    }
  }

  Future<void> _fetchLikedSongs() async {
    try {
      final songs = await DatabaseService().getLikedSongs();
      if (mounted) {
        setState(() {
          _likedSongs = songs;
          _isLoadingSongs = false;
        });
      }
    } catch (e) {
      debugPrint('Failed to load liked songs: $e');
      if (mounted) setState(() => _isLoadingSongs = false);
    }
  }

  Widget _buildPlaylistGridCard(BuildContext context, ArtistCategory category) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PlaylistScreen(
              categoryId: category.categoryId ?? '',
              imageUrl: category.categoryImage ?? '',
              title: category.categoryName ?? '',
              subtitle: '',
              songs: category.songs,
              isArtist: category.adapterType == 2,
            ),
          ),
        ).then((_) {
          // Refresh on return
          _fetchLikedPlaylists();
        });
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                category.categoryImage ?? '',
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey[800],
                  child: const Center(child: Icon(Icons.broken_image, color: Colors.white54)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          AnimatedBuilder(
            animation: AudioService(),
            builder: (context, child) {
              final audioService = AudioService();
              final isActive = audioService.currentSong != null && 
                  (audioService.currentSong?.categoryId == category.categoryId?.toString() || 
                   audioService.currentSong?.categoryName == category.categoryName);
              return Text(
                category.categoryName ?? '',
                style: TextStyle(
                  color: isActive ? const Color(0xFFEB1C24) : Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              );
            }
          ),
        ],
      ),
    );
  }

  Widget _buildSongRow(BuildContext context, AudioModel song, int index) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CachedNetworkImage(
          imageUrl: song.imageUrl ?? '',
          width: 50,
          height: 50,
          fit: BoxFit.cover,
          errorWidget: (context, error, stackTrace) => Container(
            width: 50,
            height: 50,
            color: Colors.grey[800],
            child: const Icon(Icons.music_note, color: Colors.white54),
          ),
        ),
      ),
      title: AnimatedBuilder(
        animation: AudioService(),
        builder: (context, child) {
          final isPlaying = AudioService().currentSong?.songId == song.songId;
          return Text(
            song.audioName ?? '',
            style: TextStyle(
              color: isPlaying ? const Color(0xFFEB1C24) : Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          );
        },
      ),
      subtitle: Text(
        song.categoryName ?? '',
        style: const TextStyle(color: Colors.white54, fontSize: 13),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: IconButton(
        icon: const Icon(Icons.more_vert, color: Colors.white54, size: 20),
        onPressed: () {
          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.transparent,
            isScrollControlled: true,
            builder: (context) => SongOptionsSheet(song: song),
          ).then((_) {
            _fetchLikedSongs(); // Refresh on return
          });
        },
      ),
      onTap: () {
        AudioService().playSongs(_likedSongs, initialIndex: index, playlistName: 'Liked Songs');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFF151515),
        appBar: AppBar(
          backgroundColor: const Color(0xFF151515),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Your Likes',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
          bottom: const TabBar(
            indicatorColor: Color(0xFFEB1C24),
            labelColor: Color(0xFFEB1C24),
            unselectedLabelColor: Colors.white54,
            tabs: [
              Tab(text: 'Songs'),
              Tab(text: 'Playlists'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Songs Tab
            _isLoadingSongs
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFEB1C24)))
                : _likedSongs.isEmpty
                    ? const Center(
                        child: Text(
                          'No liked songs yet.',
                          style: TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _likedSongs.length,
                        itemBuilder: (context, index) {
                          return _buildSongRow(context, _likedSongs[index], index);
                        },
                      ),

            // Playlists Tab
            _isLoadingPlaylists
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFEB1C24)))
                : _likedPlaylists.isEmpty
                    ? const Center(
                        child: Text(
                          'No liked playlists yet.',
                          style: TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 0.85,
                        ),
                        itemCount: _likedPlaylists.length,
                        itemBuilder: (context, index) {
                          return _buildPlaylistGridCard(context, _likedPlaylists[index]);
                        },
                      ),
          ],
        ),
      ),
    );
  }
}
