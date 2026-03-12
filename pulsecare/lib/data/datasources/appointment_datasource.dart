import 'package:pulsecare/model/appointment_model.dart';
import 'package:pulsecare/model/doctor_model.dart';

abstract class AppointmentDataSource {
  Future<List<Appointment>> getAll();
  Future<List<Appointment>> getForUser(String userId);
  Future<List<Appointment>> getForDoctor(String doctorId);
  Future<List<Appointment>> getForDoctorAt(
    String doctorId,
    DateTime scheduledAt,
  );
  Future<Appointment?> getById(String id);
  Stream<List<Appointment>> watchForUser(String userId);
  Stream<List<Appointment>> watchForDoctor(String doctorId);
  Future<void> add(Appointment appointment);
  Future<void> update(Appointment appointment);
  Future<void> updateStatusRaw(String appointmentId, String rawStatus);
  Future<void> remove(Appointment appointment);
}

class LocalAppointmentDataSource implements AppointmentDataSource {
  LocalAppointmentDataSource();

  static Doctor _seedDoctor(String id) {
    return Doctor(
      id: id,
      name: '',
      speciality: '',
      address: '',
      experience: 0,
      rating: 0,
      reviews: 0,
      patients: 0,
      image: '',
      email: '',
      about: '',
      consultationFee: 0.0,
      slotDuration: 30,
      isAvailableForBooking: true,
      schedule: const [],
    );
  }

  final List<Appointment> _appointments = [
    Appointment(
      doctorId: '1',
      doctor: _seedDoctor('1'),
      patientName: "Harshil",
      age: 23,
      gender: "Male",
      scheduledAt: DateTime(2026, 3, 12, 9, 0),
      status: AppointmentStatus.completed,
    ),
    Appointment(
      doctorId: '2',
      doctor: _seedDoctor('2'),
      patientName: "Harshil",
      age: 23,
      gender: "Male",
      scheduledAt: DateTime(2026, 3, 10, 14, 0),
      status: AppointmentStatus.cancelled,
    ),
    Appointment(
      doctorId: '2',
      doctor: _seedDoctor('2'),
      patientName: "Harshil",
      age: 23,
      gender: "Male",
      scheduledAt: DateTime(2026, 3, 14, 11, 0),
      status: AppointmentStatus.confirmed,
    ),
    Appointment(
      id: "seed_confirmed_u1",
      userId: "u1",
      doctorId: '1',
      doctor: _seedDoctor('1'),
      patientName: "Isha Patel",
      age: 34,
      gender: "Female",
      scheduledAt: DateTime(2026, 3, 15, 10, 30),
      symptoms: "Follow-up consultation",
      status: AppointmentStatus.confirmed,
    ),
    Appointment(
      id: "seed_completed_u1",
      userId: "u1",
      doctorId: '2',
      doctor: _seedDoctor('2'),
      patientName: "Isha Patel",
      age: 34,
      gender: "Female",
      scheduledAt: DateTime(2026, 3, 9, 15, 0),
      symptoms: "Routine check completed",
      status: AppointmentStatus.completed,
    ),
    Appointment(
      id: "seed_cancelled_u1",
      userId: "u1",
      doctorId: '1',
      doctor: _seedDoctor('1'),
      patientName: "Isha Patel",
      age: 34,
      gender: "Female",
      scheduledAt: DateTime(2026, 3, 8, 12, 0),
      symptoms: "Appointment cancelled by patient",
      status: AppointmentStatus.cancelled,
    ),
  ];

  @override
  Future<List<Appointment>> getAll() async => List.unmodifiable(_appointments);

  @override
  Future<List<Appointment>> getForUser(String userId) async {
    return _appointments
        .where((appointment) => appointment.userId == userId)
        .toList(growable: false);
  }

  @override
  Future<List<Appointment>> getForDoctor(String doctorId) async {
    return _appointments
        .where((appointment) => appointment.doctorId == doctorId)
        .toList(growable: false);
  }

  @override
  Future<List<Appointment>> getForDoctorAt(
    String doctorId,
    DateTime scheduledAt,
  ) async {
    return _appointments
        .where(
          (appointment) =>
              appointment.doctorId == doctorId &&
              appointment.scheduledAt.year == scheduledAt.year &&
              appointment.scheduledAt.month == scheduledAt.month &&
              appointment.scheduledAt.day == scheduledAt.day &&
              appointment.scheduledAt.hour == scheduledAt.hour &&
              appointment.scheduledAt.minute == scheduledAt.minute,
        )
        .toList(growable: false);
  }

  @override
  Future<Appointment?> getById(String id) async {
    try {
      return _appointments.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Stream<List<Appointment>> watchForUser(String userId) async* {
    yield _appointments
        .where((appointment) => appointment.userId == userId)
        .toList(growable: false);
  }

  @override
  Stream<List<Appointment>> watchForDoctor(String doctorId) async* {
    yield _appointments
        .where((appointment) => appointment.doctorId == doctorId)
        .toList(growable: false);
  }

  @override
  Future<void> add(Appointment appointment) async {
    final generatedAppointment = appointment.copyWith(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
    );
    _appointments.add(generatedAppointment);
  }

  @override
  Future<void> update(Appointment appointment) async {
    final index = _appointments.indexWhere((a) => a.id == appointment.id);
    if (index != -1) {
      _appointments[index] = appointment;
    }
  }

  @override
  Future<void> updateStatusRaw(String appointmentId, String rawStatus) async {
    final index = _appointments.indexWhere((a) => a.id == appointmentId);
    if (index == -1) return;
    final status = Appointment.parseStatus(rawStatus);
    _appointments[index] = _appointments[index].copyWith(status: status);
  }

  @override
  Future<void> remove(Appointment appointment) async {
    _appointments.remove(appointment);
  }
}
