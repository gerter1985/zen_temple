import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'mantra_data.dart';
import 'om_service.dart';
import 'silence_view.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  runApp(const OmApp());
}
class OmApp extends StatefulWidget {
  const OmApp({super.key});
  @override
  State<OmApp> createState() => _OmAppState();
}

class _OmAppState extends State<OmApp> {
  bool isNeon = false;
  @override
  Widget build(BuildContext context) {
    final accent = isNeon ? const Color(0xFF00F5D4) : const Color(0xFFD4AF37);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ОМ • Мантра Медитація',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: isNeon ? const Color(0xFF090D16) : const Color(0xFF12100E),
        cardColor: isNeon ? const Color(0xFF111827) : const Color(0xFF1E1A16),
        colorScheme: ColorScheme.dark(primary: accent, secondary: accent),
      ),
      home: OmHome(accent: accent, onToggleTheme: () => setState(() => isNeon = !isNeon)),
    );
  }
}
class OmHome extends StatefulWidget {
  final Color accent;
  final VoidCallback onToggleTheme;
  const OmHome({super.key, required this.accent, required this.onToggleTheme});
  @override
  State<OmHome> createState() => _OmHomeState();
}

class _OmHomeState extends State<OmHome> {
  late final Player player;
  List<MantraTrack> tracks = [];
  Set<String> savedIds = {};
  List<MeditationSession> sessions = [];
  Map<String, OmMantraInfo> customTexts = {};
  MantraTrack? current;
  bool loading = true, isPlaying = false, showSavedOnly = false, resolving = false, silenceMode = false;
  String search = '';
  int beads = 0, sessionStartSec = 0;
  DateTime? sessionStartTime;
  @override
  void initState() {
    super.initState();
    player = Player();
    player.stream.playing.listen((v) { if (mounted) setState(() => isPlaying = v); });
    _init();
  }

  Future<void> _init() async {
    savedIds = await OmService.loadSavedIds();
    sessions = await OmService.loadSessions();
    final prefs = await SharedPreferences.getInstance();
    final rawCustom = prefs.getString('om_custom_texts');
    if (rawCustom != null) {
      customTexts = (jsonDecode(rawCustom) as Map<String, dynamic>).map((k, v) => MapEntry(k, OmMantraInfo.fromJson(v)));
    }
    try {
      tracks = await OmService.fetchPlaylist();
    } catch (_) {}
    if (mounted) {
      setState(() {
        loading = false;
        if (tracks.isNotEmpty) current = tracks.first;
      });
    }
  }
  OmMantraInfo _textFor(MantraTrack? t) {
    if (t == null) return kBuiltinMantras['om_root']!;
    return customTexts[t.id] ?? resolveMantraForTitle(t.title);
  }

