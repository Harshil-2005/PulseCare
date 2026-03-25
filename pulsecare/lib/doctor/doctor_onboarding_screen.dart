import 'package:flutter/material.dart';
import 'package:pulsecare/utils/keyboard_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pulsecare/constrains/next_action_button.dart';
import 'package:pulsecare/data/medical/medical_specialties.dart';
import 'package:pulsecare/doctor/doctor_app_shell.dart';
import 'package:pulsecare/model/day_schedule.dart';
import 'package:pulsecare/model/doctor_model.dart';
import 'package:pulsecare/repositories/session_repository.dart';
import '../providers/repository_providers.dart';

typedef DoctorOnboardingScreen = DoctorAccountSetupFlowScreen;

class DoctorAccountSetupFlowScreen extends ConsumerStatefulWidget {
  const DoctorAccountSetupFlowScreen({super.key});

  @override
  ConsumerState<DoctorAccountSetupFlowScreen> createState() =>
      _DoctorAccountSetupFlowScreenState();
}

class _DoctorAccountSetupFlowScreenState
    extends ConsumerState<DoctorAccountSetupFlowScreen> {
  bool _isFinishing = false;
  final PageController _pageController = PageController();
  final TextEditingController _experienceController = TextEditingController();
  final TextEditingController _specializationController =
      TextEditingController();
  final TextEditingController _hospitalNameController = TextEditingController();
  final TextEditingController _aboutController = TextEditingController();
  final TextEditingController _consultationFeeController =
      TextEditingController();
  List<DaySchedule> weeklySchedule = [];
  String? _stepErrorMessage;
  final Map<String, Map<String, TextEditingController>>
  _availabilityControllers = {};
  final Map<String, Map<String, FocusNode>> _availabilityFocusNodes = {};

  int _currentPage = 0;
  int _slotDuration = 30;
  final List<String> _days = const [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];
  final Set<String> _selectedDays = <String>{};
  final List<String> _specializations = medicalSpecialties;
  List<String> _filteredSpecializations = [];

  static const List<String> _titles = [
    'How many years of experience?',
    'What is your specialization?',
    'Where do you practice?',
    'Tell patients about yourself',
    'Enter your consultation fee',
    'Select your working days',
    'Set your working hours',
    'Consultation Duration',
  ];

  static const List<String> _subtitles = [
    'Tell patients about your professional experience.',
    'This helps patients find you easily.',
    'Enter your hospital or clinic name.',
    'Share your background and approach in a few lines.',
    'Set the fee patients will see while booking.',
    'Choose the days you are available.',
    'Choose your available time range.',
    'Select how long each appointment lasts.',
  ];

  static const Map<String, String> _dayLabels = {
    'Mon': 'Monday',
    'Tue': 'Tuesday',
    'Wed': 'Wednesday',
    'Thu': 'Thursday',
    'Fri': 'Friday',
    'Sat': 'Saturday',
    'Sun': 'Sunday',
  };

  double _stableHeaderHeight(BuildContext context) {
    final maxTextWidth = MediaQuery.sizeOf(context).width - 32;
    final textScaler = MediaQuery.textScalerOf(context);
    final baseStyle = DefaultTextStyle.of(context).style;

    final titleStyle = baseStyle.merge(
      const TextStyle(
        fontFamily: 'Kodchasan',
        fontSize: 24,
        fontWeight: FontWeight.w700,
      ),
    );
    final subtitleStyle = baseStyle.merge(
      TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w400,
        color: Colors.grey.shade400,
      ),
    );

    double maxHeight = 0;
    for (var i = 0; i < _titles.length; i++) {
      final titlePainter = TextPainter(
        text: TextSpan(text: _titles[i], style: titleStyle),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
        textScaler: textScaler,
      )..layout(maxWidth: maxTextWidth);

      final subtitlePainter = TextPainter(
        text: TextSpan(text: _subtitles[i], style: subtitleStyle),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
        textScaler: textScaler,
      )..layout(maxWidth: maxTextWidth);

      final totalHeight = titlePainter.height + 10 + subtitlePainter.height;
      if (totalHeight > maxHeight) {
        maxHeight = totalHeight;
      }
    }

    // Buffer to avoid rounding/line-height edge cases on smaller devices.
    return maxHeight + 20;
  }

  Future<void> _onNext() async {
    KeyboardUtils.hideKeyboardKeepFocus();
    _clearStepError();

    if (_currentPage == 4) {
      final fee = double.tryParse(_consultationFeeController.text.trim());
      if (fee == null || fee <= 0) {
        _showError('Please enter a valid consultation fee');
        return;
      }
    }

    if (_currentPage < 7) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      return;
    }

    setState(() => _isFinishing = true);
    try {
      for (final day in _selectedDays) {
        _ensureDefaultsForDayIfNeeded(day);
      }

      final schedule = _normalizedWeeklySchedule(weeklySchedule);
      final userId = SessionRepository().getCurrentUserId();
      final userRepository = ref.read(userRepositoryProvider);
      final currentUser = await userRepository.getUserById(userId);
      if (!mounted) return;
      if (currentUser == null) {
        throw StateError('User not found for active onboarding session');
      }
      final doctorRepository = ref.read(doctorRepositoryProvider);
      final createdDoctor = await doctorRepository.createDoctor(
        Doctor(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          userId: userId,
          name: currentUser.fullName,
          speciality: _specializationController.text.trim(),
          address: _hospitalNameController.text.trim(),
          experience: int.tryParse(_experienceController.text.trim()) ?? 0,
          rating: 0,
          reviews: 0,
          patients: 0,
          image: 'assets/images/Dr1.png',
          email: currentUser.email,
          phone: currentUser.phone,
          about: _aboutController.text.trim(),
          consultationFee: double.parse(_consultationFeeController.text.trim()),
          slotDuration: _slotDuration,
          isAvailableForBooking: true,
          schedule: schedule,
        ),
      );
      if (!mounted) return;
      await SessionRepository().setCurrentDoctor(createdDoctor.id);
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => DoctorAppShell(
            doctorId: createdDoctor.id,
            initialSchedule: schedule,
          ),
        ),
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

  String _normalizeDayKey(String day) {
    switch (day.trim()) {
      case 'Monday':
        return 'Mon';
      case 'Tuesday':
        return 'Tue';
      case 'Wednesday':
        return 'Wed';
      case 'Thursday':
        return 'Thu';
      case 'Friday':
        return 'Fri';
      case 'Saturday':
        return 'Sat';
      case 'Sunday':
        return 'Sun';
      default:
        return day;
    }
  }

  List<DaySchedule> _normalizedWeeklySchedule(List<DaySchedule> input) {
    final byDay = <String, DaySchedule>{};
    for (final daySchedule in input) {
      final key = _normalizeDayKey(daySchedule.day);
      byDay[key] = DaySchedule(
        day: key,
        morningEnabled: daySchedule.morningEnabled,
        morningStart: daySchedule.morningStart,
        morningEnd: daySchedule.morningEnd,
        afternoonEnabled: daySchedule.afternoonEnabled,
        afternoonStart: daySchedule.afternoonStart,
        afternoonEnd: daySchedule.afternoonEnd,
      );
    }

    return _days.map((day) {
      final existing = byDay[day];
      if (existing != null) {
        return existing;
      }
      return DaySchedule(
        day: day,
        morningEnabled: false,
        morningStart: '',
        morningEnd: '',
        afternoonEnabled: false,
        afternoonStart: '',
        afternoonEnd: '',
      );
    }).toList();
  }

  Future<void> _pickTime(TextEditingController controller) async {
    KeyboardUtils.hideKeyboardKeepFocus();

    TimeOfDay initialTime = TimeOfDay.now();
    final currentText = controller.text.trim();
    final match = RegExp(
      r'^(\d{1,2}):(\d{2})\s(AM|PM)$',
    ).firstMatch(currentText);
    if (match != null) {
      final hour = int.tryParse(match.group(1)!);
      final minute = int.tryParse(match.group(2)!);
      final meridiem = match.group(3)!;
      if (hour != null && minute != null) {
        final baseHour = hour == 12 ? 0 : hour;
        final hour24 = meridiem == 'PM' ? baseHour + 12 : baseHour;
        initialTime = TimeOfDay(hour: hour24, minute: minute);
      }
    }

    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
    if (!mounted) return;
    if (picked == null) return;

    final hour = picked.hourOfPeriod == 0 ? 12 : picked.hourOfPeriod;
    final minute = picked.minute.toString().padLeft(2, '0');
    final period = picked.period == DayPeriod.am ? 'AM' : 'PM';

    controller.text = '$hour:$minute $period';
  }

  DaySchedule _defaultDaySchedule(String day) {
    final morningStart = _snapAndFormat(_parseTime('9:00 AM')!);
    final morningEnd = _snapAndFormat(_parseTime('12:00 PM')!);
    final afternoonStart = _snapAndFormat(_parseTime('2:00 PM')!);
    final afternoonEnd = _snapAndFormat(_parseTime('6:00 PM')!);

    return DaySchedule(
      day: day,
      morningEnabled: true,
      morningStart: morningStart,
      morningEnd: morningEnd,
      afternoonEnabled: true,
      afternoonStart: afternoonStart,
      afternoonEnd: afternoonEnd,
    );
  }

  void _ensureDefaultsForDayIfNeeded(String day) {
    _ensureAvailabilityDay(day);
    final daySlots = _scheduleForDay(day)!;
    var updated = daySlots;

    if (updated.morningEnabled) {
      final ms = updated.morningStart.trim();
      final me = updated.morningEnd.trim();
      if (ms.isEmpty || me.isEmpty) {
        updated = updated.copyWith(
          morningStart: _snapAndFormat(_parseTime('9:00 AM')!),
          morningEnd: _snapAndFormat(_parseTime('12:00 PM')!),
        );
      }
    }

    if (updated.afternoonEnabled) {
      final as = updated.afternoonStart.trim();
      final ae = updated.afternoonEnd.trim();
      if (as.isEmpty || ae.isEmpty) {
        updated = updated.copyWith(
          afternoonStart: _snapAndFormat(_parseTime('2:00 PM')!),
          afternoonEnd: _snapAndFormat(_parseTime('6:00 PM')!),
        );
      }
    }

    if (!_sameDaySchedule(daySlots, updated)) {
      _upsertDaySchedule(updated);
    }

    final controllers = _availabilityControllers[day];
    if (controllers != null) {
      controllers['morningStart']?.text = updated.morningStart;
      controllers['morningEnd']?.text = updated.morningEnd;
      controllers['afternoonStart']?.text = updated.afternoonStart;
      controllers['afternoonEnd']?.text = updated.afternoonEnd;
    }
  }

  void _ensureAvailabilityDay(String day) {
    if (_scheduleForDay(day) == null) {
      weeklySchedule.add(_defaultDaySchedule(day));
    }

    final daySchedule = _scheduleForDay(day)!;

    _availabilityControllers.putIfAbsent(day, () {
      return {
        'morningStart': TextEditingController(text: daySchedule.morningStart),
        'morningEnd': TextEditingController(text: daySchedule.morningEnd),
        'afternoonStart': TextEditingController(
          text: daySchedule.afternoonStart,
        ),
        'afternoonEnd': TextEditingController(text: daySchedule.afternoonEnd),
      };
    });
    _availabilityFocusNodes.putIfAbsent(day, () {
      return {
        'morningStart': FocusNode(),
        'morningEnd': FocusNode(),
        'afternoonStart': FocusNode(),
        'afternoonEnd': FocusNode(),
      };
    });
  }

  void _removeAvailabilityDay(String day) {
    final controllers = _availabilityControllers.remove(day);
    controllers?.forEach((_, controller) => controller.dispose());
    final focusNodes = _availabilityFocusNodes.remove(day);
    focusNodes?.forEach((_, node) => node.dispose());
    weeklySchedule.removeWhere((schedule) => schedule.day == day);
  }

  TextEditingController _controllerFor(String day, String slotKey) {
    _ensureAvailabilityDay(day);
    return _availabilityControllers[day]![slotKey]!;
  }

  FocusNode _focusNodeFor(String day, String slotKey) {
    _ensureAvailabilityDay(day);
    return _availabilityFocusNodes[day]![slotKey]!;
  }

  void _setAvailabilityValue(String day, String slotKey, String value) {
    _ensureAvailabilityDay(day);
    _updateDaySchedule(
      day,
      (current) => _copyWithSlotValue(current, slotKey, value),
    );
  }

  DaySchedule? _scheduleForDay(String day) {
    final index = weeklySchedule.indexWhere((schedule) => schedule.day == day);
    return index == -1 ? null : weeklySchedule[index];
  }

  void _upsertDaySchedule(DaySchedule schedule) {
    final index = weeklySchedule.indexWhere((item) => item.day == schedule.day);
    if (index == -1) {
      weeklySchedule.add(schedule);
      return;
    }
    weeklySchedule[index] = schedule;
  }

  void _updateDaySchedule(
    String day,
    DaySchedule Function(DaySchedule current) updater,
  ) {
    final existing = _scheduleForDay(day);
    final current = existing ?? _defaultDaySchedule(day);
    _upsertDaySchedule(updater(current));
  }

  DaySchedule _copyWithSlotValue(
    DaySchedule schedule,
    String slotKey,
    String value,
  ) {
    switch (slotKey) {
      case 'morningStart':
        return schedule.copyWith(morningStart: value);
      case 'morningEnd':
        return schedule.copyWith(morningEnd: value);
      case 'afternoonStart':
        return schedule.copyWith(afternoonStart: value);
      case 'afternoonEnd':
        return schedule.copyWith(afternoonEnd: value);
      default:
        return schedule;
    }
  }

  String _slotValue(DaySchedule schedule, String slotKey) {
    switch (slotKey) {
      case 'morningStart':
        return schedule.morningStart;
      case 'morningEnd':
        return schedule.morningEnd;
      case 'afternoonStart':
        return schedule.afternoonStart;
      case 'afternoonEnd':
        return schedule.afternoonEnd;
      default:
        return '';
    }
  }

  bool _sameDaySchedule(DaySchedule a, DaySchedule b) {
    return a.day == b.day &&
        a.morningEnabled == b.morningEnabled &&
        a.morningStart == b.morningStart &&
        a.morningEnd == b.morningEnd &&
        a.afternoonEnabled == b.afternoonEnabled &&
        a.afternoonStart == b.afternoonStart &&
        a.afternoonEnd == b.afternoonEnd;
  }

  TimeOfDay? _parseTime(String text) {
    final match = RegExp(
      r'^(0?[1-9]|1[0-2]):([0-5][0-9])\s?(AM|PM)$',
      caseSensitive: false,
    ).firstMatch(text.trim());
    if (match == null) return null;

    final hour12 = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    final period = match.group(3)!.toUpperCase();
    final baseHour = hour12 == 12 ? 0 : hour12;
    final hour24 = period == 'PM' ? baseHour + 12 : baseHour;
    return TimeOfDay(hour: hour24, minute: minute);
  }

  String? _normalizeTypedTime(String raw, String slotKey) {
    final value = raw.trim().toUpperCase();
    if (value.isEmpty) return '';

    // Already in hh:mm AM/PM format.
    if (_parseTime(value) != null) return value;

    final isMorning = slotKey.startsWith('morning');
    final defaultPeriod = isMorning ? 'AM' : 'PM';

    final hourOnly = RegExp(r'^(0?[1-9]|1[0-2])$').firstMatch(value);
    if (hourOnly != null) {
      final hour = int.parse(hourOnly.group(1)!);
      if (hour == 12) {
        // Treat plain "12" as noon to avoid 12:00 AM confusion.
        return '12:00 PM';
      }
      return '$hour:00 $defaultPeriod';
    }

    final hourMinute = RegExp(
      r'^(0?[1-9]|1[0-2]):([0-5]?[0-9])$',
    ).firstMatch(value);
    if (hourMinute != null) {
      final hour = int.parse(hourMinute.group(1)!);
      final minute = int.parse(hourMinute.group(2)!);
      final minuteStr = minute.toString().padLeft(2, '0');
      return '$hour:$minuteStr $defaultPeriod';
    }

    return null;
  }

  int _timeToMinutes(TimeOfDay value) => value.hour * 60 + value.minute;

  TimeOfDay _snapToSlot(TimeOfDay time) {
    final totalMinutes = _timeToMinutes(time);
    final snapped = (totalMinutes / _slotDuration).ceil() * _slotDuration;
    final capped = snapped.clamp(0, (23 * 60) + 59);
    return TimeOfDay(hour: capped ~/ 60, minute: capped % 60);
  }

  String _snapAndFormat(TimeOfDay time) => _formatTime(_snapToSlot(time));

  bool _inMorningRange(TimeOfDay value) {
    final m = _timeToMinutes(value);
    return m >= (5 * 60) && m <= (12 * 60);
  }

  bool _inAfternoonRange(TimeOfDay value) {
    final m = _timeToMinutes(value);
    return m >= (12 * 60) && m <= (21 * 60);
  }

  String _formatTime(TimeOfDay value) {
    final hour = value.hourOfPeriod == 0 ? 12 : value.hourOfPeriod;
    final minute = value.minute.toString().padLeft(2, '0');
    final period = value.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  void _showError(String message) {
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

  String? _validateDaySlots(DaySchedule daySlots) {
    final morningEnabled = daySlots.morningEnabled;
    final afternoonEnabled = daySlots.afternoonEnabled;

    final msText = daySlots.morningStart.trim();
    final meText = daySlots.morningEnd.trim();
    final asText = daySlots.afternoonStart.trim();
    final aeText = daySlots.afternoonEnd.trim();

    final ms = msText.isEmpty ? null : _parseTime(msText);
    final me = meText.isEmpty ? null : _parseTime(meText);
    final as = asText.isEmpty ? null : _parseTime(asText);
    final ae = aeText.isEmpty ? null : _parseTime(aeText);

    if (msText.isNotEmpty && ms == null) return 'Use hh:mm AM/PM format';
    if (meText.isNotEmpty && me == null) return 'Use hh:mm AM/PM format';
    if (asText.isNotEmpty && as == null) return 'Use hh:mm AM/PM format';
    if (aeText.isNotEmpty && ae == null) return 'Use hh:mm AM/PM format';

    if (morningEnabled) {
      if (ms != null && !_inMorningRange(ms)) {
        return 'Morning session must be between 5 AM and 12 PM.';
      }
      if (me != null && !_inMorningRange(me)) {
        return 'Morning session must be between 5 AM and 12 PM.';
      }
      if (ms != null &&
          me != null &&
          _timeToMinutes(me) <= _timeToMinutes(ms)) {
        return 'Morning end time must be after start time';
      }
      if (me != null && _timeToMinutes(me) > (12 * 60)) {
        return 'Morning session must be between 5 AM and 12 PM.';
      }
    }

    if (afternoonEnabled) {
      if (as != null && !_inAfternoonRange(as)) {
        return 'Afternoon session must be between 12 PM and 9 PM.';
      }
      if (ae != null && !_inAfternoonRange(ae)) {
        return 'Afternoon session must be between 12 PM and 9 PM.';
      }
      if (as != null &&
          ae != null &&
          _timeToMinutes(ae) <= _timeToMinutes(as)) {
        return 'Afternoon end time must be after start time';
      }
      if (as != null && _timeToMinutes(as) < (12 * 60)) {
        return 'Afternoon session must be between 12 PM and 9 PM.';
      }
    }

    if (morningEnabled && afternoonEnabled && me != null && as != null) {
      if (_timeToMinutes(me) >= _timeToMinutes(as)) {
        return 'Morning must end before Afternoon starts';
      }
    }

    return null;
  }

  void _setSessionEnabled(String day, String sessionKey, bool enabled) {
    _ensureAvailabilityDay(day);
    setState(() {
      _updateDaySchedule(
        day,
        (current) => sessionKey == 'morning'
            ? current.copyWith(morningEnabled: enabled)
            : current.copyWith(afternoonEnabled: enabled),
      );
    });
  }

  void _onManualTimeEditingComplete(String day, String slotKey) {
    _ensureAvailabilityDay(day);
    final controller = _controllerFor(day, slotKey);
    final raw = controller.text.trim();
    final normalized = _normalizeTypedTime(raw, slotKey);

    if (normalized == '') {
      _setAvailabilityValue(day, slotKey, '');
      return;
    }
    if (normalized == null) {
      _showError('Use hh:mm AM/PM format');
      controller.clear();
      _setAvailabilityValue(day, slotKey, '');
      return;
    }

    final parsed = _parseTime(normalized);
    if (parsed == null) {
      _showError('Use hh:mm AM/PM format');
      controller.clear();
      _setAvailabilityValue(day, slotKey, '');
      return;
    }

    final normalizedFormatted = _snapAndFormat(parsed);
    final previous = _slotValue(_scheduleForDay(day)!, slotKey);
    _setAvailabilityValue(day, slotKey, normalizedFormatted);
    final error = _validateDaySlots(_scheduleForDay(day)!);
    if (error != null) {
      _showError(error);
      controller.clear();
      _setAvailabilityValue(day, slotKey, '');
      return;
    }

    if (previous != normalizedFormatted) {
      controller.text = normalizedFormatted;
      controller.selection = TextSelection.collapsed(
        offset: normalizedFormatted.length,
      );
    }
  }

  Future<void> _pickAvailabilityTime(String day, String slotKey) async {
    _ensureAvailabilityDay(day);
    final controller = _controllerFor(day, slotKey);
    final previous = controller.text.trim();
    await _pickTime(controller);
    if (!mounted) return;
    final pickedValue = controller.text.trim();
    if (pickedValue.isEmpty || pickedValue == previous) return;

    final parsed = _parseTime(pickedValue);
    if (parsed == null) {
      _showError('Use hh:mm AM/PM format');
      controller.text = previous;
      _setAvailabilityValue(day, slotKey, previous);
      return;
    }

    final snappedFormatted = _snapAndFormat(parsed);
    controller.text = snappedFormatted;
    _setAvailabilityValue(day, slotKey, snappedFormatted);
    final error = _validateDaySlots(_scheduleForDay(day)!);
    if (error != null) {
      _showError(error);
      controller.text = previous;
      _setAvailabilityValue(day, slotKey, previous);
    }
  }

  Widget _availabilityField({
    required String day,
    required String slotKey,
    required String hint,
    String? nextSlotKey,
  }) {
    return _textFieldStep(
      label: '',
      hintText: hint,
      controller: _controllerFor(day, slotKey),
      focusNode: _focusNodeFor(day, slotKey),
      textInputAction: nextSlotKey == null
          ? TextInputAction.done
          : TextInputAction.next,
      keyboardType: TextInputType.datetime,
      suffixIconPath: 'assets/icons/calender.svg',
      onSuffixTap: () => _pickAvailabilityTime(day, slotKey),
      readOnly: false,
      onChanged: (value) => _setAvailabilityValue(day, slotKey, value.trim()),
      onEditingComplete: () => _onManualTimeEditingComplete(day, slotKey),
      onSubmitted: (_) {
        _onManualTimeEditingComplete(day, slotKey);
        if (nextSlotKey == null) {
          KeyboardUtils.hideKeyboardKeepFocus();
          return;
        }
        FocusScope.of(context).requestFocus(_focusNodeFor(day, nextSlotKey));
      },
      showLabel: false,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      textStyle: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500),
      hintStyle: TextStyle(fontSize: 12.5, color: Colors.grey.shade400),
      isDense: true,
      suffixIconPadding: const EdgeInsets.all(9),
      suffixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: 36),
    );
  }

  void _onSpecializationChanged(String value) {
    final query = value.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() {
        _filteredSpecializations = [];
      });
      return;
    }

    final matches = _specializations
        .where((item) => item.toLowerCase().contains(query))
        .toList();

    setState(() {
      _filteredSpecializations = matches;
    });
  }

  void _selectSpecialization(String value) {
    _specializationController.text = value;
    _specializationController.selection = TextSelection.collapsed(
      offset: value.length,
    );
    setState(() {
      _filteredSpecializations = [];
    });
    KeyboardUtils.hideKeyboardKeepFocus();
  }

  Widget _textFieldStep({
    required String label,
    required String hintText,
    required TextEditingController controller,
    TextInputType? keyboardType,
    FocusNode? focusNode,
    TextInputAction? textInputAction,
    String? suffixIconPath,
    VoidCallback? onSuffixTap,
    List<TextInputFormatter>? inputFormatters,
    ValueChanged<String>? onChanged,
    bool readOnly = false,
    VoidCallback? onTap,
    bool showLabel = true,
    EdgeInsetsGeometry? contentPadding,
    VoidCallback? onEditingComplete,
    ValueChanged<String>? onSubmitted,
    TextStyle? textStyle,
    TextStyle? hintStyle,
    bool isDense = false,
    EdgeInsetsGeometry? suffixIconPadding,
    BoxConstraints? suffixIconConstraints,
    int? minLines,
    int? maxLines,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showLabel) ...[
          Text(
            label,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 10),
        ],
        TextField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          minLines: minLines,
          maxLines: maxLines,
          inputFormatters: inputFormatters,
          onChanged: onChanged,
          readOnly: readOnly,
          onTap: onTap,
          onEditingComplete: onEditingComplete,
          onSubmitted: onSubmitted,
          onTapOutside: (_) => KeyboardUtils.hideKeyboardKeepFocus(),
          style: textStyle,
          decoration: InputDecoration(
            isDense: isDense,
            contentPadding: contentPadding,
            suffixIconConstraints: suffixIconConstraints,
            suffixIcon: suffixIconPath == null
                ? null
                : InkWell(
                    onTap: onSuffixTap,
                    child: Padding(
                      padding: suffixIconPadding ?? const EdgeInsets.all(12),
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
            hintStyle: hintStyle ?? TextStyle(color: Colors.grey.shade400),
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
          label: 'Experience',
          hintText: 'Enter years of experience',
          controller: _experienceController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        );
      case 1:
        return Builder(
          builder: (context) {
            final media = MediaQuery.of(context);
            final keyboardInset = media.viewInsets.bottom;
            final safeVertical = media.padding.top + media.padding.bottom;
            final availableHeight =
                media.size.height - keyboardInset - safeVertical;
            final suggestionMaxHeight = keyboardInset > 0
                ? 110.0
                : (availableHeight * 0.28).clamp(110.0, 200.0);

            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.only(bottom: keyboardInset + 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _textFieldStep(
                    label: 'Specialization',
                    hintText: 'Enter specialization',
                    controller: _specializationController,
                    keyboardType: TextInputType.text,
                    onChanged: _onSpecializationChanged,
                  ),
                  if (_filteredSpecializations.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      constraints: BoxConstraints(
                        maxHeight: suggestionMaxHeight,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.grey.shade300),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: _filteredSpecializations.length,
                          separatorBuilder: (context, _) => Divider(
                            height: 1,
                            thickness: 0.6,
                            color: Colors.grey.shade200,
                          ),
                          itemBuilder: (context, index) {
                            final item = _filteredSpecializations[index];
                            return InkWell(
                              onTap: () => _selectSpecialization(item),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                child: Text(
                                  item,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      case 2:
        return _textFieldStep(
          label: 'Hospital Name',
          hintText: 'Enter hospital or clinic name',
          controller: _hospitalNameController,
          keyboardType: TextInputType.text,
        );
      case 3:
        return _textFieldStep(
          label: 'About',
          hintText:
              'Tell patients about your experience, specialization, and approach to treatment.',
          controller: _aboutController,
          keyboardType: TextInputType.multiline,
          textInputAction: TextInputAction.newline,
          minLines: 3,
          maxLines: 5,
        );
      case 4:
        return _textFieldStep(
          label: 'Consultation Fee',
          hintText: 'Enter consultation fee',
          controller: _consultationFeeController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
          ],
        );
      case 5:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Working Days',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 10),
            ..._days.map((day) {
              final isSelected = _selectedDays.contains(day);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _choiceTile(
                  title: _dayLabels[day] ?? day,
                  isSelected: isSelected,
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedDays.remove(day);
                        _removeAvailabilityDay(day);
                      } else {
                        _selectedDays.add(day);
                        _ensureAvailabilityDay(day);
                      }
                    });
                  },
                ),
              );
            }),
          ],
        );
      case 6:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ..._days.where(_selectedDays.contains).map((day) {
              _ensureAvailabilityDay(day);
              final daySchedule = _scheduleForDay(day)!;
              final morningEnabled = daySchedule.morningEnabled;
              final afternoonEnabled = daySchedule.afternoonEnabled;
              return Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _dayLabels[day] ?? day,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F7FF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Morning Session',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Switch(
                                value: morningEnabled,
                                onChanged: (value) =>
                                    _setSessionEnabled(day, 'morning', value),
                                activeThumbColor: const Color(0xFF3F67FD),
                                activeTrackColor: const Color.fromARGB(
                                  255,
                                  196,
                                  209,
                                  255,
                                ),
                              ),
                            ],
                          ),
                          if (morningEnabled) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: _availabilityField(
                                    day: day,
                                    slotKey: 'morningStart',
                                    hint: 'Start Time',
                                    nextSlotKey: 'morningEnd',
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  '-',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _availabilityField(
                                    day: day,
                                    slotKey: 'morningEnd',
                                    hint: 'End Time',
                                    nextSlotKey: afternoonEnabled
                                        ? 'afternoonStart'
                                        : null,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                          ],
                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Afternoon Session',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Switch(
                                value: afternoonEnabled,
                                onChanged: (value) =>
                                    _setSessionEnabled(day, 'afternoon', value),
                                activeThumbColor: const Color(0xFF3F67FD),
                                activeTrackColor: const Color.fromARGB(
                                  255,
                                  196,
                                  209,
                                  255,
                                ),
                              ),
                            ],
                          ),
                          if (afternoonEnabled) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: _availabilityField(
                                    day: day,
                                    slotKey: 'afternoonStart',
                                    hint: 'Start Time',
                                    nextSlotKey: 'afternoonEnd',
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  '-',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _availabilityField(
                                    day: day,
                                    slotKey: 'afternoonEnd',
                                    hint: 'End Time',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        );
      case 7:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...[15, 20, 30, 45, 60].map((minutes) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 15),
                child: _choiceTile(
                  title: '$minutes minutes',
                  isSelected: _slotDuration == minutes,
                  onTap: () => setState(() => _slotDuration = minutes),
                ),
              );
            }),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _experienceController.dispose();
    _specializationController.dispose();
    _hospitalNameController.dispose();
    _aboutController.dispose();
    _consultationFeeController.dispose();
    for (final dayControllers in _availabilityControllers.values) {
      for (final controller in dayControllers.values) {
        controller.dispose();
      }
    }
    for (final dayFocusNodes in _availabilityFocusNodes.values) {
      for (final node in dayFocusNodes.values) {
        node.dispose();
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_currentPage + 1) / 8;
    final headerHeight = _stableHeaderHeight(context);

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
                          padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
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
                              SizedBox(
                                height: headerHeight,
                                child: Column(
                                  children: [
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
                                  ],
                                ),
                              ),
                              const SizedBox(height: 40),
                              Expanded(
                                child: PageView.builder(
                                  controller: _pageController,
                                  itemCount: 8,
                                  physics: const NeverScrollableScrollPhysics(),
                                  onPageChanged: (index) {
                                    setState(() {
                                      _currentPage = index;
                                      _stepErrorMessage = null;
                                    });
                                  },
                                  itemBuilder: (context, index) {
                                    final content = _stepContent(index);
                                    if (index == 1) {
                                      return content;
                                    }
                                    return SingleChildScrollView(
                                      child: content,
                                    );
                                  },
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
                              const SizedBox(height: 16),
                              NextActionButton(
                                text: _currentPage == 7 ? 'Finish' : 'Next',
                                isLoading: _currentPage == 7 && _isFinishing,
                                loadingText: 'Finishing...',
                                onTap: () => _onNext(),
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
