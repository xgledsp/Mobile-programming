import 'text_match.dart';

// ================================================================
// HODU TOPIC GUARD - keeps Hodu inside the app's topic
// ================================================================
//
// Before Hodu answers, the guard looks at the question and decides:
//
//   injection  -> "ignore your instructions..." tricks       -> refuse
//   smallTalk  -> "hi", "thanks", "who are you?"              -> short friendly reply
//   onTopic    -> visas, dorms, banks, school, culture...      -> answer
//   offTopic   -> coding, math homework, stocks, games...      -> refuse
//   unclear    -> no clear signal either way                   -> let the brain decide
//
// It works with simple keyword rules, so it runs OFFLINE and instantly.
// Korean words are matched as substrings because Korean attaches
// particles to words (비자 -> 비자를, 비자가, 비자는).
// English words are matched as whole words (+ plural "s"/"es") so that
// short words do not match inside longer ones.
// ================================================================

enum TopicVerdict { injection, smallTalk, onTopic, offTopic, unclear }

/// What kind of small talk the user wrote.
enum SmallTalkKind { greeting, thanks, goodbye, aboutHodu }

/// Life-in-Korea areas Hodu knows about. The knowledge base (step 4)
/// uses the same categories.
enum TopicCategory {
  visa,
  housing,
  banking,
  phone,
  school,
  transport,
  health,
  work,
  culture,
  language,
  emergency,
  dailyLife,
  appHelp,
}

class TopicDecision {
  final TopicVerdict verdict;

  /// Categories that matched, most matches first. Empty if none.
  final List<TopicCategory> categories;

  /// Only set when [verdict] is [TopicVerdict.smallTalk].
  final SmallTalkKind? smallTalk;

  const TopicDecision(this.verdict, {this.categories = const [], this.smallTalk});

  bool get shouldRefuse =>
      verdict == TopicVerdict.injection || verdict == TopicVerdict.offTopic;

  TopicCategory? get mainCategory => categories.isEmpty ? null : categories.first;

  @override
  String toString() => 'TopicDecision(${verdict.name}, $categories, $smallTalk)';
}

class TopicGuard {
  const TopicGuard();

  TopicDecision classify(String rawText) {
    final String text = TextMatch.normalize(rawText);
    if (text.isEmpty) {
      return const TopicDecision(TopicVerdict.unclear);
    }

    // 1. Tricks that try to change Hodu's rules are always refused.
    if (_matchesAny(text, _injectionPatterns)) {
      return const TopicDecision(TopicVerdict.injection);
    }

    // 2. Short greetings / thanks / "who are you".
    final SmallTalkKind? small = _smallTalk(text);
    if (small != null) {
      return TopicDecision(TopicVerdict.smallTalk, smallTalk: small);
    }

    // 3. Life-in-Korea keywords win over off-topic words, so a question
    //    like "how do I write a resume for a part-time job" is allowed.
    final List<TopicCategory> categories = _matchCategories(text);
    if (categories.isNotEmpty) {
      return TopicDecision(TopicVerdict.onTopic, categories: categories);
    }

    if (_matchesAny(text, _offTopicPatterns)) {
      return const TopicDecision(TopicVerdict.offTopic);
    }

    return const TopicDecision(TopicVerdict.unclear);
  }

  // ------------------------------------------------------------ helpers

  static SmallTalkKind? _smallTalk(String text) {
    // The whole message must be the phrase (Hodu's name may be added:
    // "hi hodu", "고마워 호두야"). Otherwise "hi, how do I open a bank
    // account" would be treated as a greeting and not answered.
    final String withoutName = text
        .split(' ')
        .where((String w) => !_hoduNames.contains(w))
        .join(' ');
    for (final MapEntry<SmallTalkKind, List<String>> entry in _smallTalkPhrases.entries) {
      if (entry.value.contains(withoutName)) {
        return entry.key;
      }
    }
    return null;
  }

  static const Set<String> _hoduNames = {'hodu', '호두', '호두야', '호두씨'};

  static List<TopicCategory> _matchCategories(String text) {
    final Map<TopicCategory, int> hits = {};
    _topicKeywords.forEach((TopicCategory category, List<String> keywords) {
      final int count = TextMatch.countKeywords(text, keywords);
      if (count > 0) {
        hits[category] = count;
      }
    });
    final List<TopicCategory> sorted = hits.keys.toList()
      ..sort((TopicCategory a, TopicCategory b) => hits[b]!.compareTo(hits[a]!));
    return sorted;
  }

