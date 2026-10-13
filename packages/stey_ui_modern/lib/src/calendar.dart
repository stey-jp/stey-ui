import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'button.dart';
import 'display.dart';
import 'theme.dart';

enum SteyDateSelectionMode { single, multiple, range }

/// Inline native calendar corresponding to Kumo DatePicker's three modes.
class SteyDatePicker extends StatefulWidget {
  const SteyDatePicker({
    super.key,
    this.value,
    this.onChanged,
    this.selectedDates = const [],
    this.onDatesChanged,
    this.range,
    this.onRangeChanged,
    this.mode = SteyDateSelectionMode.single,
    required this.firstDate,
    required this.lastDate,
    this.initialMonth,
    this.numberOfMonths = 1,
    this.showOutsideDays = true,
    this.disabledDate,
    this.minSelections = 0,
    this.maxSelections,
    this.weekStartsOn = 0,
    this.label = 'Select date',
  }) : assert(numberOfMonths > 0),
       assert(weekStartsOn >= 0 && weekStartsOn < 7);
  final DateTime? value, initialMonth;
  final ValueChanged<DateTime>? onChanged;
  final List<DateTime> selectedDates;
  final ValueChanged<List<DateTime>>? onDatesChanged;
  final DateTimeRange? range;
  final ValueChanged<DateTimeRange>? onRangeChanged;
  final SteyDateSelectionMode mode;
  final DateTime firstDate, lastDate;
  final int numberOfMonths, minSelections, weekStartsOn;
  final int? maxSelections;
  final bool showOutsideDays;
  final bool Function(DateTime)? disabledDate;
  final String label;
  @override
  State<SteyDatePicker> createState() => _SteyDatePickerState();
}

class _SteyDatePickerState extends State<SteyDatePicker> {
  late DateTime month;
  DateTime? rangeStart;
  final Map<DateTime, FocusNode> focusNodes = {};
  @override
  void initState() {
    super.initState();
    final date =
        widget.initialMonth ??
        widget.value ??
        widget.range?.start ??
        DateTime.now();
    final start = DateUtils.dateOnly(widget.firstDate),
        end = DateUtils.dateOnly(widget.lastDate);
    final bounded = date.isBefore(start)
        ? start
        : date.isAfter(end)
        ? end
        : date;
    month = DateTime(bounded.year, bounded.month);
  }

