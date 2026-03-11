import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

Future<DateTime?> showScheduleDatePicker({
  required BuildContext context,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
}) {
  final normalizedFirst = DateUtils.dateOnly(firstDate);
  final normalizedLast = DateUtils.dateOnly(lastDate);
  final safeFirst = normalizedFirst.isAfter(normalizedLast)
      ? normalizedLast
      : normalizedFirst;
  final safeLast = normalizedLast.isBefore(normalizedFirst)
      ? normalizedFirst
      : normalizedLast;

  DateTime clamp(DateTime value) {
    final normalized = DateUtils.dateOnly(value);
    final min = safeFirst;
    final max = safeLast;
    if (normalized.isBefore(min)) return min;
    if (normalized.isAfter(max)) return max;
    return normalized;
  }

  final safeInitial = clamp(initialDate);

  return showDialog<DateTime>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) {
      return Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        backgroundColor: Colors.transparent,
        child: _ScheduleDatePickerDialog(
          initialDate: safeInitial,
          firstDate: safeFirst,
          lastDate: safeLast,
        ),
      );
    },
  );
}

class _ScheduleDatePickerDialog extends StatefulWidget {
  const _ScheduleDatePickerDialog({
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
  });

  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;

  @override
  State<_ScheduleDatePickerDialog> createState() =>
      _ScheduleDatePickerDialogState();
}

class _ScheduleDatePickerDialogState extends State<_ScheduleDatePickerDialog> {
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  bool _showYearPicker = false;
  ScrollController? _yearScrollController;

  DateTime _clampToBounds(DateTime value) {
    final normalized = DateUtils.dateOnly(value);
    if (normalized.isBefore(widget.firstDate)) return widget.firstDate;
    if (normalized.isAfter(widget.lastDate)) return widget.lastDate;
    return normalized;
  }

  @override
  void initState() {
    super.initState();
    _selectedDay = _clampToBounds(widget.initialDate);
    _focusedDay = _selectedDay;
  }

  void _shiftMonth(int delta) {
    setState(() {
      final shifted = _clampToBounds(
        DateTime(_focusedDay.year, _focusedDay.month + delta, _focusedDay.day),
      );

      if (shifted.year == _focusedDay.year &&
          shifted.month == _focusedDay.month) {
        return;
      }

      _focusedDay = shifted;
    });
  }

  void _toggleYearPicker() {
    setState(() {
      _showYearPicker = !_showYearPicker;
    });
  }

  @override
  void dispose() {
    _yearScrollController?.dispose();
    super.dispose();
  }

  void _selectYear(int year) {
    setState(() {
      final month = _focusedDay.month;
      final candidate = DateTime(year, month, _focusedDay.day);
      _focusedDay = _clampToBounds(candidate);
      _showYearPicker = false;
    });
  }

  bool _isEnabledDay(DateTime day) {
    final normalized = DateUtils.dateOnly(day);
    final isVisibleMonth =
        day.year == _focusedDay.year && day.month == _focusedDay.month;
    return isVisibleMonth &&
        !normalized.isBefore(widget.firstDate) &&
        !normalized.isAfter(widget.lastDate);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 338,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(9),
      ),
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const headerHeight = 40.0;
          const bottomGap = 8.0;
          const saveRowHeight = 40.0;
          const daysOfWeekHeight = 22.0;
          final usableForCalendar =
              constraints.maxHeight -
              headerHeight -
              bottomGap -
              saveRowHeight -
              bottomGap;
          final rowHeight = ((usableForCalendar - daysOfWeekHeight) / 6).clamp(
            27.0,
            33.0,
          );

