import 'dart:developer';
import 'dart:io';

import 'package:Tijaraa/app/routes.dart';
import 'package:Tijaraa/data/cubits/chat/blocked_users_list_cubit.dart';
import 'package:Tijaraa/data/cubits/chat/get_buyer_chat_users_cubit.dart';
import 'package:Tijaraa/data/cubits/favorite/favorite_cubit.dart';
import 'package:Tijaraa/data/cubits/item/job_application/fetch_job_application_cubit.dart';
import 'package:Tijaraa/data/cubits/report/update_report_items_list_cubit.dart';
import 'package:Tijaraa/data/cubits/system/user_details.dart';
import 'package:Tijaraa/utils/constant.dart';
import 'package:Tijaraa/utils/extensions/extensions.dart';
import 'package:Tijaraa/utils/helper_utils.dart';
import 'package:Tijaraa/utils/hive_utils.dart';
import 'package:Tijaraa/utils/network_request_interseptor.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ApiException implements Exception {
  ApiException(this.errorMessage);

  dynamic errorMessage;

  @override
  String toString() {
    return errorMessage.toString();
  }
}

class Api {
  static Dio _dio =
      Dio(
          BaseOptions(
            connectTimeout: const Duration(seconds: 30),
            receiveTimeout: const Duration(seconds: 30),
            sendTimeout: const Duration(seconds: 30),
          ),
        )
        ..interceptors.addAll([
          NetworkRequestInterceptor(),
          //CurlLoggerDioInterceptor(printOnSuccess: true),
        ]);

  static bool _isProcessing = false;

  static Map<String, dynamic> headers() {
    final token = HiveUtils.isUserAuthenticated() ? HiveUtils.getJWT() : null;
    return {
      if (token != null) "Authorization": "Bearer $token",
      "Accept": "application/json",
      "Content-Language": Constant.currentLanguageCode,
      // Always include User-Agent to prevent 403 Forbidden errors
      "User-Agent":
          "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
    };
  }

  //Twilio API
  static const String getTwilioOtp = 'get-otp';
  static const String verifyTwilioOtp = 'verify-otp';

  static String loginApi = "user-signup";
  static String updateProfileApi = "update-profile";
  static String userJobProfile = "userJobProfile";
  static String getSliderApi = "get-slider";
  static String sendEmailOtp = "send-email-otp";
  static String verifyEmailOtp = "verify-email-otp";
  static String sendPhoneOtp = "send-phone-otp";
  static String verifyPhoneOtp = "verify-phone-otp";

  static String getCategoriesApi = "get-categories";
  static String getItemApi = "get-item";
  static String getMyItemApi = "my-items";
  static String getNotificationListApi = "get-notification-list";
  static String deleteUserApi = "delete-user";
  static String manageFavouriteApi = "manage-favourite";
  static String getPackageApi = "get-package";
  static String getLanguageApi = "get-languages";
  static String getPaymentSettingsApi = "get-payment-settings";
  static String getSystemSettingsApi = "get-system-settings";
  static String getFavoriteItemApi = "get-favourite-item";
  static String updateItemStatusApi = "update-item-status";
  static String getReportReasonsApi = "get-report-reasons";
  static String addReportsApi = "add-reports";
  static String getCustomFieldsApi = "get-customfields";
  static String getFeaturedSectionApi = "get-featured-section";
  static String updateItemApi = "update-item";
  static String addItemApi = "add-item";
  static String deleteItemApi = "delete-item";
  static String setItemTotalClickApi = "set-item-total-click";
  static String makeItemFeaturedApi = "make-item-featured";
  static String assignFreePackageApi = "assign-free-package";
  static String getLimitsOfPackageApi = "get-limits";
  static String getPaymentIntentApi = "payment-intent";
  static String inAppPurchaseApi = "in-app-purchase";
  static String getTipsApi = "tips";
  static String getCountriesApi = "countries";
  static String getStatesApi = "states";
  static String getCitiesApi = "cities";
  static String getAreasApi = "areas";
  static String getBlogApi = "blogs";
  static String getFaqApi = "faq";
  static String getItemBuyerListApi = "item-buyer-list";
  static String getSellerApi = "get-seller";
  static String addItemReviewApi = "add-item-review";
  static String getVerificationFieldApi = "verification-fields";
  static String sendVerificationRequestApi = "send-verification-request";
  static String getVerificationRequestApi = "verification-request";
  static String getMyReviewApi = "my-review";
  static String addReviewReportApi = "add-review-report";
  static String renewItemApi = "renew-item";
  static String bankTransferUpdateApi = "bank-transfer-update";
  static String applyForJobApi = "job-apply";
  static String getJobApplicationsApi = "get-job-applications";
  static String myJobApplicationsApi = "my-job-applications";
  static String updateJobApplicationsStatusApi =
      "update-job-applications-status";
  static String getLocationApi = "get-location";

