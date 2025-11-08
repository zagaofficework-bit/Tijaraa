// lib/ui/screens/home/widgets/all_items_widget.dart
import 'package:Tijaraa/app/routes.dart';
import 'package:Tijaraa/data/cubits/home/fetch_home_all_items_cubit.dart';
import 'package:Tijaraa/data/cubits/location/leaf_location_cubit.dart';
import 'package:Tijaraa/data/model/location/leaf_location.dart';
import 'package:Tijaraa/ui/screens/ad_banner_screen.dart';
import 'package:Tijaraa/ui/screens/home/widgets/grid_list_adapter.dart';
import 'package:Tijaraa/ui/screens/home/widgets/home_sections_adapter.dart';
import 'package:Tijaraa/ui/screens/native_ads_screen.dart';
import 'package:Tijaraa/ui/screens/widgets/errors/no_data_found.dart';
import 'package:Tijaraa/ui/screens/widgets/errors/no_internet.dart';
import 'package:Tijaraa/ui/screens/widgets/errors/something_went_wrong.dart';
import 'package:Tijaraa/utils/api.dart';
import 'package:Tijaraa/utils/constant.dart';
import 'package:Tijaraa/utils/extensions/extensions.dart';
import 'package:Tijaraa/utils/ui_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart' show TemplateType;

class AllItemsWidget extends StatelessWidget {
  const AllItemsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FetchHomeAllItemsCubit, FetchHomeAllItemsState>(
      builder: (context, state) {
        if (state is FetchHomeAllItemsSuccess) {
          if (state.items.isNotEmpty) {
            final int crossAxisCount = 2;
            final int items = state.items.length;
            final int total =
                (items ~/ crossAxisCount) +
                (items % crossAxisCount != 0 ? 1 : 0);

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (Constant.isGoogleBannerAdsEnabled == "1") ...[
                  Container(
                    padding: EdgeInsets.only(top: 5),
                    margin: EdgeInsets.symmetric(vertical: 10),
                    child: AdBannerWidget(), // Custom widget for banner ad
                  ),
                ] else ...[
                  SizedBox(height: 10),
                ],
                GridListAdapter(
                  type: ListUiType.List,
                  crossAxisCount: 2,
                  builder: (context, int index, bool isGrid) {
                    int itemIndex = index * crossAxisCount;
                    return SizedBox(
                      height: MediaQuery.sizeOf(context).height / 3.2,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (int i = 0; i < crossAxisCount; ++i) ...[
                            Expanded(
                              child: itemIndex + 1 <= items
                                  ? ItemCard(item: state.items[itemIndex++])
                                  : SizedBox.shrink(),
                            ),
                            if (i != crossAxisCount - 1) SizedBox(width: 15),
                          ],
                        ],
                      ),
                    );
                  },
                  listSeparator: (context, index) {
                    if (index == 0 ||
                        index % Constant.nativeAdsAfterItemNumber != 0) {
                      return SizedBox(height: 15);
                    } else {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(height: 5),
                          NativeAdWidget(type: TemplateType.medium),
                          //AdBannerWidget(),
                          SizedBox(height: 5),
                        ],
                      );
                    }
                  },
                  total: total,
                ),
                if (state.isLoadingMore) UiUtils.progress(),
              ],
            );
          } else {
            return NoDataFound(
              onTap: () async {
                final location =
                    await Navigator.pushNamed(context, Routes.locationScreen)
                        as LeafLocation?;
                if (location == null) return;

                context.read<LeafLocationCubit>().setLocation(location);
              },
              mainMsgStyle: context.font.larger,
              subMsgStyle: context.font.large,
              mainMessage: "noAdsFound".translate(context),
              subMessage: "noAdsAvailableInThisLocation".translate(context),
              showBtn: false,
              btnName: "changeLocation".translate(context),
            );
          }
        }
        if (state is FetchHomeAllItemsFail) {
          if (state.error is ApiException) {
            if (state.error.error == "no-internet") {
              return Center(child: NoInternet(onRetry: () {}));
            }
          }

          return const SomethingWentWrong();
        }
        return SizedBox.shrink();
      },
    );
  }
}
