import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_theme.dart';
import 'event_form_sheet.dart';
import 'me_models.dart';
import 'me_strings.dart';

// ================================================================
// 실제 Me 화면
// ME PAGE (bottom tab "Me · 나")
// ================================================================
//
//  ┌ Header ............ title + "edit your profile" button
//  ├ My calendar ....... _CalendarCard (swipe / < > months, tap a day,
//  │                     period bars, long-press a plan to delete it)
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
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Header(s: s),
                const SizedBox(height: 22),
                _SectionTitle(s.myCalendar),
                const SizedBox(height: 10),
                // Rebuilds when Notice Explained adds a deadline.
                ListenableBuilder(
                  listenable: eventStore,
                  builder: (context, _) => _CalendarCard(
                    s: s,
                    events: eventStore.events,
                    onAdd: eventStore.add,
                    onUpdate: eventStore.update,
                    onDelete: eventStore.remove,
                  ),
                ),
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
                  fontSize: 28,
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
//
// Each week row:  day numbers on top, then up to [_laneCount] event
// lanes, then a "+N more" line.
//  - A period (start ~ end) is one blue bar that runs from its start day
//    to its end day; it is cut into one piece per week row.
//  - A one-day plan is a blue dot + its title.
// Tap a day   -> its plans are listed (titles) under the calendar;
//                tap a title for details, ✏️ to edit it.
// Long-press  -> a bar in the grid or a plan below -> delete.
// "Add plan"  -> the user adds a plan of their own (event_form_sheet.dart).
// ================================================================

class _CalendarCard extends StatefulWidget {
  final MeStrings s;
  final List<ScheduleEvent> events;
  final bool Function(ScheduleEvent) onAdd;
  final bool Function(ScheduleEvent oldEvent, ScheduleEvent newEvent) onUpdate;
  final bool Function(ScheduleEvent) onDelete;

  const _CalendarCard({
    required this.s,
    required this.events,
    required this.onAdd,
    required this.onUpdate,
    required this.onDelete,
  });

  @override
  State<_CalendarCard> createState() => _CalendarCardState();
}

/// One piece of an event inside one week row.
class _Segment {
  final ScheduleEvent event;
  final int startCol;
  final int endCol;
  final int lane;

  /// The event goes on before / after this week row (flat edge, no gap).
  final bool continuesLeft;
  final bool continuesRight;

  const _Segment({
    required this.event,
    required this.startCol,
    required this.endCol,
    required this.lane,
    required this.continuesLeft,
    required this.continuesRight,
  });

  bool covers(int col) => col >= startCol && col <= endCol;
}

class _CalendarCardState extends State<_CalendarCard> {
  // PageView pages are months. Page [_initialPage] = the current month,
  // so the user can swipe far into the past and the future.
  static const int _initialPage = 1200;

  // Week row layout (see the comment at the top of this section).
  static const double _numberArea = 28;
  static const int _laneCount = 2;
  static const double _laneHeight = 17;
  static const double _barHeight = 15;
  static const double _moreHeight = 14;
  static const double _rowHeight =
      _numberArea + _laneCount * _laneHeight + _moreHeight + 4;

  late final DateTime _baseMonth;
  late final PageController _pageController;
  late DateTime _visibleMonth;
  late DateTime _selectedDay;

  /// Plans whose details are open under the calendar (see [_keyOf]).
  final Set<String> _expanded = {};

  String _keyOf(ScheduleEvent e) => '${e.titleEn}|${e.dateTime}';

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
  int _leadingDays(DateTime month) =>
      DateTime(month.year, month.month, 1).weekday % 7;

  int _rowCount(DateTime month) {
    final int daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    return ((_leadingDays(month) + daysInMonth) / 7).ceil();
  }

  /// Plans that include [day], earliest first.
  List<ScheduleEvent> _eventsOn(DateTime day) {
    final List<ScheduleEvent> list =
        widget.events.where((e) => e.occursOn(day)).toList();
    list.sort((a, b) {
      final int byStart = a.startDay.compareTo(b.startDay);
      return byStart != 0 ? byStart : a.dateTime.compareTo(b.dateTime);
    });
    return list;
  }

