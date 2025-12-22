import 'package:Tijaraa/utils/api.dart';

class Type {
  String? id;
  String? type;

  Type({this.id, this.type});

  Type.fromJson(Map<String, dynamic> json) {
    id = json[Api.id]?.toString();
    type = json[Api.type]?.toString();
  }
}

class CategoryModel {
  final int? id;
  final String? name;
  final String? url;
  final List<CategoryModel>? children;
  final String? description;
  final int? subcategoriesCount;
  final int? isJobCategory;
  final int? priceOptional;

  CategoryModel({
    this.id,
    this.name,
    this.url,
    this.description,
    this.children,
    this.subcategoriesCount,
    this.isJobCategory,
    this.priceOptional,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    // 1. Extract subcategories safely
    List<CategoryModel> childrenList = [];
    if (json['subcategories'] != null && json['subcategories'] is List) {
      final List<dynamic> childData = json['subcategories'];
      if (childData.isNotEmpty) {
        childrenList = childData
            .map(
              (child) => CategoryModel.fromJson(child as Map<String, dynamic>),
            )
            .toList();
      }
    }

    // 2. Perform safe type conversion for potential Bool vs Int crashes
    // This is the fix for your "bool is not a subtype of int" error
    int safeIsJobCategory = 0;
    if (json['is_job_category'] is bool) {
      safeIsJobCategory = (json['is_job_category'] == true) ? 1 : 0;
    } else {
      safeIsJobCategory =
          int.tryParse(json['is_job_category']?.toString() ?? "0") ?? 0;
    }

    int safePriceOptional = 0;
    if (json['price_optional'] is bool) {
      safePriceOptional = (json['price_optional'] == true) ? 1 : 0;
    } else {
      safePriceOptional =
          int.tryParse(json['price_optional']?.toString() ?? "0") ?? 0;
    }

    // 3. Return the instance with NAMED arguments
    return CategoryModel(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? ""),
      name:
          json['translated_name']?.toString() ?? json['name']?.toString() ?? "",
      url: json['image']?.toString() ?? "",
      description: json['description']?.toString() ?? "",
      subcategoriesCount:
          int.tryParse(json['subcategories_count']?.toString() ?? "0") ?? 0,
      isJobCategory: safeIsJobCategory,
      priceOptional: safePriceOptional,
      children: childrenList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'translated_name': name,
      'image': url,
      'subcategories_count': subcategoriesCount,
      'description': description,
      'subcategories': children?.map((child) => child.toJson()).toList(),
      'is_job_category': isJobCategory,
      'price_optional': priceOptional,
    };
  }

  @override
  String toString() {
    return 'CategoryModel(id: $id, name: $name, url: $url, job: $isJobCategory)';
  }
}
