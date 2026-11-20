import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'mantra_data.dart';

class OmService {
  static const playlistUrl = 'https://www.youtube.com/playlist?list=PLvfeL05IH5nNalqoViD-hzb7EIthloBZX';
  static String get _dir => File(Platform.resolvedExecutable).parent.path;
  static String get ytdlpBin => Platform.isWindows ? '$_dir\\tools\\yt-dlp.exe' : 'yt-dlp';
  static Map<String, String>? get _env => Platform.isWindows ? null : {'PATH': '/usr/local/bin:/usr/bin:/bin', 'LANG': 'C.UTF-8'};
  
  static int _rank(String title) {
    final t = title.toLowerCase();
    if (t.contains('шакьямуни') || t.contains('shakyamuni') || t.contains('muni')) return 1;
    if (t.contains('мани') || t.contains('mani') || t.contains('avalokiteshvara') || t.contains('chenrezig')) return 2;
    if (t.contains('зелен') && t.contains('тар') || t.contains('green tara')) return 3;
    if (t.contains('белой тар') || t.contains('white tara') || t.contains('тар') || t.contains('tara')) return 4;
    if (t.contains('медицин') || t.contains('medicine') || t.contains('здоров') || t.contains('исцел')) return 5;
    if (t.contains('ваджрасаттв') || t.contains('vajrasattva') || t.contains('очищ') || t.contains('карм')) return 6;
    if (t.contains('манджушри') || t.contains('manjushri') || t.contains('ринпоче') || t.contains('rinpoche')) return 7;
    if (t.contains('амитабх') || t.contains('amitabha') || t.contains('дзамбал') || t.contains('dzambhala')) return 8;
    if (t.contains('праджняпарамит') || t.contains('prajna') || t.contains('heart sutra')) return 9;
    return 10;
  }

  static Future<List<MantraTrack>> fetchPlaylist() async {
    final res = await Process.run(ytdlpBin, ['--flat-playlist', '--dump-json', '--ignore-errors', '--no-warnings', playlistUrl], environment: _env);
    final lines = const LineSplitter().convert(res.stdout.toString());
    final list = <MantraTrack>[];
    int idx = 1;
    for (final line in lines) {
      if (!line.trim().startsWith('{')) continue;
      try {
        final j = jsonDecode(line);
        final id = j['id']?.toString() ?? '';
        final title = j['title']?.toString() ?? '';
        if (id.isEmpty || title == 'NA' || title == '[Deleted video]' || title == '[Private video]') continue;
        list.add(MantraTrack(id: id, title: title, url: 'https://www.youtube.com/watch?v=$id', index: idx++));
      } catch (_) {}
    }
        list.sort((a, b) => _rank(a.title).compareTo(_rank(b.title)));
    return [for (int i = 0; i < list.length; i++) MantraTrack(id: list[i].id, title: list[i].title, url: list[i].url, index: i + 1)];
  }
  static Future<String> resolveAudio(String url) async {
    final res = await Process.run(ytdlpBin, ['-f', 'bestaudio[ext=m4a]/bestaudio', '-g', '--no-playlist', '--no-warnings', url], environment: _env);
    if (res.exitCode != 0) throw Exception(res.stderr.toString());
    return res.stdout.toString().trim().split('\n').first;
  }

  static Future<File> _historyFile() async {
    final doc = await getApplicationDocumentsDirectory();
    return File('${doc.path}${Platform.pathSeparator}OM_Meditation_History.json');
  }
  static Future<List<MeditationSession>> loadSessions() async {
    final prefs = await SharedPreferences.getInstance();
    String? raw = prefs.getString('om_sessions');
    final f = await _historyFile();
    if (await f.exists()) raw = await f.readAsString();
    if (raw == null || raw.isEmpty) return [];
    return (jsonDecode(raw) as List).map((e) => MeditationSession.fromJson(e)).toList();
  }

  static Future<void> saveSessions(List<MeditationSession> list) async {
    final raw = jsonEncode(list.map((e) => e.toJson()).toList());
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('om_sessions', raw);
    final f = await _historyFile();
    await f.writeAsString(raw);
  }

  static Future<Set<String>> loadSavedIds() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList('om_saved_ids') ?? []).toSet();
  }

  static Future<void> saveSavedIds(Set<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('om_saved_ids', ids.toList());
  }
}
