package com.azonixnetworks.tradex_mobile

import android.app.Application
import android.content.Context
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.embedding.engine.dart.DartExecutor

class TradeXApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        getOrCreateFlutterEngine(this)
    }

    companion object {
        private const val engineId = "tradex_primary_engine"

        @Synchronized
        fun getOrCreateFlutterEngine(context: Context): FlutterEngine {
            FlutterEngineCache.getInstance().get(engineId)?.let { return it }

            return FlutterEngine(context.applicationContext).also { engine ->
                engine.navigationChannel.setInitialRoute("/")
                engine.dartExecutor.executeDartEntrypoint(
                    DartExecutor.DartEntrypoint.createDefault()
                )
                FlutterEngineCache.getInstance().put(engineId, engine)
            }
        }
    }
}
