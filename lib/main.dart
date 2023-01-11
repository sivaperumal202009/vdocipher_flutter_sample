import 'package:flutter/material.dart';
import 'package:vdocipher_flutter/vdocipher_flutter.dart';
import 'package:vdocipher_flutter_sample/vdo_player_service.dart';
import 'package:vdocipher_flutter_sample/video_player_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: () {
                const EmbedInfo embedInfo = EmbedInfo.streaming(
                  otp:
                      "20160313versUSE323Zg7S1z8F3lSWKxiWmzkmTJDjDQPQBvMFKbHMIJCJlFapGp",
                  playbackInfo:
                      "eyJ2aWRlb0lkIjoiZDNhMjA4YjBiOTViNDNlMDhkMGE0M2EwYWZmMTgxYzAifQ==",
                  playbackSpeedOptions: [
                    0.25,
                    0.5,
                    0.75,
                    1,
                    1.25,
                    1.5,
                    1.75,
                    2.0
                  ],
                  embedInfoOptions: EmbedInfoOptions(
                    resumePosition: Duration(seconds: 30),
                  ),
                );
                final VdoPlayerService service = VdoPlayerService(embedInfo);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => VideoPlayerScreen(service: service),
                  ),
                );
              },
              child: const Text("Play Video"),
            ),
          ],
        ),
      ),
    );
  }
}
