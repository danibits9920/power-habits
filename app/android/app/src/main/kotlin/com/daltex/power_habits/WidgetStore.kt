package com.daltex.power_habits

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

data class WidgetRoutineItem(
    val id: String,
    val title: String,
    val contextType: String, // "personal" | "work"
    val completed: Boolean
)

data class WidgetGoalItem(
    val id: String,
    val title: String,
    val contextType: String,
    val unitLabel: String,
    val current: Int,
    val target: Int
)

object WidgetStore {
    const val PREFS = "power_habits_widget"
    const val EXTRA_ROUTE = "widget_route"

    private const val KEY_TODAY_DATE = "today_date"
    private const val KEY_TODAY_ITEMS = "today_items"
    private const val KEY_GOALS_ITEMS = "goals_items"
    private const val KEY_HOY_FILTER = "hoy_filter" // all | personal | work
    private const val KEY_HOY_PAGE = "hoy_page"
    private const val KEY_GOALS_PAGE = "goals_page"
    private const val KEY_PENDING_ACTIONS = "pending_actions"

    private val lock = Any()

    fun todayDateStr(): String =
        SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date())

    fun getTodayDate(context: Context): String {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        return prefs.getString(KEY_TODAY_DATE, null)?.takeIf { it.isNotBlank() }
            ?: todayDateStr()
    }

    fun getHoyFilter(context: Context): String {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        return prefs.getString(KEY_HOY_FILTER, "all") ?: "all"
    }

    fun cycleHoyFilter(context: Context): String {
        val next = when (getHoyFilter(context)) {
            "all" -> "personal"
            "personal" -> "work"
            else -> "all"
        }
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .edit()
            .putString(KEY_HOY_FILTER, next)
            .putInt(KEY_HOY_PAGE, 0)
            .apply()
        return next
    }

    fun getHoyPage(context: Context): Int =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .getInt(KEY_HOY_PAGE, 0).coerceAtLeast(0)

    fun shiftHoyPage(context: Context, delta: Int, totalPages: Int) {
        if (totalPages <= 1) return
        val cur = getHoyPage(context)
        val next = (cur + delta + totalPages) % totalPages
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .edit()
            .putInt(KEY_HOY_PAGE, next)
            .apply()
    }

    fun getGoalsPage(context: Context): Int =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .getInt(KEY_GOALS_PAGE, 0).coerceAtLeast(0)

    fun shiftGoalsPage(context: Context, delta: Int, totalPages: Int) {
        if (totalPages <= 1) return
        val cur = getGoalsPage(context)
        val next = (cur + delta + totalPages) % totalPages
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .edit()
            .putInt(KEY_GOALS_PAGE, next)
            .apply()
    }

    fun getTodayItems(context: Context): List<WidgetRoutineItem> {
        val raw = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .getString(KEY_TODAY_ITEMS, "[]") ?: "[]"
        val out = mutableListOf<WidgetRoutineItem>()
        try {
            val arr = JSONArray(raw)
            for (i in 0 until arr.length()) {
                val obj = arr.optJSONObject(i) ?: continue
                val id = obj.optString("id").trim()
                val title = obj.optString("title").trim()
                if (id.isEmpty() || title.isEmpty()) continue
                out.add(
                    WidgetRoutineItem(
                        id = id,
                        title = title,
                        contextType = obj.optString("context", "personal"),
                        completed = obj.optBoolean("completed", false)
                    )
                )
            }
        } catch (_: Exception) {
            // Ignorar JSON corrupto previo.
        }
        return out
    }

    fun getGoalItems(context: Context): List<WidgetGoalItem> {
        val raw = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .getString(KEY_GOALS_ITEMS, "[]") ?: "[]"
        val out = mutableListOf<WidgetGoalItem>()
        try {
            val arr = JSONArray(raw)
            for (i in 0 until arr.length()) {
                val obj = arr.optJSONObject(i) ?: continue
                val id = obj.optString("id").trim()
                val title = obj.optString("title").trim()
                if (id.isEmpty() || title.isEmpty()) continue
                out.add(
                    WidgetGoalItem(
                        id = id,
                        title = title,
                        contextType = obj.optString("context", "personal"),
                        unitLabel = obj.optString("unitLabel", "pasos"),
                        current = obj.optInt("current", 0),
                        target = obj.optInt("target", 1).coerceAtLeast(1)
                    )
                )
            }
        } catch (_: Exception) {
            // Ignorar JSON corrupto previo.
        }
        return out
    }

    fun saveSnapshot(
        context: Context,
        dateKey: String,
        todayItemsJson: String,
        goalsItemsJson: String
    ) {
        synchronized(lock) {
            val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            prefs.edit()
                .putString(KEY_TODAY_DATE, dateKey)
                .putString(KEY_TODAY_ITEMS, todayItemsJson)
                .putString(KEY_GOALS_ITEMS, goalsItemsJson)
                .apply()
        }
        updateAllWidgets(context)
    }

    fun toggleRoutine(context: Context, routineId: String): Boolean {
        if (routineId.isBlank()) return false
        var changed = false
        synchronized(lock) {
            val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            val dateKey = getTodayDate(context)
            val items = getTodayItems(context)
            val updated = JSONArray()
            var nextCompleted = true
            for (item in items) {
                val isTarget = item.id == routineId
                val done = if (isTarget) !item.completed else item.completed
                if (isTarget) {
                    changed = true
                    nextCompleted = done
                }
                updated.put(
                    JSONObject()
                        .put("id", item.id)
                        .put("title", item.title)
                        .put("context", item.contextType)
                        .put("completed", done)
                )
            }
            if (changed) {
                val queue = readPendingArray(prefs)
                queue.put(
                    JSONObject()
                        .put("type", "toggle_routine")
                        .put("id", routineId)
                        .put("dateKey", dateKey)
                        .put("completed", nextCompleted)
                        .put("ts", System.currentTimeMillis())
                )
                prefs.edit()
                    .putString(KEY_TODAY_ITEMS, updated.toString())
                    .putString(KEY_PENDING_ACTIONS, queue.toString())
                    .apply()
            }
        }
        if (changed) {
            updateAllWidgets(context)
            MainActivity.notifyPendingActions()
        }
        return changed
    }

    fun incrementGoal(context: Context, goalId: String): Boolean {
        if (goalId.isBlank()) return false
        var changed = false
        synchronized(lock) {
            val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            val goals = getGoalItems(context)
            val updated = JSONArray()
            for (g in goals) {
                val isTarget = g.id == goalId && g.current < g.target
                val nextVal = if (isTarget) g.current + 1 else g.current
                if (isTarget) changed = true
                updated.put(
                    JSONObject()
                        .put("id", g.id)
                        .put("title", g.title)
                        .put("context", g.contextType)
                        .put("unitLabel", g.unitLabel)
                        .put("current", nextVal)
                        .put("target", g.target)
                )
            }
            if (changed) {
                val queue = readPendingArray(prefs)
                queue.put(
                    JSONObject()
                        .put("type", "inc_goal")
                        .put("id", goalId)
                        .put("delta", 1)
                        .put("ts", System.currentTimeMillis())
                )
                prefs.edit()
                    .putString(KEY_GOALS_ITEMS, updated.toString())
                    .putString(KEY_PENDING_ACTIONS, queue.toString())
                    .apply()
            }
        }
        if (changed) {
            updateAllWidgets(context)
            MainActivity.notifyPendingActions()
        }
        return changed
    }

    fun consumePendingActionsJson(context: Context): String {
        synchronized(lock) {
            val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            val raw = prefs.getString(KEY_PENDING_ACTIONS, "[]") ?: "[]"
            if (raw != "[]") {
                prefs.edit().putString(KEY_PENDING_ACTIONS, "[]").apply()
            }
            return raw
        }
    }

    fun updateAllWidgets(context: Context) {
        PowerHabitsWidgetProvider.updateAll(context)
        PowerHabitsGoalsWidgetProvider.updateAll(context)
        PowerHabitsMiniWidgetProvider.updateAll(context)
    }

    private fun readPendingArray(prefs: android.content.SharedPreferences): JSONArray {
        val raw = prefs.getString(KEY_PENDING_ACTIONS, "[]") ?: "[]"
        return try {
            JSONArray(raw)
        } catch (_: Exception) {
            JSONArray()
        }
    }
}