  static bool _matchesAny(String text, List<String> keywords) =>
      keywords.any((String k) => TextMatch.containsKeyword(text, k));

  // ------------------------------------------------------------ word lists

  static const List<String> _injectionPatterns = [
    'ignore previous instructions',
    'ignore all previous instructions',
    'ignore the above',
    'ignore your instructions',
    'ignore your rules',
    'forget your instructions',
    'system prompt',
    'you are now',
    'pretend you are',
    'pretend to be',
    'act as if you have no rules',
    'developer mode',
    'jailbreak',
    '이전 지시',
    '지시를 무시',
    '규칙을 무시',
    '시스템 프롬프트',
  ];

  static const Map<SmallTalkKind, List<String>> _smallTalkPhrases = {
    SmallTalkKind.greeting: [
      'hi', 'hello', 'hey', 'good morning', 'good afternoon', 'good evening',
      '안녕', '안녕하세요', '하이', '반가워', '반가워요',
    ],
    SmallTalkKind.thanks: [
      'thanks', 'thank you', 'thx', 'ty', 'thank you so much',
      '고마워', '고마워요', '감사합니다', '감사해요', '땡큐',
    ],
    SmallTalkKind.goodbye: [
      'bye', 'goodbye', 'see you', 'see ya',
      '잘가', '잘 가', '안녕히 계세요', '또 봐', '다음에 봐요',
    ],
    SmallTalkKind.aboutHodu: [
      'who are you', 'what are you', 'what can you do', 'help', 'what is hodu',
      '누구야', '넌 누구야', '너는 누구야', '뭐 할 수 있어', '도와줘',
    ],
  };

