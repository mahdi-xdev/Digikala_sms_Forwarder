package com.example.sms_forwarder;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.util.Log;

public class BootReceiver extends BroadcastReceiver {
    @Override
    public void onReceive(Context context, Intent intent) {
        try {
            // بعد از بوت سرویس foreground رو بالا بیاور
            Intent svc = new Intent(context, KeepAliveService.class);
            context.startForegroundService(svc);
        } catch (Exception e) {
            Log.e("BootReceiver", "start service error: " + e.getMessage());
        }
    }
}
