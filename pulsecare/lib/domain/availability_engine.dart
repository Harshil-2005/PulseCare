import 'package:pulsecare/model/appointment_model.dart';
import 'package:pulsecare/model/date_override.dart';
import 'package:pulsecare/model/day_schedule.dart';
import 'package:pulsecare/model/doctor_availability.dart';
import 'package:pulsecare/model/doctor_model.dart';

class AvailabilityEngine {
  List<Map<String, dynamic>> generateSlots({
    required Doctor doctor,
    required DateTime date,
    required List<Appointment> appointments,
  }) {
    if (!doctor.isAvailableForBooking) {
      return const <Map<String, dynamic>>[];
    }

    final shortDay = _shortWeekdayKey(date);
    final override = _matchingOverride(doctor, date);
    if (override != null && override.isFullDayLeave) {
      return const <Map<String, dynamic>>[];
    }

    DaySchedule? daySchedule;
    if (override != null && override.customSchedule != null) {
      daySchedule = override.customSchedule;
    } else {
      try {
        daySchedule = doctor.schedule.firstWhere((d) => d.day == shortDay);
      } catch (_) {
        daySchedule = null;
      }
    }

    if (daySchedule == null) {
      return const <Map<String, dynamic>>[];
    }

    final morningEnabled = daySchedule.morningEnabled;
    final afternoonEnabled = daySchedule.afternoonEnabled;
    final generated = <Map<String, dynamic>>[];

    if (morningEnabled) {
      final morningTimes = _generateSlots(
        startTime: daySchedule.morningStart,
        endTime: daySchedule.morningEnd,
        slotDuration: doctor.slotDuration,
      );
      for (final slot in morningTimes) {
        final slotDateTime = _slotDateTime(date, slot);
        generated.add({
          'period': 'morning',
          'time': slot,
          'status': _isBooked(slotDateTime, appointments, doctor.id)
              ? SlotStatus.booked
              : SlotStatus.available,
        });
      }
    }

    if (afternoonEnabled) {
      final afternoonTimes = _generateSlots(
        startTime: daySchedule.afternoonStart,
        endTime: daySchedule.afternoonEnd,
        slotDuration: doctor.slotDuration,
      );
      for (final slot in afternoonTimes) {
        final slotDateTime = _slotDateTime(date, slot);
        generated.add({
          'period': 'afternoon',
          'time': slot,
          'status': _isBooked(slotDateTime, appointments, doctor.id)
              ? SlotStatus.booked
              : SlotStatus.available,
        });
      }
    }

    if ((!morningEnabled && !afternoonEnabled) || generated.isEmpty) {
      return const <Map<String, dynamic>>[];
    }

    return generated;
  }

  DateOverride? _matchingOverride(Doctor doctor, DateTime date) {
    for (final override in doctor.overrides) {
      if (override.appliesTo(date)) {
        return override;
      }
    }
    return null;
  }

  String _shortWeekdayKey(DateTime date) {
    const keys = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return keys[date.weekday - 1];
  }

  TimeSlot? _parseTimeSlot(String value) {
    final match = RegExp(
      r'^(0?[1-9]|1[0-2]):([0-5][0-9])\s?(AM|PM)$',
      caseSensitive: false,
    ).firstMatch(value.trim());
    if (match == null) return null;

    final hour12 = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    final period = match.group(3)!.toUpperCase();

    final base = hour12 == 12 ? 0 : hour12;
    final hour24 = period == 'PM' ? base + 12 : base;
    return TimeSlot(
      time:
          '${hour24.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
      status: SlotStatus.available,
    );
  }

  int _toMinutes(TimeSlot time) {
    final parts = time.time.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  int _toMinutesFromString(String time) {
    final parsed = _parseTimeSlot(time);
    if (parsed == null) {
      throw FormatException('Invalid time format: $time');
    }
    return _toMinutes(parsed);
  }

  String _minutesToFormattedTime(int totalMinutes) {
    final normalized = ((totalMinutes % (24 * 60)) + (24 * 60)) % (24 * 60);
    final hour24 = normalized ~/ 60;
    final minute = normalized % 60;

    final period = hour24 >= 12 ? 'PM' : 'AM';
    var hour12 = hour24 % 12;
    if (hour12 == 0) hour12 = 12;

    final minuteStr = minute.toString().padLeft(2, '0');
    return '$hour12:$minuteStr $period';
  }

  List<String> _generateSlots({
    required String startTime,
    required String endTime,
    required int slotDuration,
  }) {
    if (slotDuration <= 0) return [];

    final start = _parseTimeSlot(startTime);
    final end = _parseTimeSlot(endTime);
    if (start == null || end == null) return [];

    final normalizedStart = _minutesToFormattedTime(_toMinutes(start));
    final normalizedEnd = _minutesToFormattedTime(_toMinutes(end));
    final isMorning = normalizedStart.endsWith('AM');
    final daySchedule = DaySchedule(
      day: '',
      morningEnabled: true,
      morningStart: normalizedStart,
      morningEnd: normalizedEnd,
      afternoonEnabled: true,
      afternoonStart: normalizedStart,
      afternoonEnd: normalizedEnd,
    );

    final startMinutes = isMorning
        ? daySchedule.morningStartMinutes
        : daySchedule.afternoonStartMinutes;

    final endMinutes = isMorning
        ? daySchedule.morningEndMinutes
        : daySchedule.afternoonEndMinutes;
    if (endMinutes <= startMinutes) return [];

    final slots = <String>[];
    var current = startMinutes;
    while (current + slotDuration <= endMinutes) {
      slots.add(_minutesToFormattedTime(current));
      current += slotDuration;
    }
    return slots;
  }

  DateTime _slotDateTime(DateTime date, String slotTime) {
    int minutes;
    try {
      minutes = _toMinutesFromString(slotTime);
    } catch (_) {
      return DateTime(date.year, date.month, date.day);
    }

    final hour = minutes ~/ 60;
    final minute = minutes % 60;
    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  bool _isBooked(DateTime slot, List<Appointment> appointments, String doctorId) {
    return appointments.any(
      (appointment) =>
          appointment.doctorId == doctorId &&
          appointment.status != AppointmentStatus.cancelled &&
          appointment.scheduledAt.year == slot.year &&
          appointment.scheduledAt.month == slot.month &&
          appointment.scheduledAt.day == slot.day &&
          appointment.scheduledAt.hour == slot.hour &&
          appointment.scheduledAt.minute == slot.minute,
    );
  }
}
