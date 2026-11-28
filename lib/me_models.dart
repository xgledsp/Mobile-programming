import 'dart:convert'; // [저장 기능 추가] 일정 목록 <-> JSON 문자열 변환용

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart'; // [저장 기능 추가]

// ================================================================
// ME PAGE DATA MODELS
// 일정과 saved journeys의 데이터 구조
// Data Structures for 'Schedules' and 'Saved Journeys'
// ================================================================
//
// [저장 기능 추가] 캘린더 일정은 이제 기기에 저장됩니다 (shared_preferences).
//  - 앱을 껐다 켜도 사용자가 추가/수정/삭제한 일정이 그대로 남아요.
//  - 예전에 들어 있던 샘플 일정(buildSampleEvents)은 삭제했어요.
//    그래서 처음 실행하면 캘린더가 비어 있어요.
// Saved journeys는 아직 샘플 데이터예요 (맨 아래 sampleJourneys).
// ================================================================

class ScheduleEvent {
  final String titleEn;
  final String titleKo;

  /// The single date, or the END of the period (the deadline).
  final DateTime dateTime;

  /// Start of the period. Null when the event is on one day only.
  final DateTime? startDateTime;

  /// Optional memo shown in the plan's details
  /// (the user's own memo, or the line of the notice this date came from).
  final String? description;

  /// "What do I do?" steps shown in the plan's details.
  /// Filled from Notice Explained's "SO, WHAT DO I DO?" section
  /// (see [whatToDoForEvent] in notice_service.dart). Empty for own plans.
  final List<String> steps;

  final String sourceEn;
  final String sourceKo;

  const ScheduleEvent({
    required this.titleEn,
    required this.titleKo,
    required this.dateTime,
    this.startDateTime,
    this.description,
    this.steps = const [],
    required this.sourceEn,
    required this.sourceKo,
  });

  /// Same plan with its "what do I do?" steps replaced.
  ScheduleEvent withSteps(List<String> newSteps) => ScheduleEvent(
        titleEn: titleEn,
        titleKo: titleKo,
        dateTime: dateTime,
        startDateTime: startDateTime,
        description: description,
        steps: List.unmodifiable(newSteps),
        sourceEn: sourceEn,
        sourceKo: sourceKo,
      );

  /// Same title at the same time counts as the same plan.
  bool sameAs(ScheduleEvent other) =>
      titleEn == other.titleEn && dateTime == other.dateTime;

  /// True when the event covers more than one calendar day.
  bool get isRange => !isSameDay(startDay, endDay);

  /// First calendar day of the event (time stripped).
  DateTime get startDay {
    final DateTime s = startDateTime ?? dateTime;
    final DateTime first = s.isAfter(dateTime) ? dateTime : s;
    return DateTime(first.year, first.month, first.day);
  }

  /// Last calendar day of the event (time stripped).
  DateTime get endDay => DateTime(dateTime.year, dateTime.month, dateTime.day);

  /// True if [day] is between the first and last day (inclusive).
  bool occursOn(DateTime day) {
    final DateTime d = DateTime(day.year, day.month, day.day);
    return !d.isBefore(startDay) && !d.isAfter(endDay);
  }

  // ---------------------------------------------------------------
  // [저장 기능 추가] JSON 변환
  // shared_preferences는 문자열/숫자 같은 단순한 값만 저장할 수 있어서,
  // 일정 하나를 Map(JSON)으로 바꿨다가(toJson) 다시 일정으로 되돌려요(fromJson).
  // DateTime은 "2026-11-26T09:00:00.000" 같은 문자열로 저장해요.
  // ---------------------------------------------------------------

  /// 일정 -> JSON Map (저장할 때 사용)
  Map<String, dynamic> toJson() => {
        'titleEn': titleEn,
        'titleKo': titleKo,
        'dateTime': dateTime.toIso8601String(),
        'startDateTime': startDateTime?.toIso8601String(),
        'description': description,
        'steps': steps,
        'sourceEn': sourceEn,
        'sourceKo': sourceKo,
      };

  /// JSON Map -> 일정 (불러올 때 사용)
  factory ScheduleEvent.fromJson(Map<String, dynamic> json) => ScheduleEvent(
        titleEn: json['titleEn'] as String,
        titleKo: json['titleKo'] as String,
        dateTime: DateTime.parse(json['dateTime'] as String),
        startDateTime: json['startDateTime'] == null
            ? null
            : DateTime.parse(json['startDateTime'] as String),
        description: json['description'] as String?,
        steps: List<String>.unmodifiable(
            (json['steps'] as List<dynamic>? ?? const []).cast<String>()),
        sourceEn: json['sourceEn'] as String,
        sourceKo: json['sourceKo'] as String,
      );
}

/// Whole days from [a] to [b] (calendar days, safe across DST changes).
int daysBetween(DateTime a, DateTime b) =>
    DateTime.utc(b.year, b.month, b.day)
        .difference(DateTime.utc(a.year, a.month, a.day))
        .inDays;

class SavedJourney {
  final String titleEn;
  final String titleKo;
  final String subtitleEn;
  final String subtitleKo;
  final int daysInKorea;
  final int questsDone;
  final int questsTotal;
  final int itemsReturned;
  final bool completed;

