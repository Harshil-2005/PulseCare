import 'package:flutter/material.dart';
import 'package:pulsecare/utils/keyboard_utils.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pulsecare/model/day_schedule.dart';

class EditDayScheduleSheet extends StatefulWidget {
  const EditDayScheduleSheet({
    super.key,
    required this.daySchedule,
    required this.slotDuration,
    required this.onSave,
  });

  final DaySchedule daySchedule;
  final int slotDuration;
  final ValueChanged<DaySchedule> onSave;

  @override
  State<EditDayScheduleSheet> createState() => _EditDayScheduleSheetState();
}

class _EditDayScheduleSheetState extends State<EditDayScheduleSheet> {
  late bool morningEnabled;
  late bool afternoonEnabled;
  late TextEditingController morningStartController;
  late TextEditingController morningEndController;
  late TextEditingController afternoonStartController;
  late TextEditingController afternoonEndController;
  late FocusNode morningStartFocusNode;
  late FocusNode morningEndFocusNode;
  late FocusNode afternoonStartFocusNode;
  late FocusNode afternoonEndFocusNode;

  @override
  void initState() {
    super.initState();
    morningEnabled = widget.daySchedule.morningEnabled;
    afternoonEnabled = widget.daySchedule.afternoonEnabled;
    morningStartController = TextEditingController(text: widget.daySchedule.morningStart);
    morningEndController = TextEditingController(text: widget.daySchedule.morningEnd);
    afternoonStartController = TextEditingController(
      text: widget.daySchedule.afternoonStart,
    );
    afternoonEndController = TextEditingController(text: widget.daySchedule.afternoonEnd);
    morningStartFocusNode = FocusNode();
    morningEndFocusNode = FocusNode();
    afternoonStartFocusNode = FocusNode();
    afternoonEndFocusNode = FocusNode();
  }

  @override
  void dispose() {
    morningStartController.dispose();
    morningEndController.dispose();
    afternoonStartController.dispose();
    afternoonEndController.dispose();
    morningStartFocusNode.dispose();
    morningEndFocusNode.dispose();
    afternoonStartFocusNode.dispose();
    afternoonEndFocusNode.dispose();
    super.dispose();
  }

  TimeOfDay? _parseTime(String text) {
    final match = RegExp(
      r'^(0?[1-9]|1[0-2]):([0-5][0-9])\s?(AM|PM)$',
      caseSensitive: false,
    ).firstMatch(text.trim());
    if (match == null) return null;

    final hour12 = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    final period = match.group(3)!.toUpperCase();
    final baseHour = hour12 == 12 ? 0 : hour12;
    final hour24 = period == 'PM' ? baseHour + 12 : baseHour;
    return TimeOfDay(hour: hour24, minute: minute);
  }

  int _timeToMinutes(TimeOfDay value) => value.hour * 60 + value.minute;

  TimeOfDay _snapToSlot(TimeOfDay time) {
    final totalMinutes = _timeToMinutes(time);
    final snappedMinutes =
        (totalMinutes / widget.slotDuration).ceil() * widget.slotDuration;
    final cappedMinutes = snappedMinutes.clamp(0, (23 * 60) + 59);
    final snappedHour = cappedMinutes ~/ 60;
    final snappedMinute = cappedMinutes % 60;
    return TimeOfDay(hour: snappedHour, minute: snappedMinute);
  }

