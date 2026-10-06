package app.reparc.reparc

import io.flutter.embedding.android.FlutterFragmentActivity

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
}
