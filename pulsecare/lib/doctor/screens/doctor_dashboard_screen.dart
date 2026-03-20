import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulsecare/constrains/app_avatar.dart';
import 'package:pulsecare/constrains/skeleton_widgets.dart';
import 'package:pulsecare/doctor/doctor_app_shell.dart';
import 'package:pulsecare/doctor/doctor_onboarding_screen.dart';
import 'package:pulsecare/model/appointment_model.dart';
import 'package:pulsecare/repositories/appointment_repository.dart';
import 'package:pulsecare/providers/session_provider.dart';
import 'package:pulsecare/utils/time_utils.dart';
import '../../providers/repository_providers.dart';
import 'doctor_appointment_detail_screen.dart';

class _DashboardIdentity {
  const _DashboardIdentity({required this.doctor, required this.user});
  final dynamic doctor;
  final dynamic user;
}

final _dashboardIdentityProvider = StreamProvider.autoDispose.family((
  ref,
  String currentUserId,
) {
  return ref
      .read(doctorRepositoryProvider)
      .watchDoctorByUserId(currentUserId)
      .asyncMap((doctor) async {
        if (doctor == null) {
          return const _DashboardIdentity(doctor: null, user: null);
        }
        final user = await ref
            .read(userRepositoryProvider)
            .getUserById(doctor.userId);
        return _DashboardIdentity(doctor: doctor, user: user);
      });
});

class DoctorDashboardScreen extends ConsumerStatefulWidget {
  const DoctorDashboardScreen({
    super.key,
    required this.appointments,
    this.onStatusChanged,
    this.onViewAppointments,
    this.onStatTap,
  });

  final List<Appointment> appointments;
  final void Function(Appointment, AppointmentStatus)? onStatusChanged;
  final VoidCallback? onViewAppointments;
  final void Function(int filterIndex)? onStatTap;

  @override
  ConsumerState<DoctorDashboardScreen> createState() =>
      _DoctorDashboardScreenState();
}

class _DoctorDashboardScreenState extends ConsumerState<DoctorDashboardScreen> {
  late AppointmentRepository _appointmentRepository;
  bool _identityLoading = true;
  bool _hasDoctorProfile = false;
  String _doctorProfileId = '';
  String _doctorDisplayName = 'Doctor';

  @override
  void initState() {
    super.initState();
    _appointmentRepository = ref.read(appointmentRepositoryProvider);
    _appointmentRepository.addListener(_onAppointmentsUpdated);
  }

  void _onAppointmentsUpdated() {
    setState(() {});
  }

  @override
  void dispose() {
    _appointmentRepository.removeListener(_onAppointmentsUpdated);
    super.dispose();
  }

  int get totalAppointments => widget.appointments.length;

  int get pendingCount => widget.appointments
      .where((a) => a.status == AppointmentStatus.pending)
      .length;

  int get confirmedCount => widget.appointments
      .where((a) => a.status == AppointmentStatus.confirmed)
      .length;

  int get completedCount => widget.appointments
      .where((a) => a.status == AppointmentStatus.completed)
      .length;

  int get cancelledCount => widget.appointments
      .where((a) => a.status == AppointmentStatus.cancelled)
      .length;

