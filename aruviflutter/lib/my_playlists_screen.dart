import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/playlist_section.dart';
import 'models/artist_category.dart';
import 'playlist_screen.dart';
import 'services/audio_service.dart';

class MyPlaylistsScreen extends StatefulWidget {
  const MyPlaylistsScreen({super.key});

  @override
  State<MyPlaylistsScreen> createState() => _MyPlaylistsScreenState();
}

class _MyPlaylistsScreenState extends State<MyPlaylistsScreen> {
  bool _isLoading = true;
  List<ArtistCategory> _playlistItems = [];

  @override
  void initState() {
    super.initState();
    _fetchPlaylistItems();
  }

  Future<void> _fetchPlaylistItems() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final addedListStr = prefs.getStringList('local_added_playlists_data') ?? [];
      
      final List<ArtistCategory> loadedItems = [];
      for (var item in addedListStr) {
        try {
          final decoded = json.decode(item);
          loadedItems.add(ArtistCategory.fromJson(decoded));
        } catch (e) {
          debugPrint('Error parsing added playlist: $e');
        }
      }

      if (mounted) {
        setState(() {
          _playlistItems = loadedItems.reversed.toList(); // Newest first
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Failed to load local playlist items: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildGridCardItem(BuildContext context, ArtistCategory category) {
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
            ),
          ),
        );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF151515),
      appBar: AppBar(
        backgroundColor: const Color(0xFF151515),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'My Playlist',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFEB1C24)))
          : _playlistItems.isEmpty
              ? const Center(
                  child: Text(
                    'No items in your playlist.',
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
                  itemCount: _playlistItems.length,
                  itemBuilder: (context, index) {
                    return _buildGridCardItem(context, _playlistItems[index]);
                  },
                ),
    );
  }
}
