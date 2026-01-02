# Руководство по интеграции

## Настройка AppHud (нативный код)

Поскольку пакет `apphud_flutter` не поддерживает null safety, необходимо реализовать нативный код для iOS и Android.

### iOS (ios/Runner/AppDelegate.swift)

```swift
import UIKit
import Flutter
import ApphudSDK

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    let apphudChannel = FlutterMethodChannel(name: "apphud_service",
                                              binaryMessenger: controller.binaryMessenger)

    apphudChannel.setMethodCallHandler({
      (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      if call.method == "initialize" {
        let args = call.arguments as! Dictionary<String, Any>
        let apiKey = args["apiKey"] as! String
        let userId = args["userId"] as! String

        Apphud.start(apiKey: apiKey, userID: userId)
        result(true)
      } else if call.method == "hasActiveSubscription" {
        result(Apphud.hasActiveSubscription())
      } else if call.method == "hasPremiumAccess" {
        result(Apphud.hasPremiumAccess())
      } else if call.method == "getPaywalls" {
        // Implement paywall loading
        result([])
      } else if call.method == "purchaseProduct" {
        let args = call.arguments as! Dictionary<String, Any>
        let productId = args["productId"] as! String
        // Implement purchase
        result(false)
      } else if call.method == "restorePurchases" {
        Apphud.restorePurchases()
        result(true)
      } else if call.method == "setAttribution" {
        let args = call.arguments as! Dictionary<String, Any>
        let data = args["data"] as! Dictionary<String, Any>
        // Set attribution
        result(true)
      } else {
        result(FlutterMethodNotImplemented)
      }
    })

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

### Android (android/app/src/main/kotlin/.../MainActivity.kt)

```kotlin
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.apphud.sdk.Apphud

class MainActivity: FlutterActivity() {
    private val CHANNEL = "apphud_service"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "initialize" -> {
                    val apiKey = call.argument<String>("apiKey") ?: ""
                    val userId = call.argument<String>("userId") ?: ""
                    Apphud.start(apiKey, userId, this)
                    result.success(true)
                }
                "hasActiveSubscription" -> {
                    result.success(Apphud.hasActiveSubscription())
                }
                "hasPremiumAccess" -> {
                    result.success(Apphud.hasPremiumAccess())
                }
                "getPaywalls" -> {
                    // Implement paywall loading
                    result.success(emptyList<Map<String, Any>>())
                }
                "purchaseProduct" -> {
                    val productId = call.argument<String>("productId") ?: ""
                    // Implement purchase
                    result.success(false)
                }
                "restorePurchases" -> {
                    Apphud.restorePurchases()
                    result.success(true)
                }
                "setAttribution" -> {
                    val data = call.argument<Map<String, Any>>("data")
                    // Set attribution
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}
```

## Настройка AppsFlyer

### iOS Info.plist

Добавьте в `ios/Runner/Info.plist`:

```xml
<key>NSUserTrackingUsageDescription</key>
<string>We need your permission to track your activity to improve our services</string>
```

### Android AndroidManifest.xml

Добавьте разрешения в `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
```

## Настройка локализации

Локализация настроена через ARB файлы:
- `lib/l10n/app_en.arb` - английский
- `lib/l10n/app_ru.arb` - русский

Для использования в коде:
```dart
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

final l10n = AppLocalizations.of(context)!;
Text(l10n.scanQRCode)
```

## Продукты подписок

Используйте следующие Product IDs:
- Weekly: `sonicforge_weekly`
- Monthly: `sonicforge_monthly`
- Yearly: `sonicforge_yearly`

Paywall ID: `main_paywall`

## ATT (App Tracking Transparency)

ATT запрашивается автоматически при запуске приложения на iOS. Статус передается в AppsFlyer для корректной атрибуции.

