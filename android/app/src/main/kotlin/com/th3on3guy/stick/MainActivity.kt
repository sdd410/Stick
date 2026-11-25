package com.th3on3guy.stick

import android.graphics.Region
import android.graphics.drawable.AdaptiveIconDrawable
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlin.math.PI
import kotlin.math.cos
import kotlin.math.sin

class MainActivity : FlutterActivity() {
    // Before Android 12 there is no system splash to wait for.
    private var splashGone = Build.VERSION.SDK_INT < Build.VERSION_CODES.S
    private var channel: MethodChannel? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Android 12+: drop the system splash without its fade (the app's
        // first frame is the same logo), then tell the app so its logo intro
        // starts now instead of playing hidden under the splash.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            splashScreen.setOnExitAnimationListener { view ->
                view.remove()
                splashGone = true
                channel?.invokeMethod("splashGone", null)
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        channel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "stick/splash",
        ).also {
            it.setMethodCallHandler { call, result ->
                when (call.method) {
                    "isGone" -> result.success(splashGone)
                    "iconShape" -> result.success(iconShape())
                    else -> result.notImplemented()
                }
            }
        }
    }

    /**
     * The phone's icon mask (circle on Pixel, rounded square on Samsung...)
     * as the centre-to-edge distance at 72 even angles, clockwise from
     * 3 o'clock, as a fraction of half the icon size. Null if unknown.
     */
    private fun iconShape(): List<Double>? {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return null
        return try {
            val icon = getDrawable(R.mipmap.ic_launcher) as? AdaptiveIconDrawable
                ?: return null
            val size = 1000
            icon.setBounds(0, 0, size, size)
            val region = Region()
            region.setPath(icon.iconMask, Region(0, 0, size, size))
            val half = size / 2.0
            (0 until 72).map { i ->
                val a = 2 * PI * i / 72
                var inside = 0.0
                var outside = half * 1.5
                repeat(24) {
                    val m = (inside + outside) / 2
                    val x = (half + cos(a) * m).toInt()
                    val y = (half + sin(a) * m).toInt()
                    if (region.contains(x, y)) inside = m else outside = m
                }
                inside / half
            }
        } catch (e: Exception) {
            null
        }
    }
}
