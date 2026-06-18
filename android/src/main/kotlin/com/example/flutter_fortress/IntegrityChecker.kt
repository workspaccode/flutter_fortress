package com.example.flutter_fortress

import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.util.Base64
import java.security.MessageDigest

object IntegrityChecker {

    fun isAppTampered(context: Context, expectedSignatureHash: String?): Boolean {
        if (expectedSignatureHash.isNullOrEmpty()) return false
        val currentHash = getAppSignatureHash(context)
        return expectedSignatureHash != currentHash
    }

    private fun getAppSignatureHash(context: Context): String {
        try {
            val packageName = context.packageName
            val signatures = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                val packageInfo = context.packageManager.getPackageInfo(
                    packageName,
                    PackageManager.GET_SIGNING_CERTIFICATES
                )
                packageInfo.signingInfo?.apkContentsSigners
            } else {
                val packageInfo = context.packageManager.getPackageInfo(
                    packageName,
                    PackageManager.GET_SIGNATURES
                )
                packageInfo.signatures
            }

            if (signatures != null && signatures.isNotEmpty()) {
                val sigBytes = signatures[0].toByteArray()
                val md = MessageDigest.getInstance("SHA-256")
                val digest = md.digest(sigBytes)
                return Base64.encodeToString(digest, Base64.NO_WRAP)
            }
        } catch (e: Exception) {
            // Package information error
        }
        return ""
    }
}
