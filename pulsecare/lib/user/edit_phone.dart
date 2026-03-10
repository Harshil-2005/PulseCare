import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:pulsecare/constrains/primary_icon_button.dart';
import 'package:pulsecare/providers/repository_providers.dart';
import 'package:pulsecare/repositories/session_repository.dart';

class EditPhone extends ConsumerStatefulWidget {
  const EditPhone({super.key});

  @override
  ConsumerState<EditPhone> createState() => _EditPhoneState();
}

class _EditPhoneState extends ConsumerState<EditPhone> {
  late final TextEditingController _phoneController;
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
    _phoneController = TextEditingController(text: user?.phone ?? '');
    if (!mounted) return;
    setState(() {
      _ready = true;
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
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
            'Edit Phone',
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
                'Update your phone',
                style: TextStyle(fontWeight: .w700, fontSize: 24),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(
                'Keeping your phone updated helps doctors reach you when necessary.',
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
              'Phone',
              style: TextStyle(
                fontWeight: FontWeight.w400,
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _phoneController,
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
                  final phone = _phoneController.text.trim();
                  if (phone.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter your phone.')),
                    );
                    return;
                  }
                  if (user != null) {
                    final updatedUser = user.copyWith(phone: phone);
                    await ref.read(userRepositoryProvider).updateUser(
                      SessionRepository().getCurrentUserId(),
                      updatedUser,
                    );
                    if (!mounted) return;
                  }
                  Navigator.pop(context);
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
