import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:mobile_banking_app/screen/kyc/document/document_controller.dart';


class DocumentView
    extends GetView<DocumentController> {
  const DocumentView({
    super.key,
  });


  static const Color primaryColor =
      Color(0xFF1249AD);


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
        backgroundColor:
            Colors.white,

        surfaceTintColor:
            Colors.white,

        title: const Text(
          'Identity Document',

          style: TextStyle(
            fontWeight:
                FontWeight.w700,
          ),
        ),

        centerTitle: true,
      ),


      body: SafeArea(
        child: Padding(
          padding:
              const EdgeInsets.all(
            20,
          ),

          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [

              const Text(
                'ថត NID ខាងមុខ',

                style: TextStyle(
                  fontSize: 24,

                  fontWeight:
                      FontWeight.w800,

                  color:
                      Color(
                    0xFF172033,
                  ),
                ),
              ),


              const SizedBox(
                height: 8,
              ),


              Text(
                'សូមដាក់ផ្នែកខាងមុខនៃ NID ក្នុងស៊ុម និងថតឱ្យច្បាស់។ ត្រូវប្រាកដថាមុខនៅលើ NID អាចមើលឃើញច្បាស់។',

                style: TextStyle(
                  color:
                      Colors.grey
                          .shade600,

                  height:
                      1.5,
                ),
              ),


              const SizedBox(
                height: 20,
              ),


              // =================================================
              // PROGRESS
              // =================================================

              ClipRRect(
                borderRadius:
                    BorderRadius.circular(
                  20,
                ),

                child:
                    LinearProgressIndicator(
                  value:
                      0.5,

                  minHeight:
                      7,

                  backgroundColor:
                      Colors.grey
                          .shade200,

                  color:
                      primaryColor,
                ),
              ),


              const SizedBox(
                height: 24,
              ),


              // =================================================
              // IMAGE
              // =================================================

              Expanded(
                child: Obx(
                  () {
                    final String path =
                        controller
                            .frontImagePath
                            .value;

                    return Container(
                      width:
                          double.infinity,

                      decoration:
                          BoxDecoration(
                        color:
                            Colors.white,

                        borderRadius:
                            BorderRadius
                                .circular(
                          24,
                        ),

                        border:
                            Border.all(
                          color:
                              path.isEmpty
                                  ? Colors.grey
                                      .shade300
                                  : primaryColor,

                          width:
                              path.isEmpty
                                  ? 1
                                  : 2,
                        ),

                        boxShadow: [
                          BoxShadow(
                            color:
                                Colors.black
                                    .withOpacity(
                              0.04,
                            ),

                            blurRadius:
                                16,

                            offset:
                                const Offset(
                              0,
                              5,
                            ),
                          ),
                        ],
                      ),

                      child:
                          path.isEmpty
                              ? _emptyDocument()
                              : Stack(
                                  children: [

                                    Positioned.fill(
                                      child:
                                          ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(
                                          22,
                                        ),

                                        child:
                                            Image.file(
                                          File(
                                            path,
                                          ),

                                          fit:
                                              BoxFit.contain,
                                        ),
                                      ),
                                    ),


                                    Positioned(
                                      top:
                                          12,

                                      right:
                                          12,

                                      child:
                                          Container(
                                        decoration:
                                            BoxDecoration(
                                          color:
                                              Colors.black
                                                  .withOpacity(
                                            0.55,
                                          ),

                                          shape:
                                              BoxShape.circle,
                                        ),

                                        child:
                                            IconButton(
                                          onPressed:
                                              controller.retake,

                                          icon:
                                              const Icon(
                                            Icons.close,

                                            color:
                                                Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),

                                  ],
                                ),
                    );
                  },
                ),
              ),


              const SizedBox(
                height: 18,
              ),


              // =================================================
              // CAMERA / GALLERY
              // =================================================

              Obx(
                () => Row(
                  children: [

                    Expanded(
                      child:
                          OutlinedButton.icon(
                        onPressed:
                            controller
                                    .isLoading
                                    .value
                                ? null
                                : controller
                                    .captureDocument,

                        icon:
                            const Icon(
                          Icons
                              .camera_alt_outlined,
                        ),

                        label:
                            const Text(
                          'ថតរូប',
                        ),

                        style:
                            OutlinedButton
                                .styleFrom(
                          minimumSize:
                              const Size(
                            0,
                            52,
                          ),

                          foregroundColor:
                              primaryColor,

                          side:
                              const BorderSide(
                            color:
                                primaryColor,
                          ),
                        ),
                      ),
                    ),


                    const SizedBox(
                      width: 12,
                    ),


                    Expanded(
                      child:
                          OutlinedButton.icon(
                        onPressed:
                            controller
                                    .isLoading
                                    .value
                                ? null
                                : controller
                                    .selectFromGallery,

                        icon:
                            const Icon(
                          Icons
                              .photo_library_outlined,
                        ),

                        label:
                            const Text(
                          'Gallery',
                        ),

                        style:
                            OutlinedButton
                                .styleFrom(
                          minimumSize:
                              const Size(
                            0,
                            52,
                          ),

                          foregroundColor:
                              primaryColor,

                          side:
                              const BorderSide(
                            color:
                                primaryColor,
                          ),
                        ),
                      ),
                    ),

                  ],
                ),
              ),


              const SizedBox(
                height: 12,
              ),


              // =================================================
              // CONTINUE
              // =================================================

              Obx(
                () => ElevatedButton(
                  onPressed:
                      controller
                                  .isLoading
                                  .value ||
                              controller
                                  .frontImagePath
                                  .value
                                  .isEmpty
                          ? null
                          : controller
                              .uploadDocument,

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
                          BorderRadius
                              .circular(
                        14,
                      ),
                    ),
                  ),

                  child:
                      controller
                              .isLoading
                              .value
                          ? const Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.center,

                              children: [

                                SizedBox(
                                  width:
                                      22,

                                  height:
                                      22,

                                  child:
                                      CircularProgressIndicator(
                                    strokeWidth:
                                        2,

                                    color:
                                        Colors.white,
                                  ),
                                ),

                                SizedBox(
                                  width:
                                      12,
                                ),

                                Text(
                                  'កំពុងពិនិត្យ NID...',
                                ),

                              ],
                            )
                          : const Text(
                              'បន្តទៅ Face Verification',

                              style:
                                  TextStyle(
                                fontWeight:
                                    FontWeight.w700,
                              ),
                            ),
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }


  Widget _emptyDocument() {
    return Center(
      child: Column(
        mainAxisSize:
            MainAxisSize.min,

        children: [

          Container(
            width:
                90,

            height:
                90,

            decoration:
                BoxDecoration(
              color:
                  primaryColor
                      .withOpacity(
                0.08,
              ),

              shape:
                  BoxShape.circle,
            ),

            child:
                const Icon(
              Icons
                  .badge_outlined,

              size:
                  54,

              color:
                  primaryColor,
            ),
          ),


          const SizedBox(
            height: 18,
          ),


          const Text(
            'មិនទាន់មានរូប NID',

            style: TextStyle(
              fontSize:
                  18,

              fontWeight:
                  FontWeight.w700,
            ),
          ),


          const SizedBox(
            height: 8,
          ),


          Text(
            'ថតផ្នែកខាងមុខរបស់ NID ឱ្យច្បាស់',

            textAlign:
                TextAlign.center,

            style: TextStyle(
              color:
                  Colors.grey
                      .shade500,
            ),
          ),

        ],
      ),
    );
  }
}