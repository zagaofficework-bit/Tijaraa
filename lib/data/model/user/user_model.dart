class UserModel {
  String? address;
  String? createdAt;
  int? customerTotalPost;
  String? email;
  String? fcmId;
  String? firebaseId;
  int? id;
  int? isActive;
  bool? isProfileCompleted;
  String? type;
  String? mobile;
  String? name;
  int? isPersonalDetailShow;
  int? notification;
  String? profile;
  String? token;
  String? updatedAt;

  // Changed these to bool to match Laravel $casts
  bool? isVerified;
  bool? isEmailVerified;
  bool? isPhoneVerified;

  UserModel({
    this.address,
    this.createdAt,
    this.customerTotalPost,
    this.email,
    this.fcmId,
    this.firebaseId,
    this.id,
    this.isActive,
    this.isProfileCompleted,
    this.type,
    this.mobile,
    this.name,
    this.notification,
    this.profile,
    this.token,
    this.updatedAt,
    this.isPersonalDetailShow,
    this.isVerified,
    this.isEmailVerified,
    this.isPhoneVerified,
  });

  UserModel.fromJson(Map<String, dynamic> json) {
    address = json['address'];
    createdAt = json['created_at'];
    customerTotalPost = json['customertotalpost'] as int?;
    email = json['email'];
    fcmId = json['fcm_id'];
    firebaseId = json['firebase_id'];
    id = json['id'];
    isActive = json['isActive'] as int?;
    isProfileCompleted = json['isProfileCompleted'] is bool
        ? json['isProfileCompleted']
        : (json['isProfileCompleted'].toString() == "1");
    type = json['type'];
    mobile = json['mobile'];
    name = json['name'];

    // Safely parse notification
    notification = json['notification'] == null
        ? null
        : (json['notification'] is bool
              ? (json['notification'] ? 1 : 0)
              : int.tryParse(json['notification'].toString()));

    profile = json['profile'];
    token = json['token'];
    updatedAt = json['updated_at'];

    // --- FIXING THE CRASH HERE ---
    // Handle is_verified as bool
    isVerified = json['is_verified'] is bool
        ? json['is_verified']
        : (json['is_verified'].toString() == "1");

    isEmailVerified = json['is_email_verified'] is bool
        ? json['is_email_verified']
        : (json['is_email_verified'].toString() == "1");

    isPhoneVerified = json['is_phone_verified'] is bool
        ? json['is_phone_verified']
        : (json['is_phone_verified'].toString() == "1");

    // Safely parse personal details show
    isPersonalDetailShow = json['show_personal_details'] == null
        ? null
        : (json['show_personal_details'] is bool
              ? (json['show_personal_details'] ? 1 : 0)
              : int.tryParse(json['show_personal_details'].toString()));
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['address'] = address;
    data['created_at'] = createdAt;
    data['customertotalpost'] = customerTotalPost;
    data['email'] = email;
    data['fcm_id'] = fcmId;
    data['firebase_id'] = firebaseId;
    data['id'] = id;
    data['isActive'] = isActive;
    data['isProfileCompleted'] = isProfileCompleted;
    data['type'] = type;
    data['mobile'] = mobile;
    data['name'] = name;
    data['notification'] = notification;
    data['profile'] = profile;
    data['token'] = token;
    data['updated_at'] = updatedAt;
    data['show_personal_details'] = isPersonalDetailShow;
    data['is_verified'] = isVerified;
    data['is_email_verified'] = isEmailVerified;
    data['is_phone_verified'] = isPhoneVerified;
    return data;
  }
}

class BuyerModel {
  int? id;
  String? name;
  String? profile;

  BuyerModel({this.id, this.name, this.profile});

  BuyerModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    profile = json['profile'];
  }

  BuyerModel.fromJobApplicationJson(Map<String, dynamic> json) {
    id = json['user_id'];
    name = json['full_name'];
    profile = '';
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['name'] = this.name;
    data['profile'] = this.profile;
    return data;
  }
}

class JobProfileModel {
  String? title;
  String? skills;
  String? experience;
  String? expectedSalary;
  String? resumePath;

  JobProfileModel({
    this.title,
    this.skills,
    this.experience,
    this.expectedSalary,
    this.resumePath,
  });

  factory JobProfileModel.fromJson(Map<String, dynamic> json) {
    return JobProfileModel(
      title: json['title'],
      skills: json['skills'],
      experience: json['experience'],
      expectedSalary: json['expectedSalary'],
      resumePath: json['resumePath'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'skills': skills,
      'experience': experience,
      'expectedSalary': expectedSalary,
      'resumePath': resumePath,
    };
  }
}
