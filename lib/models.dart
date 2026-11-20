import 'dart:convert';

enum SourceCategory { youtube, audiobooks, podcasts }

class MediaSource {
  final String id;
  final String title;
  final String url;
  final SourceCategory category;

  MediaSource({
    required this.id,
    required this.title,
    required this.url,
    required this.category,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'url': url,
        'category': category.index,
      };

  factory MediaSource.fromJson(Map<String, dynamic> j) => MediaSource(
        id: j['id'],
        title: j['title'],
        url: j['url'],
        category: SourceCategory.values[j['category'] ?? 0],
      );
}

class MediaItem {
  final String id;
  final String title;
  final String sourceTitle;
  final String url;
  final String? thumb;
  final bool isYoutube;
  final int durationSec;

  MediaItem({
    required this.id,
    required this.title,
    required this.sourceTitle,
    required this.url,
    this.thumb,
    required this.isYoutube,
    this.durationSec = 0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'sourceTitle': sourceTitle,
        'url': url,
        'thumb': thumb,
        'isYoutube': isYoutube,
        'durationSec': durationSec,
      };

  factory MediaItem.fromJson(Map<String, dynamic> j) => MediaItem(
        id: j['id'],
        title: j['title'],
        sourceTitle: j['sourceTitle'] ?? '',
        url: j['url'],
        thumb: j['thumb'],
        isYoutube: j['isYoutube'] ?? false,
        durationSec: j['durationSec'] ?? 0,
      );
}

class WatchProgress {
  final MediaItem item;
  final int positionSec;
  final int totalSec;
  final bool lastWasVideo;
  final int updatedAt;

  WatchProgress({
    required this.item,
    required this.positionSec,
    required this.totalSec,
    required this.lastWasVideo,
    required this.updatedAt,
  });

  double get ratio =>
      totalSec > 0 ? (positionSec / totalSec).clamp(0.0, 1.0) : 0.15;

  Map<String, dynamic> toJson() => {
        'item': item.toJson(),
        'positionSec': positionSec,
        'totalSec': totalSec,
        'lastWasVideo': lastWasVideo,
        'updatedAt': updatedAt,
      };

