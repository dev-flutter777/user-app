import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_sixvalley_ecommerce/utill/app_constants.dart';
import 'package:flutter_sixvalley_ecommerce/features/customer_packages/model/customer_package_model.dart'; 


class CustomerPackageController extends ChangeNotifier {
  List<CustomerPackageModel> packageList = [];
  ActivationInvoiceModel? currentInvoice;
  bool isLoading = false;

  Map<String, String> _getHeaders(String token) {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    };
  }

  // 1. جلب الباقات الحقيقية المتاحة للشراء
  Future<void> getPackageList(String token) async {
    isLoading = true;
    notifyListeners();
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/api/v1/customer/purchase-packages'),
        headers: _getHeaders(token),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['packages'] != null) {
          packageList = (data['packages'] as List)
              .map((p) => CustomerPackageModel.fromJson(p))
              .toList();
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
        Uri.parse('${AppConstants.baseUrl}/api/v1/customer/purchase-packages/purchase'),
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

  // 3. جلب فاتورة التنشيط الحالية المدمج بها التأمين والمعلومات المحدثة
  Future<void> getCurrentActivationInvoice(String token) async {
    isLoading = true;
    notifyListeners();
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/api/v1/customer/activation-invoice/current'),
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
    } catch (e) {
      debugPrint("Error fetching invoice: $e");
    }
    isLoading = false;
    notifyListeners();
  }

  // 4. إرسال الدفع الأوفلاين المشفر base64 لتبدأ الإدارة في مراجعته يدوياً
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
        Uri.parse('${AppConstants.baseUrl}/api/v1/customer/activation-invoice/pay-by-offline-payment'),
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