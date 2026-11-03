package com.github.tiltozavr2545.framebook

import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.android.FlutterSurfaceView

class MainActivity : FlutterActivity() {
    private var flutterSurface: FlutterSurfaceView? = null
    private var resumed = false
    private val needsSurfaceRelayout: Boolean
        get() = Build.VERSION.SDK_INT == 34 &&
            Build.MANUFACTURER.equals("samsung", ignoreCase = true)

    private val relayoutSurface = Runnable {
        if (resumed && hasWindowFocus()) {
            flutterSurface?.takeIf { it.isAttachedToWindow }?.requestLayout()
        }
    }

    override fun onFlutterSurfaceViewCreated(surfaceView: FlutterSurfaceView) {
        super.onFlutterSurfaceViewCreated(surfaceView)
        flutterSurface?.removeCallbacks(relayoutSurface)
        flutterSurface = surfaceView
        scheduleSurfaceRelayout()
    }

    override fun onResume() {
        super.onResume()
        resumed = true
        scheduleSurfaceRelayout()
    }

    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        if (hasFocus) scheduleSurfaceRelayout()
    }

    private fun scheduleSurfaceRelayout() {
        val surface = flutterSurface ?: return
        surface.removeCallbacks(relayoutSurface)
        if (needsSurfaceRelayout && resumed) {
            // Samsung Android 14 can lose the SurfaceView after a long pause.
            // Run after focus/visibility changes have settled, on the surface itself.
            // https://github.com/flutter/flutter/issues/139630#issuecomment-1858465706
            surface.postDelayed(relayoutSurface, 100L)
        }
    }

    override fun onPause() {
        resumed = false
        flutterSurface?.removeCallbacks(relayoutSurface)
        super.onPause()
    }

    override fun onDestroy() {
        flutterSurface?.removeCallbacks(relayoutSurface)
        flutterSurface = null
        super.onDestroy()
    }
}
