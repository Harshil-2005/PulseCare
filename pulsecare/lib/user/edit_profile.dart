import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pulsecare/constrains/primary_icon_button.dart';
import 'package:pulsecare/constrains/schedule_date_picker_dialog.dart';
import 'package:pulsecare/providers/repository_providers.dart';
import 'package:pulsecare/repositories/session_repository.dart';
import 'package:pulsecare/utils/age_dob_input.dart';

class EditProfile extends ConsumerStatefulWidget {
  const EditProfile({
    super.key,
    this.initialStep = 0,
    this.singleStepMode = false,
  });

  final int initialStep;
  final bool singleStepMode;

  @override
  ConsumerState<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends ConsumerState<EditProfile> {
  bool _ready = false;
  late final PageController _pageController;
  late final TextEditingController firstNameController;
  late final TextEditingController lastNameController;
  late final TextEditingController phoneController;
  late final TextEditingController ageController;
  final FocusNode _lastNameFocusNode = FocusNode();
  int _currentStep = 0;
  DateTime? _lastDobFromInput;
  String _selectedGender = 'Female';

  static const List<String> _titles = [
    'Edit Profile',
    'Edit Phone',
    'Edit Age',
    'Edit Gender',
  ];

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    _pageController = PageController(
      initialPage: widget.singleStepMode ? 0 : widget.initialStep,
    );
    final user = await ref
        .read(userRepositoryProvider)
        .getUserById(SessionRepository().getCurrentUserId());
    final nameParts = user?.fullName.split(' ') ?? [''];
    final firstName = nameParts.isNotEmpty ? nameParts.first : '';
    final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
    firstNameController = TextEditingController(text: firstName);
    lastNameController = TextEditingController(text: lastName);
    phoneController = TextEditingController(text: user?.phone ?? '');
    ageController = TextEditingController(text: user?.age.toString() ?? '');
    _lastDobFromInput = user?.dateOfBirth;
    _selectedGender = user?.gender ?? 'Female';
    _currentStep = widget.initialStep;
    if (!mounted) return;
    setState(() {
      _ready = true;
    });
  }

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

  void _onAgeChanged(String value) {
    final dob = parseTypedDob(value.trim());
    if (dob == null) {
      if (int.tryParse(value.trim()) != null) {
        _lastDobFromInput = null;
      }
      return;
    }

    _lastDobFromInput = dob;
    final age = calculateAgeFromDob(dob).toString();
    ageController.value = TextEditingValue(
      text: age,
      selection: TextSelection.collapsed(offset: age.length),
      composing: TextRange.empty,
    );
  }

  Future<void> _saveCurrentStep() async {
    final userId = SessionRepository().getCurrentUserId();
    final user = await ref.read(userRepositoryProvider).getUserById(userId);
    if (!mounted) return;
    if (user == null) return;

    if (_currentStep == 0) {
      final fullName = '${firstNameController.text} ${lastNameController.text}'
          .trim();
      final updatedUser = user.copyWith(
        fullName: fullName,
        firstName: firstNameController.text.trim(),
        lastName: lastNameController.text.trim(),
      );
      await ref.read(userRepositoryProvider).updateUser(userId, updatedUser);
      return;
    }

    if (_currentStep == 1) {
      final phone = phoneController.text.trim();
      if (phone.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter your phone.')),
        );
        return;
      }
      final updatedUser = user.copyWith(phone: phone);
      await ref.read(userRepositoryProvider).updateUser(userId, updatedUser);
      return;
    }

    if (_currentStep == 2) {
      final rawAge = ageController.text.trim();
      final parsedAge = parseAgeInput(rawAge);
      if (parsedAge == null) {
        final message = rawAge.isEmpty
            ? 'Please enter your age.'
            : 'Please enter a valid age or DOB (dd/MM/yyyy).';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
        return;
      }
      final updatedUser = user.copyWith(age: parsedAge);
      final updatedUserWithDob = updatedUser.copyWith(
        dateOfBirth: _lastDobFromInput,
        clearDateOfBirth: _lastDobFromInput == null,
      );
      await ref
          .read(userRepositoryProvider)
          .updateUser(userId, updatedUserWithDob);
      return;
    }