  /// Puts the plans of one week into lanes so bars never overlap.
  /// Longer periods go first so they stay on the top lanes.
  List<_Segment> _layoutWeek(DateTime weekStart) {
    final DateTime weekEnd =
        DateTime(weekStart.year, weekStart.month, weekStart.day + 6);
    final List<ScheduleEvent> events = widget.events
        .where((e) => !e.endDay.isBefore(weekStart) && !e.startDay.isAfter(weekEnd))
        .toList()
      ..sort((a, b) {
        final int byStart = a.startDay.compareTo(b.startDay);
        if (byStart != 0) return byStart;
        final int byLength = daysBetween(b.startDay, b.endDay)
            .compareTo(daysBetween(a.startDay, a.endDay));
        if (byLength != 0) return byLength;
        return a.dateTime.compareTo(b.dateTime);
      });

    final List<int> laneEnds = []; // last column used in each lane
    final List<_Segment> segments = [];
    for (final ScheduleEvent e in events) {
      final int fromStart = daysBetween(weekStart, e.startDay);
      final int fromEnd = daysBetween(weekStart, e.endDay);
      final int startCol = fromStart < 0 ? 0 : fromStart;
      final int endCol = fromEnd > 6 ? 6 : fromEnd;

      int lane = laneEnds.indexWhere((int end) => end < startCol);
      if (lane == -1) {
        lane = laneEnds.length;
        laneEnds.add(endCol);
      } else {
        laneEnds[lane] = endCol;
      }

      segments.add(_Segment(
        event: e,
        startCol: startCol,
        endCol: endCol,
        lane: lane,
        continuesLeft: fromStart < 0,
        continuesRight: fromEnd > 6,
      ));
    }
    return segments;
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

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _addEvent() async {
    final MeStrings s = widget.s;
    final ScheduleEvent? e =
        await showEventFormSheet(context, s: s, day: _selectedDay);
    if (e == null || !mounted) return;
    if (!widget.onAdd(e)) {
      _showSnack(s.duplicatePlan);
      return;
    }
    // Jump to the new plan's first day and open its details.
    setState(() {
      _selectedDay = e.startDay;
      _expanded.add(_keyOf(e));
    });
    if (e.startDay.month != _visibleMonth.month ||
        e.startDay.year != _visibleMonth.year) {
      _goToMonth(DateTime(e.startDay.year, e.startDay.month));
    }
    _showSnack(s.planAdded);
  }

  Future<void> _editEvent(ScheduleEvent old) async {
    final MeStrings s = widget.s;
    final ScheduleEvent? e =
        await showEventFormSheet(context, s: s, initial: old);
    if (e == null || !mounted) return;
    if (!widget.onUpdate(old, e)) {
      _showSnack(s.duplicatePlan);
      return;
    }
    // Keep the details open, and follow the plan if its dates moved away
    // from the selected day.
    final bool moved = !e.occursOn(_selectedDay);
    setState(() {
      if (_expanded.remove(_keyOf(old))) _expanded.add(_keyOf(e));
      if (moved) _selectedDay = e.startDay;
    });
    if (moved &&
        (e.startDay.month != _visibleMonth.month ||
            e.startDay.year != _visibleMonth.year)) {
      _goToMonth(DateTime(e.startDay.year, e.startDay.month));
    }
    _showSnack(s.planUpdated);
  }

  Future<void> _confirmDelete(ScheduleEvent e) async {
    final MeStrings s = widget.s;
    HapticFeedback.mediumImpact();

    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: Text(
          s.deleteTitle,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        content: Text(
          s.pick(e.titleEn, e.titleKo),
          style: const TextStyle(fontSize: 14, color: darkText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(s.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red.shade700),
            child: Text(s.delete),
          ),
        ],
      ),
    );

    if (ok != true || !mounted) return;
    if (widget.onDelete(e)) _showSnack(s.deleted);
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
              // While the height animates between 5- and 6-week months a
              // page can be taller than the box: clip it instead of
              // showing an overflow error.
              itemBuilder: (_, int page) => SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: _buildMonthGrid(_monthForPage(page)),
              ),
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

