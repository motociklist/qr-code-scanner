# Быстрая настройка Firebase

## Автоматическая настройка (рекомендуется)

1. **Войдите в Firebase CLI:**
```bash
firebase login
```

2. **Запустите автоматическую настройку:**
```bash
flutterfire configure
```

3. **Следуйте инструкциям:**
   - Выберите ваш Firebase проект
   - Выберите платформы (Android, iOS)
   - Файлы конфигурации будут созданы автоматически

4. **Установите зависимости:**
```bash
flutter pub get
```

## Ручная настройка

Если автоматическая настройка не работает:

### Android

1. Скачайте `google-services.json` из Firebase Console
2. Поместите в `android/app/google-services.json`
3. Обновите значения в `lib/firebase_options.dart` для Android

### iOS

1. Скачайте `GoogleService-Info.plist` из Firebase Console
2. Откройте проект в Xcode: `open ios/Runner.xcworkspace`
3. Перетащите файл в папку `Runner`
4. Обновите значения в `lib/firebase_options.dart` для iOS

## Проверка

После настройки запустите:
```bash
flutter run
```

Если Firebase инициализируется без ошибок - всё готово! ✅

