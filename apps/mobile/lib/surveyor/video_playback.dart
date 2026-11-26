// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:google_fonts/google_fonts.dart';
import '../service/language_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../login_page.dart';

class VideoModel {
  final String id;
  final String title;
  final String description;
  final String url;
  final String duration;
  final List<Color> gradientColors;

  VideoModel({
    required this.id,
    required this.title,
    required this.description,
    required this.url,
    required this.duration,
    required this.gradientColors,
  });
}

class VideoPlayerScreen extends StatelessWidget {
  VideoPlayerScreen({super.key});

  final List<VideoModel> videos = [
    VideoModel(
      id: "video_tobacco_cessation_part1",
      title: "video_tobacco_cessation_part1_title",
      description: "video_tobacco_cessation_part1_desc",
      url: "assets/Video1.mp4",
      duration: "2:45",
      gradientColors: [const Color(0xFF14532D), const Color(0xFF10B981)],
    ),
    VideoModel(
      id: "video_coping_urges_part2",
      title: "video_coping_urges_part2_title",
      description: "video_coping_urges_part2_desc",
      url: "assets/Video2.mp4",
      duration: "3:15",
      gradientColors: [const Color(0xFF11998e), const Color(0xFF38ef7d)],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final languageService = LanguageService();

    return ListenableBuilder(
      listenable: languageService,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: Colors.grey.shade50,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.white,
            foregroundColor: Colors.grey.shade800,
            title: Text(
              languageService.getText('video_library'),
              style:
                  GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ),
          body: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header section
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          languageService.getText('educational_videos'),
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade900,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          languageService.getText('select_video_learn'),
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Video list
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                      itemCount: videos.length,
                      itemBuilder: (context, index) {
                        final video = videos[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 20),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                                color: Colors.grey.shade200, width: 1.5),
                          ),
                          clipBehavior: Clip.antiAlias,
                          color: Colors.white,
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      PlayVideoScreen(video: video),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Thumbnail (gradient design)
                                Container(
                                  height: 180,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: video.gradientColors,
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                  ),
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      // Soft play overlay button
                                      Container(
                                        padding: const EdgeInsets.all(14),
                                        decoration: BoxDecoration(
                                          color: Colors.white
                                              .withOpacity(0.9),
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black
                                                  .withOpacity(0.08),
                                              blurRadius: 16,
                                              spreadRadius: 2,
                                            ),
                                          ],
                                        ),
                                        child: Icon(
                                          Icons.play_arrow_rounded,
                                          size: 36,
                                          color: video.gradientColors[0],
                                        ),
                                      ),
                                      // Duration Badge
                                      Positioned(
                                        right: 14,
                                        bottom: 14,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.black
                                                .withOpacity(0.65),
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                Icons.access_time_rounded,
                                                color: Colors.white,
                                                size: 13,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                video.duration,
                                                style: GoogleFonts.poppins(
                                                  color: Colors.white,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Details
                                Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        languageService.getText(video.title),
                                        style: GoogleFonts.poppins(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey.shade900,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        languageService
                                            .getText(video.description),
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          color: Colors.grey.shade600,
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class PlayVideoScreen extends StatefulWidget {
  final VideoModel video;
  const PlayVideoScreen({super.key, required this.video});

  @override
  _PlayVideoScreenState createState() => _PlayVideoScreenState();
}

class _PlayVideoScreenState extends State<PlayVideoScreen> {
  late VideoPlayerController _controller;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    _initializeVideo(widget.video.url);
    _trackVideoOpen(widget.video.id);
  }

  void _initializeVideo(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      _controller = VideoPlayerController.networkUrl(Uri.parse(url));
    } else {
      _controller = VideoPlayerController.asset(url);
    }

    _controller.initialize().then((_) {
      setState(() {});
      _controller.play(); // Auto-play when opened
    }).catchError((error) {
      debugPrint("Error initializing video: $error");
    });

    _controller.addListener(() {
      if (mounted) setState(() {});
    });
  }

  Future<void> _trackVideoOpen(String id) async {
    if (LoginPage.userId.isEmpty) {
      print(
          "PlayVideoScreen: LoginPage.userId is empty. Skipping progress save.");
      return;
    }
    final progressUrl =
        "${LoginPage.protocol}://${LoginPage.domainName}/api/user/save-progress";
    try {
      final response = await http.post(
        Uri.parse(progressUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${LoginPage.jwtToken}',
        },
        body: jsonEncode({
          'userid': LoginPage.userId,
          'item_id': id,
          'item_type': 'video',
        }),
      );
      print(
          "PlayVideoScreen: Video open tracked. Response: ${response.statusCode}");
    } catch (e) {
      print("PlayVideoScreen: Error tracking video open: $e");
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    final bool isInitialized = _controller.value.isInitialized;
    final languageService = LanguageService();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          languageService.getText(widget.video.title),
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          child: isInitialized
              ? GestureDetector(
                  onTap: () {
                    setState(() {
                      _showControls = !_showControls;
                    });
                  },
                  child: AspectRatio(
                    aspectRatio: _controller.value.aspectRatio,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Video Player
                        VideoPlayer(_controller),

                        // Controls Overlay
                        if (_showControls) ...[
                          // Dark overlay shade
                          Container(
                            color: Colors.black.withOpacity(0.4),
                          ),
                          // Big Play/Pause Toggle
                          IconButton(
                            iconSize: 64,
                            icon: Icon(
                              _controller.value.isPlaying
                                  ? Icons.pause_circle_filled_rounded
                                  : Icons.play_circle_filled_rounded,
                              color: Colors.white,
                            ),
                            onPressed: () {
                              setState(() {
                                _controller.value.isPlaying
                                    ? _controller.pause()
                                    : _controller.play();
                              });
                            },
                          ),
                          // Progress Bar & Controls Bar
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withOpacity(0.8)
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Video Slider progress bar
                                  VideoProgressIndicator(
                                    _controller,
                                    allowScrubbing: true,
                                    colors: VideoProgressColors(
                                      playedColor:
                                          widget.video.gradientColors[0],
                                      bufferedColor: Colors.white30,
                                      backgroundColor: Colors.white12,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      // Time Label
                                      Text(
                                        "${_formatDuration(_controller.value.position)} / ${_formatDuration(_controller.value.duration)}",
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          // Mute/Unmute
                                          IconButton(
                                            icon: Icon(
                                              _controller.value.volume > 0
                                                  ? Icons.volume_up_rounded
                                                  : Icons.volume_off_rounded,
                                              color: Colors.white,
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                _controller.setVolume(
                                                  _controller.value.volume > 0
                                                      ? 0.0
                                                      : 1.0,
                                                );
                                              });
                                            },
                                          ),
                                          // Playback Speed
                                          PopupMenuButton<double>(
                                            initialValue:
                                                _controller.value.playbackSpeed,
                                            icon: const Icon(
                                              Icons.speed_rounded,
                                              color: Colors.white,
                                            ),
                                            onSelected: (speed) {
                                              _controller
                                                  .setPlaybackSpeed(speed);
                                            },
                                            itemBuilder: (context) => [
                                              const PopupMenuItem(
                                                value: 0.5,
                                                child: Text("0.5x"),
                                              ),
                                              const PopupMenuItem(
                                                value: 1.0,
                                                child: Text("Normal"),
                                              ),
                                              const PopupMenuItem(
                                                value: 1.5,
                                                child: Text("1.5x"),
                                              ),
                                              const PopupMenuItem(
                                                value: 2.0,
                                                child: Text("2.0x"),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                )
              : const Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }
}
