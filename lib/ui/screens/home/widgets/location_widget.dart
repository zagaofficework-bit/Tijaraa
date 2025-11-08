import 'package:Tijaraa/app/routes.dart';
import 'package:Tijaraa/data/cubits/location/leaf_location_cubit.dart';
import 'package:Tijaraa/data/model/location/leaf_location.dart';
import 'package:Tijaraa/ui/screens/home/home_screen.dart';
import 'package:Tijaraa/ui/theme/theme.dart';
import 'package:Tijaraa/utils/app_icon.dart';
import 'package:Tijaraa/utils/custom_text.dart';
import 'package:Tijaraa/utils/extensions/extensions.dart';
import 'package:Tijaraa/utils/ui_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LocationWidget extends StatefulWidget {
  const LocationWidget({super.key});

  @override
  State<LocationWidget> createState() => _LocationWidgetState();
}

class _LocationWidgetState extends State<LocationWidget> {
  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 10,
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () async {
            final location =
                await Navigator.of(context).pushNamed(Routes.locationScreen)
                    as LeafLocation?;

            if (location == null) return;

            context.read<LeafLocationCubit>().setLocation(location);
          },
          // Expanded(
          child: BlocBuilder<LeafLocationCubit, LeafLocation?>(
            builder: (context, state) {
              final location = state;
              return Row(
                spacing: sidePadding,
                // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: context.color.secondaryColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: UiUtils.getSvg(
                      AppIcons.location,
                      fit: BoxFit.none,
                      color: context.color.territoryColor,
                    ),
                  ),
                  Column(
                    children: [
                      CustomText(
                        location?.primaryText ??
                            "locationLbl".translate(context),
                        color: context.color.textColorDark,
                        fontSize: context.font.normal,
                        fontWeight: FontWeight.w600,
                      ),
                      if (location?.secondaryText != null)
                        CustomText(
                          location!.secondaryText!,
                          softWrap: true,
                          overflow: TextOverflow.ellipsis,
                          fontSize: context.font.small,
                          maxLines: 2,
                        ),
                      if (location == null || location.isEmpty)
                        CustomText(
                          'Global',
                          softWrap: true,
                          overflow: TextOverflow.ellipsis,
                          fontSize: context.font.small,
                          maxLines: 2,
                        ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),

        // ),
        SizedBox(width: 10),
      ],
    );
  }
}
