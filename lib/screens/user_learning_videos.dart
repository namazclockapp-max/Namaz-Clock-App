import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

class UserLearningVideos extends StatefulWidget {
  const UserLearningVideos({super.key});

  @override
  State<UserLearningVideos> createState() => _UserLearningVideosState();
}

class _UserLearningVideosState extends State<UserLearningVideos> {
  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color secondaryGreen = Color(0xFF4CAF50);
  static const Color lightGreen = Color(0xFF81C784);
  static const Color darkGreen = Color(0xFF1B5E20);
  static const Color accentGreen = Color(0xFF66BB6A);

  String? _playingVideoId;
  YoutubePlayerController? _youtubeController;

  @override
  void dispose() {
    _youtubeController?.close();
    super.dispose();
  }

  void _toggleVideo(String videoUrl) {
    final videoId = YoutubePlayerController.convertUrlToId(videoUrl);
    if (videoId == null) return;

    setState(() {
      if (_playingVideoId == videoId) {
        // Agar wahi video dubara tap hui to collapse
        _playingVideoId = null;
        _youtubeController?.close();
        _youtubeController = null;
      } else {
        // Nayi video play karni hai
        _playingVideoId = videoId;
        _youtubeController?.close();
        _youtubeController = YoutubePlayerController.fromVideoId(
          videoId: videoId,
          autoPlay: true,
          params: const YoutubePlayerParams(showFullscreenButton: true),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    const videoUrl = "https://www.youtube.com/watch?v=Tm5-CHxQMOk";
    final videoId = YoutubePlayerController.convertUrlToId(videoUrl);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryGreen,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Learning Videos',
          style: TextStyle(color: Colors.white),
        ),
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
                'User Learning Videos',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: darkGreen,
                    ),
              ),
              const SizedBox(height: 24),

              // Video Card
              InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  _toggleVideo(videoUrl);
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: lightGreen.withOpacity(0.2), width: 1),
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
                      const Icon(Icons.play_circle_outline,
                          color: primaryGreen, size: 40),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "How To Use",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: darkGreen,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Learn about the flow of the app",
                              style: TextStyle(
                                  fontSize: 14,
                                  color: primaryGreen.withOpacity(0.7)),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        _playingVideoId == videoId
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: primaryGreen,
                      )
                    ],
                  ),
                ),
              ),

              // Show video below when tapped
              if (_playingVideoId == videoId && _youtubeController != null) ...[
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: YoutubePlayer(controller: _youtubeController!),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () async {
                    final url = Uri.parse(videoUrl);
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url,
                          mode: LaunchMode.externalApplication);
                    }
                  },
                  icon: const Icon(Icons.open_in_new, color: primaryGreen),
                  label: const Text(
                    "Watch on YouTube",
                    style: TextStyle(color: primaryGreen),
                  ),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}
