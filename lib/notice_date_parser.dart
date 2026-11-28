// ================================================================
// NOTICE DATE PARSER
// 한국어 공지 텍스트에서 날짜/기간을 찾아내는 규칙 기반 파서 (API 없이 동작)
// ================================================================
//
// Understands the date styles Korean school notices use, e.g.
//   2026. 11. 18.(수) 10:00 ~ 11. 20.(금) 24:00     (range, end has no year)
//   2026. 12.15.(화) 10:00 ~ 12.22.(화) 23:00       (no spaces)
//   2027. 1. 21.(목) 10:00 ~ 24:00                  (range end is a time only)
//   2026년 9월 7일 오후 6시                           (Korean words)
//   9월 12일까지                                      (no year: taken from the notice)
//
// For every date it also finds a label: the words in front of the date on
// the same line ("• 수강신청: 2026. ..." -> "수강신청").
// ================================================================

class NoticeDate {
  /// Korean label taken from the notice, e.g. "수강신청".
  final String labelKo;

  /// Start of the period. Null when the notice gives a single date.
  final DateTime? start;

  /// The single date, or the END of the period (the deadline).
  final DateTime when;

  /// The notice line this date was found on (trimmed), used as the
  /// event's description in the Me calendar.
  final String line;

  const NoticeDate({
    required this.labelKo,
    required this.when,
    this.start,
    this.line = '',
  });

  bool get isRange => start != null;

  @override
  String toString() => 'NoticeDate($labelKo, start: $start, when: $when)';
}

class NoticeDateParser {
  const NoticeDateParser();

  // One date, optionally followed by a weekday and a time.
  static final RegExp _dateToken = RegExp(
    r'(?:(\d{4})\s*(?:\.|년|-|/)\s*)?' // 1 year (optional)
    r'(\d{1,2})\s*(\.|월|-|/)\s*' // 2 month, 3 separator
    r'(\d{1,2})(?!\d)\s*(\.|일)?' // 4 day, 5 suffix
    r'(?:\s*\(\s*[월화수목금토일]\s*\))?' // weekday, e.g. (수)
    r'(?:\s*(오전|오후))?' // 6 am/pm
    r'(?:\s*(\d{1,2})\s*(?::\s*(\d{2})|시(?:\s*(\d{1,2})\s*분)?))?', // 7 hour, 8/9 minute
  );

  static final RegExp _rangeJoin = RegExp(r'^\s*[~∼〜\-–]\s*$');
  static final RegExp _timeOnlyEnd =
      RegExp(r'^\s*[~∼〜]\s*(오전|오후)?\s*(\d{1,2})\s*(?::\s*(\d{2})|시)');
  static final RegExp _anyYear = RegExp(r'(20\d{2})\s*(?:\.|년|-|/)');

  List<NoticeDate> parse(String text, {DateTime? now}) {
    final DateTime today = now ?? DateTime.now();
    final List<String> lines = text.split(RegExp(r'\r?\n'));
    final String fallbackLabel = _noticeTitle(lines);

    // Year to use when a date has none: the first year in the notice.
    final Match? firstYear = _anyYear.firstMatch(text);
    int lastYear = firstYear != null ? int.parse(firstYear.group(1)!) : today.year;

    final List<NoticeDate> results = [];

    for (final String line in lines) {
      final List<_Token> tokens = [];
      for (final RegExpMatch m in _dateToken.allMatches(line)) {
        final _Token? t = _Token.fromMatch(m);
        if (t != null) tokens.add(t);
      }
      if (tokens.isEmpty) continue;

      int labelFrom = 0; // where the label text for the next date starts
      int i = 0;
      while (i < tokens.length) {
        final _Token first = tokens[i];
        if (first.year != null) lastYear = first.year!;
        final DateTime? startDate = first.toDateTime(first.year ?? lastYear, isEnd: false);

        DateTime? endDate;
        int consumedEnd = first.end;
        int nextIndex = i + 1;

        final _Token? next = i + 1 < tokens.length ? tokens[i + 1] : null;
        final String between = line.substring(first.end, next?.start ?? line.length);

        if (next != null && _rangeJoin.hasMatch(between)) {
          // "A ~ B": B may leave out the year.
          int endYear = next.year ?? startDate?.year ?? lastYear;
          endDate = next.toDateTime(endYear, isEnd: true);
          if (next.year == null && endDate != null && startDate != null && endDate.isBefore(startDate)) {
            endDate = next.toDateTime(endYear + 1, isEnd: true); // Dec ~ Jan
          }
          if (next.year != null) lastYear = next.year!;
          consumedEnd = next.end;
          nextIndex = i + 2;
        } else {
          // "A 10:00 ~ 24:00": the end is a time on the same day.
          final RegExpMatch? t = _timeOnlyEnd.firstMatch(between);
          if (t != null && startDate != null) {
            final int hour = _hour(int.parse(t.group(2)!), t.group(1));
            final int minute = int.tryParse(t.group(3) ?? '') ?? 0;
            endDate = _at(startDate, hour, minute);
            consumedEnd = first.end + t.end;
          }
        }

        if (startDate != null) {
          final String prefix = line.substring(labelFrom, first.start);
          final String suffix = line.substring(consumedEnd, nextIndex < tokens.length ? tokens[nextIndex].start : line.length);
          final String label = _pickLabel(prefix, suffix, fallbackLabel);

          final String lineText = line.replaceAll(RegExp(r'\s+'), ' ').trim();
          final NoticeDate date = endDate != null
              ? NoticeDate(labelKo: label, start: startDate, when: endDate, line: lineText)
              : NoticeDate(labelKo: label, when: startDate, line: lineText);
          final bool duplicate = results.any((r) => r.labelKo == date.labelKo && r.when == date.when);
          if (!duplicate) results.add(date);
        }

        labelFrom = consumedEnd;
        i = nextIndex;
      }
    }

    results.sort((a, b) => a.when.compareTo(b.when));
    return results;
  }

