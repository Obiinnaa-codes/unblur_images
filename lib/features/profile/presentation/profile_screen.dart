import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unblur_images/features/history/presentation/history_screen.dart';
import 'package:unblur_images/features/auth/presentation/login_screen.dart';
import 'package:unblur_images/features/paywall/data/usage_repository.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = Supabase.instance.client.auth.currentUser;
    final profileImageUrl = user?.userMetadata?['avatar_url'] as String?;
    final fullName = user?.userMetadata?['full_name'] as String? ?? 'User';
    final email = user?.email ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: ref.read(usageRepositoryProvider).getUsageStatus(),
        builder: (context, snapshot) {
          final isPro = snapshot.data?['isSubscribed'] ?? false;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: profileImageUrl != null
                          ? NetworkImage(profileImageUrl)
                          : null,
                      child: profileImageUrl == null
                          ? const Icon(Icons.person, size: 50)
                          : null,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      fullName,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    Text(email, style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 8),
                    // Dynamic Plan Chip
                    Chip(
                      label: Text(
                        isPro ? 'Pro' : 'Free Plan',
                        style: TextStyle(
                          color: isPro ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      avatar: isPro
                          ? const Icon(
                              Icons.all_inclusive,
                              color: Colors.white,
                              size: 18,
                            )
                          : null,
                      backgroundColor: isPro
                          ? Colors.deepPurple
                          : Colors.grey[300],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.history),
                title: const Text('History'),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const HistoryScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.credit_card),
                title: const Text('Buy Credits'),
                onTap: () async {
                  // Present the RevenueCat paywall.
                  // When a user successfully purchases something, redirect them to the homepage.
                  final result = await RevenueCatUI.presentPaywall();
                  if (result == PaywallResult.purchased && context.mounted) {
                    // Show a success toast (SnackBar) when the purchase is completed
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Purchase successful!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    // Redirect to the homepage by popping back to the root
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  }
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text(
                  'Sign Out',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () async {
                  // Sign out from Supabase and redirect to the login page
                  await Supabase.instance.client.auth.signOut();
                  if (context.mounted) {
                    // Redirect to the login page and remove all previous routes from the stack
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                      (route) => false,
                    );
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
