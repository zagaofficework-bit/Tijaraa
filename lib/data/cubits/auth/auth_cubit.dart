import 'dart:io';

import 'package:Tijaraa/data/model/user/user_model.dart';
import 'package:Tijaraa/data/repositories/auth_repository.dart';
import 'package:Tijaraa/utils/api.dart';
import 'package:Tijaraa/utils/hive_utils.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// ===========================
/// Auth States
/// ===========================
abstract class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthProgress extends AuthState {
  const AuthProgress();
}

class Unauthenticated extends AuthState {
  const Unauthenticated();
}

class Authenticated extends AuthState {
  final UserModel user;
  const Authenticated(this.user);
}

class AuthFailure extends AuthState {
  final String errorMessage;
  const AuthFailure(this.errorMessage);
}

class AuthOtpSent extends AuthState {
  final String message;
  const AuthOtpSent(this.message);
}

class AuthVerified extends AuthState {
  final String message;
  const AuthVerified(this.message);
}

/// ===========================
/// Auth Cubit
/// ===========================
class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _repository = AuthRepository();

  AuthCubit() : super(const AuthInitial());

  /// Load user from Hive
  void loadUserFromHive() {
    try {
      final user = HiveUtils.getUserDetails();
      if (user != null) {
        emit(Authenticated(user));
      } else {
        emit(const Unauthenticated());
      }
    } catch (e) {
      emit(AuthFailure('Failed to load user: $e'));
    }
  }

  Future<Map<String, dynamic>> updateUserData({
    String? name,
    String? email,
    String? address,
    File? fileUserImg,
    String? fcmToken,
    String? notification,
    String? mobile,
    String? countryCode,
    int? personalDetail,
    String? dob,
    String? nationality,
    String? gender,
  }) async {
    try {
      emit(const AuthProgress());

      final parameters = await _buildUpdateParameters(
        name: name,
        email: email,
        address: address,
        fileUserimg: fileUserImg,
        fcmToken: fcmToken,
        notification: notification,
        mobile: mobile,
        countryCode: countryCode,
        personalDetail: personalDetail,
        dob: dob,
        nationality: nationality,
        gender: gender,
      );

      final response = await Api.post(
        url: Api.updateProfileApi,
        parameter: parameters,
      );

      if (!response[Api.error]) {
        HiveUtils.setUserData(response['data']);
        final updatedUser = HiveUtils.getUserDetails();
        emit(Authenticated(updatedUser));
      } else {
        emit(const Unauthenticated());
      }

      return response;
    } catch (e) {
      emit(AuthFailure('Failed to update profile: $e'));
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _buildUpdateParameters({
    String? name,
    String? email,
    String? address,
    File? fileUserimg,
    String? fcmToken,
    String? notification,
    String? mobile,
    String? countryCode,
    int? personalDetail,
    String? dob,
    String? nationality,
    String? gender,
  }) async {
    final parameters = {
      Api.name: name ?? '',
      Api.email: email ?? '',
      Api.address: address ?? '',
      Api.fcmId: fcmToken ?? '',
      Api.notification: notification,
      Api.mobile: mobile,
      Api.countryCode: countryCode,
      Api.personalDetail: personalDetail,
      Api.dob: dob,
      Api.nationality: nationality,
      Api.gender: gender,
    };

    if (fileUserimg != null) {
      parameters['profile'] = await MultipartFile.fromFile(fileUserimg.path);
    }

    return parameters;
  }

  /// Sign out
  Future<void> signOut(BuildContext context) async {
    try {
      emit(const AuthProgress());
      HiveUtils.logoutUser(context, onLogout: () {});
      emit(const Unauthenticated());
    } catch (e) {
      emit(AuthFailure('Failed to sign out: $e'));
    }
  }

  Future<void> sendEmailOtp(String email) async {
    try {
      emit(const AuthProgress());
      final response = await _repository.sendEmailOtp(email);

      if (response['status'] == true) {
        emit(AuthOtpSent(response['message'] ?? "OTP sent successfully"));
      } else {
        emit(AuthFailure(response['message'] ?? "Failed to send OTP"));
      }
    } catch (e) {
      emit(AuthFailure("Failed to send OTP: $e"));
    }
  }

  Future<void> verifyEmailOtp(String email, String otp) async {
    try {
      emit(const AuthProgress());
      final response = await _repository.verifyEmailOtp(email: email, otp: otp);

      if (response['status'] == true) {
        HiveUtils.setEmailVerified(true);
        emit(AuthVerified("Email verified successfully"));
      } else {
        emit(AuthFailure(response['message'] ?? "Invalid OTP"));
      }
    } catch (e) {
      emit(AuthFailure("Failed to verify email OTP: $e"));
    }
  }

  Future<void> sendPhoneOtp(String phone, String countryCode) async {
    try {
      emit(const AuthProgress());
      final response = await _repository.sendPhoneOtp("$countryCode", "$phone");

      if (response['status'] == true) {
        emit(AuthOtpSent(response['message'] ?? "OTP sent to phone"));
      } else {
        emit(AuthFailure(response['message'] ?? "Failed to send OTP"));
      }
    } catch (e) {
      emit(AuthFailure("Failed to send phone OTP: $e"));
    }
  }

  Future<void> verifyPhoneOtp(String phone, String otp) async {
    try {
      emit(const AuthProgress());
      final response = await _repository.verifyPhoneOtp(phone, otp);

      if (response['status'] == true) {
        HiveUtils.setPhoneVerified(true);
        emit(AuthVerified("Phone verified successfully"));
      } else {
        emit(AuthFailure(response['message'] ?? "Invalid OTP"));
      }
    } catch (e) {
      emit(AuthFailure("Failed to verify phone OTP: $e"));
    }
  }
}
