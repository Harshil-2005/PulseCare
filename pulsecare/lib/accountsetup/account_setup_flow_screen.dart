import 'package:flutter/material.dart';
import 'package:pulsecare/utils/keyboard_utils.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pulsecare/constrains/schedule_date_picker_dialog.dart';
import 'package:pulsecare/constrains/next_action_button.dart';
import 'package:pulsecare/doctor/doctor_onboarding_screen.dart';
import 'package:pulsecare/model/user_model.dart';
import 'package:pulsecare/providers/repository_providers.dart';
import 'package:pulsecare/repositories/session_repository.dart';
import 'package:pulsecare/user/app_shell.dart';

typedef DoctorAccountSetupFlowScreen = DoctorOnboardingScreen;

class AgeOrDobInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length > 8) digits = digits.substring(0, 8);

    if (digits.length <= 2 && !newValue.text.contains('/')) {
      return TextEditingValue(
        text: digits,
        selection: TextSelection.collapsed(offset: digits.length),
      );
    }

    final parts = <String>[];
    if (digits.isNotEmpty) {
      parts.add(digits.substring(0, digits.length.clamp(0, 2)));
    }
    if (digits.length > 2) {
      parts.add(digits.substring(2, digits.length.clamp(2, 4)));
    }
    if (digits.length > 4) {
      parts.add(digits.substring(4, digits.length.clamp(4, 8)));
    }

    final formatted = parts.join('/');
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class AccountSetupFlowScreen extends ConsumerStatefulWidget {
  const AccountSetupFlowScreen({super.key});

  @override
  ConsumerState<AccountSetupFlowScreen> createState() =>
      _AccountSetupFlowScreenState();
}

