// lib/home_page.dart
import 'dart:ui';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'controllers/home_controller.dart';

class HomePage extends GetView<HomeController> {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<HomeController>()) {
      Get.put(HomeController());
    }

    final ThemeData themeData = Theme.of(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('خانه'),
          backgroundColor: Colors.blueAccent,
          elevation: 0,
          centerTitle: true,
          actions: [
            IconButton(
              onPressed: controller.logout,
              icon: const Icon(Icons.logout),
              tooltip: 'خروج',
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
          child: Obx(() {
            if (controller.isLoading.value) {
              return const Center(child: CircularProgressIndicator());
            }
            if (controller.errorMessage.value.isNotEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      controller.errorMessage.value,
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: controller.fetchUserProfile,
                      child: const Text('تلاش مجدد'),
                    ),
                  ],
                ),
              );
            }

            final profile = controller.userProfile;
            if (profile.isEmpty) {
              return const Center(
                child: Text('اطلاعاتی موجود نیست. لطفاً بارگذاری کنید.'),
              );
            }

            // Sample "stories" data adapted from profile (customize as needed)
            final List<Map<String, dynamic>> quickInfo = [
              {
                'name': 'شماره',
                'value': controller.phone.value,
                'isViewed': true,
              },
              {
                'name': 'نام کاربری',
                'value': profile['UserName'] ?? 'ندارد',
                'isViewed': false,
              },
              {
                'name': 'شغل',
                'value': profile['Job'] ?? 'ندارد',
                'isViewed': true,
              },
              {
                'name': 'شیفت',
                'value': profile['Shift'] ?? 'ندارد',
                'isViewed': false,
              },
            ];

            return RefreshIndicator(
              onRefresh: () async {
                await controller.fetchUserProfile();
              },
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(32, 16, 32, 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'خوش آمدید! ${profile['Name'] ?? ''}',
                            style: themeData.textTheme.headlineSmall?.copyWith(
                              color: Colors.black,
                            ), // Improved: White text for better contrast on gradient
                          ),
                        ],
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.fromLTRB(32, 16, 32, 16),
                      child: Text(
                        'اطلاعات پروفایل',
                        style: themeData.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w500,
                        ), // Improved: Bolder for emphasis
                      ),
                    ),
                    _QuickInfoList(quickInfo: quickInfo),
                    // Adapted from _StoryList
                    const SizedBox(height: 16),
                    _ProfileSectionCarousel(
                      profile: profile,
                      maskedToken: controller.maskedToken.value,
                    ),
                    // Fixed: Removed extra comma
                    const SizedBox(height: 16),
                    _TransactionsList(
                      transactions: profile['Transactions'] ?? {},
                    ),
                    // Adapted from _PostList
                    const SizedBox(height: 16),
                    _ReservationsList(
                      reservations: profile['Reservations'] ?? {},
                    ),
                    // Adapted from _PostList
                    const SizedBox(height: 32),
                    Center(
                      child: ElevatedButton(
                        onPressed: controller.fetchUserProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent.shade200,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 28,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 5,
                          shadowColor: Colors.black38,
                        ),
                        child: const Text(
                          'بارگذاری مجدد اطلاعات',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _QuickInfoList extends StatelessWidget {
  final List<Map<String, dynamic>> quickInfo;

  const _QuickInfoList({required this.quickInfo});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      height: 100,
      child: ListView.builder(
        physics: const BouncingScrollPhysics(),
        itemCount: quickInfo.length,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(32, 0, 32, 0),
        itemBuilder: (context, index) {
          final info = quickInfo[index];
          return _QuickInfoItem(info: info);
        },
      ),
    );
  }
}

class _QuickInfoItem extends StatelessWidget {
  final Map<String, dynamic> info;

