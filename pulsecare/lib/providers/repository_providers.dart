import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulsecare/controllers/ai_controller.dart';
import 'package:pulsecare/controllers/appointment_controller.dart';
import 'package:pulsecare/controllers/auth_controller.dart';
import 'package:pulsecare/controllers/report_controller.dart';
import 'package:pulsecare/config/app_environment.dart';

import '../data/datasources/appointment_datasource.dart';
import '../data/datasources/availability_datasource.dart';
import '../data/datasources/auth_datasource.dart';
import '../data/datasources/api/api_chat_datasource.dart';
import '../data/datasources/chat_datasource.dart';
import '../data/datasources/doctor_datasource.dart';
import '../data/datasources/doctor_review_datasource.dart';
import '../data/datasources/firebase/firebase_appointment_datasource.dart';
import '../data/datasources/firebase/firebase_auth_datasource.dart';
import '../data/datasources/firebase/firebase_doctor_datasource.dart';
import '../data/datasources/firebase/firebase_doctor_review_datasource.dart';
import '../data/datasources/firebase/firebase_report_datasource.dart';
import '../data/datasources/firebase/firebase_user_datasource.dart';
import '../data/datasources/report_datasource.dart';
import '../data/datasources/user_datasource.dart';
import '../repositories/auth_repository.dart';
import '../repositories/doctor_repository.dart';
import '../repositories/doctor_review_repository.dart';
import '../repositories/appointment_repository.dart';
import '../repositories/chat_repository.dart';
import '../repositories/profile_image_repository.dart';
import '../repositories/user_repository.dart';
import '../repositories/report_repository.dart';
import '../repositories/availability_repository.dart';
import '../repositories/ai_summary_repository.dart';
import '../services/ai_service.dart';

final bool isDev = kDebugMode;

final doctorDatasourceProvider = Provider<DoctorDataSource>(
  (ref) => AppEnvironment.useLocalSeedData
      ? LocalDoctorDataSource()
      : FirebaseDoctorDataSource(),
);

final doctorReviewDatasourceProvider = Provider<DoctorReviewDataSource>(
  (ref) => FirebaseDoctorReviewDataSource(),
);

final appointmentDatasourceProvider = Provider<AppointmentDataSource>(
  (ref) => AppEnvironment.useLocalSeedData
      ? LocalAppointmentDataSource()
      : FirebaseAppointmentDataSource(),
);

final userDatasourceProvider = Provider<UserDataSource>(
  (ref) => AppEnvironment.useLocalSeedData
      ? LocalUserDataSource()
      : FirebaseUserDataSource(),
);

final reportDatasourceProvider = Provider<ReportDataSource>(
  (ref) => AppEnvironment.useLocalSeedData
      ? LocalReportDataSource()
      : FirebaseReportDataSource(),
);

final availabilityDatasourceProvider = Provider<AvailabilityDataSource>(
  (ref) => AppEnvironment.useLocalSeedData
      ? LocalAvailabilityDataSource()
      : ProductionAvailabilityDataSource(),
);

final chatDatasourceProvider = Provider<ChatDataSource>(
  (ref) => isDev ? LocalChatDataSource() : ApiChatDataSource(),
);

final authDatasourceProvider = Provider<AuthDatasource>(
  (ref) => FirebaseAuthDatasource(),
);

final doctorRepositoryProvider = ChangeNotifierProvider<DoctorRepository>(
  (ref) => DoctorRepository(ref.read(doctorDatasourceProvider)),
);

final doctorReviewRepositoryProvider = Provider<DoctorReviewRepository>(
  (ref) => DoctorReviewRepository(ref.read(doctorReviewDatasourceProvider)),
);

final appointmentRepositoryProvider = Provider<AppointmentRepository>(
  (ref) => AppointmentRepository(
    dataSource: ref.read(appointmentDatasourceProvider),
    doctorRepository: ref.read(doctorRepositoryProvider),
    userRepository: ref.read(userRepositoryProvider),
  ),
);

final chatRepositoryProvider = Provider<ChatRepository>(
  (ref) => ChatRepository(
    dataSource: ref.read(chatDatasourceProvider),
    aiSummaryRepository: ref.read(aiSummaryRepositoryProvider),
    aiService: ref.read(aiServiceProvider),
  ),
);

final userRepositoryProvider = ChangeNotifierProvider<UserRepository>(
  (ref) => UserRepository(ref.read(userDatasourceProvider)),
);

final profileImageRepositoryProvider = Provider<ProfileImageRepository>(
  (ref) => ProfileImageRepository(),
);

final reportRepositoryProvider = Provider<ReportRepository>(
  (ref) => ReportRepository(ref.read(reportDatasourceProvider)),
);

final availabilityRepositoryProvider = Provider<AvailabilityRepository>(
  (ref) => AvailabilityRepository(ref.read(availabilityDatasourceProvider)),
);

final aiSummaryRepositoryProvider = Provider<AISummaryRepository>(
  (ref) => AISummaryRepository(),
);

final aiServiceProvider = Provider<AIService>(
  (ref) => isDev ? MockAIService() : ProductionAIService(),
);

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final datasource = ref.read(authDatasourceProvider);
  return AuthRepository(datasource);
});

final authControllerProvider = Provider<AuthController>((ref) {
  return AuthController(ref.read(authRepositoryProvider));
});

final appointmentControllerProvider = Provider<AppointmentController>((ref) {
  return AppointmentController(ref.read(appointmentRepositoryProvider));
});

final reportControllerProvider = Provider<ReportController>((ref) {
  return ReportController(ref.read(reportRepositoryProvider));
});

final aiControllerProvider = Provider<AIController>((ref) {
  return AIController(ref.read(aiSummaryRepositoryProvider));
});
