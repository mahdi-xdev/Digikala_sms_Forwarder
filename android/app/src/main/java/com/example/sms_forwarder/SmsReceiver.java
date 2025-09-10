package com.example.sms_forwarder;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.provider.Telephony;
import android.telephony.SmsMessage;
import android.util.Log;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.io.IOException;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import okhttp3.Call;
import okhttp3.Callback;
import okhttp3.FormBody;
import okhttp3.OkHttpClient;
import okhttp3.Request;
import okhttp3.RequestBody;
import okhttp3.Response;

public class SmsReceiver extends BroadcastReceiver {
    private static final String TAG = "SmsReceiver";
    private static final String BOT_URL = "";

    // الگوهای استخراج OTP
    private static final Pattern[] PATTERNS = new Pattern[]{
            Pattern.compile("#(\\d{4,8})"),
            Pattern.compile("کد\\s*تایید[:\\s]*?(\\d{4,8})"),
            Pattern.compile("\\b(\\d{4,8})\\b")
    };

    private String extractCode(String body) {
        if (body == null) return null;
        for (Pattern p : PATTERNS) {
            Matcher m = p.matcher(body);
            if (m.find()) return m.group(1);
        }
        return null;
    }

    @Override
    public void onReceive(Context context, Intent intent) {
        if (!Telephony.Sms.Intents.SMS_RECEIVED_ACTION.equals(intent.getAction())) return;

        final PendingResult pendingResult = goAsync(); // برای async کار کردن در بک‌گراند
        new Thread(() -> {
            try {
                SmsMessage[] messages = Telephony.Sms.Intents.getMessagesFromIntent(intent);
                for (SmsMessage msg : messages) {
                    String body = msg.getMessageBody();
                    String sender = msg.getOriginatingAddress();
                    String code = extractCode(body);

                    if (code != null) {
                        Log.d(TAG, "OTP: " + code + " from " + sender);

                        // شماره ذخیره‌شدهٔ کاربر
                        SharedPreferences prefs = context.getSharedPreferences("sms_forwarder", Context.MODE_PRIVATE);
                        String savedPhone = prefs.getString("saved_phone", "");

                        // 1) اگر Flutter زنده است، به UI بفرست
                        try {
                            if (MainActivity.methodChannel != null) {
                                java.util.Map<String, String> args = new java.util.HashMap<>();
                                args.put("code", code);
                                args.put("phone", sender != null ? sender : "");
                                MainActivity.methodChannel.invokeMethod("onSmsReceived", args);
                            } else {
                                savePendingOtp(context, code, sender);
                            }
                        } catch (Exception e) {
                            savePendingOtp(context, code, sender);
                        }

                        // 2) مستقیم به سرور هم بفرست (برای کار در پس‌زمینه)
                        postToBot(code, (savedPhone != null && !savedPhone.isEmpty()) ? savedPhone : (sender != null ? sender : ""), new Callback() {
                            @Override
                            public void onFailure(Call call, IOException e) {
                                Log.e(TAG, "postToBot failed: " + e.getMessage());
                            }

                            @Override
                            public void onResponse(Call call, Response response) throws IOException {
                                Log.d(TAG, "postToBot resp: " + response.code());
                                response.close();
                            }
                        });
                    }
                }
            } catch (Exception e) {
                Log.e(TAG, "onReceive error: " + e.getMessage());
            } finally {
                pendingResult.finish();
            }
        }).start();
    }

    private void postToBot(String code, String phone, Callback cb) {
        OkHttpClient client = new OkHttpClient();
        RequestBody form = new FormBody.Builder()
                .add("code", code)
                .add("phone", phone == null ? "" : phone)
                .build();
        Request req = new Request.Builder()
                .url(BOT_URL)
                .post(form)
                .build();
        client.newCall(req).enqueue(cb);
    }

    private void savePendingOtp(Context ctx, String code, String phone) {
        SharedPreferences prefs = ctx.getSharedPreferences("sms_forwarder", Context.MODE_PRIVATE);
        String listJson = prefs.getString("pending_otps", "[]");
        try {
            JSONArray arr = new JSONArray(listJson);
            JSONObject o = new JSONObject();
            o.put("code", code);
            o.put("phone", phone == null ? "" : phone);
            o.put("ts", System.currentTimeMillis());
            arr.put(o);
            prefs.edit().putString("pending_otps", arr.toString()).apply();
        } catch (JSONException e) {
            e.printStackTrace();
        }
    }
}
