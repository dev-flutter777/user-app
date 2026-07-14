class CustomerPackageModel {
  int? id;
  String? name;
  double? price;
  int? durationInDays;
  String? description;
  double? purchaseLimit; // تم تغييرها إلى purchaseLimit لتتوافق مع السيرفر وقاعدة البيانات
  List<String>? advantages;

  CustomerPackageModel({
    this.id,
    this.name,
    this.price,
    this.durationInDays,
    this.description,
    this.purchaseLimit,
    this.advantages,
  });

  CustomerPackageModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    price = double.tryParse(json['package_price']?.toString() ?? json['price']?.toString() ?? '0');
    durationInDays = json['duration_in_days'];
    description = json['description'];
    purchaseLimit = double.tryParse(json['purchase_limit']?.toString() ?? '0');
    if (json['advantages'] != null) {
      advantages = List<String>.from(json['advantages']);
    }
  }
}

class ActivationInvoiceModel {
  int? id;
  String? invoiceNo;
  double? totalAmount;
  String? paymentStatus;
  String? status;
  String? message; 
  PackageInfo? package;
  InsuranceInfo? insurance;

  ActivationInvoiceModel({
    this.id,
    this.invoiceNo,
    this.totalAmount,
    this.paymentStatus,
    this.status,
    this.message,
    this.package,
    this.insurance,
  });

  ActivationInvoiceModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    invoiceNo = json['invoice_no'];
    totalAmount = double.tryParse(json['total_amount']?.toString() ?? '0');
    paymentStatus = json['payment_status'];
    status = json['status'];
    message = json['message'] ?? json['status_message']; 
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
    name = json['package_name'] ?? json['name'];
    price = double.tryParse(json['package_price']?.toString() ?? json['price']?.toString() ?? '0');
    purchaseLimit = double.tryParse(json['package_purchase_limit']?.toString() ?? json['purchase_limit']?.toString() ?? '0');
  }
}

class InsuranceInfo {
  double? amount;

  InsuranceInfo({this.amount});

  InsuranceInfo.fromJson(Map<String, dynamic> json) {
    amount = double.tryParse(json['insurance_amount']?.toString() ?? json['amount']?.toString() ?? '0');
  }
}