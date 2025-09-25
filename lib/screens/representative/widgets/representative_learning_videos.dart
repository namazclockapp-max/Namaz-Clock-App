import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

class RepresentativeLearningVideos extends StatefulWidget {
  const RepresentativeLearningVideos({super.key});

  @override
  State<RepresentativeLearningVideos> createState() => _RepresentativeLearningVideosState();
}

class _RepresentativeLearningVideosState extends State<RepresentativeLearningVideos> {
  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color secondaryGreen = Color(0xFF4CAF50);
  static const Color lightGreen = Color(0xFF81C784);
  static const Color darkGreen = Color(0xFF1B5E20);
  static const Color accentGreen = Color(0xFF66BB6A);

  String? _playingVideoId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryGreen,
        title: const Text(
          'Learning Videos',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFE8F5E8),
              Color(0xFFF1F8E9),
              Color(0xFFE8F5E8),
              Colors.white,
            ],
            stops: [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                'Representative Learning Videos',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: darkGreen,
                    ),
              ),
              const SizedBox(height: 24),
              _buildVideoCard(
                context,
                title: 'How to Manage Masjids',
                description: 'Learn to add, edit, or remove masjids effectively.',
                videoUrl: 'https://youtube.com/shorts/uotqhe2emUQ',
              ),
              const SizedBox(height: 16),
              _buildVideoCard(
                context,
                title: 'How To Manage Event',
                description: 'Learn to add events.',
                videoUrl: 'https://youtube.com/shorts/j4tCbsasFQ4',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideoCard(BuildContext context,
      {required String title, required String description, required String videoUrl}) {
    final videoId = YoutubePlayerController.convertUrlToId(videoUrl);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            setState(() {
              _playingVideoId = videoId;
            });
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: lightGreen.withOpacity(0.2), width: 1),
              boxShadow: [
                BoxShadow(
                  color: primaryGreen.withOpacity(0.08),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.play_circle_outline, color: primaryGreen, size: 40),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: darkGreen)),
                      const SizedBox(height: 4),
                      Text(description,
                          style: TextStyle(
                              fontSize: 14, color: primaryGreen.withOpacity(0.7))),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: primaryGreen),
              ],
            ),
          ),
        ),
        if (_playingVideoId == videoId) ...[
          const SizedBox(height: 12),
          AspectRatio(
            aspectRatio: 16 / 9,
            child: YoutubePlayer(
              controller: YoutubePlayerController.fromVideoId(
                videoId: videoId ?? '',
                autoPlay: true,
                params: const YoutubePlayerParams(showFullscreenButton: true),
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () async {
              final url = Uri.parse(videoUrl);
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              }
            },
            icon: const Icon(Icons.open_in_new, color: primaryGreen),
            label: const Text("Watch on YouTube",
                style: TextStyle(color: primaryGreen)),
          ),
          const SizedBox(height: 16),
        ]
      ],
    );
  }
}
