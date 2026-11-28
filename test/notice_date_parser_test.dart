import 'package:flutter_test/flutter_test.dart';

import 'package:mobile_programming/notice_date_parser.dart';
import 'package:mobile_programming/notice_service.dart';

const NoticeDateParser parser = NoticeDateParser();
final DateTime now = DateTime(2026, 11, 25);

NoticeDate byLabel(List<NoticeDate> dates, String label) =>
    dates.firstWhere((d) => d.labelKo == label, orElse: () => throw StateError('no "$label" in $dates'));

void main() {
  test('winter session schedule (sample PDF text)', () {
    const String text = '''2026학년도 동계 계절학기 일정 및 운영 안내

• 수강신청: 2026. 11. 18.(수) 10:00 ~ 11. 20.(금) 24:00
• 1차 폐강 공고: 2026. 11. 25.(수) 17:00
• 수강정정: 2026. 11. 26.(목) 10:00 ~ 11. 27.(금) 24:00
  ※ 1차 수강신청하지 않은 경우도 여석 있으면 신청가능
• 수강료 고지서 출력 및 납부(1차): 2026. 12. 2.(수) 09:00 ~ 12. 4.(금) 21:00
• 수강 취소: 2026. 12. 15.(화) 10:00 ~ 2027. 1. 4.(월)
등록금 전액 2026. 12.15.(화) 10:00 ~ 12.22.(화) 23:00
• 개강: 2026. 12. 23.(수)
• 성적 정정: 2027. 1. 21.(목) 10:00 ~ 24:00
문의: 교양대학 교학지원팀(02-820-6631,6638) 최대 6학점, 버전 1.5''';

    final List<NoticeDate> dates = parser.parse(text, now: now);

    final NoticeDate reg = byLabel(dates, '수강신청');
    expect(reg.start, DateTime(2026, 11, 18, 10));
    expect(reg.when, DateTime(2026, 11, 20, 23, 59)); // 24:00 -> 23:59

    expect(byLabel(dates, '1차 폐강 공고').when, DateTime(2026, 11, 25, 17));
    expect(byLabel(dates, '수강료 고지서 출력 및 납부(1차)').when, DateTime(2026, 12, 4, 21));
    expect(byLabel(dates, '수강 취소').when, DateTime(2027, 1, 4, 23, 59)); // explicit next year, no time
    expect(byLabel(dates, '등록금 전액').when, DateTime(2026, 12, 22, 23)); // "12.15." with no spaces
    expect(byLabel(dates, '개강').when, DateTime(2026, 12, 23, 9)); // single date, no time
    expect(byLabel(dates, '성적 정정').when, DateTime(2027, 1, 21, 23, 59)); // "~ 24:00" time-only end

    // Phone numbers and "1.5" are not dates; results are sorted.
    expect(dates.length, 8);
    for (int i = 1; i < dates.length; i++) {
      expect(dates[i - 1].when.isAfter(dates[i].when), isFalse);
    }
  });

  test('Korean words, missing year, and Dec -> Jan rollover', () {
    const String text = '''2026학년도 기숙사 안내
1. 입사 신청 기간: 12월 28일 ~ 1월 3일
2. 서류 제출은 2026년 12월 30일 오후 6시까지
기간: 2026. 9. 1.(화) 10:00 ~ 9. 7.(월) 23:59''';

    final List<NoticeDate> dates = parser.parse(text, now: now);

    final NoticeDate move = byLabel(dates, '입사 신청');
    expect(move.start, DateTime(2026, 12, 28, 9));
    expect(move.when, DateTime(2027, 1, 3, 23, 59)); // Jan comes after Dec

    expect(byLabel(dates, '서류 제출은').when, DateTime(2026, 12, 30, 18)); // 오후 6시

    // "기간:" has no label of its own, so the notice title is used.
    expect(byLabel(dates, '2026학년도 기숙사 안내').when, DateTime(2026, 9, 7, 23, 59));
  });

  test('no dates', () {
    expect(parser.parse('희망근로지는 2개까지 신청할 수 있습니다. 문의 1599-2290', now: now), isEmpty);
  });

  test('LocalNoticeAnalyzer builds English titles and steps', () async {
    final LocalNoticeAnalyzer analyzer = LocalNoticeAnalyzer(clock: () => now);
    final analysis = await analyzer.analyze(
        '• 수강신청: 2026. 11. 18.(수) 10:00 ~ 11. 20.(금) 24:00\n• 개강: 2026. 12. 23.(수)');

    expect(analysis.deadlines.map((e) => e.titleEn), ['Course registration closes', 'Classes start']);
    expect(analysis.deadlines.map((e) => e.titleKo), ['수강신청 마감', '개강']);
    expect(analysis.steps.first, contains('(already passed)'));
    expect(analysis.summary, contains('1 upcoming'));
  });
}
