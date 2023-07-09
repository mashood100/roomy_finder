import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class PlayVideoScreen extends StatefulWidget {
  const PlayVideoScreen({
    super.key,
    required this.source,
    required this.isAsset,
  });
  final String source;
  final bool isAsset;

  @override
  State<PlayVideoScreen> createState() => _PlayVideoScreenState();
}

class _PlayVideoScreenState extends State<PlayVideoScreen> {
  late final VideoPlayerController _controller;
  @override
  void initState() {
    super.initState();

    if (widget.isAsset) {
      _controller = VideoPlayerController.asset(widget.source)
        ..initialize().then(
          (_) => setState(() {
            _controller.play();
          }),
        );
    } else {
      _controller = VideoPlayerController.networkUrl(Uri.parse(widget.source))
        ..initialize().then(
          (_) => setState(() {
            _controller.play();
          }),
        );
    }

    _controller.setLooping(true);
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Video Player")),
      body: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Center(
            child: _controller.value.isInitialized
                ? AspectRatio(
                    aspectRatio: _controller.value.aspectRatio,
                    child: VideoPlayer(
                      _controller,
                    ),
                  )
                : const CircularProgressIndicator(),
          ),
          VideoProgressIndicator(
            _controller,
            allowScrubbing: true,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _controller.value.isPlaying
                ? _controller.pause()
                : _controller.play();
          });
        },
        child: Icon(
          _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
        ),
      ),
    );
  }
}
