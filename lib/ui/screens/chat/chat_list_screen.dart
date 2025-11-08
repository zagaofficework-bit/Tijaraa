import 'package:Tijaraa/app/routes.dart';
import 'package:Tijaraa/data/cubits/chat/blocked_users_list_cubit.dart';
import 'package:Tijaraa/data/cubits/chat/get_buyer_chat_users_cubit.dart';
import 'package:Tijaraa/data/cubits/chat/get_combined_chat_users_cubit.dart';
import 'package:Tijaraa/data/cubits/chat/get_combined_chat_users_state.dart';
import 'package:Tijaraa/data/cubits/chat/get_seller_chat_users_cubit.dart';
import 'package:Tijaraa/data/model/chat/chat_user_model.dart';
import 'package:Tijaraa/ui/screens/chat/chatTile.dart';
import 'package:Tijaraa/ui/screens/widgets/errors/no_internet.dart';
import 'package:Tijaraa/ui/theme/theme.dart';
import 'package:Tijaraa/utils/api.dart';
import 'package:Tijaraa/utils/app_icon.dart';
import 'package:Tijaraa/utils/extensions/extensions.dart';
import 'package:Tijaraa/utils/hive_utils.dart';
import 'package:Tijaraa/utils/ui_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  static Route route(RouteSettings settings) {
    return MaterialPageRoute(
      builder: (context) {
        return const ChatListScreen();
      },
    );
  }

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen>
    with AutomaticKeepAliveClientMixin {
  // Controllers for each list
  ScrollController chatBuyerScreenController = ScrollController();
  ScrollController chatSellerScreenController = ScrollController();
  ScrollController chatCombinedScreenController = ScrollController();

  @override
  void initState() {
    super.initState();
    if (HiveUtils.isUserAuthenticated()) {
      // Fetch initial data for all lists
      context.read<GetBuyerChatListCubit>().fetch();
      context.read<GetSellerChatListCubit>().fetch();
      context.read<GetCombinedChatListCubit>().fetch(); // Fetch combined list
      context.read<BlockedUsersListCubit>().blockedUsersList();

      // Listeners for loadMore functionality
      chatBuyerScreenController.addListener(() {
        if (chatBuyerScreenController.isEndReached()) {
          if (context.read<GetBuyerChatListCubit>().hasMoreData()) {
            context.read<GetBuyerChatListCubit>().loadMore();
          }
        }
      });
      chatSellerScreenController.addListener(() {
        if (chatSellerScreenController.isEndReached()) {
          if (context.read<GetSellerChatListCubit>().hasMoreData()) {
            context.read<GetSellerChatListCubit>().loadMore();
          }
        }
      });
      // Listener for the combined chat list (All Chats tab)
      chatCombinedScreenController.addListener(_combinedScrollListener);
    }
  }

  // Listener function for the combined chat list
  void _combinedScrollListener() {
    if (chatCombinedScreenController.isEndReached()) {
      final cubit = context.read<GetCombinedChatListCubit>();
      if (cubit.hasMoreData()) {
        cubit.loadMore();
      }
    }
  }

  @override
  void dispose() {
    // Dispose all controllers and listeners
    chatBuyerScreenController.dispose();
    chatSellerScreenController.dispose();

    chatCombinedScreenController.removeListener(_combinedScrollListener);
    chatCombinedScreenController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return AnnotatedRegion(
      value: UiUtils.getSystemUiOverlayStyle(
        context: context,
        statusBarColor: context.color.secondaryColor,
      ),
      child: DefaultTabController(
        length: 3,
        initialIndex: 0,
        child: Scaffold(
          backgroundColor: context.color.backgroundColor,
          appBar: UiUtils.buildAppBar(
            context,
            title: "message".translate(context),
            bottomHeight: 49,
            actions: [
              InkWell(
                child: UiUtils.getSvg(
                  AppIcons.blockedUserIcon,
                  color: context.color.textDefaultColor,
                ),
                onTap: () {
                  Navigator.pushNamed(context, Routes.blockedUserListScreen);
                },
              ),
            ],
            bottom: [
              TabBar(
                tabs: [
                  Tab(text: 'All'.translate(context)),
                  Tab(text: 'selling'.translate(context)),
                  Tab(text: 'buying'.translate(context)),
                ],
                indicatorColor: context.color.textDefaultColor,
                indicatorWeight: 1.5,
                labelColor: context.color.textDefaultColor,
                unselectedLabelColor: context.color.textDefaultColor.withValues(
                  alpha: 0.5,
                ),
                labelStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                labelPadding: const EdgeInsets.symmetric(horizontal: 16),
                indicatorSize: TabBarIndicatorSize.tab,
              ),
              Divider(
                height: 0,
                thickness: 0.5,
                color: context.color.textDefaultColor.withValues(alpha: 0.2),
              ),
            ],
          ),
          body: TabBarView(
            children: [
              // Content of the 'All' tab (Combined list)
              allChatListData(),
              // Content of the 'Selling' tab
              sellingChatListData(),
              // Content of the 'Buying' tab
              buyingChatListData(),
            ],
          ),
        ),
      ),
    );
  }

  // Widget for the "All Chats" Tab (Combined List)
  Widget allChatListData() {
    return RefreshIndicator(
      triggerMode: RefreshIndicatorTriggerMode.anywhere,
      onRefresh: () async {
        // Fetch the combined list
        context.read<GetCombinedChatListCubit>().fetch();
      },
      color: context.color.territoryColor,
      child: BlocBuilder<GetCombinedChatListCubit, GetCombinedChatListState>(
        builder: (context, state) {
          if (state is GetCombinedChatListFailed) {
            if (state.error is ApiException) {
              if ((state.error as ApiException).errorMessage == "no-internet") {
                return NoInternet(
                  onRetry: () {
                    context.read<GetCombinedChatListCubit>().fetch();
                  },
                );
              }
            }
            return NoChatFound();
          }

          if (state is GetCombinedChatListInProgress) {
            return buildChatListLoadingShimmer();
          }

          if (state is GetCombinedChatListSuccess) {
            if (state.combinedChatList.isEmpty) {
              return NoChatFound();
            }

            return Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    controller:
                        chatCombinedScreenController, // Use the new controller
                    shrinkWrap: true,
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: state.combinedChatList.length,
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    itemBuilder: (context, index) {
                      ChatUser chatedUser = state.combinedChatList[index];

                      // Determine if this chat originated from the buyer or seller list
                      final bool isBuyerSideChat =
                          chatedUser.isBuyerChat ?? false;

                      // The ChatTile needs 'id' of the OTHER party (Seller for Buyer's chat, Buyer for Seller's chat)
                      final String partnerId = isBuyerSideChat
                          ? chatedUser.sellerId.toString()
                          : chatedUser.buyerId.toString();

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: ChatTile(
                          id: partnerId,
                          itemId: chatedUser.itemId.toString(),

                          isBuyerList: isBuyerSideChat,

                          // Profile/Name logic depends on who the current user is talking to
                          profilePicture: isBuyerSideChat
                              ? chatedUser.seller?.profile ?? ""
                              : chatedUser.buyer?.profile ?? "",
                          userName: isBuyerSideChat
                              ? chatedUser.seller?.name ?? ""
                              : chatedUser.buyer?.name ?? "",

                          itemPicture: chatedUser.item?.image ?? "",

                          itemName: chatedUser.item?.name?.localized ?? "",

                          pendingMessageCount:
                              "5", // Static value from original code
                          date: chatedUser.createdAt ?? '',
                          itemOfferId: chatedUser.id!,
                          itemPrice: chatedUser.item?.price?.toString(),
                          itemAmount: chatedUser.amount,
                          status: chatedUser.item?.status,

                          // If it's a buyer-side chat, buyerId is used as the current user's ID
                          buyerId: chatedUser.buyerId.toString(),

                          isPurchased: chatedUser.item?.isPurchased ?? 0,
                          alreadyReview: chatedUser.item?.review == null
                              ? false
                              : true,
                          unreadCount: chatedUser.unreadCount ?? 0,
                        ),
                      );
                    },
                  ),
                ),
                if (state.isLoadingMore) UiUtils.progress(),
              ],
            );
          }

          return Container();
        },
      ),
    );
  }

  // Widget for the "Buying" Tab
  Widget buyingChatListData() {
    // Existing implementation remains the same
    return RefreshIndicator(
      triggerMode: RefreshIndicatorTriggerMode.anywhere,
      onRefresh: () async {
        context.read<GetBuyerChatListCubit>().fetch();
      },
      color: context.color.territoryColor,
      child: BlocBuilder<GetBuyerChatListCubit, GetBuyerChatListState>(
        builder: (context, state) {
          if (state is GetBuyerChatListFailed) {
            if (state.error is ApiException) {
              if ((state.error as ApiException).errorMessage == "no-internet") {
                return NoInternet(
                  onRetry: () {
                    context.read<GetBuyerChatListCubit>().fetch();
                  },
                );
              }
            }

            return NoChatFound();
          }

          if (state is GetBuyerChatListInProgress) {
            return buildChatListLoadingShimmer();
          }
          if (state is GetBuyerChatListSuccess) {
            if (state.chatedUserList.isEmpty) {
              return NoChatFound();
            }
            return Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    controller: chatBuyerScreenController,
                    shrinkWrap: true,
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: state.chatedUserList.length,
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    itemBuilder: (context, index) {
                      ChatUser chatedUser = state.chatedUserList[index];

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: ChatTile(
                          id: chatedUser.sellerId.toString(),
                          itemId: chatedUser.itemId.toString(),
                          isBuyerList: true,
                          profilePicture: chatedUser.seller?.profile ?? "",
                          userName: chatedUser.seller?.name ?? "",
                          itemPicture: chatedUser.item?.image ?? "",
                          itemName: chatedUser.item?.name?.localized ?? "",
                          pendingMessageCount: "5",
                          date: chatedUser.createdAt!,
                          itemOfferId: chatedUser.id!,
                          itemPrice: chatedUser.item?.price.toString(),
                          itemAmount: chatedUser.amount,
                          status: chatedUser.item?.status,
                          buyerId: chatedUser.buyerId.toString(),
                          isPurchased: chatedUser.item?.isPurchased ?? 0,
                          alreadyReview: chatedUser.item?.review == null
                              ? false
                              : true,
                          unreadCount: chatedUser.unreadCount ?? 0,
                        ),
                      );
                    },
                  ),
                ),
                if (state.isLoadingMore) UiUtils.progress(),
              ],
            );
          }

          return Container();
        },
      ),
    );
  }

  // Widget for the "Selling" Tab
  Widget sellingChatListData() {
    // Existing implementation remains the same
    return RefreshIndicator(
      triggerMode: RefreshIndicatorTriggerMode.anywhere,
      onRefresh: () async {
        context.read<GetSellerChatListCubit>().fetch();
      },
      color: context.color.territoryColor,
      child: BlocBuilder<GetSellerChatListCubit, GetSellerChatListState>(
        builder: (context, state) {
          if (state is GetSellerChatListFailed) {
            if (state.error is ApiException) {
              if ((state.error as ApiException).errorMessage == "no-internet") {
                return NoInternet(
                  onRetry: () {
                    context.read<GetSellerChatListCubit>().fetch();
                  },
                );
              }
            }

            return NoChatFound();
          }

          if (state is GetSellerChatListInProgress) {
            return buildChatListLoadingShimmer();
          }
          if (state is GetSellerChatListSuccess) {
            if (state.chatedUserList.isEmpty) {
              return NoChatFound();
            }
            return Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    controller: chatSellerScreenController,
                    shrinkWrap: true,
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: state.chatedUserList.length,
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    itemBuilder: (context, index) {
                      ChatUser chatedUser = state.chatedUserList[index];

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: ChatTile(
                          id: chatedUser.buyerId.toString(),
                          itemId: chatedUser.itemId.toString(),
                          isBuyerList: false,
                          profilePicture: chatedUser.buyer?.profile ?? "",
                          userName: chatedUser.buyer?.name ?? "",
                          itemPicture: chatedUser.item?.image ?? "",
                          itemName: chatedUser.item?.name?.localized ?? "",
                          pendingMessageCount: "5",
                          date: chatedUser.createdAt ?? '',
                          itemOfferId: chatedUser.id!,
                          itemPrice: chatedUser.item?.price.toString(),
                          itemAmount: chatedUser.amount,
                          status: chatedUser.item?.status,
                          buyerId: chatedUser.buyerId.toString(),
                          isPurchased: chatedUser.item?.isPurchased ?? 0,
                          alreadyReview: chatedUser.item?.review == null
                              ? false
                              : true,
                          unreadCount: chatedUser.unreadCount ?? 0,
                        ),
                      );
                    },
                  ),
                ),
                if (state.isLoadingMore) UiUtils.progress(),
              ],
            );
          }

          return Container();
        },
      ),
    );
  }

  // Shimmer Widget (Moved here for consistency)
  Widget buildChatListLoadingShimmer() {
    return ListView.builder(
      itemCount: 10,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsetsDirectional.all(16),
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(top: 9.0),
          child: SizedBox(
            height: 74,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Shimmer.fromColors(
                    baseColor: Theme.of(context).colorScheme.shimmerBaseColor,
                    highlightColor: Theme.of(
                      context,
                    ).colorScheme.shimmerHighlightColor,
                    child: Stack(
                      children: [
                        const SizedBox(width: 58, height: 58),
                        GestureDetector(
                          onTap: () {},
                          child: Container(
                            width: 42,
                            height: 42,
                            clipBehavior: Clip.antiAlias,
                            decoration: BoxDecoration(
                              color: Colors.grey,
                              border: Border.all(
                                width: 1.5,
                                color: Colors.white,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        PositionedDirectional(
                          end: 0,
                          bottom: 0,
                          child: GestureDetector(
                            onTap: () {},
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              child: CircleAvatar(
                                radius: 15,
                                backgroundColor: context.color.territoryColor,
                                // backgroundImage: NetworkImage(profilePicture),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Using a dummy widget for CustomShimmer since its definition is missing
                      Container(
                        height: 10,
                        width: context.screenWidth * 0.53,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(5),
                          color: Colors.grey.shade300,
                        ),
                      ),
                      Container(
                        height: 10,
                        width: context.screenWidth * 0.3,
                        margin: const EdgeInsets.only(top: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(5),
                          color: Colors.grey.shade300,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // NoChatFound Widget (Moved here for consistency)
  Widget NoChatFound() {
    return const Center(
      child: Text("No Chats Found"), // Replace with your actual UI
    );
  }

  @override
  bool get wantKeepAlive => true;
}
