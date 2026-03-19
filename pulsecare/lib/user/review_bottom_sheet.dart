import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulsecare/constrains/app_toast.dart';
import 'package:pulsecare/model/appointment_model.dart';
import 'package:pulsecare/model/doctor_review_model.dart';
import 'package:pulsecare/providers/repository_providers.dart';

class ReviewBottomSheet extends ConsumerStatefulWidget {
  const ReviewBottomSheet({super.key, required this.appointment});

  final Appointment appointment;

  @override
  ConsumerState<ReviewBottomSheet> createState() => _ReviewBottomSheetState();
}

class _ReviewBottomSheetState extends ConsumerState<ReviewBottomSheet> {
  late final TextEditingController _commentController;
  int _rating = 0;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _commentController = TextEditingController();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    if (_rating == 0 || _isSubmitting) {
      if (_rating == 0 && mounted) {
        showAppToast(context, 'Please select a rating.');
      }
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final review = DoctorReview(
      id: '',
      doctorId: widget.appointment.doctorId,
      userId: widget.appointment.userId,
      appointmentId: widget.appointment.id,
      rating: _rating.toDouble(),
      comment: _commentController.text.trim(),
      createdAt: DateTime.now(),
    );

    try {
      await ref.read(doctorReviewRepositoryProvider).createReview(review);

      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
      });
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
      });

      // HANDLE DUPLICATE CASE
      if (e.toString().contains('duplicate_review_for_appointment')) {
        showAppToast(context, 'Review already submitted');
        Navigator.pop(context);
        return;
      }

      if (e.toString().contains('appointment_not_found')) {
        showAppToast(context, 'Appointment not found for this review.');
        return;
      }

      if (e.toString().contains('review_submission_failed')) {
        showAppToast(
          context,
          'Could not submit review right now. Please try again.',
        );
        return;
      }

      // SHOW REAL ERROR
      showAppToast(context, 'Error: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 20,
          bottom: 16 + bottomInset,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Text(
                'Rate Your Consultation',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (index) {
                  final starIndex = index + 1;
                  final isSelected = _rating >= starIndex;
                  return IconButton(
                    onPressed: _isSubmitting
                        ? null
                        : () {
                            setState(() {
                              _rating = starIndex;
                            });
                          },
                    icon: Icon(
                      isSelected ? Icons.star : Icons.star_border,
                      color: isSelected ? const Color(0xFFF59E0B) : Colors.grey,
                      size: 28,
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _commentController,
              minLines: 3,
              maxLines: null,
              textInputAction: TextInputAction.newline,
              decoration: InputDecoration(
                hintText: 'Write a review (optional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitReview,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff3F67FD),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Text(
                  _isSubmitting ? 'Submitting...' : 'Submit Review',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
