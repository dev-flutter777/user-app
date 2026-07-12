import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_button_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/address/controllers/address_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/checkout/controllers/checkout_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/offline_payment/domain/models/offline_payment_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/profile/controllers/profile_contrroller.dart';
import 'package:flutter_sixvalley_ecommerce/helper/price_converter.dart';
import 'package:flutter_sixvalley_ecommerce/helper/velidate_check.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/features/coupon/controllers/coupon_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/splash/controllers/splash_controller.dart';
import 'package:flutter_sixvalley_ecommerce/utill/custom_themes.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:flutter_sixvalley_ecommerce/utill/images.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_app_bar_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_textfield_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/checkout/widgets/shipping_details_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/offline_payment/widgets/offline_card_widget.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';

class OfflinePaymentScreen extends StatefulWidget {
  final double payableAmount;
  final Function callback;
  
  // 🟢 المتغيرات الجديدة اللي استقبلناها عشان الباقة
  final String paymentType; 
  final int? activationInvoiceId;

  const OfflinePaymentScreen({
    super.key, 
    required this.payableAmount, 
    required this.callback,
    this.paymentType = 'order', // افتراضي أوردر منتجات عشان السلة متضربش
    this.activationInvoiceId,
  });

  @override
  State<OfflinePaymentScreen> createState() => _OfflinePaymentScreenState();
}

class _OfflinePaymentScreenState extends State<OfflinePaymentScreen> {
   TextEditingController paymentController = TextEditingController();
   final GlobalKey<FormState> offlineFormKey = GlobalKey<FormState>();
   File? _pickedImage;




