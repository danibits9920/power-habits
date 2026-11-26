package com.daltex.power_habits

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.view.View
import android.widget.RemoteViews

class PowerHabitsWidgetProvider : AppWidgetProvider() {
    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            ACTION_TOGGLE_ROUTINE -> {
                val id = intent.getStringExtra(EXTRA_ROUTINE_ID).orEmpty()
                if (id.isNotEmpty()) {
                    WidgetStore.toggleRoutine(context, id)
                }
            }
            ACTION_CYCLE_FILTER -> {
                WidgetStore.cycleHoyFilter(context)
                updateAll(context)
            }
            ACTION_HOY_PAGE -> {
                val delta = intent.getIntExtra(EXTRA_PAGE_DELTA, 1)
                val filter = WidgetStore.getHoyFilter(context)
                val filtered = filterItems(WidgetStore.getTodayItems(context), filter)
                val pages = ((filtered.size + PAGE_SIZE - 1) / PAGE_SIZE).coerceAtLeast(1)
                WidgetStore.shiftHoyPage(context, delta, pages)
                updateAll(context)
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
        const val PREFS = WidgetStore.PREFS
        const val EXTRA_ROUTE = WidgetStore.EXTRA_ROUTE
        const val ACTION_TOGGLE_ROUTINE = "com.daltex.power_habits.WIDGET_TOGGLE_ROUTINE"
        const val ACTION_CYCLE_FILTER = "com.daltex.power_habits.WIDGET_CYCLE_FILTER"
        const val ACTION_HOY_PAGE = "com.daltex.power_habits.WIDGET_HOY_PAGE"
        const val EXTRA_ROUTINE_ID = "routine_id"
        const val EXTRA_PAGE_DELTA = "page_delta"
        private const val PAGE_SIZE = 4

        private fun filterItems(
            items: List<WidgetRoutineItem>,
            filter: String
        ): List<WidgetRoutineItem> = when (filter) {
            "personal" -> items.filter { it.contextType == "personal" }
            "work" -> items.filter { it.contextType == "work" }
            else -> items
        }

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
            val filter = WidgetStore.getHoyFilter(context)
            val allItems = WidgetStore.getTodayItems(context)
            val filtered = filterItems(allItems, filter)

            val total = filtered.size
            val done = filtered.count { it.completed }
            val pct = if (total == 0) 0 else ((done * 100.0) / total).toInt().coerceIn(0, 100)

            val totalPages = ((total + PAGE_SIZE - 1) / PAGE_SIZE).coerceAtLeast(1)
            val page = WidgetStore.getHoyPage(context).coerceIn(0, totalPages - 1)
            val start = page * PAGE_SIZE
            val pageItems = filtered.drop(start).take(PAGE_SIZE)

            val views = RemoteViews(context.packageName, R.layout.power_habits_widget)
            views.setTextViewText(R.id.tv_header, "Hoy")
            views.setTextViewText(R.id.tv_pct, "$pct%")
            views.setTextViewText(
                R.id.tv_count,
                if (total > 0) "$done de $total completadas" else "Sin pendientes"
            )
            views.setProgressBar(R.id.pb_progress, 100, pct, false)

            // Filter pill styling & label
            val (filterLabel, filterBg, filterText) = when (filter) {
                "personal" -> Triple("Personal", R.drawable.widget_pill_pink, Color.parseColor("#5C2840"))
                "work" -> Triple("Laboral", R.drawable.widget_pill_gray, Color.parseColor("#2C2F33"))
                else -> Triple("Todo", R.drawable.widget_pill_pink, Color.parseColor("#5C2840"))
            }
            views.setTextViewText(R.id.btn_filter, filterLabel)
            views.setInt(R.id.btn_filter, "setBackgroundResource", filterBg)
            views.setTextColor(R.id.btn_filter, filterText)

            val filterPending = PendingIntent.getBroadcast(
                context,
                3001,
                Intent(context, PowerHabitsWidgetProvider::class.java).apply {
                    action = ACTION_CYCLE_FILTER
                },
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.btn_filter, filterPending)

            // Open app & add buttons
            val openTodayPending = PendingIntent.getActivity(
                context,
                3002,
                Intent(context, MainActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                    putExtra(EXTRA_ROUTE, "/hoy")
                },
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.area_open_today, openTodayPending)
            views.setOnClickPendingIntent(R.id.tv_empty, openTodayPending)

            val addPending = PendingIntent.getActivity(
                context,
                3003,
                Intent(context, MainActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                    putExtra(EXTRA_ROUTE, "/hoy?new=1")
                },
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.btn_add, addPending)

            val rowIds = intArrayOf(R.id.row_1, R.id.row_2, R.id.row_3, R.id.row_4)
            val chkIds = intArrayOf(R.id.chk_1, R.id.chk_2, R.id.chk_3, R.id.chk_4)
            val txtIds = intArrayOf(R.id.tv_item_1, R.id.tv_item_2, R.id.tv_item_3, R.id.tv_item_4)
            val tagIds = intArrayOf(R.id.tag_1, R.id.tag_2, R.id.tag_3, R.id.tag_4)

            if (pageItems.isEmpty()) {
                val emptyMsg = when {
                    allItems.isEmpty() -> "Abre Power Habits para cargar tus rutinas"
                    filter == "personal" -> "Sin rutinas personales para hoy"
                    filter == "work" -> "Sin tareas laborales para hoy"
                    else -> "Todo completado por hoy"
                }
                views.setTextViewText(R.id.tv_empty, emptyMsg)
                views.setViewVisibility(R.id.tv_empty, View.VISIBLE)
                for (rid in rowIds) views.setViewVisibility(rid, View.GONE)
            } else {
                views.setViewVisibility(R.id.tv_empty, View.GONE)
                for (i in 0 until PAGE_SIZE) {
                    if (i < pageItems.size) {
                        val item = pageItems[i]
                        views.setViewVisibility(rowIds[i], View.VISIBLE)
                        views.setTextViewText(txtIds[i], item.title)

                        if (item.completed) {
                            views.setInt(rowIds[i], "setBackgroundResource", R.drawable.widget_row_done_bg)
                            views.setInt(chkIds[i], "setBackgroundResource", R.drawable.widget_check_on)
                            views.setTextViewText(chkIds[i], "✓")
                            views.setTextColor(txtIds[i], Color.parseColor("#6B7280"))
                        } else {
                            views.setInt(rowIds[i], "setBackgroundResource", R.drawable.widget_row_bg)
                            views.setInt(chkIds[i], "setBackgroundResource", R.drawable.widget_check_off)
                            views.setTextViewText(chkIds[i], "")
                            views.setTextColor(txtIds[i], Color.parseColor("#141517"))
                        }

                        if (item.contextType == "work") {
                            views.setTextViewText(tagIds[i], "L")
                            views.setInt(tagIds[i], "setBackgroundResource", R.drawable.widget_pill_gray)
                            views.setTextColor(tagIds[i], Color.parseColor("#2C2F33"))
                        } else {
                            views.setTextViewText(tagIds[i], "P")
                            views.setInt(tagIds[i], "setBackgroundResource", R.drawable.widget_pill_pink)
                            views.setTextColor(tagIds[i], Color.parseColor("#5C2840"))
                        }

                        val toggleIntent = Intent(context, PowerHabitsWidgetProvider::class.java).apply {
                            action = ACTION_TOGGLE_ROUTINE
                            putExtra(EXTRA_ROUTINE_ID, item.id)
                        }
                        val togglePending = PendingIntent.getBroadcast(
                            context,
                            3100 + i,
                            toggleIntent,
                            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                        )
                        views.setOnClickPendingIntent(rowIds[i], togglePending)
                    } else {
                        views.setViewVisibility(rowIds[i], View.GONE)
                    }
                }
            }

            if (totalPages > 1) {
                views.setViewVisibility(R.id.pager_row, View.VISIBLE)
                views.setTextViewText(R.id.tv_page_info, "Página ${page + 1} de $totalPages")
                val prevPending = PendingIntent.getBroadcast(
                    context,
                    3201,
                    Intent(context, PowerHabitsWidgetProvider::class.java).apply {
                        action = ACTION_HOY_PAGE
                        putExtra(EXTRA_PAGE_DELTA, -1)
                    },
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                val nextPending = PendingIntent.getBroadcast(
                    context,
                    3202,
                    Intent(context, PowerHabitsWidgetProvider::class.java).apply {
                        action = ACTION_HOY_PAGE
                        putExtra(EXTRA_PAGE_DELTA, 1)
                    },
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                views.setOnClickPendingIntent(R.id.btn_prev_page, prevPending)
                views.setOnClickPendingIntent(R.id.btn_next_page, nextPending)
            } else {
                views.setViewVisibility(R.id.pager_row, View.GONE)
            }

            mgr.updateAppWidget(appWidgetId, views)
        }
    }
}
