import '../core/services/storage_service.dart';

class AccessibilitySettings {
  final bool dyslexiaMode;
  final bool motorMode;
  final bool calmMode;

  const AccessibilitySettings({
    required this.dyslexiaMode,
    required this.motorMode,
    required this.calmMode,
  });

  static const off = AccessibilitySettings(
    dyslexiaMode: false,
    motorMode: false,
    calmMode: false,
  );
}

class AccessibilityService {
  final StorageService _storage;

  AccessibilityService([StorageService? storage])
    : _storage = storage ?? StorageService.instance;

  bool get dyslexiaMode =>
      _storage.getBoolValue('dyslexia_mode', defaultValue: false);

  bool get motorMode =>
      _storage.getBoolValue('motor_mode', defaultValue: false);

  bool get calmMode =>
      _storage.getBoolValue('calm_mode', defaultValue: false);

  AccessibilitySettings get settings => AccessibilitySettings(
    dyslexiaMode: dyslexiaMode,
    motorMode: motorMode,
    calmMode: calmMode,
  );

  Future<void> setDyslexiaMode(bool value) =>
      _storage.setOnboardingValue('dyslexia_mode', value);

  Future<void> setMotorMode(bool value) =>
      _storage.setOnboardingValue('motor_mode', value);

  Future<void> setCalmMode(bool value) =>
      _storage.setOnboardingValue('calm_mode', value);
}