  const SavedJourney({
    required this.titleEn,
    required this.titleKo,
    required this.subtitleEn,
    required this.subtitleKo,
    required this.daysInKorea,
    required this.questsDone,
    required this.questsTotal,
    required this.itemsReturned,
    this.completed = false,
  });
}

bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

// ================================================================
// SHARED CALENDAR EVENTS
// Notice Explained adds events here, and the Me tab calendar listens,
// so a new deadline shows up in the calendar right away.
//
// [저장 기능 추가] 일정이 바뀔 때마다(추가/수정/삭제) 전체 목록을 JSON
// 문자열 하나로 만들어 기기에 저장하고, 앱이 시작될 때 load()로 불러와요.
// 달력 화면과 Notice 화면은 예전처럼 add/update/remove만 부르면 되고,
// 저장은 이 클래스가 알아서 해요.
// ================================================================

class EventStore extends ChangeNotifier {
  /// [저장 기능 추가] 기기에 저장할 때 쓰는 이름(키).
  /// 나중에 저장 형식을 크게 바꾸면 v2처럼 이름을 바꾸면 돼요.
  static const String storageKey = 'me_calendar_events_v1';

  // [수정] 예전에는 샘플 일정을 받아서 시작했지만, 이제 빈 목록으로 시작하고
  // load()가 저장된 일정을 채워요.
  final List<ScheduleEvent> _events = [];

  EventStore();

  List<ScheduleEvent> get events => List.unmodifiable(_events);

  // ---------------------------------------------------------------
  // [저장 기능 추가] 불러오기 / 저장하기
  // ---------------------------------------------------------------

  /// 저장된 일정을 불러와요. 앱 시작 시 main()에서 한 번 불러요.
  /// 저장된 게 없으면(첫 실행) 빈 캘린더로 시작해요.
  /// 저장된 데이터가 깨져 있어도 앱이 멈추지 않도록 빈 목록으로 시작해요.
  Future<void> load() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? saved = prefs.getString(storageKey);
    _events.clear();
    if (saved != null) {
      try {
        final List<dynamic> list = jsonDecode(saved) as List<dynamic>;
        _events.addAll(list.map(
            (dynamic j) => ScheduleEvent.fromJson(j as Map<String, dynamic>)));
      } catch (e) {
        debugPrint('Could not read saved calendar events: $e');
        _events.clear();
      }
    }
    notifyListeners();
  }

  /// 지금 일정 목록 전체를 JSON 문자열 하나로 바꿔 기기에 저장해요.
  Future<void> _save() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String json =
        jsonEncode(_events.map((ScheduleEvent e) => e.toJson()).toList());
    await prefs.setString(storageKey, json);
  }

  /// [저장 기능 추가] 일정이 바뀌었을 때 부르는 함수:
  /// 화면을 다시 그리라고 알리고(notifyListeners) + 기기에 저장해요(_save).
  void _changed() {
    notifyListeners();
    _save();
  }

  /// Same title at the same time counts as the same event.
  bool contains(ScheduleEvent e) => _events.any((x) => x.sameAs(e));

  /// Adds the events that are not in the calendar yet.
  /// Returns how many were actually added.
  int addAll(Iterable<ScheduleEvent> newEvents) {
    int added = 0;
    for (final ScheduleEvent e in newEvents) {
      if (!contains(e)) {
        _events.add(e);
        added++;
      }
    }
    if (added > 0) _changed(); // [수정] notifyListeners() -> _changed() (저장 포함)
    return added;
  }

  /// Adds one plan (the "Add plan" button in the Me calendar).
  /// Returns false if the same plan is already there.
  bool add(ScheduleEvent e) => addAll([e]) == 1;

  /// Replaces [oldEvent] with [newEvent] (the pencil button).
  /// Returns false if [oldEvent] is gone, or if [newEvent] would be a
  /// copy of another plan.
  bool update(ScheduleEvent oldEvent, ScheduleEvent newEvent) {
    final int i = _events.indexWhere((x) => x.sameAs(oldEvent));
    if (i == -1) return false;
    final bool clash = _events.any((x) => x.sameAs(newEvent) && !x.sameAs(oldEvent));
    if (clash) return false;
    _events[i] = newEvent;
    _changed(); // [수정] notifyListeners() -> _changed() (저장 포함)
    return true;
  }

  /// Removes [e] (long-press delete in the Me calendar).
  /// Returns false if it was not in the calendar.
  bool remove(ScheduleEvent e) {
    final int before = _events.length;
    _events.removeWhere((x) => x.sameAs(e));
    final bool removed = _events.length != before;
    if (removed) _changed(); // [수정] notifyListeners() -> _changed() (저장 포함)
    return removed;
  }
}

// [수정] 샘플 일정 없이 빈 캘린더로 만들어요.
// 저장된 일정은 main()의 eventStore.load()가 채워요.
final EventStore eventStore = EventStore();

const List<SavedJourney> sampleJourneys = [
  SavedJourney(
    titleEn: "Sarah's journey in Korea",
    titleKo: '사라의 한국 여정',
    subtitleEn: 'A semester to remember',
    subtitleKo: '소중한 한 학기',
    daysInKorea: 112,
    questsDone: 12,
    questsTotal: 12,
    itemsReturned: 4,
    completed: true,
  ),
];
