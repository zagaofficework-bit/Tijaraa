import 'dart:async';
import 'dart:io';

import 'package:Tijaraa/app/routes.dart';
import 'package:Tijaraa/data/cubits/chat/get_combined_chat_users_cubit.dart';
import 'package:Tijaraa/data/cubits/system/fetch_system_settings_cubit.dart';
import 'package:Tijaraa/data/model/system_settings_model.dart';
import 'package:Tijaraa/ui/screens/chat/chat_list_screen.dart';
import 'package:Tijaraa/ui/screens/home/home_screen.dart';
import 'package:Tijaraa/ui/screens/item/my_items_screen.dart';
import 'package:Tijaraa/ui/screens/user_profile/profile_screen.dart';
import 'package:Tijaraa/ui/screens/widgets/blurred_dialog_box.dart';
import 'package:Tijaraa/ui/screens/widgets/bottom_navigation_bar/custom_bottom_navigation_bar.dart';
import 'package:Tijaraa/ui/screens/widgets/bottom_navigation_bar/diamond_fab.dart';
import 'package:Tijaraa/ui/screens/widgets/chatbot/floating_ai_moon.dart';
import 'package:Tijaraa/ui/screens/widgets/maintenance_mode.dart';
import 'package:Tijaraa/ui/theme/theme.dart';
import 'package:Tijaraa/utils/app_icon.dart';
import 'package:Tijaraa/utils/constant.dart';
import 'package:Tijaraa/utils/custom_text.dart';
import 'package:Tijaraa/utils/extensions/extensions.dart';
import 'package:Tijaraa/utils/helper_utils.dart';
import 'package:Tijaraa/utils/hive_utils.dart';
import 'package:Tijaraa/utils/ui_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

Map<String, dynamic> searchBody = {};
String selectedCategoryId = "0";
String selectedCategoryName = "";
dynamic selectedCategory;

dynamic currentVisitingCategoryId = "";
dynamic currentVisitingCategory = "";

class MainActivity extends StatefulWidget {
  final String from;
  final String? itemSlug;
  final String? sellerId;

  // FIX: Keep both keys for backward compatibility
  static final GlobalKey<MainActivityState> globalKey =
      GlobalKey<MainActivityState>();

  MainActivity({Key? key, required this.from, this.itemSlug, this.sellerId})
    : super(key: globalKey);

  @override
  State<MainActivity> createState() => MainActivityState();

  static Route route(RouteSettings routeSettings) {
    Map arguments = routeSettings.arguments as Map;
    return MaterialPageRoute(
      builder: (_) => MainActivity(
        from: arguments['from'] as String,
        itemSlug: arguments['slug'] as String?,
        sellerId: arguments['sellerId'] as String?,
      ),
    );
  }
}

class MainActivityState extends State<MainActivity> {
  final PageController _pageController = PageController();
  final BottomNavigationController _bottomNavigationController =
      BottomNavigationController();

  Timer? _timer;

  @override
  void initState() {
    super.initState();

    FetchSystemSettingsCubit settings = context
        .read<FetchSystemSettingsCubit>();
    if (!bool.fromEnvironment(
      Constant.forceDisableDemoMode,
      defaultValue: false,
    )) {
      Constant.isDemoModeOn =
          settings.getSetting(SystemSetting.demoMode) ?? false;
    }
    var numberWithSuffix = settings.getSetting(SystemSetting.numberWithSuffix);
    Constant.isNumberWithSuffix = numberWithSuffix == "1" ? true : false;

    versionCheck(settings);

    if (widget.itemSlug != null) {
      Navigator.of(context).pushNamed(
        Routes.adDetailsScreen,
        arguments: {"slug": widget.itemSlug!},
      );
    }
    if (widget.sellerId != null) {
      Navigator.pushNamed(
        context,
        Routes.sellerProfileScreen,
        arguments: {"sellerId": int.parse(widget.sellerId!)},
      );
    }

    _bottomNavigationController.addListener(() {
      _pageController.jumpToPage(_bottomNavigationController.index);
    });
  }

  void completeProfileCheck() {
    if (HiveUtils.getUserDetails().name == "" ||
        HiveUtils.getUserDetails().email == "") {
      Future.delayed(const Duration(milliseconds: 100), () {
        Navigator.pushReplacementNamed(
          context,
          Routes.completeProfile,
          arguments: {"from": "login"},
        );
      });
    }
  }

