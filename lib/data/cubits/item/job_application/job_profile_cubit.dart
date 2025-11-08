import 'package:Tijaraa/data/model/user/user_model.dart';
import 'package:Tijaraa/services/profile_sync_service.dart';
import 'package:Tijaraa/utils/hive_utils.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class JobProfileCubit extends Cubit<JobProfileModel?> {
  JobProfileCubit() : super(HiveUtils.getJobProfile());

  void loadProfile() {
    emit(HiveUtils.getJobProfile());
  }

  void updateProfile(JobProfileModel model) {
    HiveUtils.saveJobProfile(model);
    ProfileSyncService.updateUserFromJob(model);
    emit(model);
  }

  void clearProfile() {
    HiveUtils.saveJobProfile(JobProfileModel());
    emit(JobProfileModel());
  }
}
