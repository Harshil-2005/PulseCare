import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pulsecare/model/date_override.dart';
import 'package:table_calendar/table_calendar.dart';

class LeaveCalendarCard extends StatefulWidget {
  final Function(DateTime start, DateTime end) onRangeSelected;
  final List<DateOverride> overrides;

  const LeaveCalendarCard({
    super.key,
    required this.onRangeSelected,
    required this.overrides,
  });

  @override
  State<LeaveCalendarCard> createState() => _LeaveCalendarCardState();
}

class _LeaveCalendarCardState extends State<LeaveCalendarCard> {
  static final DateTime _firstDay = DateTime(2000, 1, 1);
  static final DateTime _lastDay = DateTime(2100, 12, 31);
  DateTime _focusedDay = DateTime.now();
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  RangeSelectionMode _rangeSelectionMode = RangeSelectionMode.toggledOn;
  bool _showYearPicker = false;

  void _shiftMonth(int delta) {
    setState(() {
      _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + delta, 1);
    });
  }

  Widget _headerChevron(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Icon(icon, color: const Color(0xFF3F67FD), size: 34),
      ),
    );
  }

  void _toggleYearPicker() {
    setState(() {
      _showYearPicker = !_showYearPicker;
    });
  }

  void _selectYear(int year) {
    setState(() {
      _focusedDay = DateTime(year, _focusedDay.month, 1);
      _showYearPicker = false;
    });
  }

  bool _hasLeave(DateTime day) {
    final normalized = DateUtils.dateOnly(day);

    for (final override in widget.overrides) {
      final start = DateUtils.dateOnly(override.startDate);
      final end = DateUtils.dateOnly(override.endDate);

      if (!normalized.isBefore(start) && !normalized.isAfter(end)) {
        return true;
      }
    }
    return false;
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
              constraints.maxHeight - headerHeight - bottomGap - saveRowHeight - bottomGap;
          final rowHeight = ((usableForCalendar - daysOfWeekHeight) / 6).clamp(27.0, 33.0);

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
                              fontSize: 20,
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
                      _headerChevron(Icons.chevron_left, () => _shiftMonth(-1)),
                      _headerChevron(Icons.chevron_right, () => _shiftMonth(1)),
                    ],
                  ],
                ),
              ),
              Expanded(
                child: _showYearPicker
                    ? GridView.builder(
                        itemCount: _lastDay.year - _firstDay.year + 1,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 4,
                              mainAxisSpacing: 8,
                              crossAxisSpacing: 8,
                              childAspectRatio: 2.1,
                            ),
                        itemBuilder: (context, index) {
                          final year = _firstDay.year + index;
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
                                  color: isSelected ? Colors.white : Colors.black,
                                ),
                              ),
                            ),
                          );
                        },
                      )
                    : TableCalendar(
                        firstDay: _firstDay,
                        lastDay: _lastDay,
                        focusedDay: _focusedDay,
                        rowHeight: rowHeight,
                        daysOfWeekHeight: daysOfWeekHeight,
                        availableGestures: AvailableGestures.horizontalSwipe,
                        rangeStartDay: _rangeStart,
                        rangeEndDay: _rangeEnd,
                        rangeSelectionMode: _rangeSelectionMode,
                        calendarFormat: CalendarFormat.month,
                        sixWeekMonthsEnforced: true,
                        headerVisible: false,
                        calendarStyle: CalendarStyle(
                          cellMargin: const EdgeInsets.symmetric(
                            horizontal: 2,
                            vertical: 2,
                          ),
                          todayDecoration: BoxDecoration(
                            color: const Color.fromARGB(255, 172, 205, 255),
                            shape: BoxShape.circle,
                          ),
                          selectedDecoration: const BoxDecoration(
                            color: Color(0xFF0066FF),
                            shape: BoxShape.circle,
                          ),
                          rangeStartDecoration: const BoxDecoration(
                            color: Color(0xFF0066FF),
                            shape: BoxShape.circle,
                          ),
                          rangeEndDecoration: const BoxDecoration(
                            color: Color(0xFF0066FF),
                            shape: BoxShape.circle,
                          ),
                          rangeHighlightColor: const Color(0x330066FF),
                          weekendTextStyle: const TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                          ),
                          defaultTextStyle: const TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                          ),
                          selectedTextStyle: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                          rangeStartTextStyle: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                          rangeEndTextStyle: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                          outsideTextStyle: const TextStyle(
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
                        enabledDayPredicate: (day) {
                          final todayLimit = DateTime.now().subtract(
                            const Duration(days: 1),
                          );
                          final isVisibleMonth =
                              day.year == _focusedDay.year &&
                              day.month == _focusedDay.month;
                          return isVisibleMonth && !day.isBefore(todayLimit);
                        },
                        calendarBuilders: CalendarBuilders(
                          defaultBuilder: (context, day, focusedDay) {
                            if (_hasLeave(day)) {
                              return Container(
                                decoration: const BoxDecoration(
                                  color: Color(0x33FF4D4F),
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '${day.day}',
                                  style: const TextStyle(color: Colors.black),
                                ),
                              );
                            }
                            return null;
                          },
                        ),
                        onDaySelected: (selectedDay, focusedDay) {
                          setState(() {
                            _focusedDay = focusedDay;
                          });
                        },
                        onRangeSelected: (start, end, focusedDay) {
                          setState(() {
                            _focusedDay = focusedDay;
                            _rangeStart = start;
                            _rangeEnd = end ?? start;
                          });
                        },
                      ),
              ),
              const SizedBox(height: bottomGap),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  InkWell(
                    onTap: (_rangeStart == null || _rangeEnd == null)
                        ? null
                        : () => widget.onRangeSelected(_rangeStart!, _rangeEnd!),
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
