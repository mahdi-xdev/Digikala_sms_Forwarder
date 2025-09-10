// lib/phone_entry_page.dart
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:animate_do/animate_do.dart';
import 'package:lottie/lottie.dart';

import 'sms_channel.dart';
import 'code_entry_page.dart';

class PhoneEntryController extends GetxController {
  /// کنترلر پایدار برای شماره
  final TextEditingController phoneCtrl = TextEditingController();

  /// stateهای ری‌اکتیو
  final RxString phone = ''.obs;
  final RxBool loading = false.obs;

  final Dio dio = Dio();

  final String requestCodeUrl = "";
  final String checkForwardUrl = "";

  /// ماسک نمایش شماره (مثال: 0912 919 8575)
  final MaskTextInputFormatter maskFormatter = MaskTextInputFormatter(
    mask: '#### ### ####',
    filter: {"#": RegExp(r'[0-9]')},
  );

  @override
  void onInit() {
    super.onInit();
    _requestSmsPermission();
    _loadSavedPhoneToField();

    // همگام‌سازی TextField -> RxString
    phoneCtrl.addListener(() {
      phone.value = phoneCtrl.text;
    });
  }

  @override
  void onClose() {
    phoneCtrl.dispose();
    super.onClose();
  }

  Future<void> _loadSavedPhoneToField() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('saved_phone') ?? '';
    if (saved.isNotEmpty) {
      phoneCtrl.text = saved;
      phone.value = saved;
    }
  }

  Future<void> _requestSmsPermission() async {
    if (await Permission.sms.isDenied) {
      await Permission.sms.request();
    }
  }

  Future<void> sendPhone() async {
    final trimmedPhone = phoneCtrl.text.trim().replaceAll(' ', '');
    if (trimmedPhone.isEmpty || trimmedPhone.length != 11) {
      _showSnack('لطفاً شماره تلفن معتبر (۱۱ رقم) وارد کنید');
      return;
    }

    loading.value = true;
    try {
      final checkResponse = await dio.post(
        checkForwardUrl,
        data: {"mobile": trimmedPhone},
        options: Options(contentType: Headers.jsonContentType),
      );

      final checkData = checkResponse.data;
      // ignore: avoid_print
      print('Check Response: $checkData');

      final okByStatus = checkData['status'] == true;
      final okByMessage =
          checkData['message']?.toString().contains('کد فعالسازی') == true;

      if (!okByStatus && !okByMessage) {
        _showSnack(checkData['message'] ?? 'خطا در چک کردن کاربر');
      } else {
        await dio.post(
          requestCodeUrl,
          data: {"mobile": trimmedPhone},
          options: Options(contentType: Headers.jsonContentType),
        );

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('saved_phone', trimmedPhone);

        try {
          await platform.invokeMethod('setSavedPhone', trimmedPhone);
        } catch (_) {}

        _showSnack(
          'کد تایید ارسال شد، لطفاً وارد کنید',
          backgroundColor: Colors.green,
        );

        Get.to(() => const CodeEntryPage(), arguments: trimmedPhone);
      }
    } catch (e) {
      _showSnack('خطا در ارسال شماره: $e');
    } finally {
      loading.value = false;
    }
  }

  void _showSnack(String t, {Color backgroundColor = Colors.redAccent}) {
    Get.snackbar(
      '',
      '',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: backgroundColor,
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      snackStyle: SnackStyle.FLOATING,

      titleText: const SizedBox.shrink(),
      messageText: Directionality(
        textDirection: TextDirection.rtl,
        child: Text(
          t,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          textAlign: TextAlign.right, // 👈 متن به راست بچسبه
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

class PhoneEntryPage extends GetView<PhoneEntryController> {
  const PhoneEntryPage({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<PhoneEntryController>()) {
      Get.put(PhoneEntryController());
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('ورود با شماره'),
          backgroundColor: Colors.blueAccent,
          elevation: 0,
          centerTitle: true,
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.blueAccent, Colors.white],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              physics: BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 32.0,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    AnimatedOpacity(
                      opacity: 1.0,
                      duration: const Duration(milliseconds: 500),
                      child: Bounce(
                        duration: const Duration(milliseconds: 1000),
                        child: Lottie.asset(
                          'assets/online-mentoring.json',
                          width: 300,
                          height: 300,
                          fit: BoxFit.contain,
                          repeat: true,
                          animate: true,
                        ),
                      ),
                    ),
                    const SizedBox(height: 1),
                    const Text(
                      'شماره تلفن خود را وارد کنید',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'کد تأیید به این شماره ارسال می‌شود',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    const SizedBox(height: 32),

                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: TextField(
                        controller: controller.phoneCtrl,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          controller.maskFormatter,
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9 ]')),
                        ],
                        decoration: InputDecoration(
                          labelText: 'شماره تلفن (مثال: 7585 919 0912)',
                          prefixIcon: const Icon(
                            Icons.phone,
                            color: Colors.blueAccent,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Colors.blueAccent,
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                        onChanged: (v) => controller.phone.value = v,
                      ),
                    ),

                    const SizedBox(height: 24),

                    Obx(
                      () => ElevatedButton(
                        onPressed: controller.loading.value
                            ? null
                            : controller.sendPhone,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 48,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 5,
                          shadowColor: Colors.black38,
                        ),
                        child: controller.loading.value
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Text(
                                'درخواست کد',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
