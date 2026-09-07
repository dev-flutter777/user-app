import 'package:dio/dio.dart';
import 'package:flutter_sixvalley_ecommerce/data/datasource/remote/dio/dio_client.dart';
import 'package:flutter_sixvalley_ecommerce/data/datasource/remote/exception/api_error_handler.dart';
import 'package:flutter_sixvalley_ecommerce/data/model/api_response.dart';
import 'package:flutter_sixvalley_ecommerce/utill/app_constants.dart';

class CustomerOrderInsuranceRepository {
  final DioClient dioClient;
  const CustomerOrderInsuranceRepository({required this.dioClient});

  Future<ApiResponseModel> getClaim(int orderId) => _guard(
    () => dioClient.get(AppConstants.customerOrderInsuranceUri(orderId)),
  );

  Future<ApiResponseModel> pay(int orderId, String paymentMethod) => _guard(
    () => dioClient.post(
      AppConstants.customerOrderInsurancePayUri(orderId),
      data: {'payment_method': paymentMethod},
    ),
  );

  Future<ApiResponseModel> submitOffline({
    required int orderId,
    required String methodId,
    required String proofPath,
    String? note,
  }) async {
    return _guard(() async {
      final data = FormData.fromMap({
        'method_id': methodId,
        'payment_note': note ?? '',
        'payment_proof': await MultipartFile.fromFile(proofPath),
      });
      return dioClient.post(AppConstants.customerOrderInsuranceOfflineUri(orderId), data: data);
    });
  }

  Future<ApiResponseModel> openSupport(int orderId, String message) => _guard(
    () => dioClient.post(
      AppConstants.customerOrderInsuranceSupportUri(orderId),
      data: {'message': message},
    ),
  );

  Future<ApiResponseModel> decline(int orderId, String reason) => _guard(
    () => dioClient.post(
      AppConstants.customerOrderInsuranceDeclineUri(orderId),
      data: {'reason': reason},
    ),
  );

  Future<ApiResponseModel> _guard(Future<Response> Function() operation) async {
    try {
      return ApiResponseModel.withSuccess(await operation());
    } catch (error) {
      return ApiResponseModel.withError(ApiErrorHandler.getMessage(error));
    }
  }
}
