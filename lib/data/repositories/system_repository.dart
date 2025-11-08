import 'package:Tijaraa/utils/api.dart';

class SystemRepository {
  Future<Map<String, dynamic>> fetchSystemSettings() async {
    try {
      final response = await Api.get(
        queryParameters: {},
        url: Api.getSystemSettingsApi,
      );
      return response;
    } on ApiException catch (e) {
      throw e; // propagate as ApiException
    } catch (e) {
      throw ApiException('Unexpected error: $e');
    }
  }
}
