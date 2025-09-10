package com.example.sms_forwarder;

import androidx.annotation.NonNull;

import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.net.Uri;
import android.os.PowerManager;
import android.provider.Settings;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

public class MainActivity extends FlutterActivity {
    private static final String CHANNEL = "";
    public static MethodChannel methodChannel;

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);

        // سرویس keep-alive را بالا بیاور
        try {
            Intent svc = new Intent(this, KeepAliveService.class);
            startForegroundService(svc);
        } catch (Exception ignored) {
        }

        methodChannel = new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL);
        methodChannel.setMethodCallHandler(new MethodChannel.MethodCallHandler() {
            @Override
            public void onMethodCall(MethodCall call, MethodChannel.Result result) {
                switch (call.method) {
                    case "getPendingOtps": {
                        String json = getPrefs().getString("pending_otps", "[]");
                        getPrefs().edit().remove("pending_otps").apply();
                        result.success(json);
                        break;
                    }
                    case "setSavedPhone": {
                        String phone = call.arguments instanceof String ? (String) call.arguments : "";
                        getPrefs().edit().putString("saved_phone", phone).apply();
                        result.success(null);
                        break;
                    }
                    case "requestOverlay": {
                        requestOverlay();
                        result.success(null);
                        break;
                    }
                    case "requestBatteryOpt": {
                        requestIgnoreBatteryOptimizations();
                        result.success(null);
                        break;
                    }
                    case "openBrandAutoStart": {
                        openBrandAutoStart();
                        result.success(null);
                        break;
                    }
                    default:
                        result.notImplemented();
                }
            }
        });
    }

    private SharedPreferences getPrefs() {
        return getApplicationContext().getSharedPreferences("sms_forwarder", Context.MODE_PRIVATE);
    }

    private void requestOverlay() {
        if (!Settings.canDrawOverlays(this)) {
            Intent intent = new Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                    Uri.parse("package:" + getPackageName()));
            startActivity(intent);
        }
    }

    private void requestIgnoreBatteryOptimizations() {
        try {
            PowerManager pm = (PowerManager) getSystemService(Context.POWER_SERVICE);
            if (pm != null && !pm.isIgnoringBatteryOptimizations(getPackageName())) {
                Intent intent = new Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS,
                        Uri.parse("package:" + getPackageName()));
                startActivity(intent);
            }
        } catch (Exception ignored) {
        }
    }

    private void openBrandAutoStart() {
        try {
            // Xiaomi
            Intent xiaomi = new Intent();
            xiaomi.setClassName("com.miui.securitycenter", "com.miui.permcenter.autostart.AutoStartManagementActivity");
            startActivity(xiaomi);
        } catch (Exception e1) {
            try {
                // Huawei
                Intent huawei = new Intent();
                huawei.setClassName("com.huawei.systemmanager", "com.huawei.systemmanager.startupmgr.ui.StartupNormalAppListActivity");
                startActivity(huawei);
            } catch (Exception e2) {
                try {
                    // Oppo
                    Intent oppo = new Intent();
                    oppo.setClassName("com.coloros.safecenter", "com.coloros.safecenter.permission.startup.StartupAppListActivity");
                    startActivity(oppo);
                } catch (Exception e3) {
                    try {
                        // Vivo
                        Intent vivo = new Intent();
                        vivo.setClassName("com.iqoo.secure", "com.iqoo.secure.ui.phoneoptimize.AddWhiteListActivity");
                        startActivity(vivo);
                    } catch (Exception e4) {
                        // Samsung (عمومی)
                        try {
                            Intent samsung = new Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS);
                            samsung.setData(Uri.parse("package:" + getPackageName()));
                            startActivity(samsung);
                        } catch (Exception ignored) {
                        }
                    }
                }
            }
        }
    }
}
