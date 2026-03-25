import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pulsecare/constrains/report_card.dart';
import 'package:pulsecare/model/ai_summary_model.dart';
import 'package:pulsecare/model/appointment_model.dart';
import 'package:pulsecare/model/report_model.dart';
import 'package:pulsecare/providers/repository_providers.dart';
import 'package:pulsecare/utils/time_utils.dart';
import 'package:pulsecare/data/triage/triage_data.dart';

class DoctorAppointmentDetailScreen extends ConsumerStatefulWidget {
  const DoctorAppointmentDetailScreen({super.key, required this.appointment});

  final Appointment appointment;

  @override
  ConsumerState<DoctorAppointmentDetailScreen> createState() =>
      _DoctorAppointmentDetailScreenState();
}

class _DoctorAppointmentDetailScreenState
    extends ConsumerState<DoctorAppointmentDetailScreen> {
  late AppointmentStatus _status;
  bool _isUpdatingStatus = false;
  AppointmentStatus? _updatingTargetStatus;

  @override
  void initState() {
    super.initState();
    _status = widget.appointment.status;
  }

  Future<void> _updateStatus(AppointmentStatus targetStatus) async {
    if (_isUpdatingStatus || _status == targetStatus) {
      return;
    }
    setState(() {
      _isUpdatingStatus = true;
      _updatingTargetStatus = targetStatus;
    });

    try {
      await ref
          .read(appointmentRepositoryProvider)
          .updateAppointmentStatus(widget.appointment.id, targetStatus);
      if (!mounted) return;
      setState(() {
        _status = targetStatus;
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isUpdatingStatus = false;
        _updatingTargetStatus = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusUi = _statusUi(_status);
    final reports = widget.appointment.reports;

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
                  appointment: widget.appointment,
                  statusUi: statusUi,
                  reports: reports,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: _ActionSection(
                status: _status,
                isUpdating: _isUpdatingStatus,
                updatingTargetStatus: _updatingTargetStatus,
                onStatusSelected: _updateStatus,
              ),
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
    final summaryFuture = appointment.aiSummaryId == null
        ? null
        : ref
              .read(aiSummaryRepositoryProvider)
              .getByIdAsync(appointment.aiSummaryId!);

    return FutureBuilder<AISummaryModel?>(
      future: summaryFuture,
      builder: (context, summarySnapshot) {
        final summary = summarySnapshot.data;

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
                                TimeUtils.formatDate(appointment.scheduledAt),
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
                                TimeUtils.formatTime(appointment.scheduledAt),
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
                    child: Divider(height: 2, color: Colors.grey.shade300),
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
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
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
                        backgroundColor: const Color.fromARGB(
                          255,
                          180,
                          212,
                          255,
                        ),
                        child: SvgPicture.asset('assets/icons/ai_chat.svg'),
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
                  if (summary != null) ...[
                    _buildSummaryRow(
                      'Symptoms',
                      summary.symptoms
                          .map(_formatSymptomLabel)
                          .where((value) => value.isNotEmpty)
                          .join(', '),
                    ),
                    _buildSummaryRow('Duration', summary.duration ?? 'N/A'),
                    if (_shouldShowFrequency(
                      summary.symptoms,
                      summary.frequency,
                    ))
                      _buildSummaryRow('Frequency', summary.frequency!.trim()),
                    _buildSummaryRow(
                      'Medications',
                      summary.medications ?? 'N/A',
                    ),
                    _buildSummaryRow('Severity', summary.severity ?? 'N/A'),
                    _buildSummaryRow(
                      'Temperature',
                      summary.temperature ?? 'N/A',
                    ),
                    if (summary.followUpAnswers.isNotEmpty)
                      _buildSummaryRow(
                        'Follow-ups',
                        summary.followUpAnswers.entries
                            .map(
                              (entry) =>
                                  '${_followUpLabelFromId(entry.key)}: ${entry.value}',
                            )
                            .join(', '),
                      ),
                    _buildSummaryRow('Triage Level', summary.triageLevel),
                    _buildSummaryRow(
                      'AI Confidence',
                      '${(summary.confidence * 100).toStringAsFixed(0)}%',
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
                physics: const NeverScrollableScrollPhysics(),
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
                              'Uploaded ${TimeUtils.formatDate(report.uploadedAt)}',
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
      },
    );
  }
}

class _ActionSection extends StatelessWidget {
  const _ActionSection({
    required this.status,
    required this.isUpdating,
    required this.updatingTargetStatus,
    required this.onStatusSelected,
  });

  final AppointmentStatus status;
  final bool isUpdating;
  final AppointmentStatus? updatingTargetStatus;
  final ValueChanged<AppointmentStatus> onStatusSelected;

  @override
  Widget build(BuildContext context) {
    if (status == AppointmentStatus.pending) {
      return Row(
        children: [
          Expanded(
            child: _ActionButton(
              text:
                  isUpdating &&
                      updatingTargetStatus == AppointmentStatus.cancelled
                  ? 'Rejecting...'
                  : 'Reject',
              onTap: isUpdating
                  ? null
                  : () => onStatusSelected(AppointmentStatus.cancelled),
              textColor: Colors.black,
              backgroundColor: Colors.grey.shade300,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _GradientActionButton(
              text:
                  isUpdating &&
                      updatingTargetStatus == AppointmentStatus.confirmed
                  ? 'Accepting...'
                  : 'Accept',
              onTap: isUpdating
                  ? null
                  : () => onStatusSelected(AppointmentStatus.confirmed),
            ),
          ),
        ],
      );
    }

    if (status == AppointmentStatus.confirmed) {
      return _GradientActionButton(
        text: isUpdating && updatingTargetStatus == AppointmentStatus.completed
            ? 'Mark as Completing...'
            : 'Mark as Completed',
        onTap: isUpdating
            ? null
            : () => onStatusSelected(AppointmentStatus.completed),
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
  final VoidCallback? onTap;

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

String _followUpLabelFromId(String id) {
  final question = _followUpQuestionById(id);
  if (question != null) {
    return _labelOverride(id) ?? _capitalize(_labelFromQuestion(question));
  }
  var fallback = id.trim();
  for (final symptom in triageSymptoms) {
    final prefix = '${symptom.id}_';
    if (fallback.startsWith(prefix)) {
      fallback = fallback.substring(prefix.length);
      break;
    }
  }
  return _labelOverride(id) ??
      _capitalize(fallback.replaceAll('_', ' ').trim());
}

String _capitalize(String value) {
  if (value.isEmpty) return value;
  return '${value[0].toUpperCase()}${value.substring(1)}';
}

String _formatSymptomLabel(String symptom) {
  final normalized = symptom.replaceAll('_', ' ').trim();
  if (normalized.isEmpty) return normalized;
  final words = normalized
      .split(' ')
      .where((word) => word.isNotEmpty)
      .map(
        (word) => '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}',
      )
      .toList(growable: false);
  return words.join(' ');
}

bool _shouldShowFrequency(List<String> symptoms, String? frequency) {
  if (frequency == null || frequency.trim().isEmpty) return false;
  const frequencySymptoms = <String>{
    'headache',
    'palpitations',
    'dizziness',
    'nausea',
    'vomiting',
    'diarrhea',
    'constipation',
    'sneezing',
    'anxiety',
    'muscle_pain',
  };
  return symptoms.any(frequencySymptoms.contains);
}

String? _followUpQuestionById(String id) {
  for (final symptom in triageSymptoms) {
    for (final followUp in symptom.followUps) {
      if (followUp.id == id) {
        return followUp.question;
      }
      for (final option in followUp.options) {
        if (option.id == id) {
          return option.label;
        }
      }
    }
  }
  return null;
}

String _labelFromQuestion(String question) {
  var label = question.trim();
  label = label.replaceAll('?', '').trim();
  final lower = label.toLowerCase();
  final prefixes = [
    'do you have ',
    'do you ',
    'are you ',
    'have you ',
    'did you ',
    'is your ',
    'is the ',
    'is it ',
    'is ',
    'where is ',
    'where on your body is ',
    'where exactly is ',
    'where exactly is the ',
    'how long have you had ',
    'how long have you been ',
    'how long do ',
    'how long ',
    'how often are ',
    'how often ',
    'how many ',
    'did this ',
    'does it ',
    'does the ',
    'are there ',
    'have you been ',
    'how high has your ',
    'how high has ',
  ];
  for (final prefix in prefixes) {
    if (lower.startsWith(prefix)) {
      label = label.substring(prefix.length);
      break;
    }
  }
  label = label.trimLeft();
  for (final article in ['a ', 'an ', 'the ']) {
    if (label.toLowerCase().startsWith(article)) {
      label = label.substring(article.length);
      break;
    }
  }
  return label.trim();
}

String? _labelOverride(String id) {
  const overrides = <String, String>{
    'fever_chills': 'Chills',
    'fever_body_aches': 'Body aches',
    'fever_sore_throat': 'Sore throat',
    'fever_taken_any_medicine_to_reduce_fever': 'Medication to reduce fever',
    'cough_cough_dry': 'Dry cough',
    'cough_wheezing': 'Wheezing',
    'cold_a_runny_nose': 'Runny nose',
    'cold_experiencing_a_sore_throat': 'Sore throat',
    'cold_chills': 'Chills',
    'headache_pain_located': 'Pain location',
    'headache_nausea': 'Nausea',
    'headache_where_is_the_pain_located': 'Pain location',
    'headache_how_severe_is_the_pain': 'Pain severity',
    'chest_pain_pain_sharp': 'Sharp pain',
    'chest_pain_spread_to_arm': 'Pain radiates to arm',
    'chest_pain_worsen_with_exertion': 'Worse with exertion',
    'shortness_of_breath_start_suddenly': 'Sudden onset',
    'shortness_of_breath_short_of_breath_at_rest':
        'Shortness of breath at rest',
    'shortness_of_breath_chest_pain': 'Chest pain',
    'rash_rash': 'Rash location',
    'rash_itchy': 'Itching',
    'rash_recently_use_a_new_soap': 'New soap exposure',
    'stomach_pain_pain_in_abdomen': 'Abdominal pain location',
    'stomach_pain_related_to_meals': 'Related to meals',
    'stomach_pain_pain_constant': 'Constant pain',
    'stomach_pain_how_severe_is_the_pain': 'Pain severity',
    'stomach_pain_is_it_constant_or_cramping': 'Pain pattern',
    'back_pain_pain_in_lower_back': 'Lower back pain',
    'back_pain_did_it_start_after_lifting': 'Started after lifting',
    'back_pain_numbness_in_legs': 'Leg numbness',
    'dizziness_feel_spinning': 'Spinning sensation',
    'dizziness_nausea': 'Nausea',
    'fatigue_fatigue_affecting_daily_activities': 'Affects daily activities',
    'fatigue_weight_change': 'Weight change',
    'sore_throat_swollen_glands': 'Swollen glands',
    'sore_throat_swallowing_painful': 'Painful swallowing',
    'runny_nose_discharge_clear': 'Clear discharge',
    'runny_nose_sinus_pressure': 'Sinus pressure',
    'vomiting_times_have_you_vomited_today': 'Vomiting count (today)',
    'vomiting_able_to_keep_fluids_down': 'Able to keep fluids down',
    'vomiting_abdominal_pain': 'Abdominal pain',
    'diarrhea_there_blood_in_stool': 'Blood in stool',
    'diarrhea_vomiting': 'Vomiting',
    'constipation_abdominal_pain': 'Abdominal pain',
    'constipation_tried_any_laxatives': 'Tried laxatives',
    'joint_pain_affected': 'Affected joints',
    'joint_pain_do_joints_feel_swollen': 'Joint swelling',
    'joint_pain_pain_start_after_injury': 'Started after injury',
    'ear_pain_which_ear_is_affected': 'Affected ear',
    'ear_pain_do_you_have_hearing_loss': 'Hearing loss',
    'ear_pain_do_you_have_discharge': 'Discharge',
    'ear_pain_do_you_have_fever': 'Fever',
    'ear_pain_did_this_start_after_a_cold_or_swimming':
        'Started after cold or swimming',
    'eye_redness_one_eye_affected': 'One eye affected',
    'eye_redness_blurred_vision': 'Blurred vision',
    'eye_redness_been_exposed_to_allergens': 'Allergen exposure',
    'skin_swelling_swelling': 'Swelling location',
    'skin_swelling_area_red': 'Redness',
    'skin_swelling_have_an_injury': 'Injury',
    'palpitations_do_they_occur_at_rest': 'Occurs at rest',
    'palpitations_chest_pain': 'Chest pain',
    'sneezing_sneezing_worse_in_morning': 'Worse in morning',
    'sneezing_a_runny_nose': 'Runny nose',
    'sneezing_recently_had_cold_exposure': 'Cold exposure',
    'nasal_congestion_facial_pressure': 'Facial pressure',
    'nasal_congestion_congestion_affecting_sleep': 'Affects sleep',
    'nausea_vomiting': 'Vomiting',
    'nausea_start_after_eating': 'Started after eating',
    'acid_reflux_do_symptoms_worsen_after_meals': 'Worse after meals',
    'acid_reflux_feel_a_burning_sensation_in_chest': 'Burning in chest',
    'acid_reflux_tried_antacids': 'Tried antacids',
    'itching_itching_most': 'Itching location',
    'itching_a_rash_with_itching': 'Rash with itching',
    'itching_recently_use_a_new_soap': 'New soap exposure',
    'neck_pain_neck_pain_start_after_poor_posture':
        'Started after poor posture',
    'neck_pain_pain_spread_to_shoulder': 'Radiates to shoulder',
    'neck_pain_feel_numbness_in_arms': 'Arm numbness',
    'muscle_pain_painful': 'Painful muscles',
    'muscle_pain_begin_after_exertion': 'Started after exertion',
    'muscle_pain_also_have_weakness': 'Weakness',
    'eye_pain_one_eye_painful': 'One eye painful',
    'eye_pain_redness_in_eye': 'Eye redness',
    'eye_pain_pain_start_after_screen_strain': 'Started after screen strain',
    'anxiety_do_you_feel_anxious': 'Feeling anxious',
    'anxiety_palpitations_during_episodes': 'Palpitations during episodes',
    'anxiety_anxiety_affecting_sleep': 'Affects sleep',
  };
  return overrides[id];
}
