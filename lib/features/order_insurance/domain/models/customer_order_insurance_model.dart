class CustomerOrderInsuranceEnvelope {
  final CustomerOrderInsuranceClaim claim;
  final CustomerInsuranceBalance balance;
  final CustomerInsurancePaymentOptions paymentOptions;

  const CustomerOrderInsuranceEnvelope({
    required this.claim,
    required this.balance,
    required this.paymentOptions,
  });

  factory CustomerOrderInsuranceEnvelope.fromJson(Map<String, dynamic> json) {
    return CustomerOrderInsuranceEnvelope(
      claim: CustomerOrderInsuranceClaim.fromJson(
        Map<String, dynamic>.from(json['claim'] as Map? ?? const {}),
      ),
      balance: CustomerInsuranceBalance.fromJson(
        Map<String, dynamic>.from(json['insurance_balance'] as Map? ?? const {}),
      ),
      paymentOptions: CustomerInsurancePaymentOptions.fromJson(
        Map<String, dynamic>.from(json['payment_options'] as Map? ?? const {}),
      ),
    );
  }
}

class CustomerOrderInsuranceClaim {
  final String contractVersion;
  final String flowStatus;
  final String orderReference;
  final double purchaseAmount;
  final double taxAmount;
  final double insuranceAmount;
  final double externalAmountDue;
  final String paymentStatus;
  final String status;
  final String? paymentDueAt;
  final String balanceUsePolicy;
  final bool suspended;
  final bool supportAvailable;
  final String purchaseRefundStatus;
  final String? purchaseRefundDueAt;

  const CustomerOrderInsuranceClaim({
    required this.contractVersion,
    required this.flowStatus,
    required this.orderReference,
    required this.purchaseAmount,
    required this.taxAmount,
    required this.insuranceAmount,
    required this.externalAmountDue,
    required this.paymentStatus,
    required this.status,
    this.paymentDueAt,
    required this.balanceUsePolicy,
    required this.suspended,
    required this.supportAvailable,
    required this.purchaseRefundStatus,
    this.purchaseRefundDueAt,
  });

  bool get canPay => paymentStatus != 'paid' && status == 'pending_payment';
  bool get isUnderReview => status == 'pending_review';
  bool get refundScheduled => purchaseRefundStatus == 'scheduled';
  bool get refundCompleted => purchaseRefundStatus == 'completed';

  factory CustomerOrderInsuranceClaim.fromJson(Map<String, dynamic> json) {
    final insurance = Map<String, dynamic>.from(json['insurance'] as Map? ?? const {});
    final tax = Map<String, dynamic>.from(json['tax'] as Map? ?? const {});
    final refund = Map<String, dynamic>.from(json['purchase_refund'] as Map? ?? const {});
    return CustomerOrderInsuranceClaim(
      contractVersion: json['contract_version']?.toString() ?? '',
      flowStatus: json['flow_status']?.toString() ?? '',
      orderReference: json['order_reference']?.toString() ?? '',
      purchaseAmount: _money(json['purchase_amount']),
      taxAmount: _money(tax['amount']),
      insuranceAmount: _money(insurance['amount']),
      externalAmountDue: _money(json['external_amount_due']),
      paymentStatus: insurance['payment_status']?.toString() ?? 'unpaid',
      status: insurance['status']?.toString() ?? 'pending_payment',
      paymentDueAt: insurance['payment_due_at']?.toString(),
      balanceUsePolicy: insurance['balance_use_policy']?.toString() ?? 'insurance_only',
      suspended: json['order_is_suspended_until_insurance_payment'] == true,
      supportAvailable: json['support_available'] == true,
      purchaseRefundStatus: refund['status']?.toString() ?? 'not_requested',
      purchaseRefundDueAt: refund['due_at']?.toString(),
    );
  }
}

class CustomerInsuranceBalance {
  final double availableBalance;
  final double heldBalance;
  final String? nextMaturityAt;
  final bool withdrawable;
  final List<String> allowedUses;

  const CustomerInsuranceBalance({
    required this.availableBalance,
    required this.heldBalance,
    this.nextMaturityAt,
    required this.withdrawable,
    required this.allowedUses,
  });

  factory CustomerInsuranceBalance.fromJson(Map<String, dynamic> json) {
    return CustomerInsuranceBalance(
      availableBalance: _money(json['available_balance']),
      heldBalance: _money(json['held_balance']),
      nextMaturityAt: json['next_maturity_at']?.toString(),
      withdrawable: json['withdrawable'] == true,
      allowedUses: (json['allowed_uses'] as List? ?? const [])
          .map((item) => item.toString()).toList(growable: false),
    );
  }
}

class CustomerInsurancePaymentOptions {
  final bool insuranceBalance;
  final bool digitalPayment;
  final bool offlinePayment;
  final List<CustomerInsurancePaymentMethod> digitalGateways;
  final List<CustomerInsurancePaymentMethod> offlineMethods;

  const CustomerInsurancePaymentOptions({
    required this.insuranceBalance,
    required this.digitalPayment,
    required this.offlinePayment,
    required this.digitalGateways,
    required this.offlineMethods,
  });

  factory CustomerInsurancePaymentOptions.fromJson(Map<String, dynamic> json) {
    List<CustomerInsurancePaymentMethod> methods(dynamic value, String idKey, String titleKey) {
      return (value as List? ?? const []).whereType<Map>().map((item) {
        final data = Map<String, dynamic>.from(item);
        return CustomerInsurancePaymentMethod(
          id: data[idKey]?.toString() ?? '',
          title: data[titleKey]?.toString() ?? '',
          fields: (data['method_fields'] as List? ?? const []).whereType<Map>().map((field) => Map<String, dynamic>.from(field)).toList(),
        );
      }).where((item) => item.id.isNotEmpty).toList(growable: false);
    }

    return CustomerInsurancePaymentOptions(
      insuranceBalance: json['insurance_balance'] == true,
      digitalPayment: json['digital_payment'] == true,
      offlinePayment: json['offline_payment'] == true,
      digitalGateways: methods(json['gateways'], 'key', 'title'),
      offlineMethods: methods(json['offline_methods'], 'id', 'method_name'),
    );
  }
}

class CustomerInsurancePaymentMethod {
  final String id;
  final String title;
  final List<Map<String, dynamic>> fields;
  const CustomerInsurancePaymentMethod({required this.id, required this.title, this.fields = const []});
}

double _money(dynamic value) => double.tryParse(value?.toString() ?? '') ?? 0;
