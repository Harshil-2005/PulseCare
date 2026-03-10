import 'package:pulsecare/model/day_schedule.dart';

class DateOverride {
  final String? id;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime startDate;
  final DateTime endDate;
  final DaySchedule? customSchedule;

  const DateOverride({
    this.id,
    this.createdAt,
    this.updatedAt,
    required this.startDate,
    required this.endDate,
    this.customSchedule,
  });

  bool appliesTo(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);

    return !normalized.isBefore(start) && !normalized.isAfter(end);
  }

  bool get isFullDayLeave => customSchedule == null;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'customSchedule': customSchedule == null
          ? null
          : {
              'day': customSchedule!.day,
              'morningEnabled': customSchedule!.morningEnabled,
              'morningStart': customSchedule!.morningStart,
              'morningEnd': customSchedule!.morningEnd,
              'afternoonEnabled': customSchedule!.afternoonEnabled,
              'afternoonStart': customSchedule!.afternoonStart,
              'afternoonEnd': customSchedule!.afternoonEnd,
            },
    };
  }

  factory DateOverride.fromJson(Map<String, dynamic> json) {
    final rawCustom = json['customSchedule'];
    return DateOverride(
      id: json['id']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      customSchedule: rawCustom != null
          ? DaySchedule(
              day: (rawCustom['day'] ?? '').toString(),
              morningEnabled: rawCustom['morningEnabled'] == true,
              morningStart: (rawCustom['morningStart'] ?? '').toString(),
              morningEnd: (rawCustom['morningEnd'] ?? '').toString(),
              afternoonEnabled: rawCustom['afternoonEnabled'] == true,
              afternoonStart: (rawCustom['afternoonStart'] ?? '').toString(),
              afternoonEnd: (rawCustom['afternoonEnd'] ?? '').toString(),
            )
          : null,
    );
  }
}
