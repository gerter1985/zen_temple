import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import 'models.dart';

class MediaFetcher {
  static const ytdlpBin = '/usr/local/bin/yt-dlp';
  static const ytBase = 'https://youtube.com';
  static const imgBase = 'https://i.yt' 'img.com';

  static Future<List<MediaItem>> fetchItems(MediaSource source) async {
    final u = source.url.trim();
    if (u.startsWith('apple_search:')) {
      return _searchApplePodcast(source, u.substring('apple_search:'.length));
    }
    if (u.contains('apple.com') || u.startsWith('apple:')) {
      return _fetchApplePodcastById(source);
    }
    if (u.startsWith('http://') || u.startsWith('https://')) {
      if (!u.contains('youtube') && !u.contains('youtu.be')) {
        return _fetchRss(source, u);
      }
    }
    return _fetchYoutube(source);
  }

  static Future<List<MediaItem>> _searchApplePodcast(
      MediaSource source, String query) async {
    final searchUri = Uri.https('itunes' + '.apple' + '.com', '/search', {
      'term': query,
      'media': 'podcast',
      'entity': 'podcast',
      'limit': '5',
    });
    final resp = await http.get(searchUri);
    final json = jsonDecode(utf8.decode(resp.bodyBytes));
    final results = (json['results'] as List?) ?? [];
    final allItems = <MediaItem>[];
    for (final pod in results) {
      final feed = pod['feedUrl']?.toString() ?? '';
      if (feed.isEmpty) continue;
      try {
        final eps = await _fetchRss(source, feed);
        allItems.addAll(eps);
        if (allItems.length >= 25) break;
      } catch (_) {}
    }
    if (allItems.length < 3) {
      return _fetchYoutube(MediaSource(
        id: source.id,
        title: source.title,
        url: 'search:' + query + ' подкаст',
        category: source.category,
      ));
    }
    return allItems;
  }

  static Future<List<MediaItem>> _fetchApplePodcastById(
      MediaSource source) async {
    final match = RegExp(r'id(\d+)').firstMatch(source.url);
    if (match == null) throw Exception('Не знайдено ID подкасту Apple');
    final lookupUri = Uri.https('itunes' + '.apple' + '.com', '/lookup', {
      'id': match.group(1)!,
      'entity': 'podcast',
    });
    final resp = await http.get(lookupUri);
    final json = jsonDecode(utf8.decode(resp.bodyBytes));
    final results = (json['results'] as List?) ?? [];
    if (results.isEmpty || results.first['feedUrl'] == null) {
      throw Exception('RSS-стрічку не знайдено');
    }
    return _fetchRss(source, results.first['feedUrl'].toString());
  }

  static String _buildTargetUrl(String raw) {
    final u = raw.trim();
    if (u.startsWith('search:')) {
      return 'ytsearch60:' + u.substring('search:'.length);
    }
    if (u.startsWith('playlist:')) {
      final listId = u.substring('playlist:'.length);
      return ytBase + '/playlist?list=' + listId;
    }
    if (u.startsWith('@')) {
      return ytBase + '/' + u ;
    }
    if (!u.startsWith('http')) {
      return ytBase + '/@' + u ;
    }
    return u;
  }

  static int _safeInt(dynamic val) {
    if (val == null) return 0;
    if (val is num) return val.toInt();
    return double.tryParse(val.toString())?.toInt() ?? 0;
  }

