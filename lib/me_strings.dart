import 'app_theme.dart';

// ================================================================
// ME PAGE STRINGS
// ME 화면에 나오는 모든 글자들 모아둠
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
  String pick(String en, String ko) => _bi(en, ko);
}
