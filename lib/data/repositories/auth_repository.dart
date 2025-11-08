import 'dart:io';

import 'package:Tijaraa/utils/api.dart';

/// 🔹 Handles API-based authentication logic
class AuthRepository {
  /// 🔹 Login using phone and backend API
  Future<Map<String, dynamic>> numberLoginWithApi({
    String? phone,
    required String uid,
    required String type,
    String? fcmId,
    String? email,
    String? name,
    String? profile,
    String? countryCode,
  }) async {
    try {
      Map<String, String> parameters = {
        if (phone != null) Api.mobile: phone,
        Api.firebaseId: uid,
        Api.type: type,
        Api.platformType: Platform.isAndroid ? "android" : "ios",
        if (fcmId != null) Api.fcmId: fcmId,
        if (email != null) Api.email: email,
        if (name != null) Api.name: name,
        if (countryCode != null) Api.countryCode: countryCode,
      };

      final response = await Api.post(url: Api.loginApi, parameter: parameters);

      return {"token": response['token'], "data": response['data']};
    } catch (e) {
      throw Exception("Login failed: $e");
    }
  }

  /// 🔹 Delete user via backend API
  Future<dynamic> deleteUser() async {
    try {
      return await Api.delete(url: Api.deleteUserApi);
    } catch (e) {
      throw Exception("Error deleting user: $e");
    }
  }

  /// 🔹 Send OTP via API (phone)
  Future<Map<String, dynamic>> sendPhoneOtp(
    String phone,
    String countryCode,
  ) async {
    try {
      final response = await Api.post(
        url: Api.sendPhoneOtp,
        parameter: {"phone": phone, "country_code": countryCode},
      );
      if (response['status'] != true) {
        throw Exception(response['message'] ?? "Failed to send OTP");
      }
      return response;
    } catch (e) {
      throw Exception("Error sending phone OTP: $e");
    }
  }

  /// 🔹 Verify OTP via API (phone)
  Future<Map<String, dynamic>> verifyPhoneOtp(String phone, String otp) async {
    try {
      final response = await Api.post(
        url: Api.verifyPhoneOtp,
        parameter: {"phone": phone, "otp": otp},
      );
      if (response['status'] != true) {
        throw Exception(response['message'] ?? "Invalid OTP");
      }
      return response;
    } catch (e) {
      throw Exception("Error verifying phone OTP: $e");
    }
  }

  /// 🔹 Send email OTP via API
  Future<Map<String, dynamic>> sendEmailOtp(String email) async {
    try {
      final response = await Api.post(
        url: Api.sendEmailOtp,
        parameter: {"email": email},
      );
      if (response['status'] != true) {
        throw Exception(response['message'] ?? "Failed to send email OTP");
      }
      return response;
    } catch (e) {
      throw Exception("Error sending email OTP: $e");
    }
  }

  /// 🔹 Verify email OTP via API
  Future<Map<String, dynamic>> verifyEmailOtp({
    required String email,
    required String otp,
  }) async {
    try {
      final response = await Api.post(
        url: Api.verifyEmailOtp,
        parameter: {"email": email, "otp": otp},
      );
      if (response['status'] != true) {
        throw Exception(response['message'] ?? "Invalid OTP");
      }
      return response;
    } catch (e) {
      throw Exception("Error verifying email OTP: $e");
    }
  }
}

/// 🔹 Multi-auth repository using API (email + phone)
class MultiAuthRepository {
  final AuthRepository _apiRepo = AuthRepository();

  /// 🔹 Send phone OTP
  Future<Map<String, dynamic>> sendOtp({
    required String phoneNumber,
    required String countryCode,
  }) async {
    return await _apiRepo.sendPhoneOtp(phoneNumber, countryCode);
  }

  /// 🔹 Verify phone OTP
  Future<Map<String, dynamic>> verifyOtp({
    required String phoneNumber,
    required String otp,
  }) async {
    return await _apiRepo.verifyPhoneOtp(phoneNumber, otp);
  }

  /// 🔹 Send email OTP
  Future<Map<String, dynamic>> sendEmailOtp(String email) async {
    return await _apiRepo.sendEmailOtp(email);
  }

  /// 🔹 Verify email OTP
  Future<Map<String, dynamic>> verifyEmailOtp({
    required String email,
    required String otp,
  }) async {
    return await _apiRepo.verifyEmailOtp(email: email, otp: otp);
  }
}
