import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../phone_entry_page.dart';
import '../sms_channel.dart';

class HomeController extends GetxController {
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();
  final RxString phone = ''.obs;
  final RxString maskedToken = ''.obs;
  final RxMap<String, dynamic> userProfile = <String, dynamic>{}.obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _loadInfo();
  }

  Future<void> _loadInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPhone = prefs.getString('saved_phone') ?? '';
    final token = await secureStorage.read(key: 'auth_token') ?? '';
    phone.value = savedPhone;
    maskedToken.value = token.isNotEmpty ? _maskToken(token) : '';
    if (phone.value.isNotEmpty) {
      await fetchUserProfile();
    }
  }

  String _maskToken(String t) {
    if (t.length <= 8) return '●●●●●●';
    return '${t.substring(0, 4)}...${t.substring(t.length - 4)}';
  }

  Future<void> fetchUserProfile() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final response = await http.post(
        Uri.parse(''),
        body: {'Comand': 'GetUserProfaile', 'Phone': phone.value},
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['status'] == true) {
          userProfile.value = jsonResponse['data'];
          // Update maskedToken if needed from loginInfo
          final loginInfo = userProfile['loginInfo'];
          if (loginInfo != null && loginInfo['Token'] != null) {
            final newToken = loginInfo['Token'];
            maskedToken.value = newToken.isNotEmpty ? _maskToken(newToken) : '';
            await secureStorage.write(key: 'auth_token', value: newToken);
          }
        } else {
          errorMessage.value =
              jsonResponse['message'] ?? 'خطا در دریافت اطلاعات';
        }
      } else {
        errorMessage.value = 'خطا در ارتباط با سرور: ${response.statusCode}';
      }
    } catch (e) {
      errorMessage.value = 'خطا: $e';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('saved_phone');
    await secureStorage.delete(key: 'auth_token');
    try {
      await platform.invokeMethod('setSavedPhone', '');
    } catch (_) {}
    userProfile.clear();
    Get.offAll(() => const PhoneEntryPage());
  }
}
