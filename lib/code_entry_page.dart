// lib/code_entry_page.dart
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:animate_do/animate_do.dart';
import 'package:lottie/lottie.dart';
import 'sms_channel.dart';
import 'home_page.dart';

class CodeEntryController extends GetxController {
  /// کنترلر پایدار برای کد
  final TextEditingController codeCtrl = TextEditingController();

  final RxString code = ''.obs;
  final Dio dio = Dio();
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();
  final RxBool verifying = false.obs;
  final String verifyUrl = "";

  late String phone;

  @override
  void onInit() {
    super.onInit();
    phone = Get.arguments as String;

    _ensureSmsPermission();
    _setupMethodChannelHandler();
    _checkPendingFromNative();

    // همگام‌سازی TextField -> RxString
    codeCtrl.addListener(() {
      code.value = codeCtrl.text;
    });
  }

  @override
  void onClose() {
    codeCtrl.dispose();
    super.onClose();
  }

  Future<void> _ensureSmsPermission() async {
    if (await Permission.sms.isDenied) await Permission.sms.request();
  }

  void _setupMethodChannelHandler() {
    platform.setMethodCallHandler((call) async {
      if (call.method == 'onSmsReceived') {
        final args = Map.from(call.arguments);
        final String receivedCode = args['code'] ?? '';
        final String phoneFromNative = args['phone'] ?? '';
        if (receivedCode.isNotEmpty &&
            (phoneFromNative.isEmpty || phoneFromNative == phone)) {
          codeCtrl.text =
              receivedCode; // این خودش code.value رو هم آپدیت می‌کنه
          await Future.delayed(const Duration(milliseconds: 200));
          verifyCode();
        }
      }
    });
  }

  Future<void> _checkPendingFromNative() async {
    try {
      // ممکنه null برگرده؛ با generic امن‌تره
      final String? pendingJson = await platform.invokeMethod<String>(
        'getPendingOtps',
      );

      final List pending = (pendingJson != null && pendingJson.isNotEmpty)
          ? (jsonDecode(pendingJson) as List)
          : const [];

      for (final item in pending) {
        final String receivedCode = item['code'] ?? '';
        final String phoneItem = item['phone'] ?? '';
        if (receivedCode.isNotEmpty &&
            (phoneItem.isEmpty || phoneItem == phone)) {
          codeCtrl.text = receivedCode;
          await Future.delayed(const Duration(milliseconds: 200));
          verifyCode();
          break;
        }
      }
    } catch (_) {}
  }

  Future<void> verifyCode() async {
    final trimmedCode = code.value.trim();
    if (trimmedCode.isEmpty) return;

    verifying.value = true;
    try {
      final resp = await dio.post(
        verifyUrl,
        data: {"mobile": phone, "code": trimmedCode},
        options: Options(contentType: Headers.jsonContentType),
      );

      if (resp.statusCode == 200) {
        final token = resp.data?['data']?['token'];
        if (token is String && token.isNotEmpty) {
          await secureStorage.write(key: 'auth_token', value: token);
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('saved_phone', phone);
          try {
            await platform.invokeMethod('setSavedPhone', phone);
          } catch (_) {}

          await Get.dialog(
            AlertDialog(
              title: const Text('ورود موفق'),
              content: const Text(
                'برای عملکرد صحیح اپ اینترنت گوشی باید روشن باشد و سیم‌کارت مورد استفاده داخل گوشی باشد.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Get.back(),
                  child: const Text('باشه'),
                ),
              ],
            ),
          );
          Get.offAll(() => const HomePage());
        } else {
          _showSnack('کد اشتباه است یا کاربر دیجی‌کالا نیست.');
        }
      } else {
        _showSnack('پاسخ ناموفق از سرور (${resp.statusCode})');
      }
    } catch (e) {
      _showSnack('خطا در ارتباط: $e');
    } finally {
      verifying.value = false;
    }
  }

  void _showSnack(String t) {
    Get.snackbar(
      '',
      t,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.redAccent,
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 10,
      snackStyle: SnackStyle.FLOATING,
    );
  }
}

class CodeEntryPage extends GetView<CodeEntryController> {
  const CodeEntryPage({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<CodeEntryController>()) {
      Get.put(CodeEntryController());
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('وارد کردن کد'),
          backgroundColor: Colors.blueAccent,
          elevation: 0,
          centerTitle: true,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 18.0),
              child: Bounce(
                duration: const Duration(milliseconds: 2000),
                child: Lottie.asset(
                  'assets/camera.json',
                  width: 40,
                  height: 40,
                  fit: BoxFit.contain,
                  repeat: true,
                  animate: true,
                ),
              ),
            ),
          ],
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
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Bounce(
                      duration: const Duration(milliseconds: 1000),
                      child: Lottie.asset(
                        'assets/optpassword.json',
                        width: 150,
                        height: 150,
                        fit: BoxFit.contain,
                        repeat: true,
                        animate: true,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'کدی که به ${controller.phone} فرستاده شد را وارد کنید',
                      textAlign: TextAlign.start,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: Obx(
                        () => PinCodeTextField(
                          appContext: context,
                          length: 5,
                          controller: controller.codeCtrl,
                          // کنترلر پایدار — نه ساخت داخل build
                          keyboardType: TextInputType.number,
                          enabled: !controller.verifying.value,
                          autoFocus: true,
                          animationType: AnimationType.fade,
                          animationDuration: const Duration(milliseconds: 200),
                          animationCurve: Curves.easeInOut,
                          textStyle: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          pastedTextStyle: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueAccent,
                          ),
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          enableActiveFill: true,
                          autoDismissKeyboard: true,
                          autoDisposeControllers: false,
                          // چون خودمان dispose می‌کنیم
                          textCapitalization: TextCapitalization.none,
                          textInputAction: TextInputAction.done,
                          onChanged: (value) => controller.code.value = value,
                          onCompleted: (_) => controller.verifyCode(),
                          onSubmitted: (_) => controller.verifyCode(),
                          pinTheme: PinTheme(
                            shape: PinCodeFieldShape.box,
                            borderRadius: BorderRadius.circular(12),
                            fieldHeight: 56,
                            fieldWidth: 56,
                            borderWidth: 2,
                            activeColor: Colors.blueAccent,
                            selectedColor: Colors.blue,
                            inactiveColor: Colors.grey[300],
                            disabledColor: Colors.grey,
                            activeFillColor: Colors.white,
                            selectedFillColor: Colors.white,
                            inactiveFillColor: Colors.white,
                            errorBorderColor: Colors.redAccent,
                          ),
                          backgroundColor: Colors.transparent,
                          showCursor: true,
                          cursorColor: Colors.blueAccent,
                          cursorWidth: 2,
                          hintCharacter: '-',
                          hintStyle: const TextStyle(
                            fontSize: 24,
                            color: Colors.grey,
                          ),
                          enablePinAutofill: true,
                          errorAnimationDuration: 300,
                          useHapticFeedback: true,
                          hapticFeedbackTypes: HapticFeedbackTypes.light,
                          blinkWhenObscuring: false,
                          obscureText: false,
                          readOnly: false,
                          autoUnfocus: true,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Obx(
                      () => ElevatedButton(
                        onPressed: controller.verifying.value
                            ? null
                            : controller.verifyCode,
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
                        child: controller.verifying.value
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
                                'تأیید',
                                style: TextStyle(
                                  fontSize: 18,
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
