import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'models/home_response.dart';
import 'models/artist_category.dart';
import 'main_activity.dart';

class ChooseArtistsScreen extends StatefulWidget {
  const ChooseArtistsScreen({super.key});

  @override
  State<ChooseArtistsScreen> createState() => _ChooseArtistsScreenState();
}

class _ChooseArtistsScreenState extends State<ChooseArtistsScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<ArtistCategory> _allArtists = [];
  final Set<String> _selectedArtistIds = {};
  List<String> _localLikedPlaylistsData = [];

  @override
  void initState() {
    super.initState();
    _fetchArtists();
  }

  Future<void> _fetchArtists() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load currently liked items so we don't overwrite existing
      _localLikedPlaylistsData = prefs.getStringList('local_liked_playlists_data') ?? [];
      for (var item in _localLikedPlaylistsData) {
        try {
          final decoded = json.decode(item);
          final category = ArtistCategory.fromJson(decoded);
          if (category.adapterType == 2 && category.categoryId != null) {
            _selectedArtistIds.add(category.categoryId!);
          }
        } catch (_) {}
      }

      final token = prefs.getString('access_token') ?? '';
      final authHeader = token.startsWith('Bearer ') ? token : 'Bearer $token';

      final response = await http.get(
        Uri.parse('https://music-app-api-1.onrender.com/api/artist'),
        headers: {'Authorization': authHeader},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final homeResponse = HomeResponse.fromJson(data);
        
        // Extract all artists from all sections
        final List<ArtistCategory> artists = [];
        for (var section in homeResponse.sections) {
          for (var category in section.categories) {
            // Avoid duplicates
            if (!artists.any((a) => a.categoryId == category.categoryId)) {
              artists.add(category);
            }
          }
        }

        if (mounted) {
          setState(() {
            _allArtists = artists;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = 'Failed to load artists';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Network Error';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleArtist(ArtistCategory artist) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      if (_selectedArtistIds.contains(artist.categoryId)) {
        _selectedArtistIds.remove(artist.categoryId);
        // Remove from list
        _localLikedPlaylistsData.removeWhere((item) {
          try {
            final decoded = json.decode(item);
            return decoded['categoryId'].toString() == artist.categoryId && decoded['adapterType'] == 2;
          } catch (_) {
            return false;
          }
        });
      } else {
        _selectedArtistIds.add(artist.categoryId!);
        // Add to list
        artist.adapterType = 2; // Force to artist
        _localLikedPlaylistsData.add(json.encode(artist.toJson()));
      }
    });
    // Save to shared prefs instantly
    await prefs.setStringList('local_liked_playlists_data', _localLikedPlaylistsData);
  }

  void _finish() {
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainActivity()));
  }

  Widget _buildArtistCircle(ArtistCategory artist) {
    final isSelected = _selectedArtistIds.contains(artist.categoryId);
    return GestureDetector(
      onTap: () => _toggleArtist(artist),
      child: Column(
        children: [
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? const Color(0xFFEB1C24) : Colors.transparent,
                      width: 3,
                    ),
                    image: DecorationImage(
                      image: CachedNetworkImageProvider(artist.categoryImage ?? ''),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                if (isSelected)
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withOpacity(0.5),
                    ),
                    child: const Center(
                      child: Icon(Icons.check, color: Colors.white, size: 40),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            artist.categoryName ?? 'Unknown',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (isSelected)
            const Text(
              'Following',
              style: TextStyle(
                color: Color(0xFFEB1C24),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            )
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
        title: const Text('Choose Artists', style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: _finish,
            child: Text(
              _selectedArtistIds.isEmpty ? 'Skip' : 'Done',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFEB1C24)))
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_errorMessage!, style: const TextStyle(color: Colors.white)),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _isLoading = true;
                            _errorMessage = null;
                          });
                          _fetchArtists();
                        },
                        child: const Text('Retry', style: TextStyle(color: Color(0xFFEB1C24))),
                      ),
                      TextButton(
                        onPressed: _finish,
                        child: const Text('Skip for now', style: TextStyle(color: Colors.white70)),
                      )
                    ],
                  ),
                )
              : Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      child: Text(
                        'Follow your favorite artists to personalize your library.',
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      child: GridView.builder(
                        padding: const EdgeInsets.all(20),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 0.75,
                          crossAxisSpacing: 15,
                          mainAxisSpacing: 15,
                        ),
                        itemCount: _allArtists.length,
                        itemBuilder: (context, index) {
                          return _buildArtistCircle(_allArtists[index]);
                        },
                      ),
                    ),
                    // Optional bottom button
                    if (_selectedArtistIds.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: InkWell(
                          onTap: _finish,
                          borderRadius: BorderRadius.circular(100),
                          child: Container(
                            width: double.infinity,
                            height: 50,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEB1C24),
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: const Center(
                              child: Text(
                                'Continue',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
    );
  }
}
