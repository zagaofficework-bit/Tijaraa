import 'package:Tijaraa/data/model/notification_model.dart';
import 'package:Tijaraa/utils/api.dart';
import 'package:Tijaraa/utils/custom_exception.dart';
import 'package:Tijaraa/utils/hive_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class NotificationState {}

class NotificationInitial extends NotificationState {}

class NotificationSetProgress extends NotificationState {}

class NotificationSetSuccess extends NotificationState {
  List<NotificationData> notificationList = [];

  NotificationSetSuccess(this.notificationList);
}

class NotificationSetFailure extends NotificationState {
  final String errMsg;

  NotificationSetFailure(this.errMsg);
}

class NotificationCubit extends Cubit<NotificationState> {
  NotificationCubit() : super(NotificationInitial());
  void getVerificationStatus() {
    // Check Hive before making the call to avoid the 401 error in the console
    if (HiveUtils.isUserAuthenticated()) {
      Api.get(url: Api.getVerificationRequestApi)
          .then((value) {
            // handle success
          })
          .catchError((e) {
            // handle error
          });
    } else {
      print("Skipping verification API: User is Guest");
    }
  }

  void getNotification(BuildContext context) {
    emit(NotificationSetProgress());
    getNotificationFromDb(context)
        .then((value) => emit(NotificationSetSuccess(value)))
        .catchError((e) => emit(NotificationSetFailure(e.toString())));
  }

  Future<List<NotificationData>> getNotificationFromDb(
    BuildContext context,
  ) async {
    Map<String, String> body = {};
    List<NotificationData> notificationList = [];
    var response = await Api.get(
      url: Api.getNotificationListApi,
      queryParameters: body,
    );

    if (!response[Api.error]) {
      List list = response['data'];
      notificationList = list
          .map((model) => NotificationData.fromJson(model))
          .toList();
    } else {
      throw CustomException(response[Api.message]);
    }
    return notificationList;
  }
}
