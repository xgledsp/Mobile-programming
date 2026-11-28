import 'app_theme.dart';

// ================================================================
// ME PAGE STRINGS
// ME 화면에 나오는 모든 글자들 모아둠. 나중에 Me 화면에서 
// ================================================================
//
// English mode  -> "English · 한국어" (bilingual, for learning Korean)
// Korean mode   -> "한국어" only
//
// Every piece of text on the Me page comes from here, so the widgets
// never need to check the language themselves.
// ================================================================

class MeStrings {
  final AppLanguage language;

  const MeStrings(this.language);

  bool get isEnglish => language == AppLanguage.english;

  // English mode shows both, Korean mode shows Korean only.
  String _bi(String en, String ko) => isEnglish ? '$en · $ko' : ko;

  // --- Header ------------------------------------------------------
  String get title => isEnglish ? 'Me' : '나';
  String get subtitle => _bi('Your dates and memories', '나의 일정과 여정');
  String get editProfile => isEnglish ? 'edit your profile' : '프로필 수정';
  String get profileComingSoon =>
      _bi('Profile page coming soon', '프로필 화면은 준비 중이에요');

  // --- Calendar ----------------------------------------------------
  String get myCalendar => _bi('My calendar', '나의 일정');
  String get noEvents => _bi('No plans on this day', '이 날은 일정이 없어요');

  List<String> get weekdayHeaders => isEnglish
      ? const ['S', 'M', 'T', 'W', 'T', 'F', 'S']
      : const ['일', '월', '화', '수', '목', '금', '토'];

  static const List<String> _monthsEn = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  /// Big part of the calendar header: "September 2025" / "2025년 9월"
  String monthTitle(DateTime month) => isEnglish
      ? '${_monthsEn[month.month - 1]} ${month.year}'
      : '${month.year}년 ${month.month}월';

  /// Small Korean hint next to the English month: "9월". Null in Korean mode.
  String? monthHint(DateTime month) => isEnglish ? '${month.month}월' : null;

  /// "Wed 9/10, 5 PM · 9월 10일 (수) 오후 5시" / "9월 10일 (수) 오후 5시"
  String eventTime(DateTime t) => _bi(_eventTimeEn(t), _eventTimeKo(t));

  /// Period: "Mon 9/8, 10 AM ~ Fri 9/12, 11:59 PM" (+ Korean line in
  /// English mode, on its own line because it is long).
  String eventPeriod(DateTime start, DateTime end) {
    final String en = '${_eventTimeEn(start)} ~ ${_eventTimeEn(end)}';
    final String ko = '${_eventTimeKo(start)} ~ ${_eventTimeKo(end)}';
    return isEnglish ? '$en\n$ko' : ko;
  }

  /// Small grey label in a calendar cell when a day has hidden events.
  String moreEvents(int n) => isEnglish ? '+$n more' : '+$n개';

  String get deleteTitle => _bi('Delete this plan?', '이 일정을 삭제할까요?');
  String get cancel => _bi('Cancel', '취소');
  String get delete => _bi('Delete', '삭제');
  String get deleted => _bi('Plan deleted', '일정을 삭제했어요');

  static const List<String> _weekdaysEn = [
    'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun',
  ];
  static const List<String> _weekdaysKo = ['월', '화', '수', '목', '금', '토', '일'];

  String _eventTimeEn(DateTime t) {
    final int hour12 = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final String minute =
        t.minute == 0 ? '' : ':${t.minute.toString().padLeft(2, '0')}';
    final String amPm = t.hour < 12 ? 'AM' : 'PM';
    return '${_weekdaysEn[t.weekday - 1]} ${t.month}/${t.day}, '
        '$hour12$minute $amPm';
  }

  String _eventTimeKo(DateTime t) {
    final int hour12 = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final String minute = t.minute == 0 ? '' : ' ${t.minute}분';
    final String amPm = t.hour < 12 ? '오전' : '오후';
    return '${t.month}월 ${t.day}일 (${_weekdaysKo[t.weekday - 1]}) '
        '$amPm $hour12시$minute';
  }

  // --- Saved journeys ----------------------------------------------
  String get savedJourneys => _bi('Saved journeys', '저장한 여정');

  String journeyCount(int n) {
    if (isEnglish) return n == 1 ? '1 journey' : '$n journeys';
    return '$n개의 여정';
  }

  // Stat labels: English mode shows an English line + a Korean line under it.
  String get statDaysEn => 'days in Korea';
  String get statDaysKo => '한국에서';
  String get statQuestsEn => 'quests';
  String get statQuestsKo => '퀘스트';
  String get statItemsEn => 'items returned';
  String get statItemsKo => '반납 완료';

  String get viewSavedJourneys => _bi('View saved journeys', '저장한 여정 보기');

  /// Pick the right text out of a model that stores both languages.
  /// Plans the user typed store the same text in both: shown once.
  String pick(String en, String ko) => en == ko ? en : _bi(en, ko);

  // --- Add / edit a plan --------------------------------------------
  String get addPlan => _bi('Add plan', '일정 추가');
  String get editPlan => _bi('Edit plan', '일정 수정');
  String get planTitle => _bi('Title', '제목');
  String get planTitleHint => isEnglish ? 'e.g. Dorm application' : '예) 생활관 신청';
  String get isPeriod => _bi('Period (start ~ end)', '기간 (시작 ~ 마감)');
  String get startLabel => _bi('Start', '시작');
  String get endLabel => _bi('End', '마감');
  String get whenLabel => _bi('When', '날짜');
  String get memo => _bi('Memo', '메모');
  String get memoHint => isEnglish ? 'Anything to remember (optional)' : '기억할 내용 (선택)';
  String get save => _bi('Save', '저장');
  String get titleRequired => _bi('Please enter a title', '제목을 입력해 주세요');
  String get endBeforeStart =>
      _bi('The end must be after the start', '마감은 시작보다 뒤여야 해요');
  String get duplicatePlan =>
      _bi('This plan is already in your calendar', '이미 캘린더에 있는 일정이에요');
  String get planAdded => _bi('Plan added', '일정을 추가했어요');
  String get planUpdated => _bi('Plan updated', '일정을 수정했어요');
  String get addedByMeEn => 'Added by me';
  String get addedByMeKo => '내가 추가함';

  // --- Plan details --------------------------------------------------
  String get whatToDo => _bi('What do I do?', '어떻게 해야 할까요?');
  String get calendarHint => _bi('Long-press to delete', '길게 누르면 삭제');

  /// "2026. 11. 25 (Wed)" / "2026. 11. 25 (수)"
  String formDate(DateTime d) {
    final String w =
        isEnglish ? _weekdaysEn[d.weekday - 1] : _weekdaysKo[d.weekday - 1];
    return '${d.year}. ${d.month}. ${d.day} ($w)';
  }

  /// "09:00"
  String formTime(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}
