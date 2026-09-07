import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/controllers/auth_controller.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:flutter_sixvalley_ecommerce/utill/images.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_button_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/show_custom_snakbar_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_textfield_widget.dart';
import 'package:provider/provider.dart';

class MobileVerificationScreen extends StatefulWidget {
  final String tempToken;
  const MobileVerificationScreen(this.tempToken, {super.key});

  @override
  MobileVerificationScreenState createState() => MobileVerificationScreenState();
}

class MobileVerificationScreenState extends State<MobileVerificationScreen> {

  TextEditingController? _numberController;
  final FocusNode _numberFocus = FocusNode();
  static const String _countryDialCode = '+20';

  @override
  void initState() {
    super.initState();
    _numberController = TextEditingController();
  }


  @override
  Widget build(BuildContext context) {
    final number = ModalRoute.of(context)!.settings.arguments??'';
    _numberController?.text = number as String;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
          physics: const BouncingScrollPhysics(),
          child: Center(child: SizedBox(width: 1170,
              child: Consumer<AuthController>(
                builder: (context, authProvider, child) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                    Center(child: Padding(padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                        child: Image.asset(Images.login, matchTextDirection: true,height: MediaQuery.of(context).size.height / 4.5))),
                    const SizedBox(height: Dimensions.paddingSizeLarge),


                    Center(child: Text(getTranslated('mobile_verification', context)??'',)),
                    const SizedBox(height: Dimensions.paddingSizeThirtyFive),


                    Text(getTranslated('mobile_number', context)??'',),
                    const SizedBox(height: Dimensions.paddingSizeSmall),


                    Container(decoration: BoxDecoration(color: Theme.of(context).highlightColor,
                        borderRadius: BorderRadius.circular(10)),
                      child: Row(children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
                          child: Text(_countryDialCode, style: TextStyle(color: Theme.of(context).textTheme.displayLarge?.color)),
                        ),


                        Expanded(child: CustomTextFieldWidget(
                          hintText: getTranslated('number_hint', context),
                          controller: _numberController,
                          focusNode: _numberFocus,
                          isAmount: true,
                          inputAction: TextInputAction.done,
                          inputType: TextInputType.phone))])),
                    const SizedBox(height: Dimensions.paddingSizeLarge),


                    const SizedBox(height: 12),
                    !authProvider.isPhoneNumberVerificationButtonLoading ?
                    CustomButton(buttonText: getTranslated('continue', context),
                      onTap: () async {
                        String number = _countryDialCode + (_numberController?.text.trim() ?? '');
                        String numberChk = _numberController?.text.trim()??'';

                        if (numberChk.isEmpty) {
                          showCustomSnackBarWidget(getTranslated('enter_phone_number', context), context, snackBarType: SnackBarType.warning);
                        }
                        else {
                          authProvider.sendOtpToPhone(number,widget.tempToken).then((value) async {
                            if (value.isSuccess) {
                              authProvider.updatePhone(number);
                              if (value.message == 'active') {
                                // Navigator.pushAndRemoveUntil(context, MaterialPageRoute(
                                //   builder: (_) => VerificationScreen(widget.tempToken,number,'', null, fromPage: FromPage.forgetPassword),
                                //   settings: RouteSettings(
                                //     arguments: number,
                                //   ),), (route) => false);
                              }
                            }else{
                              if(context.mounted) {
                                showCustomSnackBarWidget(getTranslated('phone_number_already_exist', context), context, snackBarType: SnackBarType.error);
                              }
                            }
                          });
                        }
                      },
                    ) :
                    Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
