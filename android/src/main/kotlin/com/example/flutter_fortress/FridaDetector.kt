package com.example.flutter_fortress

import java.io.BufferedReader
import java.io.File
import java.io.FileReader
import java.net.Socket

object FridaDetector {

    private val suspiciousPorts = intArrayOf(27042, 27043, 27044, 27045, 20242)

    fun isFridaDetected(): Boolean {
        return checkFridaPort() || checkProcMaps() || checkFridaProcesses() || checkLoadedLibraries()
    }

    private fun checkFridaPort(): Boolean {
        for (port in suspiciousPorts) {
            try {
                val socket = Socket("127.0.0.1", port)
                socket.close()
                return true
            } catch (_: Exception) {
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
                if (currentLine.contains("frida") ||
                    currentLine.contains("xposed") ||
                    currentLine.contains("gadget") ||
                    currentLine.contains("frida-agent")
                ) {
                    reader.close()
                    return true
                }
            }
            reader.close()
        } catch (_: Exception) {
        }
        return false
    }

    private fun checkFridaProcesses(): Boolean {
        return try {
            val processes = File("/proc").listFiles()
                ?.filter { it.name.matches(Regex("\\d+")) }
                ?: return false
            for (proc in processes) {
                try {
                    val cmdline = File(proc, "cmdline").readText()
                    if (cmdline.contains("frida", ignoreCase = true) ||
                        cmdline.contains("frida-server", ignoreCase = true)
                    ) return true
                } catch (_: Exception) {
                }
            }
            false
        } catch (_: Exception) {
            false
        }
    }

    private fun checkLoadedLibraries(): Boolean {
        return try {
            val env = System.getenv("LD_PRELOAD") ?: ""
            env.contains("frida", ignoreCase = true) || env.contains("gadget", ignoreCase = true)
        } catch (_: Exception) {
            false
        }
    }
}
