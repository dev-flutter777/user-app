import 'package:flutter_sixvalley_ecommerce/data/model/api_response.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/controllers/auth_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/cart/domain/models/cart_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/checkout/domain/services/checkout_service_interface.dart';
import 'package:flutter_sixvalley_ecommerce/features/checkout/domain/models/order_insurance_quote_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/offline_payment/domain/models/offline_payment_model.dart';
import 'package:flutter_sixvalley_ecommerce/helper/api_checker.dart';
import 'package:flutter_sixvalley_ecommerce/helper/route_healper.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/main.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/show_custom_snakbar_widget.dart';
import 'package:provider/provider.dart';
import 'dart:convert';



class CheckoutController with ChangeNotifier {
  final CheckoutServiceInterface checkoutServiceInterface;
  CheckoutController({required this.checkoutServiceInterface});

  int? _addressIndex;
  int? _billingAddressIndex;
  int? get billingAddressIndex => _billingAddressIndex;
  int? _shippingIndex;
  bool _isLoading = false;
  bool _isCheckCreateAccount = false;
  bool _newUser = false;

  int _paymentMethodIndex = -1;
  bool _onlyDigital = true;
  bool get onlyDigital => _onlyDigital;
  int? get addressIndex => _addressIndex;
  int? get shippingIndex => _shippingIndex;
  bool get isLoading => _isLoading;
  int get paymentMethodIndex => _paymentMethodIndex;
  bool get isCheckCreateAccount => _isCheckCreateAccount;


  ReferralAmount? _referralAmount;
  ReferralAmount? get referralAmount => _referralAmount;
  OrderInsuranceQuoteModel? _orderInsuranceQuote;
  OrderInsuranceQuoteModel? get orderInsuranceQuote => _orderInsuranceQuote;
  bool _insuranceQuoteLoading = false;
  bool get insuranceQuoteLoading => _insuranceQuoteLoading;
  int _quoteRequest = 0;

  Future<void> getOrderInsuranceQuote({String couponCode = ''}) async {
    final requestId = ++_quoteRequest;
    _orderInsuranceQuote = null;
    _insuranceQuoteLoading = true;
    notifyListeners();
    final response = await checkoutServiceInterface.getOrderInsuranceQuote(couponCode);
    if (requestId != _quoteRequest) return;
    _insuranceQuoteLoading = false;
    if (response.response != null && response.response!.statusCode == 200) {
      _orderInsuranceQuote = OrderInsuranceQuoteModel.fromJson(Map<String, dynamic>.from(response.response!.data));
    }
    notifyListeners();
  }

  String selectedPaymentName = '';
  void setSelectedPayment(String payment){
    selectedPaymentName = payment;
    notifyListeners();
  }

  bool _isAcceptTerms = false;
  bool get isAcceptTerms => _isAcceptTerms;


  final TextEditingController orderNoteController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  List<String> inputValueList = [];