  static String sendMessageApi = "send-message";
  static String getChatListApi = "chat-list";
  static String itemOfferApi = "item-offer";
  static String chatMessagesApi = "chat-messages";
  static String blockUserApi = "block-user";
  static String unBlockUserApi = "unblock-user";
  static String blockedUsersListApi = "blocked-users";
  static String getPaymentDetailsApi = "payment-transactions";

  static String userPurchasePackageApi = "user-purchase-package";
  static String deleteInquiryApi = "delete-inquiry";
  static String setItemEnquiryApi = "set-item_-inquiry";
  static String getItemApiEnquiry = "get-item-inquiry";
  static String interestedUsersApi = "interested-users";
  static String storeAdvertisementApi = "store-advertisement";
  static String deleteAdvertisementApi = "delete-advertisement";
  static String deleteChatMessageApi = "delete-chat-message";

  //params
  static String id = "id";
  static String itemId = "item_id";
  static String mobile = "mobile";
  static String type = "type";
  static String itemOfferId = "item_offer_id";
  static String flag = "flag";
  static String firebaseId = "firebase_id";
  static String profile = "profile";
  static String fcmId = "fcm_id";
  static String address = "address";
  static String clientAddress = "client_address";
  static String email = "email";
  static String name = "name";
  static String amount = "amount";
  static String error = "error";
  static String message = "message";
  static String showOnlyToPremium = "show_only_to_premium";
  static String loginType = "logintype";
  static String isActive = "isActive";
  static String image = "image";
  static String category = "category";
  static String typeids = "typeids";
  static String userid = "userid";
  static String measurement = "measurement";
  static String categoryId = "category_id";
  static String title = "title";
  static String description = "description";
  static String price = "price";
  static String galleryImages = "gallery_images";
  static String purchaseToken = "purchase_token";
  static String resume = "resume";
  static String reportReasonId = "report_reason_id";
  static String otherMessage = "other_message";
  static String typeId = "type_id";
  static String itemType = "item_type";
  static String imageUrl = "image_url";
  static String gallery = "gallery";
  static String parameterTypes = "parameter_types";
  static String status = "status";
  static String platform = "platform";
  static String totalView = "total_view";
  static String slug = "slug";
  static String addedBy = "added_by";
  static String state = "state";
  static String city = "city";
  static String languageCode = "language_code";
  static String country = "country";
  static String areaId = "area_id";
  static String area = "area";
  static String radius = "radius";
  static String latitude = "latitude";
  static String longitude = "longitude";
  static String lat = "lat";
  static String lng = "lng";
  static String lang = "lang";
  static String placeId = "place_id";

  static String bathroom = "bathroom";
  static String aboutUs = "about_us";
  static String contactUs = "contact_us";
  static String termsAndConditions = "terms_conditions";
  static String privacyPolicy = "privacy_policy";
  static String currencySymbol = "currency_symbol";
  static String company = "company";
  static String data = "data";
  static String customerId = "customer_id";
  static String itemsId = "items_id";
  static String customersId = "customers_id";
  static String search = "search";
  static String createdAt = "created_at";
  static String sendType = "send_type";
  static String created = "created";
  static String compName = "company_name";
  static String compWebsite = "company_website";
  static String compEmail = "company_email";
  static String compAdrs = "company_address";
  static String tele1 = "company_tel1";
  static String tele2 = "company_tel2";
  static String maintenanceMode = "maintenance_mode";
  static String maxPrice = "max_price";
  static String minPrice = "min_price";
  static String postedSince = "posted_since";
  static String file = "file";
  static String audio = "audio";
  static String blockedUserId = "blocked_user_id";
  static String userId = "user_id";

