import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'quest_data.dart';
import 'quest_icons.dart';
import 'quest_sheet.dart';
import 'trip_settings_sheet.dart';

class QuestsPage extends StatefulWidget {
  const QuestsPage({super.key});

  @override
  State<QuestsPage> createState() => _QuestsPageState();
}

class _QuestsPageState extends State<QuestsPage> {
  // false = Arrival tab, true = Return tab.
  bool _showReturn = false;

  // Data from QuestStore (filled in by _loadData).
  List<Quest> _quests = [];
  List<Quest> _returnQuests = [];
  // Time groups the user folded on the Return tab (not saved).
  final Set<String> _collapsedPhases = {};
  TripSettings _settings = TripSettings();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// Reads quests and settings from the store, then redraws the page.
  Future<void> _loadData() async {
    final List<Quest> quests = await QuestStore.instance.loadQuests();
    final List<Quest> returnQuests =
        await QuestStore.instance.loadReturnQuests();
    final TripSettings settings = await QuestStore.instance.loadSettings();
    if (!mounted) return; // The page may be closed while waiting
    setState(() {
      _quests = quests;
      _returnQuests = returnQuests;
      _settings = settings;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: ResponsiveLayout(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Quests',
                        style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: darkText),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _openTripSettings,
                      icon: const Icon(Icons.settings_outlined, size: 18),
                      label: const Text('My stay',
                          style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  '입국부터 귀국까지 · Your semester, step by step',
                  style: TextStyle(fontSize: 13, color: lightText),
                ),
                const SizedBox(height: 16),
                _buildTabToggle(),
                const SizedBox(height: 20),

                // Return tab content
                if (_showReturn) ...[
                  _buildDepartureCard(),
                  const SizedBox(height: 16),
                  if (_returnQuests.isEmpty) _buildReturnEmptyState(),
                  if (_returnQuests.isNotEmpty) _buildReturnQuests(), 
                  if (!_settings.hideReturnRecommendations &&
                      _returnRecommendations.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _buildRecommendations(
                      items: _returnRecommendations,
                      onHide: _hideReturnRecommendations,
                      onAdd: _addReturnQuest,
                      showPhase: true,
                    ),
                  ],
                ] else ...[
                  // Arrival tab content.
                  _buildArrivalSummary(),
                  const SizedBox(height: 16),
                  if (_quests.isEmpty) _buildEmptyState(),
                  if (_allDone) ...[
                    _buildAllDone(),
                    const SizedBox(height: 16),
                  ],
                  if (_quests.isNotEmpty) _buildMyQuests(),
                  if (!_settings.hideRecommendations &&
                      _recommendations.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _buildRecommendations(
                      items: _recommendations,
                      onHide: _hideRecommendations,
                      onAdd: _addQuest,
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  static const List<String> _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  /// Short date text like "Sep 1".
  String _formatDate(DateTime date) {
    return '${_months[date.month - 1]} ${date.day}';
  }

  /// Days left until departure, e.g. 24 for "D-24". Null if no date yet.
  int? get _daysUntilDeparture {
    final DateTime? departure = _settings.departureDate;
    if (departure == null) return null;
    final DateTime today = DateUtils.dateOnly(DateTime.now());
    return departure.difference(today).inDays;
  }

  /// Small white "n / m done" badge. Hidden when there are no quests.
  Widget _buildDoneBadge(List<Quest> quests) {
    if (quests.isEmpty) return const SizedBox.shrink();
    final int done = quests.where((Quest q) => q.done).length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$done / ${quests.length} done',
        style: const TextStyle(
            fontSize: 12, fontWeight: FontWeight.bold, color: primaryBlue),
      ),
    );
  }

  /// Blue card shared by both tabs when the date is set.
  /// Left: label, big number and date. Right: progress badge.
  Widget _buildSummaryCard({
    required String label, // e.g. "RETURN IN | 귀국까지"
    required String bigText, // e.g. "D-24" or "Day 23"
    required String dateText, // e.g. "Dec 20, 2026"
    required List<Quest> quests, // Used for the badge
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: primaryBlue,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white70),
                ),
              ),
              _buildDoneBadge(quests),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            bigText,
            style: const TextStyle(
                fontSize: 32, fontWeight: FontWeight.w800, color: Colors.white),
          ),
          Text(
            dateText,
            style: const TextStyle(fontSize: 12, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  /// Blue card shared by both tabs when the date is not set yet.
  Widget _buildNoDateCard({
    required String title,
    required String titleKo,
    required List<Quest> quests,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: primaryBlue,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white),
                ),
              ),
              _buildDoneBadge(quests),
            ],
          ),
          Text(
            titleKo,
            style: const TextStyle(fontSize: 13, color: Colors.white70),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _openTripSettings,
            icon: const Icon(Icons.settings_outlined, size: 18),
            label: const Text('Set up my stay'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  /// Blue card at the top of the Return tab.
  Widget _buildDepartureCard() {
    final DateTime? departure = _settings.departureDate;
    final int? days = _daysUntilDeparture;

    if (departure == null || days == null) {
      return _buildNoDateCard(
        title: 'Enter your return date.',
        titleKo: '귀국 날짜를 입력해 주세요',
        quests: _returnQuests,
      );
    }
    return _buildSummaryCard(
      label: 'RETURN IN | 귀국까지',
      bigText: days > 0 ? 'D-$days' : (days == 0 ? 'D-Day' : 'Back home'),
      dateText: '${_formatDate(departure)}, ${departure.year}',
      quests: _returnQuests,
    );
  }

  /// Blue card at the top of the Arrival tab.
  Widget _buildArrivalSummary() {
    final DateTime? arrival = _settings.arrivalDate;

    if (arrival == null) {
      return _buildNoDateCard(
        title: 'Add your arrival date.',
        titleKo: '입국 날짜를 입력해 주세요',
        quests: _quests,
      );
    }

    final DateTime today = DateUtils.dateOnly(DateTime.now());
    final int days = today.difference(arrival).inDays; // Negative before arrival
    final bool arrived = days >= 0;

    return _buildSummaryCard(
      label: arrived ? 'IN KOREA | 한국에서' : 'ARRIVING IN | 입국까지',
      bigText: arrived ? 'Day ${days + 1}' : 'D$days',
      dateText:
          '${arrived ? 'Arrived' : 'Arriving'} ${_formatDate(arrival)}, ${arrival.year}',
      quests: _quests,
    );
  }

  /// Shown when the user has no arrival quests yet.
  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderGray),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: softBlue,
              borderRadius: BorderRadius.circular(16),
            ),
            child:
                const Icon(Icons.flag_outlined, color: primaryBlue, size: 28),
          ),
          const SizedBox(height: 16),
          const Text(
            'Your first quest awaits',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.w800, color: darkText),
          ),
          const SizedBox(height: 4),
          const Text(
            '아직 만든 퀘스트가 없어요',
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.bold, color: darkText),
          ),
          const SizedBox(height: 8),
          const Text(
            'Choose what you want to do first in Korea.\n'
            '한국에서 시작할 나만의 목표를 정해보세요.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, height: 1.4, color: lightText),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _openCreateQuest,
              icon: const Icon(Icons.add),
              label: const Text(
                'Create a quest · 퀘스트 만들기',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Opens My stay and saves the new values.
  Future<void> _openTripSettings() async {
    final TripSettings? updated =
        await showTripSettingsSheet(context, _settings);
    if (updated == null) return; // Closed without saving
    setState(() => _settings = updated);
    await QuestStore.instance.saveSettings(updated);
  }

  /// Opens the "Create a quest" sheet and adds the new quest.
  /// All create buttons (empty state, list header, all done) call this.
  Future<void> _openCreateQuest() async {
    final Quest? created = await showQuestSheet(context);
    if (created == null) return; // Closed without saving
    await _addQuest(created);
  }

  /// Adds a quest to the Return list and saves it.
  Future<void> _addReturnQuest(Quest quest) async {
    setState(() {
      _returnQuests.add(quest);
    });
    await QuestStore.instance.saveReturnQuests(_returnQuests);
  }

  /// Opens the create sheet for a Return quest.
  /// [phase] picks a time group in advance (used by "+ Add" in a group).
  Future<void> _openCreateReturnQuest({String? phase}) async {
    final Quest? created =
        await showQuestSheet(context, isReturn: true, phase: phase);
    if (created == null) return; // Closed without saving
    await _addReturnQuest(created);
  }

  /// Shown when the user has no return quests yet.
  Widget _buildReturnEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderGray),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: softBlue,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.luggage_outlined,
                color: primaryBlue, size: 28),
          ),
          const SizedBox(height: 16),
          const Text(
            'Plan your way home',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.w800, color: darkText),
          ),
          const SizedBox(height: 4),
          const Text(
            '아직 만든 귀국 퀘스트가 없어요',
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.bold, color: darkText),
          ),
          const SizedBox(height: 8),
          const Text(
            'Sort tasks by when to do them, so nothing gets left behind.\n'
            '시기별로 나눠 두면 빠뜨리는 것 없이 꼼꼼하게 챙길 수 있어요.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, height: 1.4, color: lightText),
          ),
          const SizedBox(height: 16),
          // Small preview of the three time groups.
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 6,
            children: [
              for (final String p in returnPhases)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(phaseIcons[p], size: 16, color: primaryBlue),
                    const SizedBox(width: 4),
                    Text(
                      phaseTitles[p] ?? p,
                      style: const TextStyle(fontSize: 12, color: primaryBlue),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () => _openCreateReturnQuest(),
              icon: const Icon(Icons.add),
              label: const Text(
                'Create a return quest · 퀘스트 만들기',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Recommended quests that are not in the user's list yet.
  /// Adding one removes it from here automatically (no duplicates).
  List<Quest> get _recommendations {
    final Set<String> myIds = _quests.map((Quest q) => q.id).toSet();
    return recommendedArrivalQuests()
        .where((Quest q) => !myIds.contains(q.id))
        .toList();
  }

  /// Adds a quest to the user's list and saves it.
  Future<void> _addQuest(Quest quest) async {
    setState(() {
      _quests.add(quest);
    });
    await QuestStore.instance.saveQuests(_quests);
  }

  /// Hides the recommended quests box for good (saved in settings).
  Future<void> _hideRecommendations() async {
    setState(() {
      _settings.hideRecommendations = true;
    });
    await QuestStore.instance.saveSettings(_settings);
  }

  /// Recommended return quests that are not in the return list yet.
  List<Quest> get _returnRecommendations {
    final Set<String> myIds = _returnQuests.map((Quest q) => q.id).toSet();
    return recommendedReturnQuests()
        .where((Quest q) => !myIds.contains(q.id))
        .toList();
  }

  /// Hides the return recommendations box (separate from Arrival).
  Future<void> _hideReturnRecommendations() async {
    setState(() {
      _settings.hideReturnRecommendations = true;
    });
    await QuestStore.instance.saveSettings(_settings);
  }

  /// "Recommended quests" box with a close button.
  /// Used on both tabs: each tab passes its own list and actions.
  Widget _buildRecommendations({
    required List<Quest> items, // Quests to show
    required VoidCallback onHide, // What the close button does
    required void Function(Quest) onAdd, // What the "+" button does
    bool showPhase = false, // Show the time group tag (Return tab)
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Recommended quests · 추천으로 시작하기',
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.bold, color: darkText),
              ),
            ),
            IconButton(
              tooltip:
                  'Hide recommendations', // Shown when the mouse is over it
              icon: const Icon(Icons.close, size: 18, color: lightText),
              onPressed: onHide,
            ),
          ],
        ),
        for (final Quest quest in items) ...[
          // ③ The list passed in
          _buildRecommendationTile(quest, onAdd: onAdd, showPhase: showPhase),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  /// One recommended quest with a "+" button.
  Widget _buildRecommendationTile(
    Quest quest, {
    required void Function(Quest) onAdd,
    bool showPhase = false,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      decoration: BoxDecoration(
        color: softBlue,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(_iconFor(quest), color: primaryBlue, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  quest.title,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: darkText),
                ),
                Text(
                  quest.titleKo,
                  style: const TextStyle(fontSize: 12, color: lightText),
                ),
              ],
            ),
          ),
          if (showPhase)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                // English part only: "Last week · 마지막 주" -> "Last week"
                (phaseTitles[quest.phase] ?? '').split(' · ').first,
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: primaryBlue),
              ),
            ),
          IconButton(
            tooltip: 'Add to my quests',
            icon: const Icon(Icons.add_circle, color: primaryBlue),
            onPressed: () => onAdd(quest),
          ),
        ],
      ),
    );
  }

  /// True when there is at least one quest and every quest is done.
  bool get _allDone => _quests.isNotEmpty && _quests.every((Quest q) => q.done);

  /// Celebration card shown when every arrival quest is done.
  Widget _buildAllDone() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: softBlue,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primaryBlue.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Text('🎉', style: TextStyle(fontSize: 36)),
          const SizedBox(height: 8),
          const Text(
            'All arrival quests done!',
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.w800, color: darkText),
          ),
          const Text(
            '입국 퀘스트를 모두 끝냈어요',
            style: TextStyle(fontSize: 13, color: lightText),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _openCreateQuest,
            icon: const Icon(Icons.add),
            label: const Text('Go create more quests'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              foregroundColor: Colors.white,
              shape: const StadiumBorder(),
            ),
          ),
        ],
      ),
    );
  }

  /// Icon for a quest, looked up by its icon key.
  /// Falls back to the flag if the key is unknown.
  IconData _iconFor(Quest quest) {
    return questIcons[quest.iconKey] ?? Icons.flag_outlined;
  }

  /// The list (Arrival or Return) that holds this quest.
  List<Quest> _listOf(Quest quest) {
    return _returnQuests.contains(quest) ? _returnQuests : _quests;
  }

  /// Saves both quest lists.
  Future<void> _saveLists() async {
    await QuestStore.instance.saveQuests(_quests);
    await QuestStore.instance.saveReturnQuests(_returnQuests);
  }

  /// Marks a quest as done, or undoes it, then saves.
  Future<void> _toggleDone(Quest quest) async {
    setState(() {
      quest.done = !quest.done;
    });
    await _saveLists();
  }

  /// Asks "Delete this quest?" and removes it if the user agrees.
  /// A recommended quest comes back to the recommendations after deleting.
  Future<void> _deleteQuest(Quest quest) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Delete this quest?'),
        content: Text('"${quest.title}" will be removed from your list.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return; // Cancel, or tapped outside the popup

    setState(() {
      _listOf(quest).remove(quest);
    });
    await _saveLists();
  }

  /// Opens the same sheet filled with this quest, then saves the changes.
  Future<void> _editQuest(Quest quest) async {
    final List<Quest> list = _listOf(quest);
    final Quest? edited = await showQuestSheet(
      context,
      quest: quest,
      isReturn: list == _returnQuests,
    );
    if (edited == null) return; // Closed without saving

    setState(() {
      final int index = list.indexOf(quest);
      list[index] = edited; // Put the new one in the same place
    });
    await _saveLists();
  }

  /// Return quests grouped by time. Each group can fold and unfold.
  Widget _buildReturnQuests() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'My return quests · 내 귀국 퀘스트',
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.bold, color: darkText),
              ),
            ),
            TextButton.icon(
              onPressed: () => _openCreateReturnQuest(),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('New quest'),
            ),
          ],
        ),
        for (final String phase in returnPhases) _buildPhaseGroup(phase),
      ],
    );
  }

  /// One time group: a title you can tap to fold, then its quests.
  Widget _buildPhaseGroup(String phase) {
    final List<Quest> inGroup =
        _returnQuests.where((Quest q) => q.phase == phase).toList();

    // Unfinished first, finished at the bottom (same as Arrival).
    final List<Quest> notDone = inGroup.where((Quest q) => !q.done).toList();
    final List<Quest> done = inGroup.where((Quest q) => q.done).toList();
    final List<Quest> visible =
        _settings.hideCompleted ? notDone : [...notDone, ...done];

    final bool collapsed = _collapsedPhases.contains(phase);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Group title. Tap to fold or unfold.
        InkWell(
          onTap: () => setState(() {
            if (collapsed) {
              _collapsedPhases.remove(phase);
            } else {
              _collapsedPhases.add(phase);
            }
          }),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                Icon(phaseIcons[phase], size: 18, color: primaryBlue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    (phaseTitles[phase] ?? phase).toUpperCase(),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      color: lightText,
                    ),
                  ),
                ),
                Text(
                  '${inGroup.length}',
                  style: const TextStyle(fontSize: 12, color: lightText),
                ),
                const SizedBox(width: 4),
                Icon(
                  collapsed ? Icons.chevron_right : Icons.expand_more,
                  color: lightText,
                ),
              ],
            ),
          ),
        ),
        if (!collapsed) ...[
          // Empty group: a short line that opens the sheet with this group.
          if (inGroup.isEmpty)
            TextButton.icon(
              onPressed: () =>
                  _openCreateReturnQuest(phase: phase), 
              icon: const Icon(Icons.add, size: 16),
              label: const Text('No quests yet · Add'),
            ),
          for (final Quest quest in visible) ...[
            _buildMyQuestTile(quest),
            const SizedBox(height: 8),
          ],
        ],
      ],
    );
  }

  /// The user's own quest list, with a "New quest" button on top.
  Widget _buildMyQuests() {
    // Unfinished quests first, finished ones at the bottom.
    // Each group keeps the order the quests were added in.
    final List<Quest> notDone = _quests.where((Quest q) => !q.done).toList();
    final List<Quest> done = _quests.where((Quest q) => q.done).toList();

    // When "hide completed" is on, show only unfinished quests.
    final List<Quest> visible =
        _settings.hideCompleted ? notDone : [...notDone, ...done];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'My quests · 내 퀘스트',
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.bold, color: darkText),
              ),
            ),
            TextButton.icon(
              onPressed: _openCreateQuest,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('New quest'),
            ),
          ],
        ),
        for (final Quest quest in visible) ...[
          _buildMyQuestTile(quest),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  /// One quest: check circle, titles, and a Done or Undo button.
  Widget _buildMyQuestTile(Quest quest) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderGray),
      ),
      child: Row(
        children: [
          // Quest icon in a soft box. Turns into a blue check when done.
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: quest.done ? primaryBlue : softBlue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              quest.done ? Icons.check : _iconFor(quest),
              color: quest.done ? Colors.white : primaryBlue,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  quest.title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: quest.done ? lightText : darkText,
                  ),
                ),
                Text(
                  quest.titleKo,
                  style: const TextStyle(fontSize: 12, color: lightText),
                ),
              ],
            ),
          ),
          quest.done
              ? OutlinedButton.icon(
                  onPressed: () => _toggleDone(quest),
                  icon: const Icon(Icons.undo, size: 16),
                  label: const Text('Undo · 취소'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: lightText,
                    shape: const StadiumBorder(),
                  ),
                )
              : ElevatedButton(
                  onPressed: () => _toggleDone(quest),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,
                    shape: const StadiumBorder(),
                  ),
                  child: const Text('Done · 완료'),
                ),
          PopupMenuButton<String>(
            tooltip: 'More options',
            icon: const Icon(Icons.more_vert, color: lightText),
            onSelected: (String value) {
              if (value == 'edit') _editQuest(quest);
              if (value == 'delete') _deleteQuest(quest);
            },
            itemBuilder: (BuildContext context) => const [
              PopupMenuItem(value: 'edit', child: Text('Edit · 수정')),
              PopupMenuItem(value: 'delete', child: Text('Delete · 삭제')),
            ],
          ),
        ],
      ),
    );
  }

  /// Pill-shaped switch between the Arrival and Return tabs.
  Widget _buildTabToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: softBlue,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton(
              icon: Icons.flight_land,
              label: 'Arrival 입국',
              selected: !_showReturn,
              onTap: () => setState(() => _showReturn = false),
            ),
          ),
          Expanded(
            child: _buildTabButton(
              icon: Icons.flight_takeoff,
              label: 'Return 귀국',
              selected: _showReturn,
              onTap: () => setState(() => _showReturn = true),
            ),
          ),
        ],
      ),
    );
  }

  /// One side of the toggle. White and blue when selected.
  Widget _buildTabButton({
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: selected ? primaryBlue : lightText),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                color: selected ? primaryBlue : lightText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
