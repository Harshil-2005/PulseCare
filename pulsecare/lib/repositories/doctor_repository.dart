import 'package:flutter/material.dart';
import 'package:pulsecare/data/datasources/doctor_datasource.dart';
import 'package:pulsecare/model/day_schedule.dart';
import 'package:pulsecare/model/date_override.dart';
import 'package:pulsecare/model/doctor_model.dart';

class DoctorRepository extends ChangeNotifier {
  DoctorRepository(this._dataSource);

  final DoctorDataSource _dataSource;

  Future<Doctor?> getDoctorById(String id) async {
    return await _dataSource.getById(id);
  }

  Future<Doctor?> getDoctorByUserId(String userId) async {
    return await _dataSource.getByUserId(userId);
  }

  Future<List<Doctor>> getAllDoctors() async {
    return await _dataSource.getAll();
  }

  Stream<Doctor?> watchDoctorById(String id) {
    return _dataSource.watchById(id);
  }

  Stream<Doctor?> watchDoctorByUserId(String userId) {
    return _dataSource.watchByUserId(userId);
  }

  Stream<List<Doctor>> watchAllDoctors() {
    return _dataSource.watchAll();
  }

  Future<Doctor> createDoctor(Doctor doctor) async {
    final created = await _dataSource.createDoctor(doctor);
    notifyListeners();
    return created;
  }

  Future<void> updateDoctor(Doctor updatedDoctor) async {
    if (await _dataSource.getById(updatedDoctor.id) != null) {
      final normalizedDoctor = updatedDoctor.copyWith(
        schedule: updatedDoctor.schedule
            .map(
              (day) => DaySchedule(
                day: _normalizeDayKey(day.day),
                morningEnabled: day.morningEnabled,
                morningStart: day.morningStart,
                morningEnd: day.morningEnd,
                afternoonEnabled: day.afternoonEnabled,
                afternoonStart: day.afternoonStart,
                afternoonEnd: day.afternoonEnd,
              ),
            )
            .toList(),
      );
      _dataSource.update(normalizedDoctor);
      notifyListeners();
    }
  }

  Future<void> incrementPatients(String doctorId) async {
    await _dataSource.incrementPatients(doctorId);
    notifyListeners();
  }

  Future<void> deleteDoctorProfileForUser(String userId) async {
    await _dataSource.deleteDoctorProfileForUser(userId);
    notifyListeners();
  }

  Future<void> addOverride({
    required String doctorId,
    required DateOverride override,
  }) async {
    final doctor = await _dataSource.getById(doctorId);
    if (doctor == null) return;

    final newStart = DateUtils.dateOnly(override.startDate);
    final newEnd = DateUtils.dateOnly(override.endDate);

    for (final existing in doctor.overrides) {
      final existingStart = DateUtils.dateOnly(existing.startDate);
      final existingEnd = DateUtils.dateOnly(existing.endDate);
      final overlaps =
          !newStart.isAfter(existingEnd) && !newEnd.isBefore(existingStart);
      if (overlaps) {
        throw StateError('overlapping_override');
      }
    }

    final updatedOverrides = List<DateOverride>.from(doctor.overrides);
    updatedOverrides.add(override);

    final updatedDoctor = doctor.copyWith(overrides: updatedOverrides);
    _dataSource.update(updatedDoctor);
    notifyListeners();
  }

  Future<void> removeOverride({
    required String doctorId,
    required DateTime date,
  }) async {
    final doctor = await _dataSource.getById(doctorId);
    if (doctor == null) return;

    final updatedOverrides = doctor.overrides
        .where((item) => !item.appliesTo(date))
        .toList();
    final updatedDoctor = doctor.copyWith(overrides: updatedOverrides);
    _dataSource.update(updatedDoctor);
    notifyListeners();
  }

  String _normalizeDayKey(String day) {
    switch (day.trim()) {
      case 'Monday':
        return 'Mon';
      case 'Tuesday':
        return 'Tue';
      case 'Wednesday':
        return 'Wed';
      case 'Thursday':
        return 'Thu';
      case 'Friday':
        return 'Fri';
      case 'Saturday':
        return 'Sat';
      case 'Sunday':
        return 'Sun';
      default:
        return day;
    }
  }

  DaySchedule createEditableSchedule(DaySchedule day, int slotDuration) {
    var editedDay = day.copyWith();

    if (!editedDay.morningEnabled && !editedDay.afternoonEnabled) {
      editedDay = editedDay.copyWith(
        morningEnabled: true,
        afternoonEnabled: true,
        morningStart: _snapAndFormatDefault('9:00 AM', slotDuration),
        morningEnd: _snapAndFormatDefault('12:00 PM', slotDuration),
        afternoonStart: _snapAndFormatDefault('2:00 PM', slotDuration),
        afternoonEnd: _snapAndFormatDefault('6:00 PM', slotDuration),
      );
    }

    return editedDay;
  }

  List<DaySchedule> updateScheduleDay({
    required List<DaySchedule> schedule,
    required DaySchedule updatedDay,
  }) {
    return schedule.map((day) {
      if (day.day == updatedDay.day) {
        return updatedDay;
      }
      return day;
    }).toList();
  }

  String _snapAndFormatDefault(String text, int slotDuration) {
    final parsed = _parseTime(text);
    if (parsed == null) return text;
    final minutes = _timeToMinutes(parsed);
    final snappedMinutes = (minutes / slotDuration).ceil() * slotDuration;
    final hour = snappedMinutes ~/ 60;
    final minute = snappedMinutes % 60;
    return _formatTime(TimeOfDay(hour: hour, minute: minute));
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


  String _formatTime(TimeOfDay value) {
    final hour = value.hourOfPeriod == 0 ? 12 : value.hourOfPeriod;
    final minute = value.minute.toString().padLeft(2, '0');
    final period = value.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }
}
