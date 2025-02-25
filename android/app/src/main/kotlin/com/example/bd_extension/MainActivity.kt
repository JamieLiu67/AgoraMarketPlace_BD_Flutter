package com.example.bd_extension

import android.os.Bundle
import io.agora.rte.extension.bytedance.ExtensionManager
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        ExtensionManager.getInstance(null).initialize(this)

        super.onCreate(savedInstanceState)
    }
}