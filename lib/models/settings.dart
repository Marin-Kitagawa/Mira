import 'package:shared_preferences/shared_preferences.dart';

enum NumberType {
  sequential,    // 1..n
  randomInteger, // random integers in [min,max]
  fraction,      // rational p/q
  real,          // random floats
  complex,       // a+bi  – ordered by |z|
  quaternion,    // a+bi+cj+dk – ordered by |q|
  octonion,      // 8 components – ordered by |o|
}

enum CoefficientType {
  sequential,    // draws from {1..numberCount}
  randomInteger, // user range [coeffMin, coeffMax]
  fraction,      // p/q where p∈[coeffMin,coeffMax], q∈[1,coeffDenomMax]
  real,          // float in [coeffMin, coeffMax]
}

class GameSettings {
  final int numberCount;
  final NumberType numberType;

  // Simple types (integer, fraction, real)
  final int randomMin;
  final int randomMax;
  final int base;          // display base for integer/fraction values
  final int denominatorMax;

  // Real-specific
  final int realDecimalPlaces;    // 1–15
  final bool includeNamedConstants; // mix in π, e, φ, etc.

  // Coefficient settings (for complex / quaternion / octonion)
  final CoefficientType coefficientType;
  final int coeffMin;
  final int coeffMax;
  final int coeffDenomMax;
  // coefficients also use `base` for display when type is integer/fraction

  // Progression
  final bool autoLevel;
  final int streakThreshold;

  const GameSettings({
    this.numberCount = 9,
    this.numberType = NumberType.sequential,
    this.randomMin = -20,
    this.randomMax = 20,
    this.base = 10,
    this.denominatorMax = 9,
    this.realDecimalPlaces = 2,
    this.includeNamedConstants = false,
    this.coefficientType = CoefficientType.randomInteger,
    this.coeffMin = -5,
    this.coeffMax = 5,
    this.coeffDenomMax = 9,
    this.autoLevel = false,
    this.streakThreshold = 3,
  });

  GameSettings copyWith({
    int? numberCount,
    NumberType? numberType,
    int? randomMin,
    int? randomMax,
    int? base,
    int? denominatorMax,
    int? realDecimalPlaces,
    bool? includeNamedConstants,
    CoefficientType? coefficientType,
    int? coeffMin,
    int? coeffMax,
    int? coeffDenomMax,
    bool? autoLevel,
    int? streakThreshold,
  }) {
    return GameSettings(
      numberCount: numberCount ?? this.numberCount,
      numberType: numberType ?? this.numberType,
      randomMin: randomMin ?? this.randomMin,
      randomMax: randomMax ?? this.randomMax,
      base: base ?? this.base,
      denominatorMax: denominatorMax ?? this.denominatorMax,
      realDecimalPlaces: realDecimalPlaces ?? this.realDecimalPlaces,
      includeNamedConstants: includeNamedConstants ?? this.includeNamedConstants,
      coefficientType: coefficientType ?? this.coefficientType,
      coeffMin: coeffMin ?? this.coeffMin,
      coeffMax: coeffMax ?? this.coeffMax,
      coeffDenomMax: coeffDenomMax ?? this.coeffDenomMax,
      autoLevel: autoLevel ?? this.autoLevel,
      streakThreshold: streakThreshold ?? this.streakThreshold,
    );
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('numberCount', numberCount);
    await prefs.setInt('numberType', numberType.index);
    await prefs.setInt('randomMin', randomMin);
    await prefs.setInt('randomMax', randomMax);
    await prefs.setInt('base', base);
    await prefs.setInt('denominatorMax', denominatorMax);
    await prefs.setInt('realDecimalPlaces', realDecimalPlaces);
    await prefs.setBool('includeNamedConstants', includeNamedConstants);
    await prefs.setInt('coefficientType', coefficientType.index);
    await prefs.setInt('coeffMin', coeffMin);
    await prefs.setInt('coeffMax', coeffMax);
    await prefs.setInt('coeffDenomMax', coeffDenomMax);
    await prefs.setBool('autoLevel', autoLevel);
    await prefs.setInt('streakThreshold', streakThreshold);
  }

  static Future<GameSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    final ntIdx = (prefs.getInt('numberType') ?? 0)
        .clamp(0, NumberType.values.length - 1);
    final ctIdx = (prefs.getInt('coefficientType') ?? 1)
        .clamp(0, CoefficientType.values.length - 1);
    return GameSettings(
      numberCount: prefs.getInt('numberCount') ?? 9,
      numberType: NumberType.values[ntIdx],
      randomMin: prefs.getInt('randomMin') ?? -20,
      randomMax: prefs.getInt('randomMax') ?? 20,
      base: prefs.getInt('base') ?? 10,
      denominatorMax: prefs.getInt('denominatorMax') ?? 9,
      realDecimalPlaces: (prefs.getInt('realDecimalPlaces') ?? 2).clamp(1, 15),
      includeNamedConstants: prefs.getBool('includeNamedConstants') ?? false,
      coefficientType: CoefficientType.values[ctIdx],
      coeffMin: prefs.getInt('coeffMin') ?? -5,
      coeffMax: prefs.getInt('coeffMax') ?? 5,
      coeffDenomMax: prefs.getInt('coeffDenomMax') ?? 9,
      autoLevel: prefs.getBool('autoLevel') ?? false,
      streakThreshold: prefs.getInt('streakThreshold') ?? 3,
    );
  }

  static Future<int> loadBestMs(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('best_$key') ?? 0;
  }

  static Future<void> saveBestMs(String key, int ms) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('best_$key', ms);
  }
}
