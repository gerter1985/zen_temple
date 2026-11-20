import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xml/xml.dart';
import 'models.dart';

class EpubBookInfo {
  final File file;
  final String title;
  final Uint8List? coverBytes;
  final String fullText;
  EpubBookInfo(this.file, this.title, this.coverBytes, this.fullText);
}

EpubBookInfo _parseEpub(File file) {
  final title = file.uri.pathSegments.last.replaceAll('.epub', '');
  final archive = ZipDecoder().decodeBytes(file.readAsBytesSync());
  final parts = <String>[];
  Uint8List? cover;
  for (final f in archive.files) {
    if (!f.isFile) continue;
    final low = f.name.toLowerCase();
    if (cover == null &&
        (low.endsWith('.jpg') || low.endsWith('.jpeg') || low.endsWith('.png')) &&
        (low.contains('cover') || (f.content as List<int>).length > 15000)) {
      cover = Uint8List.fromList(f.content as List<int>);
    }
    if (low.endsWith('.xhtml') || low.endsWith('.html') || low.endsWith('.htm')) {
      try {
        final doc = XmlDocument.parse(
            utf8.decode(f.content as List<int>, allowMalformed: true));
        final buf = StringBuffer();
        for (final el in doc.findAllElements('*')) {
          final tag = el.name.local.toLowerCase();
          if (tag == 'p' || tag == 'h1' || tag == 'h2' || tag == 'h3' || tag == 'div') {
            final line = el.innerText.replaceAll(RegExp(r'\s+'), ' ').trim();
            if (line.isNotEmpty) buf.writeln(line + '\n');
          }
        }
        final txt = buf.toString().trim().isNotEmpty
            ? buf.toString().trim()
            : doc.rootElement.innerText.replaceAll(RegExp(r'\s+'), ' ').trim();
        if (txt.length > 80) parts.add(txt);
      } catch (_) {}
    }
  }
  return EpubBookInfo(file, title, cover, parts.join('\n\n────────────────────\n\n'));
}

Future<void> showBooksDialog(BuildContext context, Color accent) async {
  final dir = await getApplicationSupportDirectory();
  final booksDir = Directory('${dir.path}/books')..createSync(recursive: true);
  final sysDir = Directory('/opt/zen-temple/books');
  if (sysDir.existsSync()) {
    for (final f in sysDir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.epub'))) {
      final dst = File('${booksDir.path}/${f.uri.pathSegments.last}');
      if (!dst.existsSync()) f.copySync(dst.path);
    }
  }
  final prefs = await SharedPreferences.getInstance();
  if (!context.mounted) return;

  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          final books = booksDir
              .listSync()
              .whereType<File>()
              .where((f) => f.path.endsWith('.epub'))
              .map(_parseEpub)
              .toList();
          final lastBook = prefs.getString('last_read_book');
          final lastInfo = books.where((b) => b.title == lastBook).firstOrNull;

          return Scaffold(
            appBar: AppBar(
              backgroundColor: Theme.of(ctx).cardColor,
              title: Text('Бібліотека (${books.length})'),
              actions: [
                if (lastInfo != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                    child: OutlinedButton.icon(
                      onPressed: () => _openEpubReader(
                          ctx, lastInfo, accent, prefs, () => setS(() {})),
                      icon: Icon(Icons.play_arrow, color: accent),
                      label: Text('Продовжити: ${lastInfo.title}',
                          overflow: TextOverflow.ellipsis),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final res = await FilePicker.platform.pickFiles(
                        type: FileType.custom,
                        allowedExtensions: ['epub'],
                      );
                      if (res != null && res.files.single.path != null) {
                        final src = File(res.files.single.path!);
                        src.copySync('${booksDir.path}/${src.uri.pathSegments.last}');
                        setS(() {});
                      }
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Додати EPUB'),
                  ),
                ),
              ],
            ),
            body: books.isEmpty
                ? const Center(child: Text('Немає книг. Натисніть «Додати EPUB».'))
                : GridView.builder(
                    padding: const EdgeInsets.all(20),
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 200,
                      childAspectRatio: 0.65,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: books.length,
                    itemBuilder: (_, i) {
                      final b = books[i];
                      final pct = prefs.getInt('book_pct_${b.title}') ?? 0;
                      return InkWell(
                        onTap: () => _openEpubReader(
                            ctx, b, accent, prefs, () => setS(() {})),
                        child: Card(
                          clipBehavior: Clip.antiAlias,
                          child: Column(children: [
                            Expanded(
                              child: b.coverBytes != null
                                  ? Image.memory(b.coverBytes!,
                                      fit: BoxFit.cover, width: double.infinity)
                                  : Container(
                                      color: Colors.black26,
                                      width: double.infinity,
                                      child: Icon(Icons.auto_stories,
                                          size: 50, color: accent),
                                    ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: Column(children: [
                                Text(b.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600)),
                                if (pct > 0)
                                  Text('Прочитано: $pct%',
                                      style: TextStyle(
                                          fontSize: 11, color: accent)),
                              ]),
                            ),
                          ]),
                        ),
                      );
                    },
                  ),
          );
        },
      ),
    ),
  );
}

