import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/features/address/controllers/address_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/address/widgets/address_shimmer.dart';
import 'package:flutter_sixvalley_ecommerce/features/checkout/controllers/checkout_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/shipping/controllers/shipping_controller.dart';
import 'package:flutter_sixvalley_ecommerce/helper/price_converter.dart';
import 'package:flutter_sixvalley_ecommerce/helper/route_healper.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:flutter_sixvalley_ecommerce/utill/images.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_app_bar_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/no_internet_screen_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/address/widgets/address_type_widget.dart';
import 'package:provider/provider.dart';

class SavedAddressListScreen extends StatefulWidget {
  final bool fromGuest;
  const SavedAddressListScreen({super.key,  this.fromGuest = false});

  @override
  State<SavedAddressListScreen> createState() => _SavedAddressListScreenState();
}

class _SavedAddressListScreenState extends State<SavedAddressListScreen> {

  @override
  void initState() {
    Provider.of<AddressController>(context, listen: false).getAddressList();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => RouterHelper.getAddNewAddressRoute(isBilling: false),
        backgroundColor: Theme.of(context).textTheme.bodyMedium?.color,
        child: Icon(Icons.add, color: Theme.of(context).highlightColor)),


      appBar: CustomAppBar(title: widget.fromGuest? getTranslated('ADDRESS_LIST', context) : getTranslated('SHIPPING_ADDRESS_LIST', context)),
      body: SafeArea(child: Consumer<AddressController>(
        builder: (context, locationProvider, child) {
          return SingleChildScrollView(
            child: Column(children: [
              locationProvider.addressList != null? locationProvider.addressList!.isNotEmpty ?  ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                itemCount: locationProvider.addressList?.length,
                shrinkWrap: true,
                itemBuilder: (context, index) {
                  return InkWell(onTap: () async {
                    final addressId = locationProvider.addressList![index].id;
                    if (addressId == null || !await Provider.of<ShippingController>(context, listen: false).quoteForAddress(context, addressId)) {
                      return;
                    }
                    if (!context.mounted) return;
                    final selectedOption = await showModalBottomSheet<String>(
                      context: context,
                      isScrollControlled: true,
                      builder: (sheetContext) => Consumer<ShippingController>(
                        builder: (context, shippingController, _) => SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text('اختر طريقة الشحن', style: Theme.of(context).textTheme.titleLarge),
                              const SizedBox(height: Dimensions.paddingSizeSmall),
                              const Text('تم حساب السعر من موقع العنوان الذي اخترته.'),
                              const SizedBox(height: Dimensions.paddingSizeDefault),
                              ...shippingController.quotedOptions.map((option) {
                                final key = '${option['key']}';
                                final isSigma = key == 'sigma';
                                final price = double.tryParse('${option['shipping_cost']}') ?? 0;
                                final minDays = option['minimum_business_days'] ?? '';
                                final maxDays = option['maximum_business_days'] ?? '';
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
                                  child: OutlinedButton(
                                    onPressed: shippingController.isLoading ? null : () async {
                                      if (await shippingController.selectQuoteForAddress(context, addressId, key) && sheetContext.mounted) {
                                        Navigator.pop(sheetContext, key);
                                      }
                                    },
                                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(Dimensions.paddingSizeDefault), alignment: Alignment.centerRight),
                                    child: Row(children: [
                                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                        Text(isSigma ? 'شحن سيجما' : 'شحن عادي', style: const TextStyle(fontWeight: FontWeight.bold)),
                                        Text('مدة التوصيل: $minDays - $maxDays يوم عمل'),
                                      ])),
                                      Text(PriceConverter.convertPrice(context, price), style: const TextStyle(fontWeight: FontWeight.bold)),
                                    ]),
                                  ),
                                );
                              }),
                            ]),
                          ),
                        ),
                      ),
                    );
                    if (selectedOption == null || !context.mounted) return;
                    Provider.of<CheckoutController>(context, listen: false).setAddressIndex(index);
                    Navigator.pop(context);
                    },
                    child: Padding(padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
                      child: Container(margin: const EdgeInsets.only(top: Dimensions.paddingSizeSmall),
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(10),
                          color: Theme.of(context).highlightColor,
                          border: index == Provider.of<CheckoutController>(context).addressIndex ?
                          Border.all(width: 2, color: Theme.of(context).primaryColor) : null),
                        child: AddressTypeWidget(address: locationProvider.addressList?[index]))));
                },):

              Padding(padding: EdgeInsets.only(top: MediaQuery.of(context).size.height/3),
                child: Center(child: Container(alignment: Alignment.center,
                    margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeLarge),
                    child: const NoInternetOrDataScreenWidget(isNoInternet: false,
                        message: 'no_address_found', icon: Images.noAddress)))) : const AddressShimmerWidget(),
              ],
            ),
          );
        },
      )),
    );
  }
}
