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
        symptomsController.text =
            'Symptoms: ${summary.symptoms.join(", ")}\n'
            'Duration: ${summary.duration ?? "N/A"}\n'
            'Medications: ${summary.medications ?? "N/A"}\n'
            'Severity: ${summary.severity ?? "N/A"}\n'
            'Temperature: ${summary.temperature ?? "N/A"}';
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
