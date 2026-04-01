import 'package:flutter/material.dart';
import '../models/settings.dart';
import '../utils/number_utils.dart';

class SettingsScreen extends StatefulWidget {
  final GameSettings initial;
  const SettingsScreen({super.key, required this.initial});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late GameSettings _s;

  // Text controllers
  late TextEditingController _minCtrl, _maxCtrl;
  late TextEditingController _coeffMinCtrl, _coeffMaxCtrl;

  static const List<int> _bases = [2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 16, 20, 32, 36];

  @override
  void initState() {
    super.initState();
    _s = widget.initial;
    _minCtrl = TextEditingController(text: _s.randomMin.toString());
    _maxCtrl = TextEditingController(text: _s.randomMax.toString());
    _coeffMinCtrl = TextEditingController(text: _s.coeffMin.toString());
    _coeffMaxCtrl = TextEditingController(text: _s.coeffMax.toString());
  }

  @override
  void dispose() {
    _minCtrl.dispose();
    _maxCtrl.dispose();
    _coeffMinCtrl.dispose();
    _coeffMaxCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final minV = int.tryParse(_minCtrl.text) ?? _s.randomMin;
    final maxV = int.tryParse(_maxCtrl.text) ?? _s.randomMax;
    final cmV  = int.tryParse(_coeffMinCtrl.text) ?? _s.coeffMin;
    final cxV  = int.tryParse(_coeffMaxCtrl.text) ?? _s.coeffMax;
    final updated = _s.copyWith(
      randomMin: minV,
      randomMax: maxV > minV ? maxV : minV + 1,
      coeffMin: cmV,
      coeffMax: cxV > cmV ? cxV : cmV + 1,
    );
    updated.save();
    Navigator.of(context).pop(updated);
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0015),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFFFF6B9D), size: 20),
          onPressed: () => Navigator.of(context).pop(widget.initial),
        ),
        title: ShaderMask(
          shaderCallback: (b) => const LinearGradient(
            colors: [Color(0xFFFF6B9D), Color(0xFFB44FDE)],
          ).createShader(b),
          child: const Text('Settings',
              style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w800, fontSize: 22)),
        ),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('Save',
                style: TextStyle(
                    color: Color(0xFFFF6B9D),
                    fontWeight: FontWeight.w700,
                    fontSize: 16)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        children: [
          _section('COUNT'),
          _card(_countSlider()),
          const SizedBox(height: 14),
          _section('NUMBER TYPE'),
          _card(_numberTypeGrid()),
          const SizedBox(height: 14),
          ..._typeSpecificSettings(),
          const SizedBox(height: 14),
          _section('PROGRESSION'),
          _card(_autoLevelRow()),
          if (_s.autoLevel) ...[
            const SizedBox(height: 10),
            _card(_streakSlider()),
          ],
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ── Count ─────────────────────────────────────────────────────────────────

  Widget _countSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Number of tiles', style: _kLabel),
            _badge('${_s.numberCount}'),
          ],
        ),
        Slider(
          value: _s.numberCount.toDouble(),
          min: 3, max: 20, divisions: 17,
          activeColor: const Color(0xFFFF6B9D),
          inactiveColor: const Color(0xFF4A1060),
          onChanged: (v) => setState(() => _s = _s.copyWith(numberCount: v.round())),
        ),
      ],
    );
  }

  // ── Number type grid ──────────────────────────────────────────────────────

  static const _typeLabels = {
    NumberType.sequential:    ('1→n', 'Sequential'),
    NumberType.randomInteger: ('ℤ', 'Integer'),
    NumberType.fraction:      ('p/q', 'Fraction'),
    NumberType.real:          ('ℝ', 'Real'),
    NumberType.complex:       ('ℂ', 'Complex'),
    NumberType.quaternion:    ('ℍ', 'Quaternion'),
    NumberType.octonion:      ('𝕆', 'Octonion'),
  };

  Widget _numberTypeGrid() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: NumberType.values.map((t) {
        final info = _typeLabels[t]!;
        return _typeChip(
          symbol: info.$1,
          name: info.$2,
          selected: _s.numberType == t,
          onTap: () => setState(() => _s = _s.copyWith(numberType: t)),
        );
      }).toList(),
    );
  }

  // ── Type-specific settings ────────────────────────────────────────────────

  List<Widget> _typeSpecificSettings() {
    switch (_s.numberType) {
      case NumberType.sequential:
        return [
          _section('DISPLAY BASE'),
          _card(_baseSelector()),
        ];

      case NumberType.randomInteger:
        return [
          _section('RANGE'),
          _card(_rangeRow(_minCtrl, _maxCtrl, signed: true)),
          const SizedBox(height: 10),
          _section('DISPLAY BASE'),
          _card(_baseSelector()),
        ];

      case NumberType.fraction:
        return [
          _section('NUMERATOR RANGE'),
          _card(_rangeRow(_minCtrl, _maxCtrl, signed: true)),
          const SizedBox(height: 10),
          _section('DENOMINATOR MAX'),
          _card(_denomSlider()),
          const SizedBox(height: 10),
          _section('DISPLAY BASE'),
          _card(_baseSelector()),
        ];

      case NumberType.real:
        return [
          _section('RANGE'),
          _card(_rangeRow(_minCtrl, _maxCtrl, signed: true)),
          const SizedBox(height: 10),
          _section('DECIMAL PLACES'),
          _card(_decimalPlacesSlider()),
          const SizedBox(height: 10),
          _section('NAMED CONSTANTS'),
          _card(_namedConstantsRow()),
        ];

      case NumberType.complex:
      case NumberType.quaternion:
      case NumberType.octonion:
        return _hyperComplexSettings();
    }
  }

  Widget _decimalPlacesSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Decimal places', style: _kLabel),
            _badge('${_s.realDecimalPlaces}'),
          ],
        ),
        Slider(
          value: _s.realDecimalPlaces.toDouble(),
          min: 1, max: 15, divisions: 14,
          activeColor: const Color(0xFFFF6B9D),
          inactiveColor: const Color(0xFF4A1060),
          onChanged: (v) =>
              setState(() => _s = _s.copyWith(realDecimalPlaces: v.round())),
        ),
      ],
    );
  }

  Widget _namedConstantsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Include named constants', style: _kLabel),
              Text(
                'Mix in π, e, φ, δ, γ, √2, ζ(3)…',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4), fontSize: 12),
              ),
            ],
          ),
        ),
        Switch(
          value: _s.includeNamedConstants,
          activeThumbColor: const Color(0xFFFF6B9D),
          activeTrackColor: const Color(0xFF4A1060),
          inactiveThumbColor: Colors.grey.shade600,
          inactiveTrackColor: Colors.grey.shade900,
          onChanged: (v) =>
              setState(() => _s = _s.copyWith(includeNamedConstants: v)),
        ),
      ],
    );
  }

  List<Widget> _hyperComplexSettings() {
    final typeName = switch (_s.numberType) {
      NumberType.complex    => 'Complex',
      NumberType.quaternion => 'Quaternion',
      _ => 'Octonion',
    };
    return [
      _section('$typeName — COEFFICIENT TYPE'),
      _card(_coeffTypeChips()),
      const SizedBox(height: 10),
      _section('COEFFICIENT RANGE'),
      _card(_rangeRow(_coeffMinCtrl, _coeffMaxCtrl, signed: true)),
      if (_s.coefficientType == CoefficientType.fraction) ...[
        const SizedBox(height: 10),
        _section('COEFFICIENT DENOMINATOR MAX'),
        _card(_coeffDenomSlider()),
      ],
      if (_s.coefficientType != CoefficientType.real) ...[
        const SizedBox(height: 10),
        _section('COEFFICIENT BASE'),
        _card(_baseSelector()),
      ],
    ];
  }

  // ── Coefficient type chips ────────────────────────────────────────────────

  static const _coeffLabels = {
    CoefficientType.sequential:    ('1..n', 'Sequential\n(1 to count)'),
    CoefficientType.randomInteger: ('ℤ', 'Random\nInteger'),
    CoefficientType.fraction:      ('p/q', 'Random\nFraction'),
    CoefficientType.real:          ('ℝ', 'Random\nReal'),
  };

  Widget _coeffTypeChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: CoefficientType.values.map((t) {
        final info = _coeffLabels[t]!;
        return _typeChip(
          symbol: info.$1,
          name: info.$2,
          selected: _s.coefficientType == t,
          onTap: () => setState(() => _s = _s.copyWith(coefficientType: t)),
        );
      }).toList(),
    );
  }

  // ── Range row ─────────────────────────────────────────────────────────────

  Widget _rangeRow(TextEditingController minC, TextEditingController maxC,
      {bool signed = false}) {
    return Row(
      children: [
        Expanded(child: _textField(minC, 'Min', signed: signed)),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: Text('→', style: TextStyle(color: Color(0xFFFF6B9D), fontSize: 18)),
        ),
        Expanded(child: _textField(maxC, 'Max', signed: signed)),
      ],
    );
  }

  // ── Denom sliders ─────────────────────────────────────────────────────────

  Widget _denomSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Max denominator', style: _kLabel),
            _badge('${_s.denominatorMax}'),
          ],
        ),
        Slider(
          value: _s.denominatorMax.toDouble(),
          min: 2, max: 99, divisions: 97,
          activeColor: const Color(0xFFFF6B9D),
          inactiveColor: const Color(0xFF4A1060),
          onChanged: (v) => setState(() => _s = _s.copyWith(denominatorMax: v.round())),
        ),
      ],
    );
  }

  Widget _coeffDenomSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Max denominator', style: _kLabel),
            _badge('${_s.coeffDenomMax}'),
          ],
        ),
        Slider(
          value: _s.coeffDenomMax.toDouble(),
          min: 2, max: 99, divisions: 97,
          activeColor: const Color(0xFFFF6B9D),
          inactiveColor: const Color(0xFF4A1060),
          onChanged: (v) => setState(() => _s = _s.copyWith(coeffDenomMax: v.round())),
        ),
      ],
    );
  }

  // ── Base selector ─────────────────────────────────────────────────────────

  Widget _baseSelector() {
    return Wrap(
      spacing: 7,
      runSpacing: 7,
      children: _bases.map((base) {
        final name = kBaseNames[base] ?? 'Base $base';
        final selected = _s.base == base;
        return GestureDetector(
          onTap: () => setState(() => _s = _s.copyWith(base: base)),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: selected
                  ? const LinearGradient(
                      colors: [Color(0xFFFF6B9D), Color(0xFFB44FDE)])
                  : null,
              color: selected ? null : const Color(0xFF2A0840),
              border: Border.all(
                color: selected
                    ? Colors.transparent
                    : const Color(0xFFFF6B9D).withValues(alpha: 0.22),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('$base',
                    style: TextStyle(
                        color: selected
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.75),
                        fontSize: 13,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w500)),
                Text(name,
                    style: TextStyle(
                        color: selected
                            ? Colors.white.withValues(alpha: 0.85)
                            : Colors.white.withValues(alpha: 0.38),
                        fontSize: 9)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Progression ───────────────────────────────────────────────────────────

  Widget _autoLevelRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Auto-Level', style: _kLabel),
              Text(
                'Increase count every ${_s.streakThreshold} wins',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4), fontSize: 12),
              ),
            ],
          ),
        ),
        Switch(
          value: _s.autoLevel,
          activeThumbColor: const Color(0xFFFF6B9D),
          activeTrackColor: const Color(0xFF4A1060),
          inactiveThumbColor: Colors.grey.shade600,
          inactiveTrackColor: Colors.grey.shade900,
          onChanged: (v) => setState(() => _s = _s.copyWith(autoLevel: v)),
        ),
      ],
    );
  }

  Widget _streakSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Wins per level', style: _kLabel),
            _badge('${_s.streakThreshold}'),
          ],
        ),
        Slider(
          value: _s.streakThreshold.toDouble(),
          min: 1, max: 10, divisions: 9,
          activeColor: const Color(0xFFFF6B9D),
          inactiveColor: const Color(0xFF4A1060),
          onChanged: (v) => setState(() => _s = _s.copyWith(streakThreshold: v.round())),
        ),
      ],
    );
  }

  // ── Shared widget builders ────────────────────────────────────────────────

  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title,
          style: TextStyle(
              color: const Color(0xFFFF6B9D).withValues(alpha: 0.75),
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 2)),
    );
  }

  Widget _card(Widget child) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A0530),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: const Color(0xFFFF6B9D).withValues(alpha: 0.13)),
      ),
      child: child,
    );
  }

  Widget _badge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
            colors: [Color(0xFFFF6B9D), Color(0xFFB44FDE)]),
      ),
      child: Text(text,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
    );
  }

  Widget _typeChip({
    required String symbol,
    required String name,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: selected
              ? const LinearGradient(
                  colors: [Color(0xFFFF6B9D), Color(0xFFB44FDE)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight)
              : null,
          color: selected ? null : const Color(0xFF2A0840),
          border: Border.all(
            color: selected
                ? Colors.transparent
                : const Color(0xFFFF6B9D).withValues(alpha: 0.22),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(symbol,
                style: TextStyle(
                    color: selected ? Colors.white : Colors.white.withValues(alpha: 0.85),
                    fontSize: 16,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(name,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: selected
                        ? Colors.white.withValues(alpha: 0.9)
                        : Colors.white.withValues(alpha: 0.45),
                    fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _textField(TextEditingController ctrl, String label,
      {bool signed = false}) {
    return TextField(
      controller: ctrl,
      keyboardType:
          TextInputType.numberWithOptions(signed: signed, decimal: false),
      style: const TextStyle(color: Colors.white, fontSize: 15),
      textAlign: TextAlign.center,
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 12),
        filled: true,
        fillColor: const Color(0xFF2A0840),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              BorderSide(color: const Color(0xFFFF6B9D).withValues(alpha: 0.28)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFFF6B9D)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              BorderSide(color: const Color(0xFFFF6B9D).withValues(alpha: 0.22)),
        ),
      ),
    );
  }
}

const _kLabel = TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600);
