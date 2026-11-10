// Data and helpers for the Korean word quiz (Campus tab).

import 'dart:math' as math;

const int quizMaxRows = 6;
const int quizMaxCols = 6;

enum TileState { correct, present, absent }

class QuizWord {
  final String hangul;
  final String romanization;
  final String meaning;

  const QuizWord({
    required this.hangul,
    required this.romanization,
    required this.meaning,
  });

  /// The word split into single letters (jamo), one tile per letter.
  List<String> get jamo => Hangul.toJamo(hangul);
}

class ReviewEntry {
  final QuizWord word;
  final bool solved;

  const ReviewEntry({required this.word, required this.solved});
}

class Hangul {
  static const List<String> _leads = [
    'ㄱ', 'ㄲ', 'ㄴ', 'ㄷ', 'ㄸ', 'ㄹ', 'ㅁ', 'ㅂ', 'ㅃ', 'ㅅ',
    'ㅆ', 'ㅇ', 'ㅈ', 'ㅉ', 'ㅊ', 'ㅋ', 'ㅌ', 'ㅍ', 'ㅎ',
  ];

  static const List<String> _vowels = [
    'ㅏ', 'ㅐ', 'ㅑ', 'ㅒ', 'ㅓ', 'ㅔ', 'ㅕ', 'ㅖ', 'ㅗ', 'ㅘ', 'ㅙ',
    'ㅚ', 'ㅛ', 'ㅜ', 'ㅝ', 'ㅞ', 'ㅟ', 'ㅠ', 'ㅡ', 'ㅢ', 'ㅣ',
  ];

  // Index 0 means "no final consonant".
  static const List<String> _tails = [
    '', 'ㄱ', 'ㄲ', 'ㄳ', 'ㄴ', 'ㄵ', 'ㄶ', 'ㄷ', 'ㄹ', 'ㄺ', 'ㄻ', 'ㄼ',
    'ㄽ', 'ㄾ', 'ㄿ', 'ㅀ', 'ㅁ', 'ㅂ', 'ㅄ', 'ㅅ', 'ㅆ', 'ㅇ', 'ㅈ', 'ㅊ',
    'ㅋ', 'ㅌ', 'ㅍ', 'ㅎ',
  ];

  /// Splits Hangul syllables into jamo. "학교" -> ㅎ ㅏ ㄱ ㄱ ㅛ
  static List<String> toJamo(String text) {
    final List<String> result = [];
    for (final int rune in text.runes) {
      if (rune >= 0xAC00 && rune <= 0xD7A3) {
        final int offset = rune - 0xAC00;
        result.add(_leads[offset ~/ 588]);
        result.add(_vowels[(offset % 588) ~/ 28]);
        final String tail = _tails[offset % 28];
        if (tail.isNotEmpty) {
          result.add(tail);
        }
      } else {
        result.add(String.fromCharCode(rune));
      }
    }
    return result;
  }
}

/// Wordle-style evaluation. Handles repeated letters correctly:
/// exact matches are marked first, then misplaced letters are matched
/// against the letters that are still unaccounted for.
List<TileState> evaluateGuess(List<String> guess, List<String> answer) {
  final List<TileState> result =
      List<TileState>.filled(guess.length, TileState.absent);
  final Map<String, int> remaining = {};

  for (int i = 0; i < answer.length; i++) {
    if (i < guess.length && guess[i] == answer[i]) {
      result[i] = TileState.correct;
    } else {
      remaining[answer[i]] = (remaining[answer[i]] ?? 0) + 1;
    }
  }

  for (int i = 0; i < guess.length; i++) {
    if (result[i] == TileState.correct) {
      continue;
    }
    final int count = remaining[guess[i]] ?? 0;
    if (count > 0) {
      result[i] = TileState.present;
      remaining[guess[i]] = count - 1;
    }
  }
  return result;
}

