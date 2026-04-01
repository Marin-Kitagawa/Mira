import 'dart:math';
import '../models/settings.dart';

const _kDigits = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ';

String convertToBase(int n, int base) {
  assert(base >= 2 && base <= 36);
  if (n == 0) return '0';
  final negative = n < 0;
  var abs = n.abs();
  var result = '';
  while (abs > 0) {
    result = _kDigits[abs % base] + result;
    abs ~/= base;
  }
  return negative ? '-$result' : result;
}

int _gcd(int a, int b) {
  a = a.abs();
  b = b.abs();
  while (b != 0) {
    final t = b;
    b = a % b;
    a = t;
  }
  return a == 0 ? 1 : a;
}

// ── GameNumber ────────────────────────────────────────────────────────────────

class GameNumber {
  final String display;
  final double sortKey; // value for scalars, magnitude for vector types
  const GameNumber({required this.display, required this.sortKey});
}

// ── Coefficient generation ────────────────────────────────────────────────────

typedef _C = ({double value, String display});

_C _genCoeff(
  CoefficientType type,
  int min,
  int max,
  int denomMax,
  int base,
  int numberCount,
  int decimalPlaces,
  Random rng,
) {
  // Safeguard: ensure range is valid
  if (min >= max) { min = -5; max = 5; }
  final range = max - min + 1;

  switch (type) {
    case CoefficientType.sequential:
      // Draw from {1 .. numberCount}
      final v = 1 + rng.nextInt(numberCount.clamp(1, 100));
      return (value: v.toDouble(), display: convertToBase(v, base));

    case CoefficientType.randomInteger:
      int v;
      int attempts = 0;
      do {
        v = min + rng.nextInt(range);
        attempts++;
      } while (v == 0 && attempts < 50);
      return (value: v.toDouble(), display: convertToBase(v, base));

    case CoefficientType.fraction:
      int n, d;
      int attempts = 0;
      do {
        n = min + rng.nextInt(range);
        d = 1 + rng.nextInt(denomMax.clamp(1, 99));
        final g = _gcd(n.abs(), d);
        n ~/= g;
        d ~/= g;
        attempts++;
      } while (n == 0 && attempts < 50);
      if (d == 1) {
        return (value: n.toDouble(), display: convertToBase(n, base));
      }
      return (
        value: n / d,
        display: '${convertToBase(n, base)}/${convertToBase(d, base)}',
      );

    case CoefficientType.real:
      double v;
      int attempts = 0;
      do {
        v = min + rng.nextDouble() * (max - min);
        attempts++;
      } while (v.abs() < 0.05 && attempts < 50);
      return (value: v, display: v.toStringAsFixed(decimalPlaces));
  }
}

// Appends a signed unit string: "+3i", "-3i", "+1/2j", "-0.5k", etc.
String _su(_C c, String unit) =>
    '${c.value >= 0 ? '+' : ''}${c.display}$unit';

// ── Public generator ──────────────────────────────────────────────────────────

List<GameNumber> generateNumbers(
  GameSettings s,
  Random rng, {
  int? countOverride,
}) {
  final n = (countOverride ?? s.numberCount).clamp(1, 50);
  switch (s.numberType) {
    case NumberType.sequential:
      return _sequential(n, s.base, rng);
    case NumberType.randomInteger:
      return _integers(n, s.randomMin, s.randomMax, s.base, rng);
    case NumberType.fraction:
      return _fractions(n, s.randomMin, s.randomMax, s.denominatorMax, s.base, rng);
    case NumberType.real:
      return _reals(n, s.randomMin.toDouble(), s.randomMax.toDouble(),
          s.realDecimalPlaces, s.includeNamedConstants, rng);
    case NumberType.complex:
      return _complex(n, s, rng);
    case NumberType.quaternion:
      return _quaternions(n, s, rng);
    case NumberType.octonion:
      return _octonions(n, s, rng);
  }
}

// ── Scalar generators ─────────────────────────────────────────────────────────

List<GameNumber> _sequential(int n, int base, Random rng) {
  final list = List.generate(n, (i) => GameNumber(
    display: convertToBase(i + 1, base),
    sortKey: (i + 1).toDouble(),
  ))..shuffle(rng);
  return list;
}

