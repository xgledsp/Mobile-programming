// ================================================================
// ME PAGE DATA MODELS\
// 일정과 saved journeys의 데이터 구조와 샘플 데이터
// ================================================================
//
// For now the data is hard-coded sample data. Later these lists can be
// filled from Notice Explained, user input, a database, etc.
// ================================================================

class ScheduleEvent {
  final String titleEn;
  final String titleKo;
  final DateTime dateTime;
  final String sourceEn;
  final String sourceKo;

  const ScheduleEvent({
    required this.titleEn,
    required this.titleKo,
    required this.dateTime,
    required this.sourceEn,
    required this.sourceKo,
  });
}

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

// ----------------------------------------------------------------
// SAMPLE DATA
// ----------------------------------------------------------------

/// Sample events placed around today so they are visible when the page opens.
List<ScheduleEvent> buildSampleEvents() {
  final DateTime now = DateTime.now();
  return [
    ScheduleEvent(
      titleEn: 'Add/drop deadline',
      titleKo: '수강 정정 마감',
      dateTime: DateTime(now.year, now.month, now.day, 17),
      sourceEn: 'From Notice Explained',
      sourceKo: '공지에서 추가됨',
    ),
    ScheduleEvent(
      titleEn: 'Alien registration appointment',
      titleKo: '외국인 등록 예약',
      dateTime: DateTime(now.year, now.month, now.day + 3, 10, 30),
      sourceEn: 'Added by me',
      sourceKo: '내가 추가함',
    ),
    ScheduleEvent(
      titleEn: 'Dorm rent due',
      titleKo: '기숙사비 납부',
      dateTime: DateTime(now.year, now.month + 1, 5, 18),
      sourceEn: 'From Notice Explained',
      sourceKo: '공지에서 추가됨',
    ),
  ];
}

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
