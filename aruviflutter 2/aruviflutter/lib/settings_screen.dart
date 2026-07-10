import 'package:flutter/material.dart';
import 'services/audio_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Settings', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.headset_mic_outlined, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: AudioService(),
        builder: (context, child) {
          final audioService = AudioService();
          final durationSeconds = audioService.clipDuration.inSeconds.toDouble();

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Clip Settings',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    const Icon(Icons.access_time, color: Color(0xFFEB1C24)),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        'Default Clip Duration',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                    Text(
                      '${durationSeconds.toInt()}s',
                      style: const TextStyle(
                        color: Color(0xFFEB1C24),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'Duration (seconds)',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 8),
                SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 2.0,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
                    activeTrackColor: const Color(0xFFEB1C24),
                    inactiveTrackColor: Colors.grey.shade800,
                    thumbColor: const Color(0xFFEB1C24),
                    overlayColor: const Color(0xFFEB1C24).withValues(alpha: 0.2),
                  ),
                  child: Slider(
                    value: durationSeconds,
                    min: 5,
                    max: 100,
                    divisions: 95,
                    onChanged: (value) {
                      audioService.setClipDuration(Duration(seconds: value.toInt()));
                    },
                  ),
                ),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('5s', style: TextStyle(color: Colors.white54, fontSize: 12)),
                    Text('100s', style: TextStyle(color: Colors.white54, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'When clip mode is activated, it will loop the selected duration from your current position',
                  style: TextStyle(color: Colors.white54, fontSize: 14),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
