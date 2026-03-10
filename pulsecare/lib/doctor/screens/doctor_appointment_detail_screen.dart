import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pulsecare/constrains/report_card.dart';
import 'package:pulsecare/model/ai_summary_model.dart';
import 'package:pulsecare/model/appointment_model.dart';
import 'package:pulsecare/model/report_model.dart';
import 'package:pulsecare/providers/repository_providers.dart';
import 'package:pulsecare/utils/time_utils.dart';

class DoctorAppointmentDetailScreen extends StatelessWidget {
  const DoctorAppointmentDetailScreen({super.key, required this.appointment});

  final Appointment appointment;

  @override
  Widget build(BuildContext context) {
    final statusUi = _statusUi(appointment.status);
    final reports = appointment.reports;

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
                child: _ContentSection(
                  appointment: appointment,
                  statusUi: statusUi,
                  reports: reports,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: _ActionSection(status: appointment.status),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContentSection extends ConsumerWidget {
  const _ContentSection({
    required this.appointment,
    required this.statusUi,
    required this.reports,
  });

  final Appointment appointment;
  final _StatusUi statusUi;
  final List<ReportModel> reports;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    AISummaryModel? summary;

    if (appointment.aiSummaryId != null) {
      summary = ref
          .read(aiSummaryRepositoryProvider)
          .getById(appointment.aiSummaryId!);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          appointment.patientName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
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
                  const Spacer(),
                  SvgPicture.asset(
                    'assets/icons/date.svg',
                    width: 16,
                    height: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    TimeUtils.formatDate(appointment.scheduledAt),
                    style: TextStyle(
                      fontSize: 14,
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
                    TimeUtils.formatTime(appointment.scheduledAt),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(top: 14, bottom: 14),
                child: Divider(height: 2, color: Colors.grey.shade300),
              ),
              Row(
                children: [
                  const Text(
                    'Age',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const Spacer(),
                  Text(
                    _ageFromAppointment(appointment),
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
                child: Divider(height: 2, color: Colors.grey.shade300),
              ),
              Row(
                children: [
                  const Text(
                    'Gender',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const Spacer(),
                  Text(
                    _genderFromAppointment(appointment),
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
                    backgroundColor: const Color.fromARGB(255, 180, 212, 255),
                    child: SvgPicture.asset('assets/icons/ai_chat.svg'),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Patient Intake Summary',
                    style: TextStyle(fontWeight: FontWeight.w500, fontSize: 18),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (summary != null) ...[
                _buildSummaryRow('Symptoms', summary.symptoms.join(', ')),
                _buildSummaryRow('Duration', summary.duration ?? 'N/A'),
                _buildSummaryRow('Medications', summary.medications ?? 'N/A'),
                _buildSummaryRow('Severity', summary.severity ?? 'N/A'),
                _buildSummaryRow('Temperature', summary.temperature ?? 'N/A'),
                _buildSummaryRow('Triage Level', summary.triageLevel),
                _buildSummaryRow(
                  'AI Confidence',
                  (summary.confidence * 100).toStringAsFixed(0) + '%',
                ),
              ] else ...[
                Text(
                  appointment.symptoms,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Colors.grey.shade500,
                    height: 1.4,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (reports.isNotEmpty) ...[
          const SizedBox(height: 20),
          const Padding(
            padding: EdgeInsets.only(left: 2),
            child: Text(
              'Uploaded Reports',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: reports.length,
            itemBuilder: (context, index) {
              final report = reports[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Stack(
                  children: [
                    ReportCard(
                      report: report,
                      title: report.title,
                      date:
                          "Uploaded ${TimeUtils.formatDate(report.uploadedAt)}",
                      icon: report.icon,
                      isDoctorView: true,
                      outerPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 20),
        ],
      ],
    );
  }
}

class _ActionSection extends StatelessWidget {
  const _ActionSection({required this.status});

  final AppointmentStatus status;

  @override
  Widget build(BuildContext context) {
    if (status == AppointmentStatus.pending) {
      return Row(
        children: [
          Expanded(
            child: _ActionButton(
              text: 'Reject',
              onTap: () => Navigator.pop(context, AppointmentStatus.cancelled),
              textColor: Colors.black,
              backgroundColor: Colors.grey.shade300,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _GradientActionButton(
              text: 'Accept',
              onTap: () => Navigator.pop(context, AppointmentStatus.confirmed),
            ),
          ),
        ],
      );
    }

    if (status == AppointmentStatus.confirmed) {
      return _GradientActionButton(
        text: 'Mark as Completed',
        onTap: () => Navigator.pop(context, AppointmentStatus.completed),
      );
    }

    if (status == AppointmentStatus.completed) {
      return _ActionButton(
        text: 'Completed',
        onTap: null,
        textColor: Colors.black54,
        backgroundColor: Colors.grey.shade300,
      );
    }

    return _ActionButton(
      text: 'Cancelled',
      onTap: null,
      textColor: Colors.black54,
      backgroundColor: Colors.grey.shade300,
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
            color: Colors.black.withOpacity(0.05),
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
        height: 60,
        decoration: BoxDecoration(
          color: backgroundColor,
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

class _GradientActionButton extends StatelessWidget {
  const _GradientActionButton({required this.text, required this.onTap});

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
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
                text,
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

Widget _buildSummaryRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(child: Text(value)),
      ],
    ),
  );
}
