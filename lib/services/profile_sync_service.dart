import 'package:Tijaraa/data/model/user/user_model.dart';
import 'package:Tijaraa/utils/hive_keys.dart';
import 'package:Tijaraa/utils/hive_utils.dart';
import 'package:hive/hive.dart';

class ProfileSyncService {
  static bool _initialized = false;

  /// Initialize listener (call once in main.dart or at login)
  static void init() {
    if (_initialized) return;
    _initialized = true;

    final userBox = Hive.box(HiveKeys.userDetailsBox);

    // Listen for changes in the box
    userBox.watch().listen((event) {
      // event.key gives which key changed
      if (event.key == HiveKeys.userDetailsBox || event.key == "jobProfile") {
        _syncProfiles();
      }
    });

    // Run once at startup
    _syncProfiles();
  }

  /// Syncs user basic info <-> job profile info
  static void _syncProfiles() {
    final user = HiveUtils.getUserDetails();
    final job = HiveUtils.getJobProfile();

    if (user == null) return;

    // If no job profile yet, create one with user data
    if (job == null) {
      final newJob = JobProfileModel(
        title: "",
        skills: "",
        experience: "",
        expectedSalary: "",
        resumePath: "",
      );
      HiveUtils.saveJobProfile(newJob);
      return;
    }

    // ✅ If user profile changes, update name/email/address in job profile
    final updatedJob = JobProfileModel(
      title: job.title,
      skills: job.skills,
      experience: job.experience,
      expectedSalary: job.expectedSalary,
      resumePath: job.resumePath,
    );

    bool updated = false;

    if ((user.name ?? "") !=
        (Hive.box(HiveKeys.userDetailsBox).get("name") ?? "")) {
      updated = true;
    }

    // If user data is more recent, update job profile fields
    updatedJob.title ??= "";
    if (user.name != null && user.name!.isNotEmpty) {
      Hive.box(HiveKeys.userDetailsBox).put("name", user.name);
      updated = true;
    }

    if (updated) {
      HiveUtils.saveJobProfile(updatedJob);
    }
  }

  /// When job profile edits user fields (like name/email), sync back to user model
  static void updateUserFromJob(JobProfileModel job) {
    final user = HiveUtils.getUserDetails();
    if (user == null) return;

    final updatedUser = UserModel(
      name: user.name ?? "",
      email: user.email ?? "",
      address: user.address ?? "",
      mobile: user.mobile,
      id: user.id,
      profile: user.profile,
      token: user.token,
      isActive: user.isActive,
      isProfileCompleted: user.isProfileCompleted,
      isVerified: user.isVerified,
    );

    // Save updated UserModel back to Hive
    Hive.box(
      HiveKeys.userDetailsBox,
    ).put(HiveKeys.userDetailsBox, updatedUser.toJson());
  }
}
