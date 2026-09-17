import 'package:get_storage/get_storage.dart';

import 'package:mobile_banking_app/core/api/base_api.dart';

class AuthApi {
  final BaseApi baseApi = BaseApi();

  final GetStorage box =
      GetStorage();

  // =========================
  // REGISTER
  // =========================

  Future<dynamic> register({
    required String firstName,
    required String lastName,
    required String phoneNumber,
    required String pin,
  }) async {
    return await baseApi.post(
      endpoint: '/auth/register',
      data: {
        'first_name':
            firstName.trim(),
        'last_name':
            lastName.trim(),
        'phone_number':
            phoneNumber.trim(),
        'pin':
            pin.trim(),
      },
    );
  }

  // =========================
  // VERIFY OTP
  // =========================

  Future<dynamic> verifyOtp({
    required String phoneNumber,
    required String otpCode,
  }) async {
    return await baseApi.post(
      endpoint:
          '/auth/verify-otp',
      data: {
        'phone_number':
            phoneNumber.trim(),
        'otp_code':
            otpCode.trim(),
      },
    );
  }

  // =========================
  // RESEND OTP
  // =========================

  Future<dynamic> resendOtp({
    required String phoneNumber,
  }) async {
    return await baseApi.post(
      endpoint:
          '/auth/resend-otp',
      data: {
        'phone_number':
            phoneNumber.trim(),
      },
    );
  }

  // =========================
  // LOGIN
  // =========================

  Future<dynamic> login({
    required String phoneNumber,
    required String pin,
  }) async {
    return await baseApi.post(
      endpoint:
          '/auth/login',
      data: {
        'phone_number':
            phoneNumber.trim(),
        'pin':
            pin.trim(),
      },
    );
  }

  // =========================
  // RESUME KYC
  // =========================

  Future<dynamic> resumeKyc({
    required String phoneNumber,
    required String pin,
  }) async {
    return await baseApi.post(
      endpoint:
          '/auth/resume-kyc',
      data: {
        'phone_number':
            phoneNumber.trim(),
        'pin':
            pin.trim(),
      },
    );
  }

  // =========================
  // GET CURRENT USER
  // =========================

  Future<dynamic> getMe() async {
    return await baseApi.get(
      endpoint: '/auth/me',
    );
  }

  // =========================
  // LOGOUT
  // =========================

  Future<void> logout() async {
    await box.remove(
      'token',
    );

    await box.remove(
      'refresh_token',
    );
  }
}