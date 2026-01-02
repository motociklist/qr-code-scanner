// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'QR Мастер';

  @override
  String get scanQRCode => 'Сканировать QR код';

  @override
  String get createQRCode => 'Создать QR код';

  @override
  String get history => 'История';

  @override
  String get myQRCodes => 'Мои QR коды';

  @override
  String get welcome => 'Добро пожаловать';

  @override
  String get scanSuccessful => 'Сканирование успешно';

  @override
  String get qrCodeDecodedSuccessfully => 'QR код успешно распознан';

  @override
  String get openLink => 'Открыть ссылку';

  @override
  String get copy => 'Копировать';

  @override
  String get share => 'Поделиться';

  @override
  String get save => 'Сохранить';

  @override
  String get delete => 'Удалить';

  @override
  String get cancel => 'Отмена';

  @override
  String get ok => 'ОК';

  @override
  String get settings => 'Настройки';

  @override
  String get premium => 'Премиум';

  @override
  String get subscribe => 'Подписаться';

  @override
  String get restore => 'Восстановить';

  @override
  String get weeklyPlan => 'Недельный план';

  @override
  String get monthlyPlan => 'Месячный план';

  @override
  String get yearlyPlan => 'Годовой план';

  @override
  String get unlockFullQRTools => 'Разблокировать все инструменты QR';

  @override
  String get unlimitedQRScans => 'Неограниченное сканирование QR';

  @override
  String get createAllQRTypes => 'Создание всех типов QR';

  @override
  String get noAds => 'Без рекламы';

  @override
  String get cloudBackup => 'Облачное резервное копирование';

  @override
  String get advancedAnalytics => 'Расширенная аналитика';

  @override
  String get cameraPermissionRequired => 'Требуется разрешение камеры';

  @override
  String get contactsPermissionRequired => 'Требуется разрешение контактов';

  @override
  String get copiedToClipboard => 'Скопировано в буфер обмена';

  @override
  String get savedSuccessfully => 'Успешно сохранено';

  @override
  String get alreadySaved => 'Уже сохранено';

  @override
  String get noHistoryYet => 'Истории пока нет';

  @override
  String get scannedQRCodesWillAppearHere =>
      'Отсканированные QR коды\nпоявятся здесь';

  @override
  String get noQRCodesYet => 'QR кодов пока нет';

  @override
  String get createYourFirstQRCode => 'Создайте свой первый QR код';
}
