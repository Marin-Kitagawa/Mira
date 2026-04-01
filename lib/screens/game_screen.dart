import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/settings.dart';
import '../utils/number_utils.dart';
import '../widgets/number_tile.dart';
import '../widgets/win_dialog.dart';
import 'settings_screen.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  // ── Settings & session ────────────────────────────────────────────────────
  GameSettings _settings = const GameSettings();
  bool _settingsLoaded = false;
  int _streak = 0;
  int _bestMs = 0;
  int _currentN = 9;

  // ── Tile data ─────────────────────────────────────────────────────────────
  List<GameNumber> _numbers = [];
  List<int> _correctOrder = [];
  List<int> _gradients = [];
  List<Offset> _positions = [];
  List<bool> _tapped = [];
  double _tileW = 88;
  double _tileH = 88;

  // ── Game state ────────────────────────────────────────────────────────────
  int _nextStep = 0;
  bool _numbersHidden = false;
  bool _gameOver = false;
  bool _tilesPlaced = false;

  // ── Timer ─────────────────────────────────────────────────────────────────
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _ticker;
  int _elapsedMs = 0;

  // ── Animations ────────────────────────────────────────────────────────────
  late AnimationController _shakeController;
  int _shakingTile = -1;
  late AnimationController _appearController;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    )..addStatusListener((s) {
        if (s == AnimationStatus.completed) {
          setState(() => _shakingTile = -1);
        }
      });
    _appearController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _loadSettingsAndStart();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _shakeController.dispose();
    _appearController.dispose();
    super.dispose();
  }

  // ── Setup ─────────────────────────────────────────────────────────────────

  Future<void> _loadSettingsAndStart() async {
    final s = await GameSettings.load();
    final best = await GameSettings.loadBestMs('main');
    if (!mounted) return;
    setState(() {
      _settings = s;
      _settingsLoaded = true;
      _bestMs = best;
      _currentN = s.numberCount;
    });
  }

  void _newGame({bool keepStreak = false, Size? size}) {
    _ticker?.cancel();
    _stopwatch.reset();
    _shakeController.reset();
    _appearController.reset();

    final rng = Random();
    final n = _currentN;
    final numbers = generateNumbers(_settings, rng, countOverride: n);
    numbers.shuffle(rng);

    final order = List.generate(n, (i) => i)
      ..sort((a, b) => numbers[a].sortKey.compareTo(numbers[b].sortKey));

    final startGrad = rng.nextInt(kFeminineGradients.length);
    final grads = List.generate(n, (i) => (startGrad + i) % kFeminineGradients.length)
      ..shuffle(rng);

    setState(() {
      _numbers = numbers;
      _correctOrder = order;
      _gradients = grads;
      _tapped = List.filled(n, false);
      _nextStep = 0;
      _numbersHidden = false;
      _gameOver = false;
      _elapsedMs = 0;
      _shakingTile = -1;
      if (!keepStreak) _streak = 0;

      if (size != null) {
        _placeTiles(size, n);
      } else {
        _tilesPlaced = false;
        _positions = [];
      }
    });

    if (size != null) {
      _appearController.forward(from: 0);
      _startTimer();
    }
  }

  // ── Tile placement ────────────────────────────────────────────────────────

  void _placeTiles(Size area, int n) {
    final dims = _computeTileDimensions(area, n, _settings.numberType);
    _tileW = dims.$1;
    _tileH = dims.$2;
    final marginX = _tileW * 0.12;
    final marginY = _tileH * 0.12;
    final positions = <Offset>[];
    final rng = Random();

    for (int i = 0; i < n; i++) {
      Offset? placed;
      for (int attempt = 0; attempt < 400; attempt++) {
        final x = marginX + rng.nextDouble() * (area.width - _tileW - marginX * 2);
        final y = marginY + rng.nextDouble() * (area.height - _tileH - marginY * 2);
        final candidate = Offset(x, y);
        if (_noOverlap(candidate, positions, _tileW, _tileH, marginX, marginY)) {
          placed = candidate;
          break;
        }
      }
      placed ??= _gridFallback(i, n, area, _tileW, _tileH, marginX, marginY);
      positions.add(placed);
    }

    _positions = positions;
    _tilesPlaced = true;
  }

  bool _noOverlap(Offset c, List<Offset> existing,
      double tw, double th, double mx, double my) {
    for (final p in existing) {
      if ((c.dx - p.dx).abs() < tw + mx && (c.dy - p.dy).abs() < th + my) {
        return false;
      }
    }
    return true;
  }

  Offset _gridFallback(int index, int n, Size area,
      double tw, double th, double mx, double my) {
    final cols = (area.width / (tw + mx)).floor().clamp(1, n);
    final col = index % cols;
    final row = index ~/ cols;
    final cellW = area.width / cols;
    final cellH = area.height / ((n / cols).ceil());
    return Offset(
      (col * cellW + mx).clamp(mx, area.width - tw - mx),
      (row * cellH + my).clamp(my, area.height - th - my),
    );
  }

  (double, double) _computeTileDimensions(Size area, int n, NumberType type) {
    // Density: fraction of screen area per tile
    final density = switch (type) {
      NumberType.octonion   => 0.08,
      NumberType.quaternion => 0.10,
      NumberType.complex    => 0.12,
      NumberType.fraction   => 0.14,
      _ => 0.16,
    };
    // Maximum tile size — smaller than before per user request
    final maxSize = switch (type) {
      NumberType.octonion   => 130.0,
      NumberType.quaternion => 115.0,
      NumberType.complex    => 100.0,
      _ => 82.0,
    };

    final targetArea = area.width * area.height * density / n;
    final side = sqrt(targetArea).clamp(52.0, maxSize);
    return (side, side);
  }

  // ── Timer ─────────────────────────────────────────────────────────────────

  void _startTimer() {
    _stopwatch.start();
    _ticker = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (mounted) setState(() => _elapsedMs = _stopwatch.elapsedMilliseconds);
    });
  }

  // ── Tap handling ──────────────────────────────────────────────────────────

  void _onTileTap(int tileIndex) {
    if (_gameOver || _tapped[tileIndex]) return;

    if (tileIndex == _correctOrder[_nextStep]) {
      setState(() {
        _tapped[tileIndex] = true;
        _nextStep++;
        if (_nextStep == 1) _numbersHidden = true;
      });
      if (_nextStep == _numbers.length) _onWin();
    } else {
      _onGameOver(wrongTile: tileIndex);
    }
  }

  void _onWin() {
    _ticker?.cancel();
    _stopwatch.stop();
    final elapsed = _stopwatch.elapsedMilliseconds;

    final newBest = _bestMs == 0 || elapsed < _bestMs;
    if (newBest) {
      _bestMs = elapsed;
      GameSettings.saveBestMs('main', elapsed);
    }

    setState(() {
      _gameOver = true;
      _elapsedMs = elapsed;
      _streak++;
    });

    if (_settings.autoLevel && _streak % _settings.streakThreshold == 0) {
      _currentN = (_currentN + 1).clamp(3, 20);
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (_) => WinDialog(
        elapsedMs: elapsed,
        bestMs: _bestMs,
        streak: _streak,
        onPlayAgain: () {
          Navigator.of(context).pop();
          if (_lastSize != null) _newGame(keepStreak: true, size: _lastSize);
        },
        onNo: () {
          Navigator.of(context).pop();
          setState(() => _streak = 0);
        },
      ),
    );
  }

  void _onGameOver({required int wrongTile}) {
    _ticker?.cancel();
    _stopwatch.stop();
    setState(() {
      _gameOver = true;
      _shakingTile = wrongTile;
      _streak = 0;
    });
    _shakeController.forward(from: 0).then((_) {
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black.withValues(alpha: 0.72),
        builder: (_) => GameOverDialog(
          tappedCount: _nextStep,
          totalCount: _numbers.length,
          onTryAgain: () {
            Navigator.of(context).pop();
            if (_lastSize != null) _newGame(size: _lastSize);
          },
        ),
      );
    });
  }

  // ── Layout ────────────────────────────────────────────────────────────────

  Size? _lastSize;

  void _onLayout(Size size) {
    if (_lastSize == size && _tilesPlaced) return;
    _lastSize = size;
    if (!_settingsLoaded) return;

    if (_numbers.isEmpty || !_tilesPlaced) {
      _newGame(size: size);
    } else {
      setState(() => _placeTiles(size, _numbers.length));
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _formatTime(int ms) =>
      ms < 1000 ? '${ms}ms' : '${(ms / 1000).toStringAsFixed(1)}s';

  bool get _isMagnitudeBased =>
      _settings.numberType == NumberType.complex ||
      _settings.numberType == NumberType.quaternion ||
      _settings.numberType == NumberType.octonion;

  Future<void> _openSettings() async {
    final result = await Navigator.of(context).push<GameSettings>(
      MaterialPageRoute(builder: (_) => SettingsScreen(initial: _settings)),
    );
    if (result != null && mounted) {
      setState(() {
        _settings = result;
        _currentN = result.numberCount;
        _streak = 0;
        _tilesPlaced = false;
      });
      if (_lastSize != null) _newGame(size: _lastSize);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080010),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFFFF6B9D), Color(0xFFB44FDE)],
          ).createShader(bounds),
          child: const Text(
            'Mira',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 24,
              letterSpacing: 1,
            ),
          ),
        ),
        centerTitle: false,
        actions: [
          if (_stopwatch.isRunning || _elapsedMs > 0)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: const Color(0xFF1A0530),
                    border: Border.all(
                        color: const Color(0xFFFF6B9D).withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    _formatTime(_elapsedMs),
                    style: const TextStyle(
                        color: Color(0xFFFF6B9D),
                        fontWeight: FontWeight.w700,
                        fontSize: 13),
                  ),
                ),
              ),
            ),
          if (_streak > 0)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: const LinearGradient(
                        colors: [Color(0xFFFF6B9D), Color(0xFFB44FDE)]),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🔥', style: TextStyle(fontSize: 11)),
                      const SizedBox(width: 3),
                      Text('$_streak',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFFB44FDE), size: 22),
            onPressed: () {
              setState(() => _streak = 0);
              if (_lastSize != null) _newGame(size: _lastSize);
            },
            tooltip: 'New game',
          ),
          IconButton(
            icon: const Icon(Icons.tune_rounded, color: Color(0xFFFF6B9D), size: 22),
            onPressed: _openSettings,
            tooltip: 'Settings',
          ),
        ],
      ),
      // Full screen – no width cap; spreading adapts to any screen size
      body: Column(
        children: [
          _buildProgressBar(),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final size = Size(constraints.maxWidth, constraints.maxHeight);
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _onLayout(size);
                });
                return _buildGameArea(size);
              },
            ),
          ),
          _buildBottomHint(),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    final progress = _numbers.isEmpty ? 0.0 : _nextStep / _numbers.length;
    return SizedBox(
      height: 3,
      child: FractionallySizedBox(
        widthFactor: progress,
        alignment: Alignment.centerLeft,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFF6B9D), Color(0xFFB44FDE)],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGameArea(Size size) {
    if (!_settingsLoaded || !_tilesPlaced || _positions.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFFF6B9D), strokeWidth: 2),
      );
    }

    return Stack(
      children: [
        Positioned.fill(child: CustomPaint(painter: _AmbientGlowPainter())),
        ...List.generate(_numbers.length, (i) {
          final pos = _positions[i];
          return Positioned(
            left: pos.dx,
            top: pos.dy,
            width: _tileW,
            height: _tileH,
            child: AnimatedBuilder(
              animation: _appearController,
              builder: (ctx, child) {
                final delay = (i / _numbers.length) * 0.55;
                final t = ((_appearController.value - delay) / 0.45).clamp(0.0, 1.0);
                final curve = Curves.easeOutBack.transform(t);
                return Transform.scale(
                  scale: curve,
                  child: Opacity(opacity: t.clamp(0.0, 1.0), child: child),
                );
              },
              child: NumberTile(
                label: _numbers[i].display,
                gradientIndex: _gradients[i],
                tapped: _tapped[i],
                showNumber: !_numbersHidden || _tapped[i],
                shaking: _shakingTile == i,
                shakeAnimation: _shakingTile == i ? _shakeController : null,
                onTap: () => _onTileTap(i),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildBottomHint() {
    if (_numbers.isEmpty) return const SizedBox.shrink();
    final remaining = _numbers.length - _nextStep;

    final String hint;
    if (!_numbersHidden) {
      hint = _isMagnitudeBased
          ? 'Memorise magnitudes, tap smallest |z| first'
          : 'Memorise, then tap smallest first';
    } else {
      hint = _isMagnitudeBased ? 'Recall magnitudes 🧠' : 'Recall from memory 🧠';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(hint,
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.35), fontSize: 11)),
          ),
          const SizedBox(width: 8),
          Text('$remaining left',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.35), fontSize: 11)),
        ],
      ),
    );
  }
}

class _AmbientGlowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    paint.shader = RadialGradient(
      center: const Alignment(-0.6, -0.4),
      radius: 0.7,
      colors: [
        const Color(0xFFB44FDE).withValues(alpha: 0.07),
        Colors.transparent,
      ],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    paint.shader = RadialGradient(
      center: const Alignment(0.7, 0.6),
      radius: 0.6,
      colors: [
        const Color(0xFFFF6B9D).withValues(alpha: 0.06),
        Colors.transparent,
      ],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(_AmbientGlowPainter _) => false;
}
