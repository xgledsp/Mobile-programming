import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mobile_programming/me_models.dart';
import 'package:mobile_programming/notice_models.dart';
import 'package:mobile_programming/notice_page.dart';
import 'package:mobile_programming/notice_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Always returns one future and one past deadline, so the test does not
/// depend on today's date.
class _TestAnalyzer implements NoticeAnalyzer {
  @override
  Future<NoticeAnalysis> analyze(String noticeText) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    final DateTime now = DateTime.now();
    return NoticeAnalysis(
      title: 'Test notice',
      originalText: noticeText,
      summary: 'Test summary.',
      steps: const ['Do the first thing.', 'Do the second thing.'],
      deadlines: [
        ScheduleEvent(
          titleEn: 'Future deadline',
          titleKo: '미래 마감',
          dateTime: DateTime(now.year, now.month, now.day + 3, 18),
          sourceEn: 'From Notice Explained',
          sourceKo: '공지에서 추가됨',
        ),
        ScheduleEvent(
          titleEn: 'Past deadline',
          titleKo: '지난 마감',
          dateTime: DateTime(now.year, now.month, now.day - 3, 18),
          sourceEn: 'From Notice Explained',
          sourceKo: '공지에서 추가됨',
        ),
      ],
    );
  }
}

void main() {
  // [저장 기능 추가] 캘린더에 추가하면 저장도 되니까, 가짜 저장소를 준비해요.
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('Paste text -> explain -> add future date to calendar',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(home: NoticePage(analyzer: _TestAnalyzer())),
    );

    // Explain is disabled until there is text.
    await tester.enterText(find.byType(TextField), '수강신청 안내');
    await tester.pump();

    await tester.tap(find.text('Explain this notice · 공지 해석하기'));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpAndSettle();

    expect(find.text('Test notice'), findsOneWidget);
    expect(find.text('Do the second thing.'), findsOneWidget);

    final int before = eventStore.events.length;
    final Finder addButton = find.text('Add dates to calendar · 캘린더에 추가');
    await tester.ensureVisible(addButton);
    await tester.tap(addButton);
    await tester.pumpAndSettle();

    // Only the future date is pre-checked; the past one is disabled.
    expect(find.text('Passed · 지남'), findsOneWidget);
    await tester.tap(find.text('Add 1 · 1개 추가'));
    await tester.pumpAndSettle();

    expect(eventStore.events.length, before + 1);
    // The plan keeps the "SO, WHAT DO I DO?" steps as its details.
    expect(eventStore.events.last.steps,
        ['Do the first thing.', 'Do the second thing.']);
    expect(find.text('Added to calendar · 캘린더에 추가됨'), findsNothing,
        reason: 'past date was not added, so not everything is added');
  });

  testWidgets('Real pasted notice -> dates found by the local analyzer',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: NoticePage()));

    // PDF input is turned off for now, so only the paste box is shown.
    expect(find.text('Attach a PDF notice'), findsNothing);

    await tester.enterText(find.byType(TextField),
        '• 수강신청: 2099. 3. 2.(월) 10:00 ~ 3. 4.(수) 24:00\n• 개강: 2099. 3. 9.(월)');
    await tester.pump();
    await tester.tap(find.text('Explain this notice · 공지 해석하기'));
    await tester.pumpAndSettle();

    expect(find.text('Dates in your notice'), findsOneWidget);

    final Finder addButton = find.text('Add dates to calendar · 캘린더에 추가');
    await tester.ensureVisible(addButton);
    await tester.tap(addButton);
    await tester.pumpAndSettle();

    expect(find.text('Course registration closes · 수강신청 마감'), findsOneWidget);
    expect(find.text('Classes start · 개강'), findsOneWidget);
    expect(find.text('Add 2 · 2개 추가'), findsOneWidget);
  });

  testWidgets('Pasted image (object character) shows the "not text" message',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: NoticePage()));

    // Rich content with an image pastes as U+FFFC.
    await tester.enterText(find.byType(TextField), '￼');
    await tester.pump();
    await tester.tap(find.text('Explain this notice · 공지 해석하기'));
    await tester.pump();

    expect(find.text(notTextMessage), findsOneWidget);
    expect(find.text('Dates in your notice'), findsNothing);

    // Pasting real text hides the message again.
    await tester.enterText(find.byType(TextField), '수강신청 안내');
    await tester.pump();
    expect(find.text(notTextMessage), findsNothing);
  });

  testWidgets('Pasting text with an image in it shows the message right away',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: NoticePage()));

    // Only a tap-and-paste box: no extra paste button.
    expect(find.textContaining('Paste from clipboard'), findsNothing);

    await tester.enterText(find.byType(TextField), '수강신청 안내 ￼');
    await tester.pump(); // no need to press Explain

    expect(find.text(notTextMessage), findsOneWidget);
  });

  test('looksLikeText', () {
    expect(looksLikeText('2026학년도 동계 계절학기 안내'), isTrue);
    expect(looksLikeText('구분\t일정\n수강신청\t11. 18.'), isTrue); // table copied as text is fine
    expect(looksLikeText(''), isFalse);
    expect(looksLikeText('  \n '), isFalse);
    expect(looksLikeText('￼'), isFalse);
    expect(looksLikeText('수강신청 ￼ 안내'), isFalse);
    expect(looksLikeText('1 2 3 4 5 6 7\n8 9 10'), isFalse);
  });
}
