import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/features/profile/controllers/profile_contrroller.dart';
import 'package:flutter_sixvalley_ecommerce/features/support/controllers/support_ticket_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/support/widgets/support_ticket_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/support/widgets/support_ticket_shimmer.dart';
import 'package:flutter_sixvalley_ecommerce/features/support/widgets/support_ticket_type_widget.dart';
import 'package:flutter_sixvalley_ecommerce/helper/route_healper.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/controllers/auth_controller.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:flutter_sixvalley_ecommerce/utill/images.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_app_bar_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_button_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/no_internet_screen_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/not_loggedin_widget.dart';
import 'package:provider/provider.dart';


class SupportTicketScreen extends StatefulWidget {
  final bool isBackButtonExist;
  final bool fromDashboard;

  const SupportTicketScreen({
    super.key,
    this.isBackButtonExist = true,
    this.fromDashboard = false,
  });
  @override
  State<SupportTicketScreen> createState() => _SupportTicketScreenState();
}

class _SupportTicketScreenState extends State<SupportTicketScreen> {
  @override
  void initState() {
    if (Provider.of<AuthController>(context, listen: false).isLoggedIn()) {
      Provider.of<SupportTicketController>(context, listen: false).getSupportTicketList();
      if(Provider.of<ProfileController>(context, listen: false).userInfoModel == null) {
        Provider.of<ProfileController>(context, listen: false).getUserInfo(context);
      }
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: getTranslated('inbox', context),
        isBackButtonExist: widget.isBackButtonExist && !widget.fromDashboard,
      ),
      bottomNavigationBar: Provider.of<AuthController>(context, listen: false).isLoggedIn() ?
      SizedBox(height: 70, child: Padding(
        padding: const EdgeInsets.all(Dimensions.paddingSizeEight),
        child: CustomButton(
          radius: Dimensions.paddingSizeExtraSmall,
          buttonText: getTranslated('add_new_ticket', context),
          onTap: (){
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (con) => const SupportTicketTypeWidget(),
            );
          },
        ),
      )) : const SizedBox(),
      body: Consumer<SupportTicketController>(
        builder: (context, support, child) {
          return Provider.of<AuthController>(context, listen: false).isLoggedIn()?
          support.supportTicketList != null ?
          support.supportTicketList!.isNotEmpty?
          RefreshIndicator(
            onRefresh: () async => await support.getSupportTicketList(),
            child: Builder(builder: (context) {
              final pendingActivations = support.supportTicketList!.where((ticket) =>
                ticket.purpose == 'account_activation' && ticket.reviewStatus != 'approved').toList();
              final pendingActivation = pendingActivations.isEmpty ? null : pendingActivations.first;
              final bannerOffset = pendingActivation == null ? 0 : 1;
              return ListView.separated(
              itemCount: support.supportTicketList!.length + bannerOffset,
              itemBuilder: (context, index) {
                if (pendingActivation != null && index == 0) {
                  return Container(
                    margin: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                    padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                    decoration: BoxDecoration(color: Colors.red.shade700, borderRadius: BorderRadius.circular(8)),
                    child: Text(getTranslated('customer_activation_support_message', context) ??
                      'Please complete account activation with support.', style: const TextStyle(color: Colors.white)),
                  );
                }
                final ticketIndex = index - bannerOffset;
                return SupportTicketWidget(supportTicketModel: support.supportTicketList![ticketIndex], index: ticketIndex);
              },
              separatorBuilder: (BuildContext context, int index) => const SizedBox(height: Dimensions.paddingSizeExtraSmall),
            );}),
          ) : const NoInternetOrDataScreenWidget(isNoInternet: false, icon: Images.noTicket,
            message: 'no_ticket_created') : const SupportTicketShimmer() : NotLoggedInWidget(
            message: getTranslated('to_communicate_with_vendors', context),
            fromPage: widget.fromDashboard ? '${RouterHelper.dashboardScreen}?page=inbox' : RouterHelper.supportTicketScreen,
            onLoginSuccess: () {
              RouterHelper.getSupportTicketRoute(action: RouteAction.pushReplacement);
            }
          );
        },
      ),
    );
  }
}



