package com.example.flutter_fortress

import android.content.Context
import com.google.android.play.core.integrity.IntegrityManagerFactory
import com.google.android.play.core.integrity.IntegrityTokenRequest
import com.google.android.play.core.integrity.model.IntegrityErrorCode
import java.security.SecureRandom

object PlayIntegrityChecker {

    private const val CLOUD_PROJECT_NUMBER = 0L

    fun requestIntegrityToken(
        context: Context,
        cloudProjectNumber: Long = CLOUD_PROJECT_NUMBER,
        onResult: (Boolean, String?) -> Unit,
    ) {
        if (cloudProjectNumber == 0L) {
            onResult(false, "Cloud project number not configured")
            return
        }
        try {
            val integrityManager = IntegrityManagerFactory.create(context)
            val nonce = generateNonce()
            val request = IntegrityTokenRequest.builder()
                .setNonce(nonce)
                .setCloudProjectNumber(cloudProjectNumber)
                .build()
            integrityManager.requestIntegrityToken(request)
                .addOnSuccessListener { response ->
                    val token = response.token()
                    onResult(token.isNotEmpty(), token)
                }
                .addOnFailureListener { exception ->
                    val errorMsg = when (IntegrityErrorCode.getErrorCode(exception)) {
                        IntegrityErrorCode.INTEGRITY_EXTERNAL_ERROR -> "External error"
                        IntegrityErrorCode.INTEGRITY_INTERNAL_ERROR -> "Internal error"
                        IntegrityErrorCode.INTEGRITY_NETWORK_ERROR -> "Network error"
                        IntegrityErrorCode.INTEGRITY_SERVICE_UNAVAILABLE -> "Service unavailable"
                        IntegrityErrorCode.APP_NOT_INSTALLED -> "App not installed"
                        IntegrityErrorCode.APP_VERSION_TOO_OLD -> "App version too old"
                        IntegrityErrorCode.APP_TOO_NEW -> "App too new"
                        IntegrityErrorCode.BAD_CLIENT_ID -> "Bad client ID"
                        IntegrityErrorCode.CANNOT_BIND_TO_SERVICE -> "Cannot bind to service"
                        IntegrityErrorCode.GOOGLE_SERVER_UNAVAILABLE -> "Google server unavailable"
                        IntegrityErrorCode.NO_ERROR -> "No error"
                        IntegrityErrorCode.PLAY_SERVICES_NOT_FOUND -> "Play Services not found"
                        IntegrityErrorCode.PLAY_SERVICES_TOO_OLD -> "Play Services too old"
                        IntegrityErrorCode.PLAY_SERVICES_VERSION_TOO_OLD -> "Play Services version too old"
                        IntegrityErrorCode.TOO_MANY_REQUESTS -> "Too many requests"
                        IntegrityErrorCode.API_NOT_AVAILABLE -> "API not available"
                        else -> "Unknown error"
                    }
                    onResult(false, errorMsg)
                }
        } catch (e: Exception) {
            onResult(false, e.message ?: "Integrity check failed")
        }
    }

    private fun generateNonce(): String {
        val nonce = ByteArray(32)
        SecureRandom().nextBytes(nonce)
        return nonce.joinToString("") { byte ->
            String.format("%02x", byte)
        }
    }
}