  int _statusPriority(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.pending:
        return 0;
      case AppointmentStatus.confirmed:
        return 1;
      case AppointmentStatus.completed:
        return 2;
      case AppointmentStatus.cancelled:
        return 3;
    }
  }

  List<Appointment> get _sortedAppointments {
    final sorted = [...widget.appointments];
    sorted.sort((a, b) {
      final statusCompare = _statusPriority(
        a.status,
      ).compareTo(_statusPriority(b.status));
      if (statusCompare != 0) {
        return statusCompare;
      }

      final isUpcoming =
          a.status == AppointmentStatus.pending ||
          a.status == AppointmentStatus.confirmed;
      return isUpcoming
          ? a.scheduledAt.compareTo(b.scheduledAt)
          : b.scheduledAt.compareTo(a.scheduledAt);
    });
    return sorted;
  }

  void _updateHeaderState({
    required bool isLoading,
    required bool hasDoctorProfile,
    required String doctorProfileId,
    required String doctorDisplayName,
  }) {
    if (_identityLoading == isLoading &&
        _hasDoctorProfile == hasDoctorProfile &&
        _doctorProfileId == doctorProfileId &&
        _doctorDisplayName == doctorDisplayName) {
      return;
    }

    setState(() {
      _identityLoading = isLoading;
      _hasDoctorProfile = hasDoctorProfile;
      _doctorProfileId = doctorProfileId;
      _doctorDisplayName = doctorDisplayName;
    });
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(sessionUserIdProvider);
    if (userId == null) {
      return const SizedBox.shrink();
    }
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isCompact = screenWidth < 380;
    final horizontalPadding = isCompact ? 14.0 : 16.0;
    final topSpacing = isCompact ? 6.0 : 8.0;
    final sectionGap = isCompact ? 14.0 : 16.0;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: SizedBox(height: topSpacing)),
            DashboardHeader(
              userId: userId,
              horizontalPadding: horizontalPadding,
              onIdentityResolved: _updateHeaderState,
              onProfileTap: () => DoctorAppShell.of(context)?.switchToTab(3),
            ),
            if (_identityLoading) ...[
              SliverToBoxAdapter(child: SizedBox(height: sectionGap)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: _DoctorStatsSkeletonCard(isCompact: isCompact),
                ),
              ),
              SliverToBoxAdapter(child: SizedBox(height: sectionGap)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: const SkeletonBox(width: 210, height: 22, radius: 8),
                ),
              ),
              SliverToBoxAdapter(child: SizedBox(height: isCompact ? 8 : 6)),
              SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  return const _DoctorAppointmentPreviewSkeleton();
                }, childCount: 3),
              ),
              SliverToBoxAdapter(child: SizedBox(height: isCompact ? 20 : 24)),
            ] else if (!_hasDoctorProfile)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Doctor onboarding is not completed yet.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const DoctorOnboardingScreen(),
                              ),
                            );
                          },
                          child: const Text('Complete Onboarding'),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else ...[
              SliverToBoxAdapter(child: SizedBox(height: sectionGap)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: _TodayScheduleCard(
                    isCompact: isCompact,
                    totalAppointments: totalAppointments,
                    pendingCount: pendingCount,
                    confirmedCount: confirmedCount,
                    completedCount: completedCount,
                    cancelledCount: cancelledCount,
                    onViewAppointments: widget.onViewAppointments ?? () {},
                    onStatTap: widget.onStatTap,
                  ),
                ),
              ),
              SliverToBoxAdapter(child: SizedBox(height: sectionGap)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: Text(
                    "Today's Appointments",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              SliverToBoxAdapter(child: SizedBox(height: isCompact ? 4 : 2)),
              SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  return _DoctorAppointmentPreviewCard(
                    item: _sortedAppointments[index],
                    onStatusUpdated: (appointment, updatedStatus) {
                      widget.onStatusChanged?.call(appointment, updatedStatus);
                    },
                  );
                }, childCount: _sortedAppointments.length),
              ),
              SliverToBoxAdapter(child: SizedBox(height: isCompact ? 20 : 24)),
            ],
          ],
        ),
      ),
    );
  }
}

class DashboardHeader extends ConsumerWidget {
  const DashboardHeader({
    super.key,
    required this.userId,
    required this.horizontalPadding,
    required this.onIdentityResolved,
    required this.onProfileTap,
  });

  final String userId;
  final double horizontalPadding;
  final void Function({
    required bool isLoading,
    required bool hasDoctorProfile,
    required String doctorProfileId,
    required String doctorDisplayName,
  })
  onIdentityResolved;
  final VoidCallback onProfileTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final identityAsync = ref.watch(_dashboardIdentityProvider(userId));

