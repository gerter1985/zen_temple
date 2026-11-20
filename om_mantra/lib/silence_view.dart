import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'mantra_data.dart';
import 'om_service.dart';

class SilencePracticeView extends StatefulWidget {
  final Color accent;
  final Player player;
  final Future<void> Function(String title, int beads, int durSec) onSaveSession;
  const SilencePracticeView({super.key, required this.accent, required this.player, required this.onSaveSession});
  @override
  State<SilencePracticeView> createState() => _SilencePracticeViewState();
}
class _SilencePracticeViewState extends State<SilencePracticeView> {
  static const _bowlsId = 'TA3G7UYnzZo';
  bool withBowls = false, loadingAudio = false, timerRunning = false, usePhysical = false;
  String selectedKey = 'om_root';
  int timerMinutes = 15, remainSec = 15 * 60, beads = 0;
  Timer? _ticker;
  final _manualCtrl = TextEditingController();

  @override
  void dispose() {
    _ticker?.cancel();
    _manualCtrl.dispose();
    super.dispose();
  }

  Future<void> _toggleSound(bool bowls) async {
    setState(() { withBowls = bowls; });
    if (!bowls) {
      await widget.player.pause();
      return;
    }
    setState(() => loadingAudio = true);
    try {
      final url = 'https://www.youtube' + '.com/watch?v=$_bowlsId';
      final stream = await OmService.resolveAudio(url);
      await widget.player.open(Media(stream), play: true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Помилка чаш: $e')));
    } finally {
      if (mounted) setState(() => loadingAudio = false);
    }
  }
  void _setMinutes(int m) {
    _ticker?.cancel();
    setState(() { timerMinutes = m; remainSec = m * 60; timerRunning = false; });
  }

  void _toggleTimer() {
    if (timerRunning) {
      _ticker?.cancel();
      setState(() => timerRunning = false);
      return;
    }
    setState(() => timerRunning = true);
    _ticker = Timer.periodic(const Duration(seconds: 1), (t) {
      if (remainSec <= 1) {
        t.cancel();
        HapticFeedback.heavyImpact();
        setState(() { remainSec = 0; timerRunning = false; });
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('🔔 Час медитації в тиші завершено!')));
      } else {
        setState(() => remainSec--);
      }
    });
  }

  String _fmt(int s) => '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';

  Future<void> _save() async {
    final m = kBuiltinMantras[selectedKey]!;
    final spent = (timerMinutes * 60 - remainSec).clamp(0, 86400);
    await widget.onSaveSession('${m.name} (${withBowls ? "Чаші" : "Тиша"})', beads, spent);
    setState(() { beads = 0; _manualCtrl.clear(); });
  }
  @override
  Widget build(BuildContext context) {
    final m = kBuiltinMantras[selectedKey]!;
    return Focus(
      autofocus: true,
      onKeyEvent: (_, e) {
        if (!usePhysical && e is KeyDownEvent && e.logicalKey == LogicalKeyboardKey.space) { setState(() => beads++); return KeyEventResult.handled; }
        return KeyEventResult.ignored;
      },
      child: Row(children: [
        Container(
          width: 280, padding: const EdgeInsets.all(16), color: Theme.of(context).cardColor.withOpacity(0.6),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('🪷 Режим Тиші', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: widget.accent)),
            const SizedBox(height: 14),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('Тиша'), icon: Icon(Icons.volume_off, size: 16)),
                ButtonSegment(value: true, label: Text('Чаші'), icon: Icon(Icons.spa, size: 16)),
              ],
              selected: {withBowls},
              onSelectionChanged: (v) => _toggleSound(v.first),
            ),
            if (loadingAudio) const Padding(padding: EdgeInsets.only(top: 8), child: LinearProgressIndicator()),
            const Divider(height: 28),
            const Text('⏳ Таймер медитації', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Center(child: Text(_fmt(remainSec), style: TextStyle(fontSize: 38, fontWeight: FontWeight.bold, color: widget.accent))),
            const SizedBox(height: 8),
            Wrap(spacing: 6, runSpacing: 6, alignment: WrapAlignment.center, children: [5, 10, 15, 20, 30, 45].map((min) => ChoiceChip(
              label: Text('$min хв'), selected: timerMinutes == min, onSelected: (_) => _setMinutes(min),
            )).toList()),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: ElevatedButton.icon(onPressed: _toggleTimer, icon: Icon(timerRunning ? Icons.pause : Icons.play_arrow), label: Text(timerRunning ? 'Пауза' : 'Старт'))),
              const SizedBox(width: 8),
              IconButton(tooltip: 'Скинути таймер', onPressed: () => _setMinutes(timerMinutes), icon: const Icon(Icons.refresh)),
            ]),
            const Divider(height: 28),
            const Text('📜 Оберіть текст мантри:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: selectedKey, isExpanded: true,
              decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
              items: kBuiltinMantras.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value.name, overflow: TextOverflow.ellipsis))).toList(),
              onChanged: (v) { if (v != null) setState(() => selectedKey = v); },
            ),
          ]),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(children: [
              Text(m.name, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: widget.accent), textAlign: TextAlign.center),
              const SizedBox(height: 24),
              Container(
                width: double.infinity, padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(18), border: Border.all(color: widget.accent.withOpacity(0.35))),
                child: Column(children: [
                  SelectableText(m.sanskrit, style: TextStyle(fontSize: 34, fontWeight: FontWeight.w600, color: widget.accent, height: 1.5), textAlign: TextAlign.center),
                  const Divider(height: 32),
                  SelectableText(m.cyrillic, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 1.1, height: 1.4), textAlign: TextAlign.center),
                  const Divider(height: 32),
                  SelectableText(m.translation, style: const TextStyle(fontSize: 16, color: Colors.white70, height: 1.5), textAlign: TextAlign.center),
                ]),
              ),
            ]),
          ),
        ),
        Container(
          width: 320, padding: const EdgeInsets.all(16), color: Theme.of(context).cardColor.withOpacity(0.5),
          child: Column(children: [
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('Віртуальні'), icon: Icon(Icons.radio_button_checked, size: 16)),
                ButtonSegment(value: true, label: Text('Живі чотки'), icon: Icon(Icons.edit_note, size: 16)),
              ],
              selected: {usePhysical},
              onSelectionChanged: (v) => setState(() => usePhysical = v.first),
            ),
            const SizedBox(height: 16),
            Text('Коло: ${beads % 108} / 108  •  Мала: ${beads ~/ 108}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: widget.accent)),
            const SizedBox(height: 14),
            Expanded(
              child: usePhysical
                  ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Text('Впишіть кількість начитаних мантр:', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70)),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _manualCtrl, keyboardType: TextInputType.number, textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        decoration: const InputDecoration(hintText: '108', border: OutlineInputBorder()),
                        onChanged: (v) => setState(() => beads = int.tryParse(v) ?? 0),
                      ),
                      const SizedBox(height: 12),
                      Wrap(spacing: 8, children: [27, 54, 108, 216].map((n) => ActionChip(label: Text('+$n'), onPressed: () => setState(() { beads += n; _manualCtrl.text = '$beads'; }))).toList()),
                    ])
                  : GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () { HapticFeedback.lightImpact(); setState(() => beads++); },
                      child: CustomPaint(
                        painter: _SilenceMalaPainter(count: beads, accent: widget.accent),
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
              Expanded(child: ElevatedButton.icon(onPressed: beads > 0 ? _save : null, icon: const Icon(Icons.save, size: 18), label: const Text('Зберегти'))),
            ]),
          ]),
        ),
      ]),
    );
  }
}

class _SilenceMalaPainter extends CustomPainter {
  final int count;
  final Color accent;
  _SilenceMalaPainter({required this.count, required this.accent});
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = math.min(size.width, size.height) * 0.42;
    final active = count % 108;
    for (int i = 0; i < 108; i++) {
      final a = -math.pi / 2 + (2 * math.pi * i / 108);
      final p = Offset(c.dx + r * math.cos(a), c.dy + r * math.sin(a));
      final isMarker = i == 0 || i % 27 == 0;
      final paint = Paint()..color = i == 0 ? Colors.amber : (i < active ? accent : (isMarker ? accent.withOpacity(0.45) : Colors.white24));
      canvas.drawCircle(p, i == 0 ? 7.5 : (isMarker ? 5.0 : 3.4), paint);
    }
  }
  @override
  bool shouldRepaint(covariant _SilenceMalaPainter old) => old.count != count || old.accent != accent;
}
