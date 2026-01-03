# Настройка Firebase для проекта

## Шаг 1: Создание проекта Firebase

1. Перейдите на [Firebase Console](https://console.firebase.google.com/)
2. Создайте новый проект или выберите существующий
3. Добавьте приложения для Android и iOS

## Шаг 2: Настройка Android

### 2.1. Добавление google-services.json

1. В Firebase Console выберите ваш Android проект
2. Скачайте файл `google-services.json`
3. Поместите его в `android/app/google-services.json`

### 2.2. Настройка build.gradle

Файлы уже настроены:
- `android/build.gradle` - добавлен Google Services plugin
- `android/app/build.gradle` - применен Google Services plugin

### 2.3. Package Name

Убедитесь, что package name в `android/app/build.gradle` совпадает с package name в Firebase Console:
```gradle
applicationId "com.example.qr_code_scanner"
```

## Шаг 3: Настройка iOS

### 3.1. Добавление GoogleService-Info.plist

1. В Firebase Console выберите ваш iOS проект
2. Скачайте файл `GoogleService-Info.plist`
3. Откройте проект в Xcode: `open ios/Runner.xcworkspace`
4. Перетащите `GoogleService-Info.plist` в папку `Runner` в Xcode
5. Убедитесь, что файл добавлен в Target "Runner"

### 3.2. Bundle Identifier

Убедитесь, что Bundle Identifier в Xcode совпадает с Bundle ID в Firebase Console:
```
com.example.qrCodeScanner
```

## Шаг 4: Генерация firebase_options.dart

### Автоматический способ (рекомендуется):

1. Убедитесь, что вы авторизованы в Firebase:
```bash
firebase login
```

2. Запустите FlutterFire CLI:
```bash
flutterfire configure
```

3. Выберите ваш Firebase проект
4. Выберите платформы (Android, iOS)
   - ⚠️ **Если iOS не создается автоматически** - это нормально, создайте его вручную в Firebase Console (см. ниже)
5. Файл `lib/firebase_options.dart` будет автоматически создан с правильными конфигурациями

### Если iOS не создается автоматически:

См. подробную инструкцию в `FIREBASE_IOS_FIX.md`

### Ручной способ:

Если автоматическая настройка не работает, отредактируйте `lib/firebase_options.dart`:

1. Откройте `lib/firebase_options.dart`
2. Замените значения в `FirebaseOptions`:
   - Для Android: используйте данные из `google-services.json`
   - Для iOS: используйте данные из `GoogleService-Info.plist`

Пример для Android:
```dart
static const FirebaseOptions android = FirebaseOptions(
  apiKey: 'AIza...', // из google-services.json -> client -> api_key -> current_key
  appId: '1:123456789:android:abc123', // из google-services.json -> client -> client_info -> mobilesdk_app_id
  messagingSenderId: '123456789', // из google-services.json -> project_number
  projectId: 'your-project-id', // из google-services.json -> project_id
  storageBucket: 'your-project-id.appspot.com', // из google-services.json -> storage_bucket
);
```

Пример для iOS:
```dart
static const FirebaseOptions ios = FirebaseOptions(
  apiKey: 'AIza...', // из GoogleService-Info.plist -> API_KEY
  appId: '1:123456789:ios:abc123', // из GoogleService-Info.plist -> GCM_SENDER_ID
  messagingSenderId: '123456789', // из GoogleService-Info.plist -> GCM_SENDER_ID
  projectId: 'your-project-id', // из GoogleService-Info.plist -> PROJECT_ID
  storageBucket: 'your-project-id.appspot.com', // из GoogleService-Info.plist -> STORAGE_BUCKET
  iosBundleId: 'com.example.qrCodeScanner', // ваш Bundle ID
);
```

## Шаг 5: Установка зависимостей

```bash
flutter pub get
```

## Шаг 6: Проверка

Запустите приложение:
```bash
flutter run
```

Firebase должен инициализироваться без ошибок.

## Включенные Firebase сервисы

- ✅ **Firebase Core** - базовая инициализация
- ✅ **Firebase Analytics** - аналитика событий
- ✅ **Firebase Crashlytics** - отслеживание ошибок (добавлен в зависимости)
- ✅ **Firebase Cloud Messaging** - push-уведомления (добавлен в зависимости)

## Дополнительные настройки

### Crashlytics

Для включения Crashlytics добавьте в `main.dart`:
```dart
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

void main() async {
  // ... существующий код ...

  FlutterError.onError = (errorDetails) {
    FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };
}
```

### Cloud Messaging

Для работы с push-уведомлениями настройте обработчики в `main.dart` и добавьте необходимые разрешения в `AndroidManifest.xml` и `Info.plist`.

## Troubleshooting

### Ошибка: "FirebaseOptions cannot be null"

Убедитесь, что:
1. Файл `lib/firebase_options.dart` существует
2. Значения в `FirebaseOptions` заполнены правильно
3. Вы запустили `flutter pub get`

### Ошибка: "google-services.json not found"

Убедитесь, что файл `google-services.json` находится в `android/app/` и добавлен в проект.

### Ошибка: "GoogleService-Info.plist not found"

Убедитесь, что файл добавлен в Xcode проект и включен в Target "Runner".

