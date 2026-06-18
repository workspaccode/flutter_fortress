package com.example.flutter_fortress

import java.io.File

object RootDetector {

    // Common paths for SU binaries
    private val binaryPaths = arrayOf(
        "/system/app/Superuser.apk",
        "/sbin/su",
        "/system/bin/su",
        "/system/xbin/su",
        "/data/local/xbin/su",
        "/data/local/bin/su",
        "/system/sd/xbin/su",
        "/system/bin/failsafe/su",
        "/data/local/su",
        "/su/bin/su"
    )

    fun isDeviceRooted(): Boolean {
        return checkBuildTags() || checkSuBinaries() || checkSuperuserApk() || checkDirectoryPermissions()
    }

    private fun checkBuildTags(): Boolean {
        val buildTags = android.os.Build.TAGS
        return buildTags != null && buildTags.contains("test-keys")
    }

    private fun checkSuBinaries(): Boolean {
        for (path in binaryPaths) {
            if (File(path).exists()) return true
        }
        return false
    }

    private fun checkSuperuserApk(): Boolean {
        val rootPackages = arrayOf(
            "com.noshufou.android.su",
            "com.thirdparty.superuser",
            "eu.chainfire.supersu",
            "com.koushikdutta.superuser",
            "com.zachspong.temprootremovejb",
            "com.ramdroid.appquarantine",
            "com.topjohnwu.magisk"
        )
        // Check directory directly if packages cannot be scanned easily
        for (pkg in rootPackages) {
            val file = File("/data/data/$pkg")
            if (file.exists()) return true
        }
        return false
    }

    private fun checkDirectoryPermissions(): Boolean {
        // Check write permission in system directories
        try {
            val file = File("/system/test.txt")
            if (file.createNewFile()) {
                file.delete()
                return true
            }
        } catch (e: Exception) {
            // Write permission denied (normal state)
        }
        return false
    }
}