  static String item = "item";
  static String page = "page";
  static String topRated = "top_rated";
  static String promoted = "promoted";
  static String packageId = "package_id";
  static String paymentMethod = "payment_method";
  static String notification = "notification";
  static String v360degImage = "threeD_image";
  static String videoLink = "video_link";
  static String categoryIds = "category_ids";
  static String sortBy = "sort_by";
  static String stateId = "state_id";
  static String countryId = "country_id";
  static String cityId = "city_id";
  static String countryCode = "country_code";
  static String personalDetail = "show_personal_details";
  static String soldTo = "sold_to";
  static String ratings = "ratings";
  static String review = "review";
  static String platformType = "platform_type";
  static String sellerReviewId = "seller_review_id";
  static String reportReason = "report_reason";
  static String featuredSectionId = "featured_section_id";
  static String packageType = "package_type";
  static String paymentTransectionId = "payment_transection_id";
  static String paymentReceipt = "payment_receipt";
  static String jobId = "job_id";
  static String popularItems = "popular_items";
  static String advertisement = "advertisement";
  static String razorpay = "Razorpay";
  static String payStack = "Paystack";
  static String stripe = "Stripe";
  static String phonePe = "PhonePe";
  static String flutterwave = "flutterwave";
  static String bankTransfer = "bankTransfer";
  static String apiKey = "api_key";
  static String currencyCode = "currency_code";
  static String accountHolderName = "account_holder_name";
  static String accountNumber = "account_number";
  static String bankName = "bank_name";
  static String ifscSwiftCode = "ifsc_swift_code";

