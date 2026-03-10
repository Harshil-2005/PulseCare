class DoctorAvailability {
  final bool morningEnabled;
  final String morningStart;
  final String morningEnd;
  final bool afternoonEnabled;
  final String afternoonStart;
  final String afternoonEnd;

  const DoctorAvailability({
    required this.morningEnabled,
    required this.morningStart,
    required this.morningEnd,
    required this.afternoonEnabled,
    required this.afternoonStart,
    required this.afternoonEnd,
  });

  factory DoctorAvailability.fromJson(Map<String, dynamic> json) {
    return DoctorAvailability(
      morningEnabled: json['morningEnabled'] ?? false,
      morningStart: json['morningStart'] ?? '',
      morningEnd: json['morningEnd'] ?? '',
      afternoonEnabled: json['afternoonEnabled'] ?? false,
      afternoonStart: json['afternoonStart'] ?? '',
      afternoonEnd: json['afternoonEnd'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'morningEnabled': morningEnabled,
      'morningStart': morningStart,
      'morningEnd': morningEnd,
      'afternoonEnabled': afternoonEnabled,
      'afternoonStart': afternoonStart,
      'afternoonEnd': afternoonEnd,
    };
  }
}

enum SlotStatus { available, selected, booked }

class TimeSlot {
  final String time;
  final SlotStatus status;

  TimeSlot({required this.time, required this.status});

  TimeSlot copyWith({
    String? time,
    SlotStatus? status,
  }) {
    return TimeSlot(
      time: time ?? this.time,
      status: status ?? this.status,
    );
  }
}

class AvailabilitySlotsResult {
  final bool isAvailable;
  final List<TimeSlot> morningSlots;
  final List<TimeSlot> afternoonSlots;

  const AvailabilitySlotsResult({
    required this.isAvailable,
    required this.morningSlots,
    required this.afternoonSlots,
  });
}
