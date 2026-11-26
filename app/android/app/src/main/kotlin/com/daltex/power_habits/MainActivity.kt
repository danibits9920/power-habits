package com.daltex.power_habits

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray
import java.io.File

class MainActivity : FlutterActivity() {
    private val widgetChannelName = "com.daltex.power_habits/widget"
    private val updaterChannelName = "com.daltex.power_habits/updater"
    private var widgetChannel: MethodChannel? = null
    private var pendingRoute: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        pendingRoute = intent?.getStringExtra(PowerHabitsWidgetProvider.EXTRA_ROUTE)
        intent?.removeExtra(PowerHabitsWidgetProvider.EXTRA_ROUTE)

        val wch = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, widgetChannelName)
        widgetChannel = wch
        wch.setMethodCallHandler { call, result ->
            when (call.method) {
                "update" -> {
                    val pct = (call.argument<Int>("pct") ?: 0).coerceIn(0, 100)
                    val doneCount = call.argument<Int>("doneCount") ?: 0
                    val totalCount = call.argument<Int>("totalCount") ?: 0
                    val titles = call.argument<List<*>>("pendingTitles")
                        ?.mapNotNull { it?.toString()?.trim() }
                        ?.filter { it.isNotEmpty() }
                        ?.take(3)
                        ?: emptyList()
                    val titlesJson = JSONArray().apply {
                        titles.forEach { put(it) }
                    }.toString()

                    getSharedPreferences(PowerHabitsWidgetProvider.PREFS, Context.MODE_PRIVATE)
                        .edit()
                        .putInt("pct", pct)
                        .putInt("doneCount", doneCount)
                        .putInt("totalCount", totalCount)
                        .putString("pendingTitles", titlesJson)
                        .apply()
                    PowerHabitsWidgetProvider.updateAll(this)
                    result.success(true)
                }
                "initialRoute" -> {
                    val route = pendingRoute
                    pendingRoute = null
                    result.success(route)
                }
                else -> result.notImplemented()
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, updaterChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "canInstall" -> {
                        val can = Build.VERSION.SDK_INT < Build.VERSION_CODES.O ||
                            packageManager.canRequestPackageInstalls()
                        result.success(can)
                    }
                    "installApk" -> {
                        val path = call.argument<String>("path")
                        if (path.isNullOrBlank()) {
                            result.error("INVALID_PATH", "Ruta de APK vacía", null)
                            return@setMethodCallHandler
                        }
                        val file = File(path)
                        if (!file.exists()) {
                            result.error("MISSING_FILE", "No se encontró el APK descargado", null)
                            return@setMethodCallHandler
                        }
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O &&
                            !packageManager.canRequestPackageInstalls()
                        ) {
                            val permIntent = Intent(
                                Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES,
                                Uri.parse("package:$packageName")
                            ).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            startActivity(permIntent)
                            result.success("NEEDS_PERMISSION")
                            return@setMethodCallHandler
                        }
                        val uri = FileProvider.getUriForFile(
                            this,
                            "$packageName.fileprovider",
                            file
                        )
                        val installIntent = Intent(Intent.ACTION_VIEW).apply {
                            setDataAndType(uri, "application/vnd.android.package-archive")
                            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        }
                        startActivity(installIntent)
                        result.success("LAUNCHED")
                    }
                    else -> result.notImplemented()
                }
            }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        val route = intent.getStringExtra(PowerHabitsWidgetProvider.EXTRA_ROUTE)
        if (!route.isNullOrBlank()) {
            intent.removeExtra(PowerHabitsWidgetProvider.EXTRA_ROUTE)
            widgetChannel?.invokeMethod("navigate", route)
        }
    }
}
