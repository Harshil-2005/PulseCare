import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pulsecare/utils/keyboard_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:pulsecare/constrains/app_toast.dart';
import 'package:pulsecare/constrains/schedule_date_picker_dialog.dart';
import 'package:pulsecare/model/appointment_model.dart';
import 'package:pulsecare/model/doctor_availability.dart';
import 'package:pulsecare/model/report_model.dart';
import 'package:pulsecare/repositories/session_repository.dart';
import 'package:pulsecare/user/app_shell.dart';
import 'package:pulsecare/utils/time_utils.dart';
import '../providers/repository_providers.dart';

class DateTimeScreen extends ConsumerStatefulWidget {
  final String doctorId;
  final String patientName;
  final int age;
  final String gender;
  final String symptoms;
  final List<ReportModel> selectedReports;
  final String? aiSummaryId;
  final Appointment? existingAppointment;

  const DateTimeScreen({
    super.key,
    required this.doctorId,
    required this.patientName,
    required this.age,
    required this.gender,
    required this.symptoms,
    required this.selectedReports,
    this.aiSummaryId,
    this.existingAppointment,
  });

  @override
  ConsumerState<DateTimeScreen> createState() => _DateTimeScreenState();
}

class _DateTimeScreenState extends ConsumerState<DateTimeScreen> {
  final TextEditingController _dateController = TextEditingController();
  late final _availabilityRepository;
  String selectedDate = TimeUtils.formatDate(DateTime.now());
  bool _doctorAvailableOnSelectedDay = true;
  bool _isFormattingDateInput = false;
  late List<TimeSlot> morningSlots;
  late List<TimeSlot> afternoonSlots;

  @override
  void initState() {
    super.initState();
    _availabilityRepository = ref.read(availabilityRepositoryProvider);
    morningSlots = _availabilityRepository.getDefaultMorningSlots();
    afternoonSlots = _availabilityRepository.getDefaultAfternoonSlots();
    Future.microtask(() => _setSelectedDateWithAutoShift(DateTime.now()));
  }

  List<TimeSlot> get _allSlots => [...morningSlots, ...afternoonSlots];

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  DateTime _slotDateTime(DateTime date, String slotTime) {
    final parsed = TimeUtils.parseTime(slotTime);
    return DateTime(
      date.year,
      date.month,
      date.day,
      parsed.hour,
      parsed.minute,
    );
  }

  Future<List<DateTime>> _getBookedSlotsForDate(DateTime date) async {
    final appointmentRepository = ref.read(appointmentRepositoryProvider);

    final appointments = await appointmentRepository
        .watchAppointmentsForDoctor(widget.doctorId)
        .first;
    return appointments
        .where(
          (appointment) =>
              appointment.scheduledAt.year == date.year &&
              appointment.scheduledAt.month == date.month &&
              appointment.scheduledAt.day == date.day &&
              (widget.existingAppointment == null ||
                  appointment.id != widget.existingAppointment!.id) &&
              appointment.status != AppointmentStatus.cancelled,
        )
        .map((appointment) {
          return appointment.scheduledAt;
        })
        .toList();
  }

  Future<void> _loadSlotsForDate(
    DateTime date, {
    bool triggerSetState = true,
  }) async {
    final doctor = await ref
        .read(doctorRepositoryProvider)
        .getDoctorById(widget.doctorId);
    if (doctor == null) {
      if (triggerSetState) {
        setState(() {
          _doctorAvailableOnSelectedDay = false;
          morningSlots = const [];
          afternoonSlots = const [];
        });
      } else {
        _doctorAvailableOnSelectedDay = false;
        morningSlots = const [];
        afternoonSlots = const [];
      }
      return;
    }

    final bookedSlotDateTimes = await _getBookedSlotsForDate(date);
    final slots = _availabilityRepository.getSlots(
      doctor: doctor,
      date: date,
      bookedSlotDateTimes: bookedSlotDateTimes,
    );

    if (triggerSetState) {
      setState(() {
        _doctorAvailableOnSelectedDay = slots.isAvailable;
        morningSlots = slots.morningSlots;
        afternoonSlots = slots.afternoonSlots;
      });
    } else {
      _doctorAvailableOnSelectedDay = slots.isAvailable;
      morningSlots = slots.morningSlots;
      afternoonSlots = slots.afternoonSlots;
    }
  }

  bool _hasAnyFutureSlotForToday(DateTime today) {
    final now = DateTime.now();
    for (final slot in _allSlots) {
      if (slot.status == SlotStatus.booked) continue;
      final slotDateTime = _slotDateTime(today, slot.time);
      if (slotDateTime.isAfter(now)) {
        return true;
      }
    }
    return false;
  }

