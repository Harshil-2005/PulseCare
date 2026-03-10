class DaySchedule {
  final String? id;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String day;
  final bool morningEnabled;
  final String morningStart;
  final String morningEnd;
  final bool afternoonEnabled;
  final String afternoonStart;
  final String afternoonEnd;

  DaySchedule({
    this.id,
    this.createdAt,
    this.updatedAt,
    required this.day,
    required this.morningEnabled,
    required this.morningStart,
    required this.morningEnd,
    required this.afternoonEnabled,
    required this.afternoonStart,
    required this.afternoonEnd,
  });

  DaySchedule copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? morningEnabled,
    String? morningStart,
    String? morningEnd,
    bool? afternoonEnabled,
    String? afternoonStart,
    String? afternoonEnd,
  }) {
    return DaySchedule(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      day: day,
      morningEnabled: morningEnabled ?? this.morningEnabled,
      morningStart: morningStart ?? this.morningStart,
      morningEnd: morningEnd ?? this.morningEnd,
      afternoonEnabled: afternoonEnabled ?? this.afternoonEnabled,
      afternoonStart: afternoonStart ?? this.afternoonStart,
      afternoonEnd: afternoonEnd ?? this.afternoonEnd,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'day': day,
      'morningEnabled': morningEnabled,
      'morningStart': morningStart,
      'morningEnd': morningEnd,
      'afternoonEnabled': afternoonEnabled,
      'afternoonStart': afternoonStart,
      'afternoonEnd': afternoonEnd,
    };
  }

  factory DaySchedule.fromJson(Map<String, dynamic> json) {
    return DaySchedule(
      id: json['id']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
      day: json['day'] as String? ?? '',
      morningEnabled: json['morningEnabled'] as bool? ?? false,
      morningStart: json['morningStart'] as String? ?? '',
      morningEnd: json['morningEnd'] as String? ?? '',
      afternoonEnabled: json['afternoonEnabled'] as bool? ?? false,
      afternoonStart: json['afternoonStart'] as String? ?? '',
      afternoonEnd: json['afternoonEnd'] as String? ?? '',
    );
  }

  int _parseTimeToMinutes(String time) {
    final regex = RegExp(r'^(\d{1,2}):(\d{2})\s?(AM|PM)$');
    final match = regex.firstMatch(time.trim());
    if (match == null) {
      throw FormatException('Invalid time format: $time');
    }

    int hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    final period = match.group(3)!;

    if (period == 'PM' && hour != 12) {
      hour += 12;
    }
    if (period == 'AM' && hour == 12) {
      hour = 0;
    }

    return hour * 60 + minute;
  }

  int get morningStartMinutes =>
      morningEnabled ? _parseTimeToMinutes(morningStart) : 0;

  int get morningEndMinutes =>
      morningEnabled ? _parseTimeToMinutes(morningEnd) : 0;

  int get afternoonStartMinutes =>
      afternoonEnabled ? _parseTimeToMinutes(afternoonStart) : 0;

  int get afternoonEndMinutes =>
      afternoonEnabled ? _parseTimeToMinutes(afternoonEnd) : 0;
}
