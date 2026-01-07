import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

class UpgradeToProScreen extends ConsumerWidget {
  const UpgradeToProScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: PaywallView(
        onDismiss: () => Navigator.pop(context),
        onPurchaseCompleted: (customerInfo, storeTransaction) {
          // Show a success toast (SnackBar) when the purchase is completed
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Purchase successful!'),
              backgroundColor: Colors.green,
            ),
          );
          // When a user successfully purchases anything from the buy credits screen,
          // redirect them to the homepage by popping back to the root navigation item.
          Navigator.of(context).popUntil((route) => route.isFirst);
        },
        onRestoreCompleted: (customerInfo) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Purchases restored successfully')),
          );
        },
      ),
    );
  }

  // NOTE: Previous "Free Credit" logic is preserved here for reference if you want to re-add it.
  /*
  Future<void> _handleFreeCredit(WidgetRef ref, BuildContext context) async {
    try {
      final usageRepo = ref.read(usageRepositoryProvider);
      await usageRepo.addCredits(1);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Free credit added!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Failed to add free credit: $e');
    }
  }
  */
}
