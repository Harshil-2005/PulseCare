import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pulsecare/appointment_screens/no_appointment_widget.dart';
import 'package:pulsecare/model/appointment_model.dart';
import 'package:pulsecare/utils/time_utils.dart';
import 'doctor_appointment_detail_screen.dart';

class DoctorAppointmentsScreen extends StatefulWidget {
  const DoctorAppointmentsScreen({
    super.key,
    required this.appointments,
    this.onStatusChanged,
  });

  final List<Appointment> appointments;
  final void Function(Appointment, AppointmentStatus)? onStatusChanged;

  @override
  State<DoctorAppointmentsScreen> createState() => DoctorAppointmentsScreenState();
}

class DoctorAppointmentsScreenState extends State<DoctorAppointmentsScreen> {
  int selectedTab = 0;

  void setTab(int index) {
    setState(() {
      selectedTab = index;
    });
  }

  List<Appointment> get upcomingAppointments => widget.appointments
      .where(
        (a) =>
            a.status == AppointmentStatus.pending ||
            a.status == AppointmentStatus.confirmed,
      )
      .toList()
    ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

  List<Appointment> get pastAppointments => widget.appointments
      .where((a) => a.status == AppointmentStatus.completed)
      .toList()
    ..sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));

  List<Appointment> get cancelledAppointments => widget.appointments
      .where((a) => a.status == AppointmentStatus.cancelled)
      .toList()
    ..sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));

  @override
  Widget build(BuildContext context) {
    final tabIndicatorWidth = (MediaQuery.of(context).size.width - 32) / 3;
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 85,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
        elevation: 0.3,
        title: const Center(
          child: Text(
            'Appointments',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
        ),
        shadowColor: Colors.black,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _tabItem('Upcoming', 0),
              _tabItem('Completed', 1),
              _tabItem('Cancelled', 2),
            ],
          ),
          const SizedBox(height: 8),
          Stack(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              AnimatedAlign(
                duration: const Duration(milliseconds: 200),
                alignment: Alignment(
                  selectedTab == 0
                      ? -1
                      : selectedTab == 1
                          ? 0
                          : 1,
                  0,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    width: tabIndicatorWidth,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xff3F67FD),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 25),
          Expanded(
            child: IndexedStack(
              index: selectedTab,
              children: [
                _AppointmentList(
                  items: upcomingAppointments,
                  onStatusChanged: widget.onStatusChanged,
                ),
                _AppointmentList(
                  items: pastAppointments,
                  onStatusChanged: widget.onStatusChanged,
                ),
                _AppointmentList(
                  items: cancelledAppointments,
                  onStatusChanged: widget.onStatusChanged,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabItem(String title, int index) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedTab = index;
        });
      },
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: selectedTab == index ? Colors.black : Colors.grey,
        ),
      ),
    );
  }
}

class _AppointmentList extends StatelessWidget {
  const _AppointmentList({
    required this.items,
    required this.onStatusChanged,
  });

  final List<Appointment> items;
  final void Function(Appointment appointment, AppointmentStatus status)?
      onStatusChanged;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(child: NoAppointmentWidget());
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _DoctorAppointmentPreviewCard(
          item: item,
          onStatusChanged: onStatusChanged,
        );
      },
    );
  }
}

class _DoctorAppointmentPreviewCard extends StatelessWidget {
  const _DoctorAppointmentPreviewCard({
    required this.item,
    required this.onStatusChanged,
  });

  final Appointment item;
  final void Function(Appointment appointment, AppointmentStatus status)?
      onStatusChanged;

  @override
  Widget build(BuildContext context) {
    final status = _statusUi(item.status);

    return Padding(
      padding: const EdgeInsets.only(top: 16, left: 16, right: 16),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DoctorAppointmentDetailScreen(appointment: item),
            ),
          );
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
                    Row(
                      children: [
                        SvgPicture.asset(
                          'assets/icons/date.svg',
                          width: 16,
                          height: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          TimeUtils.formatDate(item.scheduledAt),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text('|', style: TextStyle(color: Colors.grey)),
                        const SizedBox(width: 8),
                        SvgPicture.asset(
                          'assets/icons/round.svg',
                          width: 16,
                          height: 16,
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
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  item.patientName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  '${_ageFromAppointment(item)} | ${_genderFromAppointment(item)}',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  item.symptoms,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                if (item.reports.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Row(
                    children: [
                      Icon(Icons.description, size: 14, color: Colors.grey),
                      SizedBox(width: 6),
                      Text(
                        'Reports available',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
                if (item.status == AppointmentStatus.pending) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _ActionButton(
                          text: 'Reject',
                          onTap: () {
                            onStatusChanged?.call(
                              item,
                              AppointmentStatus.cancelled,
                            );
                          },
                          textColor: Colors.black,
                          backgroundColor: Colors.grey.shade300,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _GradientActionButton(
                          text: 'Accept',
                          onTap: () {
                            onStatusChanged?.call(
                              item,
                              AppointmentStatus.confirmed,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
                if (item.status == AppointmentStatus.confirmed) ...[
                  const SizedBox(height: 12),
                  _GradientActionButton(
                    text: 'Mark Completed',
                    onTap: () {
                      onStatusChanged?.call(
                        item,
                        AppointmentStatus.completed,
                      );
                    },
                  ),
                ],
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

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.text,
    this.onTap,
    required this.textColor,
    this.backgroundColor = Colors.white,
  });

  final String text;
  final VoidCallback? onTap;
  final Color textColor;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }
}

class _GradientActionButton extends StatelessWidget {
  const _GradientActionButton({
    required this.text,
    required this.onTap,
  });

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: const Color(0xff3F67FD),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Center(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }
}

String _ageFromAppointment(Appointment appointment) {
  try {
    final dynamic rawAge = (appointment as dynamic).age;
    if (rawAge == null) return '32';
    final value = rawAge.toString().trim();
    return value.isEmpty ? '32' : value;
  } catch (_) {
    return '32';
  }
}

String _genderFromAppointment(Appointment appointment) {
  try {
    final dynamic rawGender = (appointment as dynamic).gender;
    if (rawGender == null) return 'Female';
    final value = rawGender.toString().trim();
    return value.isEmpty ? 'Female' : value;
  } catch (_) {
    return 'Female';
  }
}
