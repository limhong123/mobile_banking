import 'package:get/get.dart';
import 'package:mobile_banking_app/app/routes/app_route.dart';
import 'package:mobile_banking_app/core/widget/bottom_nav/bottom_nav_view.dart';
import 'package:mobile_banking_app/screen/analyst/analys_date/analys_date_binding.dart';
import 'package:mobile_banking_app/screen/analyst/analys_date/analys_date_view.dart';
import 'package:mobile_banking_app/screen/auth/login/login_binding.dart';
import 'package:mobile_banking_app/screen/auth/login/login_view.dart';
import 'package:mobile_banking_app/screen/auth/register/register_binding.dart';
import 'package:mobile_banking_app/screen/auth/register/register_view.dart';
import 'package:mobile_banking_app/screen/auth/splash_screen/splash_screen_binding.dart';
import 'package:mobile_banking_app/screen/auth/splash_screen/splash_screen_view.dart';
import 'package:mobile_banking_app/screen/auth/verify_otp/verify_otp_binding.dart';
import 'package:mobile_banking_app/screen/auth/verify_otp/verify_otp_view.dart';
import 'package:mobile_banking_app/screen/cash_transfer/cash_transfer_binding.dart';
import 'package:mobile_banking_app/screen/cash_transfer/cash_transfer_view.dart';
import 'package:mobile_banking_app/screen/home/home_binding.dart';
import 'package:mobile_banking_app/screen/home/home_view.dart';
import 'package:mobile_banking_app/screen/home/scan_khqr/scan_khqr_view.dart';
import 'package:mobile_banking_app/screen/kyc/document/document_binding.dart';
import 'package:mobile_banking_app/screen/kyc/document/document_view.dart';
import 'package:mobile_banking_app/screen/kyc/liveness/liveness_binding.dart';
import 'package:mobile_banking_app/screen/kyc/liveness/liveness_view.dart';
import 'package:mobile_banking_app/screen/kyc/result/result_binding.dart';
import 'package:mobile_banking_app/screen/kyc/result/result_view.dart';
import 'package:mobile_banking_app/screen/payment/my_qr/my_qr_binding.dart';
import 'package:mobile_banking_app/screen/payment/my_qr/my_qr_view.dart';
import 'package:mobile_banking_app/screen/payment/send/send_binding.dart';
import 'package:mobile_banking_app/screen/payment/send/send_view.dart';
import 'package:mobile_banking_app/screen/profile/profile_view.dart';
import 'package:mobile_banking_app/screen/scan_qr/scan_qr_binding.dart';
import 'package:mobile_banking_app/screen/scan_qr/scan_qr_view.dart';
import 'package:mobile_banking_app/screen/transaction_detail/transaction_detail_binding.dart';
import 'package:mobile_banking_app/screen/transaction_detail/transaction_detail_view.dart';
import 'package:mobile_banking_app/screen/transaction_history/transaction_history_binding.dart';
import 'package:mobile_banking_app/screen/transaction_history/transaction_history_view.dart';

abstract class AppPages {
  static final pages = <GetPage<dynamic>>[
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginView(),
      binding: LoginViewBinding(),
    ),

    GetPage(
      name: AppRoutes.register,
      page: () => const RegisterView(),
      binding: RegisterViewBinding(),
    ),

    GetPage(
      name: AppRoutes.verifyOtp,
      page: () => const VerifyOtpView(),
      binding: VerifyOtpBinding(),
    ),

    GetPage(
      name: AppRoutes.kycDocument,
      page: () => const DocumentView(),
      binding: DocumentBinding(),
    ),

    GetPage(
      name: AppRoutes.kycLiveness,
      page: () => const LivenessView(),
      binding: LivenessBinding(),
    ),

    GetPage(
      name: AppRoutes.kycResult,
      page: () => const ResultView(),
      binding: ResultBinding(),
    ),

    GetPage(
      name: AppRoutes.home,
      page: () => const HomeView(),
      binding: HomeViewBinding(),
    ),

    GetPage(
      name: AppRoutes.scanKhqr,
      page: () => const ScanKhqrView(),
      binding: ScanKhqrViewBinding(),
    ),

    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashScreenView(),
      binding: SplashBinding(),
    ),
    GetPage(
      name: AppRoutes.bottomNavigation,
      page: () => const BottomNavView(),
      binding: BottomNavViewBinding(),
    ),
    GetPage(
      name: AppRoutes.profile,
      page: () => const ProfileView(),
      binding: ProfileViewBinding(),
    ),
    GetPage(
      name: AppRoutes.analyst,
      page: () => const AnalysDateView(),
      binding: AnalysDateBinding(),
    ),

    GetPage(
      name: AppRoutes.myQr,

      page: () => const MyQrView(),

      binding: MyQrBinding(),
    ),

    GetPage(
      name: AppRoutes.scanQr,

      page: () => const ScanQrView(),

      binding: ScanQrBinding(),
    ),
    GetPage(
      name: AppRoutes.send,

      page: () => const SendView(),

      binding: SendBinding(),
    ),

    GetPage(
      name: AppRoutes.transactionHistory,
      page: () => TransactionHistoryView(),
      binding: TransactionHistoryViewBinding(),
    ),
    GetPage(
      name: AppRoutes.transactionDetail,
      page: () => TransactionDetailView(transactionId: '',),
      binding: TransactionDetailViewBinding(),
    ),
    GetPage(
  name:
      AppRoutes.cashReceive,

  page:
      () =>
          const CashReceiveView(),

  binding:
      CashReceiveBinding(),
),
  ];
}
