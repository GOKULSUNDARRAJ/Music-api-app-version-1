import 'package:flutter/material.dart';
import '../models/audio_model.dart';
import '../services/audio_service.dart';
import '../services/download_service.dart';
import '../services/database_service.dart';
import 'add_to_playlist_sheet.dart';
import '../aruvi_code_generator_sheet.dart';
import 'package:cached_network_image/cached_network_image.dart';

class SongOptionsSheet extends StatefulWidget {
  final AudioModel song;

  const SongOptionsSheet({super.key, required this.song});

  @override
  State<SongOptionsSheet> createState() => _SongOptionsSheetState();
}

class _SongOptionsSheetState extends State<SongOptionsSheet> {
  bool _isLiked = false;
  bool _isDownloaded = false;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    if (widget.song.songId != null) {
      final isLiked = await DatabaseService().isSongLiked(widget.song.songId!);
      final isDownloaded = await DatabaseService().isDownloaded(widget.song.songId!);
      if (mounted) {
        setState(() {
          _isLiked = isLiked;
          _isDownloaded = isDownloaded;
        });
      }
    }
  }

  Future<void> _toggleLike() async {
    if (widget.song.songId == null) return;
    
    setState(() {
      _isLiked = !_isLiked;
    });

    if (_isLiked) {
      await DatabaseService().likeSong(widget.song);
    } else {
      await DatabaseService().unlikeSong(widget.song.songId!);
    }
  }

  void _showAriviCode(BuildContext context) {
    Navigator.pop(context); // Close this sheet
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (context) => AruviCodeGeneratorSheet(
        categoryId: widget.song.songId ?? 'unknown',
        title: widget.song.audioName ?? 'Unknown Song',
        imageUrl: widget.song.imageUrl ?? '',
      ),
    );
  }

  void _showAddToPlaylist(BuildContext context) {
    Navigator.pop(context); // Close this sheet
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => AddToPlaylistSheet(song: widget.song),
    );
  }

  Widget _buildOptionTile(IconData icon, String title, VoidCallback onTap, {Color iconColor = Colors.white}) {
    return ListTile(
      leading: Icon(icon, color: iconColor, size: 28),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 16),
      ),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with Cover Art
          Padding(
            padding: const EdgeInsets.only(top: 20, left: 20, right: 20, bottom: 10),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: widget.song.imageUrl ?? '',
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                    errorWidget: (context, error, stackTrace) => Container(
                      width: 100,
                      height: 100,
                      color: Colors.grey[800],
                      child: const Icon(Icons.music_note, color: Colors.white54, size: 50),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.song.audioName ?? 'Unknown Song',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          
          const Divider(color: Colors.white24, height: 1),
          
          // Options List
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              children: [
                _buildOptionTile(
                  _isLiked ? Icons.favorite : Icons.favorite_border,
                  _isLiked ? 'Liked' : 'Like',
                  () {
                    _toggleLike();
                    Navigator.pop(context);
                  },
                  iconColor: _isLiked ? const Color(0xFFEB1C24) : Colors.white,
                ),
                _buildOptionTile(Icons.play_arrow, 'Play', () {
                  Navigator.pop(context);
                  AudioService().playSongs([widget.song], initialIndex: 0, playlistName: widget.song.categoryName ?? 'Song');
                }),
                _buildOptionTile(Icons.queue_music, 'Add to Playlist', () => _showAddToPlaylist(context)),
                _buildOptionTile(
                  _isDownloaded ? Icons.download_done : Icons.download_outlined,
                  _isDownloaded ? 'Remove from download' : 'Download',
                  () async {
                    Navigator.pop(context);
                    if (_isDownloaded) {
                      await DownloadService().removeSingleSong(widget.song);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Removed from downloads'), backgroundColor: Colors.red),
                        );
                      }
                    } else {
                      await DownloadService().downloadSingleSong(widget.song);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Downloading...'), backgroundColor: Colors.green),
                        );
                      }
                    }
                  },
                  iconColor: _isDownloaded ? Colors.green : Colors.white,
                ),
                _buildOptionTile(Icons.reply, 'Share', () {
                  Navigator.pop(context);
                }),
                _buildOptionTile(Icons.playlist_add, 'Add to Queue', () {
                  Navigator.pop(context);
                  // TODO: Implement Queue logic in AudioService
                }),
                _buildOptionTile(Icons.graphic_eq, 'Show Arivi Code', () => _showAriviCode(context)),
              ],
            ),
          ),
          
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
