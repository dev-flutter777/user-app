import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:flutter_sixvalley_ecommerce/di_container.dart' as di;
import 'package:flutter_sixvalley_ecommerce/data/datasource/remote/dio/dio_client.dart';
import 'package:flutter_sixvalley_ecommerce/features/splash/controllers/splash_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/wallet/screens/add_fund_to_wallet_screen.dart';
import 'package:flutter_sixvalley_ecommerce/helper/price_converter.dart';
import 'package:flutter_sixvalley_ecommerce/helper/route_healper.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/utill/app_constants.dart';

/// The same restricted balances and review queue used by the customer website.
class CustomerWalletScreen extends StatefulWidget {
  const CustomerWalletScreen({super.key});
  @override
  State<CustomerWalletScreen> createState() => _CustomerWalletScreenState();
}

class _CustomerWalletScreenState extends State<CustomerWalletScreen> {
  final DioClient api = di.sl<DioClient>();
  Map<String, dynamic>? data;
  String? error;
  int page = 1;
  String tr(String key) => getTranslated(key, context) ?? key;
  String money(dynamic value) =>
      PriceConverter.convertPrice(context, double.tryParse('$value') ?? 0);

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final response = await api.get('/api/v1/customer/wallet/overview',
          queryParameters: {'page': page});
      if (mounted)
        setState(() {
          data = Map<String, dynamic>.from(response.data);
          error = null;
        });
    } catch (_) {
      if (mounted) setState(() => error = tr('wallet_load_failed'));
    }
  }

  Widget card(Widget child) => Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(padding: const EdgeInsets.all(16), child: child));

  Future<void> deposit(String wallet) async {
    await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => CustomerDepositScreen(wallet: wallet, config: data!)));
    await load();
  }

  Widget balance(String key, dynamic amount, IconData icon, String wallet) =>
      card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, color: Theme.of(context).primaryColor),
          const SizedBox(width: 8),
          Expanded(
              child:
                  Text(tr(key), style: Theme.of(context).textTheme.titleMedium))
        ]),
        Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(money(amount),
                style: Theme.of(context).textTheme.headlineSmall)),
        Text(tr('${wallet}_wallet_only_notice')),
        if ((wallet != 'purchase' || data!['purchase_enabled'] == true) &&
            ((data!['offline_methods'] as List).isNotEmpty ||
                (data!['digital_methods'] as List).isNotEmpty))
          TextButton.icon(
              onPressed: () => deposit(wallet),
              icon: const Icon(Icons.add_circle_outline),
              label: Text(tr('wallet_make_deposit'))),
      ]));

  @override
  Widget build(BuildContext context) {
    final insurance = data?['insurance'] as Map? ?? {};
    return Scaffold(
        appBar: AppBar(title: Text(tr('wallet_my_wallet'))),
        body: RefreshIndicator(
            onRefresh: load,
            child: data == null
                ? ListView(children: [
                    const SizedBox(height: 80),
                    Center(
                        child: error == null
                            ? const CircularProgressIndicator()
                            : TextButton(onPressed: load, child: Text(error!)))
                  ])
                : ListView(padding: const EdgeInsets.all(16), children: [
                    if (error != null) Text(error!),
                    balance('purchase_wallet', data!['purchase_balance'],
                        Icons.shopping_bag_outlined, 'purchase'),
                    balance('insurance_wallet', insurance['available_balance'],
                        Icons.shield_outlined, 'insurance'),
                    card(Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              '${tr('insurance_held_balance')}: ${money(insurance['held_balance'])}'),
                          if (insurance['next_maturity_at'] != null)
                            Text(
                                '${tr('next_insurance_maturity')}: ${insurance['next_maturity_at']}'),
                          const SizedBox(height: 8),
                          Text(tr('wallet_reuse_notice')),
                        ])),
                    Text(tr('wallet_deposit_history'),
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 12),
                    for (final item in data!['deposits']['data'] as List)
                      card(ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(item['wallet_type'] == 'insurance'
                              ? Icons.shield_outlined
                              : Icons.shopping_bag_outlined),
                          title: Text(
                              '${money(item['amount'])} · ${tr('wallet_status_${item['status']}')}'),
                          subtitle: Text(
                              '${item['method_name']}\n${item['created_at']}${item['review_note'] == null ? '' : '\n${item['review_note']}'}'))),
                    if ((data!['deposits']['data'] as List).isEmpty)
                      Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(tr('wallet_no_records'))),
                    Text(tr('wallet_order_history'),
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 12),
                    for (final item in data!['orders']['data'] as List)
                      card(ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.receipt_long_outlined),
                          title:
                              Text('#${item['id']} · ${money(item['amount'])}'),
                          subtitle: Text(
                              '${tr('insurance_wallet')}: ${money(item['insurance']?['amount'])}\n${tr('next_insurance_maturity')}: ${item['insurance']?['matures_at'] ?? tr('wallet_not_scheduled')}'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => RouterHelper.getOrderDetailsScreenRoute(
                              orderId: item['id'],
                              action: RouteAction.push,
                              isNotification: true))),
                    Text(tr('wallet_history'),
                        style: Theme.of(context).textTheme.titleLarge),
                    for (final item
                        in data!['purchase_entries']['data'] as List)
                      card(ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                              '${tr('wallet_credit')}: ${money(item['credit'])} · ${tr('wallet_debit')}: ${money(item['debit'])}'),
                          subtitle: Text(
                              '${tr('purchase_wallet')}: ${money(item['balance'])} · ${item['created_at']}'))),
                    Text(tr('wallet_insurance_history'),
                        style: Theme.of(context).textTheme.titleLarge),
                    for (final item in data!['insurance_entries'] as List)
                      card(ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                              '${tr('wallet_credit')}: ${money(item['credit'])} · ${tr('wallet_debit')}: ${money(item['debit'])}'),
                          subtitle: Text(
                              '${item['order_id'] == null ? '' : '#${item['order_id']} · '}${item['created_at']}'))),
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                              onPressed: page > 1
                                  ? () {
                                      setState(() {
                                        page--;
                                      });
                                      load();
                                    }
                                  : null,
                              child: Text(tr('wallet_previous'))),
                          Text('$page'),
                          TextButton(
                              onPressed:
                                  (data!['orders']['next_page_url'] != null ||
                                          data!['deposits']['next_page_url'] !=
                                              null ||
                                          data!['purchase_entries']
                                                  ['next_page_url'] !=
                                              null)
                                      ? () {
                                          setState(() {
                                            page++;
                                          });
                                          load();
                                        }
                                      : null,
                              child: Text(tr('wallet_next'))),
                        ]),
                  ])));
  }
}

