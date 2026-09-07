import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_app_bar_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/show_custom_snakbar_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/checkout/screens/digital_payment_order_place_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/order_insurance/controllers/customer_order_insurance_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/order_insurance/domain/models/customer_order_insurance_model.dart';
import 'package:flutter_sixvalley_ecommerce/helper/price_converter.dart';
import 'package:flutter_sixvalley_ecommerce/helper/route_healper.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class CustomerOrderInsuranceScreen extends StatefulWidget {
  final int orderId;
  const CustomerOrderInsuranceScreen({super.key, required this.orderId});

  @override
  State<CustomerOrderInsuranceScreen> createState() => _CustomerOrderInsuranceScreenState();
}

class _CustomerOrderInsuranceScreenState extends State<CustomerOrderInsuranceScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<CustomerOrderInsuranceController>().load(widget.orderId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: getTranslated('customer_order_insurance', context)),
      body: Consumer<CustomerOrderInsuranceController>(builder: (context, controller, _) {
        if (controller.loading && controller.envelope == null) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.envelope == null) {
          return _ErrorState(
            message: controller.error?.toString() ?? getTranslated('unable_to_load_insurance_claim', context)!,
            onRetry: () => controller.load(widget.orderId),
          );
        }
        return RefreshIndicator(
          onRefresh: () async {
            await controller.load(widget.orderId);
          },
          child: _ClaimContent(orderId: widget.orderId, envelope: controller.envelope!),
        );
      }),
    );
  }
}

class _ClaimContent extends StatelessWidget {
  final int orderId;
  final CustomerOrderInsuranceEnvelope envelope;
  const _ClaimContent({required this.orderId, required this.envelope});

