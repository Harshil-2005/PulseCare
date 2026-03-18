import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:pulsecare/constrains/upload_report_bottom_sheet.dart';
import 'package:pulsecare/model/doctor_model.dart';
import 'package:pulsecare/model/report_model.dart';
import 'package:pulsecare/providers/repository_providers.dart';
import 'package:pulsecare/repositories/session_repository.dart';
import 'package:pulsecare/user/date_time_screen.dart';
import 'package:pulsecare/utils/time_utils.dart';
import 'package:pulsecare/data/triage/triage_data.dart';

class PatientDetailScreen extends ConsumerStatefulWidget {
  final Doctor doctor;
  final String? prefilledSymptoms;
  final int? prefilledAge;
  final String? prefilledGender;
  final String? aiSummaryId;

  const PatientDetailScreen({
    super.key,
    required this.doctor,
    this.prefilledSymptoms,
    this.prefilledAge,
    this.prefilledGender,
    this.aiSummaryId,
  });

  @override
  ConsumerState<PatientDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends ConsumerState<PatientDetailScreen> {
  final TextEditingController ageController = TextEditingController();
  final TextEditingController symptomsController = TextEditingController();
  List<ReportModel> _selectedReports = [];

  final List<String> bookfor = ['Self', 'Other'];
  final List<String> gender = ['Male', 'Female', 'Other'];
  bool isOpen = false;
  bool isGenderOpen = false;
  String selectbookfor = "Self";
  String selectgender = "";
  String patientName = "";
  final LayerLink _bookingLink = LayerLink();
  final LayerLink _genderLink = LayerLink();
  OverlayEntry? _bookingOverlay;
  OverlayEntry? _genderOverlay;
  bool _ready = false;
  dynamic _currentUser;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final user = await ref
        .read(userRepositoryProvider)
        .getUserById(SessionRepository().getCurrentUserId());
    _currentUser = user;
    selectgender = widget.prefilledGender ?? (user?.gender ?? '');
    ageController.text =
        widget.prefilledAge?.toString() ?? (user?.age.toString() ?? '');
    patientName = user?.fullName ?? '';
    symptomsController.text = widget.prefilledSymptoms ?? '';

    final summaryId = widget.aiSummaryId;

    if (summaryId != null) {
      final summary = await ref
          .read(aiSummaryRepositoryProvider)
          .getByIdAsync(summaryId);

      if (summary != null) {
        final buffer = StringBuffer();
        final formattedSymptoms = summary.symptoms
            .map(_formatSymptomLabel)
            .where((value) => value.isNotEmpty)
            .join(', ');
        buffer.writeln('Symptoms: $formattedSymptoms');
        buffer.writeln('Duration: ${summary.duration ?? "N/A"}');
        if (_shouldShowFrequency(summary.symptoms, summary.frequency)) {
          buffer.writeln('Frequency: ${summary.frequency!.trim()}');
        }
        buffer.writeln('Medications: ${summary.medications ?? "N/A"}');
        buffer.writeln('Severity: ${summary.severity ?? "N/A"}');

        final hasFever = summary.symptoms.any(
          (symptom) => symptom.toLowerCase() == 'fever',
        );
        if (hasFever) {
          buffer.writeln('Temperature: ${summary.temperature ?? "N/A"}');
        }

        if (summary.followUpAnswers.isNotEmpty) {
          for (final entry in summary.followUpAnswers.entries) {
            final label = _followUpLabelFromId(entry.key);
            buffer.writeln('$label: ${entry.value}');
          }
        }

        symptomsController.text = buffer.toString();
      }
    }
    if (!mounted) return;
    setState(() {
      _ready = true;
    });
  }

  double _twoColumnFieldWidth(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final availableWidth = screenWidth - 32 - 12;
    final width = availableWidth / 2;
    return width.clamp(130.0, 175.0);
  }

