# What is this?
It's a flutter demo for AgoraMarketPlace ByteDance beauty extensions,that can allow you running on Android(For now).

AgoraMarketPlace(EN): https://www.agora.io/en/agora-extensions-marketplace/
AgoraMarketPlace(CN): https://www.shengwang.cn/cn/marketplace

# How to use?
1. Download the extensions and resource from [README.md](README.md)
2. Put extension and resource into project like this:
```
├── android
│   |
│   └── libs //extension file for android
│        |
│        └──extension_aar-release.aar // aar file
│   └── build.gradle
├── ios
|    |
|    └──AgoraByteDanceExtension.framework //extensions framework for iOS
|    └──AgoraByteDanceExtension.framework.dSYM //extensions framework for iOS
├── lib
|__ Resource
``` 
3. flutter pub get & flutter run

# How to use my own license and run?
1. Change the applicationId to your own.(Aka BundleIdentifier in Xcode)
```gradle
    defaultConfig {
        // TODO: Change the applicationId to your own, if you have changed your own license.bundle
        applicationId "io.agora.rte.extension.bytedance.peter"

        minSdkVersion flutter.minSdkVersion
        targetSdkVersion flutter.targetSdkVersion
        versionCode flutterVersionCode.toInteger()
        versionName flutterVersionName
    }
```
2. Drag your license file out of Resource/LicenseBag.bundle/xxxx.licbag , and put it into Resource file

```
├── lib
|__ Resource
|    └──a.bundle
|    └──b.bundle
|    └──xxxx.licbag
|    └──LicenseBag.bundle
```

# PS
If you want to use extension in your own android porject,pls check and add these code to your android/app/src/main/kotlin/com/example/bd_extension/MainActivity.kt
```kotlin
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
```