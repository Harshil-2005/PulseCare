import 'package:flutter/material.dart';
import 'package:pulsecare/utils/time_utils.dart';
import 'package:pulsecare/data/datasources/appointment_datasource.dart';
import 'package:pulsecare/model/appointment_model.dart';
import 'package:pulsecare/model/report_model.dart';
import 'package:pulsecare/repositories/doctor_repository.dart';
import 'package:pulsecare/repositories/user_repository.dart';

class AppointmentRepository extends ChangeNotifier {
  AppointmentRepository({
    AppointmentDataSource? dataSource,
    required DoctorRepository doctorRepository,
    required UserRepository userRepository,
  }) : _dataSource = dataSource ?? LocalAppointmentDataSource(),
       _doctorRepository = doctorRepository,
       _userRepository = userRepository;

  final AppointmentDataSource _dataSource;
  final DoctorRepository _doctorRepository;
  final UserRepository _userRepository;

  Future<List<Appointment>> getAppointments({
    String? userId,
    String? doctorId,
  }) async {
    if ((userId == null || userId.isEmpty) &&
        (doctorId == null || doctorId.isEmpty)) {
      throw ArgumentError('Provide userId or doctorId to fetch appointments.');
    }

    if ((userId != null && userId.isNotEmpty) &&
        (doctorId != null && doctorId.isNotEmpty)) {
      throw ArgumentError('Provide either userId or doctorId, not both.');
    }

    final appointments = userId != null && userId.isNotEmpty
        ? await _dataSource.getForUser(userId)
        : await _dataSource.getForDoctor(doctorId!);
    final hydrated = <Appointment>[];
    for (final appointment in appointments) {
      final doctor = await _doctorRepository.getDoctorById(appointment.doctorId);
      if (doctor == null) {
        hydrated.add(appointment);
        continue;
      }
      hydrated.add(appointment.copyWith(doctor: doctor));
    }
    return hydrated.toList(growable: false);
  }

  Stream<List<Appointment>> watchAppointmentsForUser(String userId) {
    return _dataSource.watchForUser(userId).asyncMap((appointments) async {
      final hydrated = <Appointment>[];
      for (final appointment in appointments) {
        final doctor = await _doctorRepository.getDoctorById(appointment.doctorId);
        if (doctor == null) {
          hydrated.add(appointment);
          continue;
        }
        hydrated.add(appointment.copyWith(doctor: doctor));
      }
      return hydrated.toList(growable: false);
    });
  }

  Stream<List<Appointment>> watchAppointmentsForDoctor(String doctorId) {
    return _dataSource.watchForDoctor(doctorId).asyncMap((appointments) async {
      final hydrated = <Appointment>[];
      for (final appointment in appointments) {
        final doctor = await _doctorRepository.getDoctorById(appointment.doctorId);
        if (doctor == null) {
          hydrated.add(appointment);
          continue;
        }
        hydrated.add(appointment.copyWith(doctor: doctor));
      }
      return hydrated.toList(growable: false);
    });
  }

  void addAppointment(Appointment appointment) {
    _dataSource.add(appointment);
    notifyListeners();
  }

  Future<void> createAppointment({
    required String doctorId,
    required String userId,
    required DateTime dateTime,
    required AppointmentStatus status,
    required String symptoms,
    String patientName = '',
    int age = 0,
    String gender = '',
    List<ReportModel> reports = const [],
    String? aiSummaryId,
  }) async {
    if (dateTime.isBefore(DateTime.now())) {
      throw StateError('past_date');
    }

    final appointments = await _dataSource.getForDoctorAt(doctorId, dateTime);
    final hasDuplicate = appointments.any((appointment) {
      return appointment.status != AppointmentStatus.cancelled;
    });

    if (hasDuplicate) {
      throw StateError('duplicate_slot');
    }

    final doctor = await _doctorRepository.getDoctorById(doctorId);

    if (doctor == null) {
      throw StateError('Doctor not found for appointment creation');
    }
    final currentUser = await _userRepository.getUserById(userId);

    final appointment = Appointment(
      userId: userId,
      doctorId: doctorId,
      doctor: doctor,
      patientName: patientName.isNotEmpty
          ? patientName
          : (currentUser?.fullName ?? ''),
      age: age > 0 ? age : (currentUser?.age ?? 0),
      gender: gender.isNotEmpty ? gender : (currentUser?.gender ?? ''),
      scheduledAt: dateTime,
      status: status,
      symptoms: symptoms,
      reports: reports,
      aiSummaryId: aiSummaryId,
    );

    _dataSource.add(appointment);
    notifyListeners();
  }

  Future<void> rescheduleAppointment({
    required String appointmentId,
    required DateTime newDate,
    required String newTime,
  }) async {
    final existing = await _dataSource.getById(appointmentId);
    if (existing == null) {
      throw StateError('Appointment not found');
    }

    final normalizedDate = TimeUtils.formatDate(newDate);
    final newDateTime = TimeUtils.parseDateTime(normalizedDate, newTime);

    if (newDateTime.isBefore(DateTime.now())) {
      throw StateError('past_date');
    }

    final appointments = await _dataSource.getForDoctorAt(
      existing.doctorId,
      newDateTime,
    );
    final hasDuplicate = appointments.any((appointment) {
      if (appointment.id == appointmentId) {
        return false;
      }
      return appointment.status != AppointmentStatus.cancelled;
    });

    if (hasDuplicate) {
      throw StateError('duplicate_slot');
    }

    final updated = existing.copyWith(
      scheduledAt: newDateTime,
      status: AppointmentStatus.pending,
    );

    _dataSource.update(updated);
    notifyListeners();
  }

  void removeAppointment(Appointment appointment) {
    _dataSource.remove(appointment);
    notifyListeners();
  }

  Future<void> updateAppointment(Appointment updated) async {
    if (await _dataSource.getById(updated.id) != null) {
      _dataSource.update(updated);
      notifyListeners();
    }
  }

  Future<void> updateAppointmentStatus(
    String appointmentId,
    AppointmentStatus newStatus,
  ) async {
    final appointment = await _dataSource.getById(appointmentId);
    if (appointment == null) {
      throw StateError('Appointment not found');
    }

    final currentStatus = appointment.status;

    bool isValidTransition = false;

    switch (currentStatus) {
      case AppointmentStatus.pending:
        isValidTransition =
            newStatus == AppointmentStatus.confirmed ||
            newStatus == AppointmentStatus.cancelled;
        break;

      case AppointmentStatus.confirmed:
        isValidTransition =
            newStatus == AppointmentStatus.completed ||
            newStatus == AppointmentStatus.cancelled;
        break;

      case AppointmentStatus.cancelled:
      case AppointmentStatus.completed:
        isValidTransition = false;
        break;
    }

    if (!isValidTransition) {
      throw StateError('Invalid status transition');
    }

    _dataSource.update(appointment.copyWith(status: newStatus));
    if (currentStatus != AppointmentStatus.completed &&
        newStatus == AppointmentStatus.completed) {
      await _doctorRepository.incrementPatients(appointment.doctorId);
    }
    notifyListeners();
  }
}