  String _capitalize(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return trimmed;
    return '${trimmed[0].toUpperCase()}${trimmed.substring(1)}';
  }

  String _formatSymptomLabel(String symptom) {
    final normalized = symptom.replaceAll('_', ' ').trim();
    if (normalized.isEmpty) return normalized;
    final words = normalized
        .split(' ')
        .where((word) => word.isNotEmpty)
        .map((word) =>
            '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}')
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
    return _labelOverride(id) ?? _capitalize(fallback.replaceAll('_', ' '));
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
      'fever_taken_any_medicine_to_reduce_fever':
          'Medication to reduce fever',
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
      'shortness_of_breath_short_of_breath_at_rest': 'Shortness of breath at rest',
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
      'neck_pain_neck_pain_start_after_poor_posture': 'Started after poor posture',
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

  @override
  void dispose() {
    _removeBookingOverlay();
    _removeGenderOverlay();
    ageController.dispose();
    symptomsController.dispose();
    super.dispose();
  }

  void _toggleBookingDropdown() {
    if (isOpen) {
      _removeBookingOverlay();
      return;
    }
    _removeGenderOverlay();
    setState(() {
      isOpen = true;
      isGenderOpen = false;
    });

    _bookingOverlay = _createDropdownOverlay(
      link: _bookingLink,
      width: MediaQuery.of(context).size.width - 32,
      selectedValue: selectbookfor,
      options: bookfor,
      onSelected: (value) {
        setState(() {
          selectbookfor = value;
        });
        _removeBookingOverlay();
      },
      onDismiss: _removeBookingOverlay,
    );
    Overlay.of(context).insert(_bookingOverlay!);
  }

  void _toggleGenderDropdown() {
    if (isGenderOpen) {
      _removeGenderOverlay();
      return;
    }
    _removeBookingOverlay();
    setState(() {
      isGenderOpen = true;
      isOpen = false;
    });

    _genderOverlay = _createDropdownOverlay(
      link: _genderLink,
      width: _twoColumnFieldWidth(context),
      selectedValue: selectgender,
      options: gender,
      onSelected: (value) {
        setState(() {
          selectgender = value;
        });
        _removeGenderOverlay();
      },
      onDismiss: _removeGenderOverlay,
    );
    Overlay.of(context).insert(_genderOverlay!);
  }

  void _removeBookingOverlay() {
    _bookingOverlay?.remove();
    _bookingOverlay = null;
    if (isOpen && mounted) {
      setState(() {
        isOpen = false;
      });
    }
  }

  void _removeGenderOverlay() {
    _genderOverlay?.remove();
    _genderOverlay = null;
    if (isGenderOpen && mounted) {
      setState(() {
        isGenderOpen = false;
      });
    }
  }

  OverlayEntry _createDropdownOverlay({
    required LayerLink link,
    required double width,
    required String selectedValue,
    required List<String> options,
    required ValueChanged<String> onSelected,
    required VoidCallback onDismiss,
  }) {
    return OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: onDismiss,
              child: const SizedBox.expand(),
            ),
          ),
          CompositedTransformFollower(
            link: link,
            showWhenUnlinked: false,
            offset: const Offset(0, 0),
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: width,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(blurRadius: 12, color: Colors.grey.shade300),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: onDismiss,
                        child: Container(
                          color: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                selectedValue,
                                style: const TextStyle(fontSize: 16),
                              ),
                              SizedBox(
                                width: 20,
                                child: Transform.rotate(
                                  angle: -pi,
                                  child: Image.asset(
                                    'assets/images/dropdown_arrow.png',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      ...options.asMap().entries.map((entry) {
                        final index = entry.key;
                        final value = entry.value;
                        return InkWell(
                          onTap: () => onSelected(value),
                          child: Padding(
                            padding: EdgeInsets.only(
                              top: 10,
                              bottom: index == options.length - 1 ? 10 : 0,
                            ),
                            child: Container(
                              width: double.infinity,
                              height: 40,
                              color: const Color(0xFFE7E7E7),
                              alignment: Alignment.centerLeft,
                              padding: const EdgeInsets.only(left: 16),
                              child: Text(value),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final user = _currentUser;
    return Scaffold(
      appBar: AppBar(
        leadingWidth: 40,
        titleSpacing: 0,
        toolbarHeight: 85,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
        elevation: 0.3,
        centerTitle: true,
        title: Text(
          'Patient Details',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        shadowColor: Colors.black,
        automaticallyImplyLeading: true,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: SvgPicture.asset(
            'assets/icons/backarrow.svg',
            width: 24,
            height: 20,
          ),
        ),
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          FocusScope.of(context).unfocus();
          FocusManager.instance.primaryFocus?.unfocus();
        },
        child: SingleChildScrollView(
          child: Column(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 50),
                  Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: Text(
                      'Booking for',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                      top: 10,
                      right: 16,
                      left: 16,
                    ),
                    child: CompositedTransformTarget(
                      link: _bookingLink,
                      child: InkWell(
                        onTap: _toggleBookingDropdown,
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                blurRadius: 12,
                                color: Colors.grey.shade300,
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  selectbookfor,
                                  style: TextStyle(fontSize: 16),
                                ),
                                isOpen
                                    ? SizedBox(
                                        width: 20,
                                        child: Transform.rotate(
                                          angle: -pi,
                                          child: Image.asset(
                                            'assets/images/dropdown_arrow.png',
                                          ),
                                        ),
                                      )
                                    : SizedBox(
                                        width: 20,
                                        child: Image.asset(
                                          'assets/images/dropdown_arrow.png',
                                        ),
                                      ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 22),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16),
                child: Row(
                  children: [
                    SizedBox(
                      width: _twoColumnFieldWidth(context),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Age',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 18,
                            ),
                          ),
                          SizedBox(height: 10),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  blurRadius: 12,
                                  color: Colors.grey.shade300,
                                ),
                              ],
                            ),
                            height: 55,
                            width: _twoColumnFieldWidth(context),
                            child: TextField(
                              keyboardType: TextInputType.number,
                              controller: ageController,
                              onTapOutside: (_) {
                                FocusScope.of(context).unfocus();
                                FocusManager.instance.primaryFocus?.unfocus();
                              },
                              decoration: InputDecoration(
                                hintText: user?.age.toString() ?? '',
                                hintStyle: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w300,
                                  fontSize: 16,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade100,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade100,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Spacer(),
                    SizedBox(
                      width: _twoColumnFieldWidth(context),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Gender',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 18,
                            ),
                          ),
                          SizedBox(height: 10),
                          CompositedTransformTarget(
                            link: _genderLink,
                            child: InkWell(
                              onTap: _toggleGenderDropdown,
                              child: Container(
                                width: _twoColumnFieldWidth(context),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      blurRadius: 12,
                                      color: Colors.grey.shade300,
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 16,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        selectgender,
                                        style: TextStyle(fontSize: 16),
                                      ),
                                      isGenderOpen
                                          ? SizedBox(
                                              width: 20,
                                              child: Transform.rotate(
                                                angle: -pi,
                                                child: Image.asset(
                                                  'assets/images/dropdown_arrow.png',
                                                ),
                                              ),
                                            )
                                          : SizedBox(
                                              width: 20,
                                              child: Image.asset(
                                                'assets/images/dropdown_arrow.png',
                                              ),
                                            ),
                                    ],
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
              Padding(
                padding: const EdgeInsets.only(top: 20, left: 16, right: 16),
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.topLeft,
                      child: Text(
                        'Symptoms',

                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      height: 170,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 12,
                            color: Colors.grey.shade300,
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.only(top: 20, left: 16),
                        child: SingleChildScrollView(
                          child: TextField(
                            keyboardType: TextInputType.text,
                            controller: symptomsController,
                            maxLines: null,
                            onTapOutside: (_) {
                              FocusScope.of(context).unfocus();
                              FocusManager.instance.primaryFocus?.unfocus();
                            },

                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Write here...',

                              hintStyle: TextStyle(
                                color: Colors.grey,
                                fontWeight: FontWeight.w300,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 20, left: 16, right: 16),
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.topLeft,
                      child: Text(
                        'Upload Reports (Optional)',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 12,
                            color: Colors.grey.shade300,
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: _selectedReports.isEmpty
                            ? Column(
                                children: [
                                  Center(
                                    child: InkWell(
                                      onTap: () {
                                        showUploadReportBottomSheet(
                                          context,
                                          onReportUploaded: (report) {
                                            if (!mounted) return;
                                            final alreadyExists =
                                                _selectedReports.any(
                                                  (r) =>
                                                      r.pdfPath ==
                                                      report.pdfPath,
                                                );

                                            if (!alreadyExists) {
                                              setState(() {
                                                _selectedReports.add(report);
                                              });
                                            }
                                          },
                                        );
                                      },
                                      child: Container(
                                        width: double.infinity,
                                        height: 55,
                                        decoration: BoxDecoration(
                                          color: const Color(0xff3F67FD),
                                          borderRadius: BorderRadius.circular(
                                            30,
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            'Upload Report',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 12),
                                  Text(
                                    'No reports attached yet',
                                    style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                children: [
                                  InkWell(
                                    onTap: () {
                                      showUploadReportBottomSheet(
                                        context,
                                        onReportUploaded: (report) {
                                          if (!mounted) return;
                                          final alreadyExists = _selectedReports
                                              .any(
                                                (r) =>
                                                    r.pdfPath == report.pdfPath,
                                              );

                                          if (!alreadyExists) {
                                            setState(() {
                                              _selectedReports.add(report);
                                            });
                                          }
                                        },
                                      );
                                    },
                                    child: Container(
                                      width: double.infinity,
                                      height: 55,
                                      decoration: BoxDecoration(
                                        color: const Color(0xff3F67FD),
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                      child: Center(
                                        child: Text(
                                          '+ Add More',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 14),
                                  Column(
                                    children: List.generate(
                                      _selectedReports.length,
                                      (index) {
                                        final report = _selectedReports[index];
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 10,
                                          ),
                                          child: Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 10,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF7F8FD),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons
                                                      .insert_drive_file_outlined,
                                                  size: 20,
                                                  color: Colors.grey.shade700,
                                                ),
                                                SizedBox(width: 10),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        report.title,
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: const TextStyle(
                                                          fontSize: 14,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        "Uploaded ${TimeUtils.formatDate(report.uploadedAt)}",
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color: Colors
                                                              .grey
                                                              .shade600,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                InkWell(
                                                  onTap: () {
                                                    setState(() {
                                                      _selectedReports.removeAt(
                                                        index,
                                                      );
                                                    });
                                                  },
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.all(4),
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
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(35),
                    color: Color(0xff3F67FD),
                  ),
                  width: double.infinity,
                  height: 65,
                  child: InkWell(
                    onTap: () {
                      final parsedAge = int.tryParse(ageController.text.trim());

                      if (parsedAge == null || parsedAge <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Please enter a valid age")),
                        );
                        return;
                      }

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DateTimeScreen(
                            doctorId: widget.doctor.id,
                            patientName: patientName,
                            age: parsedAge,
                            gender: selectgender,
                            symptoms: symptomsController.text,
                            selectedReports: _selectedReports,
                            aiSummaryId: widget.aiSummaryId,
                          ),
                        ),
                      );
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Next',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(width: 16),
                        Transform.rotate(
                          angle: -pi / 2,
                          child: SizedBox(
                            width: 26,
                            child: Image.asset(
                              'assets/images/next_arrow.png',
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
