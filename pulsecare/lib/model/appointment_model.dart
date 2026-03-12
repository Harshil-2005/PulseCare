import 'doctor_model.dart';
import 'package:pulsecare/model/report_model.dart';

enum AppointmentStatus { pending, confirmed, cancelled, completed }

const String appointmentStatusCancelledByTimeout = 'cancelled_by_timeout';
const String appointmentStatusCompletedAuto = 'completed_auto';

class Appointment {
  // Embedded doctor snapshot for display purposes.
  // The authoritative identity of the doctor is doctorId.
  // This snapshot may become stale if the doctor profile updates.
  final Doctor doctor;
  final String patientName;
  final int age;
  final String gender;
  final DateTime scheduledAt;
  final AppointmentStatus status;
  final String id;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String userId;
  final String doctorId;
  final String symptoms;
  final List<ReportModel> reports;
  final String? aiSummaryId;
  final bool reviewSubmitted;

  Appointment({
    required this.doctor,
    required this.patientName,
    required this.age,
    required this.gender,
    required this.scheduledAt,
    required this.status,
    String? id,
    this.createdAt,
    this.updatedAt,
    String? userId,
    String? doctorId,
    String? symptoms,
    List<ReportModel>? reports,
    this.aiSummaryId,
    bool? reviewSubmitted,
  }) : id = id ?? '',
       userId = userId ?? '',
       doctorId = doctorId ?? doctor.id,
       symptoms = symptoms ?? '',
       reports = List.unmodifiable(reports ?? const <ReportModel>[]),
       reviewSubmitted = reviewSubmitted ?? false,
       assert(
         doctor.id == (doctorId ?? doctor.id),
         'Appointment doctor.id must match doctorId',
       );

  // Returns the embedded doctor snapshot.
  // UI code should access doctor information through this getter.
  // In the future this may hydrate doctor data using doctorId.
  Doctor get resolvedDoctor => doctor;

  Appointment copyWith({
    Doctor? doctor,
    String? patientName,
    int? age,
    String? gender,
    DateTime? scheduledAt,
    AppointmentStatus? status,
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? userId,
    String? doctorId,
    String? symptoms,
    List<ReportModel>? reports,
    String? aiSummaryId,
    bool? reviewSubmitted,
  }) {
    return Appointment(
      doctor: doctor ?? this.doctor,
      patientName: patientName ?? this.patientName,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      status: status ?? this.status,
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userId: userId ?? this.userId,
      doctorId: doctorId ?? this.doctorId,
      symptoms: symptoms ?? this.symptoms,
      reports: List.unmodifiable(reports ?? this.reports),
      aiSummaryId: aiSummaryId ?? this.aiSummaryId,
      reviewSubmitted: reviewSubmitted ?? this.reviewSubmitted,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'doctor': doctor.toJson(),
      'patientName': patientName,
      'age': age,
      'gender': gender,
      'scheduledAt': scheduledAt.toIso8601String(),
      'status': status.name,
      'id': id,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'userId': userId,
      'doctorId': doctorId,
      'symptoms': symptoms,
      'reports': reports.map((report) => report.toJson()).toList(),
      'aiSummaryId': aiSummaryId,
      'reviewSubmitted': reviewSubmitted,
    };
  }

  static AppointmentStatus parseStatus(String? rawStatus) {
    final normalized = (rawStatus ?? '').trim().toLowerCase();

    if (normalized == appointmentStatusCancelledByTimeout) {
      return AppointmentStatus.cancelled;
    }
    if (normalized == appointmentStatusCompletedAuto) {
      return AppointmentStatus.completed;
    }

    return AppointmentStatus.values.firstWhere(
      (value) => value.name == normalized,
      orElse: () => AppointmentStatus.pending,
    );
  }

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      doctor: Doctor.fromJson(Map<String, dynamic>.from(json['doctor'] as Map)),
      patientName: json['patientName'],
      age: json['age'],
      gender: json['gender'],
      scheduledAt: DateTime.parse(json['scheduledAt'] as String),
      status: parseStatus(json['status'] as String?),
      id: json['id'],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
      userId: json['userId'],
      doctorId: json['doctorId'],
      symptoms: json['symptoms'],
      reports: (json['reports'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map(
            (report) => ReportModel.fromJson(Map<String, dynamic>.from(report)),
          )
          .toList(),
      aiSummaryId: json['aiSummaryId'],
      reviewSubmitted: json['reviewSubmitted'] == true,
    );
  }
}