  Future<void> _setSelectedDateWithAutoShift(DateTime pickedDate) async {
    DateTime finalDate = pickedDate;
    final now = DateTime.now();

    await _loadSlotsForDate(pickedDate, triggerSetState: false);

    if (_isSameDay(pickedDate, now) && !_hasAnyFutureSlotForToday(now)) {
      finalDate = DateTime(
        now.year,
        now.month,
        now.day,
      ).add(const Duration(days: 1));
      await _loadSlotsForDate(finalDate, triggerSetState: false);
    }

    if (mounted) {
      setState(() {
        selectedDate = TimeUtils.formatDate(finalDate);
        if (_dateController.text != selectedDate) {
          _dateController.text = selectedDate;
        }
      });
    } else {
      selectedDate = TimeUtils.formatDate(finalDate);
      if (_dateController.text != selectedDate) {
        _dateController.text = selectedDate;
      }
    }
  }

  void _handleDateInputChanged(String value) {
    if (_isFormattingDateInput) return;

    final currentSelection = _dateController.selection.baseOffset;
    final safeSelection = currentSelection.clamp(0, value.length);
    final digitsBeforeCursor = value
        .substring(0, safeSelection)
        .replaceAll(RegExp(r'[^0-9]'), '')
        .length;
    String normalized = value;
    var targetCursor = safeSelection;

    if (value.contains('/')) {
      final slashSafe = value.replaceAll(RegExp(r'[^0-9/]'), '');
      final parts = slashSafe.split('/');

      String onlyDigits(String input) {
        return input.replaceAll(RegExp(r'[^0-9]'), '');
      }

      String takeDigits(String input, int max) {
        final d = input.replaceAll(RegExp(r'[^0-9]'), '');
        return d.length > max ? d.substring(0, max) : d;
      }

      final p0 = parts.isNotEmpty ? onlyDigits(parts[0]) : '';
      final p1 = parts.length > 1 ? onlyDigits(parts[1]) : '';
      final p2 = parts.length > 2 ? onlyDigits(parts[2]) : '';

      final dd = takeDigits(p0, 2);
      final carryToMm = p0.length > 2 ? p0.substring(2) : '';
      final mmCombined = '$carryToMm$p1';
      final mm = takeDigits(mmCombined, 2);
      final carryToYyyy = mmCombined.length > 2 ? mmCombined.substring(2) : '';
      final yyyyCombined = '$carryToYyyy$p2';
      final yyyy = takeDigits(yyyyCombined, 4);

      final buffer = StringBuffer();
      buffer.write(dd);
      if (mm.isNotEmpty || yyyy.isNotEmpty || slashSafe.contains('/')) {
        buffer.write('/');
        buffer.write(mm);
      }
      if (yyyy.isNotEmpty || slashSafe.split('/').length > 2) {
        buffer.write('/');
        buffer.write(yyyy);
      }
      normalized = buffer.toString();
      final normalizedDigits = normalized.replaceAll(RegExp(r'[^0-9]'), '');
      targetCursor = _cursorOffsetForDigitCount(
        normalized,
        digitsBeforeCursor > normalizedDigits.length
            ? normalizedDigits.length
            : digitsBeforeCursor,
      );
    } else {
      final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
      if (digits.isEmpty) {
        if (_dateController.text.isNotEmpty) {
          _isFormattingDateInput = true;
          _dateController.value = const TextEditingValue(
            text: '',
            selection: TextSelection.collapsed(offset: 0),
          );
          _isFormattingDateInput = false;
        }
        return;
      }

      final limitedDigits = digits.length > 8 ? digits.substring(0, 8) : digits;
      normalized = _formatDateDigits(limitedDigits);
      targetCursor = _cursorOffsetForDigitCount(
        normalized,
        digitsBeforeCursor > limitedDigits.length
            ? limitedDigits.length
            : digitsBeforeCursor,
      );
    }

    if (normalized != value) {
      _isFormattingDateInput = true;
      _dateController.value = TextEditingValue(
        text: normalized,
        selection: TextSelection.collapsed(offset: targetCursor),
      );
      _isFormattingDateInput = false;
    }

    final onlyDigits = normalized.replaceAll(RegExp(r'[^0-9]'), '');
    if (onlyDigits.length == 8 && normalized.length == 10) {
      try {
        final parsedDate = TimeUtils.parseDateStrict(normalized);
        unawaited(_setSelectedDateWithAutoShift(parsedDate));
      } catch (_) {
        // Keep normalized text only for invalid full dates.
      }
    }
  }

