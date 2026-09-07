import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/features/address/domain/models/address_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/checkout/controllers/checkout_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/location/controllers/location_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/profile/controllers/profile_contrroller.dart';
import 'package:flutter_sixvalley_ecommerce/helper/country_code_helper.dart';
import 'package:flutter_sixvalley_ecommerce/helper/egypt_location_helper.dart';
import 'package:flutter_sixvalley_ecommerce/helper/route_healper.dart';
import 'package:flutter_sixvalley_ecommerce/helper/velidate_check.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/main.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/controllers/auth_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/address/controllers/address_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/splash/controllers/splash_controller.dart';
import 'package:flutter_sixvalley_ecommerce/utill/custom_themes.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:flutter_sixvalley_ecommerce/utill/images.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_button_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_app_bar_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/show_custom_snakbar_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/success_dialog_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_textfield_widget.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

class AddNewAddressScreen extends StatefulWidget {
  final bool isEnableUpdate;
  final bool fromCheckout;
  final AddressModel? address;
  final bool? isBilling;
  const AddNewAddressScreen({super.key, this.isEnableUpdate = false, this.address, this.fromCheckout = false, this.isBilling});

  @override
  State<AddNewAddressScreen> createState() => _AddNewAddressScreenState();
}

class _AddNewAddressScreenState extends State<AddNewAddressScreen> {
  final TextEditingController _contactPersonNameController = TextEditingController();
  final TextEditingController _contactPersonEmailController = TextEditingController();
  final TextEditingController _contactPersonNumberController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _zipCodeController = TextEditingController();
  final TextEditingController _countryCodeController = TextEditingController();
  final FocusNode _addressNode = FocusNode();
  final FocusNode _nameNode = FocusNode();
  final FocusNode _emailNode = FocusNode();
  final FocusNode _numberNode = FocusNode();
  String? _selectedGovernorate;
  final FocusNode _zipNode = FocusNode();
  GoogleMapController? _controller;
  CameraPosition? _cameraPosition;
  bool _updateAddress = true;
  static const String _egyptDialCode = '+20';
  static const String _egyptCountryName = 'Egypt';
  static const LatLng _egyptCenter = LatLng(26.8206, 30.8025);
  String zip = '',  country = 'EG';
  late LatLng _defaut;

  final GlobalKey<FormState> _addressFormKey = GlobalKey();