void _openEpubReader(BuildContext context, EpubBookInfo book, Color accent,
    SharedPreferences prefs, VoidCallback onUpdate) {
  double fontSize = 19;
  final savedOff = prefs.getDouble('book_off_${book.title}') ?? 0;
  final scrollCtrl = ScrollController(initialScrollOffset: savedOff);
  final bookmarks =
      List<String>.from(prefs.getStringList('book_bm_${book.title}') ?? []);
  final notes =
      List<String>.from(prefs.getStringList('book_nt_${book.title}') ?? []);
  int pct = prefs.getInt('book_pct_${book.title}') ?? 0;

  scrollCtrl.addListener(() {
    if (!scrollCtrl.hasClients) return;
    final max = scrollCtrl.position.maxScrollExtent;
    final cur = scrollCtrl.offset;
    pct = max > 0 ? ((cur / max) * 100).round().clamp(0, 100) : 0;
    prefs.setString('last_read_book', book.title);
    prefs.setDouble('book_off_${book.title}', cur);
    prefs.setInt('book_pct_${book.title}', pct);
    
  });

  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Scaffold(
          appBar: AppBar(
            backgroundColor: Theme.of(ctx).cardColor,
            title: Text(book.title, overflow: TextOverflow.ellipsis),
            actions: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text('$pct%',
                      style: TextStyle(
                          color: accent, fontWeight: FontWeight.bold)),
                ),
              ),
              IconButton(
                tooltip: 'Додати закладку',
                icon: Icon(Icons.bookmark_add, color: accent),
                onPressed: () {
                  final off = scrollCtrl.hasClients ? scrollCtrl.offset : 0.0;
                  final label =
                      'Позиція $pct% (${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')})';
                  setS(() => bookmarks.add('${off.toStringAsFixed(1)}|$label'));
                  prefs.setStringList('book_bm_${book.title}', bookmarks);
                  ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(content: Text('Закладку збережено: $label')));
                },
              ),
              IconButton(
                tooltip: 'Закладки (${bookmarks.length})',
                icon: const Icon(Icons.bookmarks),
                onPressed: () => showDialog(
                  context: ctx,
                  builder: (bCtx) => AlertDialog(
                    title: const Text('Закладки'),
                    content: SizedBox(
                      width: 380,
                      height: 280,
                      child: bookmarks.isEmpty
                          ? const Center(child: Text('Закладок поки немає'))
                          : ListView.builder(
                              itemCount: bookmarks.length,
                              itemBuilder: (_, i) {
                                final parts = bookmarks[i].split('|');
                                return ListTile(
                                  title: Text(parts.last),
                                  onTap: () {
                                    Navigator.pop(bCtx);
                                    final target =
                                        double.tryParse(parts.first) ?? 0;
                                    if (scrollCtrl.hasClients) {
                                      scrollCtrl.animateTo(target,
                                          duration:
                                              const Duration(milliseconds: 300),
                                          curve: Curves.easeOut);
                                    }
                                  },
                                );
                              },
                            ),
                    ),
                  ),
                ),
              ),

              IconButton(
                tooltip: 'Замітки (${notes.length})',
                icon: Icon(Icons.note_add, color: accent),
                onPressed: () {
                  final noteCtrl = TextEditingController();
                  showDialog(
                    context: ctx,
                    builder: (nCtx) => StatefulBuilder(
                      builder: (nCtx, setN) => AlertDialog(
                        title: const Text('Замітки до книги'),
                        content: SizedBox(
                          width: 440,
                          height: 340,
                          child: Column(children: [
                            TextField(
                              controller: noteCtrl,
                              decoration: const InputDecoration(
                                  hintText: 'Напишіть думку або цитату...'),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: () {
                                if (noteCtrl.text.trim().isEmpty) return;
                                setN(() => notes.insert(
                                    0, '[$pct%] ${noteCtrl.text.trim()}'));
                                prefs.setStringList(
                                    'book_nt_${book.title}', notes);
                                noteCtrl.clear();
                                setS(() {});
                              },
                              child: const Text('Зберегти замітку'),
                            ),
                            const Divider(),
                            Expanded(
                              child: ListView.builder(
                                itemCount: notes.length,
                                itemBuilder: (_, i) => ListTile(
                                  dense: true,
                                  title: Text(notes[i]),
                                ),
                              ),
                            ),
                          ]),
                        ),
                      ),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.remove),
                onPressed: () =>
                    setS(() => fontSize = (fontSize - 2).clamp(13, 34)),
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () =>
                    setS(() => fontSize = (fontSize + 2).clamp(13, 34)),
              ),
              const SizedBox(width: 12),
            ],
          ),
          body: book.fullText.isEmpty
              ? const Center(child: Text('Не вдалося розпізнати текст книги.'))
              : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 820),
                    child: ListView.builder(
                      controller: scrollCtrl,
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                      itemCount: book.fullText.split("\n\n").length,
                      itemBuilder: (_, i) => Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Text(book.fullText.split("\n\n")[i], style: TextStyle(fontSize: fontSize, height: 1.65)),
                      ),
                    ),
                  ),
                ),
        ),
      ),
    ),
  );
}

