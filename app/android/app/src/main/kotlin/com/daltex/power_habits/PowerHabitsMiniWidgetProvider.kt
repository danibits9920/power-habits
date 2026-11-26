package com.daltex.power_habits

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews

class PowerHabitsMiniWidgetProvider : AppWidgetProvider() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == ACTION_CHECK_NEXT) {
            val id = intent.getStringExtra(EXTRA_ROUTINE_ID).orEmpty()
            if (id.isNotEmpty()) {
                WidgetStore.toggleRoutine(context, id)
            }
        }
        super.onReceive(context, intent)
    }

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
        const val ACTION_CHECK_NEXT = "com.daltex.power_habits.WIDGET_MINI_CHECK_NEXT"
        const val EXTRA_ROUTINE_ID = "routine_id"

        fun updateAll(context: Context) {
            val mgr = AppWidgetManager.getInstance(context)
            val ids = mgr.getAppWidgetIds(
                ComponentName(context, PowerHabitsMiniWidgetProvider::class.java)
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
            val items = WidgetStore.getTodayItems(context)
            val total = items.size
            val done = items.count { it.completed }
            val pct = if (total == 0) 0 else ((done * 100.0) / total).toInt().coerceIn(0, 100)
            val nextPending = items.firstOrNull { !it.completed }

            val views = RemoteViews(context.packageName, R.layout.power_habits_mini_widget)
            views.setTextViewText(R.id.tv_mini_pct, "$pct%")
            views.setTextViewText(R.id.tv_mini_count, "$done/$total hoy")
            views.setProgressBar(R.id.pb_mini, 100, pct, false)

            val openTodayPending = PendingIntent.getActivity(
                context,
                5001,
                Intent(context, MainActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                    putExtra(WidgetStore.EXTRA_ROUTE, "/hoy")
                },
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.mini_widget_root, openTodayPending)

            val addPending = PendingIntent.getActivity(
                context,
                5002,
                Intent(context, MainActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                    putExtra(WidgetStore.EXTRA_ROUTE, "/hoy?new=1")
                },
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.btn_mini_add, addPending)

            if (nextPending != null) {
                views.setTextViewText(R.id.tv_mini_next, nextPending.title)
                views.setInt(R.id.chk_mini_next, "setBackgroundResource", R.drawable.widget_check_off)
                views.setTextViewText(R.id.chk_mini_next, "")
                val checkPending = PendingIntent.getBroadcast(
                    context,
                    5010,
                    Intent(context, PowerHabitsMiniWidgetProvider::class.java).apply {
                        action = ACTION_CHECK_NEXT
                        putExtra(EXTRA_ROUTINE_ID, nextPending.id)
                    },
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                views.setOnClickPendingIntent(R.id.row_mini_next, checkPending)
            } else {
                val msg = if (total == 0) "Crea tu primera rutina" else "Todo listo por hoy"
                views.setTextViewText(R.id.tv_mini_next, msg)
                views.setInt(
                    R.id.chk_mini_next,
                    "setBackgroundResource",
                    if (total > 0) R.drawable.widget_check_on else R.drawable.widget_check_off
                )
                views.setTextViewText(R.id.chk_mini_next, if (total > 0) "✓" else "")
                views.setOnClickPendingIntent(R.id.row_mini_next, openTodayPending)
            }

            mgr.updateAppWidget(appWidgetId, views)
        }
    }
}
