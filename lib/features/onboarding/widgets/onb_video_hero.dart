import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class OnbVideoHero extends StatefulWidget {
  const OnbVideoHero({
    super.key,
    required this.assetPath,
    this.size = 160,
    this.borderRadius = 28,
    this.playbackSpeed = 1.0,
  });
  final String assetPath;
  final double size;
  final double borderRadius;
  final double playbackSpeed;

  @override
  State<OnbVideoHero> createState() => _OnbVideoHeroState();
}

class _OnbVideoHeroState extends State<OnbVideoHero> with WidgetsBindingObserver {
  late final VideoPlayerController _c;
  bool _ready = false;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _c = VideoPlayerController.asset(widget.assetPath)
      ..setLooping(true)
      ..setVolume(0);
    _init();
  }

  Future<void> _init() async {
    try {
      await _c.initialize();
      await _c.setPlaybackSpeed(widget.playbackSpeed);
      setState(() => _ready = true);
      await _c.play();
    } catch (_) {
      setState(() => _error = true);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_ready) return;
    if (state == AppLifecycleState.resumed) {
      _c.play();
    } else {
      _c.pause();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (_error) {
      return SizedBox(
        width: widget.size, height: widget.size,
        child: CircularProgressIndicator(
          strokeWidth: 6, valueColor: AlwaysStoppedAnimation(cs.primary),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: Container(
        width: widget.size, height: widget.size,
        color: Colors.white,
        child: _ready
            ? FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _c.value.size.width,
                  height: _c.value.size.height,
                  child: VideoPlayer(_c),
                ),
              )
            : Center(
                child: SizedBox(
                  width: 32, height: 32,
                  child: CircularProgressIndicator(strokeWidth: 3),
                ),
              ),
      ),
    );
  }
}