package com.karson.kikoenai

import android.app.NotificationManager
import android.graphics.Color
import android.media.AudioManager
import android.os.Build
import android.os.Bundle
import androidx.core.view.WindowCompat
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : AudioServiceActivity() {

    companion object {
        // audio_service 原生层内部使用的媒体通知 ID（AudioService.java:
        // private static final int NOTIFICATION_ID = 1124）与渠道 ID。
        private const val MEDIA_NOTIFICATION_ID = 1124
        private const val MEDIA_CHANNEL_ID = "com.karson.kikoenai.audio"
        private const val DIAGNOSTICS_CHANNEL = "kikoenai/media_center_diagnostics"
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // 1. 告诉 Window 内容应该延伸到系统栏（状态栏/导航栏）后面
        // false 表示不由系统负责适应系统栏，由应用自己处理布局
        WindowCompat.setDecorFitsSystemWindows(window, false)

        // 2. 将状态栏颜色设置为完全透明
        window.statusBarColor = Color.TRANSPARENT
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // 媒体中心注册诊断探针：
        // 媒体通知被投递 ⇔ 原生层已执行 startForeground（即注册成功）。
        // 应用读取自己的活动通知不需要额外权限。
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            DIAGNOSTICS_CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "probeMediaNotification" -> {
                    try {
                        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
                            result.error("UNSUPPORTED", "requires API 23+", null)
                            return@setMethodCallHandler
                        }
                        val notificationManager = getSystemService(NotificationManager::class.java)
                        val mediaNotification = notificationManager?.activeNotifications?.firstOrNull { sbn ->
                            channelIdOf(sbn.notification) == MEDIA_CHANNEL_ID || sbn.id == MEDIA_NOTIFICATION_ID
                        }
                        val audioManager = getSystemService(AudioManager::class.java)
                        val response = mapOf(
                            "notificationPosted" to (mediaNotification != null),
                            "notificationId" to mediaNotification?.id,
                            "channel" to channelIdOf(mediaNotification?.notification),
                            "ongoing" to mediaNotification?.isOngoing,
                            "postTime" to mediaNotification?.postTime,
                            "musicActive" to audioManager?.isMusicActive
                        )
                        result.success(response)
                    } catch (e: Exception) {
                        result.error("PROBE_FAILED", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    // 通知渠道 ID 仅存在于 API 26+，低版本直接返回 null 避免 NoSuchMethodError。
    private fun channelIdOf(notification: android.app.Notification?): String? {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O || notification == null) return null
        return notification.channelId
    }
}
