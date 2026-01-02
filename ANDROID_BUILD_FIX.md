# Исправление проблем сборки Android

## Проблемы и решения

### 1. Обновлены версии

✅ **Android Gradle Plugin**: обновлен с 8.1.0 до 8.7.0
✅ **Kotlin**: обновлен с 1.9.22 до 2.1.0
✅ **Gradle**: обновлен с 8.3.0 до 8.7.0
✅ **compileSdkVersion**: обновлен до 35 (требуется для AppsFlyer)

### 2. Проблема с namespace для плагинов

Плагин `contacts_service` не имеет namespace, что требуется для AGP 8.0+.

**Решение**: Добавлена автоматическая настройка namespace в `android/build.gradle`:
- Автоматически извлекает namespace из `AndroidManifest.xml` плагина
- Если namespace не найден, используется значение из манифеста

### 3. Если проблема сохраняется

Если ошибка с namespace все еще возникает, попробуйте:

1. **Очистить кэш Gradle**:
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
```

2. **Удалить кэш Kotlin**:
```bash
rm -rf ~/.gradle/caches/
```

3. **Использовать флаг для пропуска проверки** (временно):
```bash
flutter run --android-skip-build-dependency-validation
```

### 4. Проверка версий

Убедитесь, что все версии соответствуют:
- `android/settings.gradle`: AGP 8.7.0, Kotlin 2.1.0
- `android/build.gradle`: AGP 8.7.0, Kotlin 2.1.0
- `android/gradle/wrapper/gradle-wrapper.properties`: Gradle 8.7
- `android/app/build.gradle`: compileSdkVersion 35, targetSdkVersion 35

