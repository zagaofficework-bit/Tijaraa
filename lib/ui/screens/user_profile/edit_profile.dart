import 'dart:io';

import 'package:Tijaraa/app/routes.dart';
import 'package:Tijaraa/data/cubits/auth/auth_cubit.dart';
import 'package:Tijaraa/data/cubits/auth/authentication_cubit.dart';
import 'package:Tijaraa/data/cubits/slider_cubit.dart';
import 'package:Tijaraa/data/cubits/system/user_details.dart';
import 'package:Tijaraa/data/model/user/user_model.dart';
import 'package:Tijaraa/ui/screens/widgets/custom_text_form_field.dart';
import 'package:Tijaraa/ui/theme/theme.dart';
import 'package:Tijaraa/utils/app_icon.dart';
import 'package:Tijaraa/utils/constant.dart';
import 'package:Tijaraa/utils/custom_text.dart';
import 'package:Tijaraa/utils/extensions/extensions.dart';
import 'package:Tijaraa/utils/helper_utils.dart';
import 'package:Tijaraa/utils/hive_utils.dart';
import 'package:Tijaraa/utils/image_picker.dart';
import 'package:Tijaraa/utils/ui_utils.dart';
import 'package:country_picker/country_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

class UserProfileScreen extends StatefulWidget {
  final String from;
  final bool? navigateToHome;
  final bool? popToCurrent;

  //final AuthenticationType? type;

  const UserProfileScreen({
    super.key,
    required this.from,
    this.navigateToHome,
    this.popToCurrent,
    //required this.type,
  });

  @override
  State<UserProfileScreen> createState() => UserProfileScreenState();

  static Route route(RouteSettings routeSettings) {
    final arguments = routeSettings.arguments as Map<dynamic, dynamic>?;

    // safely convert to Map<String, dynamic>
    final typedArguments = arguments?.map(
      (key, value) => MapEntry(key.toString(), value),
    );

    return MaterialPageRoute(
      builder: (_) => UserProfileScreen(
        from: typedArguments?['from']?.toString() ?? '',
        // provide default if null
        popToCurrent: typedArguments?['popToCurrent'] as bool? ?? false,
        navigateToHome: typedArguments?['navigateToHome'] as bool? ?? false,
      ),
    );
  }
}

