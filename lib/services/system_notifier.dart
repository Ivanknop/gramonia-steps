import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/textos.dart';
import '../logic/notification_summary.dart';

/// Notificaciones del celular (fuera del juego).
abstract interface class SystemNotifier {
  /// Pide el permiso POST_NOTIFICATIONS (Android 13 o superior). En
  /// versiones anteriores no hace falta: devuelve true.
  Future<bool> requestPermission();

  /// Muestra (o actualiza) la notificación del juego.
  Future<void> show(GameNotification notification);

  /// Saca la notificación del juego.
  Future<void> cancel();

  /// Ajustes de la app, para dar el permiso si se negó.
  Future<void> openSettings();
}

/// Dónde se guarda si las notificaciones están activadas.
abstract interface class NotificationPrefs {
  Future<bool> loadEnabled();
  Future<void> saveEnabled(bool enabled);
}

class LocalSystemNotifier implements SystemNotifier {
  LocalSystemNotifier();

  final _plugin = FlutterLocalNotificationsPlugin();
  Future<void>? _ready;

  /// Siempre la misma: se actualiza en vez de sumar otra.
  static const _id = 1;
  static const _channelId = 'objetos_y_etapas';

  Future<void> _init() => _ready ??= _plugin.initialize(
    settings: const InitializationSettings(
      // android/app/src/main/res/drawable/ic_notification.xml
      android: AndroidInitializationSettings('ic_notification'),
    ),
  );

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  @override
  Future<bool> requestPermission() async {
    await _init();
    return await _android?.requestNotificationsPermission() ?? true;
  }

  @override
  Future<void> show(GameNotification notification) async {
    await _init();
    await _plugin.show(
      id: _id,
      title: notification.title,
      body: notification.body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          Strings.notificationChannel,
          channelDescription: Strings.notificationChannelDescription,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          // Sin sonido ni vibración si solo se sumaron objetos.
          silent: !notification.alert,
          styleInformation: InboxStyleInformation(
            notification.lines,
            contentTitle: notification.title,
          ),
        ),
      ),
    );
  }

  @override
  Future<void> cancel() async {
    await _init();
    await _plugin.cancel(id: _id);
  }

  @override
  Future<void> openSettings() => openAppSettings();
}

class PrefsNotificationPrefs implements NotificationPrefs {
  const PrefsNotificationPrefs();

  static const key = 'notifications_enabled';

  @override
  Future<bool> loadEnabled() async =>
      (await SharedPreferences.getInstance()).getBool(key) ?? false;

  @override
  Future<void> saveEnabled(bool enabled) async =>
      (await SharedPreferences.getInstance()).setBool(key, enabled);
}
