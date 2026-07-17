import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'models/playlist_section.dart';
import 'models/artist_category.dart';
import 'playlist_screen.dart';
import 'services/audio_service.dart';

class SectionSeeAllScreen extends StatelessWidget {
  final PlaylistSection section;

  const SectionSeeAllScreen({super.key, required this.section});

  Widget _buildImage(String? imageUrl, {bool isCircle = false, double borderRadius = 6.0}) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(isCircle ? 100 : borderRadius),
        ),
        child: const Center(
          child: Icon(Icons.music_note, color: Colors.white54, size: 30),
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(isCircle ? 100 : borderRadius),
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: const Color(0xFF1E1E1E),
        ),
        errorWidget: (context, url, error) => Container(
          color: const Color(0xFF1E1E1E),
          child: const Center(
            child: Icon(Icons.music_note, color: Colors.white54, size: 30),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Text(
          section.sectionTitle ?? 'See All',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.85,
          crossAxisSpacing: 16,
          mainAxisSpacing: 24,
        ),
        itemCount: section.categories.length,
        itemBuilder: (context, index) {
          final category = section.categories[index];
          final isArtist = category.adapterType == 2;
          
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PlaylistScreen(
                    title: category.categoryName ?? 'Unknown',
                    subtitle: category.songs.isNotEmpty ? '${category.songs.length} Songs' : (isArtist ? 'Artist' : 'Album'),
                    imageUrl: category.categoryImage ?? '',
                    categoryId: category.categoryId?.toString() ?? '',
                    songs: category.songs,
                    isArtist: isArtist,
                  ),
                ),
              );
            },
            child: Column(
              crossAxisAlignment: isArtist ? CrossAxisAlignment.center : CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: SizedBox(
                    width: double.infinity,
                    child: _buildImage(category.categoryImage, isCircle: isArtist),
                  ),
                ),
                const SizedBox(height: 10),
                AnimatedBuilder(
                  animation: AudioService(),
                  builder: (context, child) {
                    final audioService = AudioService();
                    final isActive = audioService.currentSong != null && 
                        (audioService.currentSong?.categoryId == category.categoryId?.toString() || 
                         audioService.currentSong?.categoryName == category.categoryName);
                    return SizedBox(
                      width: double.infinity,
                      child: Text(
                        category.categoryName ?? 'Unknown',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: isArtist ? TextAlign.center : TextAlign.start,
                        style: TextStyle(
                          color: isActive ? const Color(0xFFEB1C24) : Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }
                ),
                if (category.songs.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  SizedBox(
                    width: double.infinity,
                    child: Text(
                      '${category.songs.length} Songs',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: isArtist ? TextAlign.center : TextAlign.start,
                      style: const TextStyle(
                        color: Color(0xFFAAAAAA),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ] else if (isArtist) ...[
                  const SizedBox(height: 2),
                  const SizedBox(
                    width: double.infinity,
                    child: Text(
                      'Artist',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFFAAAAAA),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ]
              ],
            ),
          );
        },
      ),
    );
  }
}
