import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';
import 'services.dart';
import 'ui_dialogs.dart';
import 'ui_widgets.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  runApp(const ZenTempleApp());
}

class ZenTempleApp extends StatefulWidget {
  const ZenTempleApp({super.key});
  @override
  State<ZenTempleApp> createState() => _ZenTempleAppState();
}

class _ZenTempleAppState extends State<ZenTempleApp> {
  bool isNeon = false;
  @override
  Widget build(BuildContext context) {
    final accent = isNeon ? const Color(0xFF00F5D4) : const Color(0xFFD4AF37);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Дзен Храм',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: isNeon ? const Color(0xFF090D16) : const Color(0xFF12100E),
        cardColor: isNeon ? const Color(0xFF111827) : const Color(0xFF1E1A16),
        colorScheme: ColorScheme.dark(primary: accent, secondary: accent),
      ),
      home: TempleHome(accent: accent, isNeon: isNeon, onToggleTheme: () => setState(() => isNeon = !isNeon)),
    );
  }
}
class TempleHome extends StatefulWidget {
  final Color accent;
  final bool isNeon;
  final VoidCallback onToggleTheme;
  const TempleHome({super.key, required this.accent, required this.isNeon, required this.onToggleTheme});
  @override
  State<TempleHome> createState() => _TempleHomeState();
}

class _TempleHomeState extends State<TempleHome> {
  late final Player player;
  late SharedPreferences prefs;
  List<MediaSource> sources = [];
  MediaSource? activeSource;
  List<MediaItem> items = [], savedItems = [];
  Map<String, WatchProgress> progressMap = {};
  bool loading = false, showOnlySaved = false, isPlaying = false, resolvingAudio = false;
  String search = '';
  MediaItem? currentItem;
  Duration pos = Duration.zero, dur = Duration.zero;
  double rate = 1.0;
  int practiceSec = 0, lastSavedTick = 0;

  @override
  void initState() {
    super.initState();
    player = Player();
    player.stream.playing.listen((v) => setState(() => isPlaying = v));
    player.stream.duration.listen((d) => setState(() => dur = d));
    player.stream.position.listen((p) {
      setState(() => pos = p);
      if (isPlaying && currentItem != null && (p.inSeconds - lastSavedTick).abs() >= 5) {
        lastSavedTick = p.inSeconds;
        practiceSec += 5;
        prefs.setInt('practice_sec', practiceSec);
        _saveProgress(currentItem!, p.inSeconds, dur.inSeconds, false);
      }
    });
    _initData();
  }

  Future<void> _initData() async {
    prefs = await SharedPreferences.getInstance();
    practiceSec = prefs.getInt('practice_sec') ?? 0;
    final rawSrc = prefs.getString('sources');
    sources = rawSrc != null ? (jsonDecode(rawSrc) as List).map((e) => MediaSource.fromJson(e)).toList() : defaultSources();
    final rawSaved = prefs.getString('saved');
    if (rawSaved != null) savedItems = (jsonDecode(rawSaved) as List).map((e) => MediaItem.fromJson(e)).toList();
    final rawProg = prefs.getString('progress');
    if (rawProg != null) progressMap = (jsonDecode(rawProg) as Map<String, dynamic>).map((k, v) => MapEntry(k, WatchProgress.fromJson(v)));
    if (sources.isNotEmpty) _selectSource(sources.first);
  }
  Future<void> _selectSource(MediaSource s) async {
    setState(() { activeSource = s; showOnlySaved = false; loading = true; items = []; });
    try {
      final list = await MediaFetcher.fetchItems(s);
      if (mounted) setState(() => items = list);
    } catch (e) {
      if (mounted) print("ZEN_ERR: $e"); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Помилка: $e')));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _saveProgress(MediaItem item, int posSec, int totSec, bool wasVideo) {
    progressMap[item.id] = WatchProgress(item: item, positionSec: posSec, totalSec: totSec > 0 ? totSec : item.durationSec, lastWasVideo: wasVideo, updatedAt: DateTime.now().millisecondsSinceEpoch);
    prefs.setString('progress', jsonEncode(progressMap.map((k, v) => MapEntry(k, v.toJson()))));
  }

  Future<void> _playAudio(MediaItem item) async {
    final startSec = progressMap[item.id]?.positionSec ?? 0;
    setState(() { currentItem = item; resolvingAudio = true; lastSavedTick = startSec; });
    try {
      final streamUrl = item.isYoutube ? await MediaFetcher.resolveYoutubeAudioUrl(item.url) : item.url;
      await player.open(Media(streamUrl), play: true);
      if (startSec > 3) { await Future.delayed(const Duration(milliseconds: 500)); await player.seek(Duration(seconds: startSec)); }
      _saveProgress(item, startSec, item.durationSec, false);
    } catch (e) {
      if (mounted) print("ZEN_ERR: $e"); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => resolvingAudio = false);
    }
  }

