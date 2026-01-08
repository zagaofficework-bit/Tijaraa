import 'package:Tijaraa/data/model/subscription/subscription_package_model.dart';
import 'package:Tijaraa/ui/screens/subscription/widget/planHelper.dart';
import 'package:Tijaraa/ui/theme/theme.dart';
import 'package:Tijaraa/utils/app_icon.dart';
import 'package:Tijaraa/utils/constant.dart';
import 'package:Tijaraa/utils/custom_text.dart';
import 'package:Tijaraa/utils/extensions/extensions.dart';
import 'package:Tijaraa/utils/extensions/lib/currency_formatter.dart';
import 'package:Tijaraa/utils/payment/gateaways/inapp_purchase_manager.dart';
import 'package:Tijaraa/utils/ui_utils.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;

class ItemListingSubscriptionPlansItem extends StatefulWidget {
  final int itemIndex, index;
  final SubscriptionPackageModel model;
  final InAppPurchaseManager? inAppPurchaseManager;

  const ItemListingSubscriptionPlansItem({
    super.key,
    required this.itemIndex,
    required this.index,
    required this.model,
    required this.inAppPurchaseManager,
  });

  @override
  _ItemListingSubscriptionPlansItemState createState() =>
      _ItemListingSubscriptionPlansItemState();
}

