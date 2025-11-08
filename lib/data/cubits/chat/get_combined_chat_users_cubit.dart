import 'package:Tijaraa/data/cubits/chat/get_combined_chat_users_state.dart';
import 'package:Tijaraa/data/model/chat/chat_user_model.dart';
import 'package:Tijaraa/data/model/data_output.dart';
import 'package:Tijaraa/data/repositories/chat_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class GetCombinedChatListCubit extends Cubit<GetCombinedChatListState> {
  GetCombinedChatListCubit() : super(GetCombinedChatListInitial());
  final ChatRepository _chatRepository = ChatRepository();

  // Helper function to merge and sort the lists
  List<ChatUser> _mergeAndSortLists(
    List<ChatUser> list1,
    List<ChatUser> list2,
  ) {
    // Combine both lists
    final List<ChatUser> combined = [...list1, ...list2];

    // Remove duplicates
    final Set<String> seenIds = {};
    final List<ChatUser> uniqueCombined = combined.where((chat) {
      // FIX 1: Used 'chat.id' as the unique identifier for the conversation entry.
      final key = '${chat.id}';
      if (seenIds.contains(key)) {
        return false;
      } else {
        seenIds.add(key);
        return true;
      }
    }).toList();

    // Sort by createdAt (latest message first)
    uniqueCombined.sort((a, b) {
      // Assuming createdAt is a string that can be parsed as DateTime
      final dateA = DateTime.tryParse(a.createdAt ?? "") ?? DateTime(1900);
      final dateB = DateTime.tryParse(b.createdAt ?? "") ?? DateTime(1900);
      return dateB.compareTo(dateA); // Descending order (newest first)
    });

    return uniqueCombined;
  }

  void fetch() async {
    try {
      emit(GetCombinedChatListInProgress());

      // Fetch both lists concurrently
      List<DataOutput<ChatUser>> results = await Future.wait([
        _chatRepository.fetchBuyerChatList(1),
        _chatRepository.fetchSellerChatList(1),
      ]);

      final buyerResult = results[0];
      final sellerResult = results[1];

      final combinedList = _mergeAndSortLists(
        buyerResult.modelList,
        sellerResult.modelList,
      );

      emit(
        GetCombinedChatListSuccess(
          isLoadingMore: false,
          hasError: false,
          combinedChatList: combinedList,
          totalBuyerChats: buyerResult.total,
          totalSellerChats: sellerResult.total,
          buyerPage: 1,
          sellerPage: 1,
        ),
      );
    } catch (e) {
      emit(GetCombinedChatListFailed(e));
    }
  }

  Future<void> loadMore() async {
    if (state is! GetCombinedChatListSuccess) return;

    final currentState = state as GetCombinedChatListSuccess;
    if (currentState.isLoadingMore) return;

    emit(currentState.copyWith(isLoadingMore: true));

    try {
      // FIX 2, 3: Replaced 'isBuyer' with 'isBuyerChat == true'
      final bool hasMoreBuyer =
          currentState.combinedChatList
              .where((c) => c.isBuyerChat == true)
              .length <
          currentState.totalBuyerChats;

      // FIX 4, 5: Replaced 'isSeller' and 'isSellerList' with 'isBuyerChat == false'
      final bool hasMoreSeller =
          currentState.combinedChatList
              .where((c) => c.isBuyerChat == false)
              .length <
          currentState.totalSellerChats;

      DataOutput<ChatUser>? newBuyerData;
      DataOutput<ChatUser>? newSellerData;

      // Prioritize loading the list that has more data remaining
      if (hasMoreBuyer) {
        newBuyerData = await _chatRepository.fetchBuyerChatList(
          currentState.buyerPage + 1,
        );
      } else if (hasMoreSeller) {
        newSellerData = await _chatRepository.fetchSellerChatList(
          currentState.sellerPage + 1,
        );
      } else {
        // No more data to load from either list
        emit(currentState.copyWith(isLoadingMore: false));
        return;
      }

      // Collect all current and new data
      // FIX 2: Replaced 'isBuyer' with 'isBuyerChat == true'
      List<ChatUser> currentBuyerChats = currentState.combinedChatList
          .where((c) => c.isBuyerChat == true)
          .toList();

      // FIX 4: Replaced 'isSeller' with 'isBuyerChat == false'
      List<ChatUser> currentSellerChats = currentState.combinedChatList
          .where((c) => c.isBuyerChat == false)
          .toList();

      if (newBuyerData != null) {
        currentBuyerChats.addAll(newBuyerData.modelList);
      }
      if (newSellerData != null) {
        currentSellerChats.addAll(newSellerData.modelList);
      }

      final newCombinedList = _mergeAndSortLists(
        currentBuyerChats,
        currentSellerChats,
      );

      emit(
        GetCombinedChatListSuccess(
          combinedChatList: newCombinedList,
          totalBuyerChats:
              currentState.totalBuyerChats, // Assuming totals don't change
          totalSellerChats:
              currentState.totalSellerChats, // Assuming totals don't change
          buyerPage: newBuyerData != null
              ? currentState.buyerPage + 1
              : currentState.buyerPage,
          sellerPage: newSellerData != null
              ? currentState.sellerPage + 1
              : currentState.sellerPage,
          hasError: false,
          isLoadingMore: false,
        ),
      );
    } catch (e) {
      emit(currentState.copyWith(isLoadingMore: false, hasError: true));
    }
  }

  // Simplified hasMoreData check for the combined list
  bool hasMoreData() {
    if (state is GetCombinedChatListSuccess) {
      final currentState = state as GetCombinedChatListSuccess;

      final loadedBuyer = currentState.combinedChatList
          .where((c) => c.isBuyerChat == true)
          .length;
      final loadedSeller = currentState.combinedChatList
          .where((c) => c.isBuyerChat == false)
          .length;

      final hasMoreBuyer = loadedBuyer < currentState.totalBuyerChats;
      final hasMoreSeller = loadedSeller < currentState.totalSellerChats;

      return hasMoreBuyer || hasMoreSeller;
    }

    return false;
  }
}
