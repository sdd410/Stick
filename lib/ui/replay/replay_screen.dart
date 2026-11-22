import 'dart:async';

import 'package:flutter/material.dart';

import '../../domain/models.dart';
import '../../services/clip_files.dart';
import '../../theme.dart';
import 'clip_player.dart';

/// Full-screen story-style replay. Never auto-plays: it waits for a tap.
class ReplayScreen extends StatefulWidget {
  const ReplayScreen({
    super.key,
    required this.clips,
    required this.files,
    this.headline,
    this.playerFactory = videoPlayerClipPlayer,
  });

  final List<Clip> clips;
  final ClipFiles files;
  final String? headline;
  final ClipPlayerFactory playerFactory;

  @override
  State<ReplayScreen> createState() => _ReplayScreenState();
}

class _ReplayScreenState extends State<ReplayScreen>
    with WidgetsBindingObserver {
  // Clips whose files exist; null while checking.
  List<Clip>? _clips;
  int _index = 0;
  bool _started = false;
  bool _playing = false;
  ClipPlayer? _player;
  StreamSubscription<void>? _sub;
  // Bumped on every navigation so a slow load of an older clip is dropped.
  int _gen = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _filter();
  }

  Future<void> _filter() async {
    final found = <Clip>[];
    for (final c in widget.clips) {
      if (await widget.files.exists(c.path)) found.add(c);
    }
    if (!mounted) return;
    setState(() => _clips = found);
    if (found.isEmpty) _close();
  }

  void _close() {
    if (mounted) Navigator.of(context).maybePop();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) return;
    if (_playing) {
      _playing = false;
      _player?.pause();
    }
  }

  Future<void> _disposePlayer() async {
    final p = _player;
    _player = null;
    unawaited(_sub?.cancel());
    _sub = null;
    await p?.dispose();
  }

  Future<void> _show(int index, {int step = 1}) async {
    final clips = _clips!;
    final gen = ++_gen;
    _playing = false;
    await _disposePlayer();
    if (!mounted || gen != _gen) return;
    if (index >= clips.length) return _close();
    if (index < 0) index = 0;
    final player = widget.playerFactory();
    try {
      await player.load(clips[index]);
    } catch (_) {
      // Unreadable file: skip it like a missing one.
      await player.dispose();
      if (!mounted || gen != _gen) return;
      final next = index + step;
      if (next < 0) return _close();
      return _show(next, step: step);
    }
    if (!mounted || gen != _gen) {
      await player.dispose();
      return;
    }
    _player = player;
    _sub = player.completed.listen((_) => _next());
    setState(() => _index = index);
    _playing = true;
    await player.play();
  }

  void _next() {
    if (_clips == null || !_started) return;
    _show(_index + 1);
  }

  void _previous() {
    if (_clips == null || !_started) return;
    _show(_index - 1, step: -1);
  }

  void _start() {
    if (_started || _clips == null || _clips!.isEmpty) return;
    setState(() => _started = true);
    _show(0);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _gen++;
    _sub?.cancel();
    _player?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clips = _clips;
    final count = clips?.length ?? 0;
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (_, _) => _player?.pause(),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            if (_started && _player != null) _player!.view(),
            if (!_started)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _start,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.headline != null) ...[
                          Text(
                            widget.headline!,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 32),
                        ],
                        if (clips != null && clips.isNotEmpty)
                          const Text(
                            '▶ You have something to say',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 22,
                              color: StickColors.lime,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              )
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: _previous,
                      child: const SizedBox.expand(),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: _next,
                      child: const SizedBox.expand(),
                    ),
                  ),
                ],
              ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        for (var i = 0; i < count; i++)
                          Expanded(
                            child: Container(
                              key: ValueKey('seg$i'),
                              height: 3,
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              decoration: BoxDecoration(
                                color: _started && i <= _index
                                    ? StickColors.lime
                                    : Colors.white24,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                      ],
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        icon: const Icon(Icons.close),
                        tooltip: 'Close',
                        onPressed: _close,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
