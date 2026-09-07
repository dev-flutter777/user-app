import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/features/address/controllers/address_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/cart/domain/models/cart_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/checkout/controllers/checkout_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/order_insurance/controllers/customer_order_insurance_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/checkout/widgets/checkout_condition_checkbox.dart';
import 'package:flutter_sixvalley_ecommerce/features/checkout/widgets/payment_method_bottom_sheet_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/profile/controllers/profile_contrroller.dart';
import 'package:flutter_sixvalley_ecommerce/features/shipping/controllers/shipping_controller.dart';
import 'package:flutter_sixvalley_ecommerce/helper/cart_healper.dart';
import 'package:flutter_sixvalley_ecommerce/helper/debounce_helper.dart';
import 'package:flutter_sixvalley_ecommerce/helper/price_converter.dart';
import 'package:flutter_sixvalley_ecommerce/helper/route_healper.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/main.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/controllers/auth_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/cart/controllers/cart_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/coupon/controllers/coupon_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/splash/controllers/splash_controller.dart';
import 'package:flutter_sixvalley_ecommerce/utill/custom_themes.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/amount_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_app_bar_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_button_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/show_custom_snakbar_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_textfield_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/checkout/widgets/choose_payment_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/checkout/widgets/coupon_apply_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/checkout/widgets/shipping_details_widget.dart';
import 'package:provider/provider.dart';
 


class CheckoutScreen extends StatefulWidget {
  final List<CartModel> cartList;
  final bool fromProductDetails;
  final double totalOrderAmount;
  final double shippingFee;
  final double discount;
  final double tax;
  final int? sellerId;
  final bool onlyDigital;
  final bool hasPhysical;
  final int quantity;

  const CheckoutScreen({super.key, required this.cartList, this.fromProductDetails = false,
    required this.discount, required this.tax, required this.totalOrderAmount, required this.shippingFee,
    this.sellerId, this.onlyDigital = false, required this.quantity, required this.hasPhysical});


  @override
  CheckoutScreenState createState() => CheckoutScreenState();
}

class CheckoutScreenState extends State<CheckoutScreen> {
  String? _quoteKey;
  String? _quoteReadyKey;
  final GlobalKey<ScaffoldMessengerState> _scaffoldKey = GlobalKey<ScaffoldMessengerState>();
  final TextEditingController _controller = TextEditingController();
  final GlobalKey<FormState> passwordFormKey = GlobalKey<FormState>();


  final FocusNode _orderNoteNode = FocusNode();
  double _order = 0;
  double _tax = 0;
  late bool _billingAddress;
  double? _couponDiscount;
  double? _referralDiscount;

  DebounceHelper debounceHelper = DebounceHelper(milliseconds: 500);
  SplashController  splashController= Provider.of<SplashController>(Get.context!, listen: false);


  @override
  void initState() {
    super.initState();
    Provider.of<AddressController>(context, listen: false).getAddressList();
    Provider.of<CheckoutController>(context, listen: false).getReferralAmount('0');
    Provider.of<CouponController>(context, listen: false).removePrevCouponData();
    Provider.of<CartController>(context, listen: false).getCartData(context);
    Provider.of<CheckoutController>(context, listen: false).resetPaymentMethod();
    Provider.of<ShippingController>(context, listen: false).getChosenShippingMethod(context);
    if(splashController.configModel != null &&
        splashController.configModel!.offlinePayment != null)
    {
      Provider.of<CheckoutController>(context, listen: false).getOfflinePaymentList();
    }

    if(Provider.of<AuthController>(context, listen: false).isLoggedIn()){
      Provider.of<CouponController>(context, listen: false).getAvailableCouponList();
    }

    if(Provider.of<CheckoutController>(context, listen: false).isAcceptTerms){
      Provider.of<CheckoutController>(context, listen: false).toggleTermsCheck(isUpdate: false);
    }

    // Billing addresses are not collected in this store. The delivery address
    // is the only address used for physical orders.
    _billingAddress = false;
    Provider.of<CheckoutController>(context, listen: false).clearData();

    if(splashController.configModel?.systemTaxIncludeStatus != 1) {
      _tax = widget.tax;
    }

  }

