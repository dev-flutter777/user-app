class ActivationInvoiceModel {
  int? id;
  String? invoiceNo;
  double? totalAmount;
  String? paymentStatus;
  String? status;
  PackageInfo? package;
  InsuranceInfo? insurance;

  ActivationInvoiceModel({
    this.id,
    this.invoiceNo,
    this.totalAmount,
    this.paymentStatus,
    this.status,
    this.package,
    this.insurance,
  });

  ActivationInvoiceModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    invoiceNo = json['invoice_no'];
    totalAmount = double.tryParse(json['total_amount'].toString());
    paymentStatus = json['payment_status'];
    status = json['status'];
    package = json['package'] != null ? PackageInfo.fromJson(json['package']) : null;
    insurance = json['insurance'] != null ? InsuranceInfo.fromJson(json['insurance']) : null;
  }
}

class PackageInfo {
  int? id;
  String? name;
  double? price;
  double? purchaseLimit;

  PackageInfo({this.id, this.name, this.price, this.purchaseLimit});

  PackageInfo.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    price = double.tryParse(json['price'].toString());
    purchaseLimit = double.tryParse(json['purchase_limit'].toString());
  }
}

class InsuranceInfo {
  double? amount;

  InsuranceInfo({this.amount});

  InsuranceInfo.fromJson(Map<String, dynamic> json) {
    amount = double.tryParse(json['amount'].toString());
  }
}