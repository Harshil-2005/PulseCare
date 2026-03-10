class DoctorReview {
  final String id;
  final String doctorId;
  final String userId;
  final String appointmentId;
  final double rating;
  final String comment;
  final DateTime? createdAt;

  DoctorReview({
    required this.id,
    required this.doctorId,
    required this.userId,
    required this.appointmentId,
    required this.rating,
    required this.comment,
    this.createdAt,
  });

  DoctorReview copyWith({
    String? id,
    String? doctorId,
    String? userId,
    String? appointmentId,
    double? rating,
    String? comment,
    DateTime? createdAt,
  }) {
    return DoctorReview(
      id: id ?? this.id,
      doctorId: doctorId ?? this.doctorId,
      userId: userId ?? this.userId,
      appointmentId: appointmentId ?? this.appointmentId,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory DoctorReview.fromJson(Map<String, dynamic> json) {
    return DoctorReview(
      id: (json['id'] ?? '').toString(),
      doctorId: (json['doctorId'] ?? '').toString(),
      userId: (json['userId'] ?? '').toString(),
      appointmentId: (json['appointmentId'] ?? '').toString(),
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      comment: (json['comment'] ?? '').toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'doctorId': doctorId,
      'userId': userId,
      'appointmentId': appointmentId,
      'rating': rating,
      'comment': comment,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}
