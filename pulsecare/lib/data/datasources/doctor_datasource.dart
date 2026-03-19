import 'dart:async';

import 'package:pulsecare/config/app_environment.dart';
import 'package:pulsecare/model/doctor_model.dart';
import 'package:pulsecare/model/day_schedule.dart';

abstract class DoctorDataSource {
  Future<List<Doctor>> getAll();
  Future<Doctor?> getById(String id);
  Future<Doctor?> getByUserId(String userId);
  Stream<Doctor?> watchById(String id);
  Stream<Doctor?> watchByUserId(String userId);
  Stream<List<Doctor>> watchAll();
  Future<Doctor> createDoctor(Doctor doctor);
  Future<void> update(Doctor doctor);
  Future<void> incrementPatients(String doctorId);
  Future<void> deleteDoctorProfileForUser(String userId);
}

class LocalDoctorDataSource implements DoctorDataSource {
  LocalDoctorDataSource() {
    if (AppEnvironment.isProduction) {
      throw StateError('LocalDoctorDataSource is disabled in production');
    }
  }

  final StreamController<List<Doctor>> _doctorStreamController =
      StreamController<List<Doctor>>.broadcast();
  final List<Doctor> _doctors = [
    Doctor(
      id: '1',
      name: 'Dr. Aarav Mehta',
      speciality: 'Cardiologist',
      address: "Advanced Heart Care, Athwa Gate, Surat",
      experience: 12,
      rating: 4.5,
      reviews: 49,
      image: 'assets/images/Dr1.png',
      email: 'dr.aarav.mehta@pulsecare.com',
      patients: 900,
      about:
          "Dr. Aarav Mehta is a skilled Cardiologist with over 12 years of experience in treating heart-related conditions. He is known for his patient-friendly approach and careful diagnosis, helping patients manage issues like chest pain, breathlessness, and heart health with confidence and care.",
      slotDuration: 30,
      schedule: [
        DaySchedule(
          day: 'Mon',
          morningEnabled: true,
          morningStart: '10:00 AM',
          morningEnd: '1:00 PM',
          afternoonEnabled: false,
          afternoonStart: '',
          afternoonEnd: '',
        ),
        DaySchedule(
          day: 'Tue',
          morningEnabled: true,
          morningStart: '10:00 AM',
          morningEnd: '12:00 PM',
          afternoonEnabled: true,
          afternoonStart: '5:00 PM',
          afternoonEnd: '7:00 PM',
        ),
        DaySchedule(
          day: 'Wed',
          morningEnabled: true,
          morningStart: '10:00 AM',
          morningEnd: '1:00 PM',
          afternoonEnabled: false,
          afternoonStart: '',
          afternoonEnd: '',
        ),
        DaySchedule(
          day: 'Thu',
          morningEnabled: true,
          morningStart: '10:00 AM',
          morningEnd: '12:00 PM',
          afternoonEnabled: true,
          afternoonStart: '5:00 PM',
          afternoonEnd: '7:00 PM',
        ),
        DaySchedule(
          day: 'Fri',
          morningEnabled: true,
          morningStart: '10:00 AM',
          morningEnd: '1:00 PM',
          afternoonEnabled: false,
          afternoonStart: '',
          afternoonEnd: '',
        ),
        DaySchedule(
          day: 'Sat',
          morningEnabled: true,
          morningStart: '10:00 AM',
          morningEnd: '1:00 PM',
          afternoonEnabled: false,
          afternoonStart: '',
          afternoonEnd: '',
        ),
        DaySchedule(
          day: 'Sun',
          morningEnabled: false,
          morningStart: '',
          morningEnd: '',
          afternoonEnabled: false,
          afternoonStart: '',
          afternoonEnd: '',
        ),
      ],
      consultationFee: 800.0,
      isAvailableForBooking: true,
    ),
    Doctor(
      id: '2',
      name: 'Dr. Neha Patel',
      speciality: 'Gynecologist',
      address: "Sunrise Women's Clinic, Vesu, Surat",
      experience: 9,
      rating: 4.0,
      reviews: 149,
      image: 'assets/images/Dr2.png',
      email: 'dr.neha.patel@pulsecare.com',
      patients: 650,
      about:
          "Dr. Neha Patel is a highly experienced Gynecologist with over 9 years of dedicated practice in women's healthcare. She specializes in preventive care, pregnancy management, menstrual health disorders, PCOS treatment, and hormonal balance therapies. Dr. Patel is known for her compassionate approach, ensuring that every patient feels comfortable discussing sensitive health concerns. ",
      slotDuration: 20,
      schedule: [
        DaySchedule(
          day: 'Mon',
          morningEnabled: true,
          morningStart: '10:00 AM',
          morningEnd: '1:00 PM',
          afternoonEnabled: false,
          afternoonStart: '',
          afternoonEnd: '',
        ),
        DaySchedule(
          day: 'Tue',
          morningEnabled: true,
          morningStart: '10:00 AM',
          morningEnd: '12:00 PM',
          afternoonEnabled: true,
          afternoonStart: '5:00 PM',
          afternoonEnd: '7:00 PM',
        ),
        DaySchedule(
          day: 'Wed',
          morningEnabled: false,
          morningStart: '',
          morningEnd: '',
          afternoonEnabled: false,
          afternoonStart: '',
          afternoonEnd: '',
        ),
        DaySchedule(
          day: 'Thu',
          morningEnabled: true,
          morningStart: '10:00 AM',
          morningEnd: '12:00 PM',
          afternoonEnabled: true,
          afternoonStart: '5:00 PM',
          afternoonEnd: '7:00 PM',
        ),
        DaySchedule(
          day: 'Fri',
          morningEnabled: true,
          morningStart: '10:00 AM',
          morningEnd: '1:00 PM',
          afternoonEnabled: false,
          afternoonStart: '',
          afternoonEnd: '',
        ),
        DaySchedule(
          day: 'Sat',
          morningEnabled: true,
          morningStart: '10:00 AM',
          morningEnd: '1:00 PM',
          afternoonEnabled: false,
          afternoonStart: '',
          afternoonEnd: '',
        ),
        DaySchedule(
          day: 'Sun',
          morningEnabled: false,
          morningStart: '',
          morningEnd: '',
          afternoonEnabled: false,
          afternoonStart: '',
          afternoonEnd: '',
        ),
      ],
      consultationFee: 600.0,
      isAvailableForBooking: true,
    ),
    Doctor(
      id: '3',
      name: 'Dr. Rohan Shah',
      speciality: 'Orthopedic Surgeon',
      address: "Sunrise Women's Clinic, Vesu, Surat",
      experience: 15,
      rating: 4.9,
      reviews: 1069,
      image: 'assets/images/Dr3.png',
      email: 'dr.rohan.shah@pulsecare.com',
      patients: 1200,
      about:
          " Dr. Rohan Shah is known for his precision in diagnosis and his structured rehabilitation-focused treatment plans. He emphasizes non-surgical treatment whenever possible and carefully evaluates each patient before recommending surgical intervention. His goal is to restore mobility, reduce pain, and improve overall quality of life. ",
      slotDuration: 15,
      schedule: [
        DaySchedule(
          day: 'Mon',
          morningEnabled: true,
          morningStart: '10:00 AM',
          morningEnd: '1:00 PM',
          afternoonEnabled: false,
          afternoonStart: '',
          afternoonEnd: '',
        ),
        DaySchedule(
          day: 'Tue',
          morningEnabled: true,
          morningStart: '10:00 AM',
          morningEnd: '12:00 PM',
          afternoonEnabled: true,
          afternoonStart: '5:00 PM',
          afternoonEnd: '7:00 PM',
        ),
        DaySchedule(
          day: 'Wed',
          morningEnabled: true,
          morningStart: '10:00 AM',
          morningEnd: '1:00 PM',
          afternoonEnabled: false,
          afternoonStart: '',
          afternoonEnd: '',
        ),
        DaySchedule(
          day: 'Thu',
          morningEnabled: true,
          morningStart: '10:00 AM',
          morningEnd: '12:00 PM',
          afternoonEnabled: true,
          afternoonStart: '5:00 PM',
          afternoonEnd: '7:00 PM',
        ),
        DaySchedule(
          day: 'Fri',
          morningEnabled: true,
          morningStart: '10:00 AM',
          morningEnd: '1:00 PM',
          afternoonEnabled: false,
          afternoonStart: '',
          afternoonEnd: '',
        ),
        DaySchedule(
          day: 'Sat',
          morningEnabled: false,
          morningStart: '',
          morningEnd: '',
          afternoonEnabled: false,
          afternoonStart: '',
          afternoonEnd: '',
        ),
        DaySchedule(
          day: 'Sun',
          morningEnabled: false,
          morningStart: '',
          morningEnd: '',
          afternoonEnabled: false,
          afternoonStart: '',
          afternoonEnd: '',
        ),
      ],
      consultationFee: 1000.0,
      isAvailableForBooking: true,
    ),
  ];