  Future<void> _playTrack(MantraTrack t) async {
    if (beads > 0 && current != null) await _commitSession(silent: true);
    setState(() { current = t; resolving = true; beads = 0; sessionStartTime = DateTime.now(); });
    try {
      final stream = await OmService.resolveAudio(t.url);
      await player.open(Media(stream), play: true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Помилка: $e')));
    } finally {
      if (mounted) setState(() => resolving = false);
    }
  }

  void _tapBead() {
    HapticFeedback.lightImpact();
    sessionStartTime ??= DateTime.now();
    setState(() => beads++);
    if (beads % 108 == 0 && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('🪷 Завершено коло (Мала): ${beads ~/ 108} × 108!')));
    }
  }
  bool usePhysicalBeads = false;
  final TextEditingController _manualCtrl = TextEditingController();

  Future<void> _commitSession({bool silent = false}) async {
    if (beads <= 0 || current == null) return;
    final dur = sessionStartTime != null ? DateTime.now().difference(sessionStartTime!).inSeconds : 0;
    final s = MeditationSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      mantraTitle: _textFor(current).name,
      dateIso: DateTime.now().toString().substring(0, 16),
      beads: beads,
      malas: beads ~/ 108,
      durationSec: dur,
    );
    sessions.insert(0, s);
    await OmService.saveSessions(sessions);
    setState(() { beads = 0; _manualCtrl.clear(); sessionStartTime = DateTime.now(); });
    if (!silent && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✨ Сесію збережено назавжди (${s.beads} повторень)')));
    }
  }
  Future<void> _toggleSave(MantraTrack t) async {
    setState(() { savedIds.contains(t.id) ? savedIds.remove(t.id) : savedIds.add(t.id); });
    await OmService.saveSavedIds(savedIds);
  }

  Future<void> _editMantraDialog() async {
    if (current == null) return;
    final cur = _textFor(current);
    final nCtrl = TextEditingController(text: cur.name), sCtrl = TextEditingController(text: cur.sanskrit);
    final cCtrl = TextEditingController(text: cur.cyrillic), tCtrl = TextEditingController(text: cur.translation);
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Редагувати текст мантри'),
        content: SizedBox(width: 440, child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: nCtrl, decoration: const InputDecoration(labelText: 'Назва')),
          TextField(controller: sCtrl, decoration: const InputDecoration(labelText: 'Санскрит')),
          TextField(controller: cCtrl, decoration: const InputDecoration(labelText: 'Кирилиця (укр)')),
          TextField(controller: tCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Переклад')),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Скасувати')),
          ElevatedButton(onPressed: () async {
            customTexts[current!.id] = OmMantraInfo(name: nCtrl.text, sanskrit: sCtrl.text, cyrillic: cCtrl.text, translation: tCtrl.text);
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('om_custom_texts', jsonEncode(customTexts.map((k, v) => MapEntry(k, v.toJson()))));
            if (mounted) { setState(() {}); Navigator.pop(context); }
          }, child: const Text('Зберегти')),
        ],
      ),
    );
  }
  void _showHistoryDialog() {
    final total = sessions.fold<int>(0, (sum, e) => sum + e.beads);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Історія медитацій ($total мантр • ${total ~/ 108} кіл)'),
        content: SizedBox(
          width: 520, height: 400,
          child: sessions.isEmpty ? const Center(child: Text('Ще немає збережених сесій')) : ListView.builder(
            itemCount: sessions.length,
            itemBuilder: (_, i) {
              final s = sessions[i];
              return ListTile(
                title: Text(s.mantraTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('📅 ${s.dateIso} • 📿 ${s.beads} мантр (${s.malas} кіл)'),
              );
            },
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Закрити'))],
      ),
    );
  }
  @override
  void dispose() { player.dispose(); _manualCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final mText = _textFor(current);
    final visible = tracks.where((t) => (!showSavedOnly || savedIds.contains(t.id)) && (search.isEmpty || t.title.toLowerCase().contains(search.toLowerCase()))).toList();
    return Focus(
      autofocus: true,
      onKeyEvent: (_, e) {
        if (!usePhysicalBeads && e is KeyDownEvent && e.logicalKey == LogicalKeyboardKey.space) { _tapBead(); return KeyEventResult.handled; }
        return KeyEventResult.ignored;
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).cardColor,
          title: Row(children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [Text('ॐ ОМ', style: TextStyle(color: widget.accent, fontWeight: FontWeight.bold, fontSize: 20)), const Text('Автор проєкту: Євген Гертер', style: TextStyle(fontSize: 11, color: Colors.grey))]),
            const SizedBox(width: 20),
            SizedBox(width: 220, height: 36, child: TextField(onChanged: (v) => setState(() => search = v), decoration: InputDecoration(hintText: 'Пошук мантри...', prefixIcon: const Icon(Icons.search, size: 18), contentPadding: EdgeInsets.zero, border: OutlineInputBorder(borderRadius: BorderRadius.circular(20))))),
          ]),
          actions: [
            TextButton.icon(onPressed: () { player.pause(); setState(() => silenceMode = !silenceMode); }, icon: Icon(silenceMode ? Icons.queue_music : Icons.self_improvement, color: widget.accent), label: Text(silenceMode ? 'Плейлист' : 'Тиша')),
            TextButton.icon(onPressed: _showHistoryDialog, icon: Icon(Icons.history_edu, color: widget.accent), label: Text('Історія (${sessions.length})')),
            IconButton(tooltip: 'Тільки збережені', icon: Icon(showSavedOnly ? Icons.bookmark : Icons.bookmark_border, color: widget.accent), onPressed: () => setState(() => showSavedOnly = !showSavedOnly)),
            IconButton(tooltip: 'Змінити тему', icon: Icon(Icons.palette, color: widget.accent), onPressed: widget.onToggleTheme),
          ],
        ),
        body: silenceMode ? SilencePracticeView(accent: widget.accent, player: player, onSaveSession: (t, b, d) async { final item = MeditationSession(id: DateTime.now().millisecondsSinceEpoch.toString(), mantraTitle: t, dateIso: DateTime.now().toString().substring(0, 16), beads: b, malas: b ~/ 108, durationSec: d); sessions.insert(0, item); await OmService.saveSessions(sessions); if (mounted) { setState(() {}); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✨ Сесію збережено ($b повторень)'))); } }) : Row(children: [
          SizedBox(
            width: 270,
            child: Material(
              color: Theme.of(context).cardColor.withOpacity(0.6),
              child: loading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: visible.length,
                      itemBuilder: (_, i) {
                        final t = visible[i];
                        final sel = current?.id == t.id;
                        final saved = savedIds.contains(t.id);
                        return ListTile(
                          selected: sel,
                          selectedTileColor: widget.accent.withOpacity(0.15),
                          title: Text('${t.index}. ${t.title}', maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: sel ? widget.accent : null)),
                          trailing: IconButton(icon: Icon(saved ? Icons.bookmark : Icons.bookmark_border, size: 18, color: saved ? widget.accent : Colors.grey), onPressed: () => _toggleSave(t)),
                          onTap: () => _playTrack(t),
                        );
                      },
                    ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
                Text(mText.name, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: widget.accent), textAlign: TextAlign.center),
                if (current != null) Padding(padding: const EdgeInsets.only(top: 6), child: Text(current!.title, style: const TextStyle(color: Colors.grey, fontSize: 13), textAlign: TextAlign.center)),
                const SizedBox(height: 28),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(18), border: Border.all(color: widget.accent.withOpacity(0.35))),
                  child: Column(children: [
                    SelectableText(mText.sanskrit, style: TextStyle(fontSize: 34, fontWeight: FontWeight.w600, color: widget.accent, height: 1.5), textAlign: TextAlign.center),
                    const Divider(height: 32),
                    SelectableText(mText.cyrillic, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 1.1, height: 1.4), textAlign: TextAlign.center),
                    const Divider(height: 32),
                    SelectableText(mText.translation, style: const TextStyle(fontSize: 16, color: Colors.white70, height: 1.5), textAlign: TextAlign.center),
                  ]),
                ),
                const SizedBox(height: 20),
                Wrap(spacing: 12, runSpacing: 10, alignment: WrapAlignment.center, children: [
                  ElevatedButton.icon(
                    onPressed: current == null ? null : () => isPlaying ? player.pause() : (player.state.playlist.medias.isEmpty ? _playTrack(current!) : player.play()),
                    icon: resolving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                    label: Text(isPlaying ? 'Пауза' : 'Слухати мантру'),
                  ),
                  OutlinedButton.icon(onPressed: _editMantraDialog, icon: const Icon(Icons.edit, size: 18), label: const Text('Змінити текст')),
                ]),
              ]),
            ),
          ),
          Container(
            width: 320,
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).cardColor.withOpacity(0.5),
            child: Column(children: [
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: false, label: Text('Віртуальні'), icon: Icon(Icons.radio_button_checked, size: 16)),
                  ButtonSegment(value: true, label: Text('Живі чотки'), icon: Icon(Icons.edit_note, size: 16)),
                ],
                selected: {usePhysicalBeads},
                onSelectionChanged: (v) => setState(() => usePhysicalBeads = v.first),
              ),
              const SizedBox(height: 16),
              Text('Коло: ${beads % 108} / 108  •  Мала: ${beads ~/ 108}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: widget.accent)),
              Text('Усього в сесії: $beads', style: const TextStyle(color: Colors.grey, fontSize: 13)),
              const SizedBox(height: 14),
              Expanded(
                child: usePhysicalBeads
                    ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const Text('Впишіть кількість прочитаних мантр на живих чотках:', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70)),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _manualCtrl,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          decoration: const InputDecoration(hintText: '108', border: OutlineInputBorder()),
                          onChanged: (v) => setState(() { beads = int.tryParse(v) ?? 0; sessionStartTime ??= DateTime.now(); }),
                        ),
                        const SizedBox(height: 12),
                        Wrap(spacing: 8, children: [54, 108, 216, 1080].map((n) => ActionChip(label: Text('+$n'), onPressed: () {
                          sessionStartTime ??= DateTime.now();
                          setState(() { beads += n; _manualCtrl.text = '$beads'; });
                        })).toList()),
                      ])
                    : GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: _tapBead,
                        child: CustomPaint(
                          painter: MalaPainter(count: beads, accent: widget.accent),
                          child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                            Text('$beads', style: TextStyle(fontSize: 42, fontWeight: FontWeight.bold, color: widget.accent)),
                            const Text('Тап по трекпаду\nабо Пробіл', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.grey)),
                          ])),
                        ),
                      ),
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: OutlinedButton(onPressed: () => setState(() { beads = 0; _manualCtrl.clear(); }), child: const Text('Скинути'))),
                const SizedBox(width: 8),
                Expanded(child: ElevatedButton.icon(onPressed: beads > 0 ? () => _commitSession() : null, icon: const Icon(Icons.save, size: 18), label: const Text('Зберегти'))),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}
class MalaPainter extends CustomPainter {
  final int count;
  final Color accent;
  MalaPainter({required this.count, required this.accent});
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = math.min(size.width, size.height) * 0.42;
    final active = count % 108;
    for (int i = 0; i < 108; i++) {
      final a = -math.pi / 2 + (2 * math.pi * i / 108);
      final p = Offset(c.dx + r * math.cos(a), c.dy + r * math.sin(a));
      final isMarker = i == 0 || i % 27 == 0;
      final isDone = i < active;
      final paint = Paint()..color = i == 0 ? Colors.amber : (isDone ? accent : (isMarker ? accent.withOpacity(0.45) : Colors.white24));
      canvas.drawCircle(p, i == 0 ? 7.5 : (isMarker ? 5.0 : 3.4), paint);
    }
  }
  @override
  bool shouldRepaint(covariant MalaPainter old) => old.count != count || old.accent != accent;
}
