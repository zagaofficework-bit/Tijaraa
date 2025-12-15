// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:async';

import 'package:Tijaraa/app/routes.dart';
import 'package:Tijaraa/data/cubits/category/fetch_category_cubit.dart';
import 'package:Tijaraa/data/cubits/chat/blocked_users_list_cubit.dart';
import 'package:Tijaraa/data/cubits/chat/get_buyer_chat_users_cubit.dart';
import 'package:Tijaraa/data/cubits/favorite/favorite_cubit.dart';
import 'package:Tijaraa/data/cubits/home/fetch_home_all_items_cubit.dart';
import 'package:Tijaraa/data/cubits/home/fetch_home_screen_cubit.dart';
import 'package:Tijaraa/data/cubits/item/job_application/fetch_job_application_cubit.dart';
import 'package:Tijaraa/data/cubits/location/leaf_location_cubit.dart';
import 'package:Tijaraa/data/cubits/slider_cubit.dart';
import 'package:Tijaraa/data/cubits/system/fetch_system_settings_cubit.dart';
import 'package:Tijaraa/data/model/home/home_screen_section_model.dart';
import 'package:Tijaraa/data/model/location/leaf_location.dart';
import 'package:Tijaraa/data/model/system_settings_model.dart'
    show SystemSetting;
import 'package:Tijaraa/services/cloud_firestore.dart'
    show CloudFirestoreService;
import 'package:Tijaraa/ui/screens/home/Hamburger_Page_Screen.dart';
import 'package:Tijaraa/ui/screens/home/slider_widget.dart' show SliderWidget;
import 'package:Tijaraa/ui/screens/home/widgets/all_items_widget.dart';
import 'package:Tijaraa/ui/screens/home/widgets/category_widget_home.dart';
import 'package:Tijaraa/ui/screens/home/widgets/home_search.dart';
import 'package:Tijaraa/ui/screens/home/widgets/home_sections_adapter.dart';
import 'package:Tijaraa/ui/screens/home/widgets/location_widget.dart';
import 'package:Tijaraa/ui/screens/widgets/shimmer_loading_container.dart';
import 'package:Tijaraa/ui/theme/theme.dart';
import 'package:Tijaraa/utils/cloud_state/cloud_state.dart';
import 'package:Tijaraa/utils/constant.dart';
import 'package:Tijaraa/utils/designs.dart';
import 'package:Tijaraa/utils/extensions/extensions.dart';
import 'package:Tijaraa/utils/hive_utils.dart';
import 'package:Tijaraa/utils/notification/awsome_notification.dart';
import 'package:Tijaraa/utils/notification/notification_service.dart';
import 'package:Tijaraa/utils/ui_utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart'
    show Permission, PermissionCheckShortcuts, PermissionActions;

const double sidePadding = 10;

class HomeScreen extends StatefulWidget {
  final String? from;

  const HomeScreen({super.key, this.from});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen>
    with AutomaticKeepAliveClientMixin<HomeScreen> {
  @override
  bool get wantKeepAlive => true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    initializeSettings();
    notificationPermissionChecker();
    LocalAwesomeNotification().init(context);
    NotificationService.init(context);

    loadInitialInfo();

    if (HiveUtils.isUserAuthenticated()) {
      context.read<FavoriteCubit>().getFavorite();
      context.read<GetBuyerChatListCubit>().fetch();
      context.read<FetchJobApplicationCubit>().fetchApplications(
        itemId: 0,
        isMyJobApplications: true,
      );
      context.read<BlockedUsersListCubit>().blockedUsersList();
    }

    _scrollController.addListener(() {
      if (_scrollController.isEndReached()) {
        if (context.read<FetchHomeAllItemsCubit>().hasMoreData()) {
          context.read<FetchHomeAllItemsCubit>().fetchMore(
            location: HiveUtils.getLocationV2(),
          );
        }
      }
    });
  }