List<GameNumber> _integers(int n, int min, int max, int base, Random rng) {
  if (min >= max) { min -= n; max += n; }
  final pool = List.generate(max - min + 1, (i) => i + min)..shuffle(rng);
  // If pool smaller than n, allow repeats with offset
  final results = <GameNumber>[];
  for (int i = 0; i < n; i++) {
    final v = pool[i % pool.length] + (i ~/ pool.length) * (max - min + 1);
    results.add(GameNumber(display: convertToBase(v, base), sortKey: v.toDouble()));
  }
  return results;
}

List<GameNumber> _fractions(
  int n, int numMin, int numMax, int denomMax, int base, Random rng) {
  if (numMin >= numMax) { numMin -= n; numMax += n; }
  final results = <GameNumber>[];
  final seen = <double>{};
  int attempts = 0;
  while (results.length < n && attempts < 2000) {
    attempts++;
    final range = numMax - numMin + 1;
    int num = numMin + rng.nextInt(range);
    int den = 1 + rng.nextInt(denomMax.clamp(1, 99));
    final g = _gcd(num.abs(), den);
    num ~/= g;
    den ~/= g;
    final key = num / den;
    if (seen.contains(key)) continue;
    seen.add(key);
    final disp = den == 1
        ? convertToBase(num, base)
        : '${convertToBase(num, base)}/${convertToBase(den, base)}';
    results.add(GameNumber(display: disp, sortKey: key));
  }
  // Fallback: pad with sequential integers
  while (results.length < n) {
    final v = results.length + 1;
    results.add(GameNumber(display: convertToBase(v, base), sortKey: v.toDouble()));
  }
  return results;
}

List<GameNumber> _reals(
  int n, double min, double max, int decimalPlaces, bool includeConstants, Random rng) {
  if (min >= max) { min -= n; max += n; }
  final results = <GameNumber>[];
  final seen = <String>{};

  if (includeConstants) {
    final pool = List.of(kNamedConstants)..shuffle(rng);
    for (final c in pool) {
      if (results.length >= n) break;
      if (seen.contains(c.symbol)) continue;
      seen.add(c.symbol);
      results.add(GameNumber(display: c.symbol, sortKey: c.value));
    }
  }

  int attempts = 0;
  while (results.length < n && attempts < 2000) {
    attempts++;
    final v = min + rng.nextDouble() * (max - min);
    final disp = v.toStringAsFixed(decimalPlaces);
    if (seen.contains(disp)) continue;
    seen.add(disp);
    results.add(GameNumber(display: disp, sortKey: v));
  }
  return results;
}

// ── Vector/hypercomplex generators ───────────────────────────────────────────

List<GameNumber> _complex(int n, GameSettings s, Random rng) {
  final results = <GameNumber>[];
  final seen = <double>{};
  int attempts = 0;
  while (results.length < n && attempts < 2000) {
    attempts++;
    final a = _genCoeff(s.coefficientType, s.coeffMin, s.coeffMax, s.coeffDenomMax, s.base, s.numberCount, s.realDecimalPlaces, rng);
    final b = _genCoeff(s.coefficientType, s.coeffMin, s.coeffMax, s.coeffDenomMax, s.base, s.numberCount, s.realDecimalPlaces, rng);
    final mag = sqrt(a.value * a.value + b.value * b.value);
    final key = (mag * 10000).roundToDouble();
    if (seen.contains(key)) continue;
    seen.add(key);
    // Format: a+bi or a-bi
    results.add(GameNumber(
      display: '${a.display}${_su(b, 'i')}',
      sortKey: mag,
    ));
  }
  return results;
}

List<GameNumber> _quaternions(int n, GameSettings s, Random rng) {
  final results = <GameNumber>[];
  final seen = <double>{};
  int attempts = 0;
  while (results.length < n && attempts < 2000) {
    attempts++;
    final c = List.generate(4, (_) =>
        _genCoeff(s.coefficientType, s.coeffMin, s.coeffMax, s.coeffDenomMax, s.base, s.numberCount, s.realDecimalPlaces, rng));
    final mag = sqrt(c.fold(0.0, (sum, x) => sum + x.value * x.value));
    final key = (mag * 10000).roundToDouble();
    if (seen.contains(key)) continue;
    seen.add(key);
    // Two-line format:
    // a+bi
    // +cj+dk
    final line1 = '${c[0].display}${_su(c[1], 'i')}';
    final line2 = '${_su(c[2], 'j')}${_su(c[3], 'k')}';
    results.add(GameNumber(display: '$line1\n$line2', sortKey: mag));
  }
  return results;
}

