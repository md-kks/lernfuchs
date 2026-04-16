import '../core/services/storage_service.dart';

enum Season { spring, summer, autumn, winter }

enum SpecialDay { christmas, newYear, halloween, birthday }

class SeasonContext {
  final Season season;
  final bool isEvening;
  final bool isNight;
  final SpecialDay? specialDay;

  const SeasonContext({
    required this.season,
    required this.isEvening,
    required this.isNight,
    required this.specialDay,
  });
}

class SeasonService {
  Season get currentSeason {
    final month = DateTime.now().month;
    if (month >= 3 && month <= 5) return Season.spring;
    if (month >= 6 && month <= 8) return Season.summer;
    if (month >= 9 && month <= 11) return Season.autumn;
    return Season.winter;
  }

  bool get isEvening {
    final hour = DateTime.now().hour;
    return hour >= 18 && hour <= 22;
  }

  bool get isNight {
    final hour = DateTime.now().hour;
    return hour > 22 || hour < 6;
  }

  SpecialDay? get todaySpecial {
    final now = DateTime.now();
    if (now.month == 12 && now.day >= 24 && now.day <= 26) {
      return SpecialDay.christmas;
    }
    if (now.month == 1 && now.day == 1) return SpecialDay.newYear;
    if (now.month == 10 && now.day == 31) return SpecialDay.halloween;

    final childBirthdate = StorageService.instance.getStringValue(
      'child_birthdate',
    );
    if (childBirthdate != null && childBirthdate.isNotEmpty) {
      final bd = DateTime.tryParse(childBirthdate);
      if (bd != null && now.month == bd.month && now.day == bd.day) {
        return SpecialDay.birthday;
      }
    }
    return null;
  }

  SeasonContext? get context {
    final enabled = StorageService.instance.getBoolValue(
      'seasonal_enabled',
      defaultValue: true,
    );
    if (!enabled) return null;
    return SeasonContext(
      season: currentSeason,
      isEvening: isEvening,
      isNight: isNight,
      specialDay: todaySpecial,
    );
  }
}
