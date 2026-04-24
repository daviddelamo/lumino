package com.lumino.lumino_app

import android.appwidget.AppWidgetManager
import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class WidgetConfigActivity : FlutterActivity() {

    override fun getInitialRoute(): String = "/widget-config"

    override fun onCreate(savedInstanceState: Bundle?) {
        val appWidgetId = intent.getIntExtra(
            AppWidgetManager.EXTRA_APPWIDGET_ID,
            AppWidgetManager.INVALID_APPWIDGET_ID
        )
        if (appWidgetId != AppWidgetManager.INVALID_APPWIDGET_ID) {
            val resultValue = Intent().apply {
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
            }
            setResult(RESULT_OK, resultValue)
        } else {
            setResult(RESULT_CANCELED)
        }
        super.onCreate(savedInstanceState)
    }
}
