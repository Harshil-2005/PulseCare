import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:async';
import 'package:pulsecare/auth/auth_screen.dart';
import 'package:pulsecare/model/appointment_model.dart';
import 'package:pulsecare/doctor/screens/doctor_appointments_screen.dart';
import 'package:pulsecare/doctor/screens/doctor_dashboard_screen.dart';
import 'package:pulsecare/doctor/screens/doctor_profile_screen.dart';
import 'package:pulsecare/doctor/screens/doctor_schedule_screen.dart';
import 'package:pulsecare/model/day_schedule.dart';
import 'package:pulsecare/model/doctor_model.dart';
import 'package:pulsecare/providers/session_provider.dart';
import 'package:pulsecare/repositories/doctor_repository.dart';
import 'package:pulsecare/utils/time_utils.dart';
import '../providers/repository_providers.dart';

class DoctorAppShell extends ConsumerStatefulWidget {
  final String doctorId;
  final int initialTab;
  final List<DaySchedule> initialSchedule;

  const DoctorAppShell({
    super.key,
    required this.doctorId,
    this.initialTab = 0,
    required this.initialSchedule,
  });

  static DoctorAppShellState? of(BuildContext context) {
    return context.findAncestorStateOfType<DoctorAppShellState>();
  }

  @override
  ConsumerState<DoctorAppShell> createState() => DoctorAppShellState();
}

class DoctorAppShellState extends ConsumerState<DoctorAppShell> {
  bool _ready = false;
  late int selectedIndex;
  late List<Appointment> appointments;
  late List<DaySchedule> weeklySchedule;
  late Doctor currentDoctor;
  late DoctorRepository _doctorRepository;
  StreamSubscription<List<Appointment>>? _appointmentsSubscription;
  Set<String> _knownAppointmentIds = <String>{};
  bool _hasPrimedAppointmentSnapshot = false;
  List<DateTime> leaveDates = [];
  bool isAvailableForBooking = true;
  final GlobalKey<DoctorAppointmentsScreenState> doctorAppointmentsKey =
      GlobalKey<DoctorAppointmentsScreenState>();

