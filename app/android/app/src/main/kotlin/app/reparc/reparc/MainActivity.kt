package app.reparc.reparc

import android.content.Intent
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

/**
 * FlutterFragmentActivity, because Health Connect's permission request uses
 * the activity result API (handbook 9, D-020).
 */
class MainActivity : FlutterFragmentActivity() {
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

/** Shares only the update folder with Android's installer. */
class UpdateFileProvider : FileProvider()
