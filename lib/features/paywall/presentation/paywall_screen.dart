import 'package:flutter/material.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

class PaywallScreen extends StatelessWidget {
  const PaywallScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PaywallView(
        onPurchaseCompleted: (customerInfo, storeTransaction) {
          // Purchase completed, pop the screen
          Navigator.of(context).pop();
        },
        onRestoreCompleted: (customerInfo) {
          // Restore completed, show a message or pop
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Purchases restored successfully')),
          );
        },
      ),
    );
  }
}
