import 'me_models.dart';
import 'notice_date_parser.dart';
import 'notice_models.dart';

// ================================================================
// NOTICE EXPLAINED SERVICES
// 공지 해석 서비스
// ================================================================
//
//  [Pasted text] -> NoticeAnalyzer.analyze(text) -> NoticeAnalysis
//
// File attachments are not supported (they would need OCR or an AI API).
//
// LocalNoticeAnalyzer works without an API: it finds the real dates in the
// text, and only the summary is toy text. To go live, write an
// ApiNoticeAnalyzer that implements the same interface and pass it to
// NoticePage. The page itself does not need to change.
// ================================================================

/// Shown when the user pastes something that is not text.(사용자가 텍스트 아닌 다른 것 붙여넣기 했을 때)
const String notTextMessage =
    "Sorry, it wasn't text so I couldn't interpret it. Please paste the text.";

/// False for things that are not readable text: an empty paste, an
/// embedded image (pasted rich content leaves U+FFFC "object" characters),
/// or only numbers/symbols with no words at all.

// 첨부한 문장이 텍스트가 맞는지 검사 (이미지나 아무 의미 없는 특수기호는 아닌지)
bool looksLikeText(String text) {
  final String t = text.trim();
  if (t.isEmpty) return false;
  if (t.contains('\uFFFC')) return false;
  return RegExp(r'[가-힣ㄱ-ㅎA-Za-z]').hasMatch(t);
}

// ----------------------------------------------------------------
// "SO, WHAT DO I DO?" -> calendar plan details
// ----------------------------------------------------------------
//
// When a date from a notice is added to the Me calendar, the plan keeps
// these steps; tapping the plan's title in the Me calendar shows them.
//
// TODO(API): for now every date gets the whole "SO, WHAT DO I DO?" list
// of its notice (toy text from [LocalNoticeAnalyzer]). When the AI API is
// connected, change ONLY this function, e.g. ask the API for the steps of
// this one date, or pick the steps that belong to [event]. The calendar
// and the notice page do not need to change.
List<String> whatToDoForEvent(ScheduleEvent event, NoticeAnalysis analysis) {
  return analysis.steps;
}

abstract class NoticeAnalyzer {
  /// Reads the Korean notice text and explains it in English.
  Future<NoticeAnalysis> analyze(String noticeText);
}

/// Explains pasted notice text WITHOUT an API.
/// - The dates are real: [NoticeDateParser] reads them from the text.
/// - The English titles come from a small glossary of school words.
/// - TODO(API): the summary is toy text. When the AI API is connected,
///   replace this class (or only [_summary]) with the real call.
class LocalNoticeAnalyzer implements NoticeAnalyzer {
  final NoticeDateParser parser;
  final DateTime Function() clock;

  const LocalNoticeAnalyzer({
    this.parser = const NoticeDateParser(),
    this.clock = DateTime.now,
  });

  @override
  Future<NoticeAnalysis> analyze(String noticeText) async {
    final DateTime now = clock();
    final List<NoticeDate> dates = parser.parse(noticeText, now: now);
    final List<ScheduleEvent> events = [
      for (final NoticeDate d in dates) _toEvent(d)
    ];

    return NoticeAnalysis(
      title: dates.isEmpty ? 'No dates found' : 'Dates in your notice',
      originalText: noticeText,
      summary: _summary(dates, events, now),
      steps: [
        for (int i = 0; i < dates.length; i++) _step(dates[i], events[i], now),
        'Check the official notice for details and exact conditions.',
      ],
      deadlines: events,
    );
  }

  ScheduleEvent _toEvent(NoticeDate d) {
    final String label = d.labelKo;
    final bool isDeadline = d.isRange || label.contains('마감');
    final String titleKo =
        d.isRange && !label.endsWith('마감') ? '$label 마감' : label;

    final String? base = englishForKorean(label);
    final String titleEn = base == null
        ? (isDeadline ? 'Deadline' : 'Date from notice')
        : (d.isRange
            ? '$base closes'
            : (label.contains('마감') ? '$base deadline' : base));

    return ScheduleEvent(
      titleEn: titleEn,
      titleKo: titleKo,
      dateTime: d.when,
      startDateTime: d.start,
      description: d.line.isEmpty ? null : d.line,
      sourceEn: _fromNoticeEn,
      sourceKo: _fromNoticeKo,
    );
  }

