    if (tab == 3 && authorSpreads.isNotEmpty) {
      if (authIdx < 0) {
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('✨ Авторські розклади Школи (10 унікальних схем)', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Text('Автор: Євген Гертер', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: th.accent)),
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
                Text(a['author'] ?? 'Автор: Євген Гертер', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: th.accent.withOpacity(0.9))),
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
          _pill(th, '← Усі 10 авторських розкладів', true, () => setState(() => authIdx = -1)),
          Text(sp['author'] ?? 'Автор: Євген Гертер', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: th.accent)),
        ]),
        const SizedBox(height: 14), Text('${sp['title']} (${pos.length} карт)', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)), const SizedBox(height: 10),
                _box(th, 'АВТОРСЬКА МЕТОДОЛОГІЯ (ЄВГЕН ГЕРТЕР)', sp['guide'] ?? sp['desc']), const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('ЗАПИТИ КЛІЄНТІВ (${(authCaseIdx % cases.length) + 1}/${cases.length}):', style: TextStyle(color: th.accent, fontWeight: FontWeight.bold, fontSize: 16)),
          Wrap(spacing: 6, children: [...List.generate(cases.length, (i) => _pill(th, '${i + 1}', (authCaseIdx % cases.length) == i, () => setState(() { authCaseIdx = i; authLaid = false; showAuthAns = false; authRndDrawn = []; ansCtrl.clear(); }), h: 10, v: 5, fs: 13)), _pill(th, 'Нові 5 запитів ↻', false, () => setState(() { authSalt++; authCaseIdx = 0; authLaid = false; showAuthAns = false; authRndDrawn = []; }), h: 10, v: 5, fs: 13)]),
        ]),
        const SizedBox(height: 8), _box(th, 'СИТУАЦІЯ КЛІЄНТА', curC['q']), const SizedBox(height: 14),
        Wrap(spacing: 10, children: [
          _pill(th, authLaid ? '🔄 Перетасувати (Нові ${pos.length} карт із 78)' : '🃏 Викласти ${pos.length} карт на стіл', true, () { if (!authLaid) { setState(() => authLaid = true); return; } final pool = [...lessons]..shuffle(); setState(() { authRndDrawn = pool.take(pos.length).map((x) => {'name': x['title'].toString().replaceFirst(RegExp(r'^Урок \d+\.\s*'), ''), 'img': x['img'], 'meaning': x['simple']}).toList(); showAuthAns = false; ansCtrl.clear(); }); }),
          if (authRndDrawn.isNotEmpty) _pill(th, '↩ Повернути карти запиту', false, () => setState(() { authRndDrawn = []; showAuthAns = false; })),
        ]),
        if (authLaid) ...[
          const SizedBox(height: 16), _tableLayout(th, drawn, pos, hints), const SizedBox(height: 14),
          TextField(controller: ansCtrl, maxLines: 2, style: const TextStyle(fontSize: 17), decoration: const InputDecoration(hintText: 'Озвуч голосом або напиши авторське трактування розкладу...', filled: true, fillColor: Colors.black45, border: OutlineInputBorder())),
          const SizedBox(height: 10),
          Wrap(spacing: 10, children: [
            _pill(th, isRec ? '⏹ Стоп (розпізнати)' : '🎙 Відповісти голосом', isRec, _toggleVoice),
            _pill(th, 'Перевірити себе (Відповідь автора)', true, () { setState(() => showAuthAns = true); _speakMaster(verdict); }),
            _pill(th, '🔊 Голос майстра', false, () => _speakMaster(verdict)),
          ]),
          if (showAuthAns) Container(margin: const EdgeInsets.only(top: 12), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.teal.withOpacity(0.22), borderRadius: BorderRadius.circular(12), border: Border.all(color: th.accent)), child: Text('Автор Євген Гертер: $verdict', style: TextStyle(color: th.accent, fontSize: 18, height: 1.5))),
        ],
      ])));
    }
