package com.daltex.power_habits

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.view.View
import android.widget.RemoteViews
import org.json.JSONArray

class PowerHabitsWidgetProvider : AppWidgetProvider() {
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
        const val PREFS = "power_habits_widget"
        const val EXTRA_ROUTE = "widget_route"

        fun updateAll(context: Context) {
            val mgr = AppWidgetManager.getInstance(context)
            val ids = mgr.getAppWidgetIds(
                ComponentName(context, PowerHabitsWidgetProvider::class.java)
            )
            for (id in ids) {
                updateWidget(context, mgr, id)
            }
        }

        private fun updateWidget(
            context: Context,
            mgr: AppWidgetManager,
            appWidgetId: Int
        ) {
            val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            val pct = prefs.getInt("pct", 0).coerceIn(0, 100)
            val doneCount = prefs.getInt("doneCount", 0)
            val totalCount = prefs.getInt("totalCount", 0)
            val rawTitles = prefs.getString("pendingTitles", "[]") ?: "[]"

            val pending = mutableListOf<String>()
            try {
                val arr = JSONArray(rawTitles)
                for (i in 0 until minOf(arr.length(), 3)) {
                    val text = arr.optString(i).trim()
                    if (text.isNotEmpty()) pending.add(text)
                }
            } catch (_: Exception) {
                // Ignorar JSON malformado en preferencias previas.
            }

            val views = RemoteViews(context.packageName, R.layout.power_habits_widget)
            views.setTextViewText(R.id.tv_header, "Power Habits · Hoy")
            views.setTextViewText(R.id.tv_pct, "$pct%")
            views.setTextViewText(
                R.id.tv_count,
                if (totalCount > 0) "$doneCount/$totalCount" else "Sin rutinas"
            )
            views.setProgressBar(R.id.pb_progress, 100, pct, false)

            val itemIds = intArrayOf(R.id.tv_item_1, R.id.tv_item_2, R.id.tv_item_3)
            if (pending.isEmpty()) {
                val emptyText = if (totalCount > 0 && doneCount >= totalCount) {
                    "Todo completado por hoy"
                } else {
                    "Abre la app para ver tus rutinas"
                }
                views.setTextViewText(itemIds[0], emptyText)
                views.setViewVisibility(itemIds[0], View.VISIBLE)
                views.setViewVisibility(itemIds[1], View.GONE)
                views.setViewVisibility(itemIds[2], View.GONE)
            } else {
                for (i in itemIds.indices) {
                    if (i < pending.size) {
                        views.setTextViewText(itemIds[i], "• ${pending[i]}")
                        views.setViewVisibility(itemIds[i], View.VISIBLE)
                    } else {
                        views.setViewVisibility(itemIds[i], View.GONE)
                    }
                }
            }

            val openTodayIntent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                putExtra(EXTRA_ROUTE, "/hoy")
            }
            val openTodayPending = PendingIntent.getActivity(
                context,
                2001,
                openTodayIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_root, openTodayPending)

            val addIntent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                putExtra(EXTRA_ROUTE, "/hoy?new=1")
            }
            val addPending = PendingIntent.getActivity(
                context,
                2002,
                addIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.btn_add, addPending)

            mgr.updateAppWidget(appWidgetId, views)
        }
    }
}
