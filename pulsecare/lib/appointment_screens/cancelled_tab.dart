import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulsecare/constrains/appointment_card.dart';
import 'package:pulsecare/constrains/skeleton_widgets.dart';
import 'package:pulsecare/user/patient_detail_screen.dart';
import 'package:pulsecare/model/appointment_model.dart';
import 'package:pulsecare/providers/session_provider.dart';
import 'package:pulsecare/user/user_appointment_detail_screen.dart';
import 'package:pulsecare/utils/time_utils.dart';

import '../providers/repository_providers.dart';

import 'no_appointment_widget.dart';

final _cancelledAppointmentsProvider = StreamProvider((ref) {
  final userId = ref.watch(sessionUserIdProvider);
  if (userId == null) {
    return const Stream<List<Appointment>>.empty();
  }
  return ref
      .read(appointmentRepositoryProvider)
      .watchAppointmentsForUser(userId)
      .map(
        (appointments) => appointments
            .where((a) => a.status == AppointmentStatus.cancelled)
            .toList(growable: false),
      );
});

class CancelledTab extends ConsumerStatefulWidget {
  const CancelledTab({super.key});

  @override
  ConsumerState<CancelledTab> createState() => _CancelledTabState();
}

class _CancelledTabState extends ConsumerState<CancelledTab> {
  String? _removingAppointmentId;

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
    final cancelledAsync = ref.watch(_cancelledAppointmentsProvider);
    return cancelledAsync.when(
      data: (cancelledAppointments) {
        final sortedAppointments = [...cancelledAppointments]
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
                bottomAction: _cancelledActions(context, appointment),
              ),
            );
          },
        );
      },
      loading: () => ListView.builder(
        padding: const EdgeInsets.only(bottom: 20),
        itemCount: 3,
        itemBuilder: (context, _) =>
            const AppointmentCardSkeleton(dualActions: true),
      ),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }

  Widget _cancelledActions(BuildContext context, Appointment appointment) {
    final isRemoving = _removingAppointmentId == appointment.id;
    return Row(
      children: [
        Expanded(
          child: _actionButton(
            text: isRemoving ? 'Removing...' : 'Remove',
            bg: Colors.grey.shade300,
            textColor: Colors.black,
            isLoading: isRemoving,
            onTap: isRemoving
                ? null
                : () async {
                    setState(() => _removingAppointmentId = appointment.id);
                    try {
                      await ref
                          .read(appointmentRepositoryProvider)
                          .removeAppointment(appointment);
                      ref.invalidate(_cancelledAppointmentsProvider);
                    } finally {
                      if (mounted &&
                          _removingAppointmentId == appointment.id) {
                        setState(() => _removingAppointmentId = null);
                      }
                    }
                  },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _actionButton(
            text: 'Book Again',
            bg: const Color(0xff3F67FD),
            textColor: Colors.white,
            isLoading: false,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PatientDetailScreen(
                    doctor: appointment.resolvedDoctor,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _actionButton({
    required String text,
    required Color bg,
    required Color textColor,
    bool isLoading = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: (onTap == null || isLoading) ? null : onTap,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: isLoading ? bg.withValues(alpha: 0.65) : bg,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