  static Future<Map<String, dynamic>> post({
    required String url,
    dynamic parameter,
    Options? options,
    bool? useBaseUrl,
  }) async {
    try {
      late dynamic requestData;

      if (parameter is Map<String, dynamic>) {
        Map<String, dynamic> formMap = {};

        parameter.forEach((key, value) {
          if (value is File) {
            formMap[key] = MultipartFile.fromFileSync(
              value.path,
              filename: value.path.split('/').last,
            );
          } else if (value is List<File>) {
            formMap[key] = value
                .map(
                  (file) => MultipartFile.fromFileSync(
                    file.path,
                    filename: file.path.split('/').last,
                  ),
                )
                .toList();
          } else {
            formMap[key] = value;
          }
        });

        requestData = FormData.fromMap(formMap, ListFormat.multiCompatible);
      } else {
        // Handle cases where parameters might be raw JSON or other types
        requestData = parameter;
      }

      final response = await _dio.post(
        ((useBaseUrl ?? true) ? Constant.baseUrl : "") + url,
        data: requestData,
        options: Options(
          // contentType is important for file uploads
          contentType: parameter is Map<String, dynamic>
              ? "multipart/form-data"
              : "application/json",
          headers: headers(), // This now includes the critical User-Agent
        ),
      );

      // Check if response is actually a Map (JSON) before accessing keys
      if (response.data is Map) {
        var resp = response.data;

        if (resp['error'] ?? false) {
          throw ApiException(resp['message']?.toString() ?? "Unknown Error");
        }

        return Map<String, dynamic>.from(resp);
      } else {
        throw ApiException("Server returned an invalid format.");
      }
    } on DioException catch (e, st) {
      log("Dio Error: ${e.message}", stackTrace: st);

      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw ApiException("Server connection timed out. Please try again.");
      }

      if (e.response?.statusCode == 401) {
        userExpired();
        throw ApiException("Session expired. Please log in again.");
      }

      if (e.response?.statusCode == 503) {
        throw "server-not-available";
      }

      // Check for 403 (Commonly caused by missing User-Agent/WAF)
      if (e.response?.statusCode == 403) {
        throw ApiException("Access Denied: Please contact support.");
      }

      throw ApiException(
        e.error is SocketException
            ? "no-internet"
            : "Request failed with status: ${e.response?.statusCode}",
      );
    } on ApiException catch (e) {
      rethrow;
    } catch (e, st) {
      log("General Error in Post: $e", stackTrace: st);
      throw ApiException(e.toString());
    }
  }

  static void userExpired() {
    if (!_isProcessing) {
      _isProcessing = true;
      HelperUtils.showSnackBarMessage(
        Constant.navigatorKey.currentContext!,
        "sessionExpiredPleaseLogin".translate(
          Constant.navigatorKey.currentContext!,
        ), // Better
        messageDuration: 3,
        isFloating: true,
      );
      Future.delayed(Duration(seconds: 2), () async {
        Constant.favoriteItemList.clear();
        Constant.navigatorKey.currentContext!.read<UserDetailsCubit>().clear();
        Constant.navigatorKey.currentContext!
            .read<FavoriteCubit>()
            .resetState();
        Constant.navigatorKey.currentContext!
            .read<UpdatedReportItemCubit>()
            .clearItem();
        Constant.navigatorKey.currentContext!
            .read<GetBuyerChatListCubit>()
            .resetState();
        Constant.navigatorKey.currentContext!
            .read<FetchJobApplicationCubit>()
            .resetState();
        Constant.navigatorKey.currentContext!
            .read<BlockedUsersListCubit>()
            .resetState();
        final context = Constant.navigatorKey.currentContext!;
        context.read<UserDetailsCubit>().clear();
        await HiveUtils.clear();
        await HiveUtils.logoutUser(
          Constant.navigatorKey.currentContext!,
          onLogout: () {
            HelperUtils.goToNextPage(Routes.login, context, true);
          },
        );
        _isProcessing = false;
      });
    }
  }

  static Future<Map<String, dynamic>> delete({
    required String url,
    Map<String, dynamic>? queryParameters,
    bool? useBaseUrl,
  }) async {
    try {
      final response = await _dio.delete(
        ((useBaseUrl ?? true) ? Constant.baseUrl : "") + url,
        queryParameters: queryParameters,
        options: Options(headers: headers()),
      );

      if (response.data['error'] == true) {
        throw ApiException(response.data['message'].toString());
      }
      return Map.from(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        userExpired();
        throw ApiException("Session expired. Please log in again.");
      }
      if (e.response?.statusCode == 503) {
        throw "server-not-available";
      }

      throw ApiException(
        e.error is SocketException
            ? "no-internet"
            : "Something went wrong with error ${e.response?.statusCode}",
      );
    } on ApiException catch (e) {
      throw ApiException(e.errorMessage);
    } catch (e, st) {
      throw ApiException(st.toString());
    }
  }

  static Future<Map<String, dynamic>> get({
    required String url,
    Map<String, dynamic>? queryParameters,
    bool? useBaseUrl,
    // ADDED: Optional custom headers parameter
    Map<String, dynamic>? customHeaders,
  }) async {
    try {
      String mainurl = ((useBaseUrl ?? true) ? Constant.baseUrl : "") + url;

      // FIX: Combine base headers with custom headers and the critical User-Agent
      Map<String, dynamic> combinedHeaders = {
        ...headers(), // Your existing Authorization, Accept, etc.
        if (customHeaders != null) ...customHeaders,

        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      };

      final response = await _dio.get(
        mainurl,
        queryParameters: queryParameters,
        // Use the combined headers in the Options object
        options: Options(headers: combinedHeaders),
      );

      if (response.data['error'] == true) {
        throw ApiException(response.data['message'].toString());
      }
      return Map.from(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        userExpired();
        throw ApiException("Unauthenticated");
      }
      if (e.response?.statusCode == 503) {
        throw "server-not-available";
      }
      if (e.type == DioExceptionType.connectionError ||
          e.error is SocketException) {
        throw ApiException("no-internet");
      }
      throw ApiException("Something went wrong (${e.response?.statusCode})");
    } on ApiException catch (e) {
      throw ApiException(e.errorMessage);
    } catch (e, st) {
      throw ApiException(st.toString());
    }
  }

  static Future<void> download({
    required String url,
    required String savePath,
    CancelToken? cancelToken,
    ValueChanged<double>? onUpdate,
  }) async {
    try {
      await _dio.download(
        url,
        savePath,
        cancelToken: cancelToken,
        options: Options(headers: {HttpHeaders.acceptEncodingHeader: '*'}),
        onReceiveProgress: onUpdate != null
            ? (count, total) {
                final percentage = (count / total) * 100;
                onUpdate(percentage < 0.0 ? 99.0 : percentage);
              }
            : null,
      );
    } on DioException catch (e) {
      log('$e', name: 'DIO');
      if (e.response?.statusCode == 401) {
        userExpired();
        throw ApiException("Session expired. Please log in again.");
      }
      if (e.response?.statusCode == 503) {
        throw "server-not-available";
      }

      throw ApiException(
        e.error is SocketException
            ? "no-internet"
            : "Something went wrong with error ${e.response?.statusCode}",
      );
    } on ApiException catch (e) {
      throw ApiException(e.errorMessage);
    } on Exception catch (e) {
      log('$e', name: 'GENERAL');
      throw ApiException(e.toString());
    }
  }
}
