import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'quest_data.dart';
import 'quest_icons.dart';

/// Opens the sheet to create a new quest, or to edit [quest] if one is given.
/// Returns the saved quest, or null if the user closed the sheet.
Future<Quest?> showQuestSheet(BuildContext context, {Quest? quest}) {
  return showModalBottomSheet<Quest>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (BuildContext context) => _QuestSheet(quest: quest),
  );
}

class _QuestSheet extends StatefulWidget {
  final Quest? quest; // null = create a new quest

  const _QuestSheet({this.quest});

  @override
  State<_QuestSheet> createState() => _QuestSheetState();
}

class _QuestSheetState extends State<_QuestSheet> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _titleKoController = TextEditingController();
  String _iconKey = 'flag';
  String? _error; // Shown under the title box when it is empty

  bool get _isEditing => widget.quest != null;

  @override
  void initState() {
    super.initState();
    final Quest? quest = widget.quest;
    if (quest != null) {
      // Edit: start with the quest's current values.
      _titleController.text = quest.title;
      _titleKoController.text = quest.titleKo;
      _iconKey = quest.iconKey;
    }
  }

  @override
  void dispose() {
    // Free the text boxes when the sheet closes.
    _titleController.dispose();
    _titleKoController.dispose();
    super.dispose();
  }

  /// Checks the title, builds the quest and closes the sheet with it.
  void _save() {
    final String title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() => _error = 'Please enter a quest title');
      return;
    }

    final Quest? old = widget.quest;
    final Quest saved = Quest(
      // When editing, keep the same id and done state.
      id: old?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      titleKo: _titleKoController.text.trim(),
      iconKey: _iconKey,
      done: old?.done ?? false,
    );
    Navigator.of(context).pop(saved);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Extra bottom space so the keyboard does not cover the sheet.
      padding: EdgeInsets.fromLTRB(
        20, 0, 20, 20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isEditing ? 'Edit quest · 퀘스트 수정' : 'New quest · 새 퀘스트',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: darkText),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Title (English)',
                hintText: 'e.g. Get a T-money card',
                errorText: _error,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              // Hide the error as soon as the user starts typing.
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _titleKoController,
              decoration: InputDecoration(
                labelText: 'Title (Korean, optional)',
                hintText: '예: 교통카드 만들기',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Icon · 아이콘',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: darkText),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final String key in questIcons.keys) _buildIconChoice(key),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  _isEditing ? 'Save · 저장' : 'Add quest · 추가',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// One icon the user can pick. The picked one is blue.
  Widget _buildIconChoice(String key) {
    final bool selected = key == _iconKey;
    return GestureDetector(
      onTap: () => setState(() => _iconKey = key),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: selected ? primaryBlue : softBlue,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          questIcons[key],
          color: selected ? Colors.white : primaryBlue,
          size: 22,
        ),
      ),
    );
  }
}