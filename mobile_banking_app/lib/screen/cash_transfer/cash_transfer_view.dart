import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_banking_app/screen/cash_transfer/cash_transfer_controller.dart';




class CashReceiveView
    extends GetView<CashReceiveController> {
  const CashReceiveView({
    super.key,
  });


  static const Color primary =
      Color(
    0xFF1249AD,
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
          'Receive Money',
        ),
        centerTitle:
            true,
        backgroundColor:
            Colors.white,
      ),

      body: Obx(
        () => SingleChildScrollView(
          padding:
              const EdgeInsets.all(
            20,
          ),

          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [

              const Text(
                'Cash Transfer Code',
                style:
                    TextStyle(
                  fontSize:
                      26,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),

              const SizedBox(
                height:
                    8,
              ),

              Text(
                'បញ្ចូលលេខ Code 12 ខ្ទង់ ដែល Agent ផ្តល់ឲ្យអ្នក។',
                style:
                    TextStyle(
                  color:
                      Colors.grey
                          .shade600,
                  height:
                      1.5,
                ),
              ),

              const SizedBox(
                height:
                    28,
              ),


              TextField(
                controller:
                    controller
                        .codeController,

                keyboardType:
                    TextInputType.number,

                maxLength:
                    12,

                onChanged:
                    controller
                        .onCodeChanged,

                style:
                    const TextStyle(
                  fontSize:
                      23,
                  fontWeight:
                      FontWeight.w700,
                  letterSpacing:
                      3,
                ),

                decoration:
                    InputDecoration(
                  labelText:
                      '12-Digit Code',

                  hintText:
                      '583104927611',

                  prefixIcon:
                      const Icon(
                    Icons
                        .confirmation_number_outlined,
                  ),

                  border:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius
                            .circular(
                      16,
                    ),
                  ),
                ),
              ),


              const SizedBox(
                height:
                    12,
              ),


              ElevatedButton(
                onPressed:
                    controller
                            .isLoading
                            .value
                        ? null
                        : controller
                            .checkCode,

                style:
                    ElevatedButton
                        .styleFrom(
                  minimumSize:
                      const Size(
                    double.infinity,
                    54,
                  ),
                  backgroundColor:
                      primary,
                  foregroundColor:
                      Colors.white,
                ),

                child:
                    controller
                            .isLoading
                            .value
                        ? const CircularProgressIndicator(
                            color:
                                Colors.white,
                          )
                        : const Text(
                            'Check Code',
                          ),
              ),


              if (controller
                  .transferFound
                  .value) ...[

                const SizedBox(
                  height:
                      28,
                ),


                Container(
                  width:
                      double.infinity,

                  padding:
                      const EdgeInsets.all(
                    22,
                  ),

                  decoration:
                      BoxDecoration(
                    color:
                        Colors.white,

                    borderRadius:
                        BorderRadius
                            .circular(
                      22,
                    ),

                    border:
                        Border.all(
                      color:
                          Colors.green
                              .shade200,
                    ),
                  ),

                  child:
                      Column(
                    children: [

                      const Icon(
                        Icons
                            .payments_rounded,
                        size:
                            52,
                        color:
                            Colors.green,
                      ),

                      const SizedBox(
                        height:
                            14,
                      ),

                      Text(
                        '\$${controller.amount.value.toStringAsFixed(2)}',
                        style:
                            const TextStyle(
                          fontSize:
                              34,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(
                        height:
                            10,
                      ),

                      Text(
                        'From ${controller.senderName.value}',
                        style:
                            TextStyle(
                          color:
                              Colors.grey
                                  .shade600,
                        ),
                      ),

                      const SizedBox(
                        height:
                            24,
                      ),

                      ElevatedButton(
                        onPressed:
                            controller
                                    .isLoading
                                    .value
                                ? null
                                : controller
                                    .receiveMoney,

                        style:
                            ElevatedButton
                                .styleFrom(
                          minimumSize:
                              const Size(
                            double.infinity,
                            54,
                          ),
                          backgroundColor:
                              Colors.green,
                          foregroundColor:
                              Colors.white,
                        ),

                        child:
                            const Text(
                          'Receive to My Account',
                        ),
                      ),

                    ],
                  ),
                ),

              ],

            ],
          ),
        ),
      ),
    );
  }
}