  @override
  Widget build(BuildContext context) {
    final claim = envelope.claim;
    final controller = context.read<CustomerOrderInsuranceController>();
    return ListView(padding: const EdgeInsets.all(16), children: [
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: claim.canPay
              ? Theme.of(context).colorScheme.errorContainer
              : Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            claim.canPay
                ? getTranslated('purchase_paid_insurance_pending_title', context)!
                : _statusLabel(context, claim),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700,
              color: claim.canPay ? Theme.of(context).colorScheme.onErrorContainer : Theme.of(context).colorScheme.onPrimaryContainer),
          ),
          const SizedBox(height: 8),
          Text(claim.canPay
              ? getTranslated('purchase_paid_insurance_pending_description', context)!
              : getTranslated('insurance_claim_status_description', context)!,
              style: TextStyle(color: claim.canPay ? Theme.of(context).colorScheme.onErrorContainer : Theme.of(context).colorScheme.onPrimaryContainer)),
        ]),
      ),
      const SizedBox(height: 12),
      Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
        _row(context, getTranslated('order_reference', context)!, claim.orderReference),
        _row(context, getTranslated('purchases_amount_paid', context)!, PriceConverter.convertPrice(context, claim.purchaseAmount)),
        _row(context, getTranslated('tax_amount_due', context)!, PriceConverter.convertPrice(context, claim.taxAmount)),
        _row(context, getTranslated('insurance_amount_due', context)!, PriceConverter.convertPrice(context, claim.insuranceAmount)),
        _row(context, getTranslated('total_amount_due', context)!, PriceConverter.convertPrice(context, claim.externalAmountDue)),
        _row(context, getTranslated('payment_deadline', context)!, claim.paymentDueAt ?? '-'),
        _row(context, getTranslated('insurance_payment_status', context)!, _statusLabel(context, claim)),
      ]))),
      const SizedBox(height: 12),
      Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(getTranslated('insurance_wallet', context)!, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        _row(context, getTranslated('insurance_available_balance', context)!, PriceConverter.convertPrice(context, envelope.balance.availableBalance)),
        _row(context, getTranslated('insurance_held_balance', context)!, PriceConverter.convertPrice(context, envelope.balance.heldBalance)),
        Text(getTranslated('insurance_wallet_only_notice', context)!, style: Theme.of(context).textTheme.bodySmall),
      ]))),
      if (claim.canPay) ...[
        const SizedBox(height: 12),
        Text(getTranslated('choose_insurance_payment_method', context)!, style: Theme.of(context).textTheme.titleMedium),
        if (envelope.paymentOptions.insuranceBalance)
          _actionButton(
            context,
            icon: Icons.account_balance_wallet_outlined,
            label: getTranslated('pay_from_insurance_wallet', context)!,
            enabled: envelope.balance.availableBalance > 0,
            onPressed: () async {
              await controller.pay(orderId, 'customer_insurance_balance');
              if (context.mounted) _showResult(context, controller);
            },
          ),
        ...envelope.paymentOptions.digitalGateways.map((gateway) => _actionButton(
          context,
          icon: Icons.credit_card,
          label: '${getTranslated('pay_with', context)} ${gateway.title}',
          onPressed: () async {
            final redirect = await controller.pay(orderId, gateway.id);
            if (!context.mounted) return;
            if (redirect != null && redirect.isNotEmpty) {
              await Navigator.push(context, MaterialPageRoute(builder: (_) =>
                DigitalPaymentScreen(url: redirect, orderId: orderId.toString(), isInsurancePayment: true),
              ));
              if (context.mounted) await controller.load(orderId);
            } else {
              _showResult(context, controller);
            }
          },
        )),
        if (envelope.paymentOptions.offlinePayment && envelope.paymentOptions.offlineMethods.isNotEmpty)
          _actionButton(
            context,
            icon: Icons.receipt_long_outlined,
            label: getTranslated('submit_offline_insurance_payment', context)!,
            onPressed: () => _offlineDialog(context, controller),
          ),
      ],
      if (claim.refundScheduled || claim.refundCompleted) ...[
        const SizedBox(height: 12),
        Card(child: ListTile(
          leading: const Icon(Icons.assignment_return_outlined),
          title: Text(claim.refundCompleted
              ? getTranslated('purchase_refund_completed', context)!
              : getTranslated('purchase_refund_scheduled', context)!),
          subtitle: Text('${getTranslated('purchase_refund_due_at', context)}: ${claim.purchaseRefundDueAt ?? '-'}'),
        )),
      ],
      const SizedBox(height: 12),
      if (claim.supportAvailable)
        OutlinedButton.icon(
          icon: const Icon(Icons.support_agent),
          label: Text(getTranslated('contact_admin_support', context)!),
          onPressed: () async {
            final ok = await controller.openSupport(orderId, getTranslated('insurance_support_default_message', context)!);
            if (ok) RouterHelper.getSupportTicketRoute(action: RouteAction.push);
            else if (context.mounted) _showResult(context, controller);
          },
        ),
      if (claim.canPay)
        TextButton(
          onPressed: () => _declineDialog(context, controller),
          child: Text(getTranslated('decline_insurance_and_request_purchase_refund', context)!),
        ),
      const SizedBox(height: 24),
    ]);
  }

  Future<void> _offlineDialog(BuildContext context, CustomerOrderInsuranceController controller) async {
    String methodId = envelope.paymentOptions.offlineMethods.first.id;
    XFile? proof;
    bool sending = false;
    String? error;
    final note = TextEditingController();
    await showDialog(context: context, builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(getTranslated('submit_offline_insurance_payment', context)!),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          DropdownButtonFormField<String>(
            value: methodId,
            items: envelope.paymentOptions.offlineMethods
                .map((item) => DropdownMenuItem(value: item.id, child: Text(item.title))).toList(),
            onChanged: sending ? null : (value) => setState(() => methodId = value ?? methodId),
          ),
          for (final field in envelope.paymentOptions.offlineMethods.firstWhere((method) => method.id == methodId).fields)
            Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: SelectableText('${field['input_name'] ?? ''}: ${field['input_data'] ?? ''}')),
          if (error != null) Text(error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          TextField(controller: note, decoration: InputDecoration(labelText: getTranslated('payment_note', context))),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: () async {
              proof = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
              if (dialogContext.mounted) setState(() {});
            },
            child: Text(proof?.name ?? getTranslated('select_payment_proof', context)!),
          ),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(getTranslated('cancel', context)!)),
          ElevatedButton(
            onPressed: proof == null || sending ? null : () async {
              setState(() { sending = true; error = null; });
              final ok = await controller.submitOffline(orderId, methodId, proof!.path, note.text);
              if (!dialogContext.mounted) return;
              if (ok) { Navigator.pop(dialogContext); } else { setState(() { sending = false; error = controller.error; }); }
            },
            child: Text(getTranslated('submit', context)!),
          ),
        ],
      ),
    ));
    note.dispose();
  }

  Future<void> _declineDialog(BuildContext context, CustomerOrderInsuranceController controller) async {
    final reason = TextEditingController();
    await showDialog(context: context, builder: (dialogContext) => AlertDialog(
      title: Text(getTranslated('decline_insurance_payment', context)!),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(getTranslated('decline_insurance_refund_notice', context)!),
        TextField(controller: reason, maxLines: 3, decoration: InputDecoration(labelText: getTranslated('reason', context))),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(getTranslated('cancel', context)!)),
        ElevatedButton(onPressed: () async {
          if (reason.text.trim().isEmpty) return;
          final ok = await controller.decline(orderId, reason.text.trim());
          if (ok && dialogContext.mounted) {
            Navigator.pop(dialogContext);
            RouterHelper.getSupportTicketRoute(action: RouteAction.push);
          }
        }, child: Text(getTranslated('confirm', context)!)),
      ],
    ));
  }

  Widget _actionButton(BuildContext context, {required IconData icon, required String label, required VoidCallback onPressed, bool enabled = true}) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: SizedBox(width: double.infinity, child: ElevatedButton.icon(
        onPressed: enabled ? onPressed : null,
        icon: Icon(icon),
        label: Text(label),
      )),
    );
  }

  Widget _row(BuildContext context, String title, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(child: Text(title)),
      const SizedBox(width: 10),
      Expanded(child: Text(value, textAlign: TextAlign.end, style: const TextStyle(fontWeight: FontWeight.w600))),
    ]),
  );

  String _statusLabel(BuildContext context, CustomerOrderInsuranceClaim claim) {
    final key = claim.refundCompleted
        ? 'purchase_refund_completed'
        : claim.refundScheduled
            ? 'purchase_refund_scheduled'
            : 'insurance_status_${claim.status}';
    return getTranslated(key, context) ?? claim.status;
  }

  void _showResult(BuildContext context, CustomerOrderInsuranceController controller) {
    if (controller.error != null) {
      showCustomSnackBarWidget(controller.error.toString(), context, snackBarType: SnackBarType.error);
    } else {
      showCustomSnackBarWidget(getTranslated('operation_completed_successfully', context), context, snackBarType: SnackBarType.success);
    }
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(child: Padding(
    padding: const EdgeInsets.all(24),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.error_outline, size: 42),
      const SizedBox(height: 12),
      Text(message, textAlign: TextAlign.center),
      const SizedBox(height: 12),
      ElevatedButton(onPressed: onRetry, child: Text(getTranslated('retry', context)!)),
    ]),
  ));
}
