package com.example.flutter_fortress

import java.io.BufferedReader
import java.io.File
import java.io.FileReader
import java.net.Socket

object FridaDetector {

    fun isFridaDetected(): Boolean {
        return checkFridaPort() || checkProcMaps()
    }

    private fun checkFridaPort(): Boolean {
        // Scans loopback ports usually used by Frida (27042, 27043)
        val ports = intArrayOf(27042, 27043)
        for (port in ports) {
            try {
                val socket = Socket("localhost", port)
                socket.close()
                return true
            } catch (e: Exception) {
                // Connection failed = port closed (normal)
            }
        }
        return false
    }

    private fun checkProcMaps(): Boolean {
        try {
            val reader = BufferedReader(FileReader("/proc/self/maps"))
            var line: String?
            while (reader.readLine().also { line = it } != null) {
                val currentLine = line ?: continue
                if (currentLine.contains("frida") || currentLine.contains("xposed")) {
                    reader.close()
                    return true
                }
            }
            reader.close()
        } catch (e: Exception) {
            // proc maps reading failed
        }
        return false
    }
}
