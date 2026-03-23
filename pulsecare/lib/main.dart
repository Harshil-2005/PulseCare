import 'package:flutter/material.dart';
import 'package:pulsecare/utils/keyboard_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'firebase_options.dart';
import 'package:pulsecare/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await Supabase.initialize(
    url: "https://nsncndzlkjlaxxvdylmq.supabase.co",
    anonKey: 'sb_publishable_vTp9Fh0XfA7cb2Vp8JtyYA_WWQ8WzDP',
  );

  await _ensureSupabaseSession();

  runApp(ProviderScope(child: const MyApp(home: SplashScreen())));
}

Future<void> _ensureSupabaseSession() async {
  final client = Supabase.instance.client;
  if (client.auth.currentSession != null) {
    return;
  }
  try {
    await client.auth.signInAnonymously();
  } catch (error) {
    debugPrint('[main] Supabase anonymous sign-in skipped: $error');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.home});

  final Widget home;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PulseCare',
      builder: (context, child) {
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            final currentFocus = FocusScope.of(context);
            if (!currentFocus.hasPrimaryFocus &&
                currentFocus.focusedChild != null) {
              KeyboardUtils.hideKeyboardKeepFocus();
            }
          },
          child: child ?? const SizedBox.shrink(),
        );
      },
      theme: ThemeData(
        fontFamily: 'Poppins',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 255, 255, 255),
        ),
      ),
      home: home,
    );
  }
}
