import 'dart:io';

import 'package:Tijaraa/data/model/data_output.dart';
import 'package:Tijaraa/data/model/item/item_filter_model.dart';
import 'package:Tijaraa/data/model/item/item_model.dart';
import 'package:Tijaraa/data/model/location/leaf_location.dart';
import 'package:Tijaraa/utils/api.dart';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as path;

class ItemRepository {
  Future<ItemModel> createItem(
    Map<String, dynamic> itemDetails,
    File mainImage,
    List<File>? otherImages,
  ) async {
    try {
      // 1. Create a deep copy and clone any existing MultipartFiles
      Map<String, dynamic> parameters = {};

      itemDetails.forEach((key, value) {
        if (value is MultipartFile) {
          // This is the crucial fix for custom_field_files
          parameters[key] = value.clone();
        } else {
          parameters[key] = value;
        }
      });

      // 2. Add the main image
      parameters[Api.image] = await MultipartFile.fromFile(
        mainImage.path,
        filename: path.basename(mainImage.path),
      );

      // 3. Add gallery images
      if (otherImages != null && otherImages.isNotEmpty) {
        parameters["gallery_images"] = await Future.wait(
          otherImages.map(
            (file) => MultipartFile.fromFile(
              file.path,
              filename: path.basename(file.path),
            ),
          ),
        );
      }

      parameters[Api.showOnlyToPremium] = 1;

      // 4. Send Request
      Map<String, dynamic> response = await Api.post(
        url: Api.addItemApi,
        parameter: parameters,
      );
      if (response['error'] == false) {
        final rawData = response['data'];

        // Check if data is a List and has at least one item
        if (rawData is List && rawData.isNotEmpty) {
          // Pass the FIRST MAP in the list to your model
          return ItemModel.fromJson(rawData.first);
        } else if (rawData is Map<String, dynamic>) {
          // If it's a direct Map, use it as is
          return ItemModel.fromJson(rawData);
        } else {
          throw "Unexpected data format from server";
        }
      } else {
        throw response['message'] ?? "Failed to add item";
      }
      final rawData = response['data'];
      if (rawData == null || (rawData is List && rawData.isEmpty)) {
        throw Exception("API returned empty data");
      }

      final itemJson = rawData is List ? rawData.first : rawData;
      return ItemModel.fromJson(itemJson);
    } catch (e) {
      rethrow;
    }
  }

