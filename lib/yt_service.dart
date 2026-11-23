import 'dart:convert';
import 'dart:io';
import 'dart:ui';

class YtVideo {
  final String id, title, thumb, url;
  YtVideo({required this.id, required this.title, required this.thumb, required this.url});
  Map<String, String> toJson() => {'id': id, 'title': title, 'thumb': thumb, 'url': url};
  factory YtVideo.fromJson(Map<String, dynamic> j) => YtVideo(id: j['id'], title: j['title'], thumb: j['thumb'], url: j['url']);
}
class YtService {
  static int _page = 0;
  static final _favFile = File('saved_videos.json');
  static final _progFile = File('video_progress.json');
  static List<YtVideo> loadFavs() => _favFile.existsSync() ? (jsonDecode(_favFile.readAsStringSync()) as List).map((e) => YtVideo.fromJson(e)).toList() : [];
  static void saveFavs(List<YtVideo> list) => _favFile.writeAsStringSync(jsonEncode(list.map((e) => e.toJson()).toList()));
  static Set<String> loadStarted() => _progFile.existsSync() ? Set<String>.from(jsonDecode(_progFile.readAsStringSync())) : {};
  static Future<List<YtVideo>> fetchChannelOrVideo(String rawInput, {Set<String> exclude = const {}}) async {
    var q = rawInput.trim();
    if (q.isEmpty) return [];
    _page++;
    final yt = utf8.decode(base64Decode('aHR0cHM6Ly93d3cueW91dHViZS5jb20='));
    final imgH = utf8.decode(base64Decode('aHR0cHM6Ly9pLnl0aW1nLmNvbS92aQ=='));
    if (q.startsWith('@')) q = '$yt/$q/videos';
    if (!q.startsWith('http')) q = 'ytsearch24:$q';
    try {
      final res = await Process.run(Platform.isWindows ? "${File(Platform.resolvedExecutable).parent.path}/yt-dlp.exe" : "yt-dlp", ['--flat-playlist', '--extractor-args', 'youtube:player_client=tv,default', '--dump-single-json', '--playlist-start', '${(_page % 3) * 6 + 1}', '--playlist-end', '${(_page % 3) * 6 + 18}', q]);
      if (res.exitCode != 0) return [];
      final data = jsonDecode(res.stdout.toString());
      final list = <YtVideo>[];
      final entries = (data['entries'] as List?) ?? [data];
      for (final e in entries) {
        final id = (e['id'] ?? '').toString();
        if (id.length == 11 && !exclude.contains(id)) list.add(YtVideo(id: id, title: (e['title'] ?? 'Видео урок').toString(), thumb: '$imgH/$id/hqdefault.jpg', url: '$yt/watch?v=$id'));
      }
      return list..shuffle();
    } catch (_) { return []; }
  }
  static Future<void> openVideo(YtVideo v, VoidCallback onDone) async {
    final s = loadStarted()..add(v.id);
    _progFile.writeAsStringSync(jsonEncode(s.toList()));
    final conf = File('${Directory.systemTemp.path}/mpv_tarot.conf')..writeAsStringSync('ESC quit\n');
    final p = await Process.start(Platform.isWindows ? "${File(Platform.resolvedExecutable).parent.path}/mpv.exe" : "mpv", ['--fs', '--no-border', '--keepaspect=yes', '--ontop', '--save-position-on-quit', '--watch-later-directory=${Directory.systemTemp.path}/mpv_watch', '--input-conf=${conf.path}', v.url]);
    p.exitCode.then((_) => onDone());
  }

  static final Map<String, String> _cache = {};
  static Future<String> resolveAudio(String url) async { if (_cache.containsKey(url)) return _cache[url]!; if (!url.startsWith("http")) { final yt = utf8.decode(base64Decode("aHR0cHM6Ly93d3cueW91dHViZS5jb20=")); url = url.startsWith("PL") ? "$yt/playlist?list=$url" : "$yt/watch?v=$url"; }
    final res = await Process.run('yt-dlp', ['--no-playlist', '-f', 'bestaudio/best', '--extractor-args', 'youtube:player_client=tv,default', '-g', url]);
    final u = res.stdout.toString().trim().split('\n').first; if (u.isNotEmpty) _cache[url] = u; return u;
  }
}
