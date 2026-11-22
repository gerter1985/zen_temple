    if (tab == 1 && spreads.isNotEmpty) {
      final sp = spreads.elementAt(spIdx % spreads.length);
      final cases = _spCases(sp);
      final curC = cases.elementAt(spCaseIdx % cases.length);
      final drawn = rndDrawn.isNotEmpty ? rndDrawn : List<Map<String, dynamic>>.from(curC['d']);
      final pos = List<String>.from(sp['positions']);
      final verdict = rndDrawn.isNotEmpty ? 'Позиція 1: ${drawn.first['name']} — ${drawn.first['meaning']}. Позиція 2: ${drawn.elementAt(1)['name']} — ${drawn.elementAt(1)['meaning']}. Підсумок: ${drawn.last['name']} — ${drawn.last['meaning']}.' : curC['v'];
      return SingleChildScrollView(child: Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: th.panel, borderRadius: BorderRadius.circular(16)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Wrap(spacing: 8, runSpacing: 8, children: List.generate(spreads.length, (i) => _pill(th, spreads.elementAt(i)['title'], spIdx == i, () => setState(() { spIdx = i; spCaseIdx = 0; laid = false; showSpAns = false; rndDrawn = []; ansCtrl.clear(); }), h: 12, v: 8, fs: 14))),
        const SizedBox(height: 14), Text(sp['title'], style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)), const SizedBox(height: 10),
        _box(th, 'ДЕТАЛЬНА ІНСТРУКЦІЯ РОЗКЛАДУ (ДЛЯ НАВЧАННЯ)', '${sp['desc']} Як читати розклад: оціни загальну стихію трьох карт, прочитай кожну позицію окремо й зв’яжи причину (1) через дію чи стан (2) у фінальний результат (3).'), const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('ЗАПИТИ КЛІЄНТІВ (${(spCaseIdx % cases.length) + 1}/${cases.length}):', style: TextStyle(color: th.accent, fontWeight: FontWeight.bold, fontSize: 16)),
          Wrap(spacing: 6, children: [...List.generate(cases.length, (i) => _pill(th, '${i + 1}', (spCaseIdx % cases.length) == i, () => setState(() { spCaseIdx = i; laid = false; showSpAns = false; rndDrawn = []; ansCtrl.clear(); }), h: 10, v: 5, fs: 13)), _pill(th, 'Нові 5 запитів ↻', false, () => setState(() { spSalt++; spCaseIdx = 0; laid = false; showSpAns = false; rndDrawn = []; }), h: 10, v: 5, fs: 13)]),
        ]),
        const SizedBox(height: 8), _box(th, 'СИТУАЦІЯ КЛІЄНТА', curC['q']), const SizedBox(height: 14),
        Wrap(spacing: 10, children: [
          _pill(th, laid ? '🔄 Перетасувати (Нові 3 карти з 78)' : '🃏 Викласти карти клієнту', true, () { if (!laid) { setState(() => laid = true); return; } final pool = [...lessons]..shuffle(); setState(() { rndDrawn = pool.take(3).map((x) => {'name': x['title'].toString().replaceFirst(RegExp(r'^Урок \d+\.\s*'), ''), 'img': x['img'], 'meaning': x['simple']}).toList(); showSpAns = false; ansCtrl.clear(); }); }),
          if (rndDrawn.isNotEmpty) _pill(th, '↩ Повернути карти запиту', false, () => setState(() { rndDrawn = []; showSpAns = false; })),
        ]),
        if (laid) ...[
          const SizedBox(height: 16),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: List.generate(3, (i) {
            final d = drawn.elementAt(i);
            const hints = ['На що відповідає: вихідна точка або думки', 'На що відповідає: поточний стан або вибір', 'На що відповідає: підсумок та порада'];
            return Expanded(child: Container(margin: const EdgeInsets.all(6), padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(14), border: Border.all(color: th.accent.withOpacity(0.5))), child: Column(children: [
              Container(width: double.infinity, padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: th.accent.withOpacity(0.15), borderRadius: BorderRadius.circular(10)), child: Column(children: [Text(pos.elementAt(i), textAlign: TextAlign.center, style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: th.accent)), const SizedBox(height: 4), Text(hints.elementAt(i), textAlign: TextAlign.center, style: const TextStyle(fontSize: 13.5, color: Colors.white70))])),
              const SizedBox(height: 10), ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.asset('assets/cards/${d['img'].toString().split('/').last}', height: 230)),
                            const SizedBox(height: 10), Text(d['name'], textAlign: TextAlign.center, style: TextStyle(color: th.accent, fontWeight: FontWeight.bold, fontSize: 19)), const SizedBox(height: 6), Text(d['meaning'], textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
            ])));
          })),
          const SizedBox(height: 14),
          TextField(controller: ansCtrl, maxLines: 2, style: const TextStyle(fontSize: 17), decoration: const InputDecoration(hintText: 'Озвуч голосом або напиши трактування...', filled: true, fillColor: Colors.black45, border: OutlineInputBorder())),
          const SizedBox(height: 10),
          Wrap(spacing: 10, children: [
            _pill(th, isRec ? '⏹ Стоп' : '🎙 Відповісти голосом', isRec, _toggleVoice),
            _pill(th, 'Перевірити себе', true, () { setState(() => showSpAns = true); _speakMaster(verdict); }),
            _pill(th, '🔊 Голос майстра', false, () => _speakMaster(verdict)),
          ]),
          if (showSpAns) Container(margin: const EdgeInsets.only(top: 12), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.teal.withOpacity(0.22), borderRadius: BorderRadius.circular(12), border: Border.all(color: th.accent)), child: Text('Майстер: $verdict', style: TextStyle(color: th.accent, fontSize: 18, height: 1.5))),
        ],
      ])));
    }
