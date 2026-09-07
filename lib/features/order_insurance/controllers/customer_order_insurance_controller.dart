import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/data/model/api_response.dart';
import 'package:flutter_sixvalley_ecommerce/features/order_insurance/domain/models/customer_order_insurance_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/order_insurance/domain/repositories/customer_order_insurance_repository.dart';

class CustomerOrderInsuranceController extends ChangeNotifier {
  final CustomerOrderInsuranceRepository repository;
  CustomerOrderInsuranceController({required this.repository});

  CustomerOrderInsuranceEnvelope? _envelope;
  CustomerOrderInsuranceEnvelope? get envelope => _envelope;
  bool _loading = false;
  bool get loading => _loading;
  String? _error;
  String? get error => _error;

  Future<bool> load(int orderId) async {
    _envelope = null;
    _setLoading(true);
    final response = await repository.getClaim(orderId);
    if (_ok(response)) {
      _envelope = CustomerOrderInsuranceEnvelope.fromJson(
        Map<String, dynamic>.from(response.response!.data as Map),
      );
      _error = null;
    } else {
      _error = response.error?.toString();
    }
    _setLoading(false);
    return _envelope != null;
  }

  Future<String?> pay(int orderId, String method) async {
    _setLoading(true);
    final response = await repository.pay(orderId, method);
    String? redirect;
    if (_ok(response)) {
      final data = Map<String, dynamic>.from(response.response!.data as Map);
      redirect = data['redirect_link']?.toString();
      if (data['claim'] is Map) {
        await load(orderId);
        return redirect;
      }
      _error = null;
    } else {
      _error = response.error?.toString();
    }
    _setLoading(false);
    return redirect;
  }

  Future<bool> submitOffline(int orderId, String methodId, String proofPath, String note) async {
    _setLoading(true);
    final response = await repository.submitOffline(
      orderId: orderId, methodId: methodId, proofPath: proofPath, note: note,
    );
    final success = _ok(response);
    if (success) await load(orderId); else _error = response.error?.toString();
    _setLoading(false);
    return success;
  }

  Future<bool> openSupport(int orderId, String message) async {
    _setLoading(true);
    final response = await repository.openSupport(orderId, message);
    final success = _ok(response);
    _error = success ? null : response.error?.toString();
    _setLoading(false);
    return success;
  }

  Future<bool> decline(int orderId, String reason) async {
    _setLoading(true);
    final response = await repository.decline(orderId, reason);
    final success = _ok(response);
    if (success) await load(orderId); else _error = response.error?.toString();
    _setLoading(false);
    return success;
  }

  bool _ok(ApiResponseModel response) =>
      response.response?.statusCode == 200 && response.response?.data is Map;

  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }
}