List<GameNumber> _octonions(int n, GameSettings s, Random rng) {
  const units = ['', 'e₁', 'e₂', 'e₃', 'e₄', 'e₅', 'e₆', 'e₇'];
  final results = <GameNumber>[];
  final seen = <double>{};
  int attempts = 0;
  while (results.length < n && attempts < 2000) {
    attempts++;
    final c = List.generate(8, (_) =>
        _genCoeff(s.coefficientType, s.coeffMin, s.coeffMax, s.coeffDenomMax, s.base, s.numberCount, s.realDecimalPlaces, rng));
    final mag = sqrt(c.fold(0.0, (sum, x) => sum + x.value * x.value));
    final key = (mag * 10000).roundToDouble();
    if (seen.contains(key)) continue;
    seen.add(key);
    // Two-line format: 4 components each line
    final parts = [
      c[0].display, // first component no unit
      _su(c[1], units[1]),
      _su(c[2], units[2]),
      _su(c[3], units[3]),
      _su(c[4], units[4]),
      _su(c[5], units[5]),
      _su(c[6], units[6]),
      _su(c[7], units[7]),
    ];
    final line1 = parts.take(4).join('');
    final line2 = parts.skip(4).join('');
    results.add(GameNumber(display: '$line1\n$line2', sortKey: mag));
  }
  return results;
}

// ── Named mathematical constants ─────────────────────────────────────────────

const List<({String symbol, double value})> kNamedConstants = [
  (symbol: 'π',     value: 3.141592653589793),   // pi
  (symbol: 'e',     value: 2.718281828459045),   // Euler's number
  (symbol: 'φ',     value: 1.6180339887498948),  // golden ratio
  (symbol: 'τ',     value: 6.283185307179586),   // 2π
  (symbol: '√2',    value: 1.4142135623730951),
  (symbol: '√3',    value: 1.7320508075688772),
  (symbol: '√5',    value: 2.23606797749979),
  (symbol: '∛2',    value: 1.2599210498948732),
  (symbol: 'γ',     value: 0.5772156649015329),  // Euler–Mascheroni
  (symbol: 'G',     value: 0.9159655941772190),  // Catalan's constant
  (symbol: 'Ω',     value: 0.5671432904097838),  // omega constant
  (symbol: 'δ',     value: 4.6692016091029906),  // Feigenbaum δ
  (symbol: 'α',     value: 2.5029078750958926),  // Feigenbaum α
  (symbol: 'ζ(2)',  value: 1.6449340668482264),  // π²/6
  (symbol: 'ζ(3)',  value: 1.2020569031595942),  // Apéry's constant
  (symbol: 'ln 2',  value: 0.6931471805599453),
  (symbol: 'ln 3',  value: 1.0986122886681098),
  (symbol: '1/φ',   value: 0.6180339887498949),  // 1/golden ratio
  (symbol: 'π/2',   value: 1.5707963267948966),
  (symbol: 'π/4',   value: 0.7853981633974483),
  (symbol: 'e⁻¹',   value: 0.36787944117144233),
  (symbol: '√π',    value: 1.7724538509055159),
  (symbol: 'π²',    value: 9.869604401089358),
  (symbol: 'e²',    value: 7.38905609893065),
  (symbol: '²√e',   value: 1.6487212707001282),  // √e
];

// ── Base name map ─────────────────────────────────────────────────────────────

const Map<int, String> kBaseNames = {
  2:  'Binary',
  3:  'Ternary',
  4:  'Quaternary',
  5:  'Quinary',
  6:  'Senary',
  7:  'Septenary',
  8:  'Octal',
  9:  'Nonary',
  10: 'Decimal',
  11: 'Undecimal',
  12: 'Duodecimal',
  16: 'Hexadecimal',
  20: 'Vigesimal',
  32: 'Duotrigesimal',
  36: 'Hexatrigesimal',
};