  String _formatDateDigits(String digits) {
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      buffer.write(digits[i]);
      if ((i == 1 || i == 3) && i != digits.length - 1) {
        buffer.write('/');
      }
    }
    return buffer.toString();
  }

  int _cursorOffsetForDigitCount(String formatted, int digitCount) {
    if (digitCount <= 0) return 0;

    var seenDigits = 0;
    for (var i = 0; i < formatted.length; i++) {
      if (RegExp(r'[0-9]').hasMatch(formatted[i])) {
        seenDigits++;
        if (seenDigits == digitCount) {
          var offset = i + 1;
          if (offset < formatted.length && formatted[offset] == '/') {
            offset += 1;
          }
          return offset;
        }
      }
    }
    return formatted.length;
  }

  void onSlotTap(TimeSlot tappedSlot) {
    if (tappedSlot.status == SlotStatus.booked) return;

    setState(() {
      morningSlots = morningSlots.map((slot) {
        if (slot.status == SlotStatus.selected) {
          slot = slot.copyWith(status: SlotStatus.available);
        }
        return slot;
      }).toList();

      afternoonSlots = afternoonSlots.map((slot) {
        if (slot.status == SlotStatus.selected) {
          slot = slot.copyWith(status: SlotStatus.available);
        }
        return slot;
      }).toList();

      morningSlots = morningSlots.map((slot) {
        if (slot.time == tappedSlot.time) {
          slot = slot.copyWith(status: SlotStatus.selected);
        }
        return slot;
      }).toList();

      afternoonSlots = afternoonSlots.map((slot) {
        if (slot.time == tappedSlot.time) {
          slot = slot.copyWith(status: SlotStatus.selected);
        }
        return slot;
      }).toList();
    });
  }

  void bookSelectedSlot() {
    TimeSlot? selectedSlot;

    for (var slot in [...morningSlots, ...afternoonSlots]) {
      if (slot.status == SlotStatus.selected) {
        selectedSlot = slot;
        break;
      }
    }

    if (selectedSlot == null) return;

    setState(() {
      morningSlots = morningSlots.map((slot) {
        if (slot.time == selectedSlot!.time) {
          slot = slot.copyWith(status: SlotStatus.booked);
        }
        return slot;
      }).toList();

      afternoonSlots = afternoonSlots.map((slot) {
        if (slot.time == selectedSlot!.time) {
          slot = slot.copyWith(status: SlotStatus.booked);
        }
        return slot;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leadingWidth: 40,
        titleSpacing: 0,
        toolbarHeight: 85,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
        elevation: 0.3,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Select Date or Time',
              style: TextStyle(fontSize: 20, fontWeight: .w600),
            ),
          ],
        ),
        shadowColor: Colors.black,
        automaticallyImplyLeading: true,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: SvgPicture.asset(
            'assets/icons/backarrow.svg',
            width: 24,
            height: 20,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 40, left: 16),
              child: Text(
                'Select Date',
                style: TextStyle(fontWeight: .w500, fontSize: 18),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 10, left: 16, right: 16),
              child: TextField(
                controller: _dateController,
                keyboardType: TextInputType.datetime,
                onTapOutside: (_) {
                  KeyboardUtils.hideKeyboardKeepFocus();
                },
                onChanged: (value) {
                  _handleDateInputChanged(value);
                },
                decoration: InputDecoration(
                  suffixIcon: InkWell(
                    onTap: () async {
                      DateTime initialDate;

                      try {
                        initialDate = DateFormat(
                          'dd/MM/yyyy',
                        ).parseStrict(_dateController.text);
                      } catch (e) {
                        initialDate = DateTime.now();
                      }

                      DateTime? picked = await showScheduleDatePicker(
                        context: context,
                        initialDate: initialDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100),
                      );
                      if (!mounted) return;

                      if (picked != null) {
                        setState(() {
                          selectedDate = DateFormat(
                            'dd/MM/yyyy',
                          ).format(picked);
                          _dateController.text = selectedDate;
                        });
                        unawaited(_setSelectedDateWithAutoShift(picked));
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: SizedBox(
                        height: 20,
                        width: 20,
                        child: Image.asset('assets/images/select_date.png'),
                      ),
                    ),
                  ),
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade400),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade400),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 20, left: 16, right: 16),
              child: Text(
                'Available Time Slots',
                style: TextStyle(fontWeight: .w500, fontSize: 18),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 10, left: 16, right: 16),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(blurRadius: 12, color: Colors.grey.shade300),
                  ],
                ),

                width: double.infinity,

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!_doctorAvailableOnSelectedDay)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'Doctor not available on this day.',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey,
                          ),
                        ),
                      )
                    else ...[
                      if (morningSlots.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.only(top: 16, left: 14),
                          child: Text(
                            'Morning Slots',
                            style: TextStyle(fontWeight: .w500, fontSize: 16),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          child: GridView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: morningSlots.length,
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  mainAxisSpacing: 12,
                                  crossAxisSpacing: 12,
                                  childAspectRatio: 110 / 45,
                                ),
                            itemBuilder: (context, index) {
                              return InkWell(
                                onTap: () => onSlotTap(morningSlots[index]),
                                child: timeSlotItem(morningSlots[index]),
                              );
                            },
                          ),
                        ),
                      ],
                      if (afternoonSlots.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.only(left: 16, right: 16),
                          child: Text(
                            'Afternoon Slots',
                            style: TextStyle(fontWeight: .w500, fontSize: 16),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          child: GridView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: afternoonSlots.length,
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  mainAxisSpacing: 12,
                                  crossAxisSpacing: 12,
                                  childAspectRatio: 110 / 45,
                                ),
                            itemBuilder: (context, index) {
                              return InkWell(
                                onTap: () => onSlotTap(afternoonSlots[index]),
                                child: timeSlotItem(afternoonSlots[index]),
                              );
                            },
                          ),
                        ),
                      ],
                      Padding(
                        padding: const EdgeInsets.only(
                          bottom: 10,
                          left: 60,
                          right: 60,
                        ),
                        child: SizedBox(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 14,
                                    height: 14,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        width: 1.5,
                                        color: Color(0xff3F67FD),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 3),
                                  Text(
                                    'Available',
                                    style: TextStyle(
                                      color: Colors.grey.shade400,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Container(
                                    width: 14,
                                    height: 14,
                                    decoration: BoxDecoration(
                                      color: Color(0xff3F67FD),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        width: 1.5,
                                        color: Color(0xff3F67FD),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 3),
                                  Text(
                                    'Selected',
                                    style: TextStyle(
                                      color: Colors.grey.shade400,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Container(
                                    width: 14,
                                    height: 14,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade400,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        width: 1.5,
                                        color: Colors.grey.shade400,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 3),
                                  Text(
                                    'Booked',
                                    style: TextStyle(
                                      color: Colors.grey.shade400,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                top: 24,
                left: 16,
                right: 16,
                bottom: 16,
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(35),
                  color: Color(0xff3F67FD),
                ),
                width: double.infinity,
                height: 65,
                child: InkWell(
                  onTap: () async {
                    final appointmentRepository = ref.read(
                      appointmentRepositoryProvider,
                    );
                    final selectedSlotTime =
                        [...morningSlots, ...afternoonSlots]
                            .where((slot) => slot.status == SlotStatus.selected)
                            .map((slot) => slot.time)
                            .cast<String?>()
                            .firstOrNull;

                    try {
                      await appointmentRepository.submitBooking(
                        doctorId: widget.doctorId,
                        userId: SessionRepository().getCurrentUserId(),
                        dateInput: _dateController.text,
                        selectedSlotTime: selectedSlotTime,
                        existingAppointment: widget.existingAppointment,
                        symptoms: widget.symptoms,
                        patientName: widget.patientName,
                        age: widget.age,
                        gender: widget.gender,
                        reports: widget.selectedReports,
                        aiSummaryId: widget.aiSummaryId,
                      );
                      if (!mounted) return;
                    } on StateError catch (error) {
                      if (!mounted) return;
                      final message = error.message.toString();
                      if (message == 'missing_slot') {
                        showAppToast(context, 'Please select a time slot');
                        return;
                      }
                      if (message == 'invalid_date') {
                        showAppToast(
                          context,
                          'Please enter a valid date (dd/MM/yyyy)',
                        );
                        return;
                      }
                      if (message == 'past_date') {
                        showAppToast(context, 'Please select a future time');
                        return;
                      }
                      if (message == 'duplicate_slot') {
                        showAppToast(
                          context,
                          'This time slot was just booked. Please choose another slot.',
                        );
                        return;
                      }
                      if (message == 'missing_user') {
                        showAppToast(context, 'Please log in and try again.');
                        return;
                      }
                      rethrow;
                    }

                    // ✅ Go to Appointments tab (Upcoming by default)
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AppShell(initialTab: 1),
                      ),
                      (route) => route.isFirst,
                    );
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Image.asset(
                          'assets/images/chat.png',
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Book Appointment',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: .w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget timeSlotItem(TimeSlot slot) {
  Color borderColor;
  Color bgColor;
  Color textColor;

  switch (slot.status) {
    case SlotStatus.selected:
      borderColor = const Color(0xFF3F67FD);
      bgColor = const Color(0xFF3F67FD);
      textColor = Colors.white;
      break;
    case SlotStatus.booked:
      borderColor = Colors.grey.shade400;
      bgColor = Colors.transparent;
      textColor = Colors.grey.shade400;
      break;
    default:
      borderColor = const Color(0xFF3F67FD);
      bgColor = Colors.transparent;
      textColor = const Color(0xFF3F67FD);
  }

  return Container(
    height: 45,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: bgColor,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: borderColor, width: 1.5),
    ),
    child: Text(
      slot.time,
      style: TextStyle(
        color: textColor,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
    ),
  );
}