  @override
  void dispose() {
    for (final node in focusNodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  bool disabled(DateTime date) =>
      date.isBefore(DateUtils.dateOnly(widget.firstDate)) ||
      date.isAfter(DateUtils.dateOnly(widget.lastDate)) ||
      (widget.disabledDate?.call(date) ?? false);
  bool same(DateTime? a, DateTime b) => a != null && DateUtils.isSameDay(a, b);
  bool selected(DateTime date) => switch (widget.mode) {
    SteyDateSelectionMode.single => same(widget.value, date),
    SteyDateSelectionMode.multiple => widget.selectedDates.any(
      (d) => same(d, date),
    ),
    SteyDateSelectionMode.range =>
      same(rangeStart, date) ||
          same(widget.range?.start, date) ||
          same(widget.range?.end, date),
  };
  void choose(DateTime date) {
    if (disabled(date)) return;
    switch (widget.mode) {
      case SteyDateSelectionMode.single:
        widget.onChanged?.call(date);
      case SteyDateSelectionMode.multiple:
        final exists = widget.selectedDates.any((d) => same(d, date));
        if (exists && widget.selectedDates.length <= widget.minSelections) {
          return;
        }
        if (!exists &&
            widget.maxSelections != null &&
            widget.selectedDates.length >= widget.maxSelections!) {
          return;
        }
        final dates = exists
            ? widget.selectedDates.where((d) => !same(d, date)).toList()
            : [...widget.selectedDates, date];
        dates.sort();
        widget.onDatesChanged?.call(dates);
      case SteyDateSelectionMode.range:
        if (rangeStart == null) {
          setState(() => rangeStart = date);
        } else {
          final start = date.isBefore(rangeStart!) ? date : rangeStart!,
              end = date.isBefore(rangeStart!) ? rangeStart! : date;
          final days = DateTime.utc(
            end.year,
            end.month,
            end.day,
          ).difference(DateTime.utc(start.year, start.month, start.day)).inDays;
          if (days < widget.minSelections ||
              widget.maxSelections != null && days > widget.maxSelections!) {
            return;
          }
          for (
            var d = start;
            !d.isAfter(end);
            d = DateTime(d.year, d.month, d.day + 1)
          ) {
            if (disabled(d)) return;
          }
          widget.onRangeChanged?.call(DateTimeRange(start: start, end: end));
          setState(() => rangeStart = null);
        }
    }
  }

  void shiftMonth(int delta) =>
      setState(() => month = DateTime(month.year, month.month + delta));
  bool get canPrevious => DateTime(
    month.year,
    month.month,
  ).isAfter(DateTime(widget.firstDate.year, widget.firstDate.month));
  bool get canNext => DateTime(
    month.year,
    month.month + widget.numberOfMonths - 1,
  ).isBefore(DateTime(widget.lastDate.year, widget.lastDate.month));
  KeyEventResult moveFocus(DateTime date, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    DateTime? target;
    if (key == LogicalKeyboardKey.arrowRight) {
      target = date.add(const Duration(days: 1));
    }
    if (key == LogicalKeyboardKey.arrowLeft) {
      target = date.subtract(const Duration(days: 1));
    }
    if (key == LogicalKeyboardKey.arrowDown) {
      target = date.add(const Duration(days: 7));
    }
    if (key == LogicalKeyboardKey.arrowUp) {
      target = date.subtract(const Duration(days: 7));
    }
    if (key == LogicalKeyboardKey.home) {
      target = date.subtract(
        Duration(days: ((date.weekday % 7) - widget.weekStartsOn + 7) % 7),
      );
    }
    if (key == LogicalKeyboardKey.end) {
      target = date.add(
        Duration(days: 6 - ((date.weekday % 7) - widget.weekStartsOn + 7) % 7),
      );
    }
    if (key == LogicalKeyboardKey.pageUp ||
        key == LogicalKeyboardKey.pageDown) {
      final delta = key == LogicalKeyboardKey.pageUp ? -1 : 1;
      final targetMonth = DateTime(date.year, date.month + delta);
      final maxDay = DateUtils.getDaysInMonth(
        targetMonth.year,
        targetMonth.month,
      );
      target = DateTime(
        date.year,
        date.month + delta,
        date.day > maxDay ? maxDay : date.day,
      );
    }
    if (target == null) return KeyEventResult.ignored;
    final candidate = target;
    if (disabled(candidate)) return KeyEventResult.handled;
    if (candidate.month != date.month) {
      setState(() => month = DateTime(candidate.year, candidate.month));
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) focusNodes[candidate]?.requestFocus();
    });
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final c = SteyTheme.colorsOf(context),
        locale = MaterialLocalizations.of(context);
    Widget calendar(DateTime current) {
      final offset = ((current.weekday % 7) - widget.weekStartsOn + 7) % 7;
      final start = current.subtract(Duration(days: offset));
      final count =
          ((offset + DateUtils.getDaysInMonth(current.year, current.month)) / 7)
              .ceil() *
          7;
      return SizedBox(
        width: 280,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 40,
              child: Row(
                children: [
                  SteyButton(
                    onPressed: canPrevious ? () => shiftMonth(-1) : null,
                    shape: SteyButtonShape.square,
                    size: SteySize.sm,
                    variant: SteyButtonVariant.outline,
                    semanticLabel: locale.previousMonthTooltip,
                    child: const Icon(Icons.chevron_left, size: 16),
                  ),
                  Expanded(
                    child: Center(
                      child: SteyText(
                        locale.formatMonthYear(current),
                        bold: true,
                      ),
                    ),
                  ),
                  SteyButton(
                    onPressed: canNext ? () => shiftMonth(1) : null,
                    shape: SteyButtonShape.square,
                    size: SteySize.sm,
                    variant: SteyButtonVariant.outline,
                    semanticLabel: locale.nextMonthTooltip,
                    child: const Icon(Icons.chevron_right, size: 16),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                for (var i = 0; i < 7; i++)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Center(
                        child: Text(
                          locale.narrowWeekdays[(widget.weekStartsOn + i) % 7],
                          style: TextStyle(fontSize: 12, color: c.subtle),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            for (var row = 0; row < count ~/ 7; row++)
              Row(
                children: [
                  for (var column = 0; column < 7; column++)
                    Builder(
                      builder: (context) {
                        final date = DateUtils.dateOnly(
                          start.add(Duration(days: row * 7 + column)),
                        );
                        final outside = date.month != current.month;
                        if (outside &&
                            (!widget.showOutsideDays ||
                                widget.numberOfMonths > 1)) {
                          return const Expanded(child: SizedBox(height: 36));
                        }
                        final active = selected(date),
                            within =
                                widget.mode == SteyDateSelectionMode.range &&
                                widget.range != null &&
                                date.isAfter(widget.range!.start) &&
                                date.isBefore(widget.range!.end);
                        final node = focusNodes.putIfAbsent(
                          date,
                          FocusNode.new,
                        );
                        return Expanded(
                          child: Container(
                            height: 36,
                            color: within ? c.fill : null,
                            padding: const EdgeInsets.all(2),
                            child: Focus(
                              onKeyEvent: (_, event) => moveFocus(date, event),
                              child: Semantics(
                                selected: active,
                                child: SteyButton(
                                  focusNode: node,
                                  onPressed: disabled(date)
                                      ? null
                                      : () => choose(date),
                                  semanticLabel: locale.formatFullDate(date),
                                  size: SteySize.base,
                                  shape: SteyButtonShape.square,
                                  variant: SteyButtonVariant.ghost,
                                  backgroundColor: active ? c.contrast : null,
                                  child: Text(
                                    '${date.day}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: active
                                          ? c.inverse
                                          : outside
                                          ? c.subtle
                                          : c.text,
                                      fontWeight: same(DateTime.now(), date)
                                          ? FontWeight.w500
                                          : FontWeight.w400,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
          ],
        ),
      );
    }

    return Semantics(
      label: widget.label,
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          for (var i = 0; i < widget.numberOfMonths; i++)
            calendar(DateTime(month.year, month.month + i)),
        ],
      ),
    );
  }
}

/// Legacy date-range trigger; the popup uses the same native range calendar.
class SteyDateRangePicker extends StatelessWidget {
  const SteyDateRangePicker({
    super.key,
    this.value,
    required this.onChanged,
    required this.firstDate,
    required this.lastDate,
    this.label = 'Select date range',
  });
  final DateTimeRange? value;
  final ValueChanged<DateTimeRange> onChanged;
  final DateTime firstDate, lastDate;
  final String label;
  @override
  Widget build(BuildContext context) => MenuAnchor(
    menuChildren: [
      Padding(
        padding: const EdgeInsets.all(16),
        child: SteyDatePicker(
          mode: SteyDateSelectionMode.range,
          range: value,
          firstDate: firstDate,
          lastDate: lastDate,
          onRangeChanged: onChanged,
          label: label,
          showOutsideDays: false,
        ),
      ),
    ],
    builder: (context, controller, _) => SteyButton(
      onPressed: () =>
          controller.isOpen ? controller.close() : controller.open(),
      icon: const Icon(Icons.calendar_today_outlined, size: 16),
      child: Text(
        value == null
            ? label
            : '${value!.start.month}/${value!.start.day} – ${value!.end.month}/${value!.end.day}',
      ),
    ),
  );
}
