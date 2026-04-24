package com.lumino.lumino_app

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import java.util.Calendar

class MidnightUpdateReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        val appWidgetManager = AppWidgetManager.getInstance(context)

        val smallIds = appWidgetManager.getAppWidgetIds(
            ComponentName(context, LuminoSmallWidget::class.java)
        )
        for (id in smallIds) {
            LuminoSmallWidget.updateWidget(context, appWidgetManager, id)
        }

        val largeIds = appWidgetManager.getAppWidgetIds(
            ComponentName(context, LuminoLargeWidget::class.java)
        )
        for (id in largeIds) {
            LuminoLargeWidget.updateWidget(context, appWidgetManager, id)
        }

        scheduleMidnightAlarm(context)
    }

    companion object {
        private const val ACTION_MIDNIGHT = "com.lumino.lumino_app.MIDNIGHT_UPDATE"

        fun scheduleMidnightAlarm(context: Context) {
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            val intent = Intent(context, MidnightUpdateReceiver::class.java).apply {
                action = ACTION_MIDNIGHT
            }
            val pendingIntent = PendingIntent.getBroadcast(
                context, 0, intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            val midnight = Calendar.getInstance().apply {
                add(Calendar.DAY_OF_YEAR, 1)
                set(Calendar.HOUR_OF_DAY, 0)
                set(Calendar.MINUTE, 0)
                set(Calendar.SECOND, 0)
                set(Calendar.MILLISECOND, 0)
            }

            alarmManager.setExactAndAllowWhileIdle(
                AlarmManager.RTC_WAKEUP,
                midnight.timeInMillis,
                pendingIntent
            )
        }
    }
}
