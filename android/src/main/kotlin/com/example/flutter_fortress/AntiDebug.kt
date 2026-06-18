package com.example.flutter_fortress

import java.io.BufferedReader
import java.io.File
import java.io.FileReader

object AntiDebug {

    fun isDebuggerAttached(): Boolean {
        return checkTracerPid() || checkDebugFlags()
    }

    private fun checkTracerPid(): Boolean {
        return try {
            val reader = BufferedReader(FileReader("/proc/self/status"))
            var line: String?
            while (reader.readLine().also { line = it } != null) {
                val currentLine = line ?: continue
                if (currentLine.startsWith("TracerPid:")) {
                    val pid = currentLine.substringAfter(":").trim().toIntOrNull() ?: 0
                    reader.close()
                    return pid != 0
                }
            }
            reader.close()
            false
        } catch (_: Exception) {
            false
        }
    }

    private fun checkDebugFlags(): Boolean {
        return try {
            val appFlags = File("/proc/self/status").readText()
            appFlags.contains("debug", ignoreCase = true) ||
            System.getProperty("java.class.path")?.contains("android.support.test") == true
        } catch (_: Exception) {
            false
        }
    }
}
