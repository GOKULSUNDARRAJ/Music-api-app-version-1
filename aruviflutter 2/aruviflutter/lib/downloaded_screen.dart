import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'models/artist_category.dart';
import 'models/audio_model.dart';
import 'services/database_service.dart';
import 'playlist_screen.dart';
import 'services/audio_service.dart';
import 'widgets/song_options_sheet.dart';

class DownloadedScreen extends StatefulWidget {
  const DownloadedScreen({super.key});

  @override
  State<DownloadedScreen> createState() => _DownloadedScreenState();
}

class _DownloadedScreenState extends State<DownloadedScreen> {
  bool _isLoadingPlaylists = true;
  bool _isLoadingSongs = true;
  List<ArtistCategory> _downloadedPlaylists = [];
  List<AudioModel> _downloadedSongs = [];

  @override
  void initState() {
    super.initState();
    _fetchDownloadedPlaylists();
    _fetchDownloadedSongs();
  }

  Future<void> _fetchDownloadedPlaylists() async {
    final playlists = await DatabaseService().getDownloadedPlaylists();
    setState(() {
      _downloadedPlaylists = playlists;
      _isLoadingPlaylists = false;
    });
  }

  Future<void> _fetchDownloadedSongs() async {
    final songs = await DatabaseService().getAllDownloads();
    setState(() {
      _downloadedSongs = songs;
      _isLoadingSongs = false;
    });
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
              title: category.categoryName ?? 'Unknown Playlist',
              subtitle: '${category.songs.length} Songs',
              songs: category.songs,
              isLocal: true,
            ),
          ),
        ).then((_) {
          _fetchDownloadedPlaylists();
        });
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: FutureBuilder<String>(
                future: () async {
                  final dir = await getApplicationDocumentsDirectory();
                  final file = File('${dir.path}/playlist_${category.categoryId}.jpg');
                  if (file.existsSync()) {
                    return file.path;
                  }
                  return '';
                }(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Container(color: Colors.grey[800]);
                  }
                  final localPath = snapshot.data ?? '';
                  if (localPath.isNotEmpty) {
                    return Image.file(
                      File(localPath),
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey[800],
                        child: const Center(child: Icon(Icons.broken_image, color: Colors.white54)),
                      ),
                    );
                  }
                  return Image.network(
                    category.categoryImage ?? '',
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey[800],
                      child: const Center(child: Icon(Icons.broken_image, color: Colors.white54)),
                    ),
                  );
                }
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
        child: FutureBuilder<String>(
          future: () async {
            // Check if we have a local playlist cover, otherwise use song's image URL
            if (song.categoryId != null) {
              final dir = await getApplicationDocumentsDirectory();
              final file = File('${dir.path}/playlist_${song.categoryId}.jpg');
              if (file.existsSync()) {
                return file.path;
              }
            }
            return '';
          }(),
          builder: (context, snapshot) {
            final localPath = snapshot.data ?? '';
            if (localPath.isNotEmpty) {
              return Image.file(
                File(localPath),
                width: 50,
                height: 50,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 50,
                  height: 50,
                  color: Colors.grey[800],
                  child: const Icon(Icons.music_note, color: Colors.white54),
                ),
              );
            }
            return Image.network(
              song.imageUrl ?? '',
              width: 50,
              height: 50,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 50,
                height: 50,
                color: Colors.grey[800],
                child: const Icon(Icons.music_note, color: Colors.white54),
              ),
            );
          },
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
            _fetchDownloadedSongs(); // Refresh on return in case of deletion
          });
        },
      ),
      onTap: () {
        AudioService().playSongs(_downloadedSongs, initialIndex: index, playlistName: 'Downloaded Songs');
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
          title: const Text('Downloaded', style: TextStyle(color: Colors.white)),
          iconTheme: const IconThemeData(color: Colors.white),
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
                : _downloadedSongs.isEmpty
                    ? const Center(
                        child: Text(
                          'No downloaded songs yet.',
                          style: TextStyle(color: Colors.white54, fontSize: 16),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _downloadedSongs.length,
                        itemBuilder: (context, index) {
                          return _buildSongRow(context, _downloadedSongs[index], index);
                        },
                      ),

            // Playlists Tab
            _isLoadingPlaylists
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFEB1C24)))
                : _downloadedPlaylists.isEmpty
                    ? const Center(
                        child: Text(
                          'No downloaded playlists yet.',
                          style: TextStyle(color: Colors.white54, fontSize: 16),
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.8, // Adjust to leave room for text
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: _downloadedPlaylists.length,
                        itemBuilder: (context, index) {
                          return _buildPlaylistGridCard(context, _downloadedPlaylists[index]);
                        },
                      ),
          ],
        ),
      ),
    );
  }
}
