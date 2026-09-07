import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/controllers/auth_controller.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/not_loggedin_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/wallet/screens/customer_wallet_screen.dart';
import 'package:flutter_sixvalley_ecommerce/helper/route_healper.dart';

class WalletScreen extends StatelessWidget {
  final bool isBacButtonExist;
  const WalletScreen({super.key, this.isBacButtonExist = true});
  @override
  Widget build(
          BuildContext context) =>
      context.watch<AuthController>().isLoggedIn()
          ? const CustomerWalletScreen()
          : const Scaffold(
              body: NotLoggedInWidget(fromPage: RouterHelper.walletScreen));
}
