// Data and storage for the Quests tab.

/// One quest in the user's list.
class Quest {
  final String id; // Unique name, used to find a quest (e.g. 'phone')
  final String title; // English title
  final String titleKo; // Korean title
  bool done; // true after the user taps "Done"

  Quest({
    required this.id,
    required this.title,
    required this.titleKo,
    this.done = false,
  });
}

/// Values from the Trip settings sheet.
/// Dates are null until the user picks them.
class TripSettings {
  DateTime? arrivalDate;
  DateTime? departureDate;
  bool hideCompleted;
  bool hideRecommendations;

  TripSettings({
    this.arrivalDate,
    this.departureDate,
    this.hideCompleted = false,
    this.hideRecommendations = false,
  });
}

/// Arrival quests suggested in "Recommended quests".
/// A new list is made every time, so adding one never changes the originals.
List<Quest> recommendedArrivalQuests() {
  return [
    Quest(id: 'phone', title: 'Get a phone number', titleKo: '휴대폰 개통'),
    Quest(id: 'arc', title: 'Register as a foreigner (ARC)', titleKo: '외국인등록'),
    Quest(id: 'bank', title: 'Open a bank account', titleKo: '은행 계좌 개설'),
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

  static final QuestStore instance= QuestStore._();

  List<Quest> _quests = [];
  TripSettings _settings = TripSettings();

  Future<List<Quest>> loadQuests() async {
    return List<Quest>.of(_quests);
  }

  Future<void> saveQuests(List<Quest> quests) async {
    _quests = List<Quest>.of(quests);
  }

  Future<TripSettings> loadSettings() async {
    return _settings;
  }

  Future<void> saveSettings(TripSettings settings) async {
    _settings = settings;
  }
}