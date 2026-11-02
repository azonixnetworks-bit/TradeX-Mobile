package com.azonixnetworks.tradex_mobile

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.view.View
import android.widget.RemoteViews
import java.text.DateFormat
import java.util.Date

class TradeXHomeWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        appWidgetIds.forEach { updateWidget(context, appWidgetManager, it) }
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: android.os.Bundle
    ) {
        updateWidget(context, appWidgetManager, appWidgetId)
    }

    companion object {
        private const val preferencesName = "tradex_home_widget"

        fun updateAll(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val component = ComponentName(context, TradeXHomeWidgetProvider::class.java)
            manager.getAppWidgetIds(component).forEach {
                updateWidget(context, manager, it)
            }
        }

        private fun updateWidget(
            context: Context,
            manager: AppWidgetManager,
            widgetId: Int
        ) {
            val preferences = context.getSharedPreferences(preferencesName, Context.MODE_PRIVATE)
            val views = RemoteViews(context.packageName, R.layout.tradex_home_widget)
            views.setTextViewText(R.id.session_sydney, "SYD ${preferences.getString("session_sydney", "—")}")
            views.setTextViewText(R.id.session_tokyo, "TYO ${preferences.getString("session_tokyo", "—")}")
            views.setTextViewText(R.id.session_london, "LON ${preferences.getString("session_london", "—")}")
            views.setTextViewText(R.id.session_new_york, "NY ${preferences.getString("session_new_york", "—")}")
            views.setTextViewText(
                R.id.widget_news,
                preferences.getString("news", "Open TradeX to load today’s market news")
            )
            views.setTextViewText(
                R.id.widget_signal,
                preferences.getString("signal", "Open TradeX to load the latest signal")
            )
            val updatedAt = preferences.getLong("updated_at", 0L)
            views.setTextViewText(
                R.id.widget_updated,
                if (updatedAt == 0L) "Waiting for secure sync"
                else "Updated ${DateFormat.getTimeInstance(DateFormat.SHORT).format(Date(updatedAt))}"
            )

            val options = manager.getAppWidgetOptions(widgetId)
            val minHeight = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT)
            views.setViewVisibility(R.id.widget_news_group, if (minHeight >= 150) View.VISIBLE else View.GONE)
            views.setViewVisibility(R.id.widget_signal_group, if (minHeight >= 205) View.VISIBLE else View.GONE)

            val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
            if (launchIntent != null) {
                launchIntent.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                val pendingIntent = PendingIntent.getActivity(
                    context,
                    0,
                    launchIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)
            }
            manager.updateAppWidget(widgetId, views)
        }
    }
}
