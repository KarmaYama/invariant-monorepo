package com.example.native_keystore

import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import java.security.KeyPairGenerator
import java.security.KeyStore
import java.security.spec.ECGenParameterSpec
import java.security.Signature

class NativeKeystorePlugin: FlutterPlugin, MethodCallHandler {
    private lateinit var channel : MethodChannel
    private val KEY_ALIAS = "invariant_identity_key"

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "com.invariant.protocol/keystore")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        try {
            when (call.method) {
                // 🔍 RECOVERY: Check if device already has a key
                "hasIdentity" -> {
                    val keyStore = KeyStore.getInstance("AndroidKeyStore")
                    keyStore.load(null)
                    result.success(keyStore.containsAlias(KEY_ALIAS))
                }
                // 🔍 RECOVERY: Get public key/chain without deleting private key
                "recoverIdentity" -> {
                    val identity = getExistingIdentity()
                    if (identity != null) {
                        result.success(identity)
                    } else {
                        result.error("NO_IDENTITY", "No identity found to recover", null)
                    }
                }
                "generateIdentity" -> {
                    val nonceHex = call.argument<String>("nonce")!!
                    // ⚠️ DESTRUCTIVE: Only used if hasIdentity is false
                    val keyStore = KeyStore.getInstance("AndroidKeyStore")
                    keyStore.load(null)
                    if (keyStore.containsAlias(KEY_ALIAS)) {
                        keyStore.deleteEntry(KEY_ALIAS)
                    }
                    result.success(generateIdentity(nonceHex))
                }
                "signHeartbeat" -> {
                    val payload = call.argument<String>("payload")!!
                    result.success(signData(payload))
                }
                else -> result.notImplemented()
            }
        } catch (e: Exception) {
            result.error("KEYSTORE_ERROR", e.message, null)
        }
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    // --- CRYPTO LOGIC ---

    private fun getExistingIdentity(): Map<String, Any>? {
        val keyStore = KeyStore.getInstance("AndroidKeyStore")
        keyStore.load(null)
        
        if (!keyStore.containsAlias(KEY_ALIAS)) return null

        val entry = keyStore.getEntry(KEY_ALIAS, null) as? KeyStore.PrivateKeyEntry ?: return null
        val certs = keyStore.getCertificateChain(KEY_ALIAS) ?: return null

        val chainList = certs.map { cert -> cert.encoded.map { it.toInt() and 0xFF }.toList() }
        val publicKeyBytes = entry.certificate.publicKey.encoded.map { it.toInt() and 0xFF }.toList()

        return mapOf("publicKey" to publicKeyBytes, "attestationChain" to chainList)
    }

    private fun generateIdentity(nonceHex: String): Map<String, Any> {
        val challengeBytes = hexStringToByteArray(nonceHex)
        val kpg = KeyPairGenerator.getInstance(KeyProperties.KEY_ALGORITHM_EC, "AndroidKeyStore")
        val parameterSpec = KeyGenParameterSpec.Builder(
            KEY_ALIAS,
            KeyProperties.PURPOSE_SIGN or KeyProperties.PURPOSE_VERIFY
        )
            .setDigests(KeyProperties.DIGEST_SHA256)
            .setAlgorithmParameterSpec(ECGenParameterSpec("secp256r1"))
            .setAttestationChallenge(challengeBytes)
            .build()

        kpg.initialize(parameterSpec)
        kpg.generateKeyPair()

        return getExistingIdentity()!!
    }

    private fun signData(data: String): List<Int> {
        val keyStore = KeyStore.getInstance("AndroidKeyStore")
        keyStore.load(null)
        val entry = keyStore.getEntry(KEY_ALIAS, null) as KeyStore.PrivateKeyEntry
        val s = Signature.getInstance("SHA256withECDSA")
        s.initSign(entry.privateKey)
        s.update(data.toByteArray(Charsets.UTF_8))
        return s.sign().map { it.toInt() and 0xFF }.toList()
    }

    private fun hexStringToByteArray(s: String): ByteArray {
        val len = s.length
        val data = ByteArray(len / 2)
        var i = 0
        while (i < len) {
            data[i / 2] = ((Character.digit(s[i], 16) shl 4) + Character.digit(s[i + 1], 16)).toByte()
            i += 2
        }
        return data
    }
}