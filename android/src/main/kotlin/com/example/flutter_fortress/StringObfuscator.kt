package com.example.flutter_fortress

object StringObfuscator {
    private val KEY = byteArrayOf(0x5A, 0x7B.toByte(), 0x11, 0x9F.toByte())

    fun encrypt(text: String): ByteArray {
        val bytes = text.toByteArray(Charsets.UTF_8)
        val encrypted = ByteArray(bytes.size)
        for (i in bytes.indices) {
            encrypted[i] = (bytes[i].toInt() xor KEY[i % KEY.size].toInt()).toByte()
        }
        return encrypted
    }

    fun decrypt(encrypted: ByteArray): String {
        val decrypted = ByteArray(encrypted.size)
        for (i in encrypted.indices) {
            decrypted[i] = (encrypted[i].toInt() xor KEY[i % KEY.size].toInt()).toByte()
        }
        return String(decrypted, Charsets.UTF_8)
    }
}
