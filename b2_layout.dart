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
    if (pos.length == 9) {
      return Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [_slot(th, drawn, pos, hints, 0), _slot(th, drawn, pos, hints, 1), _slot(th, drawn, pos, hints, 2)]),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [_slot(th, drawn, pos, hints, 3), _slot(th, drawn, pos, hints, 4), _slot(th, drawn, pos, hints, 5)]),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [_slot(th, drawn, pos, hints, 6), _slot(th, drawn, pos, hints, 7), _slot(th, drawn, pos, hints, 8)]),
      ]);
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
