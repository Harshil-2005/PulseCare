import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulsecare/constrains/appointment_card.dart';
import 'package:pulsecare/constrains/primary_icon_button.dart';
import 'package:pulsecare/model/appointment_model.dart';
import 'package:pulsecare/providers/session_provider.dart';
import 'package:pulsecare/user/patient_detail_screen.dart';
import 'package:pulsecare/user/user_appointment_detail_screen.dart';
import 'package:pulsecare/utils/time_utils.dart';
import '../providers/repository_providers.dart';
import 'no_appointment_widget.dart';

final _pastAppointmentsProvider = StreamProvider((ref) {
  final userId = ref.watch(sessionUserIdProvider);
  if (userId == null) {
    return const Stream<List<Appointment>>.empty();
  }
  return ref
      .read(appointmentRepositoryProvider)
      .watchAppointmentsForUser(userId)
      .map(
        (appointments) => appointments
            .where((a) => a.status == AppointmentStatus.completed)
            .toList(growable: false),
      );
});


class PastTab extends ConsumerStatefulWidget {
  const PastTab({super.key});

  @override
  ConsumerState<PastTab> createState() => _PastTabState();
}

class _PastTabState extends ConsumerState<PastTab> {
AppointmentCardStatus mapToCardStatus(AppointmentStatus status) {
  switch (status) {
    case AppointmentStatus.pending:
      return AppointmentCardStatus.pending;
    case AppointmentStatus.confirmed:
      return AppointmentCardStatus.confirmed;
    case AppointmentStatus.cancelled:
      return AppointmentCardStatus.cancelled;
    case AppointmentStatus.completed:
      return AppointmentCardStatus.completed;
  }
}

@override
Widget build(BuildContext context) {
  final pastAsync = ref.watch(_pastAppointmentsProvider);
  return pastAsync.when(
    data: (pastAppointments) {
      final sortedAppointments = [...pastAppointments]
        ..sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));
      if (sortedAppointments.isEmpty) {
        return const Center(child: NoAppointmentWidget());
      }

      return ListView.builder(
        padding: const EdgeInsets.only(bottom: 20),
        itemCount: sortedAppointments.length,
        itemBuilder: (context, index) {
          final appointment = sortedAppointments[index];

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      UserAppointmentDetailScreen(appointment: appointment),
                ),
              );
            },
            child: AppointmentCard(
              status: mapToCardStatus(appointment.status),
              doctorName: appointment.resolvedDoctor.name,
              speciality: appointment.resolvedDoctor.speciality,
              image: appointment.resolvedDoctor.image,
              date: TimeUtils.formatDate(appointment.scheduledAt),
              time: TimeUtils.formatTime(appointment.scheduledAt),
              bottomAction: PrimaryIconButton(
                text: 'Book Again',
                iconPath: 'assets/images/chat.png',
                height: 50,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PatientDetailScreen(
                        doctor: appointment.resolvedDoctor,
                        prefilledSymptoms: appointment.symptoms,
                        prefilledAge: appointment.age,
                        prefilledGender: appointment.gender,
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      );
    },
    loading: () => const Center(child: CircularProgressIndicator()),
    error: (error, stack) => Center(child: Text('Error: $error')),
  );
}

}
