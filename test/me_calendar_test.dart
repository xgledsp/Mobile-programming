import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mobile_programming/app_theme.dart';
import 'package:mobile_programming/me_models.dart';
import 'package:mobile_programming/me_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  // [저장 기능 추가] 테스트에서는 실제 기기 저장소 대신 가짜(메모리) 저장소를 써요.
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('First run: the calendar is empty (no sample plans)', () async {
    final EventStore store = EventStore();
    await store.load();
    expect(store.events, isEmpty);
  });

  test('Plans are saved and come back after a restart', () async {
    final EventStore store = EventStore();
    await store.load();
    final ScheduleEvent plan = ScheduleEvent(
      titleEn: 'Bank visit',
      titleKo: '은행 방문',
      startDateTime: DateTime(2026, 12, 1, 10),
      dateTime: DateTime(2026, 12, 3, 18, 30),
      description: 'Bring passport',
      steps: const ['Step 1', 'Step 2'],
      sourceEn: 'Added by me',
      sourceKo: '내가 추가함',
    );
    store.add(plan);
    await pumpEventQueue(); // let the save finish

    // "Restart": a brand-new store reads what was saved.
    final EventStore restarted = EventStore();
    await restarted.load();
    expect(restarted.events, hasLength(1));
    final ScheduleEvent back = restarted.events.single;
    expect(back.sameAs(plan), isTrue);
    expect(back.titleKo, '은행 방문');
    expect(back.startDateTime, DateTime(2026, 12, 1, 10));
    expect(back.description, 'Bring passport');
    expect(back.steps, ['Step 1', 'Step 2']);

    // Edit and delete are saved too.
    final ScheduleEvent renamed = ScheduleEvent(
      titleEn: 'Bank visit (KB)',
      titleKo: 'Bank visit (KB)',
      dateTime: plan.dateTime,
      sourceEn: plan.sourceEn,
      sourceKo: plan.sourceKo,
    );
    restarted.update(back, renamed);
    await pumpEventQueue();
    final EventStore again = EventStore();
    await again.load();
    expect(again.events.single.titleEn, 'Bank visit (KB)');

    again.remove(again.events.single);
    await pumpEventQueue();
    final EventStore last = EventStore();
    await last.load();
    expect(last.events, isEmpty);
  });

  test('Broken saved data does not crash: starts empty', () async {
    SharedPreferences.setMockInitialValues(
        {EventStore.storageKey: 'not json'});
    final EventStore store = EventStore();
    await store.load();
    expect(store.events, isEmpty);
  });

  test('ScheduleEvent period covers every day from start to end', () {
    final ScheduleEvent e = ScheduleEvent(
      titleEn: 'Dorm',
      titleKo: '생활관',
      startDateTime: DateTime(2026, 11, 19, 10),
      dateTime: DateTime(2026, 11, 26, 23, 59),
      sourceEn: 'x',
      sourceKo: 'x',
    );
    expect(e.isRange, isTrue);
    expect(e.occursOn(DateTime(2026, 11, 18)), isFalse);
    expect(e.occursOn(DateTime(2026, 11, 19)), isTrue);
    expect(e.occursOn(DateTime(2026, 11, 22, 15)), isTrue);
    expect(e.occursOn(DateTime(2026, 11, 26)), isTrue);
    expect(e.occursOn(DateTime(2026, 11, 27)), isFalse);
    expect(daysBetween(e.startDay, e.endDay), 7);
  });

  testWidgets('Period bar shows, tapping a day explains it, long-press deletes',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2600);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);

    final DateTime now = DateTime.now();
    final ScheduleEvent period = ScheduleEvent(
      titleEn: 'Test period',
      titleKo: '테스트 기간',
      startDateTime: DateTime(now.year, now.month, 1, 10),
      dateTime: DateTime(now.year, now.month, 10, 23, 59),
      description: 'Line from the notice',
      steps: const ['Do this first', 'Then this'],
      sourceEn: 'Added by me',
      sourceKo: '내가 추가함',
    );
    eventStore.addAll([period]);

    await tester.pumpWidget(
      const MaterialApp(home: MePage(language: AppLanguage.english)),
    );

    // One bar piece per week row the period touches (1st..10th = 2-3 rows).
    expect(find.text('Test period'), findsWidgets);

    // Tap the 5th of this month: only the title is listed.
    await tester.tap(find.text('5').first);
    await tester.pumpAndSettle();
    expect(find.text('Test period · 테스트 기간'), findsOneWidget);
    expect(find.text('Line from the notice'), findsNothing);
    expect(find.text('Do this first'), findsNothing);

    // Tap the title: the details ("what do I do?" steps + memo) open.
    await tester.tap(find.text('Test period · 테스트 기간'));
    await tester.pumpAndSettle();
    expect(find.text('What do I do? · 어떻게 해야 할까요?'), findsOneWidget);
    expect(find.text('Do this first'), findsOneWidget);
    expect(find.text('Line from the notice'), findsOneWidget);

    // Long-press the plan -> confirm -> gone from the calendar.
    await tester.longPress(find.text('Test period · 테스트 기간'));
    await tester.pumpAndSettle();
    expect(find.text('Delete this plan? · 이 일정을 삭제할까요?'), findsOneWidget);
    await tester.tap(find.text('Delete · 삭제'));
    await tester.pumpAndSettle();

    expect(eventStore.contains(period), isFalse);
    expect(find.text('Test period'), findsNothing);
    expect(find.text('Test period · 테스트 기간'), findsNothing);
  });

  testWidgets('Add my own plan, then edit it with the pencil',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2600);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(home: MePage(language: AppLanguage.english)),
    );

    // Add: title only, on the selected day (today) at 09:00.
    final Finder addButton = find.text('Add plan · 일정 추가');
    await tester.ensureVisible(addButton);
    await tester.tap(addButton);
    await tester.pumpAndSettle();

    // Saving without a title shows an error.
    await tester.tap(find.text('Save · 저장'));
    await tester.pump();
    expect(find.text('Please enter a title · 제목을 입력해 주세요'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('planTitleField')), 'Bank visit');
    await tester.enterText(find.byType(TextField).last, 'Bring passport');
    await tester.tap(find.text('Save · 저장'));
    await tester.pumpAndSettle();

    final DateTime now = DateTime.now();
    final ScheduleEvent added = eventStore.events.firstWhere(
        (e) => e.titleEn == 'Bank visit');
    expect(added.titleKo, 'Bank visit');
    expect(added.dateTime, DateTime(now.year, now.month, now.day, 9));
    expect(added.description, 'Bring passport');
    expect(added.sourceEn, 'Added by me');

    // Typed title is shown once (not "Bank visit · Bank visit"),
    // and the new plan's details are already open.
    expect(find.text('Bank visit'), findsWidgets);
    expect(find.text('Bring passport'), findsOneWidget);

    // Edit with the pencil: rename it.
    final Finder pencil = find.descendant(
      of: find.ancestor(
          of: find.text('Bring passport'), matching: find.byType(Material)).first,
      matching: find.byIcon(Icons.edit_outlined),
    );
    await tester.tap(pencil);
    await tester.pumpAndSettle();
    expect(find.text('Edit plan · 일정 수정'), findsOneWidget);
    await tester.enterText(
        find.byKey(const Key('planTitleField')), 'Bank visit (KB)');
    await tester.tap(find.text('Save · 저장'));
    await tester.pumpAndSettle();

    expect(eventStore.events.any((e) => e.titleEn == 'Bank visit'), isFalse);
    final ScheduleEvent edited = eventStore.events.firstWhere(
        (e) => e.titleEn == 'Bank visit (KB)');
    expect(edited.description, 'Bring passport');
    expect(find.text('Bank visit (KB)'), findsWidgets);

    eventStore.remove(edited);
  });
}
