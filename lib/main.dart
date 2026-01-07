import 'package:flutter/material.dart';
import 'package:unblur_images/core/constants/supabase_constants.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unblur_images/features/auth/presentation/login_screen.dart';
import 'package:unblur_images/features/home/presentation/home_screen.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:unblur_images/features/paywall/data/iap_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConstants.url,
    anonKey: SupabaseConstants.anonKey,
  );

  await SentryFlutter.init(
    (options) {
      options.dsn =
          'https://1fc9fcfa26f584b6d2eba513ffdfd723@o4510480770990080.ingest.us.sentry.io/4510480772694016';
      // Set tracesSampleRate to 1.0 to capture 100% of transactions for tracing.
      // We recommend adjusting this value in production.
      options.tracesSampleRate = 1.0;
      // The sampling rate for profiling is relative to tracesSampleRate
      // Setting to 1.0 will profile 100% of sampled transactions:
      options.profilesSampleRate = 1.0;
    },
    appRunner: () =>
        runApp(SentryWidget(child: const ProviderScope(child: MyApp()))),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Image Enhancer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends ConsumerStatefulWidget {
  const AuthGate({super.key});

  @override
  ConsumerState<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<AuthGate> {
  @override
  void initState() {
    super.initState();
    // Initialize RevenueCat
    ref.read(iapRepositoryProvider).initialize();

    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final user = data.session?.user;
      final userId = user?.id;
      if (userId != null) {
        // Extract user attributes from metadata (Google Sign-In fills these)
        final name = user?.userMetadata?['full_name'] as String?;
        final email = user?.email;

        ref.read(iapRepositoryProvider).logIn(userId, name: name, email: email);
      }
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      return const HomeScreen();
    } else {
      return const LoginScreen();
    }
  }
}
