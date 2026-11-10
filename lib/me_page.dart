import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'me_models.dart';
import 'me_strings.dart';

// ================================================================
// 실제 Me 화면
// ME PAGE (bottom tab "Me · 나")
// ================================================================
//
//  ┌ Header ............ title + "edit your profile" button
//  ├ My calendar ....... _CalendarCard (swipe / < > months, tap a day)
//  └ Saved journeys .... _JourneyCard + "View saved journeys" button
// ================================================================

class MePage extends StatelessWidget {
  final AppLanguage language;

  const MePage({super.key, required this.language});

  @override
  Widget build(BuildContext context) {
    final MeStrings s = MeStrings(language);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: ResponsiveLayout(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Header(s: s),
                const SizedBox(height: 22),
                _SectionTitle(s.myCalendar),
                const SizedBox(height: 10),
                _CalendarCard(s: s, events: buildSampleEvents()),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(child: _SectionTitle(s.savedJourneys)),
                    Text(
                      s.journeyCount(sampleJourneys.length),
                      style: const TextStyle(fontSize: 12, color: lightText),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                for (final SavedJourney j in sampleJourneys) ...[
                  _JourneyCard(s: s, journey: j),
                  const SizedBox(height: 10),
                ],
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => SavedJourneysPage(language: language),
                      ),
                    ),
                    icon: const Icon(Icons.favorite_border, size: 18),
                    label: Text(
                      s.viewSavedJourneys,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ================================================================
// HEADER
// ================================================================

class _Header extends StatelessWidget {
  final MeStrings s;

  const _Header({required this.s});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                s.title,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: darkText,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                s.subtitle,
                style: const TextStyle(fontSize: 13, color: lightText),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          // The profile screen is not built yet: the button is clickable
          // and only shows a message for now.
          onPressed: () {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(s.profileComingSoon)));
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryBlue,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: Text(
            s.editProfile,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w800,
        color: darkText,
      ),
    );
  }
}

/// White rounded card with a light border, shared by calendar and journeys.
class _WhiteCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _WhiteCard({
    required this.child,
    this.padding = const EdgeInsets.all(14),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderGray),
      ),
      child: child,
    );
  }
}

// ================================================================
// CALENDAR
// ================================================================

class _CalendarCard extends StatefulWidget {
  final MeStrings s;
  final List<ScheduleEvent> events;

  const _CalendarCard({required this.s, required this.events});

  @override
  State<_CalendarCard> createState() => _CalendarCardState();
}

class _CalendarCardState extends State<_CalendarCard> {
  // PageView pages are months. Page [_initialPage] = the current month,
  // so the user can swipe far into the past and the future.
  static const int _initialPage = 1200;
  static const double _rowHeight = 40;

  late final DateTime _baseMonth;
  late final PageController _pageController;
  late DateTime _visibleMonth;
  late DateTime _selectedDay;