class CustomerDepositScreen extends StatefulWidget {
  final String wallet;
  final Map<String, dynamic> config;
  const CustomerDepositScreen(
      {super.key, required this.wallet, required this.config});
  @override
  State<CustomerDepositScreen> createState() => _CustomerDepositScreenState();
}

class _CustomerDepositScreenState extends State<CustomerDepositScreen> {
  final form = GlobalKey<FormState>();
  final amount = TextEditingController();
  final reference = TextEditingController();
  final note = TextEditingController();
  final Map<String, String> information = {};
  final String requestKey = _uuid();
  String? method;
  XFile? proof;
  bool busy = false;
  String? error;
  String tr(String key) => getTranslated(key, context) ?? key;
  static String _uuid() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 15) | 64;
    bytes[8] = (bytes[8] & 63) | 128;
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }

  Map? get offline {
    for (final item in widget.config['offline_methods'] as List) {
      if (method == 'offline:${item['id']}') return item as Map;
    }
    return null;
  }

  @override
  void dispose() {
    amount.dispose();
    reference.dispose();
    note.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (busy || !form.currentState!.validate()) return;
    if (offline != null && proof == null) {
      setState(() => error = tr('wallet_proof_required'));
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final api = di.sl<DioClient>();
      final currency = context.read<SplashController>().myCurrency!.code;
      if (offline != null) {
        final bytes = await proof!.readAsBytes();
        if (bytes.length > 5 * 1024 * 1024) throw StateError('proof_size');
        await api.post('/api/v1/customer/wallet/deposits',
            data: FormData.fromMap({
              'wallet_type': widget.wallet,
              'amount': amount.text.trim(),
              'currency_code': currency,
              'method_id': offline!['id'],
              'request_key': requestKey,
              'payment_reference': reference.text.trim(),
              'payment_note': note.text.trim(),
              for (final entry in information.entries)
                'method_information[${entry.key}]': entry.value,
              'payment_proof':
                  MultipartFile.fromBytes(bytes, filename: proof!.name),
            }));
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(tr('wallet_deposit_pending'))));
        Navigator.of(context).pop();
      } else {
        final response = await api.post(AppConstants.addFundToWallet, data: {
          'wallet_type': widget.wallet,
          'amount': amount.text.trim(),
          'current_currency_code': currency,
          'payment_method': method!.substring(8),
          'payment_platform': 'app',
          'payment_request_from': 'app',
        });
        if (!mounted) return;
        final url = response.data['redirect_link'];
        if (url is! String || Uri.tryParse(url)?.hasAbsolutePath != true)
          throw StateError('payment_url');
        await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => AddFundToWalletScreen(url: url)));
        if (mounted) Navigator.of(context).pop();
      }
    } catch (exception) {
      if (mounted)
        setState(() {
          final response =
              exception is DioException ? exception.response?.data : null;
          error = response is Map && response['message'] is String
              ? response['message']
              : tr('wallet_deposit_failed');
        });
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: Text(tr('wallet_make_deposit'))),
      body: Form(
          key: form,
          child: ListView(padding: const EdgeInsets.all(20), children: [
            Text(tr('${widget.wallet}_wallet'),
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            Text(tr('${widget.wallet}_wallet_only_notice')),
            const SizedBox(height: 20),
            TextFormField(
                controller: amount,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration:
                    InputDecoration(labelText: tr('wallet_deposit_amount')),
                validator: (value) {
                  final number = double.tryParse(value ?? '');
                  return number != null && number.isFinite && number > 0
                      ? null
                      : tr('wallet_invalid_amount');
                }),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
                initialValue: method,
                isExpanded: true,
                decoration: InputDecoration(labelText: tr('payment_method')),
                items: [
                  for (final item in widget.config['offline_methods'] as List)
                    DropdownMenuItem(
                        value: 'offline:${item['id']}',
                        child: Text('${item['method_name']}')),
                  for (final item in widget.config['digital_methods'] as List)
                    DropdownMenuItem(
                        value: 'digital:${item['key']}',
                        child: Text('${item['key']}'))
                ],
                onChanged: busy
                    ? null
                    : (value) => setState(() {
                          method = value;
                          information.clear();
                        }),
                validator: (value) =>
                    value == null ? tr('select_payment_method') : null),
            if (offline != null) ...[
              const SizedBox(height: 16),
              for (final field in offline!['method_fields'] as List? ?? [])
                Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: SelectableText(
                        '${field['input_name'] ?? ''}: ${field['input_data'] ?? ''}')),
              TextFormField(
                  controller: reference,
                  decoration: InputDecoration(
                      labelText: tr('wallet_payment_reference')),
                  validator: (value) =>
                      (value?.trim().isEmpty ?? true) ? tr('required') : null),
              for (final field
                  in offline!['method_informations'] as List? ?? [])
                if (field['customer_input'] != null &&
                    field['customer_input'] != 'payment_screenshot')
                  TextFormField(
                      key: ValueKey('$method:${field['customer_input']}'),
                      decoration: InputDecoration(
                          labelText: '${field['customer_input']}'),
                      onChanged: (value) =>
                          information['${field['customer_input']}'] = value,
                      validator: (value) => (field['is_required'] == 1 ||
                                  field['is_required'] == true ||
                                  field['is_required'] == '1') &&
                              (value?.trim().isEmpty ?? true)
                          ? tr('required')
                          : null),
              TextFormField(
                  controller: note,
                  maxLines: 3,
                  decoration:
                      InputDecoration(labelText: tr('wallet_deposit_note'))),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                  onPressed: busy
                      ? null
                      : () async {
                          final selected = await ImagePicker()
                              .pickImage(source: ImageSource.gallery);
                          if (mounted && selected != null)
                            setState(() => proof = selected);
                        },
                  icon: const Icon(Icons.upload_file_outlined),
                  label: Text(proof?.name ?? tr('wallet_upload_proof'))),
              Text(tr('wallet_deposit_review_notice')),
            ],
            if (error != null)
              Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(error!,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.error))),
            const SizedBox(height: 24),
            FilledButton(
                onPressed: busy ? null : submit,
                child: busy
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(tr('proceed'))),
          ])));
}
