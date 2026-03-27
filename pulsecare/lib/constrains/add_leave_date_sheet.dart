import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulsecare/constrains/edit_day_schedule_sheet.dart';
import 'package:pulsecare/doctor/widgets/leave_calendar_card.dart';
import 'package:pulsecare/model/day_schedule.dart';
import 'package:pulsecare/model/date_override.dart';
import 'package:pulsecare/providers/repository_providers.dart';
import 'package:pulsecare/repositories/doctor_repository.dart';
import 'package:pulsecare/repositories/session_repository.dart';

final _leaveDoctorProvider = StreamProvider((ref) {
  final doctorId = SessionRepository().getCurrentDoctorId();
  return ref.read(doctorRepositoryProvider).watchDoctorById(doctorId);
});

class AddLeaveDateSheet extends ConsumerWidget {
  const AddLeaveDateSheet({
    super.key,
    required this.leaveDates,
    required this.onUpdated,
  });

  final List<DateTime> leaveDates;
  final VoidCallback onUpdated;

  void _openLeaveTypeSheet(
    BuildContext context,
    DateTime start,
    DateTime end,
    DoctorRepository doctorRepository,
  ) {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (modalContext) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 18),
            Container(
              width: 45,
              height: 7,
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 26),
            const Text(
              'Add Leave',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
            ),
            InkWell(
              onTap: () async {
                final doctorId = SessionRepository().getCurrentDoctorId();

                await doctorRepository.addOverride(
                  doctorId: doctorId,
                  override: DateOverride(
                    startDate: start,
                    endDate: end,
                    customSchedule: null,
                  ),
                );

                if (modalContext.mounted) {
                  Navigator.pop(modalContext);
                }

                onUpdated();
              },
              child: _leaveTypeOption(
                icon: Icons.event_busy,
                title: 'Full Day Leave',
              ),
            ),
            InkWell(
              onTap: () {
                Navigator.pop(modalContext);
                _openCustomLeaveEditor(context, start, end, doctorRepository);
              },
              child: _leaveTypeOption(
                icon: Icons.schedule,
                title: 'Custom Hours',
              ),
            ),
            const SizedBox(height: 30),
            TextButton(
              onPressed: () => Navigator.pop(modalContext),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Color(0xff3F67FD),
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        );
      },
    );
  }

  String _formatLeaveRangeLabel(DateTime start, DateTime end) {
    const months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final startDate = DateUtils.dateOnly(start);
    final endDate = DateUtils.dateOnly(end);
    final startMonth = months[startDate.month - 1];
    final endMonth = months[endDate.month - 1];

    if (startDate.year == endDate.year &&
        startDate.month == endDate.month &&
        startDate.day == endDate.day) {
      return '$startMonth ${startDate.day}';
    }
    if (startDate.year == endDate.year && startDate.month == endDate.month) {
      return '$startMonth ${startDate.day} - ${endDate.day}';
    }
    return '$startMonth ${startDate.day} - $endMonth ${endDate.day}';
  }

  Future<void> _openCustomLeaveEditor(
    BuildContext context,
    DateTime start,
    DateTime end,
    DoctorRepository doctorRepository,
  ) async {
    final doctorId = SessionRepository().getCurrentDoctorId();

    final doctor = await doctorRepository.getDoctorById(doctorId);
    if (!context.mounted) return;
    final slotDuration = doctor?.slotDuration ?? 30;
    final rangeLabel = _formatLeaveRangeLabel(start, end);
    final baseSchedule = DaySchedule(
      day: rangeLabel,
      morningEnabled: false,
      morningStart: '',
      morningEnd: '',
      afternoonEnabled: false,
      afternoonStart: '',
      afternoonEnd: '',
    );
    final editableSchedule = doctorRepository.createEditableSchedule(
      baseSchedule,
      slotDuration,
    );

    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (modalContext) {
        return EditDayScheduleSheet(
          daySchedule: editableSchedule,
          slotDuration: slotDuration,
          onSave: (updatedDay) async {
            final customSchedule = DaySchedule(
              day: rangeLabel,
              morningEnabled: updatedDay.morningEnabled,
              morningStart: updatedDay.morningStart,
              morningEnd: updatedDay.morningEnd,
              afternoonEnabled: updatedDay.afternoonEnabled,
              afternoonStart: updatedDay.afternoonStart,
              afternoonEnd: updatedDay.afternoonEnd,
            );

            await doctorRepository.addOverride(
              doctorId: doctorId,
              override: DateOverride(
                startDate: start,
                endDate: end,
                customSchedule: customSchedule,
              ),
            );

            if (modalContext.mounted) {
              Navigator.pop(modalContext);
            }
            onUpdated();
          },
        );
      },
    );
  }

  Widget _leaveTypeOption({required IconData icon, required String title}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 201, 212, 253),
          borderRadius: BorderRadius.circular(35),
        ),
        child: Row(
          children: [
            const SizedBox(width: 30),
            Icon(icon, size: 24, color: const Color(0xff3F67FD)),
            const SizedBox(width: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final doctorAsync = ref.watch(_leaveDoctorProvider);
    return doctorAsync.when(
      data: (doctor) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: LeaveCalendarCard(
            overrides: doctor?.overrides ?? [],
            onRangeSelected: (start, end) {
              final doctorRepository = ref.read(doctorRepositoryProvider);
              final rootContext = Navigator.of(
                context,
                rootNavigator: true,
              ).context;
              Navigator.of(context, rootNavigator: true).pop();
              _openLeaveTypeSheet(rootContext, start, end, doctorRepository);
            },
          ),
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }
}
