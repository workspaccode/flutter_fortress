package com.example.flutter_fortress

import android.app.Activity
import android.os.Handler
import android.os.Looper
import android.view.WindowManager
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class FlutterFortressPlugin :
    FlutterPlugin,
    MethodCallHandler,
    ActivityAware {

    private lateinit var channel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private var eventSink: EventChannel.EventSink? = null
    private var activity: Activity? = null
    private var bindingContext: android.content.Context? = null
    private val handler = Handler(Looper.getMainLooper())
    private var expectedSignatureHash: String? = null

    // Background thread checking Frida
    private var threadRunning = false
    private val fridaCheckRunnable = object : Runnable {
        override fun run() {
            if (FridaDetector.isFridaDetected()) {
                sendThreatEvent("hooking", "Frida hooking agent detected.")
            }
            if (threadRunning) {
                handler.postDelayed(this, 3000)
            }
        }
    }

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        bindingContext = flutterPluginBinding.applicationContext
        
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "flutter_fortress")
        channel.setMethodCallHandler(this)

        eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "flutter_fortress_events")
        eventChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                eventSink = events
                threadRunning = true
                handler.post(fridaCheckRunnable)
            }

            override fun onCancel(arguments: Any?) {
                eventSink = null
                threadRunning = false
                handler.removeCallbacks(fridaCheckRunnable)
            }
        })
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "getPlatformVersion" -> {
                result.success("Android ${android.os.Build.VERSION.RELEASE}")
            }
            "checkDeviceIntegrity" -> {
                val context = bindingContext
                if (context != null) {
                    val status = mapOf(
                        "isRooted" to RootDetector.isDeviceRooted(),
                        "isEmulator" to EmulatorDetector.isRunningOnEmulator(),
                        "isTampered" to IntegrityChecker.isAppTampered(context, expectedSignatureHash)
                    )
                    result.success(status)
                } else {
                    result.error("CONTEXT_NULL", "Application context is null", null)
                }
            }
            "setExpectedSignatureHash" -> {
                expectedSignatureHash = call.argument<String>("hash")
                result.success(null)
            }
            "setScreenSecure" -> {
                val secure = call.argument<Boolean>("secure") ?: false
                setFlagSecure(secure)
                result.success(null)
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    private fun setFlagSecure(secure: Boolean) {
        val currentActivity = activity ?: return
        handler.post {
            if (secure) {
                currentActivity.window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
            } else {
                currentActivity.window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
            }
        }
    }

    private fun sendThreatEvent(type: String, message: String) {
        handler.post {
            eventSink?.success(mapOf(
                "type" to type,
                "message" to message,
                "details" to emptyMap<String, Any>()
            ))
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
        bindingContext = null
    }

    // ActivityAware implementation
    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivity() {
        activity = null
    }
}
