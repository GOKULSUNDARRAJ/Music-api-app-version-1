import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/playlist_section.dart';
import 'models/artist_category.dart';
import 'models/audio_model.dart';
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

      // Background sync for dynamic playlists (like blends)
      _backgroundSyncDynamicPlaylists(loadedItems);
    } catch (e) {
      debugPrint('Failed to load local playlist items: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _backgroundSyncDynamicPlaylists(List<ArtistCategory> playlists) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token') ?? '';
      if (token.isEmpty) return;

      bool cacheUpdated = false;
      final addedListStr = prefs.getStringList('local_added_playlists_data') ?? [];

      for (var i = 0; i < playlists.length; i++) {
        final category = playlists[i];
        if (category.categoryId != null && category.categoryId!.startsWith('blend_')) {
          final blendId = category.categoryId!.replaceAll('blend_', '');
          final url = Uri.parse('https://music-app-api-1.onrender.com/api/user/blend/$blendId');
          
          final response = await http.get(url, headers: {'Authorization': 'Bearer $token'});
          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            if (data['status'] == true) {
              final List<dynamic> songsData = data['data'] ?? [];
              final latestSongs = songsData.map((s) => AudioModel.fromJson(s)).toList();
              
              if (latestSongs.length != category.songs?.length || 
                  _songsListChanged(latestSongs, category.songs ?? [])) {
                
                category.songs = latestSongs;
                
                final index = addedListStr.indexWhere((item) {
                  try { return json.decode(item)['categoryId'] == category.categoryId; } catch (_) { return false; }
                });
                
                if (index != -1) {
                  addedListStr[index] = json.encode(category.toJson());
                  cacheUpdated = true;
                }
              }
            }
          }
        }
      }

      if (cacheUpdated) {
        await prefs.setStringList('local_added_playlists_data', addedListStr);
      }
    } catch (e) {
      debugPrint('Failed background sync: $e');
    }
  }

  bool _songsListChanged(List<AudioModel> list1, List<AudioModel> list2) {
    if (list1.length != list2.length) return true;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i].songId != list2[i].songId) return true;
    }
    return false;
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
