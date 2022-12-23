import 'package:flutter/material.dart';
import 'package:vdocipher_flutter_sample/custom_vdo_player.dart';
import 'package:vdocipher_flutter_sample/vdo_player_service.dart';

class VideoPlayerScreen extends StatefulWidget {
  final VdoPlayerService service;
  const VideoPlayerScreen({super.key, required this.service});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  bool isFullScreen = false;
  bool hasInitialized = false;
  @override
  void initState() {
    widget.service.vdoPlayerValueNotifier.addListener(() {
      setState(() {
        hasInitialized = true;
        isFullScreen = widget.service.isFullScreen;
      });
    });
    super.initState();
  }

  @override
  void dispose() {
    widget.service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: isFullScreen
          ? null
          : AppBar(
              title: const Text("Sample Video"),
            ),
      body: Column(
        children: [
          CustomVdoPlayerView(service: widget.service),
          if (!isFullScreen && hasInitialized) ...[
            const SizedBox(height: 30),
            Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(width: 20),
                    const Text(
                      "Speed Options : ",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        height: 1.5,
                      ),
                    ),
                    Flexible(
                      child: Text(
                        "[${widget.service.playbackSpeedList.join(", ")}]",
                        style: const TextStyle(height: 1.5),
                      ),
                    ),
                    const SizedBox(width: 20),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(width: 20),
                    const Text(
                      "Selected Speed : ",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        height: 1.5,
                      ),
                    ),
                    Flexible(
                      child: Text(
                        "${widget.service.value.playbackSpeed}",
                        style: const TextStyle(height: 1.5),
                      ),
                    ),
                    const SizedBox(width: 20),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(width: 20),
                    const Text(
                      "SubTitle Options : ",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        height: 1.5,
                      ),
                    ),
                    Flexible(
                      child: Text(
                        "[${widget.service.subtitleTracks.map((e) => e.language).toList().join(", ")}]",
                        style: const TextStyle(height: 1.5),
                      ),
                    ),
                    const SizedBox(width: 20),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(width: 20),
                    const Text(
                      "Selected SubTitle : ",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        height: 1.5,
                      ),
                    ),
                    Flexible(
                      child: Text(
                        "${widget.service.value.subtitleTrack?.language}",
                        style: const TextStyle(height: 1.5),
                      ),
                    ),
                    const SizedBox(width: 20),
                  ],
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
