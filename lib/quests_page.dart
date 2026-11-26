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
  TripSettings _settings = TripSettings();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// Reads quests and settings from the store, then redraws the page.
  Future<void> _loadData() async {
    final List<Quest> quests = await QuestStore.instance.loadQuests();
    final TripSettings settings = await QuestStore.instance.loadSettings();
    if (!mounted) return; // The page may be closed while waiting
    setState(() {
      _quests = quests;
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
                      label: const Text('Trip settings',
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
                  const SizedBox(height: 30),
                  const Text('Pack your suitcase',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: darkText)),
                  const SizedBox(height: 8),
                  const Text('(목표: 4/4) Collect 4 essential items',
                      style: TextStyle(fontSize: 13, color: lightText)),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSuitcaseItem(Icons.sim_card, 'SIM'),
                      _buildSuitcaseItem(Icons.credit_card, 'Bank card'),
                      _buildSuitcaseItem(Icons.money, 'Cash'),
                      _buildSuitcaseItem(Icons.badge, 'ARC'),
                    ],
                  ),
                  const SizedBox(height: 30),
                  _buildQuestTile(
                      Icons.phone_iphone, 'Carpool phone plan', '통신사 요금제'),
                  const SizedBox(height: 12),
                  _buildQuestTile(Icons.account_balance, 'Clone bank account',
                      '은행 계좌 개설하기'),
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
                    _buildRecommendations(),
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

  /// Text under the blue card for the arrival date.
  /// After arrival: "Arrived Nov 4 · Day 23 in Korea".
  /// Before arrival: "Arriving Dec 20 · D-24".
  String _arrivalText(DateTime arrival) {
    final DateTime today = DateUtils.dateOnly(DateTime.now());
    final int days =
        today.difference(arrival).inDays; // Negative before arrival

    if (days < 0) {
      return 'Arriving ${_formatDate(arrival)} · D$days'; // e.g. "D-24"
    }
    return 'Arrived ${_formatDate(arrival)} · Day ${days + 1} in Korea';
  }

  /// Days left until departure, e.g. 24 for "D-24". Null if no date yet.
  int? get _daysUntilDeparture {
    final DateTime? departure = _settings.departureDate;
    if (departure == null) return null;
    final DateTime today = DateUtils.dateOnly(DateTime.now());
    return departure.difference(today).inDays;
  }

  /// Top card of the Return tab: D-day, or a prompt to set the return date.
  Widget _buildDepartureCard() {
    final DateTime? departure = _settings.departureDate;
    final int? days = _daysUntilDeparture;

    if (departure == null || days == null) {
      // No return date yet: ask the user to set it.
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: softBlue,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter your return date.',
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w800, color: darkText),
            ),
            const Text(
              '귀국 날짜를 입력해 주세요',
              style: TextStyle(fontSize: 13, color: lightText),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _openTripSettings,
              icon: const Icon(Icons.settings_outlined, size: 18),
              label: const Text('Open Trip settings'),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: softBlue,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'DEPARTURE IN | 출국까지',
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.bold, color: primaryBlue),
          ),
          const SizedBox(height: 4),
          Text(
            days > 0 ? 'D-$days' : (days == 0 ? 'D-Day' : 'Departed'),
            style: const TextStyle(
                fontSize: 32, fontWeight: FontWeight.w800, color: darkText),
          ),
          Text(
            '${_formatDate(departure)}, ${departure.year}',
            style: const TextStyle(fontSize: 12, color: lightText),
          ),
        ],
      ),
    );
  }

  /// Blue summary card at the top of the Arrival tab.
  Widget _buildArrivalSummary() {
    final int total = _quests.length;
    final int done = _quests.where((Quest q) => q.done).length;
    final DateTime? arrival = _settings.arrivalDate;

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
              Text(
                total == 0 ? '0' : '$done / $total',
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      total == 0
                          ? 'arrival quests created'
                          : 'arrival quests done',
                      style: const TextStyle(fontSize: 14, color: Colors.white),
                    ),
                    Text(
                      total == 0 ? '생성한 입국 퀘스트' : '완료한 입국 퀘스트',
                      style:
                          const TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (total == 0)
            const Text(
              'Your journey starts with your first quest.',
              style: TextStyle(fontSize: 13, color: Colors.white),
            ),
          Text(
            arrival == null
                ? 'Add your arrival date in Trip settings'
                : _arrivalText(arrival),
            style: const TextStyle(fontSize: 12, color: Colors.white70),
          ),
        ],
      ),
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

  /// Opens Trip settings and saves the new values.
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

  /// "Recommended quests" box with a close button.
  Widget _buildRecommendations() {
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
              onPressed: _hideRecommendations,
            ),
          ],
        ),
        for (final Quest quest in _recommendations) ...[
          _buildRecommendationTile(quest),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  /// One recommended quest with a "+" button.
  Widget _buildRecommendationTile(Quest quest) {
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
          IconButton(
            tooltip: 'Add to my quests',
            icon: const Icon(Icons.add_circle, color: primaryBlue),
            onPressed: () => _addQuest(quest),
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

  /// Marks a quest as done, or undoes it, then saves.
  Future<void> _toggleDone(Quest quest) async {
    setState(() {
      quest.done = !quest.done;
    });
    await QuestStore.instance.saveQuests(_quests);
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
      _quests.remove(quest);
    });
    await QuestStore.instance.saveQuests(_quests);
  }

  /// Opens the same sheet filled with this quest, then saves the changes.
  Future<void> _editQuest(Quest quest) async {
    final Quest? edited = await showQuestSheet(context, quest: quest);
    if (edited == null) return; // Closed without saving

    setState(() {
      final int index = _quests.indexOf(quest);
      _quests[index] = edited; // Put the new one in the same place
    });
    await QuestStore.instance.saveQuests(_quests);
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

  Widget _buildSuitcaseItem(IconData icon, String label) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: borderGray),
          ),
          child: Icon(icon, color: primaryBlue, size: 28),
        ),
        const SizedBox(height: 8),
        Text(label,
            style: const TextStyle(
                fontSize: 12, color: darkText, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildQuestTile(IconData icon, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderGray),
      ),
      child: Row(
        children: [
          Icon(icon, color: primaryBlue, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: darkText)),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: const TextStyle(fontSize: 12, color: lightText)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: lightText),
        ],
      ),
    );
  }
}
