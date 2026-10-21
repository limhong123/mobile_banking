import 'package:dio/dio.dart';
import 'package:mobile_banking_app/core/api/base_api.dart';

class ProfileApi {
  final BaseApi baseApi = BaseApi();

  Future<dynamic> getProfile() async {
    return await baseApi.get(endpoint: '/profile/');
  }

  Future<dynamic> updateProfile({
    String? firstName,
    String? lastName,
    String? phoneNumber,
  }) async {
    final data = <String, dynamic>{};
    if (firstName != null) data['first_name'] = firstName;
    if (lastName != null) data['last_name'] = lastName;
    if (phoneNumber != null) data['phone_number'] = phoneNumber;

    return await baseApi.put(
      endpoint: '/profile/',
      data: data,
    );
  }

  Future<dynamic> uploadProfilePhoto({
    required String filePath,
    required String fileName,
  }) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        filePath,
        filename: fileName,
      ),
    });

    return await baseApi.post(
      endpoint: '/profile/upload-photo',
      data: formData,
    );
  }
}