  Future<void> _playExternalVideo(MediaItem item) async {
    await player.pause();
    final startSec = progressMap[item.id]?.positionSec ?? 0;
    _saveProgress(item, startSec > 0 ? startSec : 10, item.durationSec, true);
    setState(() {});
    await MediaFetcher.openExternalVideo(item.url, startSec: startSec);
  }

  void _toggleSave(MediaItem item) {
    setState(() {
      savedItems.any((e) => e.id == item.id) ? savedItems.removeWhere((e) => e.id == item.id) : savedItems.add(item);
      prefs.setString('saved', jsonEncode(savedItems.map((e) => e.toJson()).toList()));
    });
  }

  @override
  void dispose() { player.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    final resumeList = progressMap.values.toList()..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final visible = (showOnlySaved ? savedItems : items).where((e) => search.isEmpty || e.title.toLowerCase().contains(search.toLowerCase())).toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).cardColor,
        title: Row(children: [
          Icon(Icons.spa, color: widget.accent), const SizedBox(width: 8),
          Text('Дзен Храм', style: TextStyle(color: widget.accent, fontWeight: FontWeight.bold)), const SizedBox(width: 20),
          SizedBox(width: 220, height: 36, child: TextField(onChanged: (v) => setState(() => search = v), decoration: InputDecoration(hintText: 'Пошук...', prefixIcon: const Icon(Icons.search, size: 18), contentPadding: EdgeInsets.zero, border: OutlineInputBorder(borderRadius: BorderRadius.circular(20))))),
        ]),
        actions: [
          TextButton.icon(onPressed: () => showBooksDialog(context, widget.accent), icon: Icon(Icons.menu_book, color: widget.accent), label: const Text('Книги')),
          TextButton.icon(onPressed: () => showDialog(context: context, builder: (_) => AlertDialog(title: const Text('Мій шлях'), content: Text('Час практики: ${practiceSec ~/ 60} хв.'))), icon: Icon(Icons.self_improvement, color: widget.accent), label: Text('${practiceSec ~/ 60} хв')),
          TextButton.icon(onPressed: () async { final s = await showAddSourceDialog(context); if (s != null) { setState(() => sources.add(s)); prefs.setString('sources', jsonEncode(sources.map((e) => e.toJson()).toList())); _selectSource(s); } }, icon: Icon(Icons.add_circle_outline, color: widget.accent), label: const Text('Додати')),
          IconButton(icon: Icon(showOnlySaved ? Icons.bookmark : Icons.bookmark_border, color: widget.accent), onPressed: () => setState(() => showOnlySaved = !showOnlySaved)),
          IconButton(tooltip: 'Оновити нові відео та подкасти', icon: Icon(Icons.refresh, color: widget.accent), onPressed: () { if (activeSource != null) _selectSource(activeSource!); }),
          IconButton(icon: Icon(Icons.palette, color: widget.accent), onPressed: widget.onToggleTheme),
        ],
      ),
      body: Row(children: [
        SizedBox(
          width: 240,
          child: Material(
            color: Theme.of(context).cardColor.withOpacity(0.6),
          child: ListView(padding: const EdgeInsets.all(8), children: [
            for (final cat in SourceCategory.values) ...[
              Padding(padding: const EdgeInsets.fromLTRB(10, 12, 10, 4), child: Text(cat == SourceCategory.youtube ? 'КАНАЛИ YOUTUBE' : cat == SourceCategory.audiobooks ? 'АУДІОКНИГИ УКР.' : 'ПОДКАСТИ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: widget.accent))),
              for (final s in sources.where((e) => e.category == cat))
                ListTile(dense: true, selected: !showOnlySaved && activeSource?.id == s.id, selectedTileColor: widget.accent.withOpacity(0.15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), title: Text(s.title, maxLines: 1, overflow: TextOverflow.ellipsis), onTap: () => _selectSource(s)),
            ],
          ]),
        )),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (resumeList.isNotEmpty) ...[
            Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 6), child: Text('Дивитися / слухати далі', style: TextStyle(fontWeight: FontWeight.bold, color: widget.accent))),
            SizedBox(height: 98, child: ListView.builder(padding: const EdgeInsets.symmetric(horizontal: 16), scrollDirection: Axis.horizontal, itemCount: resumeList.length, itemBuilder: (_, i) { final wp = resumeList[i]; return ResumeCard(wp: wp, accent: widget.accent, onAudio: () => _playAudio(wp.item), onVideo: () => _playExternalVideo(wp.item), onRemove: () => setState(() { progressMap.remove(wp.item.id); prefs.setString('progress', jsonEncode(progressMap.map((k, v) => MapEntry(k, v.toJson())))); })); })),
          ],
          Expanded(child: loading ? Center(child: CircularProgressIndicator(color: widget.accent)) : GridView.builder(padding: const EdgeInsets.all(16), gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 310, childAspectRatio: 1.12, crossAxisSpacing: 14, mainAxisSpacing: 14), itemCount: visible.length, itemBuilder: (_, i) { final item = visible[i]; return MediaCard(item: item, accent: widget.accent, isSaved: savedItems.any((e) => e.id == item.id), savedSec: progressMap[item.id]?.positionSec ?? 0, onAudio: () => _playAudio(item), onVideo: () => _playExternalVideo(item), onToggleSave: () => _toggleSave(item)); })),
        ])),
      ]),
      bottomNavigationBar: currentItem == null ? null : Container(
        height: 74, padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(color: Theme.of(context).cardColor, border: Border(top: BorderSide(color: widget.accent.withOpacity(0.3)))),
        child: Row(children: [
          if (resolvingAudio) SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: widget.accent))
          else IconButton(iconSize: 34, color: widget.accent, icon: Icon(isPlaying ? Icons.pause_circle : Icons.play_circle), onPressed: () => player.playOrPause()),
          const SizedBox(width: 10),
          SizedBox(width: 230, child: Text(currentItem!.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
          Text(fmtDur(pos.inSeconds), style: const TextStyle(fontSize: 12)),
          Expanded(child: Slider(activeColor: widget.accent, value: pos.inSeconds.toDouble().clamp(0, dur.inSeconds > 0 ? dur.inSeconds.toDouble() : 1), max: dur.inSeconds > 0 ? dur.inSeconds.toDouble() : 1, onChanged: (v) => player.seek(Duration(seconds: v.toInt())))),
          Text(fmtDur(dur.inSeconds), style: const TextStyle(fontSize: 12)), const SizedBox(width: 12),
          TextButton(onPressed: () { setState(() => rate = rate == 1.0 ? 1.25 : rate == 1.25 ? 1.5 : 1.0); player.setRate(rate); }, child: Text('${rate}x', style: TextStyle(color: widget.accent, fontWeight: FontWeight.bold))),
        ]),
      ),
    );
  }
}