  @override
  Widget build(BuildContext context) {
    _order = widget.totalOrderAmount + widget.discount;
    // Shipping is intentionally calculated only after the delivery address is
    // selected. Read it from the server-synchronised cart state instead of the
    // value that was available when the customer first left the cart.
    final physicalCartGroupIds = widget.cartList
        .where((cart) => cart.productType == 'physical' && (cart.isChecked ?? false))
        .map((cart) => cart.cartGroupId)
        .whereType<String>()
        .toSet();
    final selectedShipping = Provider.of<ShippingController>(context).chosenShippingList
        .where((shipping) => shipping.isCheckItemExist == 1 && physicalCartGroupIds.contains(shipping.cartGroupId))
        .toList();
    final selectedShippingFee = selectedShipping
        .fold<double>(0, (total, shipping) => total + (shipping.shippingCost ?? 0));
    final coupon = context.watch<CouponController>();
    final checkout = context.watch<CheckoutController>();
    final quoteKey = '${coupon.couponCode}:${coupon.discount}:${checkout.addressIndex}:${selectedShipping.map((s) => '${s.cartGroupId}:${s.shippingCost}').join(',')}';
    if (_quoteKey != quoteKey) {
      _quoteKey = quoteKey;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        await checkout.getOrderInsuranceQuote(couponCode: coupon.discount != null && coupon.discount != 0 ? coupon.couponCode : '');
        if (mounted && _quoteKey == quoteKey) setState(() => _quoteReadyKey = checkout.orderInsuranceQuote == null ? null : quoteKey);
      });
    }
    final deliveryIsConfirmed = !widget.hasPhysical || (
        Provider.of<CheckoutController>(context).addressIndex != null &&
        physicalCartGroupIds.isNotEmpty &&
        physicalCartGroupIds.every((groupId) => selectedShipping.any((shipping) => shipping.cartGroupId == groupId))
    );
    return Scaffold(
      resizeToAvoidBottomInset: true,
      key: _scaffoldKey,
      bottomNavigationBar: Consumer<AddressController>(
        builder: (context, locationProvider,_) {
          return Consumer<CheckoutController>(
            builder: (context, orderProvider, child) {
              return Consumer<CouponController>(
                builder: (context, couponProvider, _) {
                  if (orderProvider.orderInsuranceQuote?.postPurchaseEnabled == true) {
                    _tax = 0;
                  } else if(splashController.configModel?.systemTaxIncludeStatus != 1) {
                    _tax = CartHelper().calculateVatTax(Provider.of<CartController>(context, listen: false).cartList);
                  }
                  return Consumer<CartController>(
                    builder: (context, cartProvider,_) {
                      return Consumer<ProfileController>(
                        builder: (context, profileProvider,_) {
                          return orderProvider.isLoading ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center, children: [
                              SizedBox(width: 30,height: 30,child: CircularProgressIndicator())]
                          ) :

                          Container(
                            padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                            color: Theme.of(context).cardColor,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [

                                const CheckoutConditionCheckBox(),
                                const SizedBox(height: Dimensions.paddingSizeSmall),

                                CustomButton(onTap: (orderProvider.isLoading || _quoteReadyKey != _quoteKey || orderProvider.insuranceQuoteLoading || orderProvider.orderInsuranceQuote == null || !orderProvider.isAcceptTerms) ? null : () async {
                                  if (!deliveryIsConfirmed) {
                                    RouterHelper.getSavedAddressListRoute(fromGuest: !context.read<AuthController>().isLoggedIn());
                                    showCustomSnackBarWidget(getTranslated('select_a_shipping_address', context), Get.context!, snackBarType: SnackBarType.warning);
                                    return;
                                  }
                                  if (orderProvider.isCheckCreateAccount && !(passwordFormKey.currentState?.validate() ?? false)) return;
                                  final orderNote = orderProvider.orderNoteController.text.trim();
                                  final couponCode = couponProvider.discount != null && couponProvider.discount != 0 ? couponProvider.couponCode : '';
                                  final couponAmount = couponProvider.discount?.toString() ?? '0';
                                  final addressId = orderProvider.addressIndex != null ? locationProvider.addressList![orderProvider.addressIndex!].id.toString() : '';
                                  if (orderProvider.isWalletChecked) {
                                    await orderProvider.payWithPurchaseWallet(addressId, couponCode, couponAmount, orderNote, _callback);
                                  } else if (orderProvider.paymentMethodIndex != -1) {
                                    await orderProvider.digitalPaymentPlaceOrder(
                                      orderNote: orderNote,
                                      customerId: context.read<AuthController>().isLoggedIn() ? profileProvider.userInfoModel?.id.toString() : context.read<AuthController>().getGuestToken(),
                                      addressId: addressId, billingAddressId: '',
                                      couponCode: couponCode, couponDiscount: couponAmount,
                                      paymentMethod: orderProvider.selectedDigitalPaymentMethodName);
                                  } else if (orderProvider.isOfflineChecked) {
                                    RouterHelper.getOfflinePaymentScreen(payableAmount: orderProvider.orderInsuranceQuote!.firstPaymentAmount ?? (_order + selectedShippingFee - widget.discount - (_referralDiscount ?? 0) - _couponDiscount! + _tax), callback: _callback);
                                  } else {
                                    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
                                      builder: (_) => PaymentMethodBottomSheetWidget(onlyDigital: widget.onlyDigital));
                                  }
                                },
                                  buttonText: '${getTranslated('proceed', context)}',
                                )
                              ],
                            ),
                          );


                        }
                      );
                    }
                  );
                }
              );
            }
          );
        }
      ),

      appBar: CustomAppBar(title: getTranslated('checkout', context)),
      body: Consumer<AuthController>(
        builder: (context, authProvider,_) {
          return Consumer<CheckoutController>(
            builder: (context, orderProvider,_) {
              return Column(children: [
                  Expanded(
                    child: ListView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.all(0),
                      children: [
                        SizedBox(height: Dimensions.paddingSizeSmall),

                        if (!orderProvider.insuranceQuoteLoading && orderProvider.orderInsuranceQuote == null)
                          TextButton.icon(onPressed: () => setState(() => _quoteKey = null),
                            icon: const Icon(Icons.refresh), label: Text(getTranslated('checkout_quote_retry', context) ?? '')),

                        Padding(
                          padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeDefault),
                          child: ShippingDetailsWidget(
                            hasPhysical: widget.hasPhysical,
                            billingAddress: _billingAddress,
                            passwordFormKey: passwordFormKey,
                          ),
                        ),


                        if (Provider.of<AuthController>(context, listen: false).isLoggedIn())
                          Padding(
                            padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
                            child: CouponApplyWidget(
                              couponController: _controller,
                              orderAmount: _order,
                            ),
                          ),


                        if (deliveryIsConfirmed)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 0),
                            child: ChoosePaymentWidget(onlyDigital: widget.onlyDigital),
                          )
                        else
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                            color: Theme.of(context).cardColor,
                            child: Text(
                              getTranslated('checkout_shipping_hint', context) ?? '',
                              style: textRegular.copyWith(color: Theme.of(context).hintColor),
                            ),
                          ),
                        SizedBox(height: Dimensions.paddingSizeSmall),

                        Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            boxShadow: [BoxShadow(color: Theme.of(context).hintColor.withValues(alpha:0.2), spreadRadius:3, blurRadius: 3)],
                          ),
                          padding: const EdgeInsets.fromLTRB(
                            Dimensions.paddingSizeDefault,
                            Dimensions.paddingSizeDefault,
                            Dimensions.paddingSizeDefault,
                            Dimensions.paddingSizeSmall,
                          ),
                          child: Text(
                            getTranslated('order_summary', context) ?? '',
                            style: textMedium.copyWith(
                              fontSize: Dimensions.fontSizeLarge,
                              color: Theme.of(context).textTheme.bodyLarge?.color,
                            ),
                          ),
                        ),


                        Container(
                          color: Theme.of(context).cardColor,
                          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
                          child: Consumer<CheckoutController>(
                            builder: (context, checkoutController, child) {
                              _couponDiscount = Provider.of<CouponController>(context).discount ?? 0;
                              _referralDiscount = Provider.of<CheckoutController>(context).referralAmount?.amount ?? 0;
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  widget.quantity > 1
                                  ? AmountWidget(
                                      title: '${getTranslated('sub_total', context)} ${' (${widget.quantity} ${getTranslated('items', context)}) '}',
                                      amount: PriceConverter.convertPrice(context, _order),
                                    )
                                  : AmountWidget(
                                      title: '${getTranslated('sub_total', context)} ${'(${widget.quantity} ${getTranslated('item', context)})'}',
                                      amount: PriceConverter.convertPrice(context, _order),
                                    ),
                                  AmountWidget(
                                    title: getTranslated('shipping_fee', context),
                                    amount: PriceConverter.convertPrice(context, selectedShippingFee),
                                  ),
                                  AmountWidget(
                                    title: getTranslated('discount', context),
                                    amount: PriceConverter.convertPrice(context, widget.discount),
                                  ),
                                  AmountWidget(
                                    title: getTranslated('coupon_voucher', context),
                                    amount: PriceConverter.convertPrice(context, _couponDiscount),
                                  ),

                                  if (checkoutController.orderInsuranceQuote?.postPurchaseEnabled != true && splashController.configModel?.systemTaxIncludeStatus != 1)
                                  AmountWidget(
                                    title: getTranslated('tax', context),
                                    amount: PriceConverter.convertPrice(context, _tax),
                                  ),

                                  if ((_referralDiscount ?? 0) > 0)
                                  AmountWidget(
                                    title: getTranslated('referral_discount', context),
                                    amount: PriceConverter.convertPrice(context, _referralDiscount),
                                  ),

                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: Text(
                                      getTranslated('post_purchase_insurance_checkout_notice', context)!,
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ),

                                  Divider(height: 5, color: Theme.of(context).hintColor),
                                  AmountWidget(
                                    fontSize: Dimensions.fontSizeLarge, isTitleBlack: true,
                                    title: '${getTranslated('total_payable', context)} ${checkoutController.orderInsuranceQuote?.postPurchaseEnabled != true && splashController.configModel?.systemTaxIncludeStatus == 1 ? getTranslated('inc_vat_tax', context) : ''}',
                                    amount: PriceConverter.convertPrice(context,
                                      checkoutController.orderInsuranceQuote?.firstPaymentAmount ?? (_order + selectedShippingFee - (_referralDiscount ?? 0) - widget.discount - _couponDiscount! + _tax),
                                    ),
                                  ),

                                  SizedBox(height: Dimensions.paddingSizeSmall),
                                ],
                              );
                            },
                          ),
                        ),


                        SizedBox(height: Dimensions.paddingSizeSmall),
                        Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            boxShadow: [BoxShadow(color: Theme.of(context).hintColor.withValues(alpha:0.2), spreadRadius:3, blurRadius: 3)],
                          ),
                          padding: const EdgeInsets.fromLTRB(
                            Dimensions.paddingSizeDefault,
                            Dimensions.paddingSizeDefault,
                            Dimensions.paddingSizeDefault,
                            Dimensions.paddingSizeDefault,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Text(
                                  '${getTranslated('order_note', context)}',
                                  style: textRegular.copyWith(
                                    fontSize: Dimensions.fontSizeLarge,
                                    color: Theme.of(context).textTheme.bodyLarge?.color,
                                  ),
                                ),
                              ]),
                              const SizedBox(height: Dimensions.paddingSizeSmall),
                              CustomTextFieldWidget(
                                hintText: getTranslated('enter_note', context),
                                inputType: TextInputType.multiline,
                                inputAction: TextInputAction.done,
                                maxLines: 3,
                                focusNode: _orderNoteNode,
                                controller: orderProvider.orderNoteController,
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: Dimensions.paddingSizeDefault),

                      ],
                    ),
                  ),
                ],
              );
            }
          );
        }
      ),
    );
  }

  void _callback(bool isSuccess, String message, String orderID, bool createAccount) async {
    if (isSuccess) {
      showCustomSnackBarWidget(
        getTranslated('order_placed_successfully', Get.context!) ?? message,
        Get.context!, 
        snackBarType: SnackBarType.success,
      );
      final firstOrderId = int.tryParse(orderID.split(',').first.trim());
      if (firstOrderId != null) {
        final requiresInsurance = await Provider.of<CustomerOrderInsuranceController>(Get.context!, listen: false)
            .load(firstOrderId);
        if (requiresInsurance) {
          RouterHelper.getCustomerOrderInsuranceRoute(
            orderId: firstOrderId,
            action: RouteAction.pushReplacement,
          );
        } else {
          RouterHelper.getOrderDetailsScreenRoute(
            orderId: firstOrderId,
            action: RouteAction.pushReplacement,
            isNotification: true,
          );
        }
      }
    } else {
      showCustomSnackBarWidget(message, Get.context!, snackBarType: SnackBarType.error);
    }
  }
}
