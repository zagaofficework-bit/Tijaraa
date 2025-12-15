import 'dart:async';
import 'dart:developer';

import 'package:Tijaraa/app/routes.dart';
import 'package:Tijaraa/data/cubits/system/fetch_language_cubit.dart';
import 'package:Tijaraa/data/cubits/system/fetch_system_settings_cubit.dart';
import 'package:Tijaraa/data/cubits/system/language_cubit.dart';
import 'package:Tijaraa/data/model/system_settings_model.dart';
import 'package:Tijaraa/ui/screens/widgets/errors/no_internet.dart';
import 'package:Tijaraa/ui/theme/theme.dart';
import 'package:Tijaraa/utils/constant.dart';
import 'package:Tijaraa/utils/extensions/extensions.dart';
import 'package:Tijaraa/utils/hive_utils.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({this.itemSlug, super.key, this.sellerId});

  //Used when the app is terminated and then is opened using deep link, in which case
  //the main route needs to be added to navigation stack, previously it directly used to
  //push adDetails route.
  final String? itemSlug;
  final String? sellerId;

  @override
  SplashScreenState createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  bool isTimerCompleted = false;
  bool isSettingsLoaded = false;
  bool isLanguageLoaded = false;
  late StreamSubscription<List<ConnectivityResult>> subscription;
  bool hasInternet = true;

  @override
  void initState() {
    super.initState();

    subscription = Connectivity().onConnectivityChanged.listen((result) {
      setState(() {
        hasInternet = (!result.contains(ConnectivityResult.none));
      });
      if (hasInternet) {
        context.read<FetchSystemSettingsCubit>().fetchSettings(
          forceRefresh: true,
        );
        startTimer();
      }
    });
  }

  @override
  void dispose() {
    subscription.cancel();
    super.dispose();
  }

  Future _getDefaultLanguage({
    required String defaultCode,
    required String currentCode,
  }) async {
    try {
      final languageData = Map<String, dynamic>.from(
        HiveUtils.getLanguage() ?? {},
      );
      if (languageData.isNotEmpty && languageData['code'] == currentCode) {
        context.read<FetchLanguageCubit>().setLanguage(languageData);
        isLanguageLoaded = true;
        setState(() {});
      } else {
        context.read<FetchLanguageCubit>().getLanguage(defaultCode);
      }
    } catch (e, st) {
      log("Error while load default language $e");
      log('$st');
    }
  }

  Future<void> startTimer() async {
    Timer(const Duration(seconds: 1), () {
      isTimerCompleted = true;
      if (mounted) setState(() {});
    });
  }

  void navigateCheck() {
    if (isTimerCompleted && isSettingsLoaded && isLanguageLoaded) {
      navigateToScreen();
    }
  }

  void navigateToScreen() async {
    if (context.read<FetchSystemSettingsCubit>().getSetting(
          SystemSetting.maintenanceMode,
        ) ==
        "1") {
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed(Routes.maintenanceMode);
        }
      });
    } else if (HiveUtils.isUserFirstTime()) {
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed(Routes.onboarding);
        }
      });
    } else if (HiveUtils.isUserAuthenticated()) {
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          //We pass slug only when the user is authenticated otherwise drop the slug
          Navigator.of(context).pushReplacementNamed(
            Routes.main,
            arguments: {
              'from': "main",
              "slug": widget.itemSlug,
              "sellerId": widget.sellerId,
            },
          );
        }
      });
    } else {
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          if (HiveUtils.isUserSkip()) {
            Navigator.of(context).pushReplacementNamed(
              Routes.main,
              arguments: {
                'from': "main",
                "slug": widget.itemSlug,
                "sellerId": widget.sellerId,
              },
            );
          } else {
            Navigator.of(context).pushReplacementNamed(Routes.login);
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    navigateCheck();

    return hasInternet
        ? BlocListener<FetchLanguageCubit, FetchLanguageState>(
            listener: (context, state) {
              if (state is FetchLanguageSuccess) {
                Map<String, dynamic> map = state.toMap();

                var data = map['file_name'];
                map['data'] = data;
                map.remove("file_name");

                HiveUtils.storeLanguage(map);
                context.read<LanguageCubit>().changeLanguages(map);
                isLanguageLoaded = true;
                if (mounted) setState(() {});
              }
            },
            child:
                BlocListener<
                  FetchSystemSettingsCubit,
                  FetchSystemSettingsState
                >(
                  listener: (context, state) {
                    if (state is FetchSystemSettingsSuccess) {
                      Constant.isDemoModeOn = context
                          .read<FetchSystemSettingsCubit>()
                          .getSetting(SystemSetting.demoMode);

                      _getDefaultLanguage(
                        defaultCode: state.settings['data']['default_language'],
                        currentCode: state.settings['data']['current_language'],
                      );

                      isSettingsLoaded = true;
                      if (mounted) setState(() {});
                    }

                    if (state is FetchSystemSettingsFailure) {
                      log('${state.errorMessage}');
                    }
                  },
                  child: SafeArea(
                    top: false,
                    child: AnnotatedRegion<SystemUiOverlayStyle>(
                      value: SystemUiOverlayStyle(
                        statusBarColor: context.color.territoryColor,
                        statusBarIconBrightness: Brightness.light,
                        systemNavigationBarIconBrightness: Brightness.light,
                        systemNavigationBarColor: context.color.territoryColor,
                      ),
                      child: Scaffold(
                        backgroundColor: context.color.territoryColor,
                        body: Stack(
                          children: [
                            // Center content: splash logo and app name
                            Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    alignment: Alignment.center,
                                    width: 300,
                                    height: 300,
                                    child: Image.asset(
                                      'assets/svg/Logo/logo.png',
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
          )
        : NoInternet(
            onRetry: () {
              setState(() {});
            },
          );
  }
}
