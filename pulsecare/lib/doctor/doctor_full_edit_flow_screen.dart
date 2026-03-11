import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pulsecare/constrains/primary_icon_button.dart';
import 'package:pulsecare/constrains/schedule_date_picker_dialog.dart';
import 'package:pulsecare/model/doctor_model.dart';
import 'package:pulsecare/repositories/doctor_repository.dart';
import 'package:pulsecare/repositories/session_repository.dart';
import 'package:pulsecare/repositories/user_repository.dart';
import 'package:pulsecare/model/user_model.dart';
import 'package:pulsecare/utils/age_dob_input.dart';
import '../providers/repository_providers.dart';

class DoctorFullEditFlowScreen extends ConsumerStatefulWidget {
  final int initialStep;
  final bool singleStepMode;

  const DoctorFullEditFlowScreen({
    super.key,
    this.initialStep = 0,
    this.singleStepMode = false,
  });

  @override
  ConsumerState<DoctorFullEditFlowScreen> createState() =>
      _DoctorFullEditFlowScreenState();
}

class _DoctorFullEditFlowScreenState
    extends ConsumerState<DoctorFullEditFlowScreen> {
  bool _ready = false;
  late final PageController _pageController;
  late Doctor _doctor;
  late final DoctorRepository _repository;
  late final UserRepository _userRepository;
  late User _user;
  late final TextEditingController _firstNameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _ageController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _experienceController;
  late final TextEditingController _specializationController;
  late final TextEditingController _hospitalController;
  late final TextEditingController _feeController;
  DateTime? _lastDobFromInput;
  String _selectedGender = 'Male';
  late int _selectedDuration;
  int _currentStep = 0;

  final List<String> _titles = [
    'Edit Profile',
    'Edit Phone',
    'Edit Age',
    'Edit Gender',
    'Edit Experience',
    'Edit Specialization',
    'Edit Hospital',
    'Edit Consultation Fee',
    'Edit Slot Duration',
  ];

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    _repository = ref.read(doctorRepositoryProvider);
    _userRepository = ref.read(userRepositoryProvider);
    final doctorId = SessionRepository().getCurrentDoctorId();
    final doctor = await _repository.getDoctorById(doctorId);
    if (doctor == null) {
      throw StateError('Doctor not found for active doctor session');
    }
    _doctor = doctor;
    final user = await _userRepository.getUserById(_doctor.userId);
    if (user == null) {
      throw StateError('User not found for active doctor session');
    }
    _user = user;
    final nameParts = _doctor.name.trim().split(RegExp(r'\s+'));
    final firstName = nameParts.isNotEmpty ? nameParts.first : '';
    final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
    _firstNameController = TextEditingController(text: firstName);
    _phoneController = TextEditingController(text: _user.phone);
    _ageController = TextEditingController(text: _user.age.toString());
    _lastDobFromInput = _user.dateOfBirth;
    _lastNameController = TextEditingController(text: lastName);
    _experienceController = TextEditingController(
      text: _doctor.experience.toString(),
    );
    _specializationController = TextEditingController(text: _doctor.speciality);
    _hospitalController = TextEditingController(text: _doctor.address);
    _feeController = TextEditingController(
      text: _doctor.consultationFee.toString(),
    );
    _selectedDuration = _doctor.slotDuration;
    _selectedGender = _user.gender;
    _pageController = PageController(
      initialPage: widget.singleStepMode ? 0 : widget.initialStep,
    );
    _currentStep = widget.initialStep;
    if (!mounted) return;
    setState(() {
      _ready = true;
    });
  }

  Future<void> _onNext() async {
    if (_currentStep == 2) {
      final parsedAge = parseAgeInput(_ageController.text.trim());
      if (parsedAge == null) {
        final raw = _ageController.text.trim();
        final message = raw.isEmpty
            ? 'Please enter your age.'
            : 'Please enter a valid age or DOB (dd/MM/yyyy).';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
        return;
      }
    }

    await _saveDoctorUpdates();
    if (!mounted) return;

    if (widget.singleStepMode) {
      Navigator.pop(context);
      return;
    }

    // Full profile edit starts at step 0. Stop after Gender (step 3)
    // so profile edits don't continue into professional fields.
    if (widget.initialStep == 0 && _currentStep == 3) {
      Navigator.pop(context);
      return;
    }

    if (_currentStep < 8) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _saveDoctorUpdates() async {
    final fullName =
        '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}'
            .trim();
    final updatedDoctor = _doctor.copyWith(
      name: fullName,
      experience:
          int.tryParse(_experienceController.text) ?? _doctor.experience,
      speciality: _specializationController.text,
      address: _hospitalController.text,
      consultationFee:
          double.tryParse(_feeController.text) ?? _doctor.consultationFee,
      slotDuration: _selectedDuration,
    );
    final updatedUser = _user.copyWith(
      fullName: fullName,
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      phone: _phoneController.text.trim(),
      age: parseAgeInput(_ageController.text.trim()) ?? _user.age,
      dateOfBirth: _lastDobFromInput,
      clearDateOfBirth: _lastDobFromInput == null,
      gender: _selectedGender,
    );
    await _repository.updateDoctor(updatedDoctor);
    await _userRepository.updateUser(_user.id, updatedUser);
    if (!mounted) return;
    _doctor = updatedDoctor;
    _user = updatedUser;
    setState(() {});
  }

  void _onBack() {
    if (widget.singleStepMode) {
      Navigator.pop(context);
      return;
    }

    if (_currentStep == 0) {
      Navigator.pop(context);
      return;
    }

    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _firstNameController.dispose();
    _phoneController.dispose();
    _ageController.dispose();
    _lastNameController.dispose();
    _experienceController.dispose();
    _specializationController.dispose();
    _hospitalController.dispose();
    _feeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final allPages = [
      EditDoctorProfileContent(
        firstNameController: _firstNameController,
        lastNameController: _lastNameController,
        imagePath: _doctor.image,
      ),
      EditPhoneContent(phoneController: _phoneController),
      EditAgeContent(
        ageController: _ageController,
        onDobChanged: (value) {
          _lastDobFromInput = value;
        },
        lastDobFromInput: _lastDobFromInput,
      ),
      EditGenderContent(
        selectedGender: _selectedGender,
        onGenderChanged: (value) {
          setState(() {
            _selectedGender = value;
          });
        },
      ),
      EditExperienceContent(experienceController: _experienceController),
      EditSpecializationContent(
        specializationController: _specializationController,
      ),
      EditHospitalContent(hospitalController: _hospitalController),
      EditConsultationFeeContent(feeController: _feeController),
      EditSlotDurationContent(
        selectedDuration: _selectedDuration,
        onDurationChanged: (duration) {
          setState(() {
            _selectedDuration = duration;
          });
        },
      ),
    ];

    final visiblePages = widget.singleStepMode
        ? [allPages[widget.initialStep]]
        : allPages;

    return WillPopScope(
      onWillPop: () async {
        _onBack();
        return false;
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          leadingWidth: 40,
          titleSpacing: 0,
          toolbarHeight: 85,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
          ),
          elevation: 0.3,
          centerTitle: true,
          title: Text(
            widget.singleStepMode
                ? _titles[widget.initialStep]
                : _titles[_currentStep],
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          leading: IconButton(
            onPressed: _onBack,
            icon: SvgPicture.asset(
              'assets/icons/backarrow.svg',
              width: 24,
              height: 20,
            ),
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) {
                  if (!widget.singleStepMode) {
                    setState(() {
                      _currentStep = index;
                    });
                  }
                },
                children: visiblePages.map((page) {
                  return SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: EdgeInsets.only(
                      top: 30,
                      left: 16,
                      right: 16,
                      bottom: MediaQuery.of(context).viewInsets.bottom + 40,
                    ),
                    child: page,
                  );
                }).toList(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: 50,
                top: 12,
              ),
              child: PrimaryIconButton(
                text: 'Save Changes',
                iconPath: 'assets/icons/save.svg',
                onTap: () => _onNext(),
                height: 60,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EditDoctorProfileContent extends StatefulWidget {
  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final String imagePath;

  const EditDoctorProfileContent({
    super.key,
    required this.firstNameController,
    required this.lastNameController,
    required this.imagePath,
  });

  @override
  State<EditDoctorProfileContent> createState() =>
      _EditDoctorProfileContentState();
}

class _EditDoctorProfileContentState extends State<EditDoctorProfileContent> {
  final FocusNode _lastNameFocusNode = FocusNode();

  void _autoCapitalizeFirstLetter(
    TextEditingController controller,
    String value,
  ) {
    if (value.isEmpty) return;
    final updated = '${value[0].toUpperCase()}${value.substring(1)}';
    if (updated == value) return;

    controller.value = controller.value.copyWith(
      text: updated,
      selection: TextSelection.collapsed(offset: updated.length),
      composing: TextRange.empty,
    );
  }

  @override
  void dispose() {
    _lastNameFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: SizedBox(
            height: 150,
            width: 150,
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 70,
                  backgroundImage: AssetImage(widget.imagePath),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: InkWell(
                    onTap: () async {
                      await FilePicker.platform.pickFiles(
                        type: FileType.custom,
                        allowedExtensions: ['jpg', 'jpeg', 'png'],
                      );
                    },
                    child: Container(
                      height: 45,
                      width: 45,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xff3F67FD),
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Center(
                        child: SvgPicture.asset(
                          'assets/icons/camera.svg',
                          colorFilter: const ColorFilter.mode(
                            Colors.white,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 30),
        const Text(
          'First Name',
          style: TextStyle(
            fontWeight: FontWeight.w400,
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: widget.firstNameController,
          textInputAction: TextInputAction.next,
          onSubmitted: (_) =>
              FocusScope.of(context).requestFocus(_lastNameFocusNode),
          onChanged: (value) =>
              _autoCapitalizeFirstLetter(widget.firstNameController, value),
          onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide(color: Colors.grey.shade400),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide(color: Colors.grey.shade400),
            ),
          ),
        ),
        const SizedBox(height: 34),
        const Text(
          'Last Name',
          style: TextStyle(
            fontWeight: FontWeight.w400,
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: widget.lastNameController,
          focusNode: _lastNameFocusNode,
          textInputAction: TextInputAction.done,
          onChanged: (value) =>
              _autoCapitalizeFirstLetter(widget.lastNameController, value),
          onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide(color: Colors.grey.shade400),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide(color: Colors.grey.shade400),
            ),
          ),
        ),
      ],
    );
  }
}

class EditPhoneContent extends StatelessWidget {
  final TextEditingController phoneController;

  const EditPhoneContent({super.key, required this.phoneController});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 150,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.topCenter,
                child: Column(
                  children: [
                    Center(
                      child: Text(
                        'Update your phone',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 24,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: Text(
                        'Keeping your phone updated helps patients reach you when necessary.',
                        style: TextStyle(
                          fontWeight: FontWeight.w400,
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 30),
        const Text(
          'Phone',
          style: TextStyle(
            fontWeight: FontWeight.w400,
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: phoneController,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.done,
          onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
          decoration: InputDecoration(
            hintText: 'Enter phone',
            hintStyle: TextStyle(color: Colors.grey.shade400),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide(color: Colors.grey.shade400),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide(color: Colors.grey.shade400),
            ),
          ),
        ),
      ],
    );
  }
}

class EditAgeContent extends StatefulWidget {
  final TextEditingController ageController;
  final ValueChanged<DateTime?> onDobChanged;
  final DateTime? lastDobFromInput;

  const EditAgeContent({
    super.key,
    required this.ageController,
    required this.onDobChanged,
    required this.lastDobFromInput,
  });

  @override
  State<EditAgeContent> createState() => _EditAgeContentState();
}

class _EditAgeContentState extends State<EditAgeContent> {
  void _onAgeChanged(String value) {
    final dob = parseTypedDob(value.trim());
    if (dob == null) {
      if (int.tryParse(value.trim()) != null) {
        widget.onDobChanged(null);
      }
      return;
    }

    widget.onDobChanged(dob);
    final age = calculateAgeFromDob(dob).toString();
    widget.ageController.value = TextEditingValue(
      text: age,
      selection: TextSelection.collapsed(offset: age.length),
      composing: TextRange.empty,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 150,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.topCenter,
                child: Column(
                  children: [
                    Center(
                      child: Text(
                        'Update Age',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 24,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: Text(
                        'This helps personalize your health experience.',
                        style: TextStyle(
                          fontWeight: FontWeight.w400,
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 30),
        const Text(
          'Age',
          style: TextStyle(
            fontWeight: FontWeight.w400,
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: widget.ageController,
          keyboardType: TextInputType.datetime,
          textInputAction: TextInputAction.done,
          inputFormatters: [AgeOrDobInputFormatter()],
          onChanged: _onAgeChanged,
          onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
          decoration: InputDecoration(
            hintText: 'Enter age or DOB',
            suffixIcon: InkWell(
              onTap: () async {
                final now = DateTime.now();
                final initialDate = resolveAgePickerInitialDate(
                  widget.ageController.text,
                  lastDobFromInput: widget.lastDobFromInput,
                  now: now,
                );

                final pickedDate = await showScheduleDatePicker(
                  context: context,
                  initialDate: initialDate,
                  firstDate: DateTime(1900),
                  lastDate: now,
                );
                if (!context.mounted) return;
                if (pickedDate == null) return;
                widget.onDobChanged(pickedDate);
                widget.ageController.text = calculateAgeFromDob(
                  pickedDate,
                ).toString();
              },
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: SizedBox(
                  height: 20,
                  width: 20,
                  child: SvgPicture.asset(
                    'assets/icons/calender.svg',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            hintStyle: TextStyle(color: Colors.grey.shade400),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide(color: Colors.grey.shade400),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide(color: Colors.grey.shade400),
            ),
          ),
        ),
      ],
    );
  }
}

class EditGenderContent extends StatelessWidget {
  final String selectedGender;
  final ValueChanged<String> onGenderChanged;

  const EditGenderContent({
    super.key,
    required this.selectedGender,
    required this.onGenderChanged,
  });

  Widget _genderTile(String gender) {
    final isSelected = selectedGender == gender;
    return InkWell(
      onTap: () => onGenderChanged(gender),
      child: Container(
        height: 60,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected ? const Color(0xFF3F67FD) : Colors.grey.shade300,
            width: 2,
          ),
          color: isSelected
              ? const Color(0xFF3F67FD).withValues(alpha: 0.08)
              : Colors.white,
        ),
        child: Row(
          children: [
            Text(
              gender,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const Spacer(),
            Container(
              height: 22,
              width: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF3F67FD)
                      : Colors.grey.shade400,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        height: 10,
                        width: 10,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF3F67FD),
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 150,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.topCenter,
                child: Column(
                  children: [
                    Center(
                      child: Text(
                        'Select Gender',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 24,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: Text(
                        'This Information helps personalize your health experience.',
                        style: TextStyle(
                          fontWeight: FontWeight.w400,
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 30),
        _genderTile('Female'),
        const SizedBox(height: 15),
        _genderTile('Male'),
      ],
    );
  }
}

class EditExperienceContent extends StatefulWidget {
  final TextEditingController experienceController;

  const EditExperienceContent({super.key, required this.experienceController});

  @override
  State<EditExperienceContent> createState() => _EditExperienceContentState();
}

class _EditExperienceContentState extends State<EditExperienceContent> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 150,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.topCenter,
                child: Column(
                  children: [
                    Center(
                      child: Text(
                        'Update Experience',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 24,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: Text(
                        'Tell patients your years of practice.',
                        style: TextStyle(
                          fontWeight: FontWeight.w400,
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 30),
        const Text(
          'Experience (Years)',
          style: TextStyle(
            fontWeight: FontWeight.w400,
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: widget.experienceController,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
          decoration: InputDecoration(
            hintText: 'Enter years',
            hintStyle: TextStyle(color: Colors.grey.shade400),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide(color: Colors.grey.shade400),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide(color: Colors.grey.shade400),
            ),
          ),
        ),
      ],
    );
  }
}

class EditSpecializationContent extends StatefulWidget {
  final TextEditingController specializationController;

  const EditSpecializationContent({
    super.key,
    required this.specializationController,
  });

  @override
  State<EditSpecializationContent> createState() =>
      _EditSpecializationContentState();
}

class _EditSpecializationContentState extends State<EditSpecializationContent> {
  final FocusNode _specializationFocusNode = FocusNode();

  final List<String> _specializations = const [
    'Cardiologist',
    'Dermatologist',
    'Dentist',
    'Neurologist',
    'Orthopedic',
    'Pediatrician',
    'General Physician',
    'Gynecologist',
    'Psychiatrist',
    'ENT Specialist',
  ];

  List<String> _filteredSpecializations = <String>[];

  @override
  void initState() {
    super.initState();
  }

  void _onSpecializationChanged(String value) {
    final query = value.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() => _filteredSpecializations = <String>[]);
      return;
    }
    setState(() {
      _filteredSpecializations = _specializations
          .where((item) => item.toLowerCase().startsWith(query))
          .take(5)
          .toList();
    });
  }

  void _selectSpecialization(String value) {
    widget.specializationController.text = value;
    widget.specializationController.selection = TextSelection.collapsed(
      offset: value.length,
    );
    setState(() => _filteredSpecializations = <String>[]);
    FocusScope.of(context).unfocus();
  }

  @override
  void dispose() {
    _specializationFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 150,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    'Update Specialization',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 24),
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: Text(
                    'This helps patients find you faster.',
                    style: TextStyle(
                      fontWeight: FontWeight.w400,
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          const Text(
            'Specialization',
            style: TextStyle(
              fontWeight: FontWeight.w400,
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: widget.specializationController,
            focusNode: _specializationFocusNode,
            textInputAction: TextInputAction.done,
            onChanged: _onSpecializationChanged,
            onTapOutside: (_) => FocusScope.of(context).unfocus(),
            decoration: InputDecoration(
              hintText: 'Enter specialization',
              hintStyle: TextStyle(color: Colors.grey.shade400),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide(color: Colors.grey.shade400),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide(color: Colors.grey.shade400),
              ),
            ),
          ),
          if (_filteredSpecializations.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxHeight: 150),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _filteredSpecializations.length,
                itemBuilder: (context, index) {
                  final item = _filteredSpecializations[index];
                  return InkWell(
                    onTap: () => _selectSpecialization(item),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                      child: Text(item),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class EditHospitalContent extends StatefulWidget {
  final TextEditingController hospitalController;

  const EditHospitalContent({super.key, required this.hospitalController});

  @override
  State<EditHospitalContent> createState() => _EditHospitalContentState();
}

class _EditHospitalContentState extends State<EditHospitalContent> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 150,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.topCenter,
                child: Column(
                  children: [
                    Center(
                      child: Text(
                        'Update Hospital',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 24,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: Text(
                        'Let patients know your practice location.',
                        style: TextStyle(
                          fontWeight: FontWeight.w400,
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 30),
        const Text(
          'Hospital / Clinic',
          style: TextStyle(
            fontWeight: FontWeight.w400,
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: widget.hospitalController,
          textInputAction: TextInputAction.done,
          onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
          decoration: InputDecoration(
            hintText: 'Enter hospital or clinic name',
            hintStyle: TextStyle(color: Colors.grey.shade400),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide(color: Colors.grey.shade400),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide(color: Colors.grey.shade400),
            ),
          ),
        ),
      ],
    );
  }
}

class EditConsultationFeeContent extends StatefulWidget {
  final TextEditingController feeController;

  const EditConsultationFeeContent({super.key, required this.feeController});

  @override
  State<EditConsultationFeeContent> createState() =>
      _EditConsultationFeeContentState();
}

class _EditConsultationFeeContentState
    extends State<EditConsultationFeeContent> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 150,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.topCenter,
                child: Column(
                  children: [
                    Center(
                      child: Text(
                        'Update Consultation Fee',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 24,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: Text(
                        'Set the amount patients pay per appointment.',
                        style: TextStyle(
                          fontWeight: FontWeight.w400,
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 30),
        const Text(
          'Consultation Fee',
          style: TextStyle(
            fontWeight: FontWeight.w400,
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: widget.feeController,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
          decoration: InputDecoration(
            prefixText: '\u20B9 ',
            hintText: 'Enter fee',
            hintStyle: TextStyle(color: Colors.grey.shade400),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide(color: Colors.grey.shade400),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide(color: Colors.grey.shade400),
            ),
          ),
        ),
      ],
    );
  }
}

class EditSlotDurationContent extends StatefulWidget {
  final int selectedDuration;
  final ValueChanged<int> onDurationChanged;

  const EditSlotDurationContent({
    super.key,
    required this.selectedDuration,
    required this.onDurationChanged,
  });

  @override
  State<EditSlotDurationContent> createState() =>
      _EditSlotDurationContentState();
}

class _EditSlotDurationContentState extends State<EditSlotDurationContent> {
  Widget _choiceTile({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 60,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected ? const Color(0xFF3F67FD) : Colors.grey.shade300,
            width: 2,
          ),
          color: isSelected
              ? const Color(0xFF3F67FD).withValues(alpha: 0.08)
              : Colors.white,
        ),
        child: Row(
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const Spacer(),
            Container(
              height: 22,
              width: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF3F67FD)
                      : Colors.grey.shade400,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        height: 10,
                        width: 10,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF3F67FD),
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 150,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.topCenter,
                child: Column(
                  children: [
                    Center(
                      child: Text(
                        'Select Slot Duration',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 24,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: Text(
                        'Choose how long each appointment lasts.',
                        style: TextStyle(
                          fontWeight: FontWeight.w400,
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 30),
        const Opacity(
          opacity: 0,
          child: Text(
            'Consultation Fee',
            style: TextStyle(
              fontWeight: FontWeight.w400,
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ),
        const SizedBox(height: 10),
        ...[15, 20, 30, 45, 60].map((minutes) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 15),
            child: _choiceTile(
              title: '$minutes minutes',
              isSelected: widget.selectedDuration == minutes,
              onTap: () => widget.onDurationChanged(minutes),
            ),
          );
        }),
      ],
    );
  }
}
