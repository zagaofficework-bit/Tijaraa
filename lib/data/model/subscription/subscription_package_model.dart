class SubscriptionPackageModel {
  int? id;
  String? iosProductId;
  String? name;
  double? price;
  double? finalPrice;
  double? discount;
  String? duration;
  String? limit;
  String? type;
  String? icon;
  String? description;
  int? status;
  String? createdAt;
  String? updatedAt;
  bool? isActive;
  List<UserPurchasedPackages>? userPurchasedPackages;
  bool? isFreePackageUsed;
  String? freePackageMessage;

  SubscriptionPackageModel({
    this.id,
    this.iosProductId,
    this.name,
    this.price,
    this.finalPrice,
    this.discount,
    this.duration,
    this.limit,
    this.type,
    this.icon,
    this.description,
    this.status,
    this.createdAt,
    this.updatedAt,
    this.isActive,
    this.userPurchasedPackages,
  });

  SubscriptionPackageModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    iosProductId = json['ios_product_id']?.toString();
    name = json['translated_name'] ?? json['name'];

    price = json['price'] != null
        ? double.tryParse(json['price'].toString())
        : 0.0;

    discount = json['discount_in_percentage'] != null
        ? double.tryParse(json['discount_in_percentage'].toString())
        : 0.0;

    finalPrice = json['final_price'] != null
        ? double.tryParse(json['final_price'].toString())
        : 0.0;

    duration = json['duration']?.toString();
    limit = json['item_limit']?.toString();
    type = json['type'];
    icon = json['icon'];
    description = json['translated_description'] ?? json['description'];
    status = json['status'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];

    /// 🔧 IMPORTANT FIX
    isActive = json['is_active'] ?? false;
    isFreePackageUsed = json['is_free_package_used'] ?? false;
    freePackageMessage = json['free_package_message'];

    if (json['user_purchased_packages'] != null) {
      userPurchasedPackages = <UserPurchasedPackages>[];
      json['user_purchased_packages'].forEach((v) {
        userPurchasedPackages!.add(UserPurchasedPackages.fromJson(v));
      });
    } else {
      userPurchasedPackages = [];
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['ios_product_id'] = iosProductId;
    data['name'] = name;
    data['price'] = price;
    data['discount_in_percentage'] = discount;
    data['final_price'] = finalPrice;
    data['duration'] = duration;
    data['item_limit'] = limit;
    data['type'] = type;
    data['icon'] = icon;
    data['description'] = description;
    data['status'] = status;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    data['is_active'] = isActive;
    data['is_free_package_used'] = isFreePackageUsed;
    data['free_package_message'] = freePackageMessage;

    if (userPurchasedPackages != null) {
      data['user_purchased_packages'] = userPurchasedPackages!
          .map((v) => v.toJson())
          .toList();
    }
    return data;
  }

  @override
  String toString() {
    return 'SubscriptionPackageModel(id: $id, name: $name, duration: $duration, price: $price, final_price: $finalPrice, discount_in_percentage: $discount, status: $status, item_limit: $limit, type: $type, createdAt: $createdAt, updatedAt: $updatedAt, icon: $icon, description: $description, is_active: $isActive, is_free_package_used: $isFreePackageUsed)';
  }
}

class UserPurchasedPackages {
  int? id;
  int? userId;
  int? packageId;
  String? startDate;
  String? endDate;
  int? totalLimit;
  int? usedLimit;
  String? createdAt;
  String? updatedAt;
  String? remainingDays;
  String? remainingItemLimit;

  UserPurchasedPackages({
    this.id,
    this.userId,
    this.packageId,
    this.startDate,
    this.endDate,
    this.totalLimit,
    this.usedLimit,
    this.createdAt,
    this.updatedAt,
    this.remainingDays,
    this.remainingItemLimit,
  });

  UserPurchasedPackages.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    userId = json['user_id'];
    packageId = json['package_id'];
    startDate = json['start_date'];
    endDate = json['end_date'];
    totalLimit = json['total_limit'];
    usedLimit = json['used_limit'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];

    /// 🔧 FIX: API sends int OR string OR "unlimited"
    remainingDays = json['remaining_days']?.toString();
    remainingItemLimit = json['remaining_item_limit']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['user_id'] = userId;
    data['package_id'] = packageId;
    data['start_date'] = startDate;
    data['end_date'] = endDate;
    data['total_limit'] = totalLimit;
    data['used_limit'] = usedLimit;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    data['remaining_days'] = remainingDays;
    data['remaining_item_limit'] = remainingItemLimit;
    return data;
  }
}
