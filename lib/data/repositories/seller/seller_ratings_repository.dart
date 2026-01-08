import 'package:Tijaraa/data/model/data_output.dart';
import 'package:Tijaraa/data/model/user/seller_ratings_model.dart';
import 'package:Tijaraa/utils/api.dart';

class SellerRatingsRepository {
  Future<DataOutput<UserRatings>> fetchSellerRatingsAllRatings({
    required int sellerId,
    required int page,
  }) async {
    try {
      Map<String, dynamic> parameters = {Api.id: sellerId, Api.page: page};

      Map<String, dynamic> response = await Api.get(
        url: Api.getSellerApi,
        queryParameters: parameters,
      );

      // 1. Correctly access the nested data
      var responseData = response["data"];

      // 2. Parse the seller info
      // Ensure your Seller.fromJson can handle null fields like 'average_rating'
      var seller = Seller.fromJson(responseData['seller']);

      // 3. Correctly access the nested ratings list inside the pagination object
      // Note: the API returns ratings -> data -> [List]
      List<UserRatings> userRatings = [];
      int totalRatings = 0;

      if (responseData['ratings'] != null) {
        totalRatings = responseData['ratings']['total'] ?? 0;

        if (responseData['ratings']['data'] != null) {
          userRatings = (responseData['ratings']['data'] as List)
              .map((e) => UserRatings.fromJson(e))
              .toList();
        }
      }

      return DataOutput(
        total: totalRatings,
        modelList: userRatings,
        extraData: ExtraData(data: seller),
      );
    } catch (error) {
      print(
        "ERROR PARSING SELLER: $error",
      ); // Add this to see the exact error in console
      rethrow;
    }
  }
}