// On-screen keyboard (2-set layout, same as the Figma design).
const List<List<String>> quizKeyboardRows = [
  ['ㅂ', 'ㅈ', 'ㄷ', 'ㄱ', 'ㅅ', 'ㅛ', 'ㅕ', 'ㅑ', 'ㅐ', 'ㅔ'],
  ['ㅁ', 'ㄴ', 'ㅇ', 'ㄹ', 'ㅎ', 'ㅗ', 'ㅓ', 'ㅏ', 'ㅣ'],
  ['ENTER', 'ㅋ', 'ㅌ', 'ㅊ', 'ㅍ', 'ㅠ', 'ㅜ', 'ㅡ', '⌫'],
];

// Every entry is checked at runtime by isPlayableWord(): a word is only offered
// when it needs at most 6 tiles and uses letters from the built-in keyboard.
const List<QuizWord> quizWords = [
  QuizWord(hangul: '학교', romanization: 'hak-gyo', meaning: 'school, campus'),
  QuizWord(hangul: '집', romanization: 'jip', meaning: 'home, house'),
  QuizWord(hangul: '책상', romanization: 'chaek-sang', meaning: 'desk'),
  QuizWord(hangul: '연필', romanization: 'yeon-pil', meaning: 'pencil'),
  QuizWord(hangul: '식당', romanization: 'sik-dang', meaning: 'restaurant, cafeteria'),
  QuizWord(hangul: '친구', romanization: 'chin-gu', meaning: 'friend'),
  QuizWord(hangul: '수업', romanization: 'su-eop', meaning: 'class, lesson'),
  QuizWord(hangul: '시험', romanization: 'si-heom', meaning: 'exam, test'),
  QuizWord(hangul: '교수', romanization: 'gyo-su', meaning: 'professor'),
  QuizWord(hangul: '학생', romanization: 'hak-saeng', meaning: 'student'),
  QuizWord(hangul: '공부', romanization: 'gong-bu', meaning: 'study'),
  QuizWord(hangul: '숙제', romanization: 'suk-je', meaning: 'homework'),
  QuizWord(hangul: '가방', romanization: 'ga-bang', meaning: 'bag'),
  QuizWord(hangul: '시간', romanization: 'si-gan', meaning: 'time'),
  QuizWord(hangul: '커피', romanization: 'keo-pi', meaning: 'coffee'),
  QuizWord(hangul: '우유', romanization: 'u-yu', meaning: 'milk'),
  QuizWord(hangul: '물', romanization: 'mul', meaning: 'water'),
  QuizWord(hangul: '밥', romanization: 'bap', meaning: 'rice, meal'),
  QuizWord(hangul: '김치', romanization: 'gim-chi', meaning: 'kimchi'),
  QuizWord(hangul: '버스', romanization: 'beo-seu', meaning: 'bus'),
  QuizWord(hangul: '택시', romanization: 'taek-si', meaning: 'taxi'),
  QuizWord(hangul: '공항', romanization: 'gong-hang', meaning: 'airport'),
  QuizWord(hangul: '은행', romanization: 'eun-haeng', meaning: 'bank'),
  QuizWord(hangul: '약국', romanization: 'yak-guk', meaning: 'pharmacy'),
  QuizWord(hangul: '도시', romanization: 'do-si', meaning: 'city'),
  QuizWord(hangul: '나라', romanization: 'na-ra', meaning: 'country'),
  QuizWord(hangul: '한국', romanization: 'han-guk', meaning: 'Korea'),
  QuizWord(hangul: '서울', romanization: 'seo-ul', meaning: 'Seoul'),
  QuizWord(hangul: '아침', romanization: 'a-chim', meaning: 'morning'),
  QuizWord(hangul: '저녁', romanization: 'jeo-nyeok', meaning: 'evening'),
  QuizWord(hangul: '오늘', romanization: 'o-neul', meaning: 'today'),
  QuizWord(hangul: '내일', romanization: 'nae-il', meaning: 'tomorrow'),
  QuizWord(hangul: '주말', romanization: 'ju-mal', meaning: 'weekend'),
  QuizWord(hangul: '방학', romanization: 'bang-hak', meaning: 'school vacation'),
  QuizWord(hangul: '기차', romanization: 'gi-cha', meaning: 'train'),
  QuizWord(hangul: '하늘', romanization: 'ha-neul', meaning: 'sky'),
  QuizWord(hangul: '바다', romanization: 'ba-da', meaning: 'sea'),
  QuizWord(hangul: '노래', romanization: 'no-rae', meaning: 'song'),
  QuizWord(hangul: '음악', romanization: 'eum-ak', meaning: 'music'),
  QuizWord(hangul: '운동', romanization: 'un-dong', meaning: 'exercise'),
  QuizWord(hangul: '우산', romanization: 'u-san', meaning: 'umbrella'),
  QuizWord(hangul: '모자', romanization: 'mo-ja', meaning: 'hat'),
  QuizWord(hangul: '신발', romanization: 'sin-bal', meaning: 'shoes'),
  QuizWord(hangul: '지갑', romanization: 'ji-gap', meaning: 'wallet'),
  QuizWord(hangul: '시장', romanization: 'si-jang', meaning: 'market'),
  QuizWord(hangul: '극장', romanization: 'geuk-jang', meaning: 'theater'),
  QuizWord(hangul: '교실', romanization: 'gyo-sil', meaning: 'classroom'),
  QuizWord(hangul: '칠판', romanization: 'chil-pan', meaning: 'blackboard'),
  QuizWord(hangul: '사전', romanization: 'sa-jeon', meaning: 'dictionary'),
  QuizWord(hangul: '단어', romanization: 'da-neo', meaning: 'word'),
  QuizWord(hangul: '학점', romanization: 'hak-jeom', meaning: 'credits, grade'),
  QuizWord(hangul: '성적', romanization: 'seong-jeok', meaning: 'grades'),
  QuizWord(hangul: '졸업', romanization: 'jol-eop', meaning: 'graduation'),
  QuizWord(hangul: '입학', romanization: 'ip-hak', meaning: 'admission'),
];

