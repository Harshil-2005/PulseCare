import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pulsecare/constrains/add_leave_date_sheet.dart';
import 'package:pulsecare/constrains/logout_delete.dart';
import 'package:pulsecare/doctor/doctor_app_shell.dart';
import 'package:pulsecare/constrains/edit_day_schedule_sheet.dart';
import 'package:pulsecare/model/day_schedule.dart';
import 'package:pulsecare/model/date_override.dart';
import 'package:pulsecare/model/doctor_model.dart';
import 'package:pulsecare/providers/repository_providers.dart';
import 'package:pulsecare/providers/session_provider.dart';

final _doctorScheduleDoctorProvider = StreamProvider.autoDispose
    .family<Doctor?, String>((ref, userId) {
      final doctorRepository = ref.read(doctorRepositoryProvider);
      return doctorRepository.watchDoctorByUserId(userId);
    });

class DoctorScheduleScreen extends ConsumerStatefulWidget {
  const DoctorScheduleScreen({
    super.key,
    required this.doctorId,
    required this.leaveDates,
  });

  final String doctorId;
  final List<DateTime> leaveDates;

  @override
  ConsumerState<DoctorScheduleScreen> createState() =>
      _DoctorScheduleScreenState();
}

class _DoctorScheduleScreenState extends ConsumerState<DoctorScheduleScreen> {
  bool isAvailableForBooking = true;

