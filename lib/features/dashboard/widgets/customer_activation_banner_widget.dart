import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/features/profile/domain/models/profile_model.dart';
import 'package:flutter_sixvalley_ecommerce/helper/route_healper.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';

class CustomerActivationBannerWidget extends StatelessWidget {
  final CustomerActivationModel activation;

  const CustomerActivationBannerWidget({super.key, required this.activation});

  @override
  Widget build(BuildContext context) {
    if (activation.isActive) return const SizedBox.shrink();

    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.errorContainer,
      child: SafeArea(
        bottom: false,
        child: InkWell(
          onTap: () => RouterHelper.getSupportTicketRoute(action: RouteAction.push),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Dimensions.paddingSizeDefault,
              vertical: Dimensions.paddingSizeSmall,
            ),
            child: Row(children: [
              Icon(Icons.support_agent, color: colors.onErrorContainer),
              const SizedBox(width: Dimensions.paddingSizeSmall),
              Expanded(
                child: Text(
                  activation.message ??
                      getTranslated('customer_activation_support_message', context) ??
                      '',
                  style: TextStyle(color: colors.onErrorContainer, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: Dimensions.paddingSizeSmall),
              Icon(Icons.arrow_forward_ios, size: 16, color: colors.onErrorContainer),
            ]),
          ),
        ),
      ),
    );
  }
}
