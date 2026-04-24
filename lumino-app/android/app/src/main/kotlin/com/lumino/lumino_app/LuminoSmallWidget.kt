package com.lumino.lumino_app

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetPlugin
import org.json.JSONArray

class LuminoSmallWidget : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (id in appWidgetIds) {
            updateWidget(context, appWidgetManager, id)
        }
    }

    companion object {
        fun updateWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val widgetData = HomeWidgetPlugin.getData(context)
            val type      = widgetData.getString("lumino_widget_type",  "tasks") ?: "tasks"
            val itemsJson = widgetData.getString("lumino_widget_items", "[]")    ?: "[]"

            val views = RemoteViews(context.packageName, R.layout.widget_small)
            views.setTextViewText(R.id.tv_header_title, "Today")
            views.setTextViewText(R.id.tv_header_type, if (type == "tasks") "Tasks" else "Habits")

            val items = try { JSONArray(itemsJson) } catch (e: Exception) { JSONArray() }

            data class RowIds(val layout: Int, val title: Int, val complete: Int)
            val rowIds = listOf(
                RowIds(R.id.row_0_layout, R.id.row_0_title, R.id.row_0_complete),
                RowIds(R.id.row_1_layout, R.id.row_1_title, R.id.row_1_complete),
                RowIds(R.id.row_2_layout, R.id.row_2_title, R.id.row_2_complete),
            )

            for (i in rowIds.indices) {
                val row = rowIds[i]
                if (i < items.length()) {
                    val item      = items.getJSONObject(i)
                    val itemId    = item.getString("id")
                    val completed = item.getBoolean("completed")

                    views.setViewVisibility(row.layout, View.VISIBLE)
                    views.setTextViewText(row.title, item.getString("title"))
                    views.setImageViewResource(
                        row.complete,
                        if (completed) R.drawable.ic_check_done else R.drawable.ic_check_empty
                    )

                    val actionUri = if (type == "habits") {
                        Uri.parse("lumino://action?type=complete_habit&id=$itemId")
                    } else {
                        Uri.parse("lumino://open?type=task&id=$itemId")
                    }
                    val completePendingIntent = if (type == "habits") {
                        HomeWidgetBackgroundIntent.getBroadcast(context, actionUri)
                    } else {
                        HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java, actionUri)
                    }
                    views.setOnClickPendingIntent(row.complete, completePendingIntent)

                    val openUri    = Uri.parse("lumino://open?type=$type&id=$itemId")
                    val openIntent = HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java, openUri)
                    views.setOnClickPendingIntent(row.layout, openIntent)
                } else {
                    views.setViewVisibility(row.layout, View.GONE)
                }
            }

            val overflow = items.length() - rowIds.size
            if (overflow > 0) {
                views.setViewVisibility(R.id.tv_overflow, View.VISIBLE)
                views.setTextViewText(R.id.tv_overflow, "+$overflow more")
                val tabUri    = Uri.parse("lumino://open?type=$type")
                val tabIntent = HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java, tabUri)
                views.setOnClickPendingIntent(R.id.tv_overflow, tabIntent)
            } else {
                views.setViewVisibility(R.id.tv_overflow, View.GONE)
            }

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