    final updatedUser = user.copyWith(gender: _selectedGender);
    await ref.read(userRepositoryProvider).updateUser(userId, updatedUser);
  }

  Future<void> _onNext() async {
    if (_currentStep == 2) {
      final parsedAge = parseAgeInput(ageController.text.trim());
      if (parsedAge == null) {
        final raw = ageController.text.trim();
        final message = raw.isEmpty
            ? 'Please enter your age.'
            : 'Please enter a valid age or DOB (dd/MM/yyyy).';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
        return;
      }
    }

    await _saveCurrentStep();
    if (!mounted) return;

    FocusManager.instance.primaryFocus?.unfocus(
      disposition: UnfocusDisposition.scope,
    );
    SystemChannels.textInput.invokeMethod('TextInput.hide');

    if (widget.singleStepMode) {
      Navigator.pop(context);
      return;
    }

    if (_currentStep < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      return;
    }

    Navigator.pop(context);
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
    firstNameController.dispose();
    lastNameController.dispose();
    phoneController.dispose();
    ageController.dispose();
    _lastNameFocusNode.dispose();
    super.dispose();
  }

  Widget _profileStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: SizedBox(
            height: 150,
            width: 150,
            child: Stack(
              children: [
                const CircleAvatar(
                  radius: 70,
                  backgroundImage: AssetImage('assets/images/user.jpg'),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: InkWell(
                    onTap: () async {
                      final result = await FilePicker.platform.pickFiles(
                        type: FileType.custom,
                        allowedExtensions: ['pdf', 'jpg', 'png'],
                      );
                      if (!mounted) return;

                      if (result != null) {
                        final file = result.files.single;
                        debugPrint('Picked file: ${file.name}');
                        debugPrint('Path: ${file.path}');
                      }

                      Navigator.pop(context);
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
        const SizedBox(height: 34),
        const Text(
          'Name',
          style: TextStyle(
            fontWeight: FontWeight.w400,
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: firstNameController,
          textInputAction: TextInputAction.next,
          onSubmitted: (_) =>
              FocusScope.of(context).requestFocus(_lastNameFocusNode),
          onChanged: (value) =>
              _autoCapitalizeFirstLetter(firstNameController, value),
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
          controller: lastNameController,
          focusNode: _lastNameFocusNode,
          textInputAction: TextInputAction.done,
          onChanged: (value) =>
              _autoCapitalizeFirstLetter(lastNameController, value),
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

  Widget _ageStep() {
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
                        'Update Your Age',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 24,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: Text(
                        'Keeping your age updated helps us provide more accurate health insights.',
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
          controller: ageController,
          keyboardType: TextInputType.datetime,
          inputFormatters: [AgeOrDobInputFormatter()],
          onChanged: _onAgeChanged,
          onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
          decoration: InputDecoration(
            hintText: 'Enter age or DOB',
            suffixIcon: InkWell(
              onTap: () async {
                final now = DateTime.now();
                final initialDate = resolveAgePickerInitialDate(
                  ageController.text,
                  lastDobFromInput: _lastDobFromInput,
                  now: now,
                );

                final pickedDate = await showScheduleDatePicker(
                  context: context,
                  initialDate: initialDate,
                  firstDate: DateTime(1900),
                  lastDate: now,
                );
                if (!mounted) return;
                if (pickedDate == null) return;
                _lastDobFromInput = pickedDate;
                ageController.text = calculateAgeFromDob(pickedDate).toString();
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

  Widget _phoneStep() {
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
                        'Keeping your phone updated helps doctors reach you when necessary.',
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
          onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
          decoration: InputDecoration(
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

  Widget _genderTile(String gender) {
    final isSelected = _selectedGender == gender;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedGender = gender;
        });
      },
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

  Widget _genderStep() {
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

  Widget _buildStep(int index) {
    if (index == 0) return _profileStep();
    if (index == 1) return _phoneStep();
    if (index == 2) return _ageStep();
    return _genderStep();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final allPages = List.generate(4, _buildStep);
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
          shadowColor: Colors.black,
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