  /// FETCH FEATURED ITEMS
  Future<DataOutput<ItemModel>> fetchMyFeaturedItems({int? page}) async {
    try {
      Map<String, dynamic> parameters = {
        Api.status: "featured",
        if (page != null) Api.page: page,
      };

      Map<String, dynamic> response = await Api.get(
        url: Api.getMyItemApi,
        queryParameters: parameters,
      );

      final rawData = response['data']?['data'] ?? [];
      List<ItemModel> itemList = (rawData as List)
          .map((e) => ItemModel.fromJson(e))
          .toList();

      return DataOutput(
        total: response['data']?['total'] ?? itemList.length,
        modelList: itemList,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// FETCH MY ITEMS (SAFE VERSION)
  Future<DataOutput<ItemModel>> fetchMyItems({
    String? getItemsWithStatus,
    int? page,
    int? id,
  }) async {
    try {
      Map<String, dynamic> parameters = {
        if (getItemsWithStatus != null && getItemsWithStatus.isNotEmpty)
          Api.status: getItemsWithStatus,
        if (page != null) Api.page: page,
        if (id != null) Api.id: id,
      };

      Map<String, dynamic> response = await Api.get(
        url: Api.getMyItemApi,
        queryParameters: parameters,
      );

      final rawData = response['data']?['data'] ?? [];
      List<ItemModel> itemList = (rawData as List)
          .map((e) => ItemModel.fromJson(e))
          .toList();

      return DataOutput(
        total: response['data']?['total'] ?? itemList.length,
        modelList: itemList,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// FETCH ITEM BY ITEM ID
  Future<DataOutput<ItemModel>> fetchItemFromItemId(int id) async {
    Map<String, dynamic> parameters = {Api.id: id};

    Map<String, dynamic> response = await Api.get(
      url: Api.getItemApi,
      queryParameters: parameters,
    );

    final rawData = response['data'] ?? [];
    List<ItemModel> modelList = (rawData as List)
        .map((e) => ItemModel.fromJson(e))
        .toList();

    return DataOutput(total: modelList.length, modelList: modelList);
  }

  /// FETCH ITEM BY SLUG
  Future<DataOutput<ItemModel>> fetchItemFromItemSlug(String slug) async {
    Map<String, dynamic> parameters = {Api.slug: slug};

    Map<String, dynamic> response = await Api.get(
      url: Api.getItemApi,
      queryParameters: parameters,
    );

    final rawData = response['data']?['data'] ?? [];
    List<ItemModel> modelList = (rawData as List)
        .map((e) => ItemModel.fromJson(e))
        .toList();

    return DataOutput(total: modelList.length, modelList: modelList);
  }

  /// CHANGE ITEM STATUS
  Future<Map> changeMyItemStatus({
    required int itemId,
    required String status,
    int? userId,
  }) async {
    Map response = await Api.post(
      url: Api.updateItemStatusApi,
      parameter: {
        Api.status: status,
        Api.itemId: itemId,
        if (userId != null) Api.soldTo: userId,
      },
    );
    return response;
  }

  /// CREATE FEATURED ADS
  Future<Map> createFeaturedAds({required int itemId}) async {
    Map response = await Api.post(
      url: Api.makeItemFeaturedApi,
      parameter: {Api.itemId: itemId},
    );
    return response;
  }

  /// FETCH ITEMS BY CATEGORY
  Future<DataOutput<ItemModel>> fetchItemFromCatId({
    required int categoryId,
    required int page,
    LeafLocation? location,
    String? search,
    String? sortBy,
    ItemFilterModel? filter,
  }) async {
    Map<String, dynamic> parameters = {
      Api.categoryId: categoryId,
      Api.page: page,
    };

    if (filter != null) {
      parameters.addAll(filter.toMap());

      if (filter.customFields != null) {
        filter.customFields!.forEach((key, value) {
          if (value is List) {
            parameters[key] = value.map((v) => v.toString()).join(',');
          } else {
            parameters[key] = value.toString();
          }
        });
      }
    } else if (location != null) {
      parameters.addAll(location.toApiJson());
    }

    if (search != null) parameters[Api.search] = search;
    if (sortBy != null) parameters[Api.sortBy] = sortBy;

    Map<String, dynamic> response = await Api.get(
      url: Api.getItemApi,
      queryParameters: parameters,
    );

    final rawData = response['data']?['data'] ?? [];
    List<ItemModel> items = (rawData as List)
        .map((e) => ItemModel.fromJson(e))
        .toList();

    return DataOutput(total: response['data']?['total'] ?? 0, modelList: items);
  }

  /// FETCH POPULAR ITEMS
  Future<DataOutput<ItemModel>> fetchPopularItems({
    required String sortBy,
    required int page,
    required LeafLocation? location,
  }) async {
    Map<String, dynamic> parameters = {
      Api.sortBy: sortBy,
      Api.page: page,
      ...?location?.toApiJson(),
    };

    Map<String, dynamic> response = await Api.get(
      url: Api.getItemApi,
      queryParameters: parameters,
    );

    final rawData = response['data']?['data'] ?? [];
    List<ItemModel> items = (rawData as List)
        .map((e) => ItemModel.fromJson(e))
        .toList();

    return DataOutput(total: response['data']?['total'] ?? 0, modelList: items);
  }

  Future<ItemModel> editItem(
    Map<String, dynamic> itemDetails,
    File? mainImage,
    List<File>? otherImages,
  ) async {
    // Use the same cloning logic here
    Map<String, dynamic> parameters = {};
    itemDetails.forEach((key, value) {
      if (value is MultipartFile) {
        parameters[key] = value.clone(); // Fix for reused files
      } else {
        parameters[key] = value;
      }
    });

    if (mainImage != null) {
      parameters[Api.image] = await MultipartFile.fromFile(
        mainImage.path,
        filename: path.basename(mainImage.path),
      );
    }

    if (otherImages != null && otherImages.isNotEmpty) {
      final List<MultipartFile> galleryMultipartFiles = await Future.wait(
        otherImages.map(
          (file) => MultipartFile.fromFile(
            file.path,
            filename: path.basename(file.path),
          ),
        ),
      );
      parameters[Api.galleryImages] = galleryMultipartFiles;
    }

    if (itemDetails.containsKey('translations')) {
      parameters['translations'] = itemDetails['translations'];
    }
    if (itemDetails.containsKey('custom_field_translations')) {
      parameters['custom_field_translations'] =
          itemDetails['custom_field_translations'];
    }

    Map<String, dynamic> response = await Api.post(
      url: Api.updateItemApi,
      parameter: parameters,
    );

    final rawData = response['data'];
    if (rawData == null || (rawData is List && rawData.isEmpty)) {
      throw Exception("API returned empty data");
    }

    final itemJson = rawData is List ? rawData.first : rawData;
    return ItemModel.fromJson(itemJson);
  }

  /// DELETE ITEM
  Future<void> deleteItem(int id) async {
    await Api.post(url: Api.deleteItemApi, parameter: {Api.itemId: id});
  }

  /// ITEM TOTAL CLICK
  Future<void> itemTotalClick(int id) async {
    await Api.post(url: Api.setItemTotalClickApi, parameter: {Api.itemId: id});
  }

  /// MAKE AN OFFER
  Future<Map> makeAnOfferItem(int id, double? amount) async {
    Map response = await Api.post(
      url: Api.itemOfferApi,
      parameter: {Api.itemId: id, if (amount != null) Api.amount: amount},
    );
    return response;
  }

  /// SEARCH ITEM
  Future<DataOutput<ItemModel>> searchItem(
    String query,
    ItemFilterModel? filter, {
    required int page,
  }) async {
    Map<String, dynamic> parameters = {
      Api.search: query,
      Api.page: page,
      if (filter != null) ...filter.toMap(),
    };

    if (filter != null) {
      parameters.remove(Api.area);
      if (filter.customFields != null) {
        parameters.addAll(filter.customFields!);
      }
    }

    Map<String, dynamic> response = await Api.get(
      url: Api.getItemApi,
      queryParameters: parameters,
    );

    final rawData = response['data']?['data'] ?? [];
    List<ItemModel> items = (rawData as List)
        .map((e) => ItemModel.fromJson(e))
        .toList();

    return DataOutput(total: response['data']?['total'] ?? 0, modelList: items);
  }
}