  const _QuickInfoItem({required this.info});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          Stack(
            children: [info['isViewed'] ? _profileViewed() : _profileNormal()],
          ),
          const SizedBox(height: 7),
          Text(
            info['name'],
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _profileNormal() {
    return SizedBox(
      height: 60,
      width: 80,
      child: DottedBorder(
        options: RoundedRectDottedBorderOptions(
          dashPattern: const [6, 3],
          strokeWidth: 2.5,
          radius: const Radius.circular(24),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xff376AED), Color(0xff49B0E2), Color(0xff9CECFB)],
          ),
          padding: const EdgeInsets.all(2),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(22),
              ),
              child: _profileContent(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _profileViewed() {
    return SizedBox(
      height: 60,
      width: 80,
      child: DottedBorder(
        options: RoundedRectDottedBorderOptions(
          dashPattern: const [6, 3],
          strokeWidth: 2.5,
          radius: const Radius.circular(24),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xff376AED), Color(0xff49B0E2), Color(0xff9CECFB)],
          ),
          padding: const EdgeInsets.all(2),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.95),
                    Colors.white.withOpacity(0.85),
                  ],
                ),
                borderRadius: BorderRadius.circular(22),
              ),
              child: _profileContent(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _profileContent() {
    return Center(
      child: Text(
        info['value'],
        style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _ProfileSectionCarousel extends StatelessWidget {
  final Map<String, dynamic> profile;
  final String maskedToken; // اضافه‌شده: پراپ جدید برای maskedToken

  const _ProfileSectionCarousel({
    required this.profile,
    required this.maskedToken, // اضافه‌شده
  });

  @override
  Widget build(BuildContext context) {
    // Sample "sections" adapted from profile data (customize images/assets)
    final List<Map<String, dynamic>> sections = [
      {
        'title': 'موجودی کیف پول',
        'value': profile['Balance'] ?? 0,
        'image': 'assets/img/posts/large/balance.png',
      },
      {
        'title': 'وضعیت فعال',
        'value': profile['IsActive'] == 1 ? 'فعال' : 'غیرفعال',
        'image': 'assets/img/posts/large/status.png',
      },
      {
        'title': 'تاریخ ثبت‌نام',
        'value': profile['RegisterDate'] ?? 'ندارد',
        'image': 'assets/img/posts/large/register.png',
      },
      {
        'title': 'توکن',
        'value': maskedToken,
        'image': 'assets/img/posts/large/token.png',
      }, // تغییر: استفاده از پراپ maskedToken به جای controller
    ];

    return CarouselSlider.builder(
      itemCount: sections.length,
      itemBuilder: (context, index, realIndex) {
        return _SectionItem(
          left: realIndex == 0 ? 32 : 8,
          right: realIndex == sections.length - 1 ? 32 : 8,
          section: sections[realIndex],
        );
      },
      options: CarouselOptions(
        scrollDirection: Axis.horizontal,
        viewportFraction: 0.7,
        aspectRatio: 1.3,
        initialPage: 0,
        scrollPhysics: const BouncingScrollPhysics(),
        disableCenter: true,
        enableInfiniteScroll: false,
        enlargeCenterPage: true,
        enlargeStrategy: CenterPageEnlargeStrategy.zoom,
      ),
    );
  }
}

class _SectionItem extends StatelessWidget {
  final Map<String, dynamic> section;
  final double left;
  final double right;

  const _SectionItem({
    required this.section,
    required this.left,
    required this.right,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.fromLTRB(6, 1, 6, 10),
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // بک‌گراند با سایه عمیق‌تر
          Positioned.fill(
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: Colors.white,
                boxShadow: const [
                  BoxShadow(
                    blurRadius: 25,
                    spreadRadius: -5,
                    offset: Offset(0, 10),
                    color: Color(0x330D253C),
                  ),
                  BoxShadow(
                    blurRadius: 10,
                    offset: Offset(0, 2),
                    color: Color(0x110D253C),
                  ),
                ],
              ),
            ),
          ),

          // محتوای اصلی کارت
          ClipRRect(
            borderRadius: BorderRadius.circular(25),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.blueAccent.withValues(alpha: 0.03),
                    Colors.blueAccent.withValues(alpha: 0.15),
                  ],
                ),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: Colors.blueAccent.withValues(alpha: 0.3),
                  style: BorderStyle.solid, // اگه dotted بخوای میشه تغییرش داد
                  width: 1.4,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // تصویر
                  SizedBox(
                    height: 100,
                    width: 239,
                    child: Image.asset(section['image']),
                  ),
                  const SizedBox(height: 16),

                  // عنوان
                  Text(
                    section['title'],
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // مقدار
                  Text(
                    '${section['value']}',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionsList extends StatelessWidget {
  final Map<String, dynamic> transactions;

  const _TransactionsList({required this.transactions});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 32, right: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'تراکنش‌ها',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              // Removed TextButton, as expansion handles "more"
            ],
          ),
        ),
        _buildTransactionsSection(transactions),
      ],
    );
  }
}

class _ReservationsList extends StatelessWidget {
  final Map<String, dynamic> reservations;

  const _ReservationsList({required this.reservations});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 32, right: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('رزروها', style: Theme.of(context).textTheme.headlineSmall),
              // Removed TextButton, as expansion handles "more"
            ],
          ),
        ),
        _buildReservationsSection(reservations),
      ],
    );
  }
}

