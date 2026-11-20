class MantraTrack {
  final String id, title, url;
  final int index;
  MantraTrack({required this.id, required this.title, required this.url, required this.index});
}

class OmMantraInfo {
  final String name, sanskrit, cyrillic, translation;
  const OmMantraInfo({required this.name, required this.sanskrit, required this.cyrillic, required this.translation});
  Map<String, dynamic> toJson() => {'name': name, 'sanskrit': sanskrit, 'cyrillic': cyrillic, 'translation': translation};
  factory OmMantraInfo.fromJson(Map<String, dynamic> j) => OmMantraInfo(name: j['name'] ?? '', sanskrit: j['sanskrit'] ?? '', cyrillic: j['cyrillic'] ?? '', translation: j['translation'] ?? '');
}
class MeditationSession {
  final String id, mantraTitle, dateIso;
  final int beads, malas, durationSec;
  MeditationSession({required this.id, required this.mantraTitle, required this.dateIso, required this.beads, required this.malas, required this.durationSec});
  Map<String, dynamic> toJson() => {'id': id, 'mantraTitle': mantraTitle, 'dateIso': dateIso, 'beads': beads, 'malas': malas, 'durationSec': durationSec};
  factory MeditationSession.fromJson(Map<String, dynamic> j) => MeditationSession(id: j['id'], mantraTitle: j['mantraTitle'], dateIso: j['dateIso'], beads: j['beads'] ?? 0, malas: j['malas'] ?? 0, durationSec: j['durationSec'] ?? 0);
}
const Map<String, OmMantraInfo> kBuiltinMantras = {
  'green_tara': OmMantraInfo(
    name: 'Мантра Зеленої Тари',
    sanskrit: 'ॐ तारे तुत्तारे तुरे स्वाहा',
    cyrillic: 'ОМ ТА́РЕ ТУТТА́РЕ ТУ́РЕ СВА́ХА (СО́ХА)',
    translation: 'Ом! Вшановуємо Рятівницю Тару, яка звільняє від усіх страхів і перешкод та веде до пробудження.',
  ),
  'white_tara': OmMantraInfo(
    name: 'Мантра Білої Тари (Довголіття)',
    sanskrit: 'ॐ तारे तुत्तारे तुरे मम आयुः पुण्य ज्ञान पुष्टिं कुरु स्वाहा',
    cyrillic: 'ОМ ТА́РЕ ТУТТА́РЕ ТУ́РЕ МА́МА А́ЮХ ПУ́НЬЯ ДЖНЯ́НА ПУШТІ́М КУ́РУ СВА́ХА',
    translation: 'Ом! Благородна Таро, даруй нам довге життя, заслуги, мудрість, життєву силу та зцілення.',
  ),
  'shakyamuni': OmMantraInfo(
    name: 'Мантра Будди Шак’ямуні',
    sanskrit: 'ॐ मुनि मुनि महामुनये स्वाहा',
    cyrillic: 'ОМ МУ́НІ МУ́НІ МАХАМУ́НАЄ СВА́ХА',
    translation: 'Ом! Мудрецю, великий Мудрецю з роду Шак’їв, вклоняємося Тобі, хто осягнув найвищу істину.',
  ),
  'avalokiteshvara': OmMantraInfo(
    name: 'Мантра Авалокітешвари (Ченрезіга)',
    sanskrit: 'ॐ मणि पद्मे हूँ',
    cyrillic: 'ОМ МА́НІ ПА́ДМЕ ХУМ',
    translation: 'Ом! Слава коштовності у квітці лотоса — єдності великого співчуття та мудрості.',
  ),
  'medicine_buddha': OmMantraInfo(
    name: 'Мантра Будди Медицини',
    sanskrit: 'तद्यथा ॐ भैषज्ये भैषज्ये महाभैषज्ये राज समुद्गते स्वाहा',
    cyrillic: 'ТАДЬЯ́ТА ОМ БЕКА́НДЗЕ БЕКА́НДЗЕ МАХА́ БЕКА́НДЗЕ РА́ДЗА САМУДГА́ТЕ СО́ХА',
    translation: 'Нехай буде так! Ом! Великий Цілителю, усунь хвороби тіла, розуму та невігластва.',
  ),
  'vajrasattva': OmMantraInfo(
    name: 'Мантра Ваджрасаттви (Очищення)',
    sanskrit: 'ॐ वज्रसत्त्व हूँ',
    cyrillic: 'ОМ ВАДЖРАСА́ТТВА ХУМ',
    translation: 'Ом! Непорушний Алмазний Розуме, очисти негативну карму й віднови споконвічну чистоту.',
  ),
  'manjushri': OmMantraInfo(
    name: 'Мантра Манджушрі (Мудрість)',
    sanskrit: 'ॐ अ र प च न धीः',
    cyrillic: 'ОМ А РА ПА ЦА НА ДХІХ',
    translation: 'Ом! Нехай пробудиться ясна мудрість і світло знання, що розсікає темряву невідання.',
  ),
  'guru_rinpoche': OmMantraInfo(
    name: 'Мантра Гуру Рінпоче',
    sanskrit: 'ॐ आः हूँ वज्र गुरु पद्म सिद्धि हूँ',
    cyrillic: 'ОМ АХ ХУМ ВА́ДЖРА ГУ́РУ ПА́ДМА СІ́ДДХІ ХУМ',
    translation: 'Ом А Хум! Звертаємося до Алмазного Вчителя, народженого з лотоса — даруй нам захист і досягнення.',
  ),
  'amitabha': OmMantraInfo(
    name: 'Мантра Будди Амітабхи',
    sanskrit: 'ॐ अमि देव ह्रीः',
    cyrillic: 'ОМ АМІ́ ДЕ́ВА ХРІХ',
    translation: 'Ом! Вклоняємося Будді Безмежного Світла й Співчуття, що веде до чистої землі спокою.',
  ),
  'dzambhala': OmMantraInfo(
    name: 'Мантра Дзамбали (Достаток)',
    sanskrit: 'ॐ जम्भल जलेंद्राय स्वाहा',
    cyrillic: 'ОМ ДЗАМБХА́ЛА ДЗАЛЕНТРА́Є СВА́ХА',
    translation: 'Ом! Владико щедрості, наповни життя добробутом, щоб ми могли допомагати іншим.',
  ),
  'heart_sutra': OmMantraInfo(
    name: 'Мантра Сутри Серця',
    sanskrit: 'गते गते पारगते पारसंगते बोधि स्वाहा',
    cyrillic: 'ГА́ТЕ ГА́ТЕ ПАРАГА́ТЕ ПАРАСАМГА́ТЕ БО́ДХІ СВА́ХА',
    translation: 'Пішов, перейшов на той берег, повністю досяг Пробудження! Слава мудрості!',
  ),
  'om_root': OmMantraInfo(
    name: 'Корінна мантра Всесвіту (ОМ)',
    sanskrit: 'ॐ शान्तिः शान्तिः शान्तिः',
    cyrillic: 'ОМ ША́НТІХ ША́НТІХ ША́НТІХ',
    translation: 'Ом! Спокій у тілі, спокій у мовленні, спокій у розумі. Мир і гармонія всьому живому.',
  ),
};
OmMantraInfo resolveMantraForTitle(String title) {
  final t = title.toLowerCase();
  if (t.contains('белой тар') || t.contains('white tara')) return kBuiltinMantras['white_tara']!;
  if (t.contains('тар') || t.contains('tara') || t.contains('dolma')) return kBuiltinMantras['green_tara']!;
  if (t.contains('шакьямуни') || t.contains('shakyamuni') || t.contains('muni')) return kBuiltinMantras['shakyamuni']!;
  if (t.contains('мани') || t.contains('mani') || t.contains('avalokiteshvara') || t.contains('chenrezig')) return kBuiltinMantras['avalokiteshvara']!;
  if (t.contains('медицин') || t.contains('medicine') || t.contains('здоров') || t.contains('исцел')) return kBuiltinMantras['medicine_buddha']!;
  if (t.contains('ваджрасаттв') || t.contains('vajrasattva') || t.contains('очищ') || t.contains('карм')) return kBuiltinMantras['vajrasattva']!;
  if (t.contains('манджушри') || t.contains('manjushri') || t.contains('ra pa')) return kBuiltinMantras['manjushri']!;
  if (t.contains('ринпоче') || t.contains('rinpoche') || t.contains('padmasambhava')) return kBuiltinMantras['guru_rinpoche']!;
  if (t.contains('амитабх') || t.contains('amitabha')) return kBuiltinMantras['amitabha']!;
  if (t.contains('дзамбал') || t.contains('dzambhala') || t.contains('васудхар') || t.contains('денег')) return kBuiltinMantras['dzambhala']!;
  if (t.contains('праджняпарамит') || t.contains('prajna') || t.contains('heart sutra') || t.contains('gate')) return kBuiltinMantras['heart_sutra']!;
  return kBuiltinMantras['om_root']!;
}
