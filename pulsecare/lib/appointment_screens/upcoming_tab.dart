import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulsecare/constrains/appointment_card.dart';
import 'package:pulsecare/constrains/skeleton_widgets.dart';
import 'package:pulsecare/model/appointment_model.dart';
import 'package:pulsecare/providers/session_provider.dart';
import 'package:pulsecare/user/app_shell.dart';
import 'package:pulsecare/user/date_time_screen.dart';
import 'package:pulsecare/user/user_appointment_detail_screen.dart';
import 'package:pulsecare/utils/time_utils.dart';

import '../providers/repository_providers.dart';

import 'no_appointment_widget.dart';

class _UpcomingTabData {
  const _UpcomingTabData({required this.currentUserId, required this.items});
  final String currentUserId;
  final List<Appointment> items;
}

final _upcomingTabDataProvider = StreamProvider((ref) {
  final userId = ref.watch(sessionUserIdProvider);
  if (userId == null) {
    return const Stream<_UpcomingTabData>.empty();
  }
  return ref
      .read(appointmentRepositoryProvider)
      .watchAppointmentsForUser(userId)
      .map((appointments) {
        final items = appointments
            .where(
              (a) =>
                  a.status == AppointmentStatus.pending ||
                  a.status == AppointmentStatus.confirmed,
            )
            .toList(growable: false);
        return _UpcomingTabData(currentUserId: userId, items: items);
      });
});

class UpcomingTab extends ConsumerStatefulWidget {
  const UpcomingTab({super.key});

  @override
  ConsumerState<UpcomingTab> createState() => _UpcomingTabState();
}

class _UpcomingTabState extends ConsumerState<UpcomingTab> {
  String? _cancellingAppointmentId;

  @override
  Widget build(BuildContext context) {
    final dataAsync = ref.watch(_upcomingTabDataProvider);
    return dataAsync.when(
      data: (data) {
        final upcomingAppointments = [...data.items]
          ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
        if (upcomingAppointments.isEmpty) {
          return const Center(child: NoAppointmentWidget());
        }
        return SingleChildScrollView(
          child: Column(
            children: List.generate(upcomingAppointments.length, (index) {
              final appointment = upcomingAppointments[index];

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UserAppointmentDetailScreen(
                        appointment: appointment,
                      ),
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
                  bottomAction: _upcomingActions(context, appointment),
                ),
              );
            }),
          ),
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

  Widget _upcomingActions(BuildContext context, Appointment appointment) {
    final canReschedule = appointment.status != AppointmentStatus.pending;
    final isCancelling = _cancellingAppointmentId == appointment.id;
    return Row(
      children: [
        Expanded(
          child: _actionButton(
            text: isCancelling ? 'Cancelling...' : 'Cancel',
            bg: Colors.grey.shade300,
            textColor: Colors.black,
            isLoading: isCancelling,
            onTap: isCancelling
                ? null
                : () async {
                    setState(() => _cancellingAppointmentId = appointment.id);
                    try {
                      await ref
                          .read(appointmentRepositoryProvider)
                          .updateAppointmentStatus(
                            appointment.id,
                            AppointmentStatus.cancelled,
                          );
                      ref.invalidate(_upcomingTabDataProvider);
                      if (!context.mounted) return;
                      AppShell.of(context)?.switchToTab(1);
                    } finally {
                      if (mounted &&
                          _cancellingAppointmentId == appointment.id) {
                        setState(() => _cancellingAppointmentId = null);
                      }
                    }
                  },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _actionButton(
            text: 'Reschedule',
            bg: canReschedule
                ? const Color(0xff3F67FD)
                : const Color(0xffAFC0FF),
            textColor: Colors.white,
            onTap: canReschedule
                ? () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DateTimeScreen(
                          doctorId: appointment.resolvedDoctor.id,
                          patientName: appointment.patientName,
                          age: appointment.age,
                          gender: appointment.gender,
                          symptoms: appointment.symptoms,
                          selectedReports: const [],
                          existingAppointment: appointment,
                        ),
                      ),
                    );
                  }
                : null,
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
