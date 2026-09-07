import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_sixvalley_ecommerce/features/checkout/domain/models/order_insurance_quote_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/order/domain/models/order_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/profile/domain/models/profile_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/order_insurance/domain/models/customer_order_insurance_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/wallet/domain/models/wallet_transaction_model.dart';
import 'package:flutter_sixvalley_ecommerce/helper/egypt_location_helper.dart';
import 'package:flutter_sixvalley_ecommerce/utill/app_constants.dart';

void main() {
  test('Arabic includes every English translation key', () {
    final english =
        jsonDecode(File('assets/language/en.json').readAsStringSync()) as Map;
    final arabic =
        jsonDecode(File('assets/language/ar.json').readAsStringSync()) as Map;
    expect(
        english.keys.where((key) =>
            !arabic.containsKey(key) || '${arabic[key]}'.trim().isEmpty),
        isEmpty);
  });

  test('first payment preserves server total without adding second stage tax',
      () {
    final quote = OrderInsuranceQuoteModel.fromJson({
      'post_purchase_enabled': true,
      'first_payment_amount': '110.50',
      'total': '40',
    });
    expect(quote.postPurchaseEnabled, isTrue);
    expect(quote.firstPaymentAmount, 110.50);
    expect(quote.total, 40);
  });
  test('mobile environment and Egypt-only location contract are valid', () {
    expect(AppConstants.baseUrl, isNotEmpty);
    expect(
        EgyptLocationHelper.contains(const LatLng(30.0444, 31.2357)), isTrue);
    expect(
        EgyptLocationHelper.contains(const LatLng(25.2048, 55.2708)), isFalse);
  });

  test('profile parses customer activation support state', () {
    final profile = ProfileModel.fromJson({
      'id': 10,
      'wallet_balance': 0,
      'loyalty_point': 0,
      'activation': {
        'customer_reference': 'C10',
        'status': 'activation_ticket_open',
        'is_active': false,
        'ticket_id': 7,
      },
    });

    expect(profile.activation?.customerReference, 'C10');
    expect(profile.activation?.isActive, isFalse);
    expect(profile.activation?.ticketId, 7);
  });

  test('insurance quote and shipping confirmation fields use API snapshots',
      () {
    final quote = OrderInsuranceQuoteModel.fromJson({
      'applicable': true,
      'total': '50',
      'original_total': '60',
      'discount_total': '10',
      'maturity_days': 90,
      'withdrawable': false,
      'balance': {'available_balance': '25'},
    });
    final order = Orders.fromJson({
      'id': 44,
      'order_amount': 1000,
      'discount_amount': 0,
      'shipping_cost': 50,
      'extra_discount': 0,
      'shipment_reference': 'SHP-44',
      'customer_delivery_confirmation_status': 'pending',
    });

    expect(quote.total, 50);
    expect(quote.withdrawable, isFalse);
    expect(order.shipmentReference, 'SHP-44');
    expect(order.customerDeliveryConfirmationStatus, 'pending');
    expect(AppConstants.confirmOrderReceiptUri, contains('confirm-receipt'));
  });

  test(
      'post-purchase insurance contract keeps purchase and insurance wallets separate',
      () {
    final envelope = CustomerOrderInsuranceEnvelope.fromJson({
      'claim': {
        'contract_version': '2.0',
        'flow_status': 'customer_insurance_pending',
        'order_reference': 'ORD-44',
        'purchase_amount': '1000',
        'insurance': {
          'amount': '75',
          'payment_status': 'unpaid',
          'status': 'pending_payment',
          'balance_use_policy': 'insurance_only',
        },
        'order_is_suspended_until_insurance_payment': true,
        'support_available': true,
        'purchase_refund': {'status': 'not_requested'},
      },
      'insurance_balance': {
        'available_balance': '50',
        'held_balance': '25',
        'withdrawable': false,
        'allowed_uses': ['insurance_payment'],
      },
      'payment_options': {
        'insurance_balance': true,
        'digital_payment': true,
        'offline_payment': true,
        'gateways': [
          {'key': 'paymob', 'title': 'Paymob'}
        ],
        'offline_methods': [
          {'id': 2, 'method_name': 'Bank'}
        ],
      },
    });
    final wallet = WalletTransactionModel.fromJson({
      'limit': 10,
      'offset': 1,
      'total_size': 0,
      'total_wallet_balance': '300',
      'insurance_available_balance': '50',
      'insurance_held_balance': '25',
      'insurance_ledger_entries': [
        {
          'id': 1,
          'order_id': 44,
          'entry_type': 'hold',
          'credit': 0,
          'debit': 75
        },
      ],
      'wallet_transaction_list': [],
    });

    expect(envelope.claim.canPay, isTrue);
    expect(envelope.claim.suspended, isTrue);
    expect(envelope.claim.balanceUsePolicy, 'insurance_only');
    expect(envelope.balance.allowedUses, ['insurance_payment']);
    expect(wallet.totalWalletBalance, 300);
    expect(wallet.insuranceAvailableBalance, 50);
    expect(wallet.insuranceLedgerEntries?.single.orderId, 44);
  });
}
