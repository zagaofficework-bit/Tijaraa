import 'package:Tijaraa/app/routes.dart';
import 'package:Tijaraa/data/cubits/subscription/fetch_user_package_limit_cubit.dart';
import 'package:Tijaraa/ui/screens/widgets/bottom_navigation_bar/hexagon_shape_border.dart';
import 'package:Tijaraa/utils/constant.dart';
import 'package:Tijaraa/utils/extensions/extensions.dart';
import 'package:Tijaraa/utils/ui_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DiamondFab extends StatelessWidget {
  const DiamondFab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<FetchUserPackageLimitCubit, FetchUserPackageLimitState>(
      listener: (context, state) {
        if (state is FetchUserPackageLimitFailure) {
          UiUtils.noPackageAvailableDialog(context);
        }
        if (state is FetchUserPackageLimitInSuccess) {
          Navigator.pushNamed(
            context,
            Routes.selectCategoryScreen,
            arguments: <String, dynamic>{},
          );
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            onPressed: () {
              UiUtils.checkUser(
                onNotGuest: () {
                  if (context.read<FetchUserPackageLimitCubit>().state
                      is FetchUserPackageLimitInProgress) {
                    return;
                  }
                  context
                      .read<FetchUserPackageLimitCubit>()
                      .fetchUserPackageLimit(
                        packageType: Constant.itemTypeListing,
                      );
                },
                context: context,
              );
            },
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
            elevation: 2,
            shape: HexagonBorderShape(),
            child: Icon(Icons.add),
          ),
          const SizedBox(height: 4), // spacing between FAB and text
          Text(
            "post".translate(context),
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyLarge?.color,
              fontWeight: FontWeight.w400,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