   @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: getTranslated('offline_payment', context)),
      body: Consumer<CheckoutController>(
        builder: (context, checkoutProvider, _) {
          return CustomScrollView(slivers: [
            SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: Dimensions.homePagePadding),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start,mainAxisSize: MainAxisSize.min, children: [
                Center(child: SizedBox(height: 100, child: Image.asset(Images.offlinePayment))),
                Padding(padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
                  child: Text('${getTranslated('offline_payment_helper_text', context)}', textAlign: TextAlign.center,
                      style: textRegular.copyWith(color: Theme.of(context).hintColor, fontSize: Dimensions.fontSizeDefault)),),

                if(checkoutProvider.offlinePaymentModel != null && checkoutProvider.offlinePaymentModel!.offlineMethods != null &&
                    checkoutProvider.offlinePaymentModel!.offlineMethods!.isNotEmpty)
                  SizedBox(height: 190,
                      child: RepaintBoundary(
                        child: ListView.builder(
                            padding: EdgeInsets.zero,
                            scrollDirection: Axis.horizontal,
                            shrinkWrap: true,
                            itemCount: checkoutProvider.offlinePaymentModel!.offlineMethods!.length,
                            itemBuilder: (context, index){
                              return InkWell(
                                splashColor: Colors.transparent,
                                onTap: (){
                                if(checkoutProvider.offlinePaymentModel?.offlineMethods != null &&
                                    checkoutProvider.offlinePaymentModel!.offlineMethods!.isNotEmpty){
                                  checkoutProvider.setOfflinePaymentMethodSelectedIndex(index);
                                }
                              }, child: OfflineCardWidget(
                                  offlinePaymentModel: checkoutProvider.offlinePaymentModel!.offlineMethods![index],
                                  index: index));}),
                      )),


                Center(child: Padding(padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                    child: Text('${getTranslated('amount', context)} : ${PriceConverter.convertPrice(context, widget.payableAmount)}',
                        style: textBold.copyWith(fontSize: Dimensions.fontSizeLarge)))),


                Text('${getTranslated('payment_info', context)}', style: textBold.copyWith(fontSize: Dimensions.fontSizeLarge),),

                Form(
                  key: offlineFormKey,
                  child: RepaintBoundary(
                    child: ListView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: checkoutProvider.offlinePaymentModel!.offlineMethods![checkoutProvider.offlineMethodSelectedIndex].methodInformations?.length ?? 0,
                        itemBuilder: (context, index){
                          MethodInformations? methodInformation = checkoutProvider.offlinePaymentModel!.offlineMethods![checkoutProvider.offlineMethodSelectedIndex].methodInformations?[index];

                          // إذا كان نوع الحقل القادم من الأدمن image يتم رسم زر اختيار صورة بدلاً من الـ TextField
                          if (methodInformation?.inputType == 'image') {
                            return Padding(
                              padding: const EdgeInsets.only(top: Dimensions.paddingSizeDefault),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${methodInformation?.customerPlaceholder}'.replaceAll('_', ' ').capitalize() + (methodInformation?.isRequired == 1 ? ' *' : ''),
                                    style: textBold.copyWith(fontSize: Dimensions.fontSizeDefault),
                                  ),
                                  const SizedBox(height: 10),
                                  InkWell(
                                    onTap: () async {
                                      final ImagePicker picker = ImagePicker();
                                      final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
                                      
                                      if (image != null) {
                                        setState(() {
                                          _pickedImage = File(image.path);
                                        });
                                        // نقوم بحفظ مسار الصورة داخل حقل الكنترولر التابع لهذا الـ index لتسهيل قراءته في الـ Controller
                                        checkoutProvider.inputFieldControllerList[index].text = image.path;
                                      }
                                    },
                                    child: Container(
                                      height: 140,
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).cardColor,
                                        borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall),
                                        border: Border.all(color: Theme.of(context).hintColor.withOpacity(0.5)),
                                      ),
                                      child: _pickedImage != null 
                                        ? ClipRRect(
                                            borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall),
                                            child: Image.file(_pickedImage!, fit: BoxFit.cover),
                                          )
                                        : Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.camera_alt, color: Theme.of(context).hintColor, size: 40),
                                              const SizedBox(height: 8),
                                              Text(
                                                'إرفاق صورة التحويل (Screenshot)',
                                                style: textRegular.copyWith(color: Theme.of(context).hintColor),
                                              ),
                                            ],
                                          ),
                                    ),
                                  ),
                                  // حقل خفي للتحقق من أن المستخدم قام برفع الصورة إذا كانت مطلوبة (is_required = 1)
                                  FormField<String>(
                                    validator: (value) {
                                      if (methodInformation?.isRequired == 1 && _pickedImage == null) {
                                        return 'يرجى إرفاق صورة إثبات التحويل أولاً';
                                      }
                                      return null;
                                    },
                                    builder: (FormFieldState<String> state) {
                                      return state.hasError 
                                        ? Padding(
                                            padding: const EdgeInsets.only(top: 5, left: 5),
                                            child: Text(state.errorText!, style: textRegular.copyWith(color: Colors.red, fontSize: Dimensions.fontSizeSmall)),
                                          )
                                        : const SizedBox();
                                    },
                                  ),
                                ],
                              ),
                            );
                          }

                          // الحقول النصية العادية ترسم TextField كما كانت سابقاً
                          return Padding(
                            padding: const EdgeInsets.only(top: Dimensions.paddingSizeDefault),
                            child: CustomTextFieldWidget(
                              controller: checkoutProvider.inputFieldControllerList[index],
                              required: methodInformation?.isRequired == 1,
                              labelText: '${methodInformation?.customerInput}'.replaceAll('_', ' ').capitalize(),
                              hintText: '${methodInformation?.customerPlaceholder}'.replaceAll('_', ' ').capitalize(),
                              validator: (value) {
                                if(methodInformation?.isRequired == 1) {
                                  return ValidateCheck.validateEmptyText(value, '${methodInformation?.customerInput}'.replaceAll('_', ' ').capitalize());
                                } else {
                                  return null;
                                }
                              },
                            ),
                          );
                        }),
                  ),
                ),

                const SizedBox(height: 20,),
                CustomTextFieldWidget(controller: paymentController,
                labelText:  getTranslated('note', context),
                hintText: getTranslated('note', context),),
                const SizedBox(height: 20,),
              ])))]);}),


      bottomNavigationBar: Consumer<CheckoutController>(
        builder: (context, checkoutProvider, _) {
          return Consumer<ProfileController>(
            builder: (context, profileProvider,_) {
              return Consumer<CouponController>(
                builder: (context, couponProvider,_) {
                  return Consumer<AddressController>(
                    builder: (context, locationProvider,_) {
                      return Padding(
                        padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                        child: CustomButton(
                          isLoading: checkoutProvider.isLoading,
                          onTap: (){
                            if(offlineFormKey.currentState?.validate() ?? false){

                              String paymentNote = paymentController.text.trim();
                              String orderNote = checkoutProvider.orderNoteController.text.trim();
                              String couponCode = couponProvider.discount != null && couponProvider.discount != 0? couponProvider.couponCode : '';
                              String couponCodeAmount = couponProvider.discount != null && couponProvider.discount != 0?
                              couponProvider.discount.toString() : '0';
                              String addressId = checkoutProvider.addressIndex != null ? locationProvider.addressList![checkoutProvider.addressIndex!].id.toString() : '';

                              String billingAddressId =  (Provider.of<SplashController>(context, listen: false).configModel!.billingInputByCustomer == 1)
                                  ? !checkoutProvider.sameAsBilling ? locationProvider.addressList![checkoutProvider.billingAddressIndex!].id.toString()
                                  : locationProvider.addressList![checkoutProvider.addressIndex!].id.toString() : '';



                              checkoutProvider.placeOrder(
                                callback: widget.callback,
                                paymentNote: paymentNote,
                                addressID: addressId,
                                billingAddressId: billingAddressId,
                                orderNote: orderNote,
                                couponCode: couponCode,
                                couponAmount: couponCodeAmount,
                                isfOffline: true,
                                paymentType: widget.paymentType,
                                activationInvoiceId: widget.activationInvoiceId,
                              );
                            }
                          },

                          buttonText: getTranslated('proceed', context),
                        ),
                      );
                    }
                  );
                }
              );
            }
          );
        }
      ),
    );
  }
}