    return Column(
      children: List<Widget>.generate(rows, (int row) {
        // DateTime normalises day 0 / negative days into the previous
        // month, and overflow into the next month.
        final DateTime weekStart =
            DateTime(month.year, month.month, 1 - leading + row * 7);
        return _buildWeekRow(month, weekStart);
      }),
    );
  }

  Widget _buildWeekRow(DateTime month, DateTime weekStart) {
    final DateTime today = DateTime.now();
    final List<_Segment> segments = _layoutWeek(weekStart);
    DateTime dayAt(int col) =>
        DateTime(weekStart.year, weekStart.month, weekStart.day + col);

    // Plans that did not fit in the lanes, per day.
    final List<int> hidden = List<int>.generate(
      7,
      (int col) => segments
          .where((seg) => seg.lane >= _laneCount && seg.covers(col))
          .length,
    );

    return SizedBox(
      height: _rowHeight,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints c) {
          final double cellWidth = c.maxWidth / 7;
          int colAt(double dx) => (dx ~/ cellWidth).clamp(0, 6);

          _Segment? segmentAt(Offset p) {
            final double y = p.dy - _numberArea;
            if (y < 0) return null;
            final int lane = y ~/ _laneHeight;
            if (lane >= _laneCount) return null;
            final int col = colAt(p.dx);
            for (final _Segment seg in segments) {
              if (seg.lane == lane && seg.covers(col)) return seg;
            }
            return null;
          }

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (TapUpDetails d) => _onDayTap(dayAt(colAt(d.localPosition.dx))),
            onLongPressStart: (LongPressStartDetails d) {
              final _Segment? seg = segmentAt(d.localPosition);
              if (seg != null) _confirmDelete(seg.event);
            },
            child: Stack(
              children: [
                // Day numbers.
                Row(
                  children: List<Widget>.generate(7, (int col) {
                    final DateTime day = dayAt(col);
                    return Expanded(
                      child: _DayNumber(
                        day: day,
                        height: _numberArea,
                        inMonth: day.month == month.month,
                        selected: isSameDay(day, _selectedDay),
                        isToday: isSameDay(day, today),
                      ),
                    );
                  }),
                ),
                // Event bars / one-day plans.
                for (final _Segment seg in segments)
                  if (seg.lane < _laneCount)
                    Positioned(
                      left: seg.startCol * cellWidth +
                          (seg.continuesLeft ? 0 : 2),
                      width: (seg.endCol - seg.startCol + 1) * cellWidth -
                          (seg.continuesLeft ? 0 : 2) -
                          (seg.continuesRight ? 0 : 2),
                      top: _numberArea + seg.lane * _laneHeight,
                      height: _barHeight,
                      child: _EventBar(
                        title: widget.s.isEnglish
                            ? seg.event.titleEn
                            : seg.event.titleKo,
                        isRange: seg.event.isRange,
                        roundLeft: !seg.continuesLeft,
                        roundRight: !seg.continuesRight,
                      ),
                    ),
                // "+N more"
                for (int col = 0; col < 7; col++)
                  if (hidden[col] > 0)
                    Positioned(
                      left: col * cellWidth + 3,
                      width: cellWidth - 3,
                      top: _numberArea + _laneCount * _laneHeight,
                      height: _moreHeight,
                      child: Text(
                        widget.s.moreEvents(hidden[col]),
                        maxLines: 1,
                        overflow: TextOverflow.clip,
                        softWrap: false,
                        style: const TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: lightText,
                        ),
                      ),
                    ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Under the calendar: the selected day's plans as titles only.
  /// Tap a title -> its details open below it. ✏️ -> edit.
  /// Long-press -> delete. The button at the bottom adds a plan.
  Widget _buildEventPanel(MeStrings s) {
    final List<ScheduleEvent> events = _eventsOn(_selectedDay);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (events.isEmpty)
          Container(
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
          )
        else ...[
          for (final ScheduleEvent e in events)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _EventTile(
                s: s,
                event: e,
                expanded: _expanded.contains(_keyOf(e)),
                onToggle: () => setState(() {
                  final String k = _keyOf(e);
                  if (!_expanded.remove(k)) _expanded.add(k);
                }),
                onEdit: () => _editEvent(e),
                onLongPress: () => _confirmDelete(e),
              ),
            ),
          Text(
            s.calendarHint,
            style: const TextStyle(fontSize: 10.5, color: lightText),
          ),
        ],
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 42,
          child: OutlinedButton.icon(
            onPressed: _addEvent,
            icon: const Icon(Icons.add, size: 18),
            label: Text(
              s.addPlan,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: primaryBlue,
              side: const BorderSide(color: primaryBlue),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// One plan under the calendar: title row (tap = open/close, ✏️ = edit),
/// and when open: time, "what do I do?" steps, memo, source.
class _EventTile extends StatelessWidget {
  final MeStrings s;
  final ScheduleEvent event;
  final bool expanded;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onLongPress;

  const _EventTile({
    required this.s,
    required this.event,
    required this.expanded,
    required this.onToggle,
    required this.onEdit,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final ScheduleEvent e = event;

    return Material(
      color: softBlue,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onToggle,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    e.isRange
                        ? Icons.date_range_outlined
                        : Icons.calendar_today_outlined,
                    size: 15,
                    color: primaryBlue,
                  ),
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
                  Icon(
                    expanded ? Icons.expand_less : Icons.expand_more,
                    size: 20,
                    color: lightText,
                  ),
                  IconButton(
                    onPressed: onEdit,
                    tooltip: s.editPlan,
                    icon: const Icon(Icons.edit_outlined,
                        size: 18, color: primaryBlue),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              if (expanded)
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 0, 8, 10),
                  child: _details(e),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _details(ScheduleEvent e) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          e.startDateTime != null && e.startDateTime != e.dateTime
              ? s.eventPeriod(e.startDateTime!, e.dateTime)
              : s.eventTime(e.dateTime),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: primaryBlue,
          ),
        ),
        // "SO, WHAT DO I DO?" steps from Notice Explained.
        if (e.steps.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            s.whatToDo,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: lightText,
            ),
          ),
          const SizedBox(height: 6),
          for (int i = 0; i < e.steps.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 18,
                    height: 18,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: primaryBlue,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${i + 1}',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      e.steps[i],
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        color: darkText,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
        if (e.description != null) ...[
          const SizedBox(height: 8),
          Text(
            e.description!,
            style: const TextStyle(fontSize: 12, height: 1.4, color: darkText),
          ),
        ],
        const SizedBox(height: 6),
        Text(
          s.pick(e.sourceEn, e.sourceKo),
          style: const TextStyle(fontSize: 10.5, color: lightText),
        ),
      ],
    );
  }
}

class _DayNumber extends StatelessWidget {
  final DateTime day;
  final double height;
  final bool inMonth;
  final bool selected;
  final bool isToday;

  const _DayNumber({
    required this.day,
    required this.height,
    required this.inMonth,
    required this.selected,
    required this.isToday,
  });

  @override
  Widget build(BuildContext context) {
    Color textColor = inMonth ? darkText : const Color(0xFFBBBBBB);
    if (isToday && !selected) textColor = primaryBlue;
    if (selected) textColor = Colors.white;

    return SizedBox(
      height: height,
      child: Center(
        child: Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? primaryBlue : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: Text(
            '${day.day}',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight:
                  selected || isToday ? FontWeight.w800 : FontWeight.w500,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }
}

/// A period = filled blue bar. A one-day plan = blue dot + title.
class _EventBar extends StatelessWidget {
  final String title;
  final bool isRange;
  final bool roundLeft;
  final bool roundRight;

  const _EventBar({
    required this.title,
    required this.isRange,
    required this.roundLeft,
    required this.roundRight,
  });

  @override
  Widget build(BuildContext context) {
    final Text label = Text(
      title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      softWrap: false,
      style: TextStyle(
        fontSize: 9.5,
        height: 1.2,
        fontWeight: FontWeight.w700,
        color: isRange ? Colors.white : darkText,
      ),
    );

    if (!isRange) {
      return Row(
        children: [
          Container(
            width: 5,
            height: 5,
            margin: const EdgeInsets.only(left: 1, right: 3),
            decoration: const BoxDecoration(
              color: primaryBlue,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(child: label),
        ],
      );
    }

    const Radius r = Radius.circular(4);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: primaryBlue,
        borderRadius: BorderRadius.horizontal(
          left: roundLeft ? r : Radius.zero,
          right: roundRight ? r : Radius.zero,
        ),
      ),
      child: label,
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
          itemBuilder: (_, int i) =>
              _JourneyCard(s: s, journey: sampleJourneys[i]),
        ),
      ),
    );
  }
}
