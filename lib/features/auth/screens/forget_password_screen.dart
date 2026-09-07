import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_app_bar_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_button_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/contact_us/screens/contact_us_screen.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/utill/custom_themes.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';

class ForgetPasswordScreen extends StatelessWidget {
  const ForgetPasswordScreen({super.key});

  String _text(BuildContext context, String key, String fallback) =>
      getTranslated(key, context) ?? fallback;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: _text(context, 'forget_password', 'Forgot password')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
          children: [
            const SizedBox(height: Dimensions.paddingSizeExtraLarge),
            Icon(Icons.lock_reset_rounded, size: 120, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: Dimensions.paddingSizeLarge),
            Text(
              _text(context, 'password_reset_support_title', 'Password reset support'),
              textAlign: TextAlign.center,
              style: textBold.copyWith(fontSize: Dimensions.fontSizeLarge),
            ),
            const SizedBox(height: Dimensions.paddingSizeDefault),
            Text(
              _text(
                context,
                'password_reset_support_message',
                'To protect your account, password resets are handled by our support team.',
              ),
              textAlign: TextAlign.center,
              style: textRegular.copyWith(color: Theme.of(context).hintColor),
            ),
            const SizedBox(height: Dimensions.paddingSizeSmall),
            Text(
              _text(
                context,
                'password_reset_support_identity_notice',
                'Send a support request with your account details. Support will verify your identity, contact you through the request, and arrange the reset.',
              ),
              textAlign: TextAlign.center,
              style: textRegular.copyWith(color: Theme.of(context).hintColor),
            ),
            const SizedBox(height: Dimensions.paddingSizeExtraLarge),
            CustomButton(
              buttonText: _text(context, 'contact_support', 'Contact support'),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ContactUsScreen(isPasswordReset: true)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
