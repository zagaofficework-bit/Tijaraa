import 'dart:async';

import 'package:Tijaraa/app/routes.dart';
import 'package:Tijaraa/data/cubits/slider_cubit.dart';
import 'package:Tijaraa/data/model/category_model.dart';
import 'package:Tijaraa/data/model/data_output.dart';
import 'package:Tijaraa/data/model/home/home_slider.dart';
import 'package:Tijaraa/data/model/item/item_model.dart';
import 'package:Tijaraa/data/repositories/item/item_repository.dart';
import 'package:Tijaraa/ui/screens/home/home_screen.dart';
import 'package:Tijaraa/utils/helper_utils.dart';
import 'package:Tijaraa/utils/ui_utils.dart';
import 'package:Tijaraa/utils/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart' as urllauncher;
import 'package:url_launcher/url_launcher.dart';

class SliderWidget extends StatefulWidget {
  const SliderWidget({super.key});

  @override
  State<SliderWidget> createState() => _SliderWidgetState();
}

class _SliderWidgetState extends State<SliderWidget>
    with AutomaticKeepAliveClientMixin {
  final ValueNotifier<int> _bannerIndex = ValueNotifier(0);
  Timer? _timer;
  int bannersLength = 0;
  final PageController _pageController = PageController();

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _bannerIndex.dispose();
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  /// Start slider only when banners are available
  void _startAutoSlider() {
    if (bannersLength == 0) return;

    _timer?.cancel(); // prevent multiple timers

    _timer = Timer.periodic(const Duration(seconds: 5), (Timer timer) {
      final nextPage = (_bannerIndex.value + 1) % bannersLength;

      _bannerIndex.value = nextPage;

      if (_pageController.hasClients) {
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return BlocBuilder<SliderCubit, SliderState>(
      builder: (context, state) {
        if (state is SliderFetchSuccess && state.sliderlist.isNotEmpty) {
          bannersLength = state.sliderlist.length;

          /// Start slider safely when data updates
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _startAutoSlider();
          });

          return SizedBox(
            height: 270,
            child: PageView.builder(
              controller: _pageController,
              itemCount: bannersLength,
              physics: const BouncingScrollPhysics(),
              onPageChanged: (index) => _bannerIndex.value = index,
              itemBuilder: (context, index) {
                final homeSlider = state.sliderlist[index];
                return InkWell(
                  onTap: () => sliderTap(homeSlider),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: sidePadding),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.grey.shade200,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: UiUtils.getImage(
                        homeSlider.image ?? "",
                        fit: BoxFit.fill,
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Future<void> sliderTap(HomeSlider homeSlider) async {
    if (homeSlider.thirdPartyLink != "") {
      await urllauncher.launchUrl(
        Uri.parse(homeSlider.thirdPartyLink!),
        mode: LaunchMode.externalApplication,
      );
    } else if (homeSlider.modelType!.contains("Category")) {
      if (homeSlider.model!.subCategoriesCount! > 0) {
        Navigator.pushNamed(
          context,
          Routes.subCategoryScreen,
          arguments: {
            "categoryList": <CategoryModel>[],
            "catName": homeSlider.model?.name?.localized,
            "catId": homeSlider.modelId,
            "categoryIds": [
              homeSlider.model!.parentCategoryId.toString(),
              homeSlider.modelId.toString(),
            ],
          },
        );
      } else {
        Navigator.pushNamed(
          context,
          Routes.itemsList,
          arguments: {
            'catID': homeSlider.modelId.toString(),
            'catName': homeSlider.model?.name?.localized,
            "categoryIds": [homeSlider.modelId.toString()],
          },
        );
      }
    } else {
      try {
        ItemRepository fetch = ItemRepository();

        LoadingWidgets.showLoader(context);

        DataOutput<ItemModel> dataOutput = await fetch.fetchItemFromItemId(
          homeSlider.modelId!,
        );

        LoadingWidgets.hideLoader(context);
        Navigator.pushNamed(
          context,
          Routes.adDetailsScreen,
          arguments: {"model": dataOutput.modelList[0]},
        );
      } catch (e) {
        LoadingWidgets.hideLoader(context);
        HelperUtils.showSnackBarMessage(context, e.toString());
      }
    }
  }
}
