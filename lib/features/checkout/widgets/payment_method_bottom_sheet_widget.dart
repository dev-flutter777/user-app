import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/controllers/auth_controller.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_button_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/checkout/widgets/custom_check_box_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/no_internet_screen_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/checkout/controllers/checkout_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/offline_payment/domain/models/offline_payment_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/splash/controllers/splash_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/splash/domain/models/config_model.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/utill/custom_themes.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:provider/provider.dart';

/// Purchase balance, online payment and offline transfer share checkout consent.
class PaymentMethodBottomSheetWidget extends StatelessWidget {
  final bool onlyDigital;
  const PaymentMethodBottomSheetWidget({super.key, required this.onlyDigital});

  @override
  Widget build(BuildContext context) {
    final configModel = Provider.of<SplashController>(context, listen: false).configModel;

    return Consumer<CheckoutController>(
      builder: (context, checkoutController, _) {
        final hasOnline = (configModel?.digitalPayment ?? false) && (configModel?.paymentMethods?.isNotEmpty ?? false);
        final hasWallet = configModel?.walletStatus == 1 && context.read<AuthController>().isLoggedIn();
        final hasOffline = !onlyDigital && configModel?.offlinePayment != null && (checkoutController.offlinePaymentModel?.offlineMethods?.isNotEmpty ?? false);

        return Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * .7),
          padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
          decoration: BoxDecoration(
            color: Theme.of(context).highlightColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(width: 35, height: 4, decoration: BoxDecoration(color: Theme.of(context).hintColor.withValues(alpha: .5), borderRadius: BorderRadius.circular(8))),
              const SizedBox(height: Dimensions.paddingSizeDefault),
              Row(children: [
                Text(getTranslated('choose_payment_method', context) ?? '', style: titilliumSemiBold.copyWith(fontSize: Dimensions.fontSizeDefault)),
                const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                Expanded(child: Text(getTranslated('click_one_of_the_option_below', context) ?? '', style: textRegular.copyWith(color: Theme.of(context).hintColor, fontSize: Dimensions.fontSizeSmall))),
              ]),
              const SizedBox(height: Dimensions.paddingSizeDefault),
              Expanded(
                child: (hasOnline || hasOffline || hasWallet)
                    ? SingleChildScrollView(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          if (hasWallet) ListTile(
                            leading: const Icon(Icons.account_balance_wallet_outlined),
                            title: Text(getTranslated('purchase_wallet', context) ?? ''),
                            subtitle: Text(getTranslated('purchase_wallet_only_notice', context) ?? ''),
                            trailing: checkoutController.isWalletChecked ? Icon(Icons.check_circle, color: Theme.of(context).primaryColor) : const Icon(Icons.circle_outlined),
                            onTap: checkoutController.selectPurchaseWallet,
                          ),
                          if (hasOnline) _onlineMethods(context),
                          if (hasOnline && hasOffline) const SizedBox(height: Dimensions.paddingSizeDefault),
                          if (hasOffline) _offlineMethods(context, checkoutController),
                        ]),
                      )
                    : const NoInternetOrDataScreenWidget(isNoInternet: false, message: 'no_payment_method_available_right_now'),
              ),
              CustomButton(buttonText: getTranslated('save', context) ?? '', onTap: () => Navigator.of(context).pop()),
            ],
          ),
        );
      },
    );
  }

  Widget _onlineMethods(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(Dimensions.paddingSizeExtraSmall)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(getTranslated('pay_via_online', context) ?? '', style: titilliumBold.copyWith(color: Theme.of(context).textTheme.bodyLarge?.color)),
        const SizedBox(height: Dimensions.paddingSizeSmall),
        Consumer<SplashController>(builder: (context, configProvider, _) {
          final methods = configProvider.configModel?.paymentMethods ?? [];
          return ListView.separated(
            padding: EdgeInsets.zero,
            itemCount: methods.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) => CustomCheckBoxWidget(
              index: index,
              padding: 0,
              icon: '${configProvider.configModel?.paymentMethodImagePath}/${methods[index].additionalDatas?.gatewayImage ?? ''}',
              name: methods[index].keyName ?? '',
              title: methods[index].additionalDatas?.gatewayTitle ?? '',
            ),
            separatorBuilder: (_, __) => const SizedBox(height: Dimensions.paddingSizeSmall),
          );
        }),
      ]),
    );
  }

  Widget _offlineMethods(BuildContext context, CheckoutController checkoutController) {
    final methods = checkoutController.offlinePaymentModel!.offlineMethods!;
    return Container(
      decoration: BoxDecoration(
        color: checkoutController.isOfflineChecked ? Theme.of(context).primaryColor.withValues(alpha: .15) : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall),
      ),
      child: Column(children: [
        CheckboxListTile(
          value: checkoutController.isOfflineChecked,
          activeColor: Colors.green,
          onChanged: (_) => checkoutController.setOfflineChecked('offline'),
          title: Text(getTranslated('pay_offline', context) ?? '', style: textBold.copyWith(color: Theme.of(context).textTheme.bodyLarge?.color)),
          controlAffinity: ListTileControlAffinity.leading,
        ),
        if (checkoutController.isOfflineChecked)
          Padding(
            padding: const EdgeInsets.fromLTRB(Dimensions.paddingSizeSmall, 0, Dimensions.paddingSizeSmall, Dimensions.paddingSizeDefault),
            child: Wrap(
              spacing: Dimensions.paddingSizeSmall,
              runSpacing: Dimensions.paddingSizeSmall,
              children: List.generate(methods.length, (index) => ChoiceChip(
                label: Text(methods[index].methodName ?? ''),
                selected: checkoutController.offlineMethodSelectedIndex == index,
                onSelected: (_) => checkoutController.setOfflinePaymentMethodSelectedIndex(index),
              )),
            ),
          ),
      ]),
    );
  }
}

bool isPrepaidMethodAvailable(ConfigModel? configModel, List<OfflineMethods>? offlineMethods, bool onlyDigital) {
  return ((configModel?.digitalPayment ?? false) && (configModel?.paymentMethods?.isNotEmpty ?? false))
      || (!onlyDigital && configModel?.offlinePayment != null && (offlineMethods?.isNotEmpty ?? false));
}
