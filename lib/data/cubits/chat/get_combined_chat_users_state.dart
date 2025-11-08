// Path: data/cubits/chat/get_combined_chat_users_state.dart

import 'package:Tijaraa/data/model/chat/chat_user_model.dart';

abstract class GetCombinedChatListState {}

class GetCombinedChatListInitial extends GetCombinedChatListState {}

class GetCombinedChatListInProgress extends GetCombinedChatListState {}

class GetCombinedChatListSuccess extends GetCombinedChatListState {
  final int totalBuyerChats;
  final int totalSellerChats;
  final bool isLoadingMore;
  final bool hasError;

  // Current page trackers for individual API calls
  final int buyerPage;
  final int sellerPage;

  // The final combined and sorted list
  final List<ChatUser> combinedChatList;

  GetCombinedChatListSuccess({
    required this.totalBuyerChats,
    required this.totalSellerChats,
    required this.isLoadingMore,
    required this.hasError,
    required this.combinedChatList,
    required this.buyerPage,
    required this.sellerPage,
  });

  GetCombinedChatListSuccess copyWith({
    int? totalBuyerChats,
    int? totalSellerChats,
    bool? isLoadingMore,
    bool? hasError,
    List<ChatUser>? combinedChatList,
    int? buyerPage,
    int? sellerPage,
  }) {
    return GetCombinedChatListSuccess(
      totalBuyerChats: totalBuyerChats ?? this.totalBuyerChats,
      totalSellerChats: totalSellerChats ?? this.totalSellerChats,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasError: hasError ?? this.hasError,
      combinedChatList: combinedChatList ?? this.combinedChatList,
      buyerPage: buyerPage ?? this.buyerPage,
      sellerPage: sellerPage ?? this.sellerPage,
    );
  }
}

class GetCombinedChatListFailed extends GetCombinedChatListState {
  final dynamic error;

  GetCombinedChatListFailed(this.error);
}
