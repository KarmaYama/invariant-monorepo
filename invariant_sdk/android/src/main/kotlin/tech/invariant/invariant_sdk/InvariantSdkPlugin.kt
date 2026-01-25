package tech.invariant.invariant_sdk

import androidx.annotation.NonNull
import android.content.Context
import android.app.KeyguardManager
import android.os.Build // Required for Build.MODEL
import android.util.Log
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
    private val TAG = "InvariantHardware"

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "com.invariant.protocol/keystore")
        channel.setMethodCallHandler(this)
        context = flutterPluginBinding.applicationContext
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        try {
            when (call.method) {
                "generateIdentity" -> {
                    if (!isDeviceSecure()) {
                        result.error("DEVICE_INSECURE", "Lock screen required.", null)
                        return
                    }

                    val nonceHex = call.argument<String>("nonce")!!
                    
                    // Clean up old keys
                    val keyStore = KeyStore.getInstance("AndroidKeyStore")
                    keyStore.load(null)
                    if (keyStore.containsAlias(KEY_ALIAS)) {
                        keyStore.deleteEntry(KEY_ALIAS)
                    }
                    
                    // Generate with Fallback
                    val keyMap = generateWithFallback(nonceHex)
                    result.success(keyMap)
                }
                else -> result.notImplemented()
            }
        } catch (e: Exception) {
            val errorMsg = if (e is InvalidAlgorithmParameterException) {
                "Hardware not supported or Lock Screen missing: ${e.message}"
            } else {
                e.message
            }
            result.error("KEYSTORE_ERROR", errorMsg, null)
        }
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    private fun isDeviceSecure(): Boolean {
        val keyguardManager = context.getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager
        return keyguardManager.isDeviceSecure
    }

    private fun generateWithFallback(nonceHex: String): Map<String, Any> {
        return try {
            // Attempt 1: Try Rich Attestation (Hardware verifies Brand/Model)
            // This crashes on Samsung A16
            generateKeyPair(nonceHex, includeDeviceProps = true)
        } catch (e: Exception) {
            Log.w(TAG, "⚠️ Rich Attestation Failed. Falling back to Standard TEE. Error: ${e.message}")
            // Attempt 2: Standard Attestation (Hardware verifies Security only)
            generateKeyPair(nonceHex, includeDeviceProps = false)
        }
    }

    private fun generateKeyPair(nonceHex: String, includeDeviceProps: Boolean): Map<String, Any> {
        val challengeBytes = hexStringToByteArray(nonceHex)
        val kpg = KeyPairGenerator.getInstance(KeyProperties.KEY_ALGORITHM_EC, "AndroidKeyStore")
        
        val builder = KeyGenParameterSpec.Builder(
            KEY_ALIAS,
            KeyProperties.PURPOSE_SIGN or KeyProperties.PURPOSE_VERIFY
        )
            .setDigests(KeyProperties.DIGEST_SHA256)
            .setAlgorithmParameterSpec(ECGenParameterSpec("secp256r1"))
            .setAttestationChallenge(challengeBytes)
            .setUserAuthenticationRequired(true)
            .setUserAuthenticationValidityDurationSeconds(60)

        // Only add this flag if requested AND supported
        if (includeDeviceProps && Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            builder.setDevicePropertiesAttestationIncluded(true)
        }

        kpg.initialize(builder.build())
        kpg.generateKeyPair()

        val keyStore = KeyStore.getInstance("AndroidKeyStore")
        keyStore.load(null)
        val entry = keyStore.getEntry(KEY_ALIAS, null) as KeyStore.PrivateKeyEntry
        val certs = keyStore.getCertificateChain(KEY_ALIAS)

        val chainList = certs.map { cert -> cert.encoded.map { it.toInt() and 0xFF }.toList() }
        val publicKeyBytes = entry.certificate.publicKey.encoded.map { it.toInt() and 0xFF }.toList()

        // 🚀 NEW: Always return the Software Metadata as a backup
        // This ensures the UI is never empty, even if the TEE is silent.
        return mapOf(
            "publicKey" to publicKeyBytes, 
            "attestationChain" to chainList,
            "softwareBrand" to (Build.MANUFACTURER ?: "Generic"),
            "softwareModel" to (Build.MODEL ?: "Android Device"),
            "softwareProduct" to (Build.PRODUCT ?: "unknown")
        )
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