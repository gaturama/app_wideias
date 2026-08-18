package com.example.wideias_app

import com.google.android.gms.wallet.IsReadyToPayRequest
import com.google.android.gms.wallet.PaymentsClient
import com.google.android.gms.wallet.Wallet
import com.google.android.gms.wallet.WalletConstants

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

import org.json.JSONArray
import org.json.JSONObject

class MainActivity : FlutterActivity() {

    private val channelName = "wideias/google_pay"

    private lateinit var paymentsClient: PaymentsClient

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        paymentsClient = Wallet.getPaymentsClient(
            this,
            Wallet.WalletOptions.Builder()
                .setEnvironment(WalletConstants.ENVIRONMENT_TEST)
                .build()
        )

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            channelName
        ).setMethodCallHandler { call, result ->

            when (call.method) {
                "isReadyToPay" -> checkIsReadyToPay(result)

                else -> result.notImplemented()
            }
        }
    }

    private fun checkIsReadyToPay(result: MethodChannel.Result) {
        try {
            val requestJson = JSONObject()
                .put("apiVersion", 2)
                .put("apiVersionMinor", 0)
                .put("existingPaymentMethodRequired", true)
                .put(
                    "allowedPaymentMethods",
                    JSONArray().put(
                        JSONObject()
                            .put("type", "CARD")
                            .put(
                                "parameters",
                                JSONObject()
                                    .put(
                                        "allowedAuthMethods",
                                        JSONArray()
                                            .put("PAN_ONLY")
                                            .put("CRYPTOGRAM_3DS")
                                    )
                                    .put(
                                        "allowedCardNetworks",
                                        JSONArray()
                                            .put("VISA")
                                            .put("MASTERCARD")
                                    )
                            )
                    )
                )

            val request =
                IsReadyToPayRequest.fromJson(requestJson.toString())

            val task = paymentsClient.isReadyToPay(request)

            task.addOnCompleteListener { completedTask ->
                if (completedTask.isSuccessful) {
                    result.success(completedTask.result == true)
                } else {
                    result.error(
                        "GOOGLE_PAY_ERROR",
                        completedTask.exception?.message
                            ?: "Erro ao verificar Google Pay.",
                        null
                    )
                }
            }
        } catch (e: Exception) {
            result.error(
                "GOOGLE_PAY_ERROR",
                e.message,
                null
            )
        }
    }
}