// Adapted to use ExpansionTile for collapsible list
Widget _buildTransactionsSection(Map<String, dynamic> transactions) {
  final payments = transactions['Payments'] as List? ?? [];
  final reservationsTx = transactions['Reservations'] as List? ?? [];
  final upBalances = transactions['UpBalances'] as List? ?? [];

  final allTx = [
    ...payments,
    ...reservationsTx,
    ...upBalances,
  ]; // Combine for list view

  if (allTx.isEmpty) {
    return const Padding(
      padding: EdgeInsets.all(16.0),
      child: Text('هیچ تراکنشی موجود نیست.'),
    );
  }

  // Show first 3 items by default, rest in expansion
  final initialItems = allTx.take(3).toList();
  final remainingItems = allTx.skip(3).toList();

  return Column(
    children: [
      ...initialItems.map((tx) => _buildTransactionItem(tx)),
      if (remainingItems.isNotEmpty)
        ExpansionTile(
          title: const Text(
            'نمایش بیشتر',
            style: TextStyle(fontSize: 14, color: Color(0xff000000)),
          ),
          children: remainingItems
              .map((tx) => _buildTransactionItem(tx))
              .toList(),
        ),
    ],
  );
}

Widget _buildTransactionItem(Map<String, dynamic> tx) {
  return InkWell(
    onTap: () {}, // Add navigation if needed
    child: SizedBox(
      height: 148,
      width: 400,
      child: Container(
        margin: const EdgeInsets.fromLTRB(32, 8, 32, 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [
            BoxShadow(blurRadius: 16, color: Color(0x1a5282FF)),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.asset(
                'assets/img/posts/large/tx_image.png', // Placeholder asset
                width: 110,
                height: 90, // Improved: Fixed height to match item size
                // Improved: Better image fitting
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                // Improved: More vertical padding
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tx['Title'] ?? 'عنوان',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: Color(0xff376AED),
                      ),
                      maxLines: 1, // Fixed: Prevent overflow
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'مبلغ: ${tx['amount'] ?? 'نامشخص'} - تاریخ: ${tx['datetime'] ?? 'نامشخص'}',
                      maxLines: 2,
                      // Fixed: Limit lines to prevent vertical overflow
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Icon(CupertinoIcons.creditcard, size: 16),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// Similar adaptation for reservations with ExpansionTile
Widget _buildReservationsSection(Map<String, dynamic> reservations) {
  final completed = reservations['Completed'] as List? ?? [];
  final cancelled = reservations['Cancelled'] as List? ?? [];
  final pending = reservations['Pending'] as List? ?? [];

  final allRes = [
    ...completed,
    ...cancelled,
    ...pending,
  ]; // Combine for list view

  if (allRes.isEmpty) {
    return const Padding(
      padding: EdgeInsets.all(16.0),
      child: Text('هیچ رزرو موجود نیست.'),
    );
  }

  // Show first 3 items by default, rest in expansion
  final initialItems = allRes.take(3).toList();
  final remainingItems = allRes.skip(3).toList();

  return Column(
    children: [
      ...initialItems.map((res) => _buildReservationItem(res)),
      if (remainingItems.isNotEmpty)
        ExpansionTile(
          title: const Text(
            'نمایش بیشتر',
            style: TextStyle(fontSize: 14, color: Color(0xff000000)),
          ),
          children: remainingItems
              .map((res) => _buildReservationItem(res))
              .toList(),
        ),
    ],
  );
}

Widget _buildReservationItem(Map<String, dynamic> res) {
  return InkWell(
    onTap: () {}, // Add navigation if needed
    child: SizedBox(
      height: 148,
      width: 400,

      child: Container(
        margin: const EdgeInsets.fromLTRB(32, 8, 32, 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [
            BoxShadow(blurRadius: 16, color: Color(0x1a5282FF)),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.asset(
                'assets/img/posts/large/res_image.png', // Placeholder asset
                width: 110,
                height: 90, // Improved: Fixed height
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                // Improved: More padding
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${res['Job'] ?? 'نامشخص'} - ${res['Company'] ?? 'نامشخص'}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: Color(0xff376AED),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'تاریخ: ${res['JalaliDate'] ?? ''} (${res['WeekDay'] ?? ''}) - زمان: ${res['StartTime'] ?? ''} تا ${res['EndeTime'] ?? ''}',
                      maxLines: 2,
                      // Fixed: Limit to 2 lines to prevent vertical overflow
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Icon(CupertinoIcons.location, size: 16),
                        const SizedBox(width: 4),
                        Expanded(
                          // Fixed: Prevent horizontal overflow
                          child: Text(
                            res['Location'] ?? 'ندارد',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