class _ItemListingSubscriptionPlansItemState
    extends State<ItemListingSubscriptionPlansItem> {
  String? _selectedGateway;

  bool get isActive => widget.model.isActive ?? false;

  bool get hasPurchasedPackage =>
      widget.model.userPurchasedPackages != null &&
      widget.model.userPurchasedPackages!.isNotEmpty;

  double get finalPrice => widget.model.finalPrice ?? 0;

  double get discount => widget.model.discount ?? 0;

  /// 🔧 Fix: Block free package if already used
  bool get isFreePackageBlocked {
    return (widget.model.finalPrice == 0) &&
        (widget.model.isFreePackageUsed ?? false);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Scaffold(
        backgroundColor: context.color.backgroundColor,
        bottomNavigationBar: bottomWidget(),
        body: Padding(
          padding: EdgeInsets.only(
            top: (widget.index == widget.itemIndex) ? 40 : 70,
            bottom: (widget.index == widget.itemIndex) ? 100 : 120,
          ),
          child: Stack(
            alignment: Alignment.topCenter,
            children: [
              if (isActive)
                ClipPath(
                  clipper: CapShapeClipper(),
                  child: Container(
                    alignment: Alignment.center,
                    color: context.color.territoryColor,
                    width: MediaQuery.of(context).size.width / 1.6,
                    height: 33,
                    padding: EdgeInsets.only(top: 3),
                    child: CustomText(
                      'activePlanLbl'.translate(context),
                      color: context.color.secondaryColor,
                      textAlign: TextAlign.center,
                      fontWeight: FontWeight.w500,
                      fontSize: 15,
                    ),
                  ),
                ),
              Card(
                color: context.color.secondaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15.0),
                  side: BorderSide(
                    color: isActive
                        ? context.color.territoryColor
                        : context.color.secondaryColor,
                    width: 1.5,
                  ),
                ),
                elevation: 0,
                margin: EdgeInsets.fromLTRB(14, 33, 14, 0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    SizedBox(height: 50),
                    ClipPath(
                      // clipper: HexagonClipper(),
                      child: Container(
                        // width: 100,
                        // height: 110,
                        // padding: EdgeInsets.all(30),
                        // color: context.color.primaryColor,
                        child: UiUtils.imageType(
                          widget.model.icon!,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    SizedBox(height: 18),
                    activeAdsData(isActive && finalPrice > 0),
                    const Spacer(),
                    CustomText(
                      finalPrice > 0
                          ? widget.model.finalPrice!.currencyFormat
                          : "free".translate(context),
                      fontSize: context.font.xxLarge,
                      fontWeight: FontWeight.bold,
                      color: context.color.textDefaultColor,
                    ),
                    if (discount > 0)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          spacing: 5,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CustomText(
                              "${widget.model.discount?.decimalFormat}%\t${"OFF".translate(context)}",
                              color: context.color.forthColor,
                              fontWeight: FontWeight.bold,
                            ),
                            Text(
                              widget.model.price?.currencyFormat ?? '',
                              style: const TextStyle(
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ],
                        ),
                      ),
                    payButtonWidget(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget activeAdsData(bool isActiveAds) {
    return Expanded(
      flex: 10,
      child: ListView(
        physics: BouncingScrollPhysics(),
        shrinkWrap: true,
        children: [
          CustomText(
            widget.model.name!,
            firstUpperCaseWidget: true,
            fontWeight: FontWeight.w600,
            fontSize: context.font.larger,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 15),
          if (widget.model.type == Constant.itemTypeListing ||
              widget.model.type == Constant.itemTypeAdvertisement) ...[
            if (isActiveAds)
              checkmarkPoint(
                context,
                "${hasPurchasedPackage ? widget.model.userPurchasedPackages![0].remainingItemLimit : "0"}/${widget.model.limit == Constant.itemLimitUnlimited ? "unlimitedLbl".translate(context) : widget.model.limit.toString()}\t${(widget.model.type == Constant.itemTypeListing ? "adsListing" : "featuredAdsListing").translate(context)}",
              )
            else
              checkmarkPoint(
                context,
                "${widget.model.limit == Constant.itemLimitUnlimited ? "unlimitedLbl".translate(context) : widget.model.limit.toString()}\t${(widget.model.type == Constant.itemTypeListing ? "adsListing" : "featuredAdsListing").translate(context)}",
              ),
          ],
          if (isActiveAds)
            checkmarkPoint(
              context,
              "${hasPurchasedPackage ? widget.model.userPurchasedPackages![0].remainingDays : "0"}/${widget.model.duration.toString()}\t${"days".translate(context)}",
            )
          else
            checkmarkPoint(
              context,
              "${widget.model.duration.toString()}\t${"days".translate(context)}",
            ),
          if (widget.model.description != null &&
              widget.model.description!.trim().isNotEmpty)
            Container(
              alignment: AlignmentDirectional.centerStart,
              padding: const EdgeInsetsDirectional.only(
                start: 20,
                end: 20,
                top: 20,
              ),
              child: CustomText(
                widget.model.description!,
                color: context.color.textDefaultColor.withValues(alpha: 0.7),
                textAlign: TextAlign.start,
              ),
            ),
        ],
      ),
    );
  }

  SingleChildRenderObjectWidget bottomWidget() {
    if (isActive &&
        finalPrice > 0 &&
        hasPurchasedPackage &&
        widget.model.userPurchasedPackages![0].endDate != null) {
      DateTime dateTime = DateTime.parse(
        widget.model.userPurchasedPackages![0].endDate!,
      );
      String formattedDate = intl.DateFormat.yMMMMd().format(dateTime);
      return Padding(
        padding: EdgeInsetsDirectional.only(bottom: 15.0, start: 15, end: 15),
        child: CustomText(
          "${"yourSubscriptionWillExpireOn".translate(context)} $formattedDate",
        ),
      );
    } else {
      return SizedBox.shrink();
    }
  }

  Widget checkmarkPoint(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      child: Row(
        spacing: 8,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          UiUtils.getSvg(AppIcons.active_mark),
          Expanded(child: CustomText(text, textAlign: TextAlign.start)),
        ],
      ),
    );
  }

  Widget payButtonWidget() {
    return PlanHelper().purchaseButtonWidget(
      context,
      widget.model,
      _selectedGateway,
      iosCallback: (String productId, String packageId) {
        widget.inAppPurchaseManager!.buy(productId, packageId);
      },
      btnTitle: isActive
          ? "purchased".translate(context)
          : isFreePackageBlocked
          ? "freePackageAlreadyUsed".translate(context)
          : "purchaseThisPackage".translate(context),
      changePaymentGateway: (String selectedPaymentGateway) {
        setState(() {
          _selectedGateway = selectedPaymentGateway;
        });
      },
      isDisabled: isFreePackageBlocked, // note: handled inside PlanHelper
    );
  }
}
