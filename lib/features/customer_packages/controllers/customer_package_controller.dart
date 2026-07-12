import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// ==================== 1. MODELS ====================

class CustomerPackageModel {
  int? id;
  String? name;
  double? price;
  int? durationInDays;
  String? description;
  int? orderLimit;
  List<String>? advantages;

  CustomerPackageModel({
    this.id,
    this.name,
    this.price,
    this.durationInDays,
    this.description,
    this.orderLimit,
    this.advantages,
  });

  CustomerPackageModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    price = double.tryParse(json['price'].toString());
    durationInDays = json['duration_in_days'];
    description = json['description'];
    orderLimit = json['order_limit'];
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
  String? message; // ✅ تم إضافة حقل الـ message هنا لحل مشكلة الـ Getter الخاطئ في شاشة الباقات
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
    totalAmount = double.tryParse(json['total_amount'].toString());
    paymentStatus = json['payment_status'];
    status = json['status'];
    message = json['message'] ?? json['status_message']; // ✅ جلب الرسالة القادمة من السيرفر
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


// ==================== 2. CONTROLLER ====================

// ✅ الكلاس يرث ChangeNotifier ومجهّز بالكامل ليعمل كـ Type Argument في الـ Provider بدون أخطاء
class CustomerPackageController extends ChangeNotifier {
  // اكتب هنا الدومين بتاع موقعك الأساسي
  final String baseUrl = "https://yourdomain.com"; 

  List<CustomerPackageModel> packageList = [];
  ActivationInvoiceModel? currentInvoice;
  bool isLoading = false;

  Map<String, String> _getHeaders(String token) {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // 1. جلب الباقات الحقيقية من الأدمن بانل
  Future<void> getPackageList(String token) async {
    isLoading = true;
    notifyListeners();
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/customer/purchase-packages'),
        headers: _getHeaders(token),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['packages'] != null) {
          packageList = [];
          for (var package in data['packages']) {
            packageList.add(CustomerPackageModel.fromJson(package));
          }
        }
      }
    } catch (e) {
      debugPrint("Error fetching packages: $e");
    }
    isLoading = false;
    notifyListeners();
  }

  // 2. خطوة حجز الباقة وتوليد فاتورة التنشيط بالتأمين في السيرفر
  Future<bool> initiatePurchase(int packageId, String token) async {
    isLoading = true;
    notifyListeners();
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/customer/purchase-packages/purchase'),
        headers: _getHeaders(token),
        body: jsonEncode({
          'package_id': packageId,
          'payment_method': 'offline_payment',
          'payment_platform': 'app',
        }),
      );
      isLoading = false;
      notifyListeners();
      return response.statusCode == 200;
    } catch (e) {
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // 3. جلب فاتورة التنشيط الحالية المدمج بها التأمين المعرف في الأدمن
  Future<void> getCurrentActivationInvoice(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/customer/purchase-packages/current'),
        headers: _getHeaders(token),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['invoice'] != null) {
          currentInvoice = ActivationInvoiceModel.fromJson(data['invoice']);
        } else {
          currentInvoice = null;
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint("Error fetching invoice: $e");
    }
  }

  // 4. إرسال الدفع الأوفلاين النصي المشفر base64 لتسمع في الأدمن بانل كـ pending_offline_review
  Future<bool> submitOfflinePayment({
    required int invoiceId,
    required int methodId,
    required String walletInfo,
    required String token,
    String? note,
  }) async {
    isLoading = true;
    notifyListeners();

    String encodedInfo = base64Encode(utf8.encode(walletInfo));

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/customer/purchase-packages/pay-by-offline-payment'),
        headers: _getHeaders(token),
        body: jsonEncode({
          'activation_invoice_id': invoiceId,
          'method_id': methodId,
          'method_informations': encodedInfo,
          'payment_note': note ?? 'طلب تفعيل باقة وتأمين حساب أوفلاين',
        }),
      );
      
      isLoading = false;
      notifyListeners();
      return response.statusCode == 200;
    } catch (e) {
      isLoading = false;
      notifyListeners();
      return false;
    }
  }
}