  // --------------------------------------------------------------

  static int _hour(int hour, String? ampm) {
    if (ampm == '오후' && hour < 12) return hour + 12;
    if (ampm == '오전' && hour == 12) return 0;
    return hour;
  }

  /// 24:00 means "end of that day", so it becomes 23:59.
  static DateTime _at(DateTime day, int hour, int minute) {
    if (hour >= 24) return DateTime(day.year, day.month, day.day, 23, 59);
    return DateTime(day.year, day.month, day.day, hour, minute);
  }

  static String _noticeTitle(List<String> lines) {
    for (final String l in lines) {
      final String t = _clean(l.replaceAll(_dateToken, ''));
      if (t.isNotEmpty) return _shorten(t);
    }
    return '일정';
  }

  static String _pickLabel(String prefix, String suffix, String fallback) {
    final String before = _clean(prefix);
    if (before.isNotEmpty) return _shorten(before);
    final String after = _clean(suffix.replaceFirst(RegExp(r'^\s*(까지|부터)'), ''));
    if (after.isNotEmpty) return _shorten(after);
    return fallback;
  }

  static String _clean(String s) {
    String t = s.replaceAll(RegExp(r'\s+'), ' ').trim();
    // Text copied from a PDF can glue a calendar grid in front of a bullet
    // ("1 2 3 4 5 6 7 • 수강신청"): keep only what follows the last bullet.
    final int bullet = t.lastIndexOf('•');
    if (bullet != -1) t = t.substring(bullet + 1);
    t = t.replaceAll(RegExp(r'^\(\s*※\s*'), '');
    t = t.replaceAll(RegExp(r'^[\s•·\-–*※■□○●▶►◆◇▪→>]+'), '');
    t = t.replaceAll(RegExp(r'^(?:(?:\d{1,2}|[일월화수목금토])\s+)+'), ''); // calendar grid
    t = t.replaceAll(RegExp(r'^\(?[※*]\)?\s*'), '');
    t = t.replaceAll(RegExp(r'^\d{1,2}[.)]\s+'), ''); // list numbers: "1. "
    t = t.replaceAll(RegExp(r'^\(\d{1,2}\)\s*'), ''); // "(1) "
    t = t.replaceAll(RegExp(r'[\s:：\-–~∼(,]+$'), '');
    t = t.replaceAll(RegExp(r'\s*(기간|일시|일정|날짜|시간)$'), '');
    return t.trim();
  }

  static String _shorten(String s) => s.length <= 30 ? s : '${s.substring(0, 29)}…';
}

class _Token {
  final int start;
  final int end;
  final int? year;
  final int month;
  final int day;
  final int? hour;
  final int minute;

  _Token(this.start, this.end, this.year, this.month, this.day, this.hour, this.minute);

  static _Token? fromMatch(RegExpMatch m) {
    final int? year = m.group(1) != null ? int.parse(m.group(1)!) : null;
    final int month = int.parse(m.group(2)!);
    final String sep = m.group(3)!;
    final int day = int.parse(m.group(4)!);
    final String? suffix = m.group(5);
    final bool hasWeekday = m.group(0)!.contains('(');

    if (month < 1 || month > 12 || day < 1 || day > 31) return null;
    if (year != null && (year < 2000 || year > 2100)) return null;
    // Without a year, only accept clear date shapes ("9. 7." / "9. 7.(월)" / "9월 7일"),
    // so things like "1.5" or phone numbers are not read as dates.
    if (year == null) {
      final bool dotted = sep == '.' && (suffix == '.' || hasWeekday);
      final bool korean = sep == '월' && suffix == '일';
      if (!dotted && !korean) return null;
    }

    int? hour = m.group(7) != null ? int.parse(m.group(7)!) : null;
    final int minute = int.tryParse(m.group(8) ?? m.group(9) ?? '') ?? 0;
    if (hour != null) {
      hour = NoticeDateParser._hour(hour, m.group(6));
      if (hour > 24 || minute > 59) hour = null;
    }
    return _Token(m.start, m.end, year, month, day, hour, minute);
  }

  /// Dates without a time: a deadline counts until 23:59, a single date at 09:00.
  DateTime? toDateTime(int year, {required bool isEnd}) {
    final DateTime day = DateTime(year, month, this.day);
    if (day.month != month) return null; // e.g. Feb 30
    if (hour == null) {
      return isEnd ? DateTime(year, month, this.day, 23, 59) : DateTime(year, month, this.day, 9);
    }
    return NoticeDateParser._at(day, hour!, minute);
  }
}