/// Letters that can be typed on the built-in keyboard.
final Set<String> quizKeyboardLetters = quizKeyboardRows
    .expand((List<String> row) => row)
    .where((String key) => key != 'ENTER' && key != '⌫')
    .toSet();

/// A word is playable when its total letter count (initial + vowel + final
/// consonant of every syllable) fits in 6 tiles and every letter exists on
/// the built-in keyboard.
bool isPlayableWord(QuizWord word) {
  final List<String> letters = word.jamo;
  return letters.isNotEmpty &&
      letters.length <= quizMaxCols &&
      letters.every(quizKeyboardLetters.contains);
}

final List<QuizWord> playableQuizWords =
    quizWords.where(isPlayableWord).toList();

/// Picks a random playable word from two groups mixed together:
///  - words that have not been played yet, and
///  - words the user got wrong the last time they played them
///    (a word leaves this group as soon as it is solved).
/// [current] is never picked, so the same word never comes twice in a row.
/// When every word has been solved, any word except [current] can come up.
QuizWord pickRandomWord(
  math.Random random, {
  List<ReviewEntry> history = const [],
  QuizWord? current,
}) {
  // history is oldest first, so the last result of a word wins.
  final Map<QuizWord, bool> lastSolved = {};
  for (final ReviewEntry entry in history) {
    lastSolved[entry.word] = entry.solved;
  }

  List<QuizWord> candidates = playableQuizWords.where((QuizWord w) {
    if (w == current) {
      return false;
    }
    final bool? solved = lastSolved[w];
    return solved == null || solved == false;
  }).toList();

  if (candidates.isEmpty) {
    candidates = playableQuizWords.where((QuizWord w) => w != current).toList();
  }
  if (candidates.isEmpty) {
    candidates = playableQuizWords;
  }
  return candidates[random.nextInt(candidates.length)];
}
