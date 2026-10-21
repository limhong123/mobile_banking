import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:mobile_banking_app/screen/kyc/result/result_controller.dart';


class ResultView
    extends GetView<ResultController> {
  const ResultView({
    super.key,
  });


  static const Color primaryColor =
      Color(
    0xFF1249AD,
  );


  static const Color secondaryColor =
      Color(
    0xFF7AC40B,
  );


  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          const Color(
        0xFFF7F9FD,
      ),

      body: SafeArea(
        child: Obx(
          () => Padding(
            padding:
                const EdgeInsets.all(
              24,
            ),

            child: Column(
              children: [

                const Spacer(),


                _statusIcon(),


                const SizedBox(
                  height:
                      28,
                ),


                Text(
                  controller.title,

                  textAlign:
                      TextAlign.center,

                  style:
                      const TextStyle(
                    fontSize:
                        28,

                    fontWeight:
                        FontWeight.w800,
                  ),
                ),


                const SizedBox(
                  height:
                      14,
                ),


                Text(
                  controller
                      .description,

                  textAlign:
                      TextAlign.center,

                  style:
                      TextStyle(
                    fontSize:
                        16,

                    height:
                        1.6,

                    color:
                        Colors.grey
                            .shade600,
                  ),
                ),


                if (
                    controller
                            .matchScore
                            .value >
                        0) ...[

                  const SizedBox(
                    height:
                        22,
                  ),


                  Container(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal:
                          20,

                      vertical:
                          12,
                    ),

                    decoration:
                        BoxDecoration(
                      color:
                          Colors.white,

                      borderRadius:
                          BorderRadius.circular(
                        16,
                      ),

                      border:
                          Border.all(
                        color:
                            Colors.grey
                                .shade200,
                      ),
                    ),

                    child:
                        Column(
                      children: [

                        Text(
                          'Face Match Score',

                          style:
                              TextStyle(
                            color:
                                Colors.grey
                                    .shade500,

                            fontSize:
                                13,
                          ),
                        ),


                        const SizedBox(
                          height:
                              4,
                        ),


                        Text(
                          controller
                              .matchScore
                              .value
                              .toStringAsFixed(
                            2,
                          ),

                          style:
                              const TextStyle(
                            fontSize:
                                22,

                            fontWeight:
                                FontWeight.w800,
                          ),
                        ),

                      ],
                    ),
                  ),
                ],

                if (controller.isApproved &&
                    (controller.nidNumber.value.isNotEmpty ||
                        controller.fullName.value.isNotEmpty)) ...[
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.badge_outlined,
                                size: 18, color: primaryColor),
                            SizedBox(width: 8),
                            Text(
                              'Identity Information',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF172033),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (controller.nidNumber.value.isNotEmpty)
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Text('NID Number',
                                  style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 13)),
                              Text(controller.nidNumber.value,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14)),
                            ],
                          ),
                        if (controller.nidNumber.value.isNotEmpty &&
                            controller.fullName.value.isNotEmpty)
                          const Divider(height: 16),
                        if (controller.fullName.value.isNotEmpty)
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Name on NID',
                                  style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 13)),
                              Text(controller.fullName.value,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14)),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],

                const Spacer(),


                // =================================================
                // APPROVED
                // =================================================

                if (
                    controller
                        .isApproved)
                  ElevatedButton.icon(
                    onPressed:
                        controller
                            .goToLogin,

                    icon:
                        const Icon(
                      Icons
                          .login_rounded,
                    ),

                    style:
                        ElevatedButton
                            .styleFrom(
                      minimumSize:
                          const Size(
                        double.infinity,
                        54,
                      ),

                      backgroundColor:
                          primaryColor,

                      foregroundColor:
                          Colors.white,

                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(
                          14,
                        ),
                      ),
                    ),

                    label:
                        const Text(
                      'ទៅកាន់ Login',

                      style:
                          TextStyle(
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),
                  )


                // =================================================
                // REJECTED
                // =================================================

                else
                  ElevatedButton.icon(
                    onPressed:
                        controller
                            .retryVerification,

                    icon:
                        const Icon(
                      Icons
                          .refresh_rounded,
                    ),

                    style:
                        ElevatedButton
                            .styleFrom(
                      minimumSize:
                          const Size(
                        double.infinity,
                        54,
                      ),

                      backgroundColor:
                          primaryColor,

                      foregroundColor:
                          Colors.white,

                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(
                          14,
                        ),
                      ),
                    ),

                    label:
                        const Text(
                      'ធ្វើ KYC ម្តងទៀត',

                      style:
                          TextStyle(
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),
                  ),

              ],
            ),
          ),
        ),
      ),
    );
  }


  Widget _statusIcon() {
    if (
        controller
            .isApproved) {
      return _circleIcon(
        icon:
            Icons.check_rounded,

        background:
            secondaryColor
                .withOpacity(
          0.14,
        ),

        foreground:
            secondaryColor,
      );
    }


    return _circleIcon(
      icon:
          Icons.close_rounded,

      background:
          Colors.red
              .withOpacity(
        0.12,
      ),

      foreground:
          Colors.red,
    );
  }


  Widget _circleIcon({
    required IconData icon,
    required Color background,
    required Color foreground,
  }) {
    return Container(
      width:
          120,

      height:
          120,

      decoration:
          BoxDecoration(
        color:
            background,

        shape:
            BoxShape.circle,
      ),

      child:
          Icon(
        icon,

        size:
            62,

        color:
            foreground,
      ),
    );
  }
}