class ReportModel {
  final String id;
  final String userId;
  final String? appointmentId;
  final String? doctorId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String title;
  final DateTime uploadedAt;
  final String icon;
  final String? pdfPath;

  ReportModel({
    required this.id,
    required this.userId,
    this.appointmentId,
    this.doctorId,
    this.createdAt,
    this.updatedAt,
    required this.title,
    required this.uploadedAt,
    required this.icon,
    this.pdfPath,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'appointmentId': appointmentId,
      'userId': userId,
      'doctorId': doctorId,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'title': title,
      'uploadedAt': uploadedAt.toIso8601String(),
      'icon': icon,
      'pdfPath': pdfPath,
    };
  }

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    return ReportModel(
      id: (json['id'] ?? '').toString(),
      appointmentId: json['appointmentId']?.toString(),
      userId: (json['userId'] ?? '').toString(),
      doctorId: json['doctorId']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
      title: (json['title'] ?? '').toString(),
      uploadedAt:
          DateTime.tryParse((json['uploadedAt'] ?? '').toString()) ??
          DateTime.now(),
      icon: (json['icon'] ?? '').toString(),
      pdfPath: json['pdfPath'] as String?,
    );
  }
}