  void _openEditDay(DaySchedule day) {
    final shell = DoctorAppShell.of(context)!;
    final duration = shell.currentDoctor.slotDuration;
    final doctorRepository = ref.read(doctorRepositoryProvider);
    final editedDay = doctorRepository.createEditableSchedule(day, duration);

    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => EditDayScheduleSheet(
        daySchedule: editedDay,
        slotDuration: duration,
        onSave: (updatedDay) async {
          setState(() {
            final shell = DoctorAppShell.of(context);
            if (shell != null) {
              final updatedSchedule = doctorRepository.updateScheduleDay(
                schedule: shell.weeklySchedule,
                updatedDay: updatedDay,
              );
              shell.weeklySchedule = updatedSchedule;
            }
          });
          final currentUserId = ref.read(sessionUserIdProvider);
          if (currentUserId == null) return;
          final freshDoctor = await ref
              .read(doctorRepositoryProvider)
              .getDoctorByUserId(currentUserId);
          if (!mounted) return;
          if (freshDoctor != null) {
            final updatedDoctor = freshDoctor.copyWith(
              schedule:
                  DoctorAppShell.of(context)?.weeklySchedule ??
                  freshDoctor.schedule,
            );
            await ref
                .read(doctorRepositoryProvider)
                .updateDoctor(updatedDoctor);
            if (!mounted) return;
            final shell = DoctorAppShell.of(context);
            if (shell != null) {
              shell.currentDoctor = updatedDoctor;
            }
          }
          Navigator.pop(context);
        },
      ),
    );
  }

  void _openAddLeaveSheet() {
    showDialog(
      context: context,
      useRootNavigator: true,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (dialogContext) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => Navigator.of(dialogContext, rootNavigator: true).pop(),
          child: Material(
            color: Colors.transparent,
            child: Center(
              child: GestureDetector(
                onTap: () {},
                child: AddLeaveDateSheet(
                  leaveDates: widget.leaveDates,
                  onUpdated: () {
                    final shell = DoctorAppShell.of(context);
                    if (shell != null) {
                      shell.setState(() {});
                    }
                    setState(() {});
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmAndRemoveLeaveOverride(
    String doctorId,
    DateOverride override,
  ) async {
    showConfirmationDialog(
      context,
      title: 'Remove Leave',
      message: 'Are you sure you want to remove this leave?',
      iconPath: null,
      confirmText: 'Confirm',
      onConfirm: () async {
        await ref.read(doctorRepositoryProvider).removeOverride(
              doctorId: doctorId,
              date: override.startDate,
            );
        if (!mounted) return;
        setState(() {});
        final shell = DoctorAppShell.of(context);
        if (shell != null) {
          shell.setState(() {});
        }
      },
    );
  }

  String _formatLeaveRange(DateOverride override) {
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
    final start = DateUtils.dateOnly(override.startDate);
    final end = DateUtils.dateOnly(override.endDate);
    final startMonth = months[start.month - 1];
    final endMonth = months[end.month - 1];

    if (start.year == end.year &&
        start.month == end.month &&
        start.day == end.day) {
      return '${start.day} $startMonth ${start.year}';
    }
    return '${start.day} $startMonth ${start.year} → ${end.day} $endMonth ${end.year}';
  }

  String _overrideLabel(DateOverride override) {
    if (override.isFullDayLeave) {
      return 'Full Day';
    }

    final schedule = override.customSchedule!;
    if (schedule.morningEnabled && !schedule.afternoonEnabled) {
      return 'Morning Only';
    }
    if (!schedule.morningEnabled && schedule.afternoonEnabled) {
      return 'Afternoon Only';
    }
    return 'Custom Hours';
  }

  String _buildScheduleText(DaySchedule schedule) {
    final parts = <String>[];

    if (schedule.morningEnabled &&
        schedule.morningStart.isNotEmpty &&
        schedule.morningEnd.isNotEmpty) {
      parts.add('${schedule.morningStart} - ${schedule.morningEnd}');
    }

    if (schedule.afternoonEnabled &&
        schedule.afternoonStart.isNotEmpty &&
        schedule.afternoonEnd.isNotEmpty) {
      parts.add('${schedule.afternoonStart} - ${schedule.afternoonEnd}');
    }

    if (parts.isEmpty) return 'OFF';
    return parts.join(' | ');
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(sessionUserIdProvider.select((id) => id));
    if (userId == null) {
      return const SizedBox.shrink();
    }
    final doctorAsync = ref.watch(_doctorScheduleDoctorProvider(userId));
    return doctorAsync.when(
      data: (doctor) {
        if (doctor == null) {
          return const Scaffold(
            body: Center(
              child: Text('Doctor not found for active doctor session'),
            ),
          );
        }
        const sectionGap = SizedBox(height: 18);
        final shell = DoctorAppShell.of(context);
        final schedule = shell?.weeklySchedule ?? <DaySchedule>[];
        final currentAvailability = doctor.isAvailableForBooking;
        final overrides = doctor.overrides;

        return Scaffold(
          appBar: AppBar(
            titleSpacing: 0,
            toolbarHeight: 85,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
            ),
            elevation: 0.3,
            title: const Center(
              child: Text(
                'Schedule',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
            ),
            shadowColor: Colors.black,
            automaticallyImplyLeading: false,
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Availability Status',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Control whether patients can book appointments',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Available for Booking',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade900,
                                ),
                              ),
                            ),
                            Switch(
                              value: currentAvailability,
                              activeThumbColor: const Color(0xFF3F67FD),
                              activeTrackColor: const Color.fromARGB(
                                255,
                                196,
                                209,
                                255,
                              ),
                              onChanged: (value) async {
                                final doctorRepository = ref.read(
                                  doctorRepositoryProvider,
                                );
                                final doctor = await doctorRepository
                                    .getDoctorByUserId(userId);
                                if (!mounted) return;

                                if (doctor == null) {
                                  throw StateError('Doctor not found');
                                }

                                final updatedDoctor = doctor.copyWith(
                                  isAvailableForBooking: value,
                                );

                                await doctorRepository.updateDoctor(
                                  updatedDoctor,
                                );
                                if (!mounted) return;
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  sectionGap,
                  _sectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Weekly Availability',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...List.generate(schedule.length, (index) {
                          final daySchedule = schedule[index];
                          final scheduleText = _buildScheduleText(daySchedule);
                          final isOff = scheduleText == 'OFF';
                          final timeParts = isOff
                              ? <String>[]
                              : scheduleText
                                    .split('|')
                                    .map((e) => e.trim())
                                    .where((e) => e.isNotEmpty)
                                    .toList();
                          if (!isOff && timeParts.length < 2) {
                            timeParts.add('');
                          }
                          return Column(
                            children: [
                              InkWell(
                                onTap: () => _openEditDay(daySchedule),
                                child: Row(
                                  crossAxisAlignment: isOff
                                      ? CrossAxisAlignment.center
                                      : CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        daySchedule.day,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      flex: 5,
                                      child: Align(
                                        alignment: Alignment.centerRight,
                                        child: SizedBox(
                                          height: 40,
                                          child: isOff
                                              ? Align(
                                                  alignment:
                                                      Alignment.centerRight,
                                                  child: Text(
                                                    scheduleText,
                                                    textAlign: TextAlign.right,
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w400,
                                                      color:
                                                          Colors.red.shade400,
                                                    ),
                                                  ),
                                                )
                                              : Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: List.generate(2, (
                                                    timeIndex,
                                                  ) {
                                                    final text =
                                                        timeParts[timeIndex];
                                                    final isPlaceholder =
                                                        text.isEmpty;
                                                    return Text(
                                                      text,
                                                      textAlign: TextAlign.left,
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.w400,
                                                        color: isPlaceholder
                                                            ? Colors.transparent
                                                            : Colors
                                                                  .grey
                                                                  .shade700,
                                                      ),
                                                    );
                                                  }),
                                                ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (index != schedule.length - 1) ...[
                                const SizedBox(height: 10),
                                Divider(
                                  height: 1,
                                  thickness: 0.8,
                                  color: Colors.grey.shade300,
                                ),
                                const SizedBox(height: 10),
                              ],
                            ],
                          );
                        }),
                      ],
                    ),
                  ),
                  sectionGap,
                  _sectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Blocked Dates / Leave',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: _openAddLeaveSheet,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xff3F67FD),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: const Center(
                              child: Text(
                                'Add Leave Date',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        if (overrides.isEmpty)
                          Text(
                            'No leave dates added',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          )
                        else
                          ...List.generate(overrides.length, (index) {
                            final override = overrides[index];
                            return Padding(
                              padding: EdgeInsets.only(
                                bottom: index == overrides.length - 1 ? 0 : 8,
                              ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _formatLeaveRange(override),
                                            style: TextStyle(
                                              fontSize: 15,
                                              color: Colors.grey.shade800,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            _overrideLabel(override),
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    InkWell(
                                      onTap: () =>
                                          _confirmAndRemoveLeaveOverride(
                                            doctor.id,
                                            override,
                                          ),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: const Color(0xffD9D9D9),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        height: 18,
                                        width: 18,
                                        child: Center(
                                          child: SvgPicture.asset(
                                            'assets/icons/cross.svg',
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stack) =>
          Scaffold(body: Center(child: Text('Error: $error'))),
    );
  }

  Widget _sectionCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}
