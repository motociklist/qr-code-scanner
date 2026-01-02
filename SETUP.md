# Настройка проекта QR Code Scanner

## Установка зависимостей

1. Установите зависимости:
```bash
flutter pub get
```

## Настройка Firebase

1. Создайте проект в [Firebase Console](https://console.firebase.google.com/)
2. Добавьте iOS и Android приложения в проект
3. Скачайте конфигурационные файлы:
   - `google-services.json` для Android (поместите в `android/app/`)
   - `GoogleService-Info.plist` для iOS (поместите в `ios/Runner/`)

## Настройка Google Mobile Ads

1. Создайте приложение в [AdMob Console](https://apps.admob.com/)
2. Создайте рекламные блоки (Banner, Interstitial, Rewarded)
3. Замените тестовые Ad Unit IDs в `lib/services/ads_service.dart`:
   - `_interstitialAdUnitId`
   - `_rewardedAdUnitId`
   - `_bannerAdUnitId`

## Настройка подписок (In-App Purchase)

1. Настройте продукты в App Store Connect (iOS) и Google Play Console (Android)
2. Создайте идентификаторы продуктов:
   - `weekly` - недельная подписка
   - `monthly` - месячная подписка
   - `yearly` - годовая подписка
3. Обновите `lib/services/subscription_service.dart` с правильными идентификаторами

## Настройка Apphud (опционально)

Если вы хотите использовать Apphud вместо стандартного In-App Purchase:

1. Зарегистрируйтесь на [Apphud](https://apphud.com/)
2. Создайте приложение и получите API ключ
3. Установите пакет `apphud_flutter` (если доступен)
4. Обновите `lib/services/subscription_service.dart` с вашим API ключом

## Настройка разрешений

### Android (`android/app/src/main/AndroidManifest.xml`)

Добавьте разрешения:
```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.READ_CONTACTS" />
<uses-permission android:name="android.permission.WRITE_CONTACTS" />
<uses-permission android:name="android.permission.INTERNET" />
```

### iOS (`ios/Runner/Info.plist`)

Добавьте описания разрешений:
```xml
<key>NSCameraUsageDescription</key>
<string>We need access to your camera to scan QR codes</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>We need access to your photo library to scan QR codes from images</string>
<key>NSContactsUsageDescription</key>
<string>We need access to your contacts to add scanned contact information</string>
```

## Запуск приложения

```bash
flutter run
```

## Сборка для релиза

### Android
```bash
flutter build apk --release
# или
flutter build appbundle --release
```

### iOS
```bash
flutter build ios --release
```

## Важные замечания

1. **API ключи**: Не коммитьте реальные API ключи в репозиторий. Используйте переменные окружения или конфигурационные файлы, которые не отслеживаются git.

2. **Тестовые данные**: В коде используются тестовые Ad Unit IDs от Google. Замените их на реальные перед публикацией.

3. **Подписки**: Убедитесь, что все идентификаторы продуктов совпадают в коде и в настройках магазинов приложений.

4. **Firebase**: Убедитесь, что Firebase правильно настроен для обеих платформ перед запуском.