  String _formatTime(TimeOfDay value) {
    final hour = value.hourOfPeriod == 0 ? 12 : value.hourOfPeriod;
    final minute = value.minute.toString().padLeft(2, '0');
    final period = value.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  String? _normalizeTypedTime(String raw, {required bool isMorning}) {
    final value = raw.trim().toUpperCase();
    if (value.isEmpty) return '';

    if (_parseTime(value) != null) return value;

    final defaultPeriod = isMorning ? 'AM' : 'PM';

    final hourOnly = RegExp(r'^(0?[1-9]|1[0-2])$').firstMatch(value);
    if (hourOnly != null) {
      final hour = int.parse(hourOnly.group(1)!);
      if (hour == 12) {
        return '12:00 PM';
      }
      return '$hour:00 $defaultPeriod';
    }

    final hourMinute = RegExp(
      r'^(0?[1-9]|1[0-2]):([0-5]?[0-9])$',
    ).firstMatch(value);
    if (hourMinute != null) {
      final hour = int.parse(hourMinute.group(1)!);
      final minute = int.parse(hourMinute.group(2)!);
      final minuteStr = minute.toString().padLeft(2, '0');
      return '$hour:$minuteStr $defaultPeriod';
    }

    return null;
  }

  void _onManualTimeEditingComplete(
    TextEditingController controller, {
    required bool isMorning,
  }) {
    final raw = controller.text.trim();
    final normalized = _normalizeTypedTime(raw, isMorning: isMorning);

    if (normalized == '') {
      controller.clear();
      return;
    }
    if (normalized == null) {
      _showError('Use hh:mm AM/PM format');
      controller.clear();
      return;
    }

    final parsed = _parseTime(normalized);
    if (parsed == null) {
      _showError('Use hh:mm AM/PM format');
      controller.clear();
      return;
    }

    final snapped = _snapToSlot(parsed);
    final formatted = _formatTime(snapped);
    if (controller.text != formatted) {
      controller.text = formatted;
      controller.selection = TextSelection.collapsed(offset: formatted.length);
    }
  }

  Future<void> _pickTime(TextEditingController controller) async {
    final parsed = _parseTime(controller.text.trim());
    final initial = parsed ?? TimeOfDay.now();
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null) return;
    final snapped = _snapToSlot(picked);
    controller.text = _formatTime(snapped);
  }

