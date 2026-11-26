package com.daltex.power_habits

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.view.View
import android.widget.RemoteViews

class PowerHabitsGoalsWidgetProvider : AppWidgetProvider() {
    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            ACTION_INC_GOAL -> {
                val id = intent.getStringExtra(EXTRA_GOAL_ID).orEmpty()
                if (id.isNotEmpty()) {
                    WidgetStore.incrementGoal(context, id)
                }
            }
            ACTION_GOALS_PAGE -> {
                val delta = intent.getIntExtra(EXTRA_PAGE_DELTA, 1)
                val goals = WidgetStore.getGoalItems(context)
                val pages = ((goals.size + PAGE_SIZE - 1) / PAGE_SIZE).coerceAtLeast(1)
                WidgetStore.shiftGoalsPage(context, delta, pages)
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
        const val ACTION_INC_GOAL = "com.daltex.power_habits.WIDGET_INC_GOAL"
        const val ACTION_GOALS_PAGE = "com.daltex.power_habits.WIDGET_GOALS_PAGE"
        const val EXTRA_GOAL_ID = "goal_id"
        const val EXTRA_PAGE_DELTA = "page_delta"
        private const val PAGE_SIZE = 2

        fun updateAll(context: Context) {
            val mgr = AppWidgetManager.getInstance(context)
            val ids = mgr.getAppWidgetIds(
                ComponentName(context, PowerHabitsGoalsWidgetProvider::class.java)
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
            val goals = WidgetStore.getGoalItems(context)
            val totalPages = ((goals.size + PAGE_SIZE - 1) / PAGE_SIZE).coerceAtLeast(1)
            val page = WidgetStore.getGoalsPage(context).coerceIn(0, totalPages - 1)
            val pageGoals = goals.drop(page * PAGE_SIZE).take(PAGE_SIZE)

            val views = RemoteViews(context.packageName, R.layout.power_habits_goals_widget)
            views.setTextViewText(
                R.id.tv_goals_sub,
                if (goals.isEmpty()) "Sin metas activas" else "${goals.size} ${if (goals.size == 1) "meta activa" else "metas activas"}"
            )

            val openGoalsPending = PendingIntent.getActivity(
                context,
                4001,
                Intent(context, MainActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                    putExtra(WidgetStore.EXTRA_ROUTE, "/metas")
                },
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.area_open_goals, openGoalsPending)
            views.setOnClickPendingIntent(R.id.tv_goals_empty, openGoalsPending)

            val addGoalPending = PendingIntent.getActivity(
                context,
                4002,
                Intent(context, MainActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                    putExtra(WidgetStore.EXTRA_ROUTE, "/metas?new=1")
                },
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.btn_goals_add, addGoalPending)

            if (totalPages > 1) {
                views.setViewVisibility(R.id.btn_goals_prev, View.VISIBLE)
                views.setViewVisibility(R.id.btn_goals_next, View.VISIBLE)
                views.setOnClickPendingIntent(
                    R.id.btn_goals_prev,
                    PendingIntent.getBroadcast(
                        context,
                        4011,
                        Intent(context, PowerHabitsGoalsWidgetProvider::class.java).apply {
                            action = ACTION_GOALS_PAGE
                            putExtra(EXTRA_PAGE_DELTA, -1)
                        },
                        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                    )
                )
                views.setOnClickPendingIntent(
                    R.id.btn_goals_next,
                    PendingIntent.getBroadcast(
                        context,
                        4012,
                        Intent(context, PowerHabitsGoalsWidgetProvider::class.java).apply {
                            action = ACTION_GOALS_PAGE
                            putExtra(EXTRA_PAGE_DELTA, 1)
                        },
                        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                    )
                )
            } else {
                views.setViewVisibility(R.id.btn_goals_prev, View.GONE)
                views.setViewVisibility(R.id.btn_goals_next, View.GONE)
            }

            val cardIds = intArrayOf(R.id.goal_card_1, R.id.goal_card_2)
            val titleIds = intArrayOf(R.id.tv_goal_title_1, R.id.tv_goal_title_2)
            val countIds = intArrayOf(R.id.tv_goal_count_1, R.id.tv_goal_count_2)
            val pbIds = intArrayOf(R.id.pb_goal_1, R.id.pb_goal_2)
            val incIds = intArrayOf(R.id.btn_goal_inc_1, R.id.btn_goal_inc_2)

            if (pageGoals.isEmpty()) {
                views.setViewVisibility(R.id.tv_goals_empty, View.VISIBLE)
                for (cid in cardIds) views.setViewVisibility(cid, View.GONE)
            } else {
                views.setViewVisibility(R.id.tv_goals_empty, View.GONE)
                for (i in 0 until PAGE_SIZE) {
                    if (i < pageGoals.size) {
                        val g = pageGoals[i]
                        val pct = ((g.current * 100.0) / g.target).toInt().coerceIn(0, 100)
                        val done = g.current >= g.target
                        views.setViewVisibility(cardIds[i], View.VISIBLE)
                        views.setTextViewText(titleIds[i], g.title)
                        views.setTextViewText(countIds[i], "${g.current}/${g.target} ${g.unitLabel}")
                        views.setProgressBar(pbIds[i], 100, pct, false)
                        views.setTextViewText(incIds[i], if (done) "✓" else "+1")
                        views.setInt(
                            incIds[i],
                            "setBackgroundResource",
                            if (done) R.drawable.widget_pill_gray else R.drawable.widget_btn_neon_pill
                        )
                        views.setOnClickPendingIntent(cardIds[i], openGoalsPending)

                        val incPending = PendingIntent.getBroadcast(
                            context,
                            4100 + i,
                            Intent(context, PowerHabitsGoalsWidgetProvider::class.java).apply {
                                action = ACTION_INC_GOAL
                                putExtra(EXTRA_GOAL_ID, g.id)
                            },
                            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                        )
                        views.setOnClickPendingIntent(incIds[i], incPending)
                    } else {
                        views.setViewVisibility(cardIds[i], View.GONE)
                    }
                }
            }

            mgr.updateAppWidget(appWidgetId, views)
        }
    }
}
