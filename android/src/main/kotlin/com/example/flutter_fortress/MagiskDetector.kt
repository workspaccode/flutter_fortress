package com.example.flutter_fortress

import java.io.File

object MagiskDetector {

    fun isMagiskPresent(): Boolean {
        return checkMagiskFiles() || checkMagiskDaemon() || checkZygisk()
    }

    private fun checkMagiskFiles(): Boolean {
        val paths = arrayOf(
            "/sbin/magisk",
            "/system/bin/magisk",
            "/data/adb/magisk",
            "/data/adb/modules",
            "/data/adb/modules/hide",
        )
        return paths.any { File(it).exists() }
    }

    private fun checkMagiskDaemon(): Boolean {
        return try {
            File("/proc/self/maps").readText().contains("magisk", ignoreCase = true)
        } catch (_: Exception) {
            false
        }
    }

    private fun checkZygisk(): Boolean {
        return try {
            val maps = File("/proc/self/maps").readText()
            maps.contains("zygisk", ignoreCase = true) || maps.contains("zygote", ignoreCase = true)
        } catch (_: Exception) {
            false
        }
    }
}
