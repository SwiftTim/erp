// lib/features/messaging/school_calendar_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/messaging_models.dart';
import '../../data/models/user_model.dart';
import '../auth/auth_provider.dart';
import 'messaging_hub_provider.dart';

// A full calendar view page (standalone route)
class SchoolCalendarPage extends ConsumerWidget {
  const SchoolCalendarPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('School Calendar')),
      body: SchoolCalendarEmbeddedView(user: user),
    );
  }
}

// An embeddable calendar widget for the messaging hub tab
class SchoolCalendarEmbeddedView extends ConsumerStatefulWidget {
  final UserModel? user;
  const SchoolCalendarEmbeddedView({super.key, this.user});

  @override
  ConsumerState<SchoolCalendarEmbeddedView> createState() =>
      _SchoolCalendarEmbeddedViewState();
}

class _SchoolCalendarEmbeddedViewState
    extends ConsumerState<SchoolCalendarEmbeddedView> {
  // Which day is selected
  DateTime _selectedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final calState = ref.watch(calendarNotifier);
    if (calState.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final focusedMonth = calState.focusedMonth;
    final eventsForSelected =
        _getEventsForDay(calState.events, _selectedDay);
    final upcomingEvents = _getUpcomingEvents(calState.events);

    return RefreshIndicator(
      onRefresh: () => ref.read(calendarNotifier.notifier).reload(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Month navigation header
            _MonthHeader(
              month: focusedMonth,
              onPrev: () => ref
                  .read(calendarNotifier.notifier)
                  .setFocusedMonth(DateTime(
                      focusedMonth.year, focusedMonth.month - 1)),
              onNext: () => ref
                  .read(calendarNotifier.notifier)
                  .setFocusedMonth(DateTime(
                      focusedMonth.year, focusedMonth.month + 1)),
            ),

            // Calendar grid
            _CalendarGrid(
              focusedMonth: focusedMonth,
              events: calState.events,
              selectedDay: _selectedDay,
              onDayTap: (d) => setState(() => _selectedDay = d),
            ),

            const SizedBox(height: 8),
            const Divider(height: 1),

            // Selected day events
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(
                DateFormat('EEEE, dd MMMM yyyy').format(_selectedDay),
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
            if (eventsForSelected.isEmpty)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Text(
                  'No events on this day',
                  style: TextStyle(
                      color: Colors.grey.shade400, fontSize: 13),
                ),
              )
            else
              ...eventsForSelected
                  .map((e) => _EventListTile(event: e, canEdit: widget.user?.roleLevel != null && widget.user!.roleLevel <= AppConstants.roleDeputy)),

            const Divider(indent: 20, endIndent: 20),

            // Upcoming events section
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Row(
                children: [
                  const Icon(Icons.upcoming_outlined,
                      size: 18, color: AppTheme.primary),
                  const SizedBox(width: 8),
                  const Text('Upcoming Events',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                  const Spacer(),
                  Text('Next 60 days',
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade500)),
                ],
              ),
            ),
            if (upcomingEvents.isEmpty)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Text('No upcoming events',
                    style: TextStyle(color: Colors.grey.shade400)),
              )
            else
              ...upcomingEvents.map((e) => _EventListTile(
                  event: e,
                  canEdit: widget.user?.roleLevel != null && widget.user!.roleLevel <= AppConstants.roleDeputy)),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  List<CalendarEvent> _getEventsForDay(
      List<CalendarEvent> events, DateTime day) {
    final dayStart =
        DateTime(day.year, day.month, day.day).millisecondsSinceEpoch;
    final dayEnd =
        dayStart + const Duration(days: 1).inMilliseconds - 1;
    return events
        .where((e) => e.startDate <= dayEnd && e.endDate >= dayStart)
        .toList();
  }

  List<CalendarEvent> _getUpcomingEvents(List<CalendarEvent> events) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final in60days = DateTime.now()
        .add(const Duration(days: 60))
        .millisecondsSinceEpoch;
    return events
        .where((e) => e.startDate >= now && e.startDate <= in60days)
        .toList()
      ..sort((a, b) => a.startDate.compareTo(b.startDate));
  }
}

// ── Month Header ──────────────────────────────────────────────────────────────
class _MonthHeader extends StatelessWidget {
  final DateTime month;
  final VoidCallback onPrev, onNext;
  const _MonthHeader(
      {required this.month, required this.onPrev, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          IconButton(
              icon: const Icon(Icons.chevron_left_rounded),
              onPressed: onPrev),
          Expanded(
            child: Text(
              DateFormat('MMMM yyyy').format(month),
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 17),
            ),
          ),
          IconButton(
              icon: const Icon(Icons.chevron_right_rounded),
              onPressed: onNext),
        ],
      ),
    );
  }
}

