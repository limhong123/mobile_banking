import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:mobile_banking_app/screen/kyc/liveness/liveness_controller.dart';


class LivenessView
    extends GetView<LivenessController> {
  const LivenessView({
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

      appBar: AppBar(
        title:
            const Text(
          'Face Verification',

          style:
              TextStyle(
            fontWeight:
                FontWeight.w700,
          ),
        ),

        centerTitle:
            true,

        backgroundColor:
            Colors.white,

        surfaceTintColor:
            Colors.white,
      ),


      body: SafeArea(
        child: Obx(
          () {
            if (
                controller
                    .errorMessage
                    .value
                    .isNotEmpty) {
              return _errorView();
            }


            if (
                !controller
                    .isCameraReady
                    .value) {
              return const Center(
                child:
                    CircularProgressIndicator(
                  color:
                      primaryColor,
                ),
              );
            }


            return Column(
              children: [

                const SizedBox(
                  height:
                      20,
                ),


                const Text(
                  'ការផ្ទៀងផ្ទាត់មុខផ្ទាល់',

                  style:
                      TextStyle(
                    fontSize:
                        24,

                    fontWeight:
                        FontWeight.w800,
                  ),
                ),


                const SizedBox(
                  height:
                      8,
                ),


                Padding(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal:
                        32,
                  ),

                  child:
                      Text(
                    controller
                        .instruction,

                    textAlign:
                        TextAlign.center,

                    style:
                        TextStyle(
                      fontSize:
                          16,

                      color:
                          Colors.grey
                              .shade600,
                    ),
                  ),
                ),


                const SizedBox(
                  height:
                      24,
                ),


                Expanded(
                  child:
                      Padding(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal:
                          24,
                    ),

                    child:
                        Center(
                      child:
                          AspectRatio(
                        aspectRatio:
                            3 / 4,

                        child:
                            Stack(
                          fit:
                              StackFit.expand,

                          children: [

                            ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(
                                160,
                              ),

                              child:
                                  CameraPreview(
                                controller
                                    .cameraController
                                    .value!,
                              ),
                            ),


                            Container(
                              decoration:
                                  BoxDecoration(
                                borderRadius:
                                    BorderRadius.circular(
                                  160,
                                ),

                                border:
                                    Border.all(
                                  color:
                                      secondaryColor,

                                  width:
                                      4,
                                ),
                              ),
                            ),


                            if (
                                controller
                                    .isUploading
                                    .value)
                              Container(
                                decoration:
                                    BoxDecoration(
                                  color:
                                      Colors.black
                                          .withOpacity(
                                    0.45,
                                  ),

                                  borderRadius:
                                      BorderRadius.circular(
                                    160,
                                  ),
                                ),

                                child:
                                    const Center(
                                  child:
                                      Column(
                                    mainAxisSize:
                                        MainAxisSize.min,

                                    children: [

                                      CircularProgressIndicator(
                                        color:
                                            Colors.white,
                                      ),

                                      SizedBox(
                                        height:
                                            16,
                                      ),

                                      Text(
                                        'កំពុងផ្ទៀងផ្ទាត់...',

                                        style:
                                            TextStyle(
                                          color:
                                              Colors.white,

                                          fontWeight:
                                              FontWeight.w700,
                                        ),
                                      ),

                                    ],
                                  ),
                                ),
                              ),

                          ],
                        ),
                      ),
                    ),
                  ),
                ),


                const SizedBox(
                  height:
                      24,
                ),


                Padding(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal:
                        24,
                  ),

                  child:
                      LinearProgressIndicator(
                    value:
                        controller
                            .progress
                            .value,

                    minHeight:
                        8,

                    borderRadius:
                        BorderRadius.circular(
                      20,
                    ),

                    backgroundColor:
                        Colors.grey
                            .shade200,

                    valueColor:
                        const AlwaysStoppedAnimation<Color>(
                      secondaryColor,
                    ),
                  ),
                ),


                const SizedBox(
                  height:
                      16,
                ),


                _steps(),


                const SizedBox(
                  height:
                      24,
                ),

              ],
            );
          },
        ),
      ),
    );
  }


  Widget _steps() {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        horizontal:
            24,
      ),

      child: Row(
        mainAxisAlignment:
            MainAxisAlignment
                .spaceBetween,

        children: [

          _stepItem(
            label:
                'ព្រិចភ្នែក',

            completed:
                controller
                        .progress
                        .value >=
                    0.45,
          ),


          _stepItem(
            label:
                'បង្វិលឆ្វេង',

            completed:
                controller
                        .progress
                        .value >=
                    0.70,
          ),


          _stepItem(
            label:
                'បង្វិលស្ដាំ',

            completed:
                controller
                        .progress
                        .value >=
                    1.0,
          ),

        ],
      ),
    );
  }


  Widget _stepItem({
    required String label,
    required bool completed,
  }) {
    return Column(
      children: [

        Container(
          width:
              38,

          height:
              38,

          decoration:
              BoxDecoration(
            color:
                completed
                    ? secondaryColor
                    : Colors.grey
                        .shade200,

            shape:
                BoxShape.circle,
          ),

          child:
              Icon(
            completed
                ? Icons.check
                : Icons.circle_outlined,

            size:
                20,

            color:
                completed
                    ? Colors.white
                    : Colors.grey,
          ),
        ),


        const SizedBox(
          height:
              8,
        ),


        Text(
          label,

          style:
              TextStyle(
            fontSize:
                11,

            fontWeight:
                FontWeight.w600,

            color:
                completed
                    ? secondaryColor
                    : Colors.grey,
          ),
        ),

      ],
    );
  }


  Widget _errorView() {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(
          24,
        ),

        child: Column(
          mainAxisSize:
              MainAxisSize.min,

          children: [

            const Icon(
              Icons.error_outline,

              size:
                  68,

              color:
                  Colors.red,
            ),


            const SizedBox(
              height:
                  18,
            ),


            Text(
              controller
                  .errorMessage
                  .value,

              textAlign:
                  TextAlign.center,
            ),


            const SizedBox(
              height:
                  20,
            ),


            ElevatedButton(
              onPressed:
                  controller
                      .initializeCamera,

              child:
                  const Text(
                'សាកម្តងទៀត',
              ),
            ),

          ],
        ),
      ),
    );
  }
}