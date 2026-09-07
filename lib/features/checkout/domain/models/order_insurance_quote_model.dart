class OrderInsuranceQuoteModel {
  final bool applicable;
  final bool postPurchaseEnabled;
  final double? firstPaymentAmount;
  final double total;
  final double originalTotal;
  final double discountTotal;
  final int maturityDays;
  final bool withdrawable;
  final bool cashOnDeliveryAllowed;
  final double insuranceAvailableBalance;
  final String? notice;

  const OrderInsuranceQuoteModel(
      {this.postPurchaseEnabled = false,
      this.firstPaymentAmount,
      required this.applicable,
      required this.total,
      required this.originalTotal,
      required this.discountTotal,
      required this.maturityDays,
      required this.withdrawable,
      required this.cashOnDeliveryAllowed,
      required this.insuranceAvailableBalance,
      this.notice});

  factory OrderInsuranceQuoteModel.fromJson(Map<String, dynamic> json) =>
      OrderInsuranceQuoteModel(
        postPurchaseEnabled: json['post_purchase_enabled'] == true,
        firstPaymentAmount: double.tryParse('${json['first_payment_amount']}'),
        applicable: json['applicable'] == true,
        total: double.tryParse('${json['total'] ?? 0}') ?? 0,
        originalTotal: double.tryParse('${json['original_total'] ?? 0}') ?? 0,
        discountTotal: double.tryParse('${json['discount_total'] ?? 0}') ?? 0,
        maturityDays: int.tryParse('${json['maturity_days'] ?? 90}') ?? 90,
        withdrawable: json['withdrawable'] == true,
        cashOnDeliveryAllowed: json['cash_on_delivery_allowed'] != false,
        insuranceAvailableBalance:
            double.tryParse('${json['balance']?['available_balance'] ?? 0}') ??
                0,
        notice: json['notice']?.toString(),
      );
}
