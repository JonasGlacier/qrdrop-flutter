package com.divan.qrdrop_app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val decoderChannelName = "com.divan.txqr/decoder"
    private val encoderChannelName = "com.divan.txqr/encoder"

    private var decoder: txqr.Decoder? = null
    private var encoder: txqr.Encoder? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        decoder = txqr.Txqr.newDecoder()
        encoder = txqr.Txqr.newEncoder(300) // default chunk length

        // Decoder channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, decoderChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "decode" -> {
                        val data = call.arguments as? String
                        if (data == null) {
                            result.error("INVALID_ARG", "data must be a String", null)
                            return@setMethodCallHandler
                        }
                        try {
                            decoder!!.decode(data)
                            result.success(null)
                        } catch (e: Exception) {
                            result.success(e.message)
                        }
                    }

                    "isCompleted" -> {
                        result.success(decoder!!.isCompleted)
                    }

                    "getData" -> {
                        result.success(decoder!!.data())
                    }

                    "getDataBytes" -> {
                        result.success(decoder!!.dataBytes())
                    }

                    "getProgress" -> {
                        val progress = decoder!!.progress().toInt()
                        result.success(progress)
                    }

                    "getSpeed" -> {
                        result.success(decoder!!.speed())
                    }

                    "getTotalTime" -> {
                        result.success(decoder!!.totalTime())
                    }

                    "reset" -> {
                        decoder!!.reset()
                        result.success(null)
                    }

                    else -> result.notImplemented()
                }
            }

        // Encoder channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, encoderChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "encode" -> {
                        val data = call.arguments as? String
                        if (data == null) {
                            result.error("INVALID_ARG", "data must be a String", null)
                            return@setMethodCallHandler
                        }
                        try {
                            encoder!!.encode(data)
                            result.success(null)
                        } catch (e: Exception) {
                            result.error("ENCODE_ERROR", e.message, null)
                        }
                    }

                    "chunkCount" -> {
                        result.success(encoder!!.chunkCount().toInt())
                    }

                    "getChunk" -> {
                        val index = call.arguments as? Int
                        if (index == null) {
                            result.error("INVALID_ARG", "index must be an Int", null)
                            return@setMethodCallHandler
                        }
                        result.success(encoder!!.getChunk(index.toLong()))
                    }

                    "setChunkLength" -> {
                        val chunkLen = call.arguments as? Int
                        if (chunkLen == null) {
                            result.error("INVALID_ARG", "chunkLen must be an Int", null)
                            return@setMethodCallHandler
                        }
                        encoder = txqr.Txqr.newEncoder(chunkLen.toLong())
                        result.success(null)
                    }

                    "setRedundancyFactor" -> {
                        val rf = call.arguments as? Double
                        if (rf == null) {
                            result.error("INVALID_ARG", "rf must be a Double", null)
                            return@setMethodCallHandler
                        }
                        encoder!!.setRedundancyFactor(rf)
                        result.success(null)
                    }

                    else -> result.notImplemented()
                }
            }
    }
}
