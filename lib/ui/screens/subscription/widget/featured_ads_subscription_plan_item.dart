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

class FeaturedAdsSubscriptionPlansItem extends StatefulWidget {
  final List<SubscriptionPackageModel> modelList;
  final InAppPurchaseManager? inAppPurchaseManager;

  const FeaturedAdsSubscriptionPlansItem({
    super.key,
    required this.modelList,
    required this.inAppPurchaseManager,
  });

  @override
  _FeaturedAdsSubscriptionPlansItemState createState() =>
      _FeaturedAdsSubscriptionPlansItemState();
}

class _FeaturedAdsSubscriptionPlansItemState
    extends State<FeaturedAdsSubscriptionPlansItem> {
  String? _selectedGateway;
  int? selectedIndex;

  @override
  void initState() {
    super.initState();
  }

  Widget mainUi() {
    return Container(
      height: MediaQuery.of(context).size.height,
      margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      child: Card(
        color: context.color.secondaryColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18.0),
        ),
        elevation: 0,
        child: Column(
          children: [
            const SizedBox(height: 50),
            UiUtils.getSvg(AppIcons.featuredAdsIcon),
            const SizedBox(height: 35),
            CustomText(
              "featureAd".translate(context),
              fontWeight: FontWeight.w600,
              fontSize: context.font.larger,
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                itemCount: widget.modelList.length,
                itemBuilder: (context, index) => itemData(index),
              ),
            ),
            if (selectedIndex != null) payButtonWidget(),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Scaffold(
        backgroundColor: context.color.backgroundColor,
        body: mainUi(),
      ),
    );
  }

  Widget itemData(int index) {
    final plan = widget.modelList[index];
    final bool isFreePackageBlocked =
        (plan.finalPrice == 0) && (plan.isFreePackageUsed ?? false);
    final bool isSelected = index == selectedIndex;

    return Padding(
      padding: const EdgeInsets.only(top: 7.0),
      child: Stack(
        alignment: Alignment.topLeft,
        children: [
          if (plan.isActive!)
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 13.0),
              child: ClipPath(
                clipper: CapShapeClipper(),
                child: Container(
                  color: context.color.territoryColor,
                  width: MediaQuery.of(context).size.width / 3,
                  height: 17,
                  padding: const EdgeInsets.only(top: 3),
                  child: CustomText(
                    'activePlanLbl'.translate(context),
                    color: context.color.secondaryColor,
                    textAlign: TextAlign.center,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          InkWell(
            onTap: plan.isActive! || isFreePackageBlocked
                ? null
                : () {
                    setState(() {
                      selectedIndex = index;
                    });
                  },
            child: Container(
              margin: const EdgeInsets.only(top: 17),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16.0),
                border: Border.all(
                  color: plan.isActive! || isSelected
                      ? context.color.territoryColor
                      : context.color.textDefaultColor.withValues(alpha: 0.13),
                  width: 1.5,
                ),
                color: isFreePackageBlocked
                    ? context.color.textDefaultColor.withValues(alpha: 0.05)
                    : null,
              ),
              child: plan.isActive!
                  ? activeAdsWidget(index)
                  : adsWidget(index, isFreePackageBlocked),
            ),
          ),
        ],
      ),
    );
  }

  Widget adsWidget(int index, bool isDisabled) {
    final plan = widget.modelList[index];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(
                plan.name!,
                firstUpperCaseWidget: true,
                fontWeight: FontWeight.w600,
                fontSize: context.font.large,
                color: isDisabled
                    ? context.color.textDefaultColor.withAlpha(100)
                    : null,
              ),
              const SizedBox(height: 5),
              CustomText(
                '${plan.limit == Constant.itemLimitUnlimited ? "unlimitedLbl".translate(context) : plan.limit}\t${"adsLbl".translate(context)} · ${plan.duration}\t${"days".translate(context)}',
                color: isDisabled
                    ? context.color.textDefaultColor.withAlpha(100)
                    : context.color.textDefaultColor.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
        CustomText(
          plan.finalPrice! > 0
              ? plan.finalPrice!.currencyFormat
              : "free".translate(context),
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: isDisabled
              ? context.color.textDefaultColor.withAlpha(100)
              : null,
        ),
      ],
    );
  }

  Widget activeAdsWidget(int index) {
    final plan = widget.modelList[index];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(
                plan.name!,
                firstUpperCaseWidget: true,
                fontWeight: FontWeight.w600,
                fontSize: context.font.large,
              ),
              const SizedBox(height: 5),
              Text.rich(
                TextSpan(
                  text: plan.limit == Constant.itemLimitUnlimited
                      ? "${"unlimitedLbl".translate(context)} ${"adsLbl".translate(context)} · "
                      : '',
                  style: TextStyle(
                    color: context.color.textDefaultColor.withValues(
                      alpha: 0.5,
                    ),
                  ),
                  children: textRichChildNotForUnlimited(
                    plan.limit == Constant.itemLimitUnlimited,
                    '${plan.userPurchasedPackages![0].remainingItemLimit}',
                    '/${plan.limit} ${"adsLbl".translate(context)} · ',
                  ),
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              Text.rich(
                TextSpan(
                  text: plan.duration == Constant.itemLimitUnlimited
                      ? "${"unlimitedLbl".translate(context)} ${"days".translate(context)}"
                      : '',
                  style: TextStyle(
                    color: context.color.textDefaultColor.withValues(
                      alpha: 0.5,
                    ),
                  ),
                  children: textRichChildNotForUnlimited(
                    plan.duration == Constant.itemLimitUnlimited,
                    '${plan.userPurchasedPackages![0].remainingDays}',
                    '/${plan.duration} ${"days".translate(context)}',
                  ),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        CustomText(
          plan.finalPrice! > 0
              ? "${Constant.currencySymbol}${plan.finalPrice}"
              : "free".translate(context),
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ],
    );
  }

  List<InlineSpan>? textRichChildNotForUnlimited(
    bool isUnlimited,
    String text1,
    String text2,
  ) {
    if (isUnlimited) return null;
    return [
      TextSpan(
        text: text1,
        style: TextStyle(color: context.color.textDefaultColor),
      ),
      TextSpan(text: text2),
    ];
  }

  Widget payButtonWidget() {
    if (selectedIndex == null) return const SizedBox.shrink();

    final plan = widget.modelList[selectedIndex!];

    final bool isFreePackageBlocked =
        (plan.finalPrice == 0) && (plan.isFreePackageUsed ?? false);

    return PlanHelper().purchaseButtonWidget(
      context,
      plan,
      _selectedGateway,
      iosCallback: (String productId, String packageId) {
        widget.inAppPurchaseManager!.buy(productId, packageId);
      },
      changePaymentGateway: (String selectedPaymentGateway) {
        setState(() {
          _selectedGateway = selectedPaymentGateway;
        });
      },
      isDisabled: isFreePackageBlocked || plan.isActive!,
      btnTitle: plan.isActive!
          ? "purchased".translate(context)
          : isFreePackageBlocked
          ? "freePackageAlreadyUsed".translate(context)
          : null,
    );
  }
}
