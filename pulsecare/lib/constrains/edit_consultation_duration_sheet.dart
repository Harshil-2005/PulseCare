import 'package:flutter/material.dart';

class EditConsultationDurationSheet extends StatefulWidget {
  const EditConsultationDurationSheet({
    super.key,
    required this.currentDuration,
    required this.onSelected,
  });

  final int currentDuration;
  final ValueChanged<int> onSelected;

  @override
  State<EditConsultationDurationSheet> createState() =>
      _EditConsultationDurationSheetState();
}

class _EditConsultationDurationSheetState
    extends State<EditConsultationDurationSheet> {
  static const List<int> _durations = [15, 20, 30, 45, 60];
  late int _selectedDuration;

  @override
  void initState() {
    super.initState();
    _selectedDuration = widget.currentDuration;
  }

  Widget _choiceTile({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
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
    return AnimatedPadding(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Consultation Duration',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              ..._durations.map((minutes) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _choiceTile(
                    title: '$minutes minutes',
                    isSelected: _selectedDuration == minutes,
                    onTap: () {
                      setState(() {
                        _selectedDuration = minutes;
                      });
                    },
                  ),
                );
              }),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: () => widget.onSelected(_selectedDuration),
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xff3F67FD),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Center(
                    child: Text(
                      'Save Changes',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
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