  @override
  void initState() {
    super.initState();

    _defaut = _egyptCenter;

    // Billing addresses are not part of this checkout. Every saved address is
    // a delivery address, so users never need to choose a second type here.

    Provider.of<AuthController>(context, listen: false).setCountryCode(_egyptDialCode, notify: false);
    _countryCodeController.text = _egyptCountryName;
    Provider.of<AddressController>(context, listen: false).getAddressType();
    Provider.of<AddressController>(context, listen: false).getRestrictedDeliveryCountryList();
    Provider.of<AddressController>(context, listen: false).getRestrictedDeliveryZipList();


    _checkPermission(() => Provider.of<LocationController>(context, listen: false).getCurrentLocation(context, true, mapController: _controller), context);
    if (widget.isEnableUpdate && widget.address != null) {
      _updateAddress = false;

      Provider.of<LocationController>(context, listen: false).updateMapPosition(CameraPosition(
          target: LatLng(
            (widget.address!.latitude != null && widget.address!.latitude != '0' && widget.address!.latitude != '') ?
            double.parse(widget.address!.latitude!) : _defaut.latitude,
            (widget.address!.longitude != null && widget.address!.longitude != '0' && widget.address!.longitude != '') ?
            double.parse(widget.address!.longitude!) : _defaut.longitude,
          )), true, widget.address!.address, context);
      _contactPersonNameController.text = '${widget.address?.contactPersonName}';
      _countryCodeController.text = _egyptCountryName;
      _contactPersonEmailController.text =  '${widget.address?.email}';
      // _contactPersonNumberController.text = '${widget.address?.phone}';
      _cityController.text = '${widget.address?.city}';
      final savedGovernorate = widget.address?.state ?? _cityController.text;
      if (EgyptLocationHelper.governorates.contains(savedGovernorate)) {
        _selectedGovernorate = savedGovernorate;
      }
      _zipCodeController.text = '${widget.address?.zip}';
      if (widget.address!.addressType == 'Home') {
        Provider.of<AddressController>(context, listen: false).updateAddressIndex(0, false);
      } else if (widget.address!.addressType == 'Workplace') {
        Provider.of<AddressController>(context, listen: false).updateAddressIndex(1, false);
      } else {
        Provider.of<AddressController>(context, listen: false).updateAddressIndex(2, false);
      }
      String countryCode = _egyptDialCode;
      Provider.of<AuthController>(context, listen: false).setCountryCode(countryCode, notify: false);
      String phoneNumberOnly = CountryCodeHelper.extractPhoneNumber(countryCode, widget.address?.phone ?? '');
      _contactPersonNumberController.text = phoneNumberOnly;

    }else {
      if(Provider.of<ProfileController>(context, listen: false).userInfoModel!=null){
        _contactPersonNameController.text = '${Provider.of<ProfileController>(context, listen: false).userInfoModel!.fName ?? ''}'
            ' ${Provider.of<ProfileController>(context, listen: false).userInfoModel!.lName ?? ''}';

        String countryCode = _egyptDialCode;
        Provider.of<AuthController>(context, listen: false).setCountryCode(countryCode);
        String phoneNumberOnly = CountryCodeHelper.extractPhoneNumber(countryCode, Provider.of<ProfileController>(context, listen: false).userInfoModel!.phone ?? '');
        _contactPersonNumberController.text = phoneNumberOnly;
      }
    }
  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: widget.isEnableUpdate ? getTranslated('update_address', context) : getTranslated('add_new_address', context)),
      body: SingleChildScrollView(
        child: Column(children: [
          Consumer<AddressController>(
            builder: (context, addressController, child) {
              return Consumer<LocationController>(
                  builder: (context, locationController, _) {
                    return Padding(padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
                      child: Form(
                        key: _addressFormKey,
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [


                          Padding(padding: const EdgeInsets.only(top: Dimensions.paddingSizeLarge),
                              child: CustomTextFieldWidget(
                                required: true,
                                prefixIcon: Images.user,
                                labelText: getTranslated('enter_contact_person_name', context),
                                hintText: getTranslated('enter_contact_person_name', context),
                                inputType: TextInputType.name,
                                controller: _contactPersonNameController,
                                focusNode: _nameNode,
                                nextFocus: _numberNode,
                                inputAction: TextInputAction.next,
                                capitalization: TextCapitalization.words,
                                validator: (value)=> ValidateCheck.validateEmptyText(value, 'contact_person_name_is_required'),
                              )),

                          const SizedBox(height: Dimensions.paddingSizeDefaultAddress),
                          Consumer<AuthController>(
                              builder: (context, authProvider,_) {
                                return CustomTextFieldWidget(
                                  required: true,
                                  labelText: getTranslated('phone', context),
                                  hintText: getTranslated('enter_mobile_number', context),
                                  controller: _contactPersonNumberController,
                                  focusNode: _numberNode,
                                  nextFocus: _emailNode,
                                  showCodePicker: false,
                                  countryDialCode: _egyptDialCode,
                                  isAmount: true,
                                  validator: (value)=> ValidateCheck.validateEmptyText(value, "phone_must_be_required"),
                                  inputAction: TextInputAction.next,
                                  inputType: TextInputType.phone,
                                );
                              }
                          ),
                          const SizedBox(height: Dimensions.paddingSizeDefaultAddress),

                          if(!Provider.of<AuthController>(context, listen: false).isLoggedIn())
                            CustomTextFieldWidget(
                              required: true,
                              prefixIcon: Images.email,
                              labelText: getTranslated('email', context),
                              hintText: getTranslated('enter_contact_person_email', context),
                              inputType: TextInputType.emailAddress,
                              controller: _contactPersonEmailController,
                              focusNode: _emailNode,
                              nextFocus: _addressNode,
                              inputAction: TextInputAction.next,
                              capitalization: TextCapitalization.words,
                              validator: (value)=> ValidateCheck.validateEmail(value),
                            ),
                          const SizedBox(height: Dimensions.paddingSizeDefaultAddress),



                          Provider.of<SplashController>(context, listen: false).configModel!.mapApiStatus == 1 ?
                          SizedBox(height: MediaQuery.of(context).size.width/2, width: MediaQuery.of(context).size.width,
                              child: ClipRRect(borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall),
                                  child: Stack(clipBehavior: Clip.none, children: [
                                    GoogleMap(mapType: MapType.normal,
                                        initialCameraPosition: CameraPosition(
                                            target: widget.isEnableUpdate ?
                                            LatLng(
                                              (widget.address!.latitude != null && widget.address!.latitude != '0' && widget.address!.latitude != '') ?
                                              double.parse(widget.address!.latitude!) : _defaut.latitude,
                                              (widget.address!.longitude != null && widget.address!.longitude != '0' && widget.address!.longitude != '') ?
                                              double.parse(widget.address!.longitude!) : _defaut.longitude,
                                            ) :
                                            _isInsideEgypt(LatLng(locationController.position.latitude, locationController.position.longitude)) ? LatLng(locationController.position.latitude, locationController.position.longitude) : _egyptCenter,
                                            zoom: 16),
                                        cameraTargetBounds: CameraTargetBounds(LatLngBounds(southwest: const LatLng(21.5, 24.5), northeast: const LatLng(31.8, 37.2))),
                                        onTap: (latLng) {
                                          RouterHelper.getSelectLocationScreen(googleMapController: _controller, action: RouteAction.push);
                                        },
                                        zoomControlsEnabled: false,
                                        compassEnabled: false,
                                        indoorViewEnabled: true,
                                        mapToolbarEnabled: false,
                                        onCameraIdle: () {
                                          if(_updateAddress) {
                                            locationController.updateMapPosition(_cameraPosition, true, null, context);
                                          }else {
                                            _updateAddress = true;
                                          }
                                        },
                                        onCameraMove: ((position) => _cameraPosition = position),
                                        onMapCreated: (GoogleMapController controller) {
                                          _controller = controller;
                                          if (!widget.isEnableUpdate && _controller != null) {
                                            locationController.getCurrentLocation(context, true, mapController: _controller);
                                          }}),


                                    locationController.loading ? Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Theme
                                        .of(context).primaryColor))) : const SizedBox(),
                                    Container(width: MediaQuery.of(context).size.width, alignment: Alignment.center,
                                        height: MediaQuery.of(context).size.height,
                                        child: Icon(Icons.location_on, size: 40, color: Theme.of(context).primaryColor,)),

                                    Positioned(top: 10, right: 0,
                                      child: InkWell(onTap: () => RouterHelper.getSelectLocationScreen(googleMapController: _controller, action: RouteAction.push),
                                        child: Container(width: 30, height: 30,
                                          margin: const EdgeInsets.only(right: Dimensions.paddingSizeLarge),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall),
                                            color: Colors.white,),
                                          child: Icon(Icons.fullscreen, color: Theme.of(context).primaryColor, size: 20))))
                                  ]))) : const SizedBox(),


                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeExtraSmall),
                            child: Text(getTranslated('label_us', context)!, style: textRegular.copyWith(
                              color: Theme.of(context).hintColor,
                              fontSize: Dimensions.fontSizeLarge,
                            )),
                          ),

                          SizedBox(height: 50,
                              child: RepaintBoundary(
                                child: ListView.builder(
                                    shrinkWrap: true,
                                    scrollDirection: Axis.horizontal,
                                    physics: const BouncingScrollPhysics(),
                                    itemCount: addressController.addressTypeList.length,
                                    itemBuilder: (context, index) => InkWell(
                                        onTap: () => addressController.updateAddressIndex(index, true),
                                        child: Container(padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeDefault, horizontal: Dimensions.paddingSizeLarge),
                                            margin: const EdgeInsets.only(right: 17),
                                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall),
                                                border: Border.all(color: addressController.selectAddressIndex == index ?
                                                Theme.of(context).primaryColor : Theme.of(context).primaryColor.withValues(alpha:.125))),
                                            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                              SizedBox(width: 20, child: Image.asset(addressController.addressTypeList[index].icon,
                                                  color: addressController.selectAddressIndex == index ?
                                                  Theme.of(context).primaryColor : Theme.of(context).primaryColor.withValues(alpha:.35))),
                                              const SizedBox(width: Dimensions.paddingSizeSmall,),
                                              Text(getTranslated(addressController.addressTypeList[index].title, context)!,
                                                  style: textRegular.copyWith())])))),
                              )),

                          CustomTextFieldWidget(labelText: getTranslated('delivery_address', context),
                            hintText: getTranslated('usa', context),
                            inputType: TextInputType.streetAddress,
                            inputAction: TextInputAction.next,
                            focusNode: _addressNode,
                            prefixIcon: Images.address,
                            required: true,
                            nextFocus: _zipNode,
                            controller: locationController.locationController,
                            validator: (value)=> ValidateCheck.validateEmptyText(value, "address_is_required"),


                          ),
                          const SizedBox(height: Dimensions.paddingSizeDefaultAddress),

                          ...[
                            Text(getTranslated('country', context)!, style: textRegular.copyWith(
                              color: Theme.of(context).hintColor,
                              fontSize: Dimensions.fontSizeSmall,
                            )),
                            const SizedBox(height: Dimensions.paddingSizeExtraSmall),


                            SizedBox(height: 60,
                                child: Consumer<AddressController>(
                                    builder: (context, addressController, _) {
                                      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                                        Container(width: MediaQuery.of(context).size.width,
                                          padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                                          decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(5), border: Border.all(width: .1, color: Theme.of(context).hintColor.withValues(alpha:0.1))),
                                          child: Row(children: [
                                              Image.asset(Images.country),
                                              const SizedBox(width: Dimensions.paddingSizeSmall),
                                              Text(_egyptCountryName, style: textRegular.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).textTheme.bodyLarge!.color)),
                                          ]),
                                        ),
                                      ]);})),
                          ],




                          const SizedBox(height: Dimensions.paddingSizeDefaultAddress),
                          DropdownButtonFormField<String>(
                            initialValue: _selectedGovernorate,
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: getTranslated('governorate', context),
                              border: const OutlineInputBorder(),
                              prefixIcon: Image.asset(Images.city),
                            ),
                            hint: Text(getTranslated('governorate', context) ?? 'Governorate'),
                            items: EgyptLocationHelper.governorates.map((governorate) => DropdownMenuItem<String>(
                              value: governorate,
                              child: Text(governorate, style: textRegular.copyWith(fontSize: Dimensions.fontSizeDefault)),
                            )).toList(),
                            validator: (value) => value == null ? getTranslated('governorate_is_required', context) : null,
                            onChanged: (value) => setState(() {
                              _selectedGovernorate = value;
                            }),
                            icon: Icon(Icons.arrow_drop_down, color: Theme.of(context).hintColor),
                          ),

                          const SizedBox(height: Dimensions.paddingSizeDefaultAddress),
                          CustomTextFieldWidget(
                            required: true,
                            prefixIcon: Images.city,
                            labelText: getTranslated('city', context),
                            hintText: getTranslated('city', context),
                            inputType: TextInputType.text,
                            controller: _cityController,
                            focusNode: _zipNode,
                            inputAction: TextInputAction.next,
                            validator: (value) => ValidateCheck.validateEmptyText(value, 'city_is_required'),
                          ),
                          const SizedBox(height: Dimensions.paddingSizeDefaultAddress),


                          Provider.of<SplashController>(context, listen: false).configModel!.deliveryZipCodeAreaRestriction == 0 ?
                          CustomTextFieldWidget(
                            labelText: getTranslated('zip', context),
                            hintText: getTranslated('zip', context),
                            inputAction: TextInputAction.done,
                            focusNode: _zipNode,
                            required: false,
                            prefixIcon: Images.city,
                            controller: _zipCodeController,
                          ) :
                          Container(width: MediaQuery.of(context).size.width,
                            decoration: BoxDecoration(color: Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(5),
                                border: Border.all(width: .1, color: Theme.of(context).hintColor.withValues(alpha:0.1))),
                            child: DropdownButtonFormField2<String>(
                              isExpanded: true,
                              isDense: true,
                              decoration: InputDecoration(contentPadding: const EdgeInsets.symmetric(vertical: 0),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(5))),
                              hint:  Row(children: [
                                Image.asset(Images.city),
                                const SizedBox(width: Dimensions.paddingSizeSmall,),
                                Text(getTranslated('zip', context)!, style: textRegular.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).textTheme.bodyLarge!.color)),
                              ],
                              ),
                              items: addressController.restrictedZipList.map((item) => DropdownItem<String>(
    value: item.zipcode ?? '', child: Text(item.zipcode ?? '', style: textRegular.copyWith(fontSize: Dimensions.fontSizeSmall)))).toList(),
                              onChanged: (value) {
                                _zipCodeController.text = value!;

                              },
                              
                              iconStyleData: IconStyleData(
                                  icon: Icon(Icons.arrow_drop_down, color: Theme.of(context).hintColor), iconSize: 24),
                              dropdownStyleData: DropdownStyleData(
                                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(5))),
                              menuItemStyleData: const MenuItemStyleData(padding: EdgeInsets.symmetric(horizontal: 16)),
                            ),
                          ),
                          const SizedBox(height: Dimensions.paddingSizeDefaultAddress),

                          Container(height: 50.0,
                            margin: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                            child: CustomButton(
                              isLoading: addressController.isLoading,
                              buttonText: widget.isEnableUpdate ? getTranslated('update_address', context) : getTranslated('save_location', context),
                              onTap: locationController.loading ? null : () {

                                if (!_isInsideEgypt(LatLng(locationController.position.latitude, locationController.position.longitude))) {
                                  showCustomSnackBarWidget(getTranslated('select_address_inside_egypt', context) ?? '', Get.context!, snackBarType: SnackBarType.warning);
                                  return;
                                }

                                if(_addressFormKey.currentState?.validate() ?? false) {
                                  AddressModel addressModel = AddressModel(
                                    addressType: addressController.addressTypeList[addressController.selectAddressIndex].title,
                                    contactPersonName: _contactPersonNameController.text,
                                    phone: '${Provider.of<AuthController>(context, listen: false).countryDialCode}${_contactPersonNumberController.text.trim()}',
                                    email: _contactPersonEmailController.text.trim(),
                                    // The API retains city for backwards compatibility; state
                                    // carries the explicit governorate used by Egypt shipping.
                                    state: _selectedGovernorate,
                                    city: _cityController.text,
                                    zip: _zipCodeController.text,
                                    country:  _countryCodeController.text,
                                    guestId: Provider.of<AuthController>(context, listen: false).getGuestToken(),
                                    isBilling: false,
                                    address: locationController.locationController.text,
                                    latitude: widget.isEnableUpdate ? locationController.position.latitude.toString() : locationController.position.latitude.toString(),
                                    longitude: widget.isEnableUpdate ? locationController.position.longitude.toString() : locationController.position.longitude.toString(),
                                  );


                                  if (widget.isEnableUpdate) {
                                    addressModel.id = widget.address!.id;
                                    addressController.updateAddress(context, addressModel: addressModel, addressId: addressModel.id);

                                  }else if(_countryCodeController.text.trim().isEmpty){
                                    showCustomSnackBarWidget(getTranslated('country_is_required', context), Get.context!, snackBarType: SnackBarType.warning);
                                  } else {
                                    addressController.addAddress(addressModel).then((value) {
                                      if (value.response?.statusCode == 200 ) {
                                        if(context.mounted) {
                                          Navigator.pop(context);
                                        }
                                        if (widget.fromCheckout) {
                                          if(context.mounted){
                                            Provider.of<CheckoutController>(context, listen: false).setAddressIndex(0);
                                          }
                                        }
                                      }
                                    });
                                  }

                                }
                              },
                            ),
                          ),


                        ]),
                      ),
                    );
                  }
              );
            },
          ),
        ],
        ),
      ),
    );
  }

  static bool _isInsideEgypt(LatLng point) => point.latitude >= 21.5 && point.latitude <= 31.8 && point.longitude >= 24.5 && point.longitude <= 37.2;
  void _checkPermission(Function callback, BuildContext context) async {
    LocationPermission permission = await Geolocator.requestPermission();
    if(permission == LocationPermission.denied || permission == LocationPermission.whileInUse) {
      InkWell(onTap: () async{
        Navigator.pop(context);
        await Geolocator.requestPermission();
        _checkPermission(callback,  Get.context!);
      },
          child: AlertDialog(content: SuccessDialog(icon: Icons.location_on_outlined, title: '',
              description: getTranslated('you_denied', Get.context!))));
    }else if(permission == LocationPermission.deniedForever) {
      InkWell(onTap: () async{
        if(context.mounted){}
        Navigator.pop(context);
        await Geolocator.openAppSettings();
        _checkPermission(callback, Get.context!);
      },
          child: AlertDialog(content: SuccessDialog(icon: Icons.location_on_outlined, title: '',
              description: getTranslated('you_denied', Get.context!))));
    }else {
      callback();
    }
  }
}

enum Address {shipping, billing }

