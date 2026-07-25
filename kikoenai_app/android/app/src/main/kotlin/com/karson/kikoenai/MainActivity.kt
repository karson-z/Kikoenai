package com.karson.kikoenai

import android.graphics.Color
import android.os.Bundle // 确保导入 Bundle
import androidx.core.view.WindowCompat // 核心库
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : AudioServiceActivity() {

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
    }
}