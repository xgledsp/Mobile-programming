// Data and storage for the Quests tab.

/// One quest in the user's list.
class Quest {
  final String id; // Unique name, used to find a quest (e.g. 'phone')
  final String title; // English title
  final String titleKo; // Korean title
  bool done; // true after the user taps "Done"
  final String iconKey; // Name of the icon, e.g. 'phone' (see quest_icons.dart)
  final String
      phase; // Return quests only: 'anytime', 'lastWeek' or 'returnDay'

  Quest({
    required this.id,
    required this.title,
    required this.titleKo,
    this.done = false,
    this.iconKey = 'flag',
    this.phase = 'anytime',
  });
}

/// The three time groups on the Return tab, in the order they are shown.
const List<String> returnPhases = ['anytime', 'lastWeek', 'returnDay'];

/// Title shown for each time group.
const Map<String, String> phaseTitles = {
  'anytime': 'Anytime · 언제든',
  'lastWeek': 'Last week · 마지막 주',
  'returnDay': 'Return day · 귀국 당일',
};

/// Values from the My stay sheet.
/// Dates are null until the user picks them.
class TripSettings {
  DateTime? arrivalDate;
  DateTime? departureDate;
  bool hideCompleted;
  bool hideRecommendations;
  bool hideReturnRecommendations;

  TripSettings({
    this.arrivalDate,
    this.departureDate,
    this.hideCompleted = false,
    this.hideRecommendations = false,
    this.hideReturnRecommendations = false,
  });
}

/// Arrival quests suggested in "Recommended quests".
/// A new list is made every time, so adding one never changes the originals.
List<Quest> recommendedArrivalQuests() {
  return [
    Quest(
        id: 'phone',
        title: 'Get a phone number',
        titleKo: '휴대폰 개통',
        iconKey: 'phone'),
    Quest(
        id: 'arc',
        title: 'Register as a foreigner (ARC)',
        titleKo: '외국인등록',
        iconKey: 'arc'),
    Quest(
        id: 'bank',
        title: 'Open a bank account',
        titleKo: '은행 계좌 개설',
        iconKey: 'bank'),
  ];
}

/// Return quests suggested on the Return tab, each with a time group.
List<Quest> recommendedReturnQuests() {
  return [
    Quest(
        id: 'phone_cancel',
        title: 'Cancel phone plan',
        titleKo: '휴대폰 해지',
        iconKey: 'phone',
        phase: 'lastWeek'),
    Quest(
        id: 'bank_close',
        title: 'Close bank account',
        titleKo: '계좌 정리',
        iconKey: 'bank',
        phase: 'lastWeek'),
    Quest(
        id: 'dorm_out',
        title: 'Dorm check-out',
        titleKo: '기숙사 퇴실',
        iconKey: 'home',
        phase: 'returnDay'),
    Quest(
        id: 'arc_return',
        title: 'Return your ARC',
        titleKo: '외국인등록증 반납',
        iconKey: 'arc',
        phase: 'returnDay'), // Done at the airport
    Quest(
        id: 'souvenirs',
        title: 'Buy souvenirs',
        titleKo: '기념품 사기',
        iconKey: 'gift',
        phase: 'anytime'),
    Quest(
        id: 'goodbye',
        title: 'Say goodbye to friends',
        titleKo: '친구들과 인사하기',
        iconKey: 'wave',
        phase: 'anytime'),
  ];
}

/// Saves and loads all Quests data.
///
/// For now everything is kept in memory, so it is lost when the app restarts.
/// When login is ready, only this class changes (save per account).
/// Every method returns a Future, so the screen already waits for it
/// and does not need to change later.
class QuestStore {
  QuestStore._();

  static final QuestStore instance = QuestStore._();

  List<Quest> _quests = [];
  List<Quest> _returnQuests = [];
  TripSettings _settings = TripSettings();

  Future<List<Quest>> loadQuests() async {
    return List<Quest>.of(_quests);
  }

  Future<void> saveQuests(List<Quest> quests) async {
    _quests = List<Quest>.of(quests);
  }

  Future<List<Quest>> loadReturnQuests() async {
    return List<Quest>.of(_returnQuests);
  }

  Future<void> saveReturnQuests(List<Quest> quests) async {
    _returnQuests = List<Quest>.of(quests);
  }

  Future<TripSettings> loadSettings() async {
    return _settings;
  }

  Future<void> saveSettings(TripSettings settings) async {
    _settings = settings;
  }
}