  String _step(NoticeDate d, ScheduleEvent e, DateTime now) {
    // If the glossary had no match, keep the Korean label so the step still says what it is.
    final String what = englishForKorean(d.labelKo) == null
        ? '${e.titleEn} ("${d.labelKo}")'
        : e.titleEn;
    final String when = d.isRange
        ? '${formatNoticeDate(d.start!)} – ${formatNoticeDate(d.when)}'
        : formatNoticeDate(d.when);
    final String passed = d.when.isBefore(now) ? ' (already passed)' : '';
    return '$what: $when$passed';
  }

  String _summary(
      List<NoticeDate> dates, List<ScheduleEvent> events, DateTime now) {
    const String toy =
        '[Toy text] A plain-English explanation of the whole notice '
        'will appear here once the AI API is connected.';
    if (dates.isEmpty) {
      return 'No dates or deadlines were found in this notice. $toy';
    }
    final int upcoming = dates.where((d) => !d.when.isBefore(now)).length;
    final int next = dates.indexWhere((d) => !d.when.isBefore(now));
    final String nextText = next == -1
        ? 'All of them have already passed.'
        : 'The next one is ${events[next].titleEn} on ${formatNoticeDate(dates[next].when)}.';
    final String count = dates.length == 1 ? '1 date' : '${dates.length} dates';
    return 'Found $count in this notice ($upcoming upcoming). $nextText $toy';
  }
}

/// TODO(API): toy translation. A small glossary of common school words,
/// checked in order (more specific words first). Returns null if nothing matches.

// 공지 해설에서 한국어로 된 제목을 영어로 바꾸는 용어 사전. 나중에 API 구현해야 함)
// 지금은 그냥 손수 한국어 -> 영어 사전을 만들어 놓은 것)
// ※ 참고로 용어 사전에 없는 단어는 영어로 바꾸지 못함.
String? englishForKorean(String labelKo) {
  const List<(String, String)> glossary = [
    ('수강신청 정정', 'Add/drop'),
    ('수강정정', 'Add/drop'),
    ('수강 정정', 'Add/drop'),
    ('수강신청', 'Course registration'),
    ('수강 신청', 'Course registration'),
    ('수강취소', 'Course cancellation'),
    ('수강 취소', 'Course cancellation'),
    ('철회', 'Course withdrawal'),
    ('폐강', 'Cancelled-course notice'),
    ('고지서', 'Tuition bill'),
    ('수강료', 'Tuition payment'),
    ('등록금 전액', 'Full tuition refund'),
    ('등록금', 'Tuition'),
    ('환불', 'Refund'),
    ('납부', 'Payment'),
    ('개강', 'Classes start'),
    ('기말고사', 'Final exams'),
    ('중간고사', 'Midterm exams'),
    ('종강', 'Last day of classes'),
    ('강의평가', 'Course evaluation'),
    ('성적 입력', 'Grade entry'),
    ('성적 조회', 'Grades open'),
    ('성적조회', 'Grades open'),
    ('성적 정정', 'Grade correction'),
    ('성적 처리', 'Grade processing'),
    ('장학금', 'Scholarship'),
    ('근로', 'Work scholarship'),
    ('기숙사', 'Dormitory'),
    ('입사', 'Dorm move-in'),
    ('퇴사', 'Dorm move-out'),
    ('휴학', 'Leave of absence'),
    ('복학', 'Return to school'),
    ('졸업', 'Graduation'),
    ('오리엔테이션', 'Orientation'),
    ('면접', 'Interview'),
    ('서류', 'Documents'),
    ('제출', 'Submission'),
    ('접수', 'Application'),
    ('신청', 'Application'),
    ('발표', 'Results announced'),
    ('공고', 'Announcement'),
  ];

  for (final (String ko, String en) in glossary) {
    if (labelKo.contains(ko)) {
      if (labelKo.contains('1차')) return '$en (1st)';
      if (labelKo.contains('2차') && labelKo.contains('최종'))
        return '$en (final)';
      if (labelKo.contains('2차')) return '$en (2nd)';
      if (labelKo.contains('3차')) return '$en (3rd)';
      return en;
    }
  }
  return null;
}

const String _fromNoticeEn = 'From Notice Explained';
const String _fromNoticeKo = '공지에서 추가됨';