  bool _validateAndSave() {
    TimeOfDay? morningStart;
    TimeOfDay? morningEnd;
    TimeOfDay? afternoonStart;
    TimeOfDay? afternoonEnd;
    const morningMin = 5 * 60;
    const noon = 12 * 60;
    const afternoonMax = 21 * 60;

    if (morningEnabled) {
      final parsedStart = _parseTime(morningStartController.text.trim());
      final parsedEnd = _parseTime(morningEndController.text.trim());
      if (parsedStart == null || parsedEnd == null) {
        _showError('Use hh:mm AM/PM format');
        return false;
      }
      morningStart = _snapToSlot(parsedStart);
      morningEnd = _snapToSlot(parsedEnd);
      morningStartController.text = _formatTime(morningStart);
      morningEndController.text = _formatTime(morningEnd);

      if (_timeToMinutes(morningStart) < morningMin ||
          _timeToMinutes(morningStart) >= noon) {
        _showError('Morning session must be between 5 AM and 12 PM.');
        return false;
      }
      if (_timeToMinutes(morningEnd) < morningMin ||
          _timeToMinutes(morningEnd) > noon) {
        _showError('Morning session must be between 5 AM and 12 PM.');
        return false;
      }
      if (_timeToMinutes(morningEnd) <= _timeToMinutes(morningStart)) {
        _showError('Morning end time must be after start time');
        return false;
      }
    }

    if (afternoonEnabled) {
      final parsedStart = _parseTime(afternoonStartController.text.trim());
      final parsedEnd = _parseTime(afternoonEndController.text.trim());
      if (parsedStart == null || parsedEnd == null) {
        _showError('Use hh:mm AM/PM format');
        return false;
      }
      afternoonStart = _snapToSlot(parsedStart);
      afternoonEnd = _snapToSlot(parsedEnd);
      afternoonStartController.text = _formatTime(afternoonStart);
      afternoonEndController.text = _formatTime(afternoonEnd);

      if (_timeToMinutes(afternoonStart) < noon ||
          _timeToMinutes(afternoonStart) > afternoonMax) {
        _showError('Afternoon session must be between 12 PM and 9 PM.');
        return false;
      }
      if (_timeToMinutes(afternoonEnd) <= noon ||
          _timeToMinutes(afternoonEnd) > afternoonMax) {
        _showError('Afternoon session must be between 12 PM and 9 PM.');
        return false;
      }
      if (_timeToMinutes(afternoonEnd) <= _timeToMinutes(afternoonStart)) {
        _showError('Afternoon end time must be after start time');
        return false;
      }
    }

    if (morningEnabled &&
        afternoonEnabled &&
        morningEnd != null &&
        afternoonStart != null &&
        _timeToMinutes(morningEnd) >= _timeToMinutes(afternoonStart)) {
      _showError('Morning must end before Afternoon starts');
      return false;
    }

    final updatedDaySchedule = widget.daySchedule.copyWith(
      morningEnabled: morningEnabled,
      morningStart: morningEnabled
          ? _formatTime(morningStart!)
          : morningStartController.text.trim(),
      morningEnd: morningEnabled
          ? _formatTime(morningEnd!)
          : morningEndController.text.trim(),
      afternoonEnabled: afternoonEnabled,
      afternoonStart: afternoonEnabled
          ? _formatTime(afternoonStart!)
          : afternoonStartController.text.trim(),
      afternoonEnd: afternoonEnabled
          ? _formatTime(afternoonEnd!)
          : afternoonEndController.text.trim(),
    );
    widget.onSave(updatedDaySchedule);
    return true;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _timeField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hint,
    required bool isMorning,
    FocusNode? nextFocusNode,
  }) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: TextInputType.datetime,
      textInputAction:
          nextFocusNode == null ? TextInputAction.done : TextInputAction.next,
      style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500),
      onEditingComplete: () =>
          _onManualTimeEditingComplete(controller, isMorning: isMorning),
      onSubmitted: (_) {
        _onManualTimeEditingComplete(controller, isMorning: isMorning);
        if (nextFocusNode == null) {
          KeyboardUtils.hideKeyboardKeepFocus();
          return;
        }
        FocusScope.of(context).requestFocus(nextFocusNode);
      },
      onTapOutside: (_) {
        _onManualTimeEditingComplete(controller, isMorning: isMorning);
        KeyboardUtils.hideKeyboardKeepFocus();
      },
      decoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        suffixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        suffixIcon: InkWell(
          onTap: () => _pickTime(controller),
          child: Padding(
            padding: const EdgeInsets.all(9),
            child: SizedBox(
              height: 20,
              width: 20,
              child: SvgPicture.asset(
                'assets/icons/calender.svg',
                fit: BoxFit.contain,
                colorFilter: ColorFilter.mode(
                  Colors.grey.shade400,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
        ),
        hintText: hint,
        hintStyle: TextStyle(fontSize: 12.5, color: Colors.grey.shade400),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.daySchedule.day,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F7FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Morning Session',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Switch(
                          value: morningEnabled,
                          onChanged: (value) {
                            setState(() {
                              morningEnabled = value;
                            });
                          },
                          activeColor: const Color(0xFF3F67FD),
                          activeTrackColor: const Color.fromARGB(255, 196, 209, 255),
                        ),
                      ],
                    ),
                    if (morningEnabled) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _timeField(
                              controller: morningStartController,
                              focusNode: morningStartFocusNode,
                              hint: 'Start Time',
                              isMorning: true,
                              nextFocusNode: morningEndFocusNode,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            '-',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _timeField(
                              controller: morningEndController,
                              focusNode: morningEndFocusNode,
                              hint: 'End Time',
                              isMorning: true,
                              nextFocusNode: afternoonEnabled
                                  ? afternoonStartFocusNode
                                  : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Afternoon Session',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Switch(
                          value: afternoonEnabled,
                          onChanged: (value) {
                            setState(() {
                              afternoonEnabled = value;
                            });
                          },
                          activeColor: const Color(0xFF3F67FD),
                          activeTrackColor: const Color.fromARGB(255, 196, 209, 255),
                        ),
                      ],
                    ),
                    if (afternoonEnabled) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _timeField(
                              controller: afternoonStartController,
                              focusNode: afternoonStartFocusNode,
                              hint: 'Start Time',
                              isMorning: false,
                              nextFocusNode: afternoonEndFocusNode,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            '-',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _timeField(
                              controller: afternoonEndController,
                              focusNode: afternoonEndFocusNode,
                              hint: 'End Time',
                              isMorning: false,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _validateAndSave,
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xff3F67FD),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Center(
                    child: Text(
                      'Save',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