    if (identityAsync.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        onIdentityResolved(
          isLoading: true,
          hasDoctorProfile: false,
          doctorProfileId: '',
          doctorDisplayName: 'Doctor',
        );
      });
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    final currentDoctor = identityAsync.valueOrNull?.doctor;
    final user = identityAsync.valueOrNull?.user;

    if (currentDoctor == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        onIdentityResolved(
          isLoading: false,
          hasDoctorProfile: false,
          doctorProfileId: '',
          doctorDisplayName: 'Doctor',
        );
      });
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    final firstName = user?.firstName.trim() ?? '';
    final lastName = user?.lastName.trim() ?? '';
    final fullName = [
      firstName,
      lastName,
    ].where((part) => part.isNotEmpty).join(' ').trim();

    final fallbackName = (currentDoctor.name.trim()).isNotEmpty
        ? (currentDoctor.name.trim().startsWith('Dr.')
              ? currentDoctor.name.trim()
              : 'Dr. ${currentDoctor.name.trim()}')
        : 'Doctor';
    final doctorName = fullName.isNotEmpty ? 'Dr. $fullName' : fallbackName;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      onIdentityResolved(
        isLoading: false,
        hasDoctorProfile: true,
        doctorProfileId: currentDoctor.id,
        doctorDisplayName: doctorName,
      );
    });

    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hi, $doctorName',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 24),
                ),
                Text(
                  'Here is your schedule overview',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            Spacer(),
            InkWell(
              onTap: onProfileTap,
              child: AppAvatar(
                radius: 28,
                name: doctorName,
                imagePath: currentDoctor.image,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TodayScheduleCard extends StatelessWidget {
  const _TodayScheduleCard({
    required this.onViewAppointments,
    this.onStatTap,
    required this.isCompact,
    required this.totalAppointments,
    required this.pendingCount,
    required this.confirmedCount,
    required this.completedCount,
    required this.cancelledCount,
  });

  final VoidCallback onViewAppointments;
  final void Function(int filterIndex)? onStatTap;
  final bool isCompact;
  final int totalAppointments;
  final int pendingCount;
  final int confirmedCount;
  final int completedCount;
  final int cancelledCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(30)),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color.fromARGB(255, 174, 192, 255), Color(0xFF3F67FD)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              height: 220,
              width: 209,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                image: const DecorationImage(
                  fit: BoxFit.cover,
                  image: AssetImage('assets/images/c_bg_lines.png'),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                        color: Colors.white,
                      ),
                      width: 50,
                      height: 50,
                      child: Center(
                        child: Image.asset(
                          'assets/images/msg.png',
                          color: Color(0xff3F67FD),
                          width: 30,
                          height: 30,
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Today's Schedule",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'You have $totalAppointments appointments today',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w400,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                SizedBox(height: 16),
                Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: GestureDetector(
                              onTap: () => onStatTap?.call(0),
                              child: _StatPill(
                                label: 'Pending',
                                value: pendingCount.toString(),
                                color: Color(0xffF59E0B),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: GestureDetector(
                              onTap: () => onStatTap?.call(0),
                              child: _StatPill(
                                label: 'Confirmed',
                                value: confirmedCount.toString(),
                                color: Color(0xFF3F67FD),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: GestureDetector(
                              onTap: () => onStatTap?.call(1),
                              child: _StatPill(
                                label: 'Completed',
                                value: completedCount.toString(),
                                color: Color(0xff059669),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: GestureDetector(
                              onTap: () => onStatTap?.call(2),
                              child: _StatPill(
                                label: 'Cancelled',
                                value: cancelledCount.toString(),
                                color: Color(0xffE12D1D),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: onViewAppointments,
                  borderRadius: BorderRadius.circular(30),
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Center(
                      child: Text(
                        'View Appointments',
                        style: TextStyle(
                          color: Color(0xFF3F67FD),
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              '$value $label',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DoctorStatsSkeletonCard extends StatelessWidget {
  const _DoctorStatsSkeletonCard({required this.isCompact});

  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final cardMinHeight = isCompact ? 172.0 : 182.0;
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: cardMinHeight),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color.fromARGB(255, 174, 192, 255), Color(0xFF3F67FD)],
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonBox(width: 170, height: 20, radius: 8),
          SizedBox(height: 8),
          SkeletonBox(width: 130, height: 14, radius: 8),
          SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              SkeletonBox(width: 110, height: 30, radius: 22),
              SkeletonBox(width: 110, height: 30, radius: 22),
              SkeletonBox(width: 110, height: 30, radius: 22),
              SkeletonBox(width: 110, height: 30, radius: 22),
            ],
          ),
          SizedBox(height: 14),
          SkeletonBox(height: 48, radius: 30),
        ],
      ),
    );
  }
}

class _DoctorAppointmentPreviewSkeleton extends StatelessWidget {
  const _DoctorAppointmentPreviewSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, left: 16, right: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Padding(
          padding: EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  SkeletonBox(width: 96, height: 24, radius: 30),
                  Spacer(),
                  SkeletonBox(width: 70, height: 14, radius: 8),
                ],
              ),
              SizedBox(height: 10),
              SkeletonBox(width: 170, height: 20, radius: 8),
              SizedBox(height: 8),
              SkeletonBox(height: 14, radius: 8),
              SizedBox(height: 6),
              SkeletonBox(width: 220, height: 14, radius: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _DoctorAppointmentPreviewCard extends StatelessWidget {
  const _DoctorAppointmentPreviewCard({
    required this.item,
    required this.onStatusUpdated,
  });

  final Appointment item;
  final void Function(Appointment appointment, AppointmentStatus updatedStatus)
  onStatusUpdated;

  @override
  Widget build(BuildContext context) {
    final status = _statusUi(item.status);
    final intakeSummary = item.symptoms;

    return Padding(
      padding: const EdgeInsets.only(top: 16, left: 16, right: 16),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          final updatedStatus = await Navigator.push<AppointmentStatus>(
            context,
            MaterialPageRoute(
              builder: (_) => DoctorAppointmentDetailScreen(appointment: item),
            ),
          );
          if (updatedStatus != null) {
            onStatusUpdated(item, updatedStatus);
          }
        },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _StatusBadge(
                      text: status.text,
                      color: status.color,
                      backgroundColor: status.backgroundColor,
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.schedule_rounded,
                      size: 16,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      TimeUtils.formatTime(item.scheduledAt),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  item.patientName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  intakeSummary,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusUi {
  const _StatusUi({
    required this.text,
    required this.color,
    required this.backgroundColor,
  });

  final String text;
  final Color color;
  final Color backgroundColor;
}

_StatusUi _statusUi(AppointmentStatus status) {
  switch (status) {
    case AppointmentStatus.confirmed:
      return const _StatusUi(
        text: 'Confirmed',
        color: Color(0xff3F67FD),
        backgroundColor: Color(0xffE4E9FC),
      );
    case AppointmentStatus.pending:
      return const _StatusUi(
        text: 'Pending',
        color: Color(0xffF59E0B),
        backgroundColor: Color(0xffFFE2AF),
      );
    case AppointmentStatus.completed:
      return const _StatusUi(
        text: 'Completed',
        color: Color(0xff059669),
        backgroundColor: Color.fromARGB(255, 203, 248, 233),
      );
    case AppointmentStatus.cancelled:
      return const _StatusUi(
        text: 'Cancelled',
        color: Color(0xffE12D1D),
        backgroundColor: Color(0xffFFDFDC),
      );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.text,
    required this.color,
    required this.backgroundColor,
  });

  final String text;
  final Color color;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 25,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