  factory WatchProgress.fromJson(Map<String, dynamic> j) => WatchProgress(
        item: MediaItem.fromJson(j['item']),
        positionSec: j['positionSec'] ?? 0,
        totalSec: j['totalSec'] ?? 0,
        lastWasVideo: j['lastWasVideo'] ?? false,
        updatedAt: j['updatedAt'] ?? 0,
      );
}

List<MediaSource> defaultSources() {
  return [
    // Підтверджені живі YouTube-канали українською
    MediaSource(id: 'yt1', title: 'Діамантовий Шлях (Буддизм UA)', url: '@buddhismua', category: SourceCategory.youtube),
    MediaSource(id: 'yt2', title: 'Тхеравада Буддизм UA', url: '@TheravadaUkraine', category: SourceCategory.youtube),
    MediaSource(id: 'yt3', title: 'Ранґджунґ Єше Гомде Україна', url: '@gomdeukraine', category: SourceCategory.youtube),
    MediaSource(id: 'yt4', title: 'Перший буддійський', url: '@first_buddha', category: SourceCategory.youtube),
    MediaSource(id: 'yt5', title: 'Буддизм ТВ', url: '@tv_buddhism', category: SourceCategory.youtube),
    MediaSource(id: 'yt6', title: 'Єрмолін Буддизм', url: '@ermolin.buddhism', category: SourceCategory.youtube),
    MediaSource(id: 'yt7', title: 'RPSHam', url: '@RPSHam', category: SourceCategory.youtube),
    MediaSource(id: 'yt8', title: 'Філософія Буддизму', url: '@ФилософияБуддизма', category: SourceCategory.youtube),
    MediaSource(id: 'yt9', title: 'NaraLoka', url: '@NaraLoka', category: SourceCategory.youtube),
    MediaSource(id: 'yt10', title: 'Аджан Брам UA', url: '@AjahnBrahmUA2022', category: SourceCategory.youtube),
    MediaSource(id: 'yt11', title: 'Садхґуру Україна', url: '@SadhguruUkraine', category: SourceCategory.youtube),

    // Аудіокниги та плейлисти українською (точні пошукові запити та плейлисти)

    // Українські подкасти (перевірені Apple Podcasts ID)
    MediaSource(id: 'pd1', title: 'Перший буддійський (Подкаст)', url: 'apple_search:Перший буддійський', category: SourceCategory.podcasts),
    MediaSource(id: 'pd3', title: 'Як це пережити', url: 'apple_search:Як це пережити', category: SourceCategory.podcasts),
    MediaSource(id: 'pd4', title: 'Душніла', url: 'apple_search:Душніла', category: SourceCategory.podcasts),
    MediaSource(id: 'pd5', title: 'УЯВИ (Медитації українською)', url: 'apple_search:УЯВИ медитації', category: SourceCategory.podcasts),
    MediaSource(id: 'pd6', title: 'Дизайн життя | Нейронаука та медитації', url: 'apple_search:Дизайн життя нейронаука та медитації', category: SourceCategory.podcasts),
    MediaSource(id: 'pd7', title: 'Афірмації українською', url: 'apple_search:Афірмації українською', category: SourceCategory.podcasts),
    MediaSource(id: 'pd8', title: 'Простими словами (Усвідомленість)', url: 'apple_search:Простими словами', category: SourceCategory.podcasts),
    MediaSource(id: 'pd9', title: 'Багатий внутрішній світ', url: 'apple_search:Багатий внутрішній світ', category: SourceCategory.podcasts),
    MediaSource(id: 'pd11', title: 'Аджан Брам — Світло в кінці тунелю', url: 'apple_search:Аджан Брам світло в кінці тунелю', category: SourceCategory.podcasts),
    MediaSource(id: 'pd16', title: 'УЯВИ (Подкаст)', url: 'apple_search:УЯВИ подкаст', category: SourceCategory.podcasts),
    MediaSource(id: 'yt16', title: 'Обитель Мудрості', url: '@obitel-mudrosti', category: SourceCategory.youtube),
    MediaSource(id: 'yt17', title: 'Академія Сну', url: '@AkademSnu', category: SourceCategory.youtube),
    MediaSource(id: 'yt18', title: 'Смак Нірвани', url: '@SmakNirvany', category: SourceCategory.youtube),
    MediaSource(id: 'yt19', title: 'Буддійський плейлист 1', url: 'playlist:PLJClRdgcTevER8aQbZQ9tAkmZFclrMG4Q', category: SourceCategory.audiobooks),
    MediaSource(id: 'yt20', title: 'Буддійський плейлист 2', url: 'playlist:PLvfeL05IH5nNalqoViD-hzb7EIthloBZX', category: SourceCategory.audiobooks),
    MediaSource(id: 'yt21', title: 'Буддійський плейлист 3', url: 'playlist:PL0tvlNdHb2cXo1T2AUeT2JKoFpWsIwoAr', category: SourceCategory.audiobooks),
    MediaSource(id: 'yt22', title: 'Буддійський плейлист 4', url: 'playlist:PLv9DRaEpE3qx6Gp6W5-J5nMDecrSkOdjO', category: SourceCategory.audiobooks),
    MediaSource(id: 'yt23', title: 'Буддійський плейлист 5', url: 'playlist:PL-6WqZaAmyuZvvINv_pamlZVRkpDmb75I', category: SourceCategory.audiobooks),
    MediaSource(id: 'yt24', title: 'Буддійський плейлист 6', url: 'playlist:PLZHnZj17pIcfaat0cpmya_iMmxufW09uR', category: SourceCategory.audiobooks),
    MediaSource(id: 'yt25', title: 'Буддійський плейлист 7', url: 'playlist:PLaKewMLuJx0BA8bSXLbRYgGailDUlyebM', category: SourceCategory.audiobooks),
    MediaSource(id: 'yt26', title: 'Буддійський плейлист 8', url: 'playlist:PLBtL4fhQ1ewL4D-gaREMXthSjPoL1O8QD', category: SourceCategory.audiobooks),
    MediaSource(id: 'yt27', title: 'Буддійський плейлист 9', url: 'playlist:PLxqVhM_kTFCqe1dW5lA9d-vYFSPjj658N', category: SourceCategory.audiobooks),
    MediaSource(id: 'pd17', title: 'Садхґуру', url: 'apple_search:Садхгуру', category: SourceCategory.podcasts),
    MediaSource(id: 'pl0', title: 'Буддійський плейлист (Основний)', url: 'playlist:PLxqVhM_kTFCqIX7JeJNaB2CehdcYrr70I', category: SourceCategory.audiobooks),
  ];
}

