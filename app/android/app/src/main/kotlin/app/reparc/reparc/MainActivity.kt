package app.reparc.reparc

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.telephony.TelephonyManager
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import androidx.core.content.FileProvider
import androidx.health.connect.client.HealthConnectClient
import androidx.health.connect.client.aggregate.AggregateMetric
import androidx.health.connect.client.aggregate.AggregationResult
import androidx.health.connect.client.records.ActiveCaloriesBurnedRecord
import androidx.health.connect.client.records.DistanceRecord
import androidx.health.connect.client.records.StepsRecord
import androidx.health.connect.client.request.AggregateGroupByPeriodRequest
import androidx.health.connect.client.time.TimeRangeFilter
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.time.LocalDate
import java.time.Period
import kotlinx.coroutines.MainScope
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch

/**
 * FlutterFragmentActivity, because Health Connect's permission request uses
 * the activity result API (handbook 9, D-020).
 */
class MainActivity : FlutterFragmentActivity() {
    private val scope = MainScope()

    /** Waits for the answer to the "Physical activity" permission request. */
    private var activityResult: MethodChannel.Result? = null

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != ACTIVITY_REQUEST) return
        activityResult?.success(grantResults.firstOrNull() == PackageManager.PERMISSION_GRANTED)
        activityResult = null
    }

    override fun onDestroy() {
        scope.cancel()
        super.onDestroy()
    }

    /**
     * Health Connect opens Reparc to show why it asks for health data. Those
     * requests start on the privacy screen; everything else starts on Home.
     */
    override fun getInitialRoute(): String? = when (intent?.action) {
        "androidx.health.ACTION_SHOW_PERMISSIONS_RATIONALE",
        "android.intent.action.VIEW_PERMISSION_USAGE" -> "/me/privacy"
        else -> super.getInitialRoute()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Food country (handbook 5.10): the country of the mobile network,
        // else of the SIM. Many phones in India use "English (United
        // States)", so the language setting alone says US. These reads need
        // no permission and give no location.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "app.reparc/region")
            .setMethodCallHandler { call, result ->
                if (call.method != "country") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val tm = getSystemService(TELEPHONY_SERVICE) as? TelephonyManager
                val code = listOfNotNull(tm?.networkCountryIso, tm?.simCountryIso)
                    .map { it.trim().uppercase() }
                    .firstOrNull { it.length == 2 }
                result.success(code)
            }
        // Health totals per local day (handbook 9.5). Health Connect adds up
        // each day itself: it counts a moment once when the phone and a watch
        // both recorded it, splits a reading that crosses midnight, and
        // follows days of 23 or 25 hours. A day with no data is left out, so
        // the app shows "no data", never 0. Reads need the type's permission;
        // without it Health Connect throws and the app shows no data.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "app.reparc/health")
            .setMethodCallHandler { call, result ->
                // Live steps (handbook 9.5): the phone's step sensor needs the
                // "Physical activity" permission from Android 10. It is asked
                // for only when the user turns Live steps on.
                if (call.method == "requestActivity") {
                    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q ||
                        ContextCompat.checkSelfPermission(this, Manifest.permission.ACTIVITY_RECOGNITION) ==
                        PackageManager.PERMISSION_GRANTED
                    ) {
                        result.success(true)
                        return@setMethodCallHandler
                    }
                    activityResult?.success(false)
                    activityResult = result
                    ActivityCompat.requestPermissions(
                        this,
                        arrayOf(Manifest.permission.ACTIVITY_RECOGNITION),
                        ACTIVITY_REQUEST,
                    )
                    return@setMethodCallHandler
                }
                if (call.method != "dailyTotals") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val metric: Pair<AggregateMetric<*>, (AggregationResult) -> Double?> =
                    when (call.argument<String>("type")) {
                        "steps" -> StepsRecord.COUNT_TOTAL to { r -> r[StepsRecord.COUNT_TOTAL]?.toDouble() }
                        "activeEnergy" -> ActiveCaloriesBurnedRecord.ACTIVE_CALORIES_TOTAL to
                            { r -> r[ActiveCaloriesBurnedRecord.ACTIVE_CALORIES_TOTAL]?.inKilocalories }
                        "distance" -> DistanceRecord.DISTANCE_TOTAL to
                            { r -> r[DistanceRecord.DISTANCE_TOTAL]?.inMeters }
                        else -> {
                            result.error("bad_type", "Unknown health type.", null)
                            return@setMethodCallHandler
                        }
                    }
                val from: LocalDate
                val to: LocalDate
                try {
                    from = LocalDate.parse(call.argument<String>("from"))
                    to = LocalDate.parse(call.argument<String>("to"))
                } catch (e: Exception) {
                    result.error("bad_range", "Days must be yyyy-MM-dd.", null)
                    return@setMethodCallHandler
                }
                scope.launch {
                    try {
                        val client = HealthConnectClient.getOrCreate(this@MainActivity)
                        val rows = client.aggregateGroupByPeriod(
                            AggregateGroupByPeriodRequest(
                                metrics = setOf(metric.first),
                                timeRangeFilter = TimeRangeFilter.between(
                                    from.atStartOfDay(),
                                    to.plusDays(1).atStartOfDay(),
                                ),
                                timeRangeSlicer = Period.ofDays(1),
                            ),
                        )
                        val out = HashMap<String, Double>()
                        for (row in rows) {
                            val value = metric.second(row.result) ?: continue
                            out[row.startTime.toLocalDate().toString()] = value
                        }
                        result.success(out)
                    } catch (e: Exception) {
                        // Only the kind of failure: never health values.
                        result.error("health", e.javaClass.simpleName, null)
                    }
                }
            }
        // App updates (D-029, handbook 17.3): hands a downloaded, checked APK
        // to Android's package installer. The installer always asks the user;
        // Reparc never installs anything by itself. Google Play delivers the
        // Play build's updates, so that build has no installer (handbook 17.10).
        if (BuildConfig.PLAY_BUILD) return
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "app.reparc/installer")
            .setMethodCallHandler { call, result ->
                if (call.method != "install") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val path = call.argument<String>("path")
                val updates = File(cacheDir, "updates").canonicalPath
                val file = path?.let { File(it) }
                // Only files in the app's own update folder.
                if (file == null || !file.exists() || !file.canonicalPath.startsWith("$updates/")) {
                    result.error("bad_path", "The update file is missing. Download it again.", null)
                    return@setMethodCallHandler
                }
                try {
                    val uri = FileProvider.getUriForFile(this, "$packageName.updates", file)
                    val intent = Intent(Intent.ACTION_VIEW)
                        .setDataAndType(uri, "application/vnd.android.package-archive")
                        .addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_ACTIVITY_NEW_TASK)
                    startActivity(intent)
                    result.success(null)
                } catch (e: Exception) {
                    result.error("no_installer", "Android could not open the installer.", e.message)
                }
            }
    }
}

private const val ACTIVITY_REQUEST = 4101

/** Shares only the update folder with Android's installer. */
class UpdateFileProvider : FileProvider()
