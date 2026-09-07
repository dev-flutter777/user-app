import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/features/support/screens/support_ticket_screen.dart';

/// Customer communication is restricted to administration and support tickets.
/// The old vendor/delivery-person conversation tabs are deliberately retired.
class InboxScreen extends StatelessWidget {
  final bool isBackButtonExist;
  final bool fromNotification;
  final bool fromDashboard;
  final int initIndex;

  const InboxScreen({
    super.key,
    this.isBackButtonExist = true,
    this.fromNotification = false,
    this.initIndex = 0,
    this.fromDashboard = false,
  });

  @override
  Widget build(BuildContext context) {
    return SupportTicketScreen(
      isBackButtonExist: isBackButtonExist,
      fromDashboard: fromDashboard,
    );
  }
}
