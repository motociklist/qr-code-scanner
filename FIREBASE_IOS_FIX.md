# Решение проблемы с iOS в Firebase

## Проблема
Firebase CLI не может автоматически создать iOS приложение. Это нормально - нужно создать его вручную.

## Решение: Настройка iOS вручную

### Вариант 1: Пропустить iOS при настройке (рекомендуется)

1. **Запустите flutterfire configure снова, но пропустите iOS:**
```bash
flutterfire configure
```

2. **Выберите только Android** (или выберите iOS позже, когда создадите приложение вручную)

3. **Android настроится автоматически**

### Вариант 2: Создать iOS приложение вручную в Firebase Console

1. **Откройте Firebase Console:**
   - Перейдите на https://console.firebase.google.com/
   - Выберите проект `qr-code-scranner--247`

2. **Добавьте iOS приложение:**
   - Нажмите на иконку iOS (или "Add app" → iOS)
   - Bundle ID: `com.example.qrCodeScanner` (или проверьте в Xcode)
   - App nickname: `QR Code Scanner iOS`
   - App Store ID: оставьте пустым (если еще нет в App Store)
   - Нажмите "Register app"

3. **Скачайте GoogleService-Info.plist:**
   - После создания приложения скачайте файл `GoogleService-Info.plist`
   - НЕ добавляйте его в проект пока

4. **Добавьте файл в Xcode:**
   ```bash
   # Откройте проект в Xcode
   open ios/Runner.xcworkspace
   ```
   - Перетащите `GoogleService-Info.plist` в папку `Runner` в Xcode
   - Убедитесь, что файл добавлен в Target "Runner"
   - ✅ Отметьте "Copy items if needed"

5. **Обновите firebase_options.dart:**
   - Откройте `GoogleService-Info.plist` в текстовом редакторе
   - Скопируйте значения и вставьте в `lib/firebase_options.dart`:

```dart
static const FirebaseOptions ios = FirebaseOptions(
  apiKey: 'AIza...', // из GoogleService-Info.plist -> API_KEY
  appId: '1:123456789:ios:abc123', // из GoogleService-Info.plist -> GOOGLE_APP_ID
  messagingSenderId: '123456789', // из GoogleService-Info.plist -> GCM_SENDER_ID
  projectId: 'qr-code-scranner--247', // из GoogleService-Info.plist -> PROJECT_ID
  storageBucket: 'qr-code-scranner--247.appspot.com', // из GoogleService-Info.plist -> STORAGE_BUCKET
  iosBundleId: 'com.example.qrCodeScanner', // ваш Bundle ID
);
```

### Вариант 3: Проверить Bundle ID в Xcode

1. **Откройте проект в Xcode:**
```bash
open ios/Runner.xcworkspace
```

2. **Проверьте Bundle Identifier:**
   - Выберите проект "Runner" в навигаторе
   - Выберите Target "Runner"
   - Вкладка "General"
   - Найдите "Bundle Identifier"
   - Используйте этот Bundle ID при создании iOS приложения в Firebase

### После настройки

1. **Установите зависимости:**
```bash
flutter pub get
```

2. **Проверьте работу:**
```bash
flutter run
```

## Альтернатива: Настроить только Android сейчас

Если iOS не критичен сейчас, можно:
1. Настроить только Android через `flutterfire configure`
2. iOS настроить позже вручную через Firebase Console

Android будет работать, iOS можно добавить когда будет готов.

