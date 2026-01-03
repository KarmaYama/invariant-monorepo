package tech.invariant.invariant_sdk

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

class InvariantSdkPlugin: FlutterPlugin, MethodCallHandler {
    private lateinit var channel : MethodChannel
    private val KEY_ALIAS = "invariant_shadow_key" // Changed alias to avoid conflict with main app

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        // MATCHES THE CHANNEL IN DART
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "com.invariant.protocol/keystore")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        try {
            when (call.method) {
                "generateIdentity" -> {
                    val nonceHex = call.argument<String>("nonce")!!
                    // Clean up old keys for fresh start
                    val keyStore = KeyStore.getInstance("AndroidKeyStore")
                    keyStore.load(null)
                    // We delete entry to ensure every verification is fresh
                    keyStore.deleteEntry(KEY_ALIAS)
                    result.success(generateIdentity(nonceHex))
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

    // --- CRYPTO LOGIC (Identical to your App) ---

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

        val keyStore = KeyStore.getInstance("AndroidKeyStore")
        keyStore.load(null)
        val entry = keyStore.getEntry(KEY_ALIAS, null) as KeyStore.PrivateKeyEntry
        val certs = keyStore.getCertificateChain(KEY_ALIAS)

        val chainList = certs.map { cert -> cert.encoded.map { it.toInt() and 0xFF }.toList() }
        val publicKeyBytes = entry.certificate.publicKey.encoded.map { it.toInt() and 0xFF }.toList()

        return mapOf("publicKey" to publicKeyBytes, "attestationChain" to chainList)
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