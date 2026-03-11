import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulsecare/controllers/ai_controller.dart';
import 'package:pulsecare/controllers/appointment_controller.dart';
import 'package:pulsecare/controllers/auth_controller.dart';
import 'package:pulsecare/controllers/report_controller.dart';

import '../data/datasources/appointment_datasource.dart';
import '../data/datasources/auth_datasource.dart';
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
import '../repositories/user_repository.dart';
import '../repositories/report_repository.dart';
import '../repositories/availability_repository.dart';
import '../repositories/ai_summary_repository.dart';
import '../services/ai_service.dart';

const bool _useFirebaseAppointmentDatasource = true;
const bool _useFirebaseUserDatasource = true;
const bool _useFirebaseReportDatasource = true;

final doctorDatasourceProvider = Provider<DoctorDataSource>(
  (ref) => FirebaseDoctorDataSource(),
);

final doctorReviewDatasourceProvider = Provider<DoctorReviewDataSource>(
  (ref) => FirebaseDoctorReviewDataSource(),
);

final appointmentDatasourceProvider = Provider<AppointmentDataSource>(
  (ref) => _useFirebaseAppointmentDatasource
      ? FirebaseAppointmentDataSource()
      : LocalAppointmentDataSource(),
);

final userDatasourceProvider = Provider<UserDataSource>(
  (ref) => _useFirebaseUserDatasource
      ? FirebaseUserDataSource()
      : LocalUserDataSource(),
);

final reportDatasourceProvider = Provider<ReportDataSource>(
  (ref) => _useFirebaseReportDatasource
      ? FirebaseReportDataSource()
      : LocalReportDataSource(),
);

final chatDatasourceProvider = Provider<ChatDataSource>(
  (ref) => LocalChatDataSource(),
);

final authDatasourceProvider = Provider<AuthDatasource>(
  (ref) => FirebaseAuthDatasource(),
);

final doctorRepositoryProvider = ChangeNotifierProvider<DoctorRepository>(
  (ref) => DoctorRepository(ref.read(doctorDatasourceProvider)),
);

final doctorReviewRepositoryProvider = Provider<DoctorReviewRepository>(
  (ref) => DoctorReviewRepository(
    ref.read(doctorReviewDatasourceProvider),
    doctorDataSource: FirebaseDoctorDataSource(),
  ),
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

final reportRepositoryProvider = Provider<ReportRepository>(
  (ref) => ReportRepository(ref.read(reportDatasourceProvider)),
);

final availabilityRepositoryProvider = Provider<AvailabilityRepository>(
  (ref) => AvailabilityRepository(),
);

final aiSummaryRepositoryProvider = Provider<AISummaryRepository>(
  (ref) => AISummaryRepository(),
);

final aiServiceProvider = Provider<AIService>((ref) => MockAIService());

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
