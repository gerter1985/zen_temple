import 'package:flutter/material.dart';
import 'models.dart';

String fmtDur(int sec) {
  if (sec <= 0) return '0:00';
  final h = sec ~/ 3600;
  final m = (sec % 3600) ~/ 60;
  final s = sec % 60;
  final mm = m.toString().padLeft(2, '0');
  final ss = s.toString().padLeft(2, '0');
  return h > 0 ? '$h:$mm:$ss' : '$m:$ss';
}

class ResumeCard extends StatelessWidget {
  final WatchProgress wp;
  final Color accent;
  final VoidCallback onAudio;
  final VoidCallback onVideo;
  final VoidCallback onRemove;

  const ResumeCard({
    super.key,
    required this.wp,
    required this.accent,
    required this.onAudio,
    required this.onVideo,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withOpacity(0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(
              wp.lastWasVideo ? Icons.ondemand_video : Icons.headphones,
              size: 16,
              color: accent,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: InkWell(
                onTap: wp.lastWasVideo ? onVideo : onAudio,
                child: Text(
                  wp.item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
            ),
            InkWell(onTap: onRemove, child: const Icon(Icons.close, size: 16)),
          ]),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: wp.ratio,
            color: accent,
            backgroundColor: accent.withOpacity(0.15),
          ),
          const SizedBox(height: 6),
          Row(children: [
            Text(
              '${fmtDur(wp.positionSec)}${wp.totalSec > 0 ? ' / ${fmtDur(wp.totalSec)}' : ''}',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
            const Spacer(),
            TextButton.icon(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(0, 28),
              ),
              onPressed: onAudio,
              icon: Icon(Icons.play_arrow, size: 16, color: accent),
              label: Text('Слухати',
                  style: TextStyle(fontSize: 12, color: accent)),
            ),
            if (wp.item.isYoutube)
              TextButton.icon(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 28),
                ),
                onPressed: onVideo,
                icon: const Icon(Icons.tv, size: 15),
                label: const Text('Відео', style: TextStyle(fontSize: 12)),
              ),
          ]),
        ],
      ),
    );
  }
}

class MediaCard extends StatelessWidget {
  final MediaItem item;
  final Color accent;
  final bool isSaved;
  final int savedSec;
  final VoidCallback onAudio;
  final VoidCallback onVideo;
  final VoidCallback onToggleSave;

  const MediaCard({
    super.key,
    required this.item,
    required this.accent,
    required this.isSaved,
    required this.savedSec,
    required this.onAudio,
    required this.onVideo,
    required this.onToggleSave,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: InkWell(
              onTap: onAudio,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (item.thumb != null)
                    Image.network(
                      item.thumb!,
                      headers: const {'User-Agent': 'Mozilla/5.0'},
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.black26,
                        child: Icon(Icons.spa, size: 40, color: accent),
                      ),
                    )
                  else
                    Container(
                      color: Colors.black26,
                      child: Icon(Icons.podcasts, size: 42, color: accent),
                    ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.black54,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        iconSize: 18,
                        icon: Icon(
                          isSaved ? Icons.bookmark : Icons.bookmark_border,
                          color: isSaved ? accent : Colors.white,
                        ),
                        onPressed: onToggleSave,
                      ),
                    ),
                  ),
                  if (savedSec > 5)
                    Positioned(
                      bottom: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Зупинено: ${fmtDur(savedSec)}',
                          style: TextStyle(fontSize: 11, color: accent),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          InkWell(
            onTap: onAudio,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
              child: Text(
                item.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: Row(children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                  ),
                  onPressed: onAudio,
                  icon: const Icon(Icons.headphones, size: 16),
                  label: const Text(
                    'Аудіо',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              if (item.isYoutube) ...[
                const SizedBox(width: 6),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                    ),
                    onPressed: onVideo,
                    icon: const Icon(Icons.ondemand_video, size: 16),
                    label: const Text('Відео', style: TextStyle(fontSize: 12)),
                  ),
                ),
              ],
            ]),
          ),
        ],
      ),
    );
  }
}

