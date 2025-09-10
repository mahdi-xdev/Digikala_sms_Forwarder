// lib/splash_screen.dart
import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'phone_entry_page.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Future.delayed(const Duration(milliseconds: 3500), () {
      Get.off(() => const PhoneEntryPage());
    });
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.blueAccent, Colors.white],
            ),
          ),
          child: Center(
            child: Bounce(
              duration: const Duration(milliseconds: 1000),
              child: Lottie.asset(
                'assets/SandyLoading.json',
                width: 300,
                height: 300,
                fit: BoxFit.contain,
                repeat: true,
                animate: true,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
