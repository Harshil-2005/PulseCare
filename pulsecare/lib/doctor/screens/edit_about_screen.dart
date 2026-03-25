import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pulsecare/constrains/app_page_loader.dart';
import 'package:pulsecare/constrains/primary_icon_button.dart';
import 'package:pulsecare/providers/repository_providers.dart';
import 'package:pulsecare/repositories/session_repository.dart';
import 'package:pulsecare/utils/keyboard_utils.dart';

class EditAboutScreen extends ConsumerStatefulWidget {
  const EditAboutScreen({super.key});

  @override
  ConsumerState<EditAboutScreen> createState() => _EditAboutScreenState();
}

class _EditAboutScreenState extends ConsumerState<EditAboutScreen> {
  late final TextEditingController _aboutController;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final doctorId = SessionRepository().getCurrentDoctorId();
    final doctor = await ref
        .read(doctorRepositoryProvider)
        .getDoctorById(doctorId);
    _aboutController = TextEditingController(text: doctor?.about ?? '');
    if (!mounted) return;
    setState(() {
      _ready = true;
    });
  }

  @override
  void dispose() {
    _aboutController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const AppPageLoader(message: 'Loading about details...');
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
            'Edit About',
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
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(top: 30, left: 16, right: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 80),
                      Center(
                        child: Text(
                          'Edit About',
                          style: TextStyle(fontWeight: .w700, fontSize: 24),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: Text(
                          'Tell patients about your experience and treatment approach.',
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
                        'About',
                        style: TextStyle(
                          fontWeight: FontWeight.w400,
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _aboutController,
                        minLines: 3,
                        maxLines: null,
                        keyboardType: TextInputType.multiline,
                        textInputAction: TextInputAction.newline,
                        onTapOutside: (_) =>
                            KeyboardUtils.hideKeyboardKeepFocus(),
                        decoration: InputDecoration(
                          hintText:
                              'Tell patients about your experience, specialization, and approach to treatment.',
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
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 50, top: 12),
                child: PrimaryIconButton(
                  text: 'Save Changes',
                  iconPath: 'assets/icons/save.svg',
                  onTap: () async {
                    final doctorId = SessionRepository().getCurrentDoctorId();
                    final doctor = await ref
                        .read(doctorRepositoryProvider)
                        .getDoctorById(doctorId);
                    if (!mounted) return;
                    if (doctor != null) {
                      final updatedDoctor = doctor.copyWith(
                        about: _aboutController.text.trim(),
                      );
                      await ref
                          .read(doctorRepositoryProvider)
                          .updateDoctor(updatedDoctor);
                      if (!context.mounted) return;
                    }
                    if (!context.mounted) return;
                    Navigator.pop(context);
                  },
                  height: 60,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
