import 'package:mobile_banking_app/core/api/base_api.dart';


class NotificationApi {
  final BaseApi baseApi =
      BaseApi();


  Future<dynamic> saveFcmToken(
    String token,
  ) async {
    return await baseApi.post(
      endpoint:
          '/notifications/fcm-token',

      data: {
        'token':
            token,
      },
    );
  }
}