  void versionCheck(settings) async {
    var remoteVersion = settings.getSetting(
      Platform.isIOS ? SystemSetting.iosVersion : SystemSetting.androidVersion,
    );
    var remote = remoteVersion;

    var forceUpdate = settings.getSetting(SystemSetting.forceUpdate);

    PackageInfo packageInfo = await PackageInfo.fromPlatform();

    var current = packageInfo.version;

    int currentVersion = HelperUtils.comparableVersion(packageInfo.version);
    if (remoteVersion == null) {
      return;
    }

    remoteVersion = HelperUtils.comparableVersion(remoteVersion);

    print("remoteVersion***$remoteVersion****$currentVersion");

    if (remoteVersion > currentVersion) {
      Constant.isUpdateAvailable = true;
      Constant.newVersionNumber = settings.getSetting(
        Platform.isIOS
            ? SystemSetting.iosVersion
            : SystemSetting.androidVersion,
      );

      Future.delayed(Duration.zero, () {
        UiUtils.showBlurredDialoge(
          context,
          dialoge: BlurredDialogBox(
            onAccept: () async {
              await launchUrl(
                Uri.parse(
                  Platform.isAndroid
                      ? Constant.playStoreUrl
                      : Constant.appStoreUrl,
                ),
                mode: LaunchMode.externalApplication,
              );
            },
            backAllowedButton: forceUpdate != "1",
            svgImagePath: AppIcons.update,
            isAcceptContainerPush: forceUpdate == "1",
            svgImageColor: context.color.territoryColor,
            showCancelButton: forceUpdate != "1",
            title: "updateAvailable".translate(context),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (forceUpdate == "1") CustomText("$current>$remote"),
                CustomText(
                  (forceUpdate == "1"
                          ? "newVersionAvailableForce"
                          : "newVersionAvailable")
                      .translate(context),
                ),
              ],
            ),
          ),
        );
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _bottomNavigationController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final keyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    return AnnotatedRegion(
      value: UiUtils.getSystemUiOverlayStyle(
        context: context,
        statusBarColor: context.color.primaryColor,
      ),
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (_bottomNavigationController.index != 0) {
            _bottomNavigationController.changeIndex(0);
          } else {
            if (_timer == null) {
              _timer = Timer(const Duration(seconds: 2), () {
                _timer?.cancel();
                _timer = null;
              });
              HelperUtils.showSnackBarMessage(
                context,
                "pressAgainToExit".translate(context),
                isFloating: true,
              );
            } else {
              SystemNavigator.pop();
            }
          }
        },
        child: Scaffold(
          // FIX: Use mainScaffoldKey for drawer, but keep widget key as globalKey
          key: mainScaffoldKey,

          resizeToAvoidBottomInset: false,
          backgroundColor: context.color.primaryColor,

          // Add AI Chat Drawer (slides from right at 80% width)
          endDrawer: const AIChatDrawer(),

          // Hide bottom nav when keyboard is visible
          bottomNavigationBar: keyboardVisible
              ? null
              : CustomBottomNavigationBar(
                  controller: _bottomNavigationController,
                ),

          // Hide FAB when keyboard is visible
          floatingActionButton: keyboardVisible ? null : const DiamondFab(),

          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerDocked,

          body: BlocProvider<GetCombinedChatListCubit>(
            create: (context) => GetCombinedChatListCubit(),
            child: Stack(
              children: <Widget>[
                RepaintBoundary(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      HomeScreen(
                        key: const ValueKey("homeScreen"),
                        from: widget.from,
                      ),
                      const ChatListScreen(key: ValueKey("chatListScreen")),
                      const ItemsScreen(key: ValueKey("itemsScreen")),
                      const ProfileScreen(key: ValueKey("profileScreen")),
                    ],
                  ),
                ),

                if (Constant.maintenanceMode == "1") const MaintenanceMode(),

                // Floating AI Moon button (opens drawer)
                const FloatingAIMoon(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Keep this method for backward compatibility with notifications
  void onItemTapped(int index) {
    print("onItemTapped: $index");
    _bottomNavigationController.changeIndex(index);
  }
}
