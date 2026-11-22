    if (tab == 2) {
      const presets = ['Навчання Таро Райдера Вейта українською', 'Старші Аркани Таро значення', 'Молодші Аркани Таро навчання', 'Як читати розклади Таро'];
      final shown = onlyFav ? favVideos : videos;
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: TextField(controller: ytVidCtrl, style: const TextStyle(fontSize: 16), decoration: InputDecoration(hintText: 'Посилання на відео, @канал YouTube або тема...', filled: true, fillColor: th.panel, border: const OutlineInputBorder()))),
          const SizedBox(width: 8),
          _pill(th, 'Вставити', false, () async { final d = await Clipboard.getData('text/plain'); if (d?.text != null) ytVidCtrl.text = d!.text!; }),
          const SizedBox(width: 8),
          _pill(th, loadingYt ? 'Завантаження...' : '+ Знайти / Оновити', true, () async { final q = ytVidCtrl.text.trim().isEmpty ? presets.first : ytVidCtrl.text.trim(); setState(() { loadingYt = true; onlyFav = false; }); final l = await YtService.fetchChannelOrVideo(q, exclude: videos.map((e) => e.id).toSet()); setState(() { videos = [...l, ...videos]; loadingYt = false; ytVidCtrl.clear(); }); }),
        ]),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 6, children: [
          _pill(th, '📺 Знайдені (${videos.length})', !onlyFav, () => setState(() => onlyFav = false), h: 12, v: 6, fs: 13),
          _pill(th, '⭐ Збережене (${favVideos.length})', onlyFav, () => setState(() => onlyFav = true), h: 12, v: 6, fs: 13),
          ...presets.map((q) => _pill(th, '🔄 $q', false, () async { setState(() { loadingYt = true; onlyFav = false; }); final l = await YtService.fetchChannelOrVideo(q, exclude: videos.map((e) => e.id).toSet()); setState(() { videos = [...l, ...videos]; loadingYt = false; }); }, h: 12, v: 6, fs: 13)),
        ]),
        const SizedBox(height: 12),
        if (shown.isEmpty) Expanded(child: Center(child: Text(onlyFav ? 'Натисни «☆ Зберегти» на відео, щоб додати його в закладки' : 'Натисни будь-яку тему зверху або встав @канал YouTube', style: const TextStyle(fontSize: 18, color: Colors.white70))))
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
                _pill(th, isFav ? '⭐ Збережено' : '☆ Зберегти', isFav, () { setState(() { if (isFav) { favVideos.removeWhere((f) => f.id == v.id); } else { favVideos.insert(0, v); } YtService.saveFavs(favVideos); }); }, h: 10, v: 4, fs: 12.5),
                InkWell(onTap: () => setState(() { if (onlyFav) { favVideos.removeAt(i); YtService.saveFavs(favVideos); } else { videos.removeAt(i); } }), child: const Icon(Icons.delete_outline, size: 20, color: Colors.white54)),
              ]),
            ])),
          ])));
        })),
      ]);
    }
