import 'package:flutter/material.dart';
import 'package:pulsecare/config/app_environment.dart';
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
  }) : _dataSource =
           dataSource ??
           (AppEnvironment.useLocalSeedData
               ? LocalAppointmentDataSource()
               : (throw StateError(
                   'AppointmentDataSource must be injected in production',
                 ))),
       _doctorRepository = doctorRepository,
       _userRepository = userRepository;

  final AppointmentDataSource _dataSource;
  final DoctorRepository _doctorRepository;
  final UserRepository _userRepository;
  static const int _fallbackSlotDurationMinutes = 30;

  String _buildSlotAppointmentId(String doctorId, DateTime dateTime) {
    final y = dateTime.year.toString().padLeft(4, '0');
    final m = dateTime.month.toString().padLeft(2, '0');
    final d = dateTime.day.toString().padLeft(2, '0');
    final hh = dateTime.hour.toString().padLeft(2, '0');
    final mm = dateTime.minute.toString().padLeft(2, '0');
    final dateKey = '$y$m$d';
    final timeSlot = '$hh$mm';
    return '${doctorId}_${dateKey}_${timeSlot}';
  }

  Future<Appointment> _applyAutomaticStatusUpdates(
    Appointment appointment,
  ) async {
    if (appointment.id.isEmpty) {
      return appointment;
    }

    final now = DateTime.now();

    if (appointment.status == AppointmentStatus.pending &&
        appointment.scheduledAt.isBefore(now)) {
      await _dataSource.updateStatusRaw(
        appointment.id,
        appointmentStatusCancelledByTimeout,
      );
      return appointment.copyWith(status: AppointmentStatus.cancelled);
    }

    if (appointment.status == AppointmentStatus.confirmed) {
      final slotDuration = appointment.resolvedDoctor.slotDuration > 0
          ? appointment.resolvedDoctor.slotDuration
          : _fallbackSlotDurationMinutes;
      final endTime = appointment.scheduledAt.add(
        Duration(minutes: slotDuration),
      );

      if (endTime.isBefore(now)) {
        await _dataSource.updateStatusRaw(
          appointment.id,
          appointmentStatusCompletedAuto,
        );
        await _doctorRepository.incrementPatients(appointment.doctorId);
        return appointment.copyWith(status: AppointmentStatus.completed);
      }
    }

    return appointment;
  }

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
      final doctor = await _doctorRepository.getDoctorById(
        appointment.doctorId,
      );
      final hydratedAppointment = doctor == null
          ? appointment
          : appointment.copyWith(doctor: doctor);

      final normalizedAppointment = await _applyAutomaticStatusUpdates(
        hydratedAppointment,
      );

      hydrated.add(normalizedAppointment);
    }
    return hydrated.toList(growable: false);
  }

  Stream<List<Appointment>> watchAppointmentsForUser(String userId) {
    return _dataSource.watchForUser(userId).asyncMap((appointments) async {
      final hydrated = <Appointment>[];
      for (final appointment in appointments) {
        final doctor = await _doctorRepository.getDoctorById(
          appointment.doctorId,
        );
        final hydratedAppointment = doctor == null
            ? appointment
            : appointment.copyWith(doctor: doctor);
        final normalizedAppointment = await _applyAutomaticStatusUpdates(
          hydratedAppointment,
        );
        hydrated.add(normalizedAppointment);
      }
      return hydrated.toList(growable: false);
    });
  }

  Stream<List<Appointment>> watchAppointmentsForDoctor(String doctorId) {
    return _dataSource.watchForDoctor(doctorId).asyncMap((appointments) async {
      final hydrated = <Appointment>[];
      for (final appointment in appointments) {
        final doctor = await _doctorRepository.getDoctorById(
          appointment.doctorId,
        );
        final hydratedAppointment = doctor == null
            ? appointment
            : appointment.copyWith(doctor: doctor);
        final normalizedAppointment = await _applyAutomaticStatusUpdates(
          hydratedAppointment,
        );
        hydrated.add(normalizedAppointment);
      }
      return hydrated.toList(growable: false);
    });
  }

  Future<void> addAppointment(Appointment appointment) async {
    await _dataSource.add(appointment);
    notifyListeners();
  }

  Future<void> submitBooking({
    required String doctorId,
    required String? userId,
    required String dateInput,
    required String? selectedSlotTime,
    Appointment? existingAppointment,
    required String symptoms,
    String patientName = '',
    int age = 0,
    String gender = '',
    List<ReportModel> reports = const [],
    String? aiSummaryId,
  }) async {
    final normalizedUserId = userId?.trim() ?? '';
    if (normalizedUserId.isEmpty) {
      throw StateError('missing_user');
    }

    final normalizedSlotTime = selectedSlotTime?.trim() ?? '';
    if (normalizedSlotTime.isEmpty) {
      throw StateError('missing_slot');
    }

    DateTime appointmentDate;
    try {
      appointmentDate = TimeUtils.parseDateStrict(dateInput.trim());
    } catch (_) {
      throw StateError('invalid_date');
    }

    final normalizedDate = TimeUtils.formatDate(appointmentDate);
    final appointmentDateTime = TimeUtils.parseDateTime(
      normalizedDate,
      normalizedSlotTime,
    );

    if (appointmentDateTime.isBefore(DateTime.now())) {
      throw StateError('past_date');
    }

    if (existingAppointment != null) {
      await rescheduleAppointment(
        appointmentId: existingAppointment.id,
        newDate: appointmentDate,
        newTime: normalizedSlotTime,
      );
      return;
    }

    await createAppointment(
      doctorId: doctorId,
      userId: normalizedUserId,
      dateTime: appointmentDateTime,
      status: AppointmentStatus.pending,
      symptoms: symptoms,
      patientName: patientName,
      age: age,
      gender: gender,
      reports: reports,
      aiSummaryId: aiSummaryId,
    );
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
    if (userId.trim().isEmpty) {
      throw StateError('missing_user');
    }

    if (dateTime.isBefore(DateTime.now())) {
      throw StateError('past_date');
    }

    final slotDocId = _buildSlotAppointmentId(doctorId, dateTime);

    final doctor = await _doctorRepository.getDoctorById(doctorId);

    if (doctor == null) {
      throw StateError('Doctor not found for appointment creation');
    }
    final currentUser = await _userRepository.getUserById(userId);

    final appointment = Appointment(
      id: slotDocId,
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

    await _dataSource.add(appointment);
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

    await _dataSource.update(updated);
    notifyListeners();
  }

  Future<void> removeAppointment(Appointment appointment) async {
    await _dataSource.remove(appointment);
    notifyListeners();
  }

  Future<void> updateAppointment(Appointment updated) async {
    if (await _dataSource.getById(updated.id) != null) {
      await _dataSource.update(updated);
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

    await _dataSource.update(appointment.copyWith(status: newStatus));
    if (currentStatus != AppointmentStatus.completed &&
        newStatus == AppointmentStatus.completed) {
      await _doctorRepository.incrementPatients(appointment.doctorId);
    }
    notifyListeners();
  }
}
