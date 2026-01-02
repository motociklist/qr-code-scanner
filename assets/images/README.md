# Images Folder

Эта папка предназначена для хранения изображений, используемых в приложении.

## Поддерживаемые форматы:
- PNG (.png)
- JPEG (.jpg, .jpeg)
- GIF (.gif)
- WebP (.webp)
- SVG (.svg)

## Использование в коде:

### Для обычных изображений (PNG, JPEG):
```dart
Image.asset('assets/images/your_image.png')
```

### Для SVG:
```dart
SvgPicture.asset('assets/images/your_image.svg')
```

## Примеры использования:

1. **В Container:**
```dart
Container(
  decoration: BoxDecoration(
    image: DecorationImage(
      image: AssetImage('assets/images/background.png'),
      fit: BoxFit.cover,
    ),
  ),
)
```

2. **В Image widget:**
```dart
Image.asset(
  'assets/images/logo.png',
  width: 100,
  height: 100,
)
```

3. **В AppBar:**
```dart
AppBar(
  leading: Image.asset('assets/images/logo.png'),
)
```

