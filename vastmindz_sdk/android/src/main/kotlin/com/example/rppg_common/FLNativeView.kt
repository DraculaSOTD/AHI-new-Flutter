package com.example.rppg_common

import android.content.Context
import android.view.View
import android.widget.FrameLayout
import io.flutter.plugin.platform.PlatformView


internal class FLNativeView(context: Context, id: Int,creationParams: Map<String?, Any?>?) : PlatformView {
    private val view : View

    override fun getView(): View {
        return view
    }

    override fun dispose() {
        try {
            // CRITICAL FIX: Remove the camera view from its parent to allow reuse in next scan
            // Without this, the singleton camera view stays attached to the old parent,
            // causing "View already has parent" exception on the second scan
            val cameraView = Analysis.getInstance().rppgCameraView
            val parent = cameraView.parent as? android.view.ViewGroup

            if (parent != null) {
                parent.removeView(cameraView)
                android.util.Log.d("FLNativeView", "✅ Camera view removed from parent during dispose")

                // ENHANCED: Verify removal was successful
                if (cameraView.parent == null) {
                    android.util.Log.d("FLNativeView", "✅ VERIFIED: Camera view has no parent after removal")
                } else {
                    android.util.Log.e("FLNativeView", "❌ WARNING: Camera view still has parent after removal!")
                    android.util.Log.e("FLNativeView", "   Parent type: ${cameraView.parent?.javaClass?.simpleName}")
                }
            } else {
                android.util.Log.d("FLNativeView", "ℹ️ Camera view already detached (parent is null)")
            }
        } catch (e: Exception) {
            android.util.Log.e("FLNativeView", "❌ Error removing camera view from parent: ${e.message}", e)
        }
    }

    init {
        var frameLayout = FrameLayout(context)
        var lps = FrameLayout.LayoutParams(
            FrameLayout.LayoutParams.MATCH_PARENT,
            FrameLayout.LayoutParams.MATCH_PARENT)
        frameLayout.layoutParams = lps
        Analysis.getInstance().rppgCameraView.layoutParams = lps
        frameLayout.addView(Analysis.getInstance().rppgCameraView)
        view = frameLayout
    }
}
