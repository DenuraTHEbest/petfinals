import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class TrainingScreen extends StatelessWidget {
  const TrainingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = YoutubePlayerController(
      initialVideoId: 'tJ3nQk1Z0Zg',
      flags: const YoutubePlayerFlags(autoPlay: false),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Training & Fun')),
      body: YoutubePlayer(
        controller: controller,
        showVideoProgressIndicator: true,
      ),
    );
  }
}
