import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'services/audio_service.dart';
import 'models/audio_model.dart';
import 'widgets/song_options_sheet.dart';

class QueueScreen extends StatelessWidget {
  const QueueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle bar
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Queue',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(color: Colors.white24, height: 1),
          Expanded(
            child: AnimatedBuilder(
        animation: AudioService(),
        builder: (context, child) {
          final audioService = AudioService();
          final currentSong = audioService.currentSong;
          final queue = audioService.queue;
          final upcoming = audioService.upcomingPlaylist;
          final playlistName = audioService.currentPlaylistName ?? 'Playlist';

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (currentSong != null) ...[
                  const Text(
                    'Now Playing',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildSongTile(context, currentSong, isPlaying: true),
                  const SizedBox(height: 32),
                ],

                if (queue.isNotEmpty) ...[
                  const Text(
                    'Next in queue',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ...queue.map((song) => _buildSongTile(context, song)).toList(),
                  const SizedBox(height: 32),
                ],

                if (upcoming.isNotEmpty) ...[
                  Text(
                    'Next from: $playlistName',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ...upcoming.map((song) => _buildSongTile(context, song)).toList(),
                  const SizedBox(height: 32),
                ],
              ],
            ),
          );
        },
      ),
    ),
        ],
      ),
    );
  }

  Widget _buildSongTile(BuildContext context, AudioModel song, {bool isPlaying = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: song.imageUrl != null && song.imageUrl!.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: song.imageUrl!,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) => _buildPlaceholder(),
                  )
                : _buildPlaceholder(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  song.audioName ?? 'Unknown Title',
                  style: TextStyle(
                    color: isPlaying ? const Color(0xFF1DB954) : Colors.white, // Spotify green for playing
                    fontSize: 16,
                    fontWeight: isPlaying ? FontWeight.bold : FontWeight.normal,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  song.categoryName ?? 'Unknown Artist',
                  style: const TextStyle(color: Colors.white54, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white54),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                isScrollControlled: true,
                builder: (context) => SongOptionsSheet(song: song),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 50,
      height: 50,
      color: Colors.grey.shade800,
      child: const Icon(Icons.music_note, color: Colors.white24),
    );
  }
}
