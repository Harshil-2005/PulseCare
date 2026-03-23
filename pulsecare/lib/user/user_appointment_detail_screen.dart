import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pulsecare/constrains/app_toast.dart';
import 'package:pulsecare/constrains/upload_report_bottom_sheet.dart';
import 'package:pulsecare/model/appointment_model.dart';
import 'package:pulsecare/model/report_model.dart';
import 'package:pulsecare/providers/repository_providers.dart';
import 'package:pulsecare/user/patient_detail_screen.dart';
import 'package:pulsecare/user/review_bottom_sheet.dart';
import 'package:pulsecare/utils/report_open_utils.dart';
import 'package:pulsecare/utils/time_utils.dart';

class UserAppointmentDetailScreen extends ConsumerStatefulWidget {
  const UserAppointmentDetailScreen({super.key, required this.appointment});

  final Appointment appointment;

  @override
  ConsumerState<UserAppointmentDetailScreen> createState() =>
      _UserAppointmentDetailScreenState();
}

class _UserAppointmentDetailScreenState
    extends ConsumerState<UserAppointmentDetailScreen> {
  late final TextEditingController _symptomsController;
  late List<ReportModel> _reports;
  late bool _reviewSubmitted;

  @override
  void initState() {
    super.initState();
    _symptomsController = TextEditingController(
      text: widget.appointment.symptoms,
    );
    _reports = List<ReportModel>.from(widget.appointment.reports);
    _reviewSubmitted = widget.appointment.reviewSubmitted;
  }

  @override
  void dispose() {
    _symptomsController.dispose();
    super.dispose();
  }

  void _openUploadSheet() {
    showUploadReportBottomSheet(
      context,
      appointmentId: widget.appointment.id,
      userId: widget.appointment.userId,
      doctorId: widget.appointment.doctorId,
      onReportUploaded: (report) {
        if (!mounted) return;
        setState(() {
          _reports.add(report);
        });
      },
    );
  }

  Future<void> _saveChanges() async {
    final updated = widget.appointment.copyWith(
      symptoms: _symptomsController.text,
      reports: _reports,
    );
    await ref.read(appointmentRepositoryProvider).updateAppointment(updated);
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final appointment = widget.appointment;
    final statusUi = _statusUi(appointment.status);
    final isEditable =
        widget.appointment.status == AppointmentStatus.pending ||
        widget.appointment.status == AppointmentStatus.confirmed;
    final canLeaveReview =
        appointment.status == AppointmentStatus.completed && !_reviewSubmitted;

    return Scaffold(
      appBar: AppBar(
        leadingWidth: 40,
        titleSpacing: 0,
        toolbarHeight: 85,
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(18)),
        ),
        elevation: 0.3,
        shadowColor: Colors.black,
        title: const Text(
          'Appointment Details',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        automaticallyImplyLeading: true,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: SvgPicture.asset(
            'assets/icons/backarrow.svg',
            width: 24,
            height: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appointment.patientName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _BaseCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              _StatusBadge(
                                text: statusUi.text,
                                color: statusUi.color,
                                backgroundColor: statusUi.backgroundColor,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    SvgPicture.asset(
                                      'assets/icons/date.svg',
                                      width: 16,
                                      height: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        TimeUtils.formatDate(
                                          appointment.scheduledAt,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      '|',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                    const SizedBox(width: 8),
                                    SvgPicture.asset(
                                      'assets/icons/round.svg',
                                      width: 16,
                                      height: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        TimeUtils.formatTime(
                                          appointment.scheduledAt,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 14, bottom: 14),
                            child: Divider(
                              height: 2,
                              color: Colors.grey.shade300,
                            ),
                          ),
                          Row(
                            children: [
                              const Text(
                                'Age',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                appointment.age.toString(),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 14, bottom: 14),
                            child: Divider(
                              height: 2,
                              color: Colors.grey.shade300,
                            ),
                          ),
                          Row(
                            children: [
                              const Text(
                                'Gender',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                appointment.gender,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    _BaseCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: const Color.fromARGB(
                                  255,
                                  180,
                                  212,
                                  255,
                                ),
                                child: SvgPicture.asset(
                                  'assets/icons/ai_chat.svg',
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Patient Intake Summary',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (isEditable)
                            TextField(
                              controller: _symptomsController,
                              maxLines: null,
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText: 'Write here...',
                                hintStyle: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 16,
                                ),
                              ),
                            )
                          else
                            Text(
                              _symptomsController.text,
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 16,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Padding(
                      padding: EdgeInsets.only(left: 2),
                      child: Text(
                        'Uploaded Reports',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _BaseCard(
                      child: Column(
                        children: [
                          if (isEditable)
                            InkWell(
                              onTap: _openUploadSheet,
                              child: Container(
                                width: double.infinity,
                                height: 55,
                                decoration: BoxDecoration(
                                  color: const Color(0xff3F67FD),
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: Center(
                                  child: Text(
                                    _reports.isEmpty
                                        ? 'Upload Report'
                                        : '+ Add More',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          if (_reports.isEmpty) ...[
                            const SizedBox(height: 12),
                            Text(
                              isEditable
                                  ? 'No reports attached yet'
                                  : 'No reports attached',
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ] else ...[
                            const SizedBox(height: 14),
                            Column(
                              children: List.generate(_reports.length, (index) {
                                final report = _reports[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(10),
                                    onTap: () async {
                                      final opened = await openReportExternally(
                                        report,
                                      );
                                      if (!mounted || opened) return;
                                      showAppToast(
                                        context,
                                        'Unable to open PDF reader on this device',
                                      );
                                    },
                                    child: Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF7F8FD),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.insert_drive_file_outlined,
                                            size: 20,
                                            color: Colors.grey.shade700,
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  report.title,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  "Uploaded ${TimeUtils.formatDate(report.uploadedAt)}",
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey.shade600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (isEditable)
                                            InkWell(
                                              onTap: () {
                                                setState(() {
                                                  _reports.removeAt(index);
                                                });
                                              },
                                              child: Padding(
                                                padding: const EdgeInsets.all(
                                                  4,
                                                ),
                                                child: SvgPicture.asset(
                                                  'assets/icons/delete.svg',
                                                  width: 18,
                                                  height: 18,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (canLeaveReview) ...[
                    InkWell(
                      onTap: () async {
                        final submitted = await showModalBottomSheet<bool>(
                          context: context,
                          isScrollControlled: true,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(24),
                            ),
                          ),
                          builder: (context) => ReviewBottomSheet(
                            appointment: widget.appointment,
                          ),
                        );
                        if (!mounted) return;
                        if (submitted == true) {
                          setState(() {
                            _reviewSubmitted = true;
                          });
                        }
                      },
                      borderRadius: BorderRadius.circular(30),
                      child: Container(
                        height: 55,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: const Color(0xff3F67FD)),
                        ),
                        child: const Center(
                          child: Text(
                            'Leave Review',
                            style: TextStyle(
                              color: Color(0xff3F67FD),
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  InkWell(
                    onTap: isEditable
                        ? () => _saveChanges()
                        : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PatientDetailScreen(
                                  doctor: widget.appointment.resolvedDoctor,
                                  prefilledAge: widget.appointment.age,
                                  prefilledGender: widget.appointment.gender,
                                  prefilledSymptoms: null,
                                ),
                              ),
                            );
                          },
                    borderRadius: BorderRadius.circular(30),
                    child: Container(
                      height: 60,
                      decoration: BoxDecoration(
                        color: const Color(0xff3F67FD),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              isEditable ? 'Save Changes' : 'Book Again',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                                fontSize: 16,
                              ),
                            ),
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
      ),
    );
  }
}

class _BaseCard extends StatelessWidget {
  const _BaseCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
        child: child,
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
        mainAxisSize: MainAxisSize.min,
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