  @override
  void initState() {
    super.initState();
    final DateTime now = DateTime.now();
    _baseMonth = DateTime(now.year, now.month);
    _visibleMonth = _baseMonth;
    _selectedDay = DateTime(now.year, now.month, now.day);
    _pageController = PageController(initialPage: _initialPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  DateTime _monthForPage(int page) =>
      DateTime(_baseMonth.year, _baseMonth.month + (page - _initialPage));

  int _pageForMonth(DateTime month) =>
      _initialPage +
      (month.year - _baseMonth.year) * 12 +
      (month.month - _baseMonth.month);

  /// Sunday-first: how many days of the previous month are shown first.
  int _leadingDays(DateTime month) => DateTime(month.year, month.month, 1).weekday % 7;

  int _rowCount(DateTime month) {
    final int daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    return ((_leadingDays(month) + daysInMonth) / 7).ceil();
  }

  List<ScheduleEvent> _eventsOn(DateTime day) {
    final List<ScheduleEvent> list =
        widget.events.where((e) => isSameDay(e.dateTime, day)).toList();
    list.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    return list;
  }

  void _goToMonth(DateTime month) {
    _pageController.animateToPage(
      _pageForMonth(month),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _onDayTap(DateTime day) {
    setState(() => _selectedDay = day);
    // Tapping a grey day of the previous/next month moves to that month.
    if (day.month != _visibleMonth.month || day.year != _visibleMonth.year) {
      _goToMonth(DateTime(day.year, day.month));
    }
  }

  @override
  Widget build(BuildContext context) {
    final MeStrings s = widget.s;

    return _WhiteCard(
      child: Column(
        children: [
          _buildMonthHeader(s),
          const SizedBox(height: 10),
          _buildWeekdayRow(s),
          const SizedBox(height: 4),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: _rowCount(_visibleMonth) * _rowHeight,
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (int page) =>
                  setState(() => _visibleMonth = _monthForPage(page)),
              itemBuilder: (_, int page) => _buildMonthGrid(_monthForPage(page)),
            ),
          ),
          const SizedBox(height: 10),
          _buildEventPanel(s),
        ],
      ),
    );
  }

  Widget _buildMonthHeader(MeStrings s) {
    final String? hint = s.monthHint(_visibleMonth);
    return Row(
      children: [
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: s.monthTitle(_visibleMonth),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: darkText,
                  ),
                ),
                if (hint != null)
                  TextSpan(
                    text: '  $hint',
                    style: const TextStyle(fontSize: 12, color: lightText),
                  ),
              ],
            ),
          ),
        ),
        _arrowButton(Icons.chevron_left, () {
          _pageController.previousPage(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }),
        _arrowButton(Icons.chevron_right, () {
          _pageController.nextPage(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }),
      ],
    );
  }

  Widget _arrowButton(IconData icon, VoidCallback onPressed) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon, size: 22, color: darkText),
      visualDensity: VisualDensity.compact,
      splashRadius: 18,
    );
  }

  Widget _buildWeekdayRow(MeStrings s) {
    return Row(
      children: s.weekdayHeaders
          .map(
            (String d) => Expanded(
              child: Center(
                child: Text(
                  d,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: lightText,
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildMonthGrid(DateTime month) {
    final int leading = _leadingDays(month);
    final int rows = _rowCount(month);
    final DateTime today = DateTime.now();

    return Column(
      children: List<Widget>.generate(rows, (int row) {
        return SizedBox(
          height: _rowHeight,
          child: Row(
            children: List<Widget>.generate(7, (int col) {
              // DateTime normalises day 0 / negative days into the
              // previous month, and overflow into the next month.
              final DateTime day =
                  DateTime(month.year, month.month, 1 - leading + row * 7 + col);
              return Expanded(
                child: _DayCell(
                  day: day,
                  inMonth: day.month == month.month,
                  selected: isSameDay(day, _selectedDay),
                  isToday: isSameDay(day, today),
                  hasEvent: _eventsOn(day).isNotEmpty,
                  onTap: () => _onDayTap(day),
                ),
              );
            }),
          ),
        );
      }),
    );
  }

  Widget _buildEventPanel(MeStrings s) {
    final List<ScheduleEvent> events = _eventsOn(_selectedDay);

    if (events.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          s.noEvents,
          style: const TextStyle(fontSize: 12, color: lightText),
        ),
      );
    }

    return Column(
      children: [
        for (final ScheduleEvent e in events)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: softBlue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        size: 15, color: primaryBlue),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        s.pick(e.titleEn, e.titleKo),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: darkText,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  s.eventTime(e.dateTime),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: primaryBlue,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  s.pick(e.sourceEn, e.sourceKo),
                  style: const TextStyle(fontSize: 10.5, color: lightText),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  final DateTime day;
  final bool inMonth;
  final bool selected;
  final bool isToday;
  final bool hasEvent;
  final VoidCallback onTap;

  const _DayCell({
    required this.day,
    required this.inMonth,
    required this.selected,
    required this.isToday,
    required this.hasEvent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color textColor = inMonth ? darkText : const Color(0xFFBBBBBB);
    if (isToday && !selected) textColor = primaryBlue;
    if (selected) textColor = Colors.white;

    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? primaryBlue : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Text(
              '${day.day}',
              style: TextStyle(
                fontSize: 13,
                fontWeight:
                    selected || isToday ? FontWeight.w800 : FontWeight.w500,
                color: textColor,
              ),
            ),
          ),
          // Small dot = this day has at least one event.
          Container(
            width: 4,
            height: 4,
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              color: hasEvent && !selected ? primaryBlue : Colors.transparent,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// SAVED JOURNEY CARD (layout only for now)
// ================================================================

class _JourneyCard extends StatelessWidget {
  final MeStrings s;
  final SavedJourney journey;

  const _JourneyCard({required this.s, required this.journey});

  @override
  Widget build(BuildContext context) {
    return _WhiteCard(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.isEnglish ? journey.titleEn : journey.titleKo,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: darkText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      s.pick(journey.subtitleEn, journey.subtitleKo),
                      style: const TextStyle(fontSize: 11.5, color: lightText),
                    ),
                  ],
                ),
              ),
              if (journey.completed)
                Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    color: softBlue,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, size: 16, color: primaryBlue),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _stat('${journey.daysInKorea}', s.statDaysEn, s.statDaysKo),
              _stat('${journey.questsDone}/${journey.questsTotal}',
                  s.statQuestsEn, s.statQuestsKo),
              _stat('${journey.itemsReturned}', s.statItemsEn, s.statItemsKo),
            ],
          ),
        ],
      ),
    );
  }

  /// English mode: value / English label / Korean label.
  /// Korean mode:  value / Korean label.
  Widget _stat(String value, String labelEn, String labelKo) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: primaryBlue,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            s.isEnglish ? labelEn : labelKo,
            style: const TextStyle(fontSize: 10.5, color: darkText),
          ),
          if (s.isEnglish)
            Text(
              labelKo,
              style: const TextStyle(fontSize: 9.5, color: lightText),
            ),
        ],
      ),
    );
  }
}

// ================================================================
// SAVED JOURNEYS DETAIL PAGE (layout only for now)
// ================================================================
//
// Later: user input + self-made quests will feed this page.
// ================================================================

class SavedJourneysPage extends StatelessWidget {
  final AppLanguage language;

  const SavedJourneysPage({super.key, required this.language});

  @override
  Widget build(BuildContext context) {
    final MeStrings s = MeStrings(language);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: Text(
          s.savedJourneys,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      body: ResponsiveLayout(
        child: ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: sampleJourneys.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, int i) => _JourneyCard(s: s, journey: sampleJourneys[i]),
        ),
      ),
    );
  }
}