Future<MediaSource?> showAddSourceDialog(BuildContext context) async {
  final titleCtrl = TextEditingController();
  final urlCtrl = TextEditingController();
  SourceCategory cat = SourceCategory.youtube;
  return showDialog<MediaSource>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setS) => AlertDialog(
        title: const Text('Додати джерело'),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<SourceCategory>(
                value: cat,
                items: const [
                  DropdownMenuItem(
                    value: SourceCategory.youtube,
                    child: Text('Канал / відео YouTube'),
                  ),
                  DropdownMenuItem(
                    value: SourceCategory.audiobooks,
                    child: Text('Плейлисти YouTube'),
                  ),
                  DropdownMenuItem(
                    value: SourceCategory.podcasts,
                    child: Text('Подкаст (Apple Podcasts / RSS)'),
                  ),
                ],
                onChanged: (v) =>
                    setS(() => cat = v ?? SourceCategory.youtube),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'Назва'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: urlCtrl,
                decoration: const InputDecoration(
                    labelText: '@handle, посилання YouTube/Apple або назва подкасту'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Скасувати'),
          ),
          ElevatedButton(
            onPressed: () {
              var u = urlCtrl.text.trim();
              if (u.isEmpty) return;
              if (cat == SourceCategory.podcasts && !u.startsWith('http')) {
                u = 'apple_search:$u';
              }
              Navigator.pop(
                ctx,
                MediaSource(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  title: titleCtrl.text.trim().isEmpty
                      ? urlCtrl.text.trim()
                      : titleCtrl.text.trim(),
                  url: u,
                  category: cat,
                ),
              );
            },
            child: const Text('Додати'),
          ),
        ],
      ),
    ),
  );
}