  Future<void> placeOrder({
    required Function callback, 
    String? addressID,
    String? couponCode, 
    String? couponAmount,
    String? billingAddressId, 
    String? orderNote, 
    String? transactionId,
    String? paymentNote, 
    int? id, 
    String? name,
    bool isfOffline = false, 
  }) async {

    String imagePath = '';
    if (isfOffline) {
      Map<String, String> methodInformations = {};

      for (int i = 0; i < offlinePaymentModel!.offlineMethods![offlineMethodSelectedIndex].methodInformations!.length; i++) {
        var field = offlinePaymentModel!.offlineMethods![offlineMethodSelectedIndex].methodInformations![i];

        if (field.inputType == 'image') {
          imagePath = inputFieldControllerList[i].text.trim();
        } else {
          methodInformations[field.customerInput ?? ''] = inputFieldControllerList[i].text.trim();
        }
      }

      String base64EncodedJson = base64Encode(utf8.encode(jsonEncode(methodInformations)));

      inputValueList = [base64EncodedJson];
      keyList = ['method_informations'];
    } else {
      for(TextEditingController textEditingController in inputFieldControllerList) {
        inputValueList.add(textEditingController.text.trim());
      }
    }

    _isLoading = true;
    _newUser = false;
    notifyListeners();
    ApiResponseModel apiResponse;
    isfOffline?
    apiResponse = await checkoutServiceInterface.offlinePaymentPlaceOrder(addressID, couponCode, couponAmount, billingAddressId, orderNote, keyList, inputValueList, offlineMethodSelectedId, offlineMethodSelectedName, paymentNote, _isCheckCreateAccount, passwordController.text.trim(), imagePath): // <-- أضفنا imagePath هنا
    apiResponse = await checkoutServiceInterface.offlinePaymentPlaceOrder(addressID, couponCode, couponAmount, billingAddressId, orderNote, keyList, inputValueList, offlineMethodSelectedId, offlineMethodSelectedName, paymentNote, _isCheckCreateAccount, passwordController.text.trim(), imagePath);

    if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
      _isCheckCreateAccount = false;
      _isLoading = false;
      _addressIndex = null;
      _billingAddressIndex = null;
      sameAsBilling = false;
      if(!Provider.of<AuthController>(Get.context!, listen: false).isLoggedIn()){
        _newUser = apiResponse.response!.data['new_user'];
      }

      String message = apiResponse.response!.data.toString();
      callback(true, message, extractId(apiResponse.response!.data['order_ids'].toString()), _newUser);
    } else {
      _isLoading = false;
     ApiChecker.checkApi(apiResponse);
    }
    notifyListeners();
  }


  String? extractId(String idsString) {

    String cleaned = idsString.replaceAll(RegExp(r'[\[\]\s]'), '');
    return cleaned.isNotEmpty ? cleaned : null;
  }

  String? getFirstOrderId(String idsString) {
    if (idsString.trim().isEmpty) return null;

    List<String> ids = idsString.split(',').map((e) => e.trim()).toList();

    return ids.isNotEmpty ? ids.first : null;
  }



  void setAddressIndex(int index) {
    _addressIndex = index;
    notifyListeners();
  }
  void setBillingAddressIndex(int index) {
    _billingAddressIndex = index;
    notifyListeners();
  }


  void resetPaymentMethod(){
    _paymentMethodIndex = -1;
    isOfflineChecked = false;
    isWalletChecked = false;
  }


  void shippingAddressNull(){
    _addressIndex = null;
    notifyListeners();
  }

  void billingAddressNull(){
    _billingAddressIndex = null;
    notifyListeners();
  }

  void setSelectedShippingAddress(int index) {
    _shippingIndex = index;
    notifyListeners();
  }
  void setSelectedBillingAddress(int index) {
    _billingAddressIndex = index;
    notifyListeners();
  }


  bool isOfflineChecked = false;
  bool isWalletChecked = false;

  void selectPurchaseWallet() {
    resetPaymentMethod();
    isWalletChecked = true;
    notifyListeners();
  }

  Future<void> payWithPurchaseWallet(String addressId, String couponCode, String couponDiscount, String orderNote, Function callback) async {
    if (_isLoading || !_isAcceptTerms) return;
    _isLoading = true;
    notifyListeners();
    try {
      final response = await checkoutServiceInterface.walletPaymentPlaceOrder(addressId, couponCode, couponDiscount, '', orderNote, false, '');
      if (response.response?.statusCode == 200) {
        callback(true, getTranslated('order_placed_successfully', Get.context!) ?? '', extractId(response.response.data['order_ids'].toString()), false);
      } else {
        ApiChecker.checkApi(response);
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setOfflineChecked(String type, {bool notify = true}) {
    isWalletChecked = false;
    if(type == 'offline'){
      isOfflineChecked = !isOfflineChecked;
      _paymentMethodIndex = -1;
      setOfflinePaymentMethodSelectedIndex(0);
    }

    if(notify) {
      notifyListeners();
    }
  }



  String selectedDigitalPaymentMethodName = '';

  void setDigitalPaymentMethodName(int index, String name) {
    _paymentMethodIndex = index;
    selectedDigitalPaymentMethodName = name;
    isOfflineChecked = false;
    isWalletChecked = false;
    notifyListeners();
  }


  void digitalOnly(bool value, {bool isUpdate = false}){
    _onlyDigital = value;
    if(isUpdate){
      notifyListeners();
    }

  }



  OfflinePaymentModel? offlinePaymentModel;
  Future<ApiResponseModel> getOfflinePaymentList() async {
    ApiResponseModel apiResponse = await checkoutServiceInterface.offlinePaymentList();
    if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
      offlineMethodSelectedIndex = 0;
      offlinePaymentModel = OfflinePaymentModel.fromJson(apiResponse.response?.data);
    }
    else {
      ApiChecker.checkApi( apiResponse);
    }
    notifyListeners();
    return apiResponse;
  }

  List<TextEditingController> inputFieldControllerList = [];
  List <String?> keyList = [];
  int offlineMethodSelectedIndex = -1;
  int offlineMethodSelectedId = 0;
  String offlineMethodSelectedName = '';

  void setOfflinePaymentMethodSelectedIndex(int index, {bool notify = true}){
    keyList = [];
    inputFieldControllerList = [];
    offlineMethodSelectedIndex = index;
    if(offlinePaymentModel != null && offlinePaymentModel!.offlineMethods!= null && offlinePaymentModel!.offlineMethods!.isNotEmpty){
      offlineMethodSelectedId = offlinePaymentModel!.offlineMethods![offlineMethodSelectedIndex].id!;
      offlineMethodSelectedName = offlinePaymentModel!.offlineMethods![offlineMethodSelectedIndex].methodName!;
    }

    if(offlinePaymentModel!.offlineMethods != null && offlinePaymentModel!.offlineMethods!.isNotEmpty && offlinePaymentModel!.offlineMethods![index].methodInformations!.isNotEmpty){
      for(int i= 0; i< offlinePaymentModel!.offlineMethods![index].methodInformations!.length; i++){
        inputFieldControllerList.add(TextEditingController());
        keyList.add(offlinePaymentModel!.offlineMethods![index].methodInformations![i].customerInput);
      }
    }
    if(notify){
      notifyListeners();
    }
  }

  Future<ApiResponseModel> digitalPaymentPlaceOrder({String? orderNote, String? customerId,
    String? addressId, String? billingAddressId,
    String? couponCode,
    String? couponDiscount,
    String? paymentMethod}) async {
    _isLoading =true;
    notifyListeners();

    ApiResponseModel apiResponse = await checkoutServiceInterface.digitalPaymentPlaceOrder(orderNote, customerId, addressId, billingAddressId, couponCode, couponDiscount, paymentMethod, _isCheckCreateAccount, passwordController.text.trim());

    if (apiResponse.response != null && apiResponse.response?.statusCode == 200) {
      _addressIndex = null;
      _billingAddressIndex = null;
      sameAsBilling = false;
      _isLoading = false;

      RouterHelper.getDigitalPaymentScreenRoute(
        url: apiResponse.response?.data['redirect_link'] ?? '',
        fromWallet: false,
        action: RouteAction.pushReplacement,
      );

    } else if(apiResponse.error == 'Already registered ') {
      _isLoading = false;
      showCustomSnackBarWidget(getTranslated(apiResponse.error, Get.context!), Get.context!, snackBarType: SnackBarType.warning);
    } else if(apiResponse.response != null && apiResponse.response!.statusCode == 403) {
      _isLoading = false;
      showCustomSnackBarWidget(getTranslated(apiResponse.error, Get.context!), Get.context!, snackBarType: SnackBarType.error);
    } else {
      _isLoading = false;
      showCustomSnackBarWidget(getTranslated('payment_method_not_properly_configured', Get.context!), Get.context!, snackBarType: SnackBarType.error);
    }
    notifyListeners();
    return apiResponse;
  }

  bool sameAsBilling = false;
  void setSameAsBilling({bool isUpdate = true}) {
    sameAsBilling = !sameAsBilling;
    if(isUpdate) {
      notifyListeners();
    }
  }

  void clearData(){
    orderNoteController.clear();
    passwordController.clear();
    confirmPasswordController.clear();
    _isCheckCreateAccount = false;
  }


  void setIsCheckCreateAccount(bool isCheck, {bool update = true}) {
    _isCheckCreateAccount = isCheck;
    if(update) {
      notifyListeners();
    }
  }



 
  Future<ApiResponseModel> getReferralAmount(String? amount) async {
    ApiResponseModel apiResponse = await checkoutServiceInterface.getReferralAmount(amount);
    if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
      _referralAmount = ReferralAmount.fromJson(apiResponse.response.data);
    } else {
      ApiChecker.checkApi( apiResponse);
    }
    notifyListeners();
    return apiResponse;
  }


  void toggleTermsCheck({bool isUpdate = true}) {
    _isAcceptTerms = !_isAcceptTerms;
    if(isUpdate) {
      notifyListeners();
    }
  }


  void updatePaymentSelection(){
    notifyListeners();
  }


}
