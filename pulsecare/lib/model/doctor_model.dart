import 'package:pulsecare/model/day_schedule.dart';
import 'package:pulsecare/model/date_override.dart';

class Doctor {
  final String id;
  final String userId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String name;
  final String speciality;
  final String address;

  final int experience;
  final double rating;
  final int reviews;
  final int patients;

  final String image;
  final String email;
  final String about;

  final double consultationFee;
  final int slotDuration;
  final bool isAvailableForBooking;

  final List<DaySchedule> schedule;
  final List<DateOverride> overrides;

  Doctor({
    required this.id,
    String? userId,
    this.createdAt,
    this.updatedAt,
    required this.name,
    required this.speciality,
    required this.address,
    required this.experience,
    required this.rating,
    required this.reviews,
    required this.patients,
    required this.image,
    required this.email,
    required this.about,
    required this.consultationFee,
    required this.slotDuration,
    required this.isAvailableForBooking,
    required this.schedule,
    List<DateOverride>? overrides,
  }) : userId = userId ?? '',
       overrides = List.unmodifiable(overrides ?? []);

  Doctor copyWith({
    String? id,
    String? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? name,
    String? speciality,
    String? address,
    int? experience,
    double? rating,
    int? reviews,
    int? patients,
    String? image,
    String? email,
    String? about,
    double? consultationFee,
    int? slotDuration,
    bool? isAvailableForBooking,
    List<DaySchedule>? schedule,
    List<DateOverride>? overrides,
  }) {
    return Doctor(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      name: name ?? this.name,
      speciality: speciality ?? this.speciality,
      address: address ?? this.address,
      experience: experience ?? this.experience,
      rating: rating ?? this.rating,
      reviews: reviews ?? this.reviews,
      patients: patients ?? this.patients,
      image: image ?? this.image,
      email: email ?? this.email,
      about: about ?? this.about,
      consultationFee: consultationFee ?? this.consultationFee,
      slotDuration: slotDuration ?? this.slotDuration,
      isAvailableForBooking:
          isAvailableForBooking ?? this.isAvailableForBooking,
      schedule: schedule ?? this.schedule,
      overrides: overrides ?? this.overrides,
    );
  }

  factory Doctor.fromJson(Map<String, dynamic> json) {
    return Doctor(
      id: json['id'],
      userId: (json['userId'] ?? '').toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
      name: (json['name'] ?? '').toString(),
      speciality: (json['specialization'] ?? json['speciality'] ?? '')
          .toString(),
      address: (json['hospital'] ?? json['address'] ?? '').toString(),
      experience: json['experience'] is int
          ? json['experience'] as int
          : int.tryParse((json['experience'] ?? '').toString()) ?? 0,
      rating: (json['rating'] is num)
          ? (json['rating'] as num).toDouble()
          : 0.0,
      reviews: (json['reviews'] is int) ? json['reviews'] : 0,
      patients: (json['patients'] is int) ? json['patients'] : 0,
      image: (json['image'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      about: (json['about'] ?? '').toString(),
      consultationFee: (json['consultationFee'] as num?)?.toDouble() ?? 0,
      slotDuration: (json['slotDuration'] is int) ? json['slotDuration'] : 15,
      isAvailableForBooking: json['isAvailableForBooking'] ?? true,
      schedule: (json['schedule'] as List<dynamic>? ?? [])
          .map(
            (item) => DaySchedule(
              day: (item['day'] ?? '').toString(),
              morningEnabled: item['morningEnabled'] == true,
              morningStart: (item['morningStart'] ?? '').toString(),
              morningEnd: (item['morningEnd'] ?? '').toString(),
              afternoonEnabled: item['afternoonEnabled'] == true,
              afternoonStart: (item['afternoonStart'] ?? '').toString(),
              afternoonEnd: (item['afternoonEnd'] ?? '').toString(),
            ),
          )
          .toList(),
      overrides: json['overrides'] != null
          ? (json['overrides'] as List)
                .map((o) => DateOverride.fromJson(Map<String, dynamic>.from(o)))
                .toList()
          : <DateOverride>[],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'name': name,
      'specialization': speciality,
      'hospital': address,
      'speciality': speciality,
      'address': address,
      'experience': experience,
      'rating': rating,
      'reviews': reviews,
      'patients': patients,
      'image': image,
      'email': email,
      'about': about,
      'consultationFee': consultationFee,
      'slotDuration': slotDuration,
      'isAvailableForBooking': isAvailableForBooking,
      'schedule': schedule
          .map(
            (day) => {
              'day': day.day,
              'morningEnabled': day.morningEnabled,
              'morningStart': day.morningStart,
              'morningEnd': day.morningEnd,
              'afternoonEnabled': day.afternoonEnabled,
              'afternoonStart': day.afternoonStart,
              'afternoonEnd': day.afternoonEnd,
            },
          )
          .toList(),
      'overrides': overrides.map((o) => o.toJson()).toList(),
    };
  }
}