  static const Map<TopicCategory, List<String>> _topicKeywords = {
    TopicCategory.visa: [
      'visa', 'arc', 'alien registration', 'residence card', 'residence permit',
      'immigration', 'hikorea', 'passport', 'd-2', 'd2', 'd-4', 'd4', 'extend my stay',
      'overstay', 'reentry', 're-entry', 'status of stay',
      '비자', '체류', '외국인등록', '외국인 등록', '등록증', '출입국', '여권', '하이코리아',
    ],
    TopicCategory.housing: [
      'dorm', 'dormitory', 'housing', 'rent', 'apartment', 'one room', 'goshiwon',
      'landlord', 'deposit', 'lease', 'contract', 'jeonse', 'wolse', 'move in',
      'move out', 'roommate', 'utility', 'utilities', 'gas bill', 'electricity bill',
      '기숙사', '월세', '전세', '보증금', '원룸', '고시원', '부동산', '집주인', '계약서',
      '입주', '퇴실', '관리비', '룸메이트',
    ],
    TopicCategory.banking: [
      'bank', 'bank account', 'debit card', 'credit card', 'money transfer',
      'send money', 'exchange money', 'currency exchange', 'atm', 'kakaobank',
      'toss', 'remittance',
      '은행', '계좌', '통장', '체크카드', '신용카드', '송금', '환전', '이체', '카카오뱅크',
    ],
    TopicCategory.phone: [
      'sim', 'sim card', 'esim', 'phone plan', 'mobile plan', 'phone number',
      'carrier', 'skt', 'kt', 'lg u+', 'data plan', 'prepaid', 'unlocked phone',
      '유심', '요금제', '통신사', '휴대폰', '핸드폰', '전화번호', '알뜰폰', '선불',
    ],
    TopicCategory.school: [
      'school', 'university', 'campus', 'class', 'course', 'lecture', 'professor',
      'exam', 'midterm', 'final exam', 'grade', 'gpa', 'credit', 'semester',
      'add drop', 'add/drop', 'course registration', 'enroll', 'enrollment',
      'tuition', 'scholarship', 'student id', 'student card', 'notice', 'portal',
      'library', 'assignment', 'attendance', 'graduation', 'major', 'leave of absence',
      '학교', '대학', '캠퍼스', '수업', '강의', '교수', '시험', '중간고사', '기말고사',
      '학점', '학기', '수강신청', '수강 신청', '정정', '철회', '등록금', '장학금',
      '학생증', '공지', '도서관', '과제', '출석', '졸업', '전공', '휴학', '복학',
    ],
    TopicCategory.transport: [
      'bus', 'subway', 'metro', 'train', 'ktx', 'taxi', 'kakao t', 't-money',
      'tmoney', 'transportation card', 'airport', 'driver license', "driver's license",
      'bike', 'ddareungi',
      '버스', '지하철', '기차', '택시', '카카오택시', '티머니', '교통카드', '공항',
      '운전면허', '따릉이', '환승',
    ],
    TopicCategory.health: [
      'hospital', 'clinic', 'doctor', 'pharmacy', 'medicine', 'sick', 'fever',
      'health insurance', 'insurance', 'nhis', 'dentist', 'covid', 'vaccine',
      'mental health', 'counseling',
      '병원', '의원', '의사', '약국', '아파요', '아프', '감기', '건강보험',
      '보험', '치과', '상담', '보건소',
    ],
    TopicCategory.work: [
      'part time', 'part-time', 'job', 'work permit', 'internship', 'salary',
      'wage', 'minimum wage', 'employer', 'boss', 'labor', 'labour', 'resume',
      'cv', 'interview', 'working hours', 'unpaid', 'severance', 'tax',
      '아르바이트', '알바', '일자리', '취업', '근무', '월급', '시급', '최저임금',
      '사장님', '노동', '이력서', '면접', '시간제취업', '시간제 취업', '퇴직금', '세금',
    ],
    TopicCategory.culture: [
      'culture', 'etiquette', 'manners', 'polite', 'rude', 'bow', 'age', 'senior',
      'sunbae', 'hoobae', 'unnie', 'oppa', 'hyung', 'noona', 'drinking culture',
      'tipping', 'holiday', 'chuseok', 'seollal', 'korean food', 'table manners',
      'custom', 'tradition',
      '문화', '예절', '예의', '존댓말', '반말', '나이', '선배', '후배', '언니', '오빠',
      '누나', '회식', '술자리', '추석', '설날', '명절', '전통',
    ],
    TopicCategory.language: [
      'korean', 'hangul', 'hangeul', 'translate', 'translation', 'meaning',
      'what does', 'how do you say', 'how to say', 'pronounce', 'pronunciation',
      'honorific', 'grammar', 'vocabulary', 'topik',
      '한국어', '한글', '번역', '무슨 뜻', '뜻이', '뜻은', '발음', '문법', '단어', '토픽',
    ],
    TopicCategory.emergency: [
      'emergency', 'police', 'ambulance', 'fire', '112', '119', '1345',
      'lost my', 'stolen', 'scam', 'fraud', 'harassment', 'embassy', 'accident',
      '응급', '긴급', '경찰', '구급차', '분실', '도난', '사기', '보이스피싱', '대사관',
      '교통사고', '신고',
    ],
    TopicCategory.dailyLife: [
      'trash', 'garbage', 'recycling', 'delivery', 'convenience store', 'grocery',
      'mart', 'laundry', 'post office', 'parcel', 'package', 'coupang', 'baemin',
      'kakaotalk', 'naver', 'address', 'cost of living', 'seoul', 'korea',
      '쓰레기', '분리수거', '음식물', '배달', '편의점', '마트', '세탁', '빨래', '우체국',
      '택배', '쿠팡', '배민', '카카오톡', '네이버', '주소', '생활비', '서울', '한국',
    ],
    TopicCategory.appHelp: [
      'quest', 'calendar', 'word quiz', 'hodu', 'this app', 'saved journey',
      'notice explained', 'culture coach',
      '퀘스트', '캘린더', '일정', '단어 퀴즈', '호두', '이 앱', '여정',
    ],
  };

  static const List<String> _offTopicPatterns = [
    // programming / tech homework
    'code', 'coding', 'programming', 'python', 'javascript', 'java',
    'c++', 'sql', 'html', 'css', 'algorithm', 'debug', 'compile', 'flutter', 'dart',
    // maths / other homework
    'solve', 'equation', 'integral', 'derivative', 'calculus', 'math', 'maths',
    'physics', 'chemistry', 'essay', 'poem', 'story', 'song lyrics',
    // money / entertainment / random
    'stock', 'stocks', 'crypto', 'bitcoin', 'investment', 'lottery', 'bet', 'betting',
    'game', 'games', 'movie', 'anime', 'celebrity', 'football', 'soccer', 'nba',
    'joke', 'recipe', 'horoscope', 'dating', 'girlfriend', 'boyfriend',
    'president', 'election', 'politics', 'religion', 'war',
    // Korean
    '코딩', '프로그래밍', '파이썬', '자바', '수학', '방정식', '미적분', '물리', '화학',
    '에세이', '시를 써', '소설', '주식', '코인', '비트코인', '투자', '로또', '게임',
    '영화', '애니', '연예인', '축구', '농담', '연애', '정치', '선거', '종교', '전쟁',
  ];
}
