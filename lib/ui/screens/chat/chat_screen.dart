import 'dart:async';
import 'dart:io';

import 'package:Tijaraa/app/routes.dart';
import 'package:Tijaraa/data/cubits/add_item_review_cubit.dart';
import 'package:Tijaraa/data/cubits/chat/block_user_cubit.dart';
import 'package:Tijaraa/data/cubits/chat/blocked_users_list_cubit.dart';
import 'package:Tijaraa/data/cubits/chat/delete_message_cubit.dart';
import 'package:Tijaraa/data/cubits/chat/get_buyer_chat_users_cubit.dart';
import 'package:Tijaraa/data/cubits/chat/get_seller_chat_users_cubit.dart';
import 'package:Tijaraa/data/cubits/chat/load_chat_messages.dart';
import 'package:Tijaraa/data/cubits/chat/send_message.dart';
import 'package:Tijaraa/data/cubits/chat/unblock_user_cubit.dart';
import 'package:Tijaraa/data/model/chat/chat_user_model.dart';
import 'package:Tijaraa/data/model/data_output.dart';
import 'package:Tijaraa/data/model/item/item_model.dart';
import 'package:Tijaraa/data/repositories/item/item_repository.dart';
import 'package:Tijaraa/ui/screens/chat/chat_audio/widgets/chat_widget.dart';
import 'package:Tijaraa/ui/screens/chat/chat_audio/widgets/record_button.dart';
import 'package:Tijaraa/ui/screens/widgets/animated_routes/transparant_route.dart';
import 'package:Tijaraa/ui/screens/widgets/blurred_dialog_box.dart';
import 'package:Tijaraa/ui/theme/theme.dart';
import 'package:Tijaraa/utils/app_icon.dart';
import 'package:Tijaraa/utils/constant.dart';
import 'package:Tijaraa/utils/custom_hero_animation.dart';
import 'package:Tijaraa/utils/custom_text.dart';
import 'package:Tijaraa/utils/extensions/extensions.dart';
import 'package:Tijaraa/utils/extensions/lib/currency_formatter.dart';
import 'package:Tijaraa/utils/helper_utils.dart';
import 'package:Tijaraa/utils/hive_utils.dart';
import 'package:Tijaraa/utils/notification/chat_message_handler.dart';
import 'package:Tijaraa/utils/notification/notification_service.dart';
import 'package:Tijaraa/utils/ui_utils.dart';
import 'package:Tijaraa/utils/widgets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

int totalMessageCount = 0;

ValueNotifier<bool> showDeleteButton = ValueNotifier<bool>(false);

ValueNotifier<int> selectedMessageId = ValueNotifier<int>(-5);

class ChatScreen extends StatefulWidget {
  final String? from;
  final int itemOfferId;
  final double? itemOfferPrice;
  final String? itemPrice;
  final String profilePicture;
  final String userName;
  final String itemImage;
  final String itemTitle;
  final String userId;
  final String itemId;
  final String date;
  final String? status;
  final String? buyerId;
  final int isPurchased;
  final bool alreadyReview;
  final bool? isFromBuyerList;

  const ChatScreen({
    super.key,
    required this.profilePicture,
    required this.userName,
    required this.itemImage,
    required this.itemTitle,
    required this.userId,
    required this.itemId,
    required this.date,
    this.from,
    required this.itemOfferId,
    this.status,
    this.itemPrice,
    this.itemOfferPrice,
    this.buyerId,
    required this.isPurchased,
    required this.alreadyReview,
    this.isFromBuyerList,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _recordButtonAnimation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  );
  TextEditingController controller = TextEditingController();
  PlatformFile? messageAttachment;
  bool isFetchedFirstTime = false;
  double scrollPositionWhenLoadMore = 0;
  late Stream<PermissionStatus> notificationStream = notificationPermission();
  late StreamSubscription notificationStreamSubscription;
  bool isNotificationPermissionGranted = true;
  bool showRecordButton = true;
  int _rating = 0;
  final TextEditingController _feedbackController = TextEditingController();
  late final ScrollController _pageScrollController = ScrollController()
    ..addListener(() {
      if (_pageScrollController.offset >=
          _pageScrollController.position.maxScrollExtent) {
        if (context.read<LoadChatMessagesCubit>().hasMoreChat()) {
          setState(() {});
          context.read<LoadChatMessagesCubit>().loadMore();
        }
      }
    });
  bool isLoading = false;
  bool _showAttachmentOptions = false;

  @override
  void initState() {
    super.initState();
    context.read<LoadChatMessagesCubit>().load(itemOfferId: widget.itemOfferId);

    currentlyChatItemId = widget.itemId;
    currentlyChatingWith = widget.userId;
    notificationStreamSubscription = notificationStream.listen((
      PermissionStatus permissionStatus,
    ) {
      isNotificationPermissionGranted = permissionStatus.isGranted;
      if (mounted) {
        setState(() {});
      }
    });
    controller.addListener(() {
      if (controller.text.isNotEmpty) {
        showRecordButton = false;
      } else {
        showRecordButton = true;
      }
      setState(() {});
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.status == Constant.statusSoldOut &&
          widget.isPurchased == 1 &&
          !widget.alreadyReview) {
        ratingsAlertDialog();
      }
    });
  }

