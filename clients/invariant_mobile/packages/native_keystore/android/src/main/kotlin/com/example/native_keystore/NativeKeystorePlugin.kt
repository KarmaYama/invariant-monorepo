// clients/invariant_mobile/packages/native_keystore/android/src/main/kotlin/com/example/native_keystore/NativeKeystorePlugin.kt
package com.example.native_keystore

import androidx.annotation.NonNull
import android.app.Activity
import android.content.Context
import androidx.fragment.app.FragmentActivity
import androidx.biometric.BiometricManager
import androidx.biometric.BiometricPrompt
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import java.security.KeyPairGenerator
import java.security.KeyStore
import java.security.Signature
import java.security.spec.ECGenParameterSpec
import java.util.ArrayList
import java.util.concurrent.Executor

class NativeKeystorePlugin: FlutterPlugin, MethodCallHandler, ActivityAware {
    private lateinit var channel : MethodChannel
    private val KEY_ALIAS = "invariant_identity_key"
    
    // Activity Awareness (Required for Biometric Prompt)
    private var activity: Activity? = null
    private var context: Context? = null

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "com.invariant.protocol/keystore")
        channel.setMethodCallHandler(this)
        context = flutterPluginBinding.applicationContext
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        try {
            when (call.method) {
                "hasIdentity" -> {
                    val keyStore = KeyStore.getInstance("AndroidKeyStore")
                    keyStore.load(null)
                    result.success(keyStore.containsAlias(KEY_ALIAS))
                }
                "recoverIdentity" -> {
                    // Recovery implies getting the public cert WITHOUT auth
                    // This is allowed because public certs are not auth-bound, only private keys are.
                    val identity = getExistingIdentity()
                    if (identity != null) {
                        result.success(identity)
                    } else {
                        result.error("NO_IDENTITY", "No identity found", null)
                    }
                }
                "generateIdentity" -> {
                    val nonceRaw = call.argument<Any>("nonce")!!
                    val challengeBytes = parseNonce(nonceRaw)

                    // 🛡️ NATIVE AUTH FLOW
                    // We hijack the flow here. Instead of generating immediately, 
                    // we show the UI first.
                    authenticateAndGenerate(challengeBytes, result)
                }
                "signHeartbeat" -> {
                    val payload = call.argument<String>("payload")!!
                    // Signing ALWAYS requires auth for our keys.
                    authenticateAndSign(payload, result)
                }
                else -> result.notImplemented()
            }
        } catch (e: Exception) {
            result.error("KEYSTORE_ERROR", e.message, null)
        }
    }

    // --- ACTIVITY LIFECYCLE (Required for UI) ---
    override fun onAttachedToActivity(binding: ActivityPluginBinding) { activity = binding.activity }
    override fun onDetachedFromActivityForConfigChanges() { activity = null }
    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) { activity = binding.activity }
    override fun onDetachedFromActivity() { activity = null }
    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) { channel.setMethodCallHandler(null) }

    // --- BIOMETRIC ORCHESTRATION ---

    private fun authenticateAndGenerate(challengeBytes: ByteArray, flutterResult: Result) {
        val currentActivity = activity as? FragmentActivity
        if (currentActivity == null) {
            flutterResult.error("NO_ACTIVITY", "Cannot show auth prompt without active screen", null)
            return
        }

        val executor = ContextCompat.getMainExecutor(currentActivity)
        
        val callback = object : BiometricPrompt.AuthenticationCallback() {
            override fun onAuthenticationSucceeded(result: BiometricPrompt.AuthenticationResult) {
                super.onAuthenticationSucceeded(result)
                // ✅ AUTH SUCCESS: TEE Window is Open.
                // We execute generation on the main thread executor immediately.
                try {
                    // 1. Delete Old
                    val keyStore = KeyStore.getInstance("AndroidKeyStore")
                    keyStore.load(null)
                    if (keyStore.containsAlias(KEY_ALIAS)) keyStore.deleteEntry(KEY_ALIAS)

                    // 2. Generate New
                    val identity = performGeneration(challengeBytes)
                    flutterResult.success(identity)
                } catch (e: Exception) {
                    flutterResult.error("GEN_FAILED", "Key generation failed after auth: ${e.message}", null)
                }
            }

            override fun onAuthenticationError(errorCode: Int, errString: CharSequence) {
                super.onAuthenticationError(errorCode, errString)
                flutterResult.error("AUTH_ERROR", errString.toString(), errorCode)
            }
            
            override fun onAuthenticationFailed() {
                super.onAuthenticationFailed()
                // Soft failure (wrong finger), prompt stays open. Do nothing.
            }
        }

        val promptInfo = BiometricPrompt.PromptInfo.Builder()
            .setTitle("Invariant Protocol")
            .setSubtitle("Generate Hardware-Backed Identity")
            .setDescription("Authenticate to bind this device's Secure Element to your account.")
            .setAllowedAuthenticators(BiometricManager.Authenticators.BIOMETRIC_STRONG or BiometricManager.Authenticators.DEVICE_CREDENTIAL)
            .build()

        BiometricPrompt(currentActivity, executor, callback).authenticate(promptInfo)
    }

    private fun authenticateAndSign(payload: String, flutterResult: Result) {
        val currentActivity = activity as? FragmentActivity
        if (currentActivity == null) {
            flutterResult.error("NO_ACTIVITY", "Cannot show auth prompt", null)
            return
        }

        // For signing, we SHOULD utilize a CryptoObject for maximum security,
        // but to keep compatibility with the "validity duration" model (Time Based),
        // we can use the same flow as generation (Time-based window).
        
        val executor = ContextCompat.getMainExecutor(currentActivity)
        
        val callback = object : BiometricPrompt.AuthenticationCallback() {
            override fun onAuthenticationSucceeded(result: BiometricPrompt.AuthenticationResult) {
                super.onAuthenticationSucceeded(result)
                try {
                    val signature = performSigning(payload)
                    flutterResult.success(signature)
                } catch (e: Exception) {
                    flutterResult.error("SIGN_FAILED", "Signing failed after auth: ${e.message}", null)
                }
            }
            
            override fun onAuthenticationError(errorCode: Int, errString: CharSequence) {
                flutterResult.error("AUTH_ERROR", errString.toString(), null)
            }
        }

        val promptInfo = BiometricPrompt.PromptInfo.Builder()
            .setTitle("Confirm Presence")
            .setSubtitle("Sign Daily Heartbeat")
            .setAllowedAuthenticators(BiometricManager.Authenticators.BIOMETRIC_STRONG or BiometricManager.Authenticators.DEVICE_CREDENTIAL)
            .build()

        BiometricPrompt(currentActivity, executor, callback).authenticate(promptInfo)
    }

    // --- CORE CRYPTO LOGIC ---

    private fun performGeneration(challengeBytes: ByteArray): Map<String, Any> {
        val kpg = KeyPairGenerator.getInstance(KeyProperties.KEY_ALGORITHM_EC, "AndroidKeyStore")
        
        val parameterSpec = KeyGenParameterSpec.Builder(
            KEY_ALIAS,
            KeyProperties.PURPOSE_SIGN or KeyProperties.PURPOSE_VERIFY
        )
            .setDigests(KeyProperties.DIGEST_SHA256)
            .setAlgorithmParameterSpec(ECGenParameterSpec("secp256r1"))
            .setAttestationChallenge(challengeBytes)
            // 🔒 SECURITY: We set this to true. 
            // Since we are calling this INSIDE onAuthenticationSucceeded, the OS allows it.
            .setUserAuthenticationRequired(true)
            .setUserAuthenticationValidityDurationSeconds(10) // Tight 10s window
            .build()

        kpg.initialize(parameterSpec)
        kpg.generateKeyPair()

        return getExistingIdentity()!!
    }

    private fun performSigning(data: String): List<Int> {
        val keyStore = KeyStore.getInstance("AndroidKeyStore")
        keyStore.load(null)
        val entry = keyStore.getEntry(KEY_ALIAS, null) as KeyStore.PrivateKeyEntry
        val s = Signature.getInstance("SHA256withECDSA")
        
        s.initSign(entry.privateKey)
        s.update(data.toByteArray(Charsets.UTF_8))
        
        return s.sign().map { it.toInt() and 0xFF }.toList()
    }

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

    private fun parseNonce(nonceRaw: Any): ByteArray {
        return when (nonceRaw) {
            is String -> hexStringToByteArray(nonceRaw)
            is ArrayList<*> -> {
                val list = nonceRaw as ArrayList<Int>
                ByteArray(list.size) { list[it].toByte() }
            }
            else -> throw IllegalArgumentException("Invalid nonce type")
        }
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