import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/features/order/domain/models/order_model.dart';
import 'package:flutter_sixvalley_ecommerce/helper/price_converter.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';

class PostPaymentRefundCard extends StatelessWidget {
  final Orders? order;
  const PostPaymentRefundCard({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final refund = order?.refundSummary;
    if (refund == null) return const SizedBox.shrink();

    final purchaseAmount = double.tryParse('${refund['purchase_amount'] ?? 0}') ?? 0;
    final insuranceAmount = double.tryParse('${refund['insurance_amount'] ?? 0}') ?? 0;
    final available = refund['status'] == 'available';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(
        Dimensions.paddingSizeDefault,
        Dimensions.paddingSizeSmall,
        Dimensions.paddingSizeDefault,
        0,
      ),
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        color: (available ? Colors.green : Colors.orange).withValues(alpha: .08),
        border: Border.all(color: (available ? Colors.green : Colors.orange).withValues(alpha: .35)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(available ? Icons.account_balance_wallet_outlined : Icons.schedule, color: available ? Colors.green : Colors.orange),
          const SizedBox(width: 8),
          Expanded(child: Text(
            getTranslated(available ? 'refund_balance_available' : 'refund_balance_held', context) ?? '',
            style: const TextStyle(fontWeight: FontWeight.w700),
          )),
        ]),
        const SizedBox(height: 10),
        _line(context, getTranslated('purchase_balance', context) ?? 'Purchase balance',
            PriceConverter.convertPrice(context, purchaseAmount)),
        _line(context, getTranslated('insurance_balance', context) ?? 'Insurance balance',
            PriceConverter.convertPrice(context, insuranceAmount)),
        if (!available) ...[
          _line(context, getTranslated('purchase_available_at', context) ?? 'Purchase available at',
              '${refund['purchase_available_at'] ?? '-'}'),
          _line(context, getTranslated('insurance_available_at', context) ?? 'Insurance available at',
              '${refund['insurance_available_at'] ?? '-'}'),
        ],
        const SizedBox(height: 6),
        Text(
          getTranslated('refund_balances_usage_note', context) ?? '',
          style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor),
        ),
      ]),
    );
  }

  Widget _line(BuildContext context, String label, String value) => Padding(
    padding: const EdgeInsets.only(top: 5),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(child: Text(label, style: TextStyle(color: Theme.of(context).hintColor))),
      Expanded(child: Text(value, textAlign: TextAlign.end, style: const TextStyle(fontWeight: FontWeight.w600))),
    ]),
  );
}
