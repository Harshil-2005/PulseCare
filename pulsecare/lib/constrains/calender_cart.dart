import 'package:flutter/material.dart';

class CalendarCard extends StatefulWidget {
  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final ValueChanged<DateTime> onDateSelected;

  const CalendarCard({
    super.key,
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
    required this.onDateSelected,
  });

  @override
  State<CalendarCard> createState() => _CalendarCardState();
}

class _CalendarCardState extends State<CalendarCard> {
  late DateTime selectedDate;

  @override
  void initState() {
    selectedDate = widget.initialDate;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          datePickerTheme: DatePickerThemeData(
            backgroundColor: Colors.white,
            headerBackgroundColor: Colors.white,
            headerForegroundColor: Colors.black,

            headerHeadlineStyle: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),

            weekdayStyle: const TextStyle(color: Colors.grey),

            dayBackgroundColor: WidgetStateProperty.resolveWith(
              (states) =>
                  states.contains(WidgetState.selected)
                      ? Colors.blue.shade100
                      : Colors.transparent,
            ),

            dayForegroundColor: WidgetStateProperty.resolveWith(
              (states) =>
                  states.contains(WidgetState.disabled)
                      ? Colors.grey
                      : Colors.black,
            ),

            todayBackgroundColor:
                WidgetStateProperty.all(Colors.transparent),
            todayForegroundColor:
                WidgetStateProperty.all(Colors.black),
          ),
        ),
        child: CalendarDatePicker(
          initialDate: selectedDate,
          firstDate: widget.firstDate,
          lastDate: widget.lastDate,
          onDateChanged: (date) {
            setState(() => selectedDate = date);
            widget.onDateSelected(date);
          },
        ),
      ),
    );
  }
}