// ── Calendar Grid ─────────────────────────────────────────────────────────────
class _CalendarGrid extends StatelessWidget {
  final DateTime focusedMonth;
  final List<CalendarEvent> events;
  final DateTime selectedDay;
  final ValueChanged<DateTime> onDayTap;

  const _CalendarGrid({
    required this.focusedMonth,
    required this.events,
    required this.selectedDay,
    required this.onDayTap,
  });

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(focusedMonth.year, focusedMonth.month, 1);
    final daysInMonth =
        DateTime(focusedMonth.year, focusedMonth.month + 1, 0).day;
    // 0=Monday, 6=Sunday — align to Mon start
    int startOffset = firstDay.weekday - 1; // Monday = 1 → offset 0

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          // Day-of-week headers
          Row(
            children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                .map((d) => Expanded(
                      child: Center(
                        child: Text(d,
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: d == 'Sun'
                                    ? Colors.red.shade300
                                    : Colors.grey.shade500)),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 4),
          // Days grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7, mainAxisSpacing: 4, crossAxisSpacing: 4),
            itemCount: startOffset + daysInMonth,
            itemBuilder: (context, i) {
              if (i < startOffset) return const SizedBox();
              final dayNum = i - startOffset + 1;
              final date = DateTime(
                  focusedMonth.year, focusedMonth.month, dayNum);
              final dayEvents = _eventsForDay(date);
              final isSelected = _isSameDay(date, selectedDay);
              final isToday = _isSameDay(date, DateTime.now());

              return GestureDetector(
                onTap: () => onDayTap(date),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primary
                        : isToday
                            ? AppTheme.primary.withOpacity(0.08)
                            : null,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$dayNum',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isToday || isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isSelected
                              ? Colors.white
                              : isToday
                                  ? AppTheme.primary
                                  : Colors.black87,
                        ),
                      ),
                      if (dayEvents.isNotEmpty)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: dayEvents
                              .take(3)
                              .map((e) => Container(
                                    width: 4,
                                    height: 4,
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 1),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? Colors.white.withOpacity(0.8)
                                          : _priorityColor(e.priority),
                                      shape: BoxShape.circle,
                                    ),
                                  ))
                              .toList(),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  List<CalendarEvent> _eventsForDay(DateTime day) {
    final dayStart =
        DateTime(day.year, day.month, day.day).millisecondsSinceEpoch;
    final dayEnd = dayStart + const Duration(days: 1).inMilliseconds - 1;
    return events
        .where((e) => e.startDate <= dayEnd && e.endDate >= dayStart)
        .toList();
  }

  Color _priorityColor(String priority) {
    switch (priority) {
      case 'urgent':
        return Colors.red;
      case 'important':
        return Colors.orange;
      default:
        return AppTheme.primary;
    }
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

// ── Event List Tile ───────────────────────────────────────────────────────────
class _EventListTile extends ConsumerWidget {
  final CalendarEvent event;
  final bool canEdit;
  const _EventListTile({required this.event, required this.canEdit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final daysUntil = Duration(
            milliseconds: event.startDate - now)
        .inDays;

    Color accentColor;
    if (daysUntil <= 2) {
      accentColor = Colors.red;
    } else if (daysUntil <= 7) {
      accentColor = Colors.orange;
    } else {
      accentColor = AppTheme.primary;
    }

    final startDt =
        DateTime.fromMillisecondsSinceEpoch(event.startDate);
    final endDt = DateTime.fromMillisecondsSinceEpoch(event.endDate);
    final sameDay = startDt.year == endDt.year &&
        startDt.month == endDt.month &&
        startDt.day == endDt.day;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Color strip
              Container(
                width: 4,
                height: 60,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(event.title,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14)),
                        ),
                        if (canEdit)
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert_rounded,
                                size: 18),
                            onSelected: (v) {
                              if (v == 'delete') {
                                ref
                                    .read(calendarNotifier.notifier)
                                    .deleteEvent(event);
                              }
                            },
                            itemBuilder: (_) => [
                              const PopupMenuItem(
                                  value: 'delete',
                                  child: Text('Delete Event')),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: accentColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(event.eventType,
                              style: TextStyle(
                                  fontSize: 10,
                                  color: accentColor,
                                  fontWeight: FontWeight.w600)),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(event.priority.toUpperCase(),
                              style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey.shade600)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined,
                            size: 12, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          sameDay
                              ? DateFormat('dd MMM yyyy').format(startDt)
                              : '${DateFormat('dd MMM').format(startDt)} – ${DateFormat('dd MMM yyyy').format(endDt)}',
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600),
                        ),
                        if (daysUntil >= 0 && daysUntil <= 14) ...[
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: accentColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              daysUntil == 0
                                  ? 'Today!'
                                  : daysUntil == 1
                                      ? 'Tomorrow'
                                      : 'In $daysUntil days',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: accentColor,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (event.description != null &&
                        event.description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(event.description!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              fontStyle: FontStyle.italic)),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
