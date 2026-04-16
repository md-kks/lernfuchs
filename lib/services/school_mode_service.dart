import '../core/services/storage_service.dart';

class SchoolModeService {
  final StorageService _storage;

  SchoolModeService([StorageService? storage])
    : _storage = storage ?? StorageService.instance;

  bool get isActive {
    final expires = _storage.getStringValue('school_mode_expires') ?? '';
    if (expires.isEmpty) return false;
    final expiry = DateTime.tryParse(expires);
    if (expiry == null) return false;
    return DateTime.now().isBefore(expiry);
  }

  List<String> get activeCompetencies {
    if (!isActive) return const [];
    return _storage.getStringListValue('school_mode_competencies');
  }

  Future<void> activate(List<String> competencyIds) async {
    await _storage.setOnboardingValue(
      'school_mode_competencies',
      competencyIds,
    );
    final expires = DateTime.now().add(const Duration(days: 14));
    await _storage.setOnboardingValue(
      'school_mode_expires',
      expires.toIso8601String(),
    );
  }

  Future<void> deactivate() async {
    await _storage.setOnboardingValue('school_mode_competencies', <String>[]);
    await _storage.setOnboardingValue('school_mode_expires', '');
  }

  String get expiresLabel {
    final expires = _storage.getStringValue('school_mode_expires') ?? '';
    if (expires.isEmpty) return '';
    return DateTime.tryParse(expires)?.toIso8601String().substring(0, 10) ?? '';
  }
}