  @override
  Future<List<Doctor>> getAll() async => List.unmodifiable(_doctors);

  @override
  Future<Doctor?> getById(String id) async {
    try {
      return _doctors.firstWhere((doctor) => doctor.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Doctor?> getByUserId(String userId) async {
    try {
      return _doctors.firstWhere((doctor) => doctor.userId == userId);
    } catch (_) {
      return null;
    }
  }

  @override
  Stream<Doctor?> watchById(String id) async* {
    yield await getById(id);
  }

  @override
  Stream<Doctor?> watchByUserId(String userId) async* {
    yield await getByUserId(userId);
  }

  @override
  Stream<List<Doctor>> watchAll() async* {
    _doctorStreamController.add(List.unmodifiable(_doctors));
    yield* _doctorStreamController.stream;
  }

  @override
  Future<Doctor> createDoctor(Doctor doctor) async {
    _doctors.add(doctor);
    _doctorStreamController.add(List.unmodifiable(_doctors));
    return doctor;
  }

  @override
  Future<void> update(Doctor doctor) async {
    final index = _doctors.indexWhere((d) => d.id == doctor.id);
    if (index != -1) {
      _doctors[index] = doctor;
      _doctorStreamController.add(List.unmodifiable(_doctors));
    }
  }

  @override
  Future<void> incrementPatients(String doctorId) async {
    final index = _doctors.indexWhere((doctor) => doctor.id == doctorId);
    if (index == -1) return;
    final current = _doctors[index];
    _doctors[index] = current.copyWith(patients: current.patients + 1);
    _doctorStreamController.add(List.unmodifiable(_doctors));
  }

  @override
  Future<void> deleteDoctorProfileForUser(String userId) async {
    _doctors.removeWhere((doctor) => doctor.userId == userId);
    _doctorStreamController.add(List.unmodifiable(_doctors));
  }
}
