import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:mobile_banking_app/screen/auth/verify_otp/verify_otp_controller.dart';

class VerifyOtpView
    extends GetView<
        VerifyOtpViewController> {
  const VerifyOtpView({
    super.key,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'ផ្ទៀងផ្ទាត់ OTP',
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Form(
          key: controller.formKey,
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.all(
              24,
            ),
            child: Column(
              children: [
                const SizedBox(
                  height: 32,
                ),

                Container(
                  width: 100,
                  height: 100,
                  decoration:
                      BoxDecoration(
                    color: Colors.blue
                        .withValues(
                      alpha: 0.10,
                    ),
                    shape:
                        BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons
                        .mark_email_read_outlined,
                    size: 48,
                    color: Colors.blue,
                  ),
                ),

                const SizedBox(
                  height: 28,
                ),

                const Text(
                  'បញ្ចូលលេខកូដ OTP',
                  textAlign:
                      TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(
                  height: 10,
                ),

                Text(
                  'យើងបានផ្ញើលេខកូដ OTP ទៅលេខទូរស័ព្ទ',
                  textAlign:
                      TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors
                        .grey.shade600,
                  ),
                ),

                const SizedBox(
                  height: 8,
                ),

                Obx(
                  () => Text(
                    controller
                        .maskedPhoneNumber,
                    style:
                        const TextStyle(
                      fontSize: 17,
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                ),

                const SizedBox(
                  height: 32,
                ),

                TextFormField(
                  controller:
                      controller
                          .otpController,
                  keyboardType:
                      TextInputType.number,
                  textInputAction:
                      TextInputAction.done,
                  textAlign:
                      TextAlign.center,
                  maxLength: 6,
                  autofocus: true,
                  inputFormatters: [
                    FilteringTextInputFormatter
                        .digitsOnly,
                    LengthLimitingTextInputFormatter(
                      6,
                    ),
                  ],
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight:
                        FontWeight.bold,
                    letterSpacing: 12,
                  ),
                  decoration:
                      InputDecoration(
                    hintText: '000000',
                    counterText: '',
                    prefixIcon:
                        const Icon(
                      Icons
                          .password_outlined,
                    ),
                    border:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(
                        12,
                      ),
                    ),
                    enabledBorder:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(
                        12,
                      ),
                      borderSide:
                          BorderSide(
                        color: Colors
                            .grey.shade300,
                      ),
                    ),
                    focusedBorder:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(
                        12,
                      ),
                      borderSide:
                          const BorderSide(
                        color:
                            Colors.blue,
                        width: 2,
                      ),
                    ),
                  ),
                  validator:
                      controller.validateOtp,
                  onFieldSubmitted: (_) {
                    if (!controller
                        .isLoading.value) {
                      controller
                          .verifyOtp();
                    }
                  },
                ),

                const SizedBox(
                  height: 28,
                ),

                Obx(
                  () => SizedBox(
                    width:
                        double.infinity,
                    height: 52,
                    child:
                        ElevatedButton(
                      onPressed: controller
                              .isLoading
                              .value
                          ? null
                          : controller
                              .verifyOtp,
                      child: controller
                              .isLoading
                              .value
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth:
                                    2,
                                color:
                                    Colors.white,
                              ),
                            )
                          : const Text(
                              'ផ្ទៀងផ្ទាត់',
                              style:
                                  TextStyle(
                                fontSize:
                                    16,
                                fontWeight:
                                    FontWeight
                                        .bold,
                              ),
                            ),
                    ),
                  ),
                ),

                const SizedBox(
                  height: 22,
                ),

                Obx(
                  () {
                    if (controller
                            .secondsRemaining
                            .value >
                        0) {
                      return Text(
                        'ផ្ញើ OTP ម្ដងទៀតក្នុង ${controller.secondsRemaining.value} វិនាទី',
                        style:
                            TextStyle(
                          color: Colors
                              .grey
                              .shade600,
                        ),
                      );
                    }

                    return TextButton.icon(
                      onPressed: controller
                              .isResending
                              .value
                          ? null
                          : controller
                              .resendOtp,
                      icon: controller
                              .isResending
                              .value
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth:
                                    2,
                              ),
                            )
                          : const Icon(
                              Icons
                                  .refresh,
                            ),
                      label: const Text(
                        'ផ្ញើ OTP ម្ដងទៀត',
                      ),
                    );
                  },
                ),

                const SizedBox(
                  height: 12,
                ),

                TextButton(
                  onPressed: () {
                    Get.back();
                  },
                  child: const Text(
                    'កែលេខទូរស័ព្ទ',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}