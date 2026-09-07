import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/features/order_details/controllers/order_details_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/order_details/domain/models/order_details_model.dart';
import 'package:flutter_sixvalley_ecommerce/helper/route_healper.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';

class SellerSectionWidget extends StatelessWidget {
  final OrderDetailsController? order;
  const SellerSectionWidget({super.key, this.order});
  @override
  Widget build(BuildContext context) => Card(child: ListTile(
    leading: const Icon(Icons.support_agent),
    title: Text(getTranslated('support_ticket', context) ?? ''),
    trailing: const Icon(Icons.chevron_right),
    onTap: () => RouterHelper.getSupportTicketRoute(action: RouteAction.push),
  ));
}

class OrderSellerInfoWidget extends StatelessWidget {
  final OrderDetailsModel? orderDetails;
  final double widthFactor;
  const OrderSellerInfoWidget({super.key, required this.orderDetails, this.widthFactor = 0.6});
  @override
  Widget build(BuildContext context) => Text(getTranslated('products', context) ?? '');
}
