package tech.invariant.invariant_sdk

import androidx.annotation.NonNull
import android.content.Context
import android.app.KeyguardManager
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
import java.security.InvalidAlgorithmParameterException

class InvariantSdkPlugin: FlutterPlugin, MethodCallHandler {
    private lateinit var channel : MethodChannel
    private lateinit var context: Context 
    private val KEY_ALIAS = "invariant_shadow_key"

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "com.invariant.protocol/keystore")
        channel.setMethodCallHandler(this)
        context = flutterPluginBinding.applicationContext
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        try {
            when (call.method) {
                "generateIdentity" -> {
                    // 1. Check if device is secure (Has PIN/Pattern/Bio)
                    if (!isDeviceSecure()) {
                        result.error(
                            "DEVICE_INSECURE", 
                            "Device must have a secure Lock Screen (PIN/Pattern) to generate hardware keys.", 
                            null
                        )
                        return
                    }

                    val nonceHex = call.argument<String>("nonce")!!
                    
                    // 2. Clean up old keys to ensure freshness
                    val keyStore = KeyStore.getInstance("AndroidKeyStore")
                    keyStore.load(null)
                    keyStore.deleteEntry(KEY_ALIAS)
                    
                    // 3. Generate
                    result.success(generateIdentity(nonceHex))
                }
                else -> result.notImplemented()
            }
        } catch (e: Exception) {
            // Handle specific Keystore errors
            if (e is InvalidAlgorithmParameterException) {
                result.error("KEYSTORE_CONFIG_ERROR", "Lock screen not set or hardware not supported: ${e.message}", null)
            } else {
                result.error("KEYSTORE_ERROR", e.message, null)
            }
        }
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    private fun isDeviceSecure(): Boolean {
        val keyguardManager = context.getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager
        return keyguardManager.isDeviceSecure
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
            
            // 👇 THIS IS THE FIX 👇
            // This tells the TEE: "Only allow this key to work if the user is authenticated"
            // The Rust server checks for this flag in the ASN.1 data.
            .setUserAuthenticationRequired(true)
            .setUserAuthenticationValidityDurationSeconds(60) // Valid for 60s after unlock/biometric
            
            .build()

        kpg.initialize(parameterSpec)
        kpg.generateKeyPair()

        val keyStore = KeyStore.getInstance("AndroidKeyStore")
        keyStore.load(null)
        val entry = keyStore.getEntry(KEY_ALIAS, null) as KeyStore.PrivateKeyEntry
        val certs = keyStore.getCertificateChain(KEY_ALIAS)

        // Convert certificates and public key to raw bytes for Dart
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