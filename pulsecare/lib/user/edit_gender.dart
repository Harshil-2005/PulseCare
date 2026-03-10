import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:pulsecare/appointment_screens/appointment_screen.dart';
import 'package:pulsecare/constrains/primary_icon_button.dart';
import 'package:pulsecare/providers/repository_providers.dart';
import 'package:pulsecare/repositories/session_repository.dart';
import 'package:pulsecare/user/home_screen.dart';
import 'package:pulsecare/user/my_report_screen.dart';
import 'package:pulsecare/user/profile_screen.dart';

class EditGender extends ConsumerStatefulWidget {
  final bool fromEditProfile;

  const EditGender({super.key, this.fromEditProfile = false});

  @override
  ConsumerState<EditGender> createState() => _EditGenderState();
}

class _EditGenderState extends ConsumerState<EditGender> {
  final List<Widget> screens = [
    const HomeScreen(),
    const AppointmentScreen(),
    const MyReportScreen(),
    const ProfileScreen(),
  ];
  String selectedGender = '';
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
    selectedGender = user?.gender ?? '';
    if (!mounted) return;
    setState(() {
      _ready = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
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
            'Edit Gender',
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
            SizedBox(height: 80),

            Center(
              child: Text(
                'Select Gender',
                style: TextStyle(fontWeight: .w700, fontSize: 24),
              ),
            ),
            SizedBox(height: 20),
            Center(
              child: Text(
                'This Information helps personalize your health experience.',
                style: TextStyle(
                  fontWeight: .w400,
                  fontSize: 18,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 50),

            Column(
              children: [
                genderTile('Female'),
                const SizedBox(height: 15),
                genderTile('Male'),
              ],
            ),
            const SizedBox(height: 34),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.only(bottom: 50),
              child: PrimaryIconButton(
                text: 'Save Changes',
                iconPath: 'assets/icons/save.svg',
                onTap: () async {
                  final user = await ref.read(userRepositoryProvider).getUserById(
                    SessionRepository().getCurrentUserId(),
                  );
                  if (!mounted) return;
                  if (user != null) {
                    final updatedUser = user.copyWith(
                      gender: selectedGender,
                    );
                    await ref.read(userRepositoryProvider).updateUser(
                      SessionRepository().getCurrentUserId(),
                      updatedUser,
                    );
                    if (!mounted) return;
                  }
                  if (widget.fromEditProfile) {
                    Navigator.pop(context); // back to EditAge
                    Navigator.pop(context); // back to EditProfile
                    Navigator.pop(context); // back to Profile
                  } else {
                    Navigator.pop(context); // direct edit → back to Profile
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

  Widget genderTile(String gender) {
    final bool isSelected = selectedGender == gender;

    return InkWell(
      onTap: () {
        setState(() {
          selectedGender = gender;
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
}

