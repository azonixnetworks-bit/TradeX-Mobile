package com.azonixnetworks.tradex_mobile

import android.os.Build
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.Base64
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.plugin.common.MethodChannel
import java.security.KeyPairGenerator
import java.security.KeyStore
import java.security.Signature
import java.security.spec.ECGenParameterSpec

class MainActivity : FlutterFragmentActivity() {
    private val channelName = "com.azonixnetworks.tradex_mobile/device_credential"
    private val aliasPrefix = "tradex.quick.login."

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                try {
                    val credentialId = call.argument<String>("credentialId")
                        ?: throw IllegalArgumentException("credentialId is required")
                    when (call.method) {
                        "createCredential" -> {
                            val requireBiometric = call.argument<Boolean>("requireBiometric") ?: false
                            result.success(createCredential(credentialId, requireBiometric))
                        }
                        "sign" -> {
                            val message = call.argument<String>("message")
                                ?: throw IllegalArgumentException("message is required")
                            result.success(sign(credentialId, message))
                        }
                        "containsCredential" -> result.success(containsCredential(credentialId))
                        "deleteCredential" -> {
                            deleteCredential(credentialId)
                            result.success(null)
                        }
                        else -> result.notImplemented()
                    }
                } catch (error: android.security.keystore.UserNotAuthenticatedException) {
                    result.error(
                        "USER_NOT_AUTHENTICATED",
                        "Confirm your fingerprint before signing in.",
                        null
                    )
                } catch (error: android.security.keystore.KeyPermanentlyInvalidatedException) {
                    result.error(
                        "CREDENTIAL_INVALIDATED",
                        "Fingerprint enrollment changed. Set up quick login again.",
                        null
                    )
                } catch (error: Throwable) {
                    result.error(
                        "DEVICE_CREDENTIAL_ERROR",
                        error.message ?: "The protected device credential failed.",
                        null
                    )
                }
            }
    }

    private fun createCredential(
        credentialId: String,
        requireBiometric: Boolean
    ): Map<String, String> {
        deleteCredential(credentialId)
        val generator = KeyPairGenerator.getInstance(
            KeyProperties.KEY_ALGORITHM_EC,
            "AndroidKeyStore"
        )
        val builder = KeyGenParameterSpec.Builder(
            alias(credentialId),
            KeyProperties.PURPOSE_SIGN or KeyProperties.PURPOSE_VERIFY
        )
            .setAlgorithmParameterSpec(ECGenParameterSpec("secp256r1"))
            .setDigests(KeyProperties.DIGEST_SHA256)

        if (requireBiometric) {
            builder.setUserAuthenticationRequired(true)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                builder.setUserAuthenticationParameters(
                    60,
                    KeyProperties.AUTH_BIOMETRIC_STRONG
                )
            } else {
                @Suppress("DEPRECATION")
                builder.setUserAuthenticationValidityDurationSeconds(60)
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                builder.setInvalidatedByBiometricEnrollment(true)
            }
        }

        generator.initialize(builder.build())
        val pair = generator.generateKeyPair()
        return mapOf(
            "publicKey" to Base64.encodeToString(pair.public.encoded, Base64.NO_WRAP),
            "algorithm" to "ES256"
        )
    }

    private fun sign(credentialId: String, message: String): String {
        val keyStore = keyStore()
        val privateKey = keyStore.getKey(alias(credentialId), null)
            ?: throw IllegalStateException("The device credential is missing.")
        val signature = Signature.getInstance("SHA256withECDSA")
        signature.initSign(privateKey as java.security.PrivateKey)
        signature.update(message.toByteArray(Charsets.UTF_8))
        return Base64.encodeToString(signature.sign(), Base64.NO_WRAP)
    }

    private fun containsCredential(credentialId: String): Boolean =
        keyStore().containsAlias(alias(credentialId))

    private fun deleteCredential(credentialId: String) {
        val store = keyStore()
        if (store.containsAlias(alias(credentialId))) {
            store.deleteEntry(alias(credentialId))
        }
    }

    private fun keyStore(): KeyStore = KeyStore.getInstance("AndroidKeyStore").apply {
        load(null)
    }

    private fun alias(credentialId: String): String =
        aliasPrefix + credentialId.lowercase()
}