  void loadInitialInfo() {
    final location = context.read<LeafLocationCubit>().state;
    context.read<SliderCubit>().fetchSlider(context);
    context.read<FetchCategoryCubit>().fetchCategories();
    context.read<FetchHomeScreenCubit>().fetch(location: location);
    context.read<FetchHomeAllItemsCubit>().fetch(location: location);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void initializeSettings() {
    final settingsCubit = context.read<FetchSystemSettingsCubit>();
    if (!bool.fromEnvironment(
      Constant.forceDisableDemoMode,
      defaultValue: false,
    )) {
      Constant.isDemoModeOn =
          settingsCubit.getSetting(SystemSetting.demoMode) ?? false;
    }
  }

  Stream<int> getUnreadNotificationsCount() {
    final userId = HiveUtils.getUserId() ?? '';
    return CloudFirestoreService().unreadCountStream(userId).map((count) {
      CloudState.cloudData['unreadCount'] = count;
      return count;
    });
  }

  Future<void> markNotificationsAsRead() async {
    final userId = HiveUtils.getUserId();

    // Only call Firestore if we have a valid user ID from a successful login
    if (userId != null &&
        userId.isNotEmpty &&
        FirebaseAuth.instance.currentUser != null) {
      await CloudFirestoreService().markAllAsRead(userId);
      CloudState.cloudData['unreadCount'] = 0;
    } else {
      debugPrint("Firestore call skipped: User is not fully authenticated.");
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocListener<LeafLocationCubit, LeafLocation?>(
      listener: (context, state) {
        context.read<FetchHomeScreenCubit>().fetch(location: state);
        context.read<FetchHomeAllItemsCubit>().fetch(location: state);
      },
      child: SafeArea(
        child: Scaffold(
          drawer: const GoldMembersDrawerScreen(),
          backgroundColor: context.color.primaryColor,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.transparent,
            automaticallyImplyLeading: false,
            titleSpacing: 0,
            toolbarHeight: 60,
            title: LayoutBuilder(
              builder: (context, constraints) {
                // Define space for left and right icons
                const double iconWidth =
                    48; // width of IconButton including padding
                final double maxWidth = constraints.maxWidth - (iconWidth * 2);

                return Stack(
                  alignment: Alignment.center,
                  children: [
                    // Centered Location with max width to avoid overlap
                    ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxWidth),
                      child: const LocationWidget(),
                    ),
                    // Hamburger menu left
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        icon: Icon(
                          Icons.menu,
                          color: context.color.textDefaultColor,
                          size: 28,
                        ),
                        onPressed: () {
                          Scaffold.of(context).openDrawer();
                        },
                      ),
                    ),

                    // Notifications right
                    Align(
                      alignment: Alignment.centerRight,
                      child: StreamBuilder<int>(
                        stream: getUnreadNotificationsCount(),
                        builder: (context, snapshot) {
                          final unreadCount = snapshot.data ?? 0;
                          return IconButton(
                            icon: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Icon(
                                  Icons.notifications_none_rounded,
                                  color: context.color.textDefaultColor,
                                  size: 28,
                                ),
                                if (unreadCount > 0)
                                  Positioned(
                                    right: -2,
                                    top: -2,
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      constraints: const BoxConstraints(
                                        minWidth: 16,
                                        minHeight: 16,
                                      ),
                                      child: Text(
                                        unreadCount > 9 ? '9+' : '$unreadCount',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            onPressed: () async {
                              await Navigator.pushNamed(
                                context,
                                Routes.notificationsScreen,
                              );
                              await markNotificationsAsRead();
                            },
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          body: RefreshIndicator(
            triggerMode: RefreshIndicatorTriggerMode.anywhere,
            color: context.color.territoryColor,
            onRefresh: () async => loadInitialInfo(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              shrinkWrap: true,
              controller: _scrollController,
              padding: const EdgeInsetsDirectional.only(bottom: 30),
              children: [
                BlocBuilder<FetchHomeScreenCubit, FetchHomeScreenState>(
                  builder: (context, state) {
                    if (state is FetchHomeScreenInProgress) {
                      return shimmerEffect();
                    }
                    if (state is FetchHomeScreenSuccess) {
                      return homeScreenContent(state);
                    }
                    return const SizedBox.shrink();
                  },
                ),
                const AllItemsWidget(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget homeScreenContent(FetchHomeScreenSuccess state) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const HomeSearchField(),
        const SliderWidget(),
        const CategoryWidgetHome(),
        ...List.generate(state.sections.length, (index) {
          HomeScreenSection section = state.sections[index];
          if (state.sections.isNotEmpty) {
            return HomeSectionsAdapter(section: section);
          } else {
            return SizedBox.shrink();
          }
        }),
      ],
    );
  }

  Widget shimmerEffect() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: defaultPadding,
        vertical: 24,
      ),
      child: Column(
        children: [
          CustomShimmer(height: 52, width: double.maxFinite, borderRadius: 10),
          const SizedBox(height: 12),
          CustomShimmer(height: 170, width: double.maxFinite, borderRadius: 10),
          Container(
            height: 100,
            margin: EdgeInsetsDirectional.only(top: 12),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: 10,
              physics: NeverScrollableScrollPhysics(),
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) {
                return Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: index == 0 ? 0 : 8.0,
                  ),
                  child: const Column(
                    children: [
                      CustomShimmer(height: 70, width: 66, borderRadius: 10),
                      CustomShimmer(
                        height: 10,
                        width: 48,
                        margin: EdgeInsetsDirectional.only(top: 5),
                      ),
                      const CustomShimmer(
                        height: 10,
                        width: 60,
                        margin: EdgeInsetsDirectional.only(top: 2),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [CustomShimmer(height: 20, width: 150)],
          ),
          Container(
            height: 214,
            margin: EdgeInsets.only(top: 10),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: 5,
              physics: NeverScrollableScrollPhysics(),
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) {
                return Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: index == 0 ? 0 : 10.0,
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomShimmer(height: 147, width: 250, borderRadius: 10),
                      CustomShimmer(
                        height: 15,
                        width: 90,
                        margin: EdgeInsetsDirectional.only(top: 8),
                      ),
                      const CustomShimmer(
                        height: 14,
                        width: 230,
                        margin: EdgeInsetsDirectional.only(top: 8),
                      ),
                      const CustomShimmer(
                        height: 14,
                        width: 200,
                        margin: EdgeInsetsDirectional.only(top: 8),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          GridView.builder(
            shrinkWrap: true,
            itemCount: 16,
            physics: NeverScrollableScrollPhysics(),
            padding: EdgeInsetsDirectional.only(top: 20),
            itemBuilder: (context, index) {
              return const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomShimmer(height: 147, borderRadius: 10),
                  CustomShimmer(
                    height: 15,
                    width: 70,
                    margin: EdgeInsetsDirectional.only(top: 8),
                  ),
                  const CustomShimmer(
                    height: 14,
                    margin: EdgeInsetsDirectional.only(top: 8),
                  ),
                  const CustomShimmer(
                    height: 14,
                    width: 130,
                    margin: EdgeInsetsDirectional.only(top: 8),
                  ),
                ],
              );
            },
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              mainAxisExtent: 215,
              crossAxisCount: 2, // Single column grid
              mainAxisSpacing: 15.0,
              crossAxisSpacing: 15.0,
              // You may adjust this aspect ratio as needed
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> notificationPermissionChecker() async {
  if (!(await Permission.notification.isGranted)) {
    await Permission.notification.request();
  }
}
