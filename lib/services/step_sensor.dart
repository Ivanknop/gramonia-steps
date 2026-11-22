import 'package:flutter/services.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';

enum SensorPermission { granted, denied, permanentlyDenied }

/// El sensor no existe en este celular.
class StepSensorUnavailable implements Exception {
  const StepSensorUnavailable(this.message);
  final String message;

  @override
  String toString() => 'StepSensorUnavailable: $message';
}

/// Acceso al sensor de pasos y a su permiso.
abstract interface class StepSensor {
  Future<SensorPermission> checkPermission();
  Future<SensorPermission> requestPermission();
  Future<void> openSettings();

  /// Lecturas de TYPE_STEP_COUNTER: pasos desde el último reinicio.
  /// Si no hay sensor, el stream da un error [StepSensorUnavailable].
  Stream<int> readings();
}

class DeviceStepSensor implements StepSensor {
  const DeviceStepSensor();

  static const _permission = Permission.activityRecognition;

  @override
  Future<SensorPermission> checkPermission() async =>
      _map(await _permission.status);

  @override
  Future<SensorPermission> requestPermission() async =>
      _map(await _permission.request());

  @override
  Future<void> openSettings() => openAppSettings();

  @override
  Stream<int> readings() => Pedometer.stepCountStream
      .map((event) => event.steps)
      .handleError((Object error) {
        // El paquete pedometer usa el código "1" cuando no hay sensor.
        if (error is PlatformException && error.code == '1') {
          throw StepSensorUnavailable(error.message ?? '');
        }
        throw error;
      });

  SensorPermission _map(PermissionStatus status) {
    if (status.isGranted || status.isLimited) return SensorPermission.granted;
    if (status.isPermanentlyDenied || status.isRestricted) {
      return SensorPermission.permanentlyDenied;
    }
    return SensorPermission.denied;
  }
}
