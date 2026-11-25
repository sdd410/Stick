import 'package:flutter/material.dart';

import '../../controller/stick_scope.dart';
import '../../domain/models.dart';
import '../../theme.dart';

/// "See all": every saved message, newest first. Tap to play, bin to delete.
class ClipListScreen extends StatelessWidget {
  const ClipListScreen({
    super.key,
    required this.onPlay,
    this.onAddMessage,
    this.onPlayAll,
  });

  final void Function(Clip clip) onPlay;

  /// Shown as the "+ Add a message" button (the Messages tab).
  final VoidCallback? onAddMessage;

  /// Plays the story-style replay ("▶ Play").
  final VoidCallback? onPlayAll;

  Future<void> _confirmDelete(BuildContext context, Clip clip) async {
    final c = StickScope.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this message?'),
        content: const Text('It will be gone for good.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Keep'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) await c.deleteClip(clip.id);
  }

  @override
  Widget build(BuildContext context) {
    final clips = [...?StickScope.of(context).snapshot?.clips]
      ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your messages'),
        actions: [
          if (onPlayAll != null && clips.isNotEmpty)
            TextButton(onPressed: onPlayAll, child: const Text('▶ Play')),
        ],
      ),
      floatingActionButton: onAddMessage == null
          ? null
          : FloatingActionButton.extended(
              onPressed: onAddMessage,
              backgroundColor: StickColors.lime,
              foregroundColor: StickColors.bg,
              label: const Text('+ Add a message'),
            ),
      body: clips.isEmpty
          ? const Center(
              child: Text(
                'No messages yet.',
                style: TextStyle(color: StickColors.muted),
              ),
            )
          : ListView.builder(
              itemCount: clips.length,
              itemBuilder: (_, i) {
                final clip = clips[i];
                final voice = clip.type == ClipType.voice;
                return ListTile(
                  leading: Icon(voice ? Icons.mic : Icons.videocam),
                  title: Text('Day ${clip.dayNumber}'),
                  subtitle: Text(voice ? 'Voice' : 'Video'),
                  onTap: () => onPlay(clip),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'Delete',
                    onPressed: () => _confirmDelete(context, clip),
                  ),
                );
              },
            ),
    );
  }
}
