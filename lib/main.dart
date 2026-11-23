import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'yt_service.dart';

void main() async { WidgetsFlutterBinding.ensureInitialized(); try { Directory.current = File(Platform.resolvedExecutable).parent; MediaKit.ensureInitialized();  } catch (_) {} runApp(const TarotApp()); }
class AppThemeData { final String name; final List<Color> bg; final Color panel, accent; const AppThemeData(this.name, this.bg, this.panel, this.accent); }
const kThemes = [
  AppThemeData('🕯 Светоч Перекрестка', [Color(0xFF09080C), Color(0xFF14121A), Color(0xFF1E1B26)], Color(0xEE14121A), Color(0xFFE5B869)),
  AppThemeData('🌿 Сад Ядовитых Трав', [Color(0xFF081410), Color(0xFF10241D), Color(0xFF173329)], Color(0xEE10241D), Color(0xFFC89D54)),
  AppThemeData('🩸 Кровавая Луна', [Color(0xFF14070A), Color(0xFF240D12), Color(0xFF331219)], Color(0xEE240D12), Color(0xFFD94E4E)),
  AppThemeData('🌙 Трехликая Селена', [Color(0xFF070C18), Color(0xFF10192E), Color(0xFF182542)], Color(0xEE10192E), Color(0xFFC9D6EA)),
];
class TarotApp extends StatefulWidget { const TarotApp({super.key}); @override State<TarotApp> createState() => _TarotAppState(); }
class _TarotAppState extends State<TarotApp> {
  int tIdx = 0;
  @override Widget build(BuildContext context) { final th = kThemes[tIdx]; return MaterialApp(debugShowCheckedModeBanner: false, theme: ThemeData.dark().copyWith(colorScheme: ColorScheme.dark(primary: th.accent)), home: MainShell(th: th, tIdx: tIdx, onT: (i) => setState(() => tIdx = i))); }
}
class MainShell extends StatefulWidget { final AppThemeData th; final int tIdx; final ValueChanged<int> onT; const MainShell({super.key, required this.th, required this.tIdx, required this.onT}); @override State<MainShell> createState() => _MainShellState(); }
class _MainShellState extends State<MainShell> {
  final bgPlayer = Player(), medPlayer = Player(), voicePlayer = Player(), scrollCtrl = ScrollController();
  bool voiceMedOn = false;
  Timer? scrollTimer; String cardSearch = '';
  bool authLaid = false, showAuthAns = false, bgOn = false, showAns = false, laid = false, showSpAns = false, loadingYt = false, isRec = false, onlyFav = false;
  List<YtVideo> favVideos = YtService.loadFavs();
  Set<String> startedIds = YtService.loadStarted();
  Process? recProc;
  int authIdx = -1, authCaseIdx = 0, authSalt = 0, tab = 0, cardIdx = 0, qIdx = 0, salt = 0, medIdx = 0, activeTrack = -1, spIdx = 0, spCaseIdx = 0, spSalt = 0;
  List<Map<String, dynamic>> rndDrawn = [], authRndDrawn = [];
  double speed = 28;
  List<dynamic> authorSpreads = [], lessons = [], spreads = [], authors = [], meds = [];
  List<YtVideo> videos = [];
  List<Map<String, String>> tracks = [
    {'name': '1. Поток Гекаты • 1', 'src': 'asset:///assets/music/1.mp3'},
    {'name': '2. Поток Гекаты • 2', 'src': 'asset:///assets/music/2.mp3'},
    {'name': '3. Поток Гекаты • 3', 'src': 'asset:///assets/music/3.mp3'},
  ];
  final ansCtrl = TextEditingController(), ytVidCtrl = TextEditingController(), ytMedCtrl = TextEditingController(), spNameCtrl = TextEditingController();
  final spPosCtrls = [TextEditingController(), TextEditingController(), TextEditingController()];
  List<Map<String, String>> customSp = [];
  @override void initState() {
    super.initState();
    rootBundle.loadString('assets/data/tarot.json').then((raw) { final j = jsonDecode(raw); setState(() { lessons = j['CARD_LESSONS'] ?? []; spreads = j['SPREAD_LESSONS'] ?? []; authorSpreads = j['AUTHOR_SPREADS'] ?? []; authors = j['AUTHOR_LESSONS'] ?? []; meds = j['MEDITATION_CARDS'] ?? []; for (final id in ['HLCXUD9zMlA','QnSGLmn3udI','_Nqlg_hZdVc','PLtx2tqJ6K3MC49y2Se5AVW_C8tFlXLbyH']) { YtService.resolveAudio(id); } }); });
    medPlayer.stream.completed.listen((d) { if (d && activeTrack >= 0) _playTrack((activeTrack + 1) % tracks.length); });
    scrollTimer = Timer.periodic(const Duration(milliseconds: 50), (_) { if (tab == 4 && scrollCtrl.hasClients && scrollCtrl.position.maxScrollExtent > 0) { final n = scrollCtrl.offset + speed / 25; scrollCtrl.jumpTo(n >= scrollCtrl.position.maxScrollExtent ? 0 : n); } });
  }
  Future<void> _speakMaster(String txt, {String mode = 'teach'}) async {
    if (voiceMedOn) { await voicePlayer.stop(); setState(() => voiceMedOn = false); if (mode == 'med') return; }
    setState(() => voiceMedOn = mode == 'med');
    try { File("${Directory.systemTemp.path}/master_voice.mp3").deleteSync(); } catch (_) {}
    await Process.run(Platform.isWindows ? "${File(Platform.resolvedExecutable).parent.path}/python/python.exe" : "python3", ['${File('${File(Platform.resolvedExecutable).parent.path}//home/evgen/hecate_flutter/voice_tts.py').existsSync() ? '${File(Platform.resolvedExecutable).parent.path}//home/evgen/hecate_flutter/voice_tts.py' : '/home/evgen/hecate_flutter/voice_tts.py'}', txt, mode]);
    await voicePlayer.open(Media('${Directory.systemTemp.path}/master_voice.mp3'));
  }
  Future<void> _toggleVoice() async {
    final wav = "${Directory.systemTemp.path}/tarot_voice.wav";
    if (!isRec) {
      recProc = await Process.start(Platform.isWindows ? "${File(Platform.resolvedExecutable).parent.path}/python/python.exe" : "arecord", Platform.isWindows ? ["${File('${File(Platform.resolvedExecutable).parent.path}/voice_rec.py').existsSync() ? '${File(Platform.resolvedExecutable).parent.path}/voice_rec.py' : 'voice_rec.py'}", wav] : ["-f", "S16_LE", "-r", "16000", "-c", "1", wav]);
      setState(() => isRec = true);
    } else {
      if (Platform.isWindows) { recProc?.stdin.writeln(); } else { recProc?.kill(); }
      await Future.delayed(const Duration(milliseconds: 250));
      setState(() { isRec = false; ansCtrl.text = 'Распознавание голоса...'; });
      final res = await Process.run('python3', ['${File('${File(Platform.resolvedExecutable).parent.path}//home/evgen/hecate_flutter/voice_stt.py').existsSync() ? '${File(Platform.resolvedExecutable).parent.path}//home/evgen/hecate_flutter/voice_stt.py' : '/home/evgen/hecate_flutter/voice_stt.py'}', wav]);
      final txt = res.stdout.toString().trim();
      setState(() => ansCtrl.text = txt.isNotEmpty ? txt : 'Не удалось распознать — попробуйте еще раз');
    }
  }
  int bgIdx = 0; List<String> bgList = ['asset:///assets/music/1.mp3', 'asset:///assets/music/2.mp3', 'asset:///assets/music/3.mp3', 'asset:///assets/music/4.mp3'];
  Future<void> _nextBg() async { if (bgList.isEmpty) return; final id = bgList[bgIdx % bgList.length]; bgIdx++; final u = id.startsWith("asset:") ? id : await YtService.resolveAudio(id); if (u.isNotEmpty) { await bgPlayer.setVolume(30); await bgPlayer.open(Media(u)); if (mounted) setState(() => bgOn = true); } }
  Future<void> _toggleBg() async { if (bgOn) { await bgPlayer.pause(); setState(() => bgOn = false); } else { await bgPlayer.setPlaylistMode(PlaylistMode.loop); await bgPlayer.setVolume(35); await _nextBg(); } }
  Future<void> _playTrack(int i) async { if (bgOn) { await bgPlayer.pause(); bgOn = false; } if (activeTrack == i) { await medPlayer.pause(); setState(() => activeTrack = -1); return; } setState(() { activeTrack = i; loadingYt = true; }); try { var s = tracks[i]['src']!; if (s.startsWith('yt:')) s = await YtService.resolveAudio(s.substring(3)); await medPlayer.open(Media(s)); } catch (_) {} if (mounted) setState(() => loadingYt = false); }
  @override void dispose() { scrollTimer?.cancel(); bgPlayer.dispose(); medPlayer.dispose(); voicePlayer.dispose(); super.dispose(); }
  List<Map<String, dynamic>> _spCases(Map<String, dynamic> sp) {
    final base = {'q': sp['practice']['client'], 'd': sp['practice']['drawn'], 'v': sp['practice']['masterVerdict']};
    const names = ['Оксана (31 год)', 'Артем (28 лет)', 'Светлана (39 лет)', 'Богдан (34 года)', 'Юлия (26 лет)', 'Дмитрий (42 года)', 'Анна (33 года)', 'Роман (37 лет)'];
    const topics = ['Как будет развиваться мое дело в ближайшие два месяца?', 'Какие истинные намерения у человека, с которым мы недавно познакомились?', 'Стоит ли соглашаться на новое предложение и менять привычный ритм?', 'Что поможет выйти из затяжной паузы и сдвинуть ситуацию с места?'];
    final list = <Map<String, dynamic>>[base];
    for (int k = 1; k < 5; k++) {
      final sd = (sp['id'] as int) * 19 + k * 7 + spSalt * 13;
      final pool = [...lessons]..shuffle(Random(sd));
      final drawn = pool.take(3).map((x) => {'name': x['title'].toString().replaceFirst(RegExp(r'^Карта \d+\.\s*'), ''), 'img': x['img'], 'meaning': x['simple']}).toList();
      final pos = List<String>.from(sp['positions']);
        final hints = sp['hints'] != null ? List<String>.from(sp['hints']) : ['Исходная точка / мысли', 'Текущее состояние / выбор', 'Итог и совет'];

      list.add({'q': '${names[sd % names.length]}: «${topics[(sd + k) % topics.length]}»', 'd': drawn, 'v': 'В позиции «${pos.first}» выпадает ${drawn.first['name']} — ${drawn.first['meaning']}. В позиции «${pos.elementAt(1)}» видим ${drawn.elementAt(1)['name']} — ${drawn.elementAt(1)['meaning']}. Итог в «${pos.last}» — ${drawn.last['name']}: ${drawn.last['meaning']}.'});
    }
    return list;
  }
  List<Map<String, String>> _qs(Map<String, dynamic> c) { const ns = ['Андрей', 'Марина', 'Алексей', 'Татьяна', 'Дмитрий', 'Екатерина']; final sd = DateTime.now().millisecondsSinceEpoch ~/ 86400000 + (c['id'] as int) * 7 + salt * 13; final b = ((c['situations'] as List?) ?? []).map((x) => {'s': x['story'].toString().replaceFirst(RegExp(r'^\d+\.\s*'), ''), 'm': x['master'].toString()}).toList(); final g = [{'s': '${ns[sd % ns.length]} спрашивает о работе и деньгах. Выпадает «${c['title']}». Как растолкуешь?', 'm': '${c['work']} Совет: ${c['advice']}'}, {'s': '${ns[(sd + 2) % ns.length]} спрашивает об отношениях. Выпадает «${c['title']}». Что скажешь?', 'm': '${c['love']} Совет: ${c['advice']}'}]; return ([...b, ...g]..shuffle(Random(sd))).take(5).toList(); }
  Widget _pill(AppThemeData th, String txt, bool act, VoidCallback tap, {double h = 14, double v = 8, double fs = 18}) => InkWell(onTap: tap, borderRadius: BorderRadius.circular(12), child: Container(padding: EdgeInsets.symmetric(horizontal: h, vertical: v), decoration: BoxDecoration(color: act ? th.accent : Colors.black45, borderRadius: BorderRadius.circular(12), border: Border.all(color: act ? th.accent : th.accent.withOpacity(0.25))), child: Text(txt, style: TextStyle(fontSize: fs, fontWeight: FontWeight.bold, color: act ? Colors.black : Colors.white))));
  @override Widget build(BuildContext context) {
    final th = widget.th;
    const tabs = ['1. Изучение карт (195)', '2. Практика раскладов', '3. Видеотека (YouTube)', '4. Авторские расклады'];
    return Scaffold(body: Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: th.bg)), child: Column(children: [
      Container(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14), color: th.panel, child: Wrap(spacing: 12, runSpacing: 8, alignment: WrapAlignment.spaceBetween, crossAxisAlignment: WrapCrossAlignment.center, children: [
        Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.auto_awesome, color: th.accent, size: 24), const SizedBox(width: 10), const Text('ОРАКУЛ ГЕКАТЫ • ШКОЛА МАСТЕРА  |  Автор: Евгений Гертер', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))]),
        Wrap(spacing: 8, children: [_pill(th, bgOn ? '🔊 Фон: Включен' : '🔇 Фон: Выключен', bgOn, _toggleBg), ...List.generate(kThemes.length, (i) => _pill(th, kThemes[i].name, widget.tIdx == i, () => widget.onT(i))), _pill(th, "❐", false, () => () { if (Platform.isLinux) Process.run("wmctrl", ["-r", ":ACTIVE:", "-b", "toggle,fullscreen"]); }, h: 12), _pill(th, "✕", false, () => exit(0), h: 12)]),
      ])),
      Container(width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10), color: Colors.black38, child: Wrap(spacing: 10, runSpacing: 8, children: List.generate(tabs.length, (i) => _pill(th, tabs[i], tab == i, () => setState(() => tab = i), h: 18, v: 10, fs: 19)))),
      Expanded(child: Padding(padding: const EdgeInsets.all(20), child: _body(th))),
    ])));
  }
  Widget _slot(AppThemeData th, List<Map<String, dynamic>> drawn, List<String> pos, List<String> hints, int i, {bool cross = false}) {
    final d = drawn.elementAt(i);
    return Container(width: 215, margin: const EdgeInsets.all(6), padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(14), border: Border.all(color: th.accent.withOpacity(0.6), width: 1.5)), child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width: double.infinity, padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: th.accent.withOpacity(0.18), borderRadius: BorderRadius.circular(8)), child: Column(children: [Text(pos.elementAt(i), textAlign: TextAlign.center, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: th.accent)), Text(hints.elementAt(i % hints.length), textAlign: TextAlign.center, style: const TextStyle(fontSize: 12.5, color: Colors.white70))])),
      const SizedBox(height: 8),
      RotatedBox(quarterTurns: cross ? 1 : 0, child: ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.asset('assets/cards/${d['img'].toString().split('/').last}', height: cross ? 150 : 185))),
      const SizedBox(height: 6), Text(d['name'], textAlign: TextAlign.center, style: TextStyle(color: th.accent, fontWeight: FontWeight.bold, fontSize: 16)), Text(d['meaning'], textAlign: TextAlign.center, style: const TextStyle(fontSize: 14)),
    ]));
  }
  Widget _tableLayout(AppThemeData th, List<Map<String, dynamic>> drawn, List<String> pos, List<String> hints) {
    if (pos.length == 10) {
      return SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [
        Column(children: [_slot(th, drawn, pos, hints, 4), Row(children: [_slot(th, drawn, pos, hints, 3), Column(children: [_slot(th, drawn, pos, hints, 0), _slot(th, drawn, pos, hints, 1, cross: true)]), _slot(th, drawn, pos, hints, 5)]), _slot(th, drawn, pos, hints, 2)]),
        const SizedBox(width: 30),
        Column(children: [_slot(th, drawn, pos, hints, 9), _slot(th, drawn, pos, hints, 8), _slot(th, drawn, pos, hints, 7), _slot(th, drawn, pos, hints, 6)]),
      ]));
    }
    if (pos.length == 7) {
      return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Column(children: [_slot(th, drawn, pos, hints, 0), _slot(th, drawn, pos, hints, 1), _slot(th, drawn, pos, hints, 2)]),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: _slot(th, drawn, pos, hints, 6)),
        Column(children: [_slot(th, drawn, pos, hints, 3), _slot(th, drawn, pos, hints, 4), _slot(th, drawn, pos, hints, 5)]),
      ]);
    }
    if (pos.length == 5) {
      return Column(children: [_slot(th, drawn, pos, hints, 3), Row(mainAxisAlignment: MainAxisAlignment.center, children: [_slot(th, drawn, pos, hints, 1), _slot(th, drawn, pos, hints, 0), _slot(th, drawn, pos, hints, 2)]), _slot(th, drawn, pos, hints, 4)]);
    }
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(pos.length, (i) => Expanded(child: _slot(th, drawn, pos, hints, i))));
  }

  Widget _box(AppThemeData th, String l, String t) => Container(width: double.infinity, padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white12)), child: RichText(text: TextSpan(style: const TextStyle(fontSize: 22, height: 1.6, color: Colors.white), children: [TextSpan(text: '$l: ', style: TextStyle(color: th.accent, fontWeight: FontWeight.bold)), TextSpan(text: t)])));
  Widget _body(AppThemeData th) {
    if (tab == 0 && lessons.isNotEmpty) {
      final c = lessons[cardIdx], qs = _qs(c), q = qs[qIdx % qs.length], img = 'assets/cards/${c['img'].toString().split('/').last}';
      return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 265, child: Column(children: [TextField(onChanged: (v) => setState(() => cardSearch = v.trim().toLowerCase()), decoration: InputDecoration(hintText: '🔍 Поиск карты...', filled: true, fillColor: Colors.black38, contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))), const SizedBox(height: 8), Expanded(child: Builder(builder: (_) { final fl = lessons.where((e) => cardSearch.isEmpty || e['title'].toString().toLowerCase().contains(cardSearch)).toList(); return ListView.builder(itemCount: fl.length, itemBuilder: (_, i) => Padding(padding: const EdgeInsets.only(bottom: 8), child: _pill(th, fl[i]['title'], lessons[cardIdx]['id'] == fl[i]['id'], () => setState(() { cardIdx = lessons.indexOf(fl[i]); qIdx = 0; showAns = false; ansCtrl.clear(); }), h: 14, v: 12, fs: 14))); }))])), const SizedBox(width: 18),
        Expanded(child: SingleChildScrollView(child: Container(padding: const EdgeInsets.all(22), decoration: BoxDecoration(color: th.panel, borderRadius: BorderRadius.circular(16), border: Border.all(color: th.accent.withOpacity(0.3))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ClipRRect(borderRadius: BorderRadius.circular(14), child: Image.asset(img, width: 255)),
            const SizedBox(width: 20),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(c['title'], style: const TextStyle(fontSize: 34, fontWeight: FontWeight.bold)), const SizedBox(height: 12), _box(th, 'ЧТО ИЗОБРАЖЕНО НА КАРТЕ', c['symbols']), const SizedBox(height: 10), _box(th, 'КЛЮЧЕВОЙ СМЫСЛ КАРТЫ', c['simple'])])),
          ]),
          const SizedBox(height: 14), _box(th, 'ЛЮБОВЬ И ОТНОШЕНИЯ', c['love']), const SizedBox(height: 10), _box(th, 'РАБОТА, БИЗНЕС И ДЕНЬГИ', c['work']), const SizedBox(height: 10), _box(th, 'ГЛАВНЫЙ СОВЕТ КАРТЫ', c['advice']), const SizedBox(height: 10), _box(th, 'ПОДРОБНЫЙ ЭНЦИКЛОПЕДИЧЕСКИЙ РАЗБОР', c['deep'] ?? c['simple']), const SizedBox(height: 16),
          Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.circular(12)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('ТРЕНАЖЕР (${(qIdx % qs.length) + 1}/${qs.length}): ${q['s']}', style: const TextStyle(fontSize: 21)), const SizedBox(height: 10),
            TextField(controller: ansCtrl, maxLines: 2, decoration: const InputDecoration(hintText: 'Ваш ответ...', filled: true, fillColor: Colors.black45)), const SizedBox(height: 10),
            Wrap(spacing: 10, children: [_pill(th, isRec ? '⏹ Стоп (распознать)' : '🎙 Ответить голосом', isRec, _toggleVoice), _pill(th, 'Проверить себя', true, () { setState(() => showAns = true); _speakMaster(q['m']!); }), _pill(th, '🔊 Голос мастера', false, () => _speakMaster(q['m']!)), _pill(th, 'Следующий →', false, () => setState(() { qIdx++; showAns = false; ansCtrl.clear(); })), _pill(th, 'Новые 5 вопросов ↻', false, () => setState(() { salt++; qIdx = 0; showAns = false; }))]),
            if (showAns) Padding(padding: const EdgeInsets.only(top: 10), child: Text('Мастер: ${q['m']}', style: TextStyle(color: th.accent, fontSize: 16))),
          ])),
        ])))),
      ]);
    }
    if (tab == 1 && spreads.isNotEmpty) {
      final sp = spreads.elementAt(spIdx % spreads.length);
      final cases = _spCases(sp);
      final curC = cases.elementAt(spCaseIdx % cases.length);
      final drawn = rndDrawn.isNotEmpty ? rndDrawn : List<Map<String, dynamic>>.from(curC['d']);
      final pos = List<String>.from(sp['positions']);
      final verdict = rndDrawn.isNotEmpty ? 'Позиция 1: ${drawn.first['name']} — ${drawn.first['meaning']}. Позиция 2: ${drawn.elementAt(1)['name']} — ${drawn.elementAt(1)['meaning']}. Итог: ${drawn.last['name']} — ${drawn.last['meaning']}.' : curC['v'];
      return SingleChildScrollView(child: Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: th.panel, borderRadius: BorderRadius.circular(16)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Wrap(spacing: 8, runSpacing: 8, children: List.generate(spreads.length, (i) => _pill(th, spreads.elementAt(i)['title'], spIdx == i, () => setState(() { spIdx = i; spCaseIdx = 0; laid = false; showSpAns = false; rndDrawn = []; ansCtrl.clear(); }), h: 12, v: 8, fs: 14))),
        const SizedBox(height: 14), Text(sp['title'], style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)), const SizedBox(height: 10),
        _box(th, 'ПОДРОБНАЯ ИНСТРУКЦИЯ РАСКЛАДА (СТРУКТУРА, ПОЗИЦИИ И КАК ЧИТАТЬ)', sp['guide'] ?? sp['desc']), const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('ЗАПРОСЫ КЛИЕНТОВ (${(spCaseIdx % cases.length) + 1}/${cases.length}):', style: TextStyle(color: th.accent, fontWeight: FontWeight.bold, fontSize: 16)),
          Wrap(spacing: 6, children: [...List.generate(cases.length, (i) => _pill(th, '${i + 1}', (spCaseIdx % cases.length) == i, () => setState(() { spCaseIdx = i; laid = false; showSpAns = false; rndDrawn = []; ansCtrl.clear(); }), h: 10, v: 5, fs: 13)), _pill(th, 'Новые 5 запросов ↻', false, () => setState(() { spSalt++; spCaseIdx = 0; laid = false; showSpAns = false; rndDrawn = []; }), h: 10, v: 5, fs: 13)]),
        ]),
        const SizedBox(height: 8), _box(th, 'СИТУАЦИЯ КЛИЕНТА', curC['q']), const SizedBox(height: 14),
        Wrap(spacing: 10, children: [
          _pill(th, laid ? '🔄 Перетасовать (Новые 3 карты из 195)' : '🃏 Выложить карты клиенту', true, () { if (!laid) { setState(() => laid = true); return; } final pool = [...lessons]..shuffle(); setState(() { rndDrawn = pool.take(3).map((x) => {'name': x['title'].toString().replaceFirst(RegExp(r'^Карта \d+\.\s*'), ''), 'img': x['img'], 'meaning': x['simple']}).toList(); showSpAns = false; ansCtrl.clear(); }); }),
          if (rndDrawn.isNotEmpty) _pill(th, '↩ Вернуть карты запроса', false, () => setState(() { rndDrawn = []; showSpAns = false; })),
        ]),
        if (laid) ...[
          const SizedBox(height: 16),
          _tableLayout(th, drawn, pos, sp['hints'] != null ? List<String>.from(sp['hints']) : ['Исходная точка / мысли', 'Текущее состояние / выбор', 'Итог и совет']),
          const SizedBox(height: 14),
          TextField(controller: ansCtrl, maxLines: 2, style: const TextStyle(fontSize: 17), decoration: const InputDecoration(hintText: 'Озвуч голосом або напиши трактування...', filled: true, fillColor: Colors.black45, border: OutlineInputBorder())),
          const SizedBox(height: 10),
          Wrap(spacing: 10, children: [
            _pill(th, isRec ? '⏹ Стоп' : '🎙 Ответить голосом', isRec, _toggleVoice),
            _pill(th, 'Проверить себя', true, () { setState(() => showSpAns = true); _speakMaster(verdict); }),
            _pill(th, '🔊 Голос мастера', false, () => _speakMaster(verdict)),
          ]),
          if (showSpAns) Container(margin: const EdgeInsets.only(top: 12), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.teal.withOpacity(0.22), borderRadius: BorderRadius.circular(12), border: Border.all(color: th.accent)), child: Text('Мастер: $verdict', style: TextStyle(color: th.accent, fontSize: 18, height: 1.5))),
        ],
      ])));
    }
    if (tab == 2) {
      const presets = ['Оракул Гекаты значение карт', 'Расклады на Оракуле Гекаты', 'Магия Гекаты и перекрестка', 'Медитации с Оракулом Гекаты'];
      final shown = onlyFav ? favVideos : videos;
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: TextField(controller: ytVidCtrl, style: const TextStyle(fontSize: 16), decoration: InputDecoration(hintText: 'Ссылка на видео, @канал YouTube или тема...', filled: true, fillColor: th.panel, border: const OutlineInputBorder()))),
          const SizedBox(width: 8),
          _pill(th, 'Вставити', false, () async { final d = await Clipboard.getData('text/plain'); if (d?.text != null) ytVidCtrl.text = d!.text!; }),
          const SizedBox(width: 8),
          _pill(th, loadingYt ? 'Загрузка...' : '+ Найти / Оновити', true, () async { final q = ytVidCtrl.text.trim().isEmpty ? presets.first : ytVidCtrl.text.trim(); setState(() { loadingYt = true; onlyFav = false; }); final l = await YtService.fetchChannelOrVideo(q, exclude: videos.map((e) => e.id).toSet()); setState(() { videos = [...l, ...videos]; loadingYt = false; ytVidCtrl.clear(); }); }),
        ]),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 6, children: [
          _pill(th, '📺 Найденные (${videos.length})', !onlyFav, () => setState(() => onlyFav = false), h: 12, v: 6, fs: 13),
          _pill(th, '⭐ Збережене (${favVideos.length})', onlyFav, () => setState(() => onlyFav = true), h: 12, v: 6, fs: 13),
          ...presets.map((q) => _pill(th, '🔄 $q', false, () async { setState(() { loadingYt = true; onlyFav = false; }); final l = await YtService.fetchChannelOrVideo(q, exclude: videos.map((e) => e.id).toSet()); setState(() { videos = [...l, ...videos]; loadingYt = false; }); }, h: 12, v: 6, fs: 13)),
        ]),
        const SizedBox(height: 12),
        if (shown.isEmpty) Expanded(child: Center(child: Text(onlyFav ? 'Нажмите «☆ Сохранить» на видео, чтобы добавить его в закладки' : 'Нажмите любую тему сверху или вставьте @канал YouTube', style: const TextStyle(fontSize: 18, color: Colors.white70))))
        else Expanded(child: GridView.builder(gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 310, childAspectRatio: 0.98, crossAxisSpacing: 14, mainAxisSpacing: 14), itemCount: shown.length, itemBuilder: (_, i) {
          final v = shown.elementAt(i);
          final isFav = favVideos.any((f) => f.id == v.id);
          final isCont = startedIds.contains(v.id);
          return InkWell(onTap: () => YtService.openVideo(v, () => setState(() => startedIds = YtService.loadStarted())), child: Container(decoration: BoxDecoration(color: th.panel, borderRadius: BorderRadius.circular(14), border: Border.all(color: isFav ? th.accent : th.accent.withOpacity(0.3))), child: Column(children: [
            Expanded(child: Stack(children: [
              ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(14)), child: Image.network(v.thumb, width: double.infinity, height: double.infinity, fit: BoxFit.cover)),
              if (isCont) Positioned(bottom: 6, left: 6, child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: th.accent, borderRadius: BorderRadius.circular(8)), child: const Text('▶ Продовжити', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)))),
            ])),
            Padding(padding: const EdgeInsets.all(8), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(v.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                _pill(th, isFav ? '⭐ Сохранено' : '☆ Сохранить', isFav, () { setState(() { if (isFav) { favVideos.removeWhere((f) => f.id == v.id); } else { favVideos.insert(0, v); } YtService.saveFavs(favVideos); }); }, h: 10, v: 4, fs: 12.5),
                InkWell(onTap: () => setState(() { if (onlyFav) { favVideos.removeAt(i); YtService.saveFavs(favVideos); } else { videos.removeAt(i); } }), child: const Icon(Icons.delete_outline, size: 20, color: Colors.white54)),
              ]),
            ])),
          ])));
        })),
      ]);
    }
    if (tab == 3) {
      if (authorSpreads.isEmpty) return const Center(child: CircularProgressIndicator());
      if (authIdx < 0) {
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('✨ Авторские расклады Школы (10 уникальных схем)', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Text('Автор: Евгений Гертер', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: th.accent)),
          ]),
          const SizedBox(height: 12),
          Expanded(child: GridView.builder(gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 340, childAspectRatio: 0.92, crossAxisSpacing: 16, mainAxisSpacing: 16), itemCount: authorSpreads.length, itemBuilder: (_, i) {
            final a = authorSpreads.elementAt(i);
            final cnt = (a['positions'] as List).length;
            return InkWell(onTap: () => setState(() { authIdx = i; authCaseIdx = 0; authLaid = false; showAuthAns = false; authRndDrawn = []; ansCtrl.clear(); }), child: Container(decoration: BoxDecoration(color: th.panel, borderRadius: BorderRadius.circular(16), border: Border.all(color: th.accent.withOpacity(0.55), width: 1.5)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(15)), child: Image.asset(a['img'], height: 155, width: double.infinity, fit: BoxFit.cover)),
              Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(a['title'], maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: th.accent)),
                const SizedBox(height: 4),
                Text('${a['sub']} • $cnt карт', style: const TextStyle(fontSize: 13.5, color: Colors.white70)),
                const SizedBox(height: 6),
                Text(a['author'] ?? 'Автор: Евгений Гертер', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: th.accent.withOpacity(0.9))),
              ])),
            ])));
          })),
        ]);
      }
      final sp = authorSpreads.elementAt(authIdx % authorSpreads.length);
      final cases = _spCases({...sp, 'id': (sp['id'] as int) + 100});
      final curC = cases.elementAt(authCaseIdx % cases.length);
      final drawn = authRndDrawn.isNotEmpty ? authRndDrawn : List<Map<String, dynamic>>.from(curC['d']);
      final pos = List<String>.from(sp['positions']);
      final hints = List<String>.from(sp['hints'] ?? pos);
      final verdict = authRndDrawn.isNotEmpty ? List.generate(pos.length, (j) => '${pos.elementAt(j)}: ${drawn.elementAt(j)['name']} — ${drawn.elementAt(j)['meaning']}').join(' ') : curC['v'];
      return SingleChildScrollView(child: Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: th.panel, borderRadius: BorderRadius.circular(16)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          _pill(th, '← Все 10 авторских раскладов', true, () => setState(() => authIdx = -1)),
          Text(sp['author'] ?? 'Автор: Евгений Гертер', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: th.accent)),
        ]),
        const SizedBox(height: 14), Text('${sp['title']} (${pos.length} карт)', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)), const SizedBox(height: 10),
                _box(th, 'О РАСКЛАДЕ: ПРЕДЫСТОРИЯ, КОГДА ПРИМЕНЯТЬ И ПРАВИЛА ЧТЕНИЯ', sp['guide'] ?? sp['desc']), const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('ЗАПРОСЫ КЛИЕНТОВ (${(authCaseIdx % cases.length) + 1}/${cases.length}):', style: TextStyle(color: th.accent, fontWeight: FontWeight.bold, fontSize: 16)),
          Wrap(spacing: 6, children: [...List.generate(cases.length, (i) => _pill(th, '${i + 1}', (authCaseIdx % cases.length) == i, () => setState(() { authCaseIdx = i; authLaid = false; showAuthAns = false; authRndDrawn = []; ansCtrl.clear(); }), h: 10, v: 5, fs: 13)), _pill(th, 'Новые 5 запросов ↻', false, () => setState(() { authSalt++; authCaseIdx = 0; authLaid = false; showAuthAns = false; authRndDrawn = []; }), h: 10, v: 5, fs: 13)]),
        ]),
        const SizedBox(height: 8), _box(th, 'СИТУАЦИЯ КЛИЕНТА', curC['q']), const SizedBox(height: 14),
        Wrap(spacing: 10, children: [
          _pill(th, authLaid ? '🔄 Перетасовать (Новые ${pos.length} карт из 195)' : '🃏 Выложить ${pos.length} карт на стол', true, () { if (!authLaid) { setState(() => authLaid = true); return; } final pool = [...lessons]..shuffle(); setState(() { authRndDrawn = pool.take(pos.length).map((x) => {'name': x['title'].toString().replaceFirst(RegExp(r'^Карта \d+\.\s*'), ''), 'img': x['img'], 'meaning': x['simple']}).toList(); showAuthAns = false; ansCtrl.clear(); }); }),
          if (authRndDrawn.isNotEmpty) _pill(th, '↩ Вернуть карты запроса', false, () => setState(() { authRndDrawn = []; showAuthAns = false; })),
        ]),
        if (authLaid) ...[
          const SizedBox(height: 16), _tableLayout(th, drawn, pos, hints), const SizedBox(height: 14),
          TextField(controller: ansCtrl, maxLines: 2, style: const TextStyle(fontSize: 17), decoration: const InputDecoration(hintText: 'Озвуч голосом або напиши авторське трактування раскладу...', filled: true, fillColor: Colors.black45, border: OutlineInputBorder())),
          const SizedBox(height: 10),
          Wrap(spacing: 10, children: [
            _pill(th, isRec ? '⏹ Стоп (распознать)' : '🎙 Ответить голосом', isRec, _toggleVoice),
            _pill(th, 'Проверить себя (Ответ автора)', true, () { setState(() => showAuthAns = true); _speakMaster(verdict); }),
            _pill(th, '🔊 Голос мастера', false, () => _speakMaster(verdict)),
          ]),
          if (showAuthAns) Container(margin: const EdgeInsets.only(top: 12), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.teal.withOpacity(0.22), borderRadius: BorderRadius.circular(12), border: Border.all(color: th.accent)), child: Text('Мастер: $verdict', style: TextStyle(color: th.accent, fontSize: 18, height: 1.5))),
        ],
      ])));
    }

    if (meds.isNotEmpty) {
      final m = meds.elementAt(medIdx % meds.length);
      return Row(children: [
        SizedBox(width: 280, child: ListView.builder(itemCount: meds.length, itemBuilder: (_, i) => ListTile(selected: medIdx == i, title: Text(meds.elementAt(i)['name'], style: TextStyle(color: medIdx == i ? th.accent : Colors.white, fontSize: 17)), onTap: () => setState(() { medIdx = i; if (scrollCtrl.hasClients) scrollCtrl.jumpTo(0); })))),
        Expanded(child: Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: th.panel, borderRadius: BorderRadius.circular(16)), child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(m['name'], style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: th.accent)), Row(children: [const Text('Скорость: '), Slider(value: speed, min: 10, max: 80, activeColor: th.accent, onChanged: (v) => setState(() => speed = v)), Wrap(spacing: 6, children: [['🥁 1','HLCXUD9zMlA'],['🔥 2','QnSGLmn3udI'],['❄️ 3','_Nqlg_hZdVc'],['🌌 4','PLtx2tqJ6K3MC49y2Se5AVW_C8tFlXLbyH']].map((x) => _pill(th, x[0], false, () async { if (bgOn) { await bgPlayer.pause(); setState(() => bgOn = false); } final u = await YtService.resolveAudio(x[1]); if (u.isNotEmpty) { await medPlayer.setPlaylistMode(PlaylistMode.loop); await medPlayer.setVolume(45); await medPlayer.open(Media(u)); } }, h: 8, v: 5, fs: 12)).toList()), _pill(th, '⏹', false, () => medPlayer.stop(), h: 8, v: 5, fs: 12), const SizedBox(width: 8), _pill(th, voiceMedOn ? "⏹ Остановить голос" : "🎙 Голос медитации", voiceMedOn, () => _speakMaster(m["scrollText"], mode: "med"), h: 12, v: 7, fs: 13)])]),
          Expanded(child: Row(children: [ClipRRect(borderRadius: BorderRadius.circular(14), child: Image.asset('assets/cards/${m['img'].toString().split('/').last}', height: 360)), const SizedBox(width: 24), Expanded(child: SingleChildScrollView(controller: scrollCtrl, child: Padding(padding: const EdgeInsets.symmetric(vertical: 140), child: Text(m['scrollText'], style: const TextStyle(fontSize: 24, height: 1.7)))))])),
        ]))),
      ]);
    }
    return const Center(child: CircularProgressIndicator());
  }
}
