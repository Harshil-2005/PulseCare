import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pulsecare/constrains/primary_icon_button.dart';
import 'package:pulsecare/providers/repository_providers.dart';
import 'package:pulsecare/repositories/session_repository.dart';

class EditProfile extends ConsumerStatefulWidget {
  const EditProfile({super.key});

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
    _pageController = PageController();
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
    _selectedGender = user?.gender ?? 'Female';
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

  DateTime? _parseTypedDob(String text) {
    final match = RegExp(r'^(\d{2})\/(\d{2})\/(\d{4})$').firstMatch(text);
    if (match == null) return null;

    final day = int.tryParse(match.group(1)!);
    final month = int.tryParse(match.group(2)!);
    final year = int.tryParse(match.group(3)!);
    if (day == null || month == null || year == null) return null;

    final candidate = DateTime(year, month, day);
    final isValidDate =
        candidate.year == year && candidate.month == month && candidate.day == day;
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

  Future<void> _saveCurrentStep() async {
    final userId = SessionRepository().getCurrentUserId();
    final user = await ref.read(userRepositoryProvider).getUserById(userId);
    if (!mounted) return;
    if (user == null) return;

    if (_currentStep == 0) {
      final fullName = '${firstNameController.text} ${lastNameController.text}'.trim();
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
      final parsedAge = _parseAgeInput(rawAge);
      if (parsedAge == null) {
        final message = rawAge.isEmpty
            ? 'Please enter your age.'
            : 'Please enter a valid age or DOB (dd/MM/yyyy).';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
        return;
      }
      ageController.text = parsedAge.toString();
      final updatedUser = user.copyWith(age: parsedAge);
      await ref.read(userRepositoryProvider).updateUser(userId, updatedUser);
      return;
    }

    final updatedUser = user.copyWith(gender: _selectedGender);
    await ref.read(userRepositoryProvider).updateUser(userId, updatedUser);
  }

  Future<void> _onNext() async {
    if (_currentStep == 2) {
      final parsedAge = _parseAgeInput(ageController.text.trim());
      if (parsedAge == null) {
        final raw = ageController.text.trim();
        final message = raw.isEmpty
            ? 'Please enter your age.'
            : 'Please enter a valid age or DOB (dd/MM/yyyy).';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
        return;
      }
    }

    await _saveCurrentStep();
    if (!mounted) return;

    FocusManager.instance.primaryFocus?.unfocus(
      disposition: UnfocusDisposition.scope,
    );
    SystemChannels.textInput.invokeMethod('TextInput.hide');

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
          onSubmitted: (_) => FocusScope.of(context).requestFocus(_lastNameFocusNode),
          onChanged: (value) => _autoCapitalizeFirstLetter(firstNameController, value),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
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
          onChanged: (value) => _autoCapitalizeFirstLetter(lastNameController, value),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
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
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 24),
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
          onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
          decoration: InputDecoration(
            suffixIcon: InkWell(
              onTap: () async {
                final now = DateTime.now();
                final typedAge = int.tryParse(ageController.text.trim());
                final typedDob = _parseTypedDob(ageController.text.trim());
                final initialDate =
                    typedDob ??
                    ((typedAge != null && typedAge >= 1 && typedAge <= 120)
                        ? DateTime(now.year - typedAge, now.month, now.day)
                        : DateTime(now.year - 20, now.month, now.day));

                final pickedDate = await showDatePicker(
                  context: context,
                  initialDate: initialDate,
                  firstDate: DateTime(1900),
                  lastDate: now,
                );
                if (!mounted) return;
                if (pickedDate == null) return;
                ageController.text = _calculateAgeFromDob(pickedDate).toString();
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
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 24),
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
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 24),
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
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        leadingWidth: 40,
        titleSpacing: 0,
        toolbarHeight: 85,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
        elevation: 0.3,
        title: Center(
          child: Text(
            _titles[_currentStep],
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
        ),
        shadowColor: Colors.black,
        automaticallyImplyLeading: true,
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
                setState(() {
                  _currentStep = index;
                });
              },
              children: List.generate(
                4,
                (index) => SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.only(
                    top: 30,
                    left: 16,
                    right: 16,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 40,
                  ),
                  child: _buildStep(index),
                ),
              ),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.only(bottom: 50, top: 12, left: 16, right: 16),
            child: PrimaryIconButton(
              text: 'Save Changes',
              iconPath: 'assets/icons/save.svg',
          onTap: () => _onNext(),
              height: 60,
            ),
          ),
        ],
      ),
    );
  }
}