  void _showNewBookingNotification(List<Appointment> newAppointments) {
    if (!mounted) return;
    final newCount = newAppointments.length;
    final latest = newCount == 1 ? newAppointments.first : null;
    final patientName = latest?.patientName.trim() ?? '';
    final patientPart = patientName.isEmpty ? 'A patient' : patientName;
    final slotPart = latest == null
        ? ''
        : ' at ${TimeUtils.formatTime(latest.scheduledAt)}';
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          newCount == 1
              ? 'New appointment booked: $patientPart$slotPart'
              : 'New appointment booked ($newCount)',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> cancelStreams() async {
    final subscription = _appointmentsSubscription;
    _appointmentsSubscription = null;
    if (subscription != null) {
      await subscription.cancel();
    }
  }

  void switchToTab(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  void openAppointmentsWithFilter(int filterIndex) {
    setState(() {
      selectedIndex = 1;
    });

    Future.microtask(() {
      doctorAppointmentsKey.currentState?.setTab(filterIndex);
    });
  }

  Future<void> refreshCurrentDoctorFromRepository() async {
    final userId = ref.read(sessionUserIdProvider);
    if (userId == null) return;
    final updatedDoctor = await ref
        .read(doctorRepositoryProvider)
        .getDoctorByUserId(userId);
    if (updatedDoctor == null) {
      throw StateError('Doctor not found for active doctor session');
    }
    if (!mounted) return;
    setState(() {
      currentDoctor = updatedDoctor;
    });
  }

  void _onDoctorUpdated() {
    _handleDoctorUpdated();
  }

  Future<void> _handleDoctorUpdated() async {
    final userId = ref.read(sessionUserIdProvider);
    if (userId == null) return;
    final updatedDoctor = await _doctorRepository.getDoctorByUserId(userId);
    if (updatedDoctor == null) return;
    if (!mounted) return;

    setState(() {
      currentDoctor = updatedDoctor;
      weeklySchedule = updatedDoctor.schedule;
    });
  }

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    _doctorRepository = ref.read(doctorRepositoryProvider);
    _doctorRepository.addListener(_onDoctorUpdated);
    selectedIndex = widget.initialTab;
    weeklySchedule = widget.initialSchedule;
    final userId = ref.read(sessionUserIdProvider);
    if (userId == null) return;
    final doctor = await _doctorRepository.getDoctorByUserId(userId);
    if (doctor == null) {
      throw StateError('Doctor not found for active doctor session');
    }
    currentDoctor = doctor;
    appointments = <Appointment>[];
    final appointmentRepository = ref.read(appointmentRepositoryProvider);
    _appointmentsSubscription = appointmentRepository
        .watchAppointmentsForDoctor(doctor.id)
        .listen((nextAppointments) {
          if (!mounted) return;

          final currentIds = nextAppointments
              .map((appointment) => appointment.id)
              .where((id) => id.isNotEmpty)
              .toSet();

          if (_hasPrimedAppointmentSnapshot) {
            final newBookings = nextAppointments
                .where(
                  (appointment) =>
                      appointment.id.isNotEmpty &&
                      !_knownAppointmentIds.contains(appointment.id) &&
                      appointment.status == AppointmentStatus.pending,
                )
                .toList(growable: false);
            if (newBookings.isNotEmpty) {
              _showNewBookingNotification(newBookings);
            }
          }

          _knownAppointmentIds = currentIds;
          _hasPrimedAppointmentSnapshot = true;

          setState(() {
            appointments = nextAppointments;
            _ready = true;
          });
        });
  }

  void addAppointment(Appointment newAppointment) {
    setState(() {
      appointments.add(newAppointment);
    });
  }

  Future<void> updateAppointmentStatus(
    Appointment appointment,
    AppointmentStatus status,
  ) async {
    final doctorRepository = ref.read(doctorRepositoryProvider);
    final userId = ref.read(sessionUserIdProvider);
    if (userId == null) return;
    final doctor = await doctorRepository.getDoctorByUserId(userId);
    if (doctor == null) {
      throw StateError('Doctor not found for active doctor session');
    }
    final appointmentRepository = ref.read(appointmentRepositoryProvider);
    String appointmentId = appointment.id;
    if (appointmentId.isEmpty) {
      final fallback = appointments.firstWhere(
        (a) =>
            a.doctorId == doctor.id &&
            a.patientName == appointment.patientName &&
            a.scheduledAt.year == appointment.scheduledAt.year &&
            a.scheduledAt.month == appointment.scheduledAt.month &&
            a.scheduledAt.day == appointment.scheduledAt.day &&
            a.scheduledAt.hour == appointment.scheduledAt.hour &&
            a.scheduledAt.minute == appointment.scheduledAt.minute,
        orElse: () => appointment,
      );
      appointmentId = fallback.id;
    }
    if (appointmentId.isEmpty) return;

    await appointmentRepository.updateAppointmentStatus(appointmentId, status);
  }

  @override
  void dispose() {
    _doctorRepository.removeListener(_onDoctorUpdated);
    _appointmentsSubscription?.cancel();
    _knownAppointmentIds = <String>{};
    super.dispose();
  }

  List<Widget> get screens => [
    DoctorDashboardScreen(
      appointments: appointments,
      onStatusChanged: (appointment, status) async {
        await updateAppointmentStatus(appointment, status);
      },
      onViewAppointments: () => switchToTab(1),
      onStatTap: (filterIndex) {
        openAppointmentsWithFilter(filterIndex);
      },
    ),
    DoctorAppointmentsScreen(
      key: doctorAppointmentsKey,
      appointments: appointments,
      onStatusChanged: (appointment, status) async {
        await updateAppointmentStatus(appointment, status);
      },
    ),
    DoctorScheduleScreen(doctorId: currentDoctor.id, leaveDates: leaveDates),
    DoctorProfileScreen(doctorId: currentDoctor.id),
  ];

  @override
  Widget build(BuildContext context) {
    ref.listen<String?>(sessionUserIdProvider, (previous, next) {
      if (next == null) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const AuthScreen()),
          (route) => false,
        );
      }
    });

    final userId = ref.watch(sessionUserIdProvider);
    if (userId == null) {
      return const SizedBox.shrink();
    }
    if (!_ready) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: IndexedStack(index: selectedIndex, children: screens),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: selectedIndex,
          onTap: switchToTab,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: const Color(0xFF3F67FD),
          unselectedItemColor: Colors.grey,
          showUnselectedLabels: true,
          items: [
            BottomNavigationBarItem(
              icon: _navIcon('assets/icons/home.svg', selectedIndex == 0),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: _navIcon('assets/icons/ex.svg', selectedIndex == 1),
              label: 'Appointments',
            ),
            BottomNavigationBarItem(
              icon: _navIcon('assets/icons/report.svg', selectedIndex == 2),
              label: 'Schedule',
            ),
            BottomNavigationBarItem(
              icon: _navIcon('assets/icons/man.svg', selectedIndex == 3),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  Widget _navIcon(String assetPath, bool isSelected) {
    return SvgPicture.asset(
      assetPath,
      width: 26,
      height: 26,
      colorFilter: ColorFilter.mode(
        isSelected ? const Color(0xFF3F67FD) : Colors.grey,
        BlendMode.srcIn,
      ),
    );
  }
}
