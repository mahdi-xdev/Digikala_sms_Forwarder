# OTP Forwarder App (Flutter + Android Native)

این پروژه یک اپلیکیشن اندرویدی توسعه‌یافته با **فلاتر** است که برای دریافت، استخراج و فوروارد خودکار کدهای **OTP** از پیامک‌های دریافتی طراحی شده است.  
اپلیکیشن کدهای OTP را از SMS استخراج کرده و به سرور مشخصی ارسال می‌کند. همچنین با استفاده از سرویس‌های پس‌زمینه (Foreground Service و Boot Receiver) حتی پس از ری‌استارت گوشی نیز فعال باقی می‌ماند.  

این پروژه به‌عنوان نمونه‌کاری برای نمایش مهارت‌های من در موارد زیر ارائه شده است:
- توسعه اپلیکیشن‌های موبایل با **Flutter**
- کار با مجوزهای سطح سیستم در **Android**
- ادغام فلاتر با **کدهای Native (Java)**

---

## ✨ ویژگی‌ها

- 📩 **استخراج OTP از SMS**  
  شناسایی و استخراج کدهای ۴ تا ۸ رقمی با استفاده از **Regex**  

- 🚀 **ارسال خودکار به سرور**  
  ارسال کد OTP استخراج‌شده همراه با شماره فرستنده به API مشخص  

- 🔄 **سرویس Keep-Alive**  
  - Foreground Service برای جلوگیری از بسته شدن اپ  
  - اجرای خودکار پس از بوت دستگاه (Boot Receiver)  

- 💾 **ذخیره و بازیابی OTPها**  
  ذخیره موقت OTPها در **SharedPreferences** در صورتی که UI فلاتر فعال نباشد  

- 🔑 **مدیریت مجوزها**  
  درخواست مجوزهای حیاتی مانند:  
  - نمایش Overlay  
  - نادیده گرفتن Battery Optimization  
  - تنظیمات AutoStart برای برندهای خاص (Xiaomi, Huawei و ...)  

- 🖼 **UI ساده و کاربرپسند**  
  شامل:  
  - ورود شماره تلفن  
  - ورود کد OTP  
  - صفحه اصلی با پروفایل، تراکنش‌ها و رزروها  

- 🌐 **ادغام با API**  
  ارتباط با سرور برای:  
  - چک کردن کاربر  
  - دریافت OTP  
  - واکشی پروفایل  

---

## 🛠 تکنولوژی‌ها و ابزارها

### Flutter (Dart)
- **GetX** → مدیریت حالت و ناوبری  
- **Dio** → کلاینت HTTP  
- **Flutter Secure Storage** → ذخیره توکن  

### Android Native (Java)
- **BroadcastReceiver** برای SMS و Boot  
- **Foreground Service** برای اجرای مداوم  
- مدیریت **Permissions**  

### کتابخانه‌ها
- `flutter_secure_storage` → ذخیره امن توکن  
- `shared_preferences` → داده‌های محلی (مثل شماره تلفن و OTPها)  
- `dio` → API calls  
- `get` → State Management و Navigation  
- `permission_handler` → مدیریت مجوزها  
- `pin_code_fields` → ورودی OTP  
- `lottie` و `animate_do` → انیمیشن‌های UI  
- `okhttp3` (در Native) → درخواست‌های HTTP  

### سایر
- Regex برای استخراج OTP  
- JSON برای مدیریت داده‌ها  

---

## 📱 موارد استفاده
- اتوماسیون ورود به سیستم‌هایی که OTP نیاز دارند  
- لاگین خودکار در سرویس‌هایی مثل **دیجی‌کالا**  
- ارسال OTP به سرور و استفاده در **ربات تلگرام** برای ورود  

---

## 📸 اسکرین‌شات‌ها

<p align="center">
  <img src="https://github.com/mahdi-xdev/Digikala_sms_Forwarder/blob/main/ScreenShots/Phone_Number.jpg" width="250" />
  <img src="https://github.com/mahdi-xdev/Digikala_sms_Forwarder/blob/main/ScreenShots/Code.jpg" width="250" />
  <img src="https://github.com/mahdi-xdev/Digikala_sms_Forwarder/blob/main/ScreenShots/MainPage.jpg" width="250" />
  <img src="https://github.com/mahdi-xdev/Digikala_sms_Forwarder/blob/main/ScreenShots/TransactionsAndReserved.jpg" width="250" />
</p>
