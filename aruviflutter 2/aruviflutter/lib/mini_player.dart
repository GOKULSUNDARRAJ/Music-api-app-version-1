import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:marquee/marquee.dart';
import 'package:palette_generator/palette_generator.dart';

class MiniPlayer extends StatefulWidget {
  final bool isBluetoothConnected;
  final bool isPlaying;
  final double progress;
  final String songTitle;
  final String artistName;
  final String? imageUrl;
  final VoidCallback onPlayPause;
  final VoidCallback onAdd;
  final VoidCallback onTap;
  final VoidCallback? onNext;
  final VoidCallback? onPrevious;
  final bool isAdPlaying;
  final VoidCallback? onLearnMore;

  const MiniPlayer({
    super.key,
    this.isBluetoothConnected = false,
    this.isPlaying = false,
    this.progress = 0.0,
    this.songTitle = 'Song Name',
    this.artistName = 'Artist',
    this.imageUrl,
    required this.onPlayPause,
    required this.onAdd,
    required this.onTap,
    this.onNext,
    this.onPrevious,
    this.isAdPlaying = false,
    this.onLearnMore,
  });

  @override
  State<MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends State<MiniPlayer> {
  Color _backgroundColor = const Color(0xFF828993);

  @override
  void initState() {
    super.initState();
    _updatePalette();
  }

  @override
  void didUpdateWidget(MiniPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _updatePalette();
    }
  }

  Future<void> _updatePalette() async {
    if (widget.imageUrl == null || widget.imageUrl!.isEmpty) {
      if (mounted) setState(() => _backgroundColor = const Color(0xFF828993));
      return;
    }

    try {
      final PaletteGenerator generator = await PaletteGenerator.fromImageProvider(
        CachedNetworkImageProvider(widget.imageUrl!),
        maximumColorCount: 10,
      );
      
      if (generator.dominantColor != null && mounted) {
        setState(() {
          _backgroundColor = _darken(generator.dominantColor!.color, 0.2);
        });
      }
    } catch (e) {
      debugPrint('Failed to extract palette: $e');
      if (mounted) setState(() => _backgroundColor = const Color(0xFF828993));
    }
  }

  Color _darken(Color c, [double amount = .1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(c);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity != null) {
          if (details.primaryVelocity! > 0) {
            // Swiped Right - Previous track
            widget.onPrevious?.call();
          } else if (details.primaryVelocity! < 0) {
            // Swiped Left - Next track
            widget.onNext?.call();
          }
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.isAdPlaying)
            GestureDetector(
              onTap: widget.onLearnMore,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                margin: const EdgeInsets.symmetric(horizontal: 10),
                decoration: const BoxDecoration(
                  color: Color(0xFF905562),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('Learn more', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    Icon(Icons.chevron_right, color: Colors.white, size: 18),
                  ],
                ),
              ),
            ),
          Container(
            height: 55, // 54dp
            decoration: BoxDecoration(
              color: widget.isAdPlaying ? const Color(0xFF1E1E1E) : _backgroundColor, // Dynamic color
              borderRadius: widget.isAdPlaying 
                  ? const BorderRadius.only(bottomLeft: Radius.circular(10), bottomRight: Radius.circular(10)) 
                  : BorderRadius.circular(10),
            ),
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), // Added margin to match CardView style
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Column(
            children: [
              Expanded(
                child: Row(
                  children: [
                    // Album Art
                    Container(
                      width: 42,
                      height: 42,
                      margin: const EdgeInsets.only(left: 10),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(4),
                        image: DecorationImage(
                          image: widget.imageUrl != null && widget.imageUrl!.isNotEmpty
                              ? CachedNetworkImageProvider(widget.imageUrl!) as ImageProvider
                              : const AssetImage('assets/images/video_placholder.png'),
                          fit: BoxFit.cover,
                          onError: (e, s) => debugPrint('MiniPlayer image error: $e'),
                        ),
                      ),
                      child: widget.imageUrl == null || widget.imageUrl!.isEmpty
                          ? const Icon(Icons.music_note, color: Colors.white54)
                          : null,
                    ),
                    
                    const SizedBox(width: 10),

                    // Song Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            height: 18,
                            child: Marquee(
                              text: widget.songTitle,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              scrollAxis: Axis.horizontal,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              blankSpace: 30.0,
                              velocity: 30.0,
                              pauseAfterRound: const Duration(seconds: 2),
                              startPadding: 0.0,
                              accelerationDuration: const Duration(seconds: 1),
                              accelerationCurve: Curves.linear,
                              decelerationDuration: const Duration(milliseconds: 500),
                              decelerationCurve: Curves.easeOut,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.artistName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Bluetooth Icon
                    if (widget.isBluetoothConnected)
                      const Padding(
                        padding: EdgeInsets.only(right: 10),
                        child: Icon(
                          Icons.headphones, // closest to headphones1
                          color: Color(0xFFEB1C24), // bgred
                          size: 24,
                        ),
                      ),

                    // Add Button
                    if (!widget.isAdPlaying)
                      GestureDetector(
                        onTap: widget.onAdd,
                        child: const Padding(
                          padding: EdgeInsets.only(right: 15),
                          child: Icon(
                            Icons.add_circle_outline,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                      ),

                    // Play/Pause Button
                    GestureDetector(
                      onTap: widget.onPlayPause,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 15),
                        child: Icon(
                          widget.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                          color: Colors.white,
                          size: 35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Progress Bar
              LinearProgressIndicator(
                value: widget.progress,
                backgroundColor: widget.isAdPlaying ? const Color(0xFF333333) : _backgroundColor, // Match new bg
                color: widget.isAdPlaying ? Colors.white : const Color(0xFFEB1C24),
                minHeight: 2,
              ),
            ],
          ),
        ),
      ),
      ],
      ),
    );
  }
}