class _AccountSetupFlowScreenState
    extends ConsumerState<AccountSetupFlowScreen> {
  bool _isFinishing = false;
  final PageController _pageController = PageController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  int _currentPage = 0;
  DateTime? _selectedDob;
  String _selectedGender = 'Female';
  String _selectedRole = 'Patient';
  String? _stepErrorMessage;

  static const List<String> _titles = [
    "What's your full name?",
    'What is your phone?',
    'How old are you?',
    'What is your gender?',
    'Select your profession',
  ];

  static const List<String> _subtitles = [
    "Let's start with your name to make your experience more personal.",
    'Keeping your phone updated helps doctors reach you when necessary.',
    'This helps us personalize your health plan.',
    'This helps us personalize your healthcare experience.',
    'Choose how you want to use PulseCare.',
  ];

  Future<void> _onNext() async {
    KeyboardUtils.hideKeyboardKeepFocus();
    _clearStepError();

    if (_currentPage == 2) {
      final rawAge = _ageController.text.trim();
      final parsedAge = _parseAgeInput(rawAge);
      _selectedDob = _parseTypedDob(rawAge);
      if (parsedAge == null) {
        final message = rawAge.isEmpty
            ? 'Please enter your age.'
            : 'Please enter a valid age or DOB (dd/MM/yyyy).';
        _setStepError(message);
        return;
      }
      _ageController.text = parsedAge.toString();
    }

    if (_currentPage == 1) {
      if (_phoneController.text.trim().isEmpty) {
        _setStepError('Please enter your phone.');
        return;
      }
    }

    if (_currentPage < 4) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      return;
    }

    setState(() => _isFinishing = true);
    try {
      final userRepository = ref.read(userRepositoryProvider);
      final authRepository = ref.read(authRepositoryProvider);
      final fullName = _nameController.text.trim();
      final parts = fullName
          .split(RegExp(r'\s+'))
          .where((p) => p.isNotEmpty)
          .toList();
      final firstName = parts.isNotEmpty ? parts.first : '';
      final lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';
      final sessionRepository = SessionRepository();
      String uid;
      try {
        uid = sessionRepository.getCurrentUserId();
      } catch (_) {
        throw Exception('No authenticated Firebase user found.');
      }
      if (uid.isEmpty) {
        throw Exception('No authenticated Firebase user found.');
      }
      final user = User(
        id: uid,
        fullName: fullName,
        firstName: firstName,
        lastName: lastName,
        email: authRepository.getCurrentUserEmail() ?? '',
        phone: _phoneController.text.trim(),
        dateOfBirth: _selectedDob,
        age: int.parse(_ageController.text),
        gender: _selectedGender,
        role: _selectedRole == 'Doctor' ? 'doctor' : 'patient',
      );
      final createdUser = await userRepository.createUser(user);
      if (!mounted) return;
      await sessionRepository.setCurrentUser(createdUser.id);
      if (!mounted) return;
      await sessionRepository.setRole(user.role);
      if (!mounted) return;

      if (_selectedRole == 'Doctor') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const DoctorAccountSetupFlowScreen(),
          ),
        );
        return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AppShell()),
      );
    } finally {
      if (mounted) setState(() => _isFinishing = false);
    }
  }

  void _onBack() {
    if (_currentPage == 0) {
      Navigator.pop(context);
      return;
    }
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _setStepError(String message) {
    if (!mounted) return;
    setState(() {
      _stepErrorMessage = message;
    });
  }

  void _clearStepError() {
    if (!mounted || _stepErrorMessage == null) return;
    setState(() {
      _stepErrorMessage = null;
    });
  }

  void _autoCapitalizeFirstName(String value) {
    if (value.isEmpty) return;
    final updated = '${value[0].toUpperCase()}${value.substring(1)}';
    if (updated == value) return;

    _nameController.value = _nameController.value.copyWith(
      text: updated,
      selection: TextSelection.collapsed(offset: updated.length),
      composing: TextRange.empty,
    );
  }

  DateTime? _parseTypedDob(String text) {
    final match = RegExp(r'^(\d{2})\/(\d{2})\/(\d{4})$').firstMatch(text);
    if (match == null) return null;

    final day = int.tryParse(match.group(1)!);
    final month = int.tryParse(match.group(2)!);
    final year = int.tryParse(match.group(3)!);
    if (day == null || month == null || year == null) return null;

    final candidate = DateTime(year, month, day);
    final isValidDate =
        candidate.year == year &&
        candidate.month == month &&
        candidate.day == day;
    if (!isValidDate) return null;

    final now = DateTime.now();
    if (candidate.isAfter(now) || year < 1900) return null;
    return candidate;
  }

  int _calculateAgeFromDob(DateTime dob) {
    final now = DateTime.now();
    var age = now.year - dob.year;
    final hadBirthday =
        now.month > dob.month || (now.month == dob.month && now.day >= dob.day);
    if (!hadBirthday) age -= 1;
    return age;
  }

  int? _parseAgeInput(String text) {
    final value = text.trim();
    if (value.isEmpty) return null;

    final numericAge = int.tryParse(value);
    if (numericAge != null) {
      if (numericAge < 1 || numericAge > 120) return null;
      return numericAge;
    }

    final dob = _parseTypedDob(value);
    if (dob == null) return null;
    return _calculateAgeFromDob(dob);
  }

  Widget _textFieldStep({
    required String label,
    required String hintText,
    required TextEditingController controller,
    TextInputType? keyboardType,
    String? suffixIconPath,
    VoidCallback? onSuffixTap,
    VoidCallback? onTap,
    bool readOnly = false,
    List<TextInputFormatter>? inputFormatters,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          readOnly: readOnly,
          onTap: onTap,
          inputFormatters: inputFormatters,
          onChanged: onChanged,
          onTapOutside: (_) => KeyboardUtils.hideKeyboardKeepFocus(),
          decoration: InputDecoration(
            suffixIcon: suffixIconPath == null
                ? null
                : InkWell(
                    onTap: onSuffixTap,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: SizedBox(
                        height: 20,
                        width: 20,
                        child: SvgPicture.asset(
                          suffixIconPath,
                          fit: BoxFit.contain,
                          colorFilter: ColorFilter.mode(
                            Colors.grey.shade400,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                    ),
                  ),
            hintText: hintText,
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

  Widget _stepContent(int index) {
    switch (index) {
      case 0:
        return _textFieldStep(
          label: 'Full Name',
          hintText: 'Enter your full name',
          controller: _nameController,
          keyboardType: TextInputType.name,
          onChanged: _autoCapitalizeFirstName,
        );
      case 1:
        return _textFieldStep(
          label: 'Phone',
          hintText: 'Enter your phone',
          controller: _phoneController,
          keyboardType: TextInputType.phone,
        );
      case 2:
        Future<void> openAgeCalendar() async {
          final now = DateTime.now();
          final typedAge = int.tryParse(_ageController.text.trim());
          final typedDob = _parseTypedDob(_ageController.text.trim());
          final initialDate =
              typedDob ??
              ((typedAge != null && typedAge >= 1 && typedAge <= 120)
                  ? DateTime(now.year - typedAge, now.month, now.day)
                  : DateTime(now.year - 20, now.month, now.day));
          final pickedDate = await showScheduleDatePicker(
            context: context,
            initialDate: initialDate,
            firstDate: DateTime(1900),
            lastDate: now,
          );
          if (!mounted) return;

          if (pickedDate == null) return;
          _selectedDob = pickedDate;
          _ageController.text = _calculateAgeFromDob(pickedDate).toString();
        }

        return _textFieldStep(
          label: 'Age',
          hintText: 'Enter age or DOB',
          controller: _ageController,
          keyboardType: TextInputType.datetime,
          readOnly: true,
          onTap: openAgeCalendar,
          suffixIconPath: 'assets/icons/calender.svg',
          onSuffixTap: openAgeCalendar,
        );
      case 3:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Gender',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 10),
            _choiceTile(
              title: 'Female',
              isSelected: _selectedGender == 'Female',
              onTap: () => setState(() => _selectedGender = 'Female'),
            ),
            const SizedBox(height: 15),
            _choiceTile(
              title: 'Male',
              isSelected: _selectedGender == 'Male',
              onTap: () => setState(() => _selectedGender = 'Male'),
            ),
          ],
        );
      default:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Role',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 10),
            _choiceTile(
              title: 'Patient',
              isSelected: _selectedRole == 'Patient',
              onTap: () => setState(() => _selectedRole = 'Patient'),
            ),
            const SizedBox(height: 15),
            _choiceTile(
              title: 'Doctor',
              isSelected: _selectedRole == 'Doctor',
              onTap: () => setState(() => _selectedRole = 'Doctor'),
            ),
          ],
        );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _ageController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_currentPage + 1) / 5;

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => KeyboardUtils.hideKeyboardKeepFocus(),
        child: Stack(
          children: [
            Align(
              alignment: Alignment.bottomRight,
              child: Image.asset('assets/images/lines_bg.png', width: 200),
            ),
            Positioned.fill(
              child: SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.of(context).viewInsets.bottom,
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                          maxHeight: constraints.maxHeight,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                          child: Column(
                            children: [
                              SizedBox(
                                height: 44,
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: _currentPage == 0
                                      ? const SizedBox.shrink()
                                      : IconButton(
                                          onPressed: _onBack,
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          icon: SvgPicture.asset(
                                            'assets/icons/backarrow.svg',
                                            width: 24,
                                            height: 24,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              LinearProgressIndicator(
                                value: progress,
                                color: const Color(0xFF3F67FD),
                                minHeight: 8,
                                borderRadius: BorderRadius.circular(30),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                _titles[_currentPage],
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontFamily: 'Kodchasan',
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                _subtitles[_currentPage],
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.grey.shade400,
                                ),
                              ),
                              const SizedBox(height: 40),
                              SizedBox(
                                height: 220,
                                child: PageView.builder(
                                  controller: _pageController,
                                  itemCount: 5,
                                  physics: const NeverScrollableScrollPhysics(),
                                  onPageChanged: (index) {
                                    setState(() {
                                      _currentPage = index;
                                      _stepErrorMessage = null;
                                    });
                                  },
                                  itemBuilder: (context, index) =>
                                      _stepContent(index),
                                ),
                              ),
                              if (_stepErrorMessage != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  _stepErrorMessage!,
                                  style: const TextStyle(
                                    color: Color(0xFFD32F2F),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                              const Spacer(),
                              NextActionButton(
                                text: _currentPage == 4 ? 'Finish' : 'Next',
                                isLoading: _currentPage == 4 && _isFinishing,
                                loadingText: 'Finishing...',
                                onTap: _onNext,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
