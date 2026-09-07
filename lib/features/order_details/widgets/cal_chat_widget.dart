import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/features/order/domain/models/order_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/order_details/controllers/order_details_controller.dart';
import 'package:flutter_sixvalley_ecommerce/helper/route_healper.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:flutter_sixvalley_ecommerce/utill/images.dart';

/// Order communication is intentionally routed to platform administration.
/// Customers cannot call or message sellers or delivery personnel directly.
class CallAndChatWidget extends StatelessWidget {
  final OrderDetailsController? orderProvider;
  final Orders? orderModel;
  final bool isSeller;

  const CallAndChatWidget({
    super.key,
    this.orderProvider,
    this.isSeller = false,
    this.orderModel,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => RouterHelper.getSupportTicketRoute(action: RouteAction.push),
      borderRadius: BorderRadius.circular(50),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: Dimensions.paddingSizeDefault,
            vertical: Dimensions.paddingSizeSmall,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).hintColor.withValues(alpha: .0525),
            border: Border.all(color: Theme.of(context).hintColor),
            borderRadius: BorderRadius.circular(50),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(Images.smsIcon, width: 20, color: Theme.of(context).primaryColor),
              const SizedBox(width: Dimensions.paddingSizeExtraSmall),
              Flexible(child: Text(getTranslated('support_ticket', context) ?? '')),
            ],
          ),
        ),
      ),
    );
  }
}
