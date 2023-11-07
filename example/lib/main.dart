import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:vdocipher_flutter_v3/vdocipher_flutter_v3.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: _HomeScreen(),
    );
  }
}

class _HomeScreen extends StatelessWidget {
  const _HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const String otp =
        "20160313versUSE323rHQ0pqmtqYdQMkJbfxUZd7dmO1EdfbBvUjS1AnqiTAyIUW";
    const String playbackInfo =
        "eyJ2aWRlb0lkIjoiMjg2ZTU1MWYxNWM4NGI1NWFlNTI0MzBiMTYxYWJhMGMifQ==";
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plugin example app'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            const EmbedInfo embedInfo = EmbedInfo.streaming(
              otp: otp,
              playbackInfo: playbackInfo,
              playbackSpeedOptions: [0.25, 0.5, 0.75, 1, 1.25, 1.5, 1.75, 2.0],
              embedInfoOptions: EmbedInfoOptions(
                resumePosition: Duration(seconds: 60),
              ),
            );
            final VdoPlayerService service = VdoPlayerService(
              embedInfo,
              "286e551f15c84b55ae52430b161aba0c",
              onVideoChaptersLoaded: (chapter) {
                // ignore: avoid_print
                print("Chapters Length : ${chapter.length}");
              },
              onEvent: (event, [v = 0]) {},
            );
            if (context.mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => _VideoPlayerScreen(service: service),
                ),
              );
            }
          },
          child: const Text('Play Video'),
        ),
      ),
    );
  }
}

class _VideoPlayerScreen extends StatefulWidget {
  final VdoPlayerService service;
  const _VideoPlayerScreen({required this.service});

  @override
  State<_VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<_VideoPlayerScreen> {
  bool isFullScreen = false;
  bool hasInitialized = false;
  @override
  void initState() {
    widget.service.isLoadingNotifier.addListener(() {
      setState(() {
        hasInitialized = true;
        isFullScreen = widget.service.isFullScreen;
      });
    });
    widget.service.isFullScreenNotifier.addListener(() {
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (kIsWeb)
            CustomWebVdoPlayerView(service: widget.service)
          else
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