  Stream<PermissionStatus> notificationPermission() async* {
    while (true) {
      await Future.delayed(const Duration(seconds: 5));
      yield* Permission.notification.request().asStream();
    }
  }

  @override
  void dispose() {
    notificationStreamSubscription.cancel();
    _feedbackController.dispose();
    controller.dispose();
    super.dispose();
  }

  List<String> supportedImageTypes = [
    'jpeg',
    'jpg',
    'png',
    'gif',
    'webp',
    'animated_webp',
  ];

  void ratingsAlertDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: true,

      // Set to false if you don't want the dialog to close by tapping outside
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: context.color.secondaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Center(child: CustomText("rateSeller".translate(context))),
          content: BlocListener<AddItemReviewCubit, AddItemReviewState>(
            listener: (context, state) {
              if (state is AddItemReviewInSuccess) {
                LoadingWidgets.hideLoader(context);
                Navigator.pop(context);
                context.read<GetBuyerChatListCubit>().updateAlreadyReview(
                  int.parse(widget.itemId),
                );
                HelperUtils.showSnackBarMessage(context, state.responseMessage);
              }
              if (state is AddItemReviewFailure) {
                LoadingWidgets.hideLoader(context);
                Navigator.pop(context);
                HelperUtils.showSnackBarMessage(
                  context,
                  state.error.toString(),
                );
              }
              if (state is AddItemReviewInProgress) {
                LoadingWidgets.showLoader(context);
              }
            },
            child: StatefulBuilder(
              builder: (BuildContext context, StateSetter setStater) {
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: 5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CustomText(
                        'rateYourExperience'.translate(context),
                        color: context.color.textLightColor,
                      ),
                      SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: List.generate(
                          5,
                          (index) => InkWell(
                            child: Icon(
                              index < _rating ? Icons.star : Icons.star_border,
                              color: Colors.amber,
                              size: 30,
                            ),
                            onTap: () {
                              setStater(() {
                                _rating = index + 1;
                              });
                              setState(() {});
                            },
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      TextField(
                        controller: _feedbackController,
                        decoration: InputDecoration(
                          hintText: 'shareYourExperience'.translate(context),
                          hintStyle: TextStyle(
                            color: context.color.textLightColor,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(5),
                            borderSide: BorderSide(
                              color: context.color.territoryColor,
                            ),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(5),
                            borderSide: BorderSide(
                              color: context.color.textLightColor.withValues(
                                alpha: 0.7,
                              ),
                            ),
                          ),
                        ),
                        maxLines: 3,
                      ),
                      SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          UiUtils.buildButton(
                            context,
                            onPressed: () {
                              _feedbackController.clear();
                              _rating = 0;
                              Navigator.of(context).pop();
                            },
                            buttonTitle: "cancelBtnLbl".translate(context),
                            radius: 8,
                            fontSize: 12,
                            width: context.screenWidth / 4,
                            textColor: context.color.textDefaultColor,
                            buttonColor: context.color.backgroundColor,
                            showElevation: false,
                            height: 39,
                          ),
                          UiUtils.buildButton(
                            context,
                            showElevation: false,
                            onPressed: () {
                              context.read<AddItemReviewCubit>().addItemReview(
                                itemId: int.parse(widget.itemId),
                                rating: _rating,
                                review: _feedbackController.text.trim(),
                              );
                            },
                            fontSize: 12,
                            disabled: _rating < 1,
                            disabledColor: context.color.deactivateColor,
                            buttonTitle: "submitBtnLbl".translate(context),
                            radius: 8,
                            width: context.screenWidth / 4,
                            textColor: secondaryColor_,
                            buttonColor: context.color.territoryColor,
                            height: 39,
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  // New method to handle camera image capture
  Future<void> _pickCameraImage() async {
    try {
      // Check camera permission
      var cameraStatus = await Permission.camera.status;
      if (!cameraStatus.isGranted) {
        cameraStatus = await Permission.camera.request();
        if (!cameraStatus.isGranted) {
          HelperUtils.showSnackBarMessage(
            context,
            "cameraPermissionDenied".translate(context),
          );
          return;
        }
      }

      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (image != null) {
        // Check file size (limit to 5MB)
        final fileSize = await File(image.path).length();
        if (fileSize > 5 * 1024 * 1024) {
          HelperUtils.showSnackBarMessage(
            context,
            "fileSize5mbWarning".translate(context),
          );
          return;
        }

        setState(() {
          messageAttachment = PlatformFile(
            name: image.name,
            path: image.path,
            size: fileSize,
          );
          showRecordButton = false;
        });
      }
    } catch (e) {
      HelperUtils.showSnackBarMessage(
        context,
        "cameraError".translate(context) + ": $e",
      );
    }
  }

  Future<void> _shareLocation() async {
    try {
      // 1️⃣ Check location service
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        HelperUtils.showSnackBarMessage(
          context,
          "locationServiceDisabled".translate(context),
        );
        return;
      }

      // 2️⃣ Permission check
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          HelperUtils.showSnackBarMessage(
            context,
            "locationPermissionDenied".translate(context),
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        HelperUtils.showSnackBarMessage(
          context,
          "locationPermissionPermanentlyDenied".translate(context),
        );
        return;
      }

      // 3️⃣ Get current position
      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final double lat = position.latitude;
      final double lng = position.longitude;

      // 4️⃣ Google Maps link (CLICKABLE)
      final String mapUrl = "https://www.google.com/maps?q=$lat,$lng";

      // 5️⃣ Send ONLY the link
      ChatMessageHandler.add(
        BlocProvider(
          create: (context) => SendMessageCubit(),
          child: ChatMessage(
            key: ValueKey(DateTime.now().toString()),
            message: mapUrl,
            senderId: int.parse(HiveUtils.getUserId()!),
            createdAt: DateTime.now().toString(),
            isSentNow: true,
            itemOfferId: widget.itemOfferId,
            audio: "",
            file: "",
            updatedAt: DateTime.now().toString(),
          ),
        ),
      );

      totalMessageCount++;
      setState(() {});

      HelperUtils.showSnackBarMessage(context, "Location shared successfully");
    } catch (e) {
      HelperUtils.showSnackBarMessage(context, "Error sharing location: $e");
    }
  }

  // New method to toggle attachment options
  void _toggleAttachmentOptions() {
    setState(() {
      _showAttachmentOptions = !_showAttachmentOptions;
    });
  }

  // New method to build attachment options
  Widget _buildAttachmentOptions() {
    if (!_showAttachmentOptions) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: BoxDecoration(
        color: context.color.secondaryColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: context.color.textLightColor.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildAttachmentOption(
                icon: Icons.camera_alt,
                label: "camera".translate(context),
                onTap: _pickCameraImage,
              ),
              _buildAttachmentOption(
                icon: Icons.photo_library,
                label: "gallery".translate(context),
                onTap: _pickGalleryImage,
              ),
              _buildAttachmentOption(
                icon: Icons.location_on,
                label: "location".translate(context),
                onTap: _shareLocation,
              ),
              _buildAttachmentOption(
                icon: Icons.insert_drive_file,
                label: "document".translate(context),
                onTap: _pickDocument,
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildAttachmentOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: () {
        onTap();
        setState(() {
          _showAttachmentOptions = false;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.color.territoryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: context.color.territoryColor),
            ),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  // New method to pick gallery image
  Future<void> _pickGalleryImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image != null) {
        // Check file size (limit to 5MB)
        final fileSize = await File(image.path).length();
        if (fileSize > 5 * 1024 * 1024) {
          HelperUtils.showSnackBarMessage(
            context,
            "fileSize5mbWarning".translate(context),
          );
          return;
        }

        setState(() {
          messageAttachment = PlatformFile(
            name: image.name,
            path: image.path,
            size: fileSize,
          );
          showRecordButton = false;
        });
      }
    } catch (e) {
      HelperUtils.showSnackBarMessage(
        context,
        "galleryError".translate(context) + ": $e",
      );
    }
  }

  // New method to pick document
  Future<void> _pickDocument() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'xls', 'xlsx'],
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;

        // Check file size (limit to 10MB)
        if (file.size > 10 * 1024 * 1024) {
          HelperUtils.showSnackBarMessage(
            context,
            "fileSize10mbWarning".translate(context),
          );
          return;
        }

        setState(() {
          messageAttachment = file;
          showRecordButton = false;
        });
      }
    } catch (e) {
      HelperUtils.showSnackBarMessage(
        context,
        "documentError".translate(context) + ": $e",
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    var attachmentMIME = "";
    if (messageAttachment != null) {
      attachmentMIME =
          (messageAttachment?.path?.split(".").last.toLowerCase()) ?? "";
    }

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        currentlyChatingWith = "";
        showDeleteButton.value = false;

        currentlyChatItemId = "";
        notificationStreamSubscription.cancel();
        ChatMessageHandler.flushMessages();
        return;
      },
      child: Scaffold(
        backgroundColor: context.color.backgroundColor,
        bottomNavigationBar: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {},
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Attachment preview when a file is selected
                if (messageAttachment != null) ...[
                  if (supportedImageTypes.contains(attachmentMIME)) ...[
                    Container(
                      decoration: BoxDecoration(
                        color: context.color.secondaryColor,
                        border: Border.all(
                          color: context.color.borderColor,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: SizedBox(
                              height: 70,
                              width: 70,
                              child: GestureDetector(
                                onTap: () {
                                  UiUtils.showFullScreenImage(
                                    context,
                                    provider: FileImage(
                                      File(messageAttachment?.path ?? ""),
                                    ),
                                  );
                                },
                                child: Image.file(
                                  File(messageAttachment?.path ?? ""),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CustomText(messageAttachment?.name ?? ""),
                                CustomText(
                                  HelperUtils.getFileSizeString(
                                    bytes: messageAttachment!.size,
                                  ).toString(),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else
                    Container(
                      color: context.color.secondaryColor,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: AttachmentMessage(url: messageAttachment!.path!),
                      ),
                    ),
                ],

                // Attachment options panel
                _buildAttachmentOptions(),

                BottomAppBar(
                  padding: const EdgeInsetsDirectional.all(10),
                  elevation: 5,
                  color: context.color.secondaryColor,
                  child: Directionality(
                    textDirection: Directionality.of(context),
                    child: BlocProvider(
                      create: (context) => UnblockUserCubit(),
                      child: Builder(
                        builder: (context) {
                          bool isBlocked = context
                              .read<BlockedUsersListCubit>()
                              .isUserBlocked(int.parse(widget.userId));
                          return BlocConsumer<
                            BlockedUsersListCubit,
                            BlockedUsersListState
                          >(
                            listener: (context, state) {
                              if (state is BlockedUsersListSuccess) {
                                isBlocked = context
                                    .read<BlockedUsersListCubit>()
                                    .isUserBlocked(int.parse(widget.userId));
                              }
                            },
                            builder: (context, blockedUsersListState) {
                              return Column(
                                children: [
                                  isBlocked
                                      ? BlocListener<
                                          UnblockUserCubit,
                                          UnblockUserState
                                        >(
                                          listener: (context, unblockState) {
                                            if (unblockState
                                                is UnblockUserSuccess) {
                                              // Remove the unblocked user from the list
                                              context
                                                  .read<BlockedUsersListCubit>()
                                                  .unblockUser(
                                                    int.parse(widget.userId),
                                                  );
                                              HelperUtils.showSnackBarMessage(
                                                context,
                                                'userUnblockedSuccessfully'
                                                    .translate(context),
                                              );
                                            } else if (unblockState
                                                is UnblockUserFail) {
                                              HelperUtils.showSnackBarMessage(
                                                context,
                                                unblockState.error.toString(),
                                              );
                                            }
                                          },
                                          child: Container(
                                            height: 40,
                                            width: double.maxFinite,
                                            color: context.color.secondaryColor,
                                            alignment: Alignment.center,
                                            child: InkWell(
                                              child: CustomText(
                                                "youBlockedThisContact"
                                                    .translate(context),
                                                color: context
                                                    .color
                                                    .textColorDark
                                                    .withValues(alpha: 0.7),
                                              ),
                                              onTap: () async {
                                                var unBlock =
                                                    await UiUtils.showBlurredDialoge(
                                                      context,
                                                      dialoge: BlurredDialogBox(
                                                        acceptButtonName:
                                                            "unBlockLbl"
                                                                .translate(
                                                                  context,
                                                                ),
                                                        content: CustomText(
                                                          "${"unBlockLbl".translate(context)}\t${widget.userName}\t${"toSendMessage".translate(context)}"
                                                              .translate(
                                                                context,
                                                              ),
                                                        ),
                                                      ),
                                                    );
                                                if (unBlock == true) {
                                                  Future.delayed(
                                                    Duration.zero,
                                                    () {
                                                      context
                                                          .read<
                                                            UnblockUserCubit
                                                          >()
                                                          .unBlockUser(
                                                            blockUserId:
                                                                int.parse(
                                                                  widget.userId,
                                                                ),
                                                          );
                                                    },
                                                  );
                                                }
                                              },
                                            ),
                                          ),
                                        )
                                      : SizedBox(),
                                  widget.status == Constant.statusReview ||
                                          widget.status ==
                                              Constant.statusRejected ||
                                          widget.status ==
                                              Constant.statusSoldOut ||
                                          widget.status ==
                                              Constant.statusInactive ||
                                          widget.status ==
                                              Constant.statusSoftRejected ||
                                          widget.status ==
                                              Constant.statusPermanentRejected
                                      ? Container(
                                          height: 40,
                                          width: double.maxFinite,
                                          color: context.color.secondaryColor,
                                          alignment: Alignment.center,
                                          child: CustomText(
                                            "${"thisItemIs".translate(context)} ${widget.status}",
                                            fontSize: context.font.large,
                                          ),
                                        )
                                      : Column(
                                          children: [
                                            SizedBox(height: 8),
                                            if (!isBlocked)
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: TextField(
                                                      controller: controller,
                                                      cursorColor: context
                                                          .color
                                                          .territoryColor,
                                                      onTap: () {
                                                        showDeleteButton.value =
                                                            false;
                                                      },
                                                      textInputAction:
                                                          TextInputAction
                                                              .newline,
                                                      minLines: 1,
                                                      maxLines: null,
                                                      decoration: InputDecoration(
                                                        suffixIconColor: context
                                                            .color
                                                            .textLightColor,
                                                        suffixIcon: IconButton(
                                                          onPressed: () async {
                                                            // Check if an attachment already exists (meaning the icon is 'close')
                                                            if (messageAttachment !=
                                                                null) {
                                                              // 1. Clear the attachment
                                                              setState(() {
                                                                messageAttachment =
                                                                    null;
                                                                // 2. Show record button if text field is empty
                                                                if (controller
                                                                    .text
                                                                    .isEmpty) {
                                                                  showRecordButton =
                                                                      true;
                                                                }
                                                              });
                                                            } else {
                                                              // 3. Attachment is null, show the options (camera, gallery, etc.)
                                                              // NOTE: This relies on the _toggleAttachmentOptions method being defined.
                                                              // Call the method to display the modal bottom sheet for options.
                                                              _toggleAttachmentOptions();

                                                              // 4. Crucially, dismiss the keyboard when attachment options pop up
                                                              FocusScope.of(
                                                                context,
                                                              ).unfocus();
                                                            }
                                                          },
                                                          icon: Icon(
                                                            // Choose icon based on state
                                                            messageAttachment !=
                                                                    null
                                                                ? Icons
                                                                      .close // Close icon to clear attachment
                                                                : Icons
                                                                      .attach_file, // Attachment icon to open options
                                                            color: context
                                                                .color
                                                                .textLightColor,
                                                          ),
                                                        ),

                                                        contentPadding:
                                                            const EdgeInsets.symmetric(
                                                              vertical: 6,
                                                              horizontal: 8,
                                                            ),
                                                        border: OutlineInputBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                20,
                                                              ),
                                                          borderSide: BorderSide(
                                                            color: context
                                                                .color
                                                                .territoryColor,
                                                          ),
                                                        ),
                                                        focusedBorder: OutlineInputBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                20,
                                                              ),
                                                          borderSide: BorderSide(
                                                            color: context
                                                                .color
                                                                .territoryColor,
                                                          ),
                                                        ),
                                                        hintText: "writeHere"
                                                            .translate(context),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 9.5),
                                                  if (showRecordButton)
                                                    RecordButton(
                                                      controller:
                                                          _recordButtonAnimation,
                                                      callback: (path) {
                                                        //This is adding Chat widget in stream with BlocProvider , because we will need to do api process to store chat message to server, when it will be added to list it's initState method will be called
                                                        ChatMessageHandler.add(
                                                          BlocProvider(
                                                            create: (context) =>
                                                                SendMessageCubit(),
                                                            child: ChatMessage(
                                                              key: ValueKey(
                                                                DateTime.now()
                                                                    .toString()
                                                                    .toString(),
                                                              ),
                                                              message:
                                                                  controller
                                                                      .text,
                                                              senderId: int.parse(
                                                                HiveUtils.getUserId()!,
                                                              ),
                                                              createdAt:
                                                                  DateTime.now()
                                                                      .toString(),
                                                              isSentNow: true,
                                                              audio: path,
                                                              itemOfferId: widget
                                                                  .itemOfferId,
                                                              file: "",
                                                              updatedAt:
                                                                  DateTime.now()
                                                                      .toString(),
                                                            ),
                                                          ),
                                                        );
                                                        totalMessageCount++;

                                                        setState(() {});
                                                      },
                                                      isSending: false,
                                                    ),
                                                  if (!showRecordButton)
                                                    GestureDetector(
                                                      onTap: () {
                                                        showDeleteButton.value =
                                                            false;
                                                        //if file is selected then user can send message without text
                                                        if (controller.text
                                                                .trim()
                                                                .isEmpty &&
                                                            messageAttachment ==
                                                                null)
                                                          return;
                                                        //This is adding Chat widget in stream with BlocProvider , because we will need to do api process to store chat message to server, when it will be added to list it's initState method will be called

                                                        ChatMessageHandler.add(
                                                          BlocProvider(
                                                            key: ValueKey(
                                                              DateTime.now()
                                                                  .toString(),
                                                            ),
                                                            create: (context) =>
                                                                SendMessageCubit(),
                                                            child: ChatMessage(
                                                              key: ValueKey(
                                                                DateTime.now()
                                                                    .toString(),
                                                              ),
                                                              message:
                                                                  controller
                                                                      .text,
                                                              senderId: int.parse(
                                                                HiveUtils.getUserId()!,
                                                              ),
                                                              createdAt:
                                                                  DateTime.now()
                                                                      .toString(),
                                                              isSentNow: true,
                                                              updatedAt:
                                                                  DateTime.now()
                                                                      .toString(),
                                                              audio: "",
                                                              file:
                                                                  messageAttachment !=
                                                                      null
                                                                  ? messageAttachment
                                                                        ?.path
                                                                  : "",
                                                              itemOfferId: widget
                                                                  .itemOfferId,
                                                            ),
                                                          ),
                                                        );

                                                        totalMessageCount++;
                                                        controller.text = "";
                                                        messageAttachment =
                                                            null;
                                                        setState(() {});
                                                      },
                                                      child: CircleAvatar(
                                                        radius: 20,
                                                        backgroundColor: context
                                                            .color
                                                            .territoryColor,
                                                        child: Icon(
                                                          Icons.send,
                                                          color: context
                                                              .color
                                                              .buttonColor,
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                          ],
                                        ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        appBar: AppBar(
          centerTitle: false,
          automaticallyImplyLeading: false,
          leading: Material(
            clipBehavior: Clip.antiAlias,
            color: Colors.transparent,
            type: MaterialType.circle,
            child: InkWell(
              onTap: () {
                Navigator.pop(context);
              },
              child: Padding(
                padding: EdgeInsetsDirectional.only(start: 15),
                child: Directionality(
                  textDirection: Directionality.of(context),
                  child: RotatedBox(
                    quarterTurns:
                        Directionality.of(context) == TextDirection.rtl
                        ? 2
                        : -4,
                    child: UiUtils.getSvg(
                      AppIcons.arrowLeft,
                      fit: BoxFit.none,
                      color: context.color.textDefaultColor,
                    ),
                  ),
                ),
              ),
            ),
          ),
          backgroundColor: context.color.secondaryColor,
          elevation: 0,
          iconTheme: IconThemeData(color: context.color.territoryColor),
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(70),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Divider(
                  color: context.color.textLightColor.withValues(alpha: 0.2),
                  thickness: 1,
                ),
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 25, vertical: 0),
                  color: context.color.secondaryColor,
                  height: 63,
                  child: Row(
                    children: [
                      FittedBox(
                        fit: BoxFit.none,
                        child: GestureDetector(
                          onTap: () async {
                            try {
                              LoadingWidgets.showLoader(context);

                              DataOutput<ItemModel> dataOutput =
                                  await ItemRepository().fetchItemFromItemId(
                                    int.parse(widget.itemId),
                                  );

                              Future.delayed(Duration.zero, () {
                                LoadingWidgets.hideLoader(context);
                                Navigator.pushNamed(
                                  context,
                                  Routes.adDetailsScreen,
                                  arguments: {"model": dataOutput.modelList[0]},
                                );
                              });
                            } catch (e) {
                              LoadingWidgets.hideLoader(context);
                            }
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: SizedBox(
                              width: 47,
                              height: 47,
                              child: UiUtils.getImage(
                                widget.itemImage,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      ),

                      SizedBox(width: 10),
                      // Adding horizontal space between items
                      Expanded(
                        child: Container(
                          color: context.color.secondaryColor,
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  widget.itemTitle,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  softWrap: true,
                                  style: TextStyle(
                                    color: context.color.textDefaultColor,
                                    fontSize: context.font.large,
                                  ),
                                ),
                              ),
                              if (widget.itemPrice != null)
                                Padding(
                                  padding: EdgeInsetsDirectional.only(
                                    start: 15.0,
                                  ),
                                  child: CustomText(
                                    double.parse(
                                      widget.itemPrice!,
                                    ).currencyFormat,
                                    // Replace with your item price
                                    color: context.color.textDefaultColor,
                                    fontSize: context.font.large,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            IconButton(
              onPressed: () {
                // Navigator.push(
                //   context,
                //   MaterialPageRoute(
                //     builder: (context) => VoiceCallScreen(
                //       userId: widget.userId,
                //       isCaller: true,
                //       userName: widget.userName,
                //       userProfilePicture: widget.profilePicture,
                //     ),
                //   ),
                // );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      '📞 Voice Call is currently under construction. Check logs for ID mapping fix.',
                    ),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              icon: Icon(Icons.call, color: context.color.textDefaultColor),
            ),

            IconButton(
              onPressed: () {
                // Navigator.push(
                //   context,
                //   MaterialPageRoute(
                //     builder: (context) => VideoCallScreen(
                //       userId: widget.userId,
                //       isCaller: true,
                //
                //       userName: widget.userName,
                //       userProfilePicture: widget.profilePicture,
                //     ),
                //   ),
                // );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      '📹 Video Call is currently under construction. Check logs for ID mapping fix.',
                    ),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              icon: Icon(Icons.videocam, color: context.color.textDefaultColor),
            ),
            MultiBlocProvider(
              providers: [
                BlocProvider(create: (context) => UnblockUserCubit()),
                BlocProvider(create: (context) => BlockUserCubit()),
              ],
              child: Builder(
                builder: (context) {
                  bool isBlocked = context
                      .read<BlockedUsersListCubit>()
                      .isUserBlocked(int.parse(widget.userId));
                  return BlocConsumer<
                    BlockedUsersListCubit,
                    BlockedUsersListState
                  >(
                    listener: (context, state) {
                      if (state is BlockedUsersListSuccess) {
                        isBlocked = context
                            .read<BlockedUsersListCubit>()
                            .isUserBlocked(int.parse(widget.userId));
                      }
                    },
                    builder: (context, blockedUsersListState) {
                      return BlocListener<BlockUserCubit, BlockUserState>(
                        listener: (context, blockState) {
                          if (blockState is BlockUserSuccess) {
                            // Add the blocked user to the list
                            context
                                .read<BlockedUsersListCubit>()
                                .addBlockedUser(
                                  BlockedUserModel(
                                    id: int.parse(widget.userId),
                                    name: widget.userName,
                                    profile: widget.profilePicture,
                                    // Add other necessary user data
                                  ),
                                );
                            HelperUtils.showSnackBarMessage(
                              context,
                              'userBlockedSuccessfully'.translate(context),
                            );
                          } else if (blockState is BlockUserFail) {
                            HelperUtils.showSnackBarMessage(
                              context,
                              blockState.error.toString(),
                            );
                          }
                        },
                        child: BlocListener<UnblockUserCubit, UnblockUserState>(
                          listener: (context, unblockState) {
                            if (unblockState is UnblockUserSuccess) {
                              // Remove the unblocked user from the list
                              context.read<BlockedUsersListCubit>().unblockUser(
                                int.parse(widget.userId),
                              );
                              HelperUtils.showSnackBarMessage(
                                context,
                                'userUnblockedSuccessfully'.translate(context),
                              );
                            } else if (unblockState is UnblockUserFail) {
                              HelperUtils.showSnackBarMessage(
                                context,
                                unblockState.error.toString(),
                              );
                            }
                          },
                          child: Padding(
                            padding: EdgeInsetsDirectional.only(end: 10.0),
                            child: Container(
                              height: 24,
                              width: 24,
                              alignment: AlignmentDirectional.center,
                              child: PopupMenuButton(
                                color: context.color.secondaryColor,
                                offset: Offset(-12, 15),
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.only(
                                    bottomLeft: Radius.circular(17),
                                    bottomRight: Radius.circular(17),
                                    topLeft: Radius.circular(17),
                                    topRight: Radius.circular(0),
                                  ),
                                ),
                                child: SvgPicture.asset(
                                  AppIcons.more,
                                  width: 20,
                                  height: 20,
                                  fit: BoxFit.contain,
                                  colorFilter: ColorFilter.mode(
                                    context.color.textDefaultColor,
                                    BlendMode.srcIn,
                                  ),
                                ),
                                itemBuilder: (context) => [
                                  // Block / Unblock menu
                                  if (!isBlocked)
                                    PopupMenuItem(
                                      onTap: () async {
                                        var block =
                                            await UiUtils.showBlurredDialoge(
                                              context,
                                              dialoge: BlurredDialogBox(
                                                acceptButtonName: "blockLbl"
                                                    .translate(context),
                                                title:
                                                    "${"blockLbl".translate(context)} ${widget.userName}?",
                                                content: CustomText(
                                                  "blockWarning".translate(
                                                    context,
                                                  ),
                                                ),
                                              ),
                                            );
                                        if (block == true) {
                                          Future.delayed(Duration.zero, () {
                                            context
                                                .read<BlockUserCubit>()
                                                .blockUser(
                                                  blockUserId: int.parse(
                                                    widget.userId,
                                                  ),
                                                );
                                          });
                                        }
                                      },
                                      child: CustomText(
                                        "blockLbl".translate(context),
                                        color: context.color.textColorDark,
                                      ),
                                    )
                                  else
                                    PopupMenuItem(
                                      onTap: () async {
                                        var unBlock =
                                            await UiUtils.showBlurredDialoge(
                                              context,
                                              dialoge: BlurredDialogBox(
                                                acceptButtonName: "unBlockLbl"
                                                    .translate(context),
                                                content: CustomText(
                                                  "${"unBlockLbl".translate(context)} ${widget.userName} ${"toSendMessage".translate(context)}",
                                                ),
                                              ),
                                            );
                                        if (unBlock == true) {
                                          Future.delayed(Duration.zero, () {
                                            context
                                                .read<UnblockUserCubit>()
                                                .unBlockUser(
                                                  blockUserId: int.parse(
                                                    widget.userId,
                                                  ),
                                                );
                                          });
                                        }
                                      },
                                      child: CustomText(
                                        "unBlockLbl".translate(context),
                                        color: context.color.textColorDark,
                                      ),
                                    ),

                                  // New: Report User menu
                                  PopupMenuItem(
                                    onTap: () {
                                      Navigator.pushNamed(
                                        context,
                                        Routes
                                            .reportUserScreen, // your report user screen route
                                        arguments: {
                                          'userId': widget.userId,
                                          'userName': widget.userName,
                                        },
                                      );
                                    },
                                    child: CustomText(
                                      "Report User".translate(
                                        context,
                                      ), // Add translation key in your i18n
                                      color: context.color.textColorDark,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
          title: FittedBox(
            fit: BoxFit.none,
            child: Row(
              children: [
                widget.profilePicture == ""
                    ? CircleAvatar(
                        backgroundColor: context.color.territoryColor,
                        child: SvgPicture.asset(
                          AppIcons.profile,
                          colorFilter: ColorFilter.mode(
                            context.color.buttonColor,
                            BlendMode.srcIn,
                          ),
                        ),
                      )
                    : GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            TransparantRoute(
                              barrierDismiss: true,
                              builder: (context) {
                                return GestureDetector(
                                  onTap: () {
                                    Navigator.pop(context);
                                  },
                                  child: Container(
                                    color: const Color.fromARGB(69, 0, 0, 0),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                        child: CustomImageHeroAnimation(
                          type: CImageType.Network,
                          image: widget.profilePicture,
                          child: CircleAvatar(
                            backgroundImage: CachedNetworkImageProvider(
                              widget.profilePicture,
                            ),
                          ),
                        ),
                      ),
                const SizedBox(width: 10),
                SizedBox(
                  width: context.screenWidth * 0.35,
                  child: CustomText(
                    widget.userName,
                    color: context.color.textColorDark,
                    fontSize: context.font.normal,
                  ),
                ),
              ],
            ),
          ),
        ),

        body: BlocProvider(
          create: (context) => AddItemReviewCubit(),
          child: Stack(
            children: [
              //Causing lag when transitioning
              // SvgPicture.asset(
              //   chatBackground,
              //   height: MediaQuery.of(context).size.height,
              //   fit: BoxFit.cover,
              //   width: MediaQuery.of(context).size.width,
              // ),
              BlocListener<DeleteMessageCubit, DeleteMessageState>(
                listener: (context, state) {
                  if (state is DeleteMessageSuccess) {
                    ChatMessageHandler.removeMessage(state.id);
                    showDeleteButton.value = false;
                  }
                },
                child: GestureDetector(
                  onTap: () {
                    showDeleteButton.value = false;
                  },
                  child: BlocConsumer<LoadChatMessagesCubit, LoadChatMessagesState>(
                    listener: (context, state) {
                      if (state is LoadChatMessagesSuccess) {
                        ChatMessageHandler.loadMessages(
                          state.messages,
                          context,
                        );
                        totalMessageCount = state.messages.length;
                        isFetchedFirstTime = true;
                        setState(() {});
                        if (widget.isFromBuyerList != null) {
                          if (widget.isFromBuyerList!) {
                            context
                                .read<GetBuyerChatListCubit>()
                                .removeUnreadCount(widget.itemOfferId);
                          } else {
                            context
                                .read<GetSellerChatListCubit>()
                                .removeUnreadCount(widget.itemOfferId);
                          }
                        }
                      }
                    },
                    builder: (context, state) {
                      return Stack(
                        children: [
                          StreamBuilder<List<Widget>>(
                            stream: ChatMessageHandler.getChatStream(),
                            builder: (context, AsyncSnapshot<List<Widget>> snapshot) {
                              Widget? loadingMoreWidget;
                              if (state is LoadChatMessagesSuccess) {
                                if (state.isLoadingMore) {
                                  // Centered loading text for better visibility
                                  loadingMoreWidget = Center(
                                    child: CustomText(
                                      "loading".translate(context),
                                    ),
                                  );
                                }
                              }
                              if (snapshot.connectionState ==
                                      ConnectionState.active ||
                                  snapshot.connectionState ==
                                      ConnectionState.done) {
                                if ((snapshot.data as List).isEmpty) {
                                  return offerWidget();
                                }

                                if (snapshot.hasData) {
                                  return Column(
                                    // Consider removing mainAxisSize: MainAxisSize.min if this Column is
                                    // expected to fill the space provided by its parent in the main chat layout.
                                    children: [
                                      loadingMoreWidget ??
                                          const SizedBox.shrink(),
                                      Expanded(
                                        child: ListView.builder(
                                          reverse: true,
                                          // *** FIX: Removed shrinkWrap: true to prevent layout ambiguity
                                          // when wrapped in Expanded. ***
                                          physics:
                                              const AlwaysScrollableScrollPhysics(),
                                          controller: _pageScrollController,
                                          itemCount: snapshot.data!.length,
                                          padding: const EdgeInsets.only(
                                            bottom: 10,
                                          ),
                                          itemBuilder: (context, index) {
                                            dynamic chat =
                                                snapshot.data![index];

                                            // 🔹 Detect system call log messages
                                            if (chat is Map &&
                                                chat['type'] ==
                                                    'system_call_log') {
                                              return Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 8.0,
                                                    ),
                                                child: Center(
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          vertical: 6.0,
                                                          horizontal: 12.0,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.grey
                                                          .withOpacity(0.2),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      chat['text'] ?? '',
                                                      style: const TextStyle(
                                                        color: Colors.grey,
                                                        fontSize: 13,
                                                        fontStyle:
                                                            FontStyle.italic,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              );
                                            }

                                            // 🔹 Otherwise, render normal chat bubble
                                            return Column(
                                              mainAxisSize: MainAxisSize.min,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                if (index ==
                                                    snapshot.data!.length - 1)
                                                  offerWidget(),
                                                chat is Widget
                                                    ? chat
                                                    : const SizedBox.shrink(),
                                              ],
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  );
                                }
                              }

                              return offerWidget();
                            },
                          ),
                          if ((state is LoadChatMessagesInProgress))
                            Center(child: UiUtils.progress()),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget offerWidget() {
    if (widget.itemOfferPrice != null) {
      if (int.parse(HiveUtils.getUserId()!) == int.parse(widget.buyerId!)) {
        return Align(
          alignment: AlignmentDirectional.topEnd,
          child: Container(
            constraints: BoxConstraints(maxHeight: 70),
            margin: EdgeInsetsDirectional.only(top: 15, bottom: 15, end: 15),
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(
                color: context.color.territoryColor.withValues(alpha: 0.3),
              ),
              color: context.color.territoryColor.withValues(alpha: 0.17),
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(0),
                topLeft: Radius.circular(8),
                bottomRight: Radius.circular(8),
                bottomLeft: Radius.circular(8),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  "yourOffer".translate(context),
                  color: context.color.textDefaultColor.withValues(alpha: 0.5),
                ),
                CustomText(
                  (widget.itemOfferPrice ?? 0.0).currencyFormat,
                  color: context.color.textDefaultColor,
                  fontSize: context.font.larger,
                  fontWeight: FontWeight.bold,
                ),
              ],
            ),
          ),
        );
      } else {
        return Align(
          alignment: AlignmentDirectional.topStart,
          child: Container(
            height: 72,
            margin: EdgeInsetsDirectional.only(top: 15, bottom: 15, start: 15),
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(
                color: context.color.territoryColor.withValues(alpha: 0.3),
              ),
              color: context.color.territoryColor.withValues(alpha: 0.17),
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(8),
                topLeft: Radius.circular(0),
                bottomRight: Radius.circular(8),
                bottomLeft: Radius.circular(8),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  "offerLbl".translate(context),
                  color: context.color.textDefaultColor.withValues(alpha: 0.5),
                ),
                CustomText(
                  Constant.currencySymbol + widget.itemOfferPrice.toString(),
                  color: context.color.textDefaultColor,
                  fontSize: context.font.larger,
                  fontWeight: FontWeight.bold,
                ),
              ],
            ),
          ),
        );
      }
    } else {
      return SizedBox.shrink();
    }
  }
}