class UserProfileScreenState extends State<UserProfileScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController phoneController = TextEditingController();
  late final TextEditingController nameController = TextEditingController();
  late final TextEditingController emailController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  late final TextEditingController dobController = TextEditingController();
  late final TextEditingController nationalityController = TextEditingController();
  String? selectedGender;
  dynamic size;
  dynamic city, _state, country;
  double? latitude, longitude;
  String? name, email, address;
  File? fileUserimg;
  bool isNotificationsEnabled = true;
  bool isPersonalDetailShow = true;
  bool? isLoading;
  String? countryCode = "+${Constant.defaultCountryCode}";
  final ImagePicker picker = ImagePicker();
  PickImage profileImagePicker = PickImage();
  bool isFromLogin = false;
  bool isEmailVerified = false;
  bool isVerifying = false;
  bool isPhoneVerified = false;
  bool isVerifyingPhone = false;
  String? verificationId;

  @override
  void initState() {
    super.initState();
    isFromLogin = widget.from == 'login';
    city = HiveUtils.getCityName();
    _state = HiveUtils.getStateName();
    country = HiveUtils.getCountryName();
    latitude = HiveUtils.getLatitude();
    longitude = HiveUtils.getLongitude();

    nameController.text = (HiveUtils.getUserDetails().name) ?? "";
    emailController.text = HiveUtils.getUserDetails().email ?? "";
    addressController.text = HiveUtils.getUserDetails().address ?? "";
    dobController.text = HiveUtils.getUserDetails().dob ?? "";
    nationalityController.text = HiveUtils.getUserDetails().nationality ?? "";
    selectedGender = HiveUtils.getUserDetails().gender;

    if (isFromLogin) {
      isNotificationsEnabled = true;
      isPersonalDetailShow = true;
    } else {
      isNotificationsEnabled = HiveUtils.getUserDetails().notification == 1
          ? true
          : false;
      isPersonalDetailShow =
          HiveUtils.getUserDetails().isPersonalDetailShow == 1 ? true : false;
    }

    if (HiveUtils.getCountryCode() != null) {
      countryCode = HiveUtils.getCountryCode() ?? '';
      phoneController.text = HiveUtils.getUserDetails().mobile != null
          ? HiveUtils.getUserDetails().mobile!.replaceFirst("+$countryCode", "")
          : "";
    } else {
      phoneController.text = HiveUtils.getUserDetails().mobile != null
          ? HiveUtils.getUserDetails().mobile!
          : "";
    }

    profileImagePicker.listener((files) {
      if (files != null && files.isNotEmpty) {
        setState(() {
          fileUserimg = files.first; // Assign picked image to fileUserimg
        });
      }
    });
  }

  @override
  void dispose() {
    profileImagePicker.dispose();
    phoneController.dispose();
    nameController.dispose();
    emailController.dispose();
    addressController.dispose();
    dobController.dispose();
    nationalityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    size = MediaQuery.of(context).size;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: safeAreaCondition(
        child: Scaffold(
          backgroundColor: context.color.primaryColor,
          appBar: isFromLogin
              ? null
              : UiUtils.buildAppBar(context, showBackButton: true),
          body: SafeArea(
            child: Stack(
              children: [
                Column(
                  children: [
                    // Scrollable content
                    Expanded(
                      child: ScrollConfiguration(
                        behavior: RemoveGlow(),
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.all(20.0),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              spacing: 10,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Align(
                                  alignment: AlignmentDirectional.center,
                                  child: buildProfilePicture(),
                                ),
                                buildTextField(
                                  context,
                                  readOnly: [
                                    AuthenticationType.email.name,
                                    AuthenticationType.google.name,
                                    AuthenticationType.apple.name,
                                  ].contains(HiveUtils.getUserDetails().type),
                                  title: "fullName",
                                  controller: nameController,
                                  validator: CustomTextFieldValidator.nullCheck,
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CustomText(
                                      "emailAddress".translate(context),
                                      color: context.color.textDefaultColor,
                                    ),
                                    CustomTextFormField(
                                      controller: emailController,
                                      isReadOnly:
                                          [
                                            AuthenticationType.email.name,
                                            AuthenticationType.google.name,
                                            AuthenticationType.apple.name,
                                          ].contains(
                                            HiveUtils.getUserDetails().type,
                                          ),
                                      validator: CustomTextFieldValidator.email,
                                      fillColor: context.color.secondaryColor,
                                      suffix: isVerifying
                                          ? const Padding(
                                              padding: EdgeInsets.all(10),
                                              child: SizedBox(
                                                width: 20,
                                                height: 20,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                    ),
                                              ),
                                            )
                                          : IconButton(
                                              icon: Icon(
                                                isEmailVerified
                                                    ? Icons.verified
                                                    : Icons.verified_outlined,
                                                color: isEmailVerified
                                                    ? Colors.green
                                                    : context
                                                          .color
                                                          .territoryColor,
                                              ),
                                              onPressed: isEmailVerified
                                                  ? null
                                                  : () {
                                                      if (emailController
                                                          .text
                                                          .isEmpty) {
                                                        HelperUtils.showSnackBarMessage(
                                                          context,
                                                          "Please enter your email first.",
                                                        );
                                                      } else {
                                                        sendVerificationEmail();
                                                      }
                                                    },
                                            ),
                                    ),
                                  ],
                                ),
                                phoneWidget(),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CustomText(
                                      "addressLbl".translate(context),
                                      color: context.color.textDefaultColor,
                                    ),
                                    CustomTextFormField(
                                      controller: addressController,
                                      fillColor: context.color.secondaryColor,
                                      maxLine: 5,
                                      action: TextInputAction.newline,
                                      hintText: "Enter your address",
                                      suffix: isLoading == true
                                          ? Padding(
                                              padding: const EdgeInsets.all(
                                                12.0,
                                              ),
                                              child: SizedBox(
                                                width: 18,
                                                height: 18,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                    ),
                                              ),
                                            )
                                          : IconButton(
                                              onPressed: fetchAndSetAddress,
                                              icon: Icon(
                                                Icons.my_location,
                                                color: context
                                                    .color
                                                    .territoryColor,
                                              ),
                                            ),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CustomText("dob".translate(context)),
                                    const SizedBox(height: 10),
                                    GestureDetector(
                                      onTap: () async {
                                        DateTime? pickedDate =
                                            await showDatePicker(
                                              context: context,
                                              initialDate: DateTime.now(),
                                              firstDate: DateTime(1900),
                                              lastDate: DateTime.now(),
                                            );
                                        if (pickedDate != null) {
                                          setState(() {
                                            dobController.text =
                                                "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
                                          });
                                        }
                                      },
                                      child: AbsorbPointer(
                                        child: CustomTextFormField(
                                          controller: dobController,
                                          isReadOnly: true,
                                          hintText: "YYYY-MM-DD",
                                          fillColor:
                                              context.color.secondaryColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                buildTextField(
                                  context,
                                  title: "nationality",
                                  controller: nationalityController,
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CustomText("gender".translate(context)),
                                    const SizedBox(height: 10),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: context.color.secondaryColor,
                                        borderRadius: BorderRadius.circular(
                                          10,
                                        ),
                                        border: Border.all(
                                          color: context.color.textLightColor
                                              .withValues(alpha: 0.3),
                                          width: 1.5,
                                        ),
                                      ),
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<String>(
                                          value: selectedGender,
                                          isExpanded: true,
                                          dropdownColor:
                                              context.color.secondaryColor,
                                          items: ["Male", "Female", "Other"]
                                              .map(
                                                (e) => DropdownMenuItem(
                                                  value: e,
                                                  child: CustomText(e),
                                                ),
                                              )
                                              .toList(),
                                          onChanged: (val) {
                                            setState(() {
                                              selectedGender = val;
                                            });
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                CustomText("notification".translate(context)),
                                buildEnableDisableSwitch(
                                  isNotificationsEnabled,
                                  (cgvalue) {
                                    isNotificationsEnabled = cgvalue;
                                    setState(() {});
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Fixed bottom button
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: updateProfileBtnWidget(),
                    ),
                  ],
                ),

                if (isLoading != null && isLoading!)
                  Center(
                    child: UiUtils.progress(
                      normalProgressColor: context.color.territoryColor,
                    ),
                  ),

                if (isFromLogin)
                  Positioned(left: 10, top: 10, child: BackButton()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> fetchAndSetAddress() async {
    setState(() => isLoading = true);

    try {
      // Request permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          HelperUtils.showSnackBarMessage(
            context,
            "Location permission denied",
          );
          setState(() => isLoading = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        HelperUtils.showSnackBarMessage(
          context,
          "Location permissions are permanently denied",
        );
        setState(() => isLoading = false);
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Reverse geocode
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        String fullAddress =
            "${place.street}, ${place.subLocality}, ${place.locality}, ${place.administrativeArea}, ${place.country}";

        // Update text field and location variables
        setState(() {
          addressController.text = fullAddress;
          city = place.locality ?? "";
          _state = place.administrativeArea ?? "";
          country = place.country ?? "";
          latitude = position.latitude;
          longitude = position.longitude;
        });
      }
    } catch (e) {
      HelperUtils.showSnackBarMessage(context, "Error fetching location: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> sendVerificationEmail() async {
    final email = emailController.text.trim();

    if (email.isEmpty) {
      HelperUtils.showSnackBarMessage(
        context,
        "Please enter your email first.",
      );
      return;
    }

    setState(() => isVerifying = true);

    try {
      // 1️⃣ Call backend or API to send OTP
      await context.read<AuthCubit>().sendEmailOtp(email);

      setState(() => isVerifying = false);

      // 2️⃣ Show OTP input dialog
      final otpController = TextEditingController();

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text("Email Verification"),
          content: TextField(
            controller: otpController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            decoration: const InputDecoration(
              labelText: "Enter 6-digit OTP",
              counterText: "",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                final otp = otpController.text.trim();
                if (otp.isEmpty) {
                  HelperUtils.showSnackBarMessage(context, "Please enter OTP");
                  return;
                }
                Navigator.pop(context);
                await verifyEmailOtp(otp);
              },
              child: const Text("Verify"),
            ),
          ],
        ),
      );
    } catch (e) {
      setState(() => isVerifying = false);
      HelperUtils.showSnackBarMessage(
        context,
        "Failed to send verification email: $e",
      );
    }
  }

  Future<void> verifyEmailOtp(String otp) async {
    final email = emailController.text.trim();

    setState(() => isVerifying = true);
    try {
      // 3️⃣ Verify OTP through your AuthCubit / repository
      await context.read<AuthCubit>().verifyEmailOtp(email, otp);

      setState(() {
        isEmailVerified = true;
        isVerifying = false;
      });

      HelperUtils.showSnackBarMessage(context, "Email verified successfully!");
    } catch (e) {
      setState(() => isVerifying = false);
      HelperUtils.showSnackBarMessage(
        context,
        "Invalid OTP. Please try again.",
      );
    }
  }

  Widget phoneWidget() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          "phoneNumber".translate(context),
          color: context.color.textDefaultColor,
        ),
        CustomTextFormField(
          controller: phoneController,
          validator: CustomTextFieldValidator.phoneNumber,
          keyboard: TextInputType.phone,
          isReadOnly:
              HiveUtils.getUserDetails().type == AuthenticationType.phone.name,
          fillColor: context.color.secondaryColor,
          onChange: (value) {
            setState(() {});
          },
          isMobileRequired: false,
          fixedPrefix: GestureDetector(
            onTap: () {
              if (HiveUtils.getUserDetails().type !=
                  AuthenticationType.phone.name) {
                showCountryCode();
              }
            },
            child: Container(
              width: 55,
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8),
              alignment: Alignment.center,
              child: CustomText(
                formatCountryCode(countryCode!),
                fontSize: context.font.large,
                textAlign: TextAlign.center,
              ),
            ),
          ),
          hintText: "phoneNumber".translate(context),
          suffix: isVerifyingPhone
              ? const Padding(
                  padding: EdgeInsets.all(10),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : IconButton(
                  icon: Icon(
                    isPhoneVerified ? Icons.verified : Icons.verified_outlined,
                    color: isPhoneVerified ? Colors.green : Colors.grey,
                  ),
                  onPressed: isPhoneVerified
                      ? null
                      : () async {
                          if (phoneController.text.trim().isEmpty) {
                            HelperUtils.showSnackBarMessage(
                              context,
                              "Please enter your phone number.",
                            );
                            return;
                          }
                          await sendPhoneVerification();
                        },
                ),
        ),
      ],
    );
  }

  /// Send OTP using API
  Future<void> sendPhoneVerification() async {
    setState(() => isVerifyingPhone = true);

    try {
      final phone = phoneController.text.trim();

      await context.read<AuthCubit>().sendPhoneOtp(phone, countryCode!);

      setState(() => isVerifyingPhone = false);

      _showOtpDialog(phone);
    } catch (e) {
      setState(() => isVerifyingPhone = false);
      HelperUtils.showSnackBarMessage(context, e.toString());
    }
  }

  /// OTP dialog
  void _showOtpDialog(String phone) {
    final otpController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Verify Phone Number"),
        content: TextField(
          controller: otpController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: "Enter OTP"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await verifyPhoneOtp(phone, otpController.text.trim());
            },
            child: const Text("Verify"),
          ),
        ],
      ),
    );
  }

  /// Verify OTP using API
  Future<void> verifyPhoneOtp(String phone, String otp) async {
    setState(() => isVerifyingPhone = true);

    try {
      await context.read<AuthCubit>().verifyPhoneOtp(phone, otp);

      setState(() {
        isPhoneVerified = true;
        isVerifyingPhone = false;
      });

      HelperUtils.showSnackBarMessage(context, "Phone number verified!");
    } catch (e) {
      setState(() => isVerifyingPhone = false);
      HelperUtils.showSnackBarMessage(
        context,
        "Invalid OTP. Please try again.",
      );
    }
  }

  String formatCountryCode(String countryCode) {
    if (countryCode.startsWith('+')) {
      return countryCode;
    } else {
      return '+$countryCode';
    }
  }

  Widget safeAreaCondition({required Widget child}) {
    if (isFromLogin) {
      return SafeArea(child: child);
    }
    return child;
  }

  Widget buildEnableDisableSwitch(bool value, Function(bool) onChangeFunction) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: context.color.textLightColor.withValues(alpha: 0.23),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(10),
        color: context.color.secondaryColor,
      ),
      height: 60,
      width: double.infinity,
      padding: const EdgeInsetsDirectional.only(start: 16.0),
      child: Row(
        spacing: 16,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CustomText(
            (value ? "enabled" : "disabled").translate(context),
            fontSize: context.font.large,
            color: context.color.textDefaultColor,
          ),
          CupertinoSwitch(
            activeTrackColor: context.color.territoryColor,
            value: value,
            onChanged: onChangeFunction,
          ),
        ],
      ),
    );
  }

  Widget buildTextField(
    BuildContext context, {
    required String title,
    required TextEditingController controller,
    CustomTextFieldValidator? validator,
    bool? readOnly,
    int? maxline,
    TextInputAction? textInputAction,
  }) {
    return Column(
      spacing: 10,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          title.translate(context),
          color: context.color.textDefaultColor,
        ),
        CustomTextFormField(
          controller: controller,
          isReadOnly: readOnly,
          validator: validator,
          // formaters: [FilteringTextInputFormatter.deny(RegExp(","))],
          fillColor: context.color.secondaryColor,
          action: textInputAction,
          maxLine: maxline,
        ),
      ],
    );
  }

  Widget getProfileImage() {
    if (fileUserimg != null) {
      return Image.file(fileUserimg!, fit: BoxFit.cover);
    } else {
      if (isFromLogin) {
        if (HiveUtils.getUserDetails().profile != null &&
            HiveUtils.getUserDetails().profile!.trim().isNotEmpty) {
          return UiUtils.getImage(
            HiveUtils.getUserDetails().profile!,
            fit: BoxFit.cover,
          );
        }

        return UiUtils.getSvg(
          AppIcons.defaultPersonLogo,
          color: context.color.territoryColor,
          fit: BoxFit.none,
        );
      } else if ((HiveUtils.getUserDetails().profile ?? "").trim().isEmpty) {
        return UiUtils.getSvg(
          AppIcons.defaultPersonLogo,
          color: context.color.territoryColor,
          fit: BoxFit.none,
        );
      } else {
        return UiUtils.getImage(
          HiveUtils.getUserDetails().profile!,
          fit: BoxFit.cover,
        );
      }
    }
  }

  Widget buildProfilePicture() {
    return Stack(
      children: [
        Container(
          height: 124,
          width: 124,
          alignment: AlignmentDirectional.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: context.color.territoryColor, width: 2),
          ),
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: context.color.territoryColor.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            width: 106,
            height: 106,
            child: getProfileImage(),
          ),
        ),
        PositionedDirectional(
          bottom: 0,
          end: 0,
          child: InkWell(
            onTap: showPicker,
            child: Container(
              height: 37,
              width: 37,
              alignment: AlignmentDirectional.center,
              decoration: BoxDecoration(
                border: Border.all(
                  color: context.color.buttonColor,
                  width: 1.5,
                ),
                shape: BoxShape.circle,
                color: context.color.territoryColor,
              ),
              child: SizedBox(
                width: 15,
                height: 15,
                child: UiUtils.getSvg(AppIcons.edit),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> validateData() async {
    if (_formKey.currentState!.validate()) {
      if (isFromLogin) {
        HiveUtils.setUserIsAuthenticated(true);
      }
      profileUpdateProcess();
    }
  }

  void profileUpdateProcess() async {
    setState(() {
      isLoading = true;
    });

    try {
      var response = await context.read<AuthCubit>().updateUserData(
        name: nameController.text.trim(),
        email: emailController.text.trim(),
        fileUserImg: fileUserimg,
        address: addressController.text,
        mobile: phoneController.text,
        notification: isNotificationsEnabled == true ? "1" : "0",
        countryCode: countryCode,
        personalDetail: isPersonalDetailShow == true ? 1 : 0,
        dob: dobController.text,
        nationality: nationalityController.text,
        gender: selectedGender,
      );

      Future.delayed(Duration.zero, () {
        context.read<UserDetailsCubit>().copy(
          UserModel.fromJson(response['data']),
        );

        setState(() {
          isLoading = false;
        });

        HelperUtils.showSnackBarMessage(context, response['message']);

        if (!isFromLogin) {
          Navigator.pop(context);
        }
      });

      if (isFromLogin) {
        Future.delayed(Duration.zero, () {
          if (widget.popToCurrent ?? false) {
            Navigator.of(context)
              ..pop()
              ..pop();
          } else if (HiveUtils.getCityName() != null &&
              HiveUtils.getCityName().toString().trim().isNotEmpty) {
            HelperUtils.killPreviousPages(context, Routes.main, {
              "from": widget.from,
            });
          } else {
            Navigator.of(context).pushNamedAndRemoveUntil(
              Routes.locationPermissionScreen,
              (route) => false,
            );
          }
        });
      }
    } catch (e) {
      Future.delayed(Duration.zero, () {
        setState(() {
          isLoading = false;
        });
        HelperUtils.showSnackBarMessage(context, e.toString());
      });
    }
  }

  void showPicker() {
    UiUtils.imagePickerBottomSheet(
      context,
      isRemovalWidget: fileUserimg != null && isFromLogin,
      callback: (bool isRemoved, ImageSource? source) async {
        if (isRemoved) {
          setState(() {
            fileUserimg = null;
          });
        } else if (source != null) {
          await profileImagePicker.pick(
            context: context,
            source: source,
            pickMultiple: false,
          );
        }
      },
    );
  }

  void showCountryCode() {
    showCountryPicker(
      context: context,
      showWorldWide: false,
      showPhoneCode: true,
      countryListTheme: CountryListThemeData(
        borderRadius: BorderRadius.circular(11),
      ),
      onSelect: (Country value) {
        countryCode = value.phoneCode;
        setState(() {});
      },
    );
  }

  Widget updateProfileBtnWidget() {
    return UiUtils.buildButton(
      context,
      outerPadding: EdgeInsetsDirectional.only(top: 15),
      onPressed: () {
        if (!isFromLogin && city != null && city != "") {
          HiveUtils.setCurrentLocation(
            city: city,
            state: _state,
            country: country,
            latitude: latitude,
            longitude: longitude,
          );

          context.read<SliderCubit>().fetchSlider(context);
        } else if (!isFromLogin) {
          HiveUtils.clearLocation();
          context.read<SliderCubit>().fetchSlider(context);
        }

        validateData();
      },
      height: 48,
      buttonTitle: "updateProfile".translate(context),
    );
  }
}
