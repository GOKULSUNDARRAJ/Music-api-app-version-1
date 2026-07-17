import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'create_collaborative_playlist_screen.dart';
import 'join_collaborative_playlist_screen.dart';
import 'collaborative_playlist_details_screen.dart';

class CollaborativePlaylistsScreen extends StatefulWidget {
  const CollaborativePlaylistsScreen({super.key});

  @override
  State<CollaborativePlaylistsScreen> createState() => _CollaborativePlaylistsScreenState();
}

class _CollaborativePlaylistsScreenState extends State<CollaborativePlaylistsScreen> {
  bool _isLoading = true;
  List<dynamic> _playlists = [];

  @override
  void initState() {
    super.initState();
    _fetchPlaylists();
  }

  Future<void> _fetchPlaylists() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      if (token == null) return;
      
      final response = await http.get(
        Uri.parse('https://music-app-api-1.onrender.com/api/user/collaborative-playlists'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == true) {
          setState(() {
            _playlists = data['playlists'];
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching collaborative playlists: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _createPlaylist() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateCollaborativePlaylistScreen(
          onCreated: _fetchPlaylists,
        ),
      ),
    );
  }

  void _joinPlaylist() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => JoinCollaborativePlaylistScreen(
          onJoined: _fetchPlaylists,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.people_alt, size: 80, color: Colors.white24),
          const SizedBox(height: 20),
          const Text(
            'No Collaborative Playlists Yet',
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            'Create or join one to start building a playlist with friends.',
            style: TextStyle(color: Colors.white54, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: _createPlaylist,
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text('Create', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEB1C24),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
              const SizedBox(width: 16),
              OutlinedButton.icon(
                onPressed: _joinPlaylist,
                icon: const Icon(Icons.group_add, color: Colors.white),
                label: const Text('Join', style: TextStyle(color: Colors.white)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white54),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF181A20),
        elevation: 0,
        title: const Text('Collaborative Playlists', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: const Color(0xFF282828),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (context) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.add_circle_outline, color: Colors.white),
                      title: const Text('Create a playlist', style: TextStyle(color: Colors.white)),
                      onTap: () {
                        Navigator.pop(context);
                        _createPlaylist();
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.group_add, color: Colors.white),
                      title: const Text('Join a playlist', style: TextStyle(color: Colors.white)),
                      onTap: () {
                        Navigator.pop(context);
                        _joinPlaylist();
                      },
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              );
            },
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFEB1C24)))
          : _playlists.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  color: const Color(0xFFEB1C24),
                  backgroundColor: const Color(0xFF282828),
                  onRefresh: _fetchPlaylists,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _playlists.length,
                    itemBuilder: (context, index) {
                      final playlist = _playlists[index];
                      final isOwner = playlist['isOwner'] == true;
                      
                      return Card(
                        color: const Color(0xFF1E1E1E),
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          leading: Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: const Color(0xFF282828),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: playlist['imageUrl'] != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(playlist['imageUrl'], fit: BoxFit.cover),
                                  )
                                : const Icon(Icons.people_alt, color: Colors.white54, size: 30),
                          ),
                          title: Text(
                            playlist['name'],
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          subtitle: Text(
                            isOwner ? 'Created by you • ${playlist['memberCount']} members' : 'Created by ${playlist['ownerName']} • ${playlist['memberCount']} members',
                            style: const TextStyle(color: Colors.white54, fontSize: 13),
                          ),
                          trailing: const Icon(Icons.chevron_right, color: Colors.white54),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CollaborativePlaylistDetailsScreen(
                                  playlistId: playlist['id'],
                                  playlistName: playlist['name'],
                                  isOwner: isOwner,
                                  inviteCode: playlist['inviteCode'],
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
