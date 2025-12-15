import 'package:Tijaraa/app/routes.dart';
import 'package:Tijaraa/data/cubits/system/app_theme_cubit.dart';
import 'package:Tijaraa/data/cubits/system/fetch_system_settings_cubit.dart';
import 'package:Tijaraa/data/model/system_settings_model.dart';
import 'package:Tijaraa/ui/theme/theme.dart';
import 'package:Tijaraa/utils/custom_text.dart';
import 'package:Tijaraa/utils/extensions/extensions.dart';
import 'package:Tijaraa/utils/hive_keys.dart';
import 'package:Tijaraa/utils/hive_utils.dart';
import 'package:Tijaraa/utils/ui_utils.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hive/hive.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int currentPageIndex = 0;
  int previousPageIndex = 0;
  double changedOnPageScroll = 0.5;
  double currentSwipe = 0;
  late int totalPages;
  double x = 0;
  double y = 0;
  ValueNotifier<Offset> values = ValueNotifier(const Offset(0, 0));

  @override
  void dispose() {
    values.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List slidersList = [
      {
        'svg': "assets/svg/Illustrators/onbo_a.svg",
        'title': "onboarding_1_title".translate(context),
        'description': "onboarding_1_des".translate(context),
      },
      {
        'svg': "assets/svg/Illustrators/onbo_b.svg",
        'title': "onboarding_2_title".translate(context),
        'description': "onboarding_2_des".translate(context),
      },
      {
        'svg': "assets/svg/Illustrators/onbo_c.svg",
        'title': "onboarding_3_title".translate(context),
        'description': "onboarding_3_des".translate(context),
      },
    ];

    totalPages = slidersList.length;

    double heightFactor = 0.79;
    return AnnotatedRegion(
      value: UiUtils.getSystemUiOverlayStyle(
        context: context,
        statusBarColor: context.color.secondaryColor,
      ),
      child: Scaffold(
        backgroundColor: context.color.backgroundColor,
        body: Column(
          spacing: 10,
          children: [
            Stack(
              children: <Widget>[
                Container(height: context.screenHeight * (heightFactor + 0.05)),
                Positioned.directional(
                  textDirection: Directionality.of(context),
                  child: ValueListenableBuilder(
                    valueListenable: values,
                    builder: (context, Offset value, c) {
                      return CustomPaint(
                        isComplex: true,
                        size: Size(
                          context.screenWidth,
                          context.screenHeight * heightFactor,
                        ),
                        painter: BottomCurvePainter(),
                      );
                    },
                  ),
                ),
                if ((context.read<FetchSystemSettingsCubit>().getSetting(
                              SystemSetting.language,
                            )
                            as List)
                        .length >
                    1)
                  PositionedDirectional(
                    top: kPagingTouchSlop,
                    start: 26,
                    child: TextButton(
                      onPressed: () async {
                        Navigator.pushNamed(
                          context,
                          Routes.languageListScreenRoute,
                        );
                      },
                      child: StreamBuilder(
                        stream: Hive.box(
                          HiveKeys.languageBox,
                        ).watch(key: HiveKeys.currentLanguageKey),
                        builder: (context, AsyncSnapshot<BoxEvent> value) {
                          final defaultLanguage = context
                              .watch<FetchSystemSettingsCubit>()
                              .getSetting(SystemSetting.defaultLanguage)
                              .toString()
                              .firstUpperCase();

                          final languageCode =
                              value.data?.value?['code'] ??
                              defaultLanguage ??
                              "En";

                          return Row(
                            children: [
                              CustomText(
                                languageCode,
                                color: context.color.textColorDark,
                              ),
                              Icon(
                                Icons.keyboard_arrow_down_sharp,
                                color: context.color.territoryColor,
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                PositionedDirectional(
                  top: kPagingTouchSlop,
                  end: 26,
                  child: MaterialButton(
                    onPressed: () {
                      HiveUtils.setUserIsNotNew();
                      HiveUtils.setUserSkip();

                      Navigator.pushReplacementNamed(
                        context,
                        Routes.main,
                        arguments: {"from": "login", "isSkipped": true},
                      );
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    color: context.color.forthColor.withValues(alpha: 0.102),
                    elevation: 0,
                    height: 28,
                    minWidth: 64,
                    child: CustomText(
                      "skip".translate(context),
                      color: context.color.forthColor,
                    ),
                  ),
                ),
                Positioned.directional(
                  textDirection: Directionality.of(context),
                  top: kPagingTouchSlop + 50,
                  child: GestureDetector(
                    onHorizontalDragUpdate: (DragUpdateDetails details) {
                      currentSwipe = details.localPosition.direction;
                      setState(() {});
                    },
                    onHorizontalDragEnd: (DragEndDetails details) {
                      if (currentSwipe < 0.9) {
                        if (changedOnPageScroll == 1 ||
                            changedOnPageScroll == 0.5) {
                          if (currentPageIndex > 0) {
                            currentPageIndex--;
                            changedOnPageScroll = 0;
                          }
                        }
                        //setState(() {});
                      } else {
                        if (currentPageIndex < totalPages) {
                          if (changedOnPageScroll == 0 ||
                              changedOnPageScroll == 0.5) {
                            if (currentPageIndex < slidersList.length - 1) {
                              currentPageIndex++;
                            } else {
                              // Navigator.of(context).pushNamedAndRemoveUntil(
                              //     Routes.login, (route) => false);
                            }
                            //setState(() {});
                          }
                        }
                      }

                      changedOnPageScroll = 0.5;
                      setState(() {});
                    },
                    child: SizedBox(
                      width: context.screenWidth,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        child: Column(
                          children: <Widget>[
                            SizedBox(height: 60),
                            SizedBox(
                              width: context.screenWidth,
                              height: 221,
                              child: SvgPicture.asset(
                                slidersList[currentPageIndex]['svg'],
                              ),
                            ),
                            SizedBox(height: 39),
                            SizedBox(
                              width: context.screenWidth,
                              child: CustomText(
                                slidersList[currentPageIndex]['title'],
                                fontSize: context.font.extraLarge,
                                fontWeight: FontWeight.w600,
                                color: context.color.textDefaultColor,
                                textAlign: TextAlign.center,
                              ),
                            ),
                            SizedBox(height: 14),
                            SizedBox(
                              width: context.screenWidth,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 13,
                                ),
                                child: CustomText(
                                  slidersList[currentPageIndex]['description'],
                                  textAlign: TextAlign.center,
                                  fontSize: context.font.larger,
                                ),
                              ),
                            ),
                            SizedBox(height: 24),
                            IndicatorBuilder(
                              total: totalPages,
                              selectedIndex: currentPageIndex,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned.directional(
                  textDirection: Directionality.of(context),
                  top: context.screenHeight * ((0.636 * heightFactor) / 0.68),
                  start: (context.screenWidth / 2) - 70 / 2,
                  child: GestureDetector(
                    onTap: () {
                      if (currentPageIndex < slidersList.length - 1) {
                        currentPageIndex++;
                      } else {
                        Navigator.of(context).pushNamedAndRemoveUntil(
                          Routes.login,
                          (route) => false,
                        );
                      }
                      HiveUtils.setUserIsNotNew();
                      setState(() {});
                    },
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: context.color.forthColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_forward,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                boxShadow: context.read<AppThemeCubit>().isDarkMode()
                    ? null
                    : [
                        BoxShadow(
                          color: context.color.territoryColor.withValues(
                            alpha: 0.3,
                          ),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
              ),
              child: MaterialButton(
                onPressed: () {
                  HiveUtils.setUserIsNotNew();
                  Navigator.of(
                    context,
                  ).pushNamedAndRemoveUntil(Routes.login, (route) => false);
                },
                height: 56,
                minWidth: 201,
                color: context.color.territoryColor,
                // Button color
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                child: CustomText(
                  currentPageIndex < slidersList.length - 1
                      ? "signIn".translate(context)
                      : "getStarted".translate(context),
                  color: context.color.buttonColor,
                  fontSize: context.font.larger,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class IndicatorBuilder extends StatelessWidget {
  final int total;
  final int selectedIndex;

  const IndicatorBuilder({
    super.key,
    required this.total,
    required this.selectedIndex,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 10,
      child: ListView.separated(
        shrinkWrap: true,
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          return Container(
            width: selectedIndex == index ? 24 : 10,
            height: 10,
            decoration: BoxDecoration(
              color: context.color.territoryColor,
              borderRadius: BorderRadius.circular(6),
            ),
          );
        },
        separatorBuilder: (context, index) {
          return const SizedBox(width: 7);
        },
        itemCount: total,
      ),
    );
  }
}

class BottomCurvePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint();
    Path path = Path();

    // Path number 1

    paint.color = const Color(0xffffffff);
    path = Path();

    path.lineTo(0, 0);
    path.cubicTo(0, 0, 0, size.height, 0, size.height);
    path.cubicTo(
      0,
      size.height,
      size.width * 0.26,
      size.height,
      size.width * 0.26,
      size.height,
    );
    path.cubicTo(
      size.width * 0.35,
      size.height,
      size.width * 0.36,
      size.height * 0.98,
      size.width * 0.38,
      size.height * 0.95,
    );
    path.cubicTo(
      size.width * 0.38,
      size.height * 0.94,
      size.width * 0.41,
      size.height * 0.89,
      size.width / 2,
      size.height * 0.89,
    );
    path.cubicTo(
      size.width * 0.58,
      size.height * 0.89,
      size.width * 0.6,
      size.height * 0.93,
      size.width * 0.61,
      size.height * 0.94,
    );
    path.cubicTo(
      size.width * 0.63,
      size.height * 0.97,
      size.width * 0.63,
      size.height,
      size.width * 0.72,
      size.height,
    );
    path.cubicTo(
      size.width * 0.72,
      size.height,
      size.width,
      size.height,
      size.width,
      size.height,
    );
    path.cubicTo(size.width, size.height, size.width, 0, size.width, 0);
    path.cubicTo(size.width, 0, 0, 0, 0, 0);
    path.cubicTo(0, 0, 0, 0, 0, 0);
    canvas.drawShadow(
      path,
      Colors.grey.withValues(alpha: 0.1),
      6.0, // Shadow radius
      true, // Whether to include the shape itself in the shadow calculation
    );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