  static Future<List<MediaItem>> _fetchYoutube(MediaSource source) async {
    final targetUrl = _buildTargetUrl(source.url);
    print('YT_REQ: ' + targetUrl);
    final res = await Process.run(
      ytdlpBin,
      [
        '--flat-playlist',
        '--yes-playlist',
        '--dump-json',
        '--ignore-errors',
                '--no-warnings',
        targetUrl,
      ],
      environment: {'PATH': '/usr/local/bin:/usr/bin:/bin', 'LANG': 'C.UTF-8'},
    );
    final out = res.stdout.toString();
    print('YT_EXIT: ' + res.exitCode.toString() + ' LEN: ' + out.length.toString());
    final lines = const LineSplitter().convert(out);
    final items = <MediaItem>[];
    for (final line in lines) {
      final trimmed = line.trim();
      if (!trimmed.startsWith('{')) continue;
      try {
        final e = jsonDecode(trimmed) as Map<String, dynamic>;
        final vid = e['id']?.toString() ?? '';
        if (vid.isEmpty || vid.startsWith('UC')) continue;
        final title = e['title']?.toString() ?? 'Відео';
        if (source.url.startsWith('search:')) {
          final low = title.toLowerCase();
          if (RegExp(r'[ыэъё]').hasMatch(low) || !RegExp(r'[а-яіїєґ]').hasMatch(low)) continue;
        }
        items.add(MediaItem(
          id: vid,
          title: title,
          sourceTitle: source.title,
          url: ytBase + '/watch?v=' + vid,
          thumb: ((e['thumbnails'] is List && (e['thumbnails'] as List).isNotEmpty) ? (e['thumbnails'] as List).last['url']?.toString() : null) ?? (imgBase + '/vi/' + vid + '/hqdefault.jpg'),
          isYoutube: true,
          durationSec: _safeInt(e['duration']),
        ));
      } catch (_) {}
    }
    if (items.isEmpty) {
      throw Exception('Порожньо для ' + targetUrl + ' | ' + res.stderr.toString());
    }
    return items;
  }

  static Future<List<MediaItem>> _fetchRss(
      MediaSource source, String feedUrl) async {
    final uri = Uri.tryParse(feedUrl);
    if (uri == null || !uri.hasScheme) return [];
    try {
      final resp = await http.get(uri);
    if (resp.statusCode != 200) return [];
    final doc =
        XmlDocument.parse(utf8.decode(resp.bodyBytes, allowMalformed: true));
    final channelImg =
        doc.findAllElements('itunes:image').firstOrNull?.getAttribute('href');
    final items = <MediaItem>[];
    for (final el in doc.findAllElements('item')) {
      final epTitle = el.findElements('title').firstOrNull?.innerText.trim() ?? 'Випуск';
      final lowEp = epTitle.toLowerCase();
      if (RegExp(r'[ыэъё]').hasMatch(lowEp) || !RegExp(r'[а-яіїєґ]').hasMatch(lowEp)) continue;
      final enc =
          el.findElements('enclosure').firstOrNull?.getAttribute('url') ?? '';
      if (enc.isEmpty) continue;
      items.add(MediaItem(
        id: enc.hashCode.toString(),
        title: el.findElements('title').firstOrNull?.innerText.trim() ?? 'Випуск',
        sourceTitle: source.title,
        url: enc,
        thumb:
            el.findElements('itunes:image').firstOrNull?.getAttribute('href') ??
                channelImg,
        isYoutube: false,
      ));
    }
    return items;
    } catch (_) { return []; }
  }

  static Future<String> resolveYoutubeAudioUrl(String watchUrl) async {
    final res = await Process.run(
      ytdlpBin,
      [
        '-f',
        'bestaudio[ext=m4a]/bestaudio',
        '-g',
        '--no-playlist',
        '--no-warnings',
        watchUrl,
      ],
      environment: {'PATH': '/usr/local/bin:/usr/bin:/bin', 'LANG': 'C.UTF-8'},
    );
    if (res.exitCode != 0) {
      throw Exception('Помилка аудіопотоку: ' + res.stderr.toString());
    }
    return res.stdout.toString().trim().split('\n').first;
  }

  static Future<void> openExternalVideo(String url, {int startSec = 0}) async {
    final args = <String>[
      '--script-opts=ytdl_hook-ytdl_path=' + ytdlpBin,
      '--fs',
      '--no-border',
      '--no-osc',
      '--input-default-bindings=no',
      '--save-position-on-quit',
      if (startSec > 5) '--start=+' + startSec.toString(),
      url,
    ];
    final escConf = File('/tmp/zen_mpv_esc.conf')..writeAsStringSync('ESC quit\nSPACE cycle pause\nLEFT seek -10\nRIGHT seek 10\n');
    await Process.start('mpv', ['--input-conf=' + escConf.path, ...args], mode: ProcessStartMode.detached);
  }
}

