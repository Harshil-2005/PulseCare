import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:pulsecare/constrains/primary_icon_button.dart';
import 'package:pulsecare/providers/repository_providers.dart';
import 'package:pulsecare/repositories/session_repository.dart';
import 'package:pulsecare/user/edit_gender.dart';

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

class EditAge extends ConsumerStatefulWidget {
  final bool fromEditProfile;

  const EditAge({super.key, this.fromEditProfile = false});

  @override
  ConsumerState<EditAge> createState() => _EditAgeState();
}

class _EditAgeState extends ConsumerState<EditAge> {
  late final TextEditingController ageController;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final user = await ref
        .read(userRepositoryProvider)
        .getUserById(SessionRepository().getCurrentUserId());
    ageController = TextEditingController(text: user?.age.toString() ?? '');
    if (!mounted) return;
    setState(() {
      _ready = true;
    });
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

  void _onAgeFieldChanged(String value) {
    final dob = _parseTypedDob(value.trim());
    if (dob == null) return;

    final age = _calculateAgeFromDob(dob).toString();
    ageController.value = TextEditingValue(
      text: age,
      selection: TextSelection.collapsed(offset: age.length),
      composing: TextRange.empty,
    );
  }

  @override
  void dispose() {
    ageController.dispose();
    super.dispose();
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
        title: const Center(
          child: Text(
            'Edit Age',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
        ),
        shadowColor: Colors.black,
        automaticallyImplyLeading: true,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: SvgPicture.asset(
            'assets/icons/backarrow.svg',
            width: 24,
            height: 20,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 30, left: 16, right: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 80),
            Center(
              child: Text(
                'Update Your Age',
                style: TextStyle(fontWeight: .w700, fontSize: 24),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(
                'Keeping your age updated helps us provide more accurate health insights.',
                style: TextStyle(
                  fontWeight: .w400,
                  fontSize: 18,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 50),
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
              onChanged: _onAgeFieldChanged,
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
            const Spacer(),
            Padding(
              padding: const EdgeInsets.only(bottom: 50, top: 12),
              child: PrimaryIconButton(
                text: 'Save Changes',
                iconPath: 'assets/icons/save.svg',
                onTap: () async {
                  final user = await ref.read(userRepositoryProvider).getUserById(
                    SessionRepository().getCurrentUserId(),
                  );
                  if (!mounted) return;
                  final rawAge = ageController.text.trim();
                  final parsedAge = _parseAgeInput(rawAge);
                  if (parsedAge == null) {
                    final message = rawAge.isEmpty
                        ? 'Please enter your age.'
                        : 'Please enter a valid age or DOB (dd/MM/yyyy).';
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(message)),
                    );
                    return;
                  }
                  ageController.text = parsedAge.toString();
                  if (user != null) {
                    final updatedUser = user.copyWith(
                      age: int.tryParse(ageController.text) ?? user.age,
                    );
                    await ref.read(userRepositoryProvider).updateUser(
                      SessionRepository().getCurrentUserId(),
                      updatedUser,
                    );
                    if (!mounted) return;
                  }

                  if (widget.fromEditProfile) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const EditGender(fromEditProfile: true),
                      ),
                    );
                  } else {
                    Navigator.pop(context);
                  }
                },
                height: 60,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
