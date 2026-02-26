package com.example.taskflow_pro

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var shortcutChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        shortcutChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            SHORTCUT_CHANNEL,
        ).also { channel ->
            channel.setMethodCallHandler { call, result ->
                when (call.method) {
                    METHOD_GET_INITIAL_SHORTCUT -> {
                        val action = extractShortcutAction(intent)
                        intent?.removeExtra(EXTRA_TARGET_ACTION)
                        result.success(action)
                    }
                    else -> result.notImplemented()
                }
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        dispatchShortcutAction(intent)
    }

    private fun dispatchShortcutAction(launchIntent: Intent?) {
        val action = extractShortcutAction(launchIntent) ?: return
        shortcutChannel?.invokeMethod(METHOD_OPEN_SHORTCUT, mapOf("action" to action))
        launchIntent?.removeExtra(EXTRA_TARGET_ACTION)
    }

    private fun extractShortcutAction(launchIntent: Intent?): String? {
        val raw = launchIntent?.getStringExtra(EXTRA_TARGET_ACTION)?.lowercase() ?: return null
        return when (raw) {
            ACTION_ADD_TASK -> raw
            else -> null
        }
    }

    companion object {
        const val SHORTCUT_CHANNEL = "doora/shortcut_navigation"
        const val METHOD_GET_INITIAL_SHORTCUT = "getInitialShortcut"
        const val METHOD_OPEN_SHORTCUT = "openShortcut"
        const val EXTRA_TARGET_ACTION = "target_action"
        const val ACTION_ADD_TASK = "add_task"
    }
}