          return Column(
            children: [
              SizedBox(
                height: headerHeight,
                child: Row(
                  children: [
                    InkWell(
                      onTap: _toggleYearPicker,
                      borderRadius: BorderRadius.circular(8),
                      child: Row(
                        children: [
                          Text(
                            DateFormat('MMMM yyyy').format(_focusedDay),
                            style: const TextStyle(
                              fontSize: 32 / 1.6,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF3A3A40),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            _showYearPicker
                                ? Icons.keyboard_arrow_down
                                : Icons.chevron_right,
                            size: 34,
                            color: const Color(0xFF3F67FD),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    if (!_showYearPicker) ...[
                      InkWell(
                        onTap: () => _shiftMonth(-1),
                        borderRadius: BorderRadius.circular(20),
                        child: const Padding(
                          padding: EdgeInsets.all(2),
                          child: Icon(
                            Icons.chevron_left,
                            color: Color(0xFF3F67FD),
                            size: 34,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () => _shiftMonth(1),
                        borderRadius: BorderRadius.circular(20),
                        child: const Padding(
                          padding: EdgeInsets.all(2),
                          child: Icon(
                            Icons.chevron_right,
                            color: Color(0xFF3F67FD),
                            size: 34,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Expanded(
                child: _showYearPicker
                    ? LayoutBuilder(
                        builder: (context, yearConstraints) {
                          const crossAxisCount = 4;
                          const mainAxisSpacing = 8.0;
                          const crossAxisSpacing = 8.0;
                          const childAspectRatio = 2.1;

                          final totalYears =
                              widget.lastDate.year - widget.firstDate.year + 1;
                          final selectedIndex =
                              (_focusedDay.year - widget.firstDate.year).clamp(
                                0,
                                totalYears - 1,
                              );

                          final itemWidth =
                              (yearConstraints.maxWidth -
                                  (crossAxisCount - 1) * crossAxisSpacing) /
                              crossAxisCount;
                          final itemHeight = itemWidth / childAspectRatio;
                          final rowExtent = itemHeight + mainAxisSpacing;
                          final selectedRow = selectedIndex ~/ crossAxisCount;
                          final targetOffset =
                              (selectedRow * rowExtent - (rowExtent * 2)).clamp(
                                0.0,
                                double.infinity,
                              );

                          _yearScrollController?.dispose();
                          _yearScrollController = ScrollController(
                            initialScrollOffset: targetOffset,
                          );

                          return GridView.builder(
                            controller: _yearScrollController,
                            itemCount: totalYears,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  mainAxisSpacing: mainAxisSpacing,
                                  crossAxisSpacing: crossAxisSpacing,
                                  childAspectRatio: childAspectRatio,
                                ),
                            itemBuilder: (context, index) {
                              final year = widget.firstDate.year + index;
                              final isSelected = year == _focusedDay.year;
                              return InkWell(
                                onTap: () => _selectYear(year),
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFF0066FF)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isSelected
                                          ? const Color(0xFF0066FF)
                                          : const Color(0xFFE0E0E0),
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '$year',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      )
                    : TableCalendar(
                        firstDay: widget.firstDate,
                        lastDay: widget.lastDate,
                        focusedDay: _focusedDay,
                        rowHeight: rowHeight,
                        daysOfWeekHeight: daysOfWeekHeight,
                        availableGestures: AvailableGestures.horizontalSwipe,
                        selectedDayPredicate: (day) =>
                            isSameDay(day, _selectedDay),
                        calendarFormat: CalendarFormat.month,
                        sixWeekMonthsEnforced: true,
                        headerVisible: false,
                        calendarStyle: const CalendarStyle(
                          cellMargin: EdgeInsets.symmetric(
                            horizontal: 2,
                            vertical: 2,
                          ),
                          todayDecoration: BoxDecoration(
                            color: Color.fromARGB(255, 172, 205, 255),
                            shape: BoxShape.circle,
                          ),
                          selectedDecoration: BoxDecoration(
                            color: Color(0xFF0066FF),
                            shape: BoxShape.circle,
                          ),
                          weekendTextStyle: TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                          ),
                          defaultTextStyle: TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                          ),
                          selectedTextStyle: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                          outsideTextStyle: TextStyle(
                            color: Color(0xFF8A8A8A),
                            fontSize: 16,
                          ),
                        ),
                        daysOfWeekStyle: const DaysOfWeekStyle(
                          weekendStyle: TextStyle(
                            color: Color(0xFF8A8A8A),
                            fontSize: 15,
                          ),
                          weekdayStyle: TextStyle(
                            color: Color(0xFF8A8A8A),
                            fontSize: 15,
                          ),
                        ),
                        enabledDayPredicate: _isEnabledDay,
                        onDaySelected: (selectedDay, focusedDay) {
                          setState(() {
                            _focusedDay = _clampToBounds(focusedDay);
                            _selectedDay = _clampToBounds(selectedDay);
                          });
                        },
                      ),
              ),
              const SizedBox(height: bottomGap),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  InkWell(
                    onTap: () => Navigator.of(context).pop(_selectedDay),
                    child: Container(
                      width: 96,
                      height: saveRowHeight,
                      decoration: BoxDecoration(
                        color: const Color(0xff3F67FD),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Center(
                        child: Text(
                          'Save',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
