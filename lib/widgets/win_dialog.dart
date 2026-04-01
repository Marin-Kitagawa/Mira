import 'package:flutter/material.dart';

class WinDialog extends StatelessWidget {
  final int elapsedMs;
  final int bestMs;
  final int streak;
  final VoidCallback onPlayAgain;
  final VoidCallback onNo;

  const WinDialog({
    super.key,
    required this.elapsedMs,
    required this.bestMs,
    required this.streak,
    required this.onPlayAgain,
    required this.onNo,
  });

  String _formatTime(int ms) {
    if (ms < 1000) return '${ms}ms';
    final s = ms / 1000;
    return '${s.toStringAsFixed(1)}s';
  }

  @override
  Widget build(BuildContext context) {
    final isNewBest = bestMs == elapsedMs;
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A0530), Color(0xFF0D001A)],
          ),
          border: Border.all(
            color: const Color(0xFFFF6B9D).withValues(alpha: 0.4),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFB44FDE).withValues(alpha: 0.3),
              blurRadius: 40,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Win header
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xFFFF6B9D), Color(0xFFB44FDE)],
              ).createShader(bounds),
              child: Text(
                '🎉 You Win!',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 28,
                    ),
              ),
            ),
            const SizedBox(height: 8),
            // Streak
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('🔥', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 6),
                Text(
                  'Streak: $streak',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Divider
            Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    const Color(0xFFFF6B9D).withValues(alpha: 0.6),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Time info
            _StatRow(
              label: 'Time',
              value: _formatTime(elapsedMs),
              highlight: false,
            ),
            const SizedBox(height: 8),
            _StatRow(
              label: isNewBest ? '🏆 New Best!' : 'Best',
              value: bestMs == 0 ? '--' : _formatTime(bestMs),
              highlight: isNewBest,
            ),
            const SizedBox(height: 24),
            Text(
              'Ready to play again?',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 20),
            // Buttons
            Row(
              children: [
                Expanded(
                  child: _DialogButton(
                    label: 'NO',
                    onTap: onNo,
                    gradient: const [Color(0xFF4A1060), Color(0xFF2D0845)],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: _DialogButton(
                    label: 'YES ✨',
                    onTap: onPlayAgain,
                    gradient: const [Color(0xFFFF6B9D), Color(0xFFB44FDE)],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _StatRow({
    required this.label,
    required this.value,
    required this.highlight,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.65),
            fontSize: 15,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: highlight ? const Color(0xFFFF6B9D) : Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _DialogButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final List<Color> gradient;

  const _DialogButton({
    required this.label,
    required this.onTap,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: gradient.last.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 15,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}

// ── Game-over dialog ──────────────────────────────────────────────────────────

class GameOverDialog extends StatelessWidget {
  final int tappedCount;   // how many tiles were correctly tapped before the mistake
  final int totalCount;
  final VoidCallback onTryAgain;

  const GameOverDialog({
    super.key,
    required this.tappedCount,
    required this.totalCount,
    required this.onTryAgain,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A0010), Color(0xFF0D0008)],
          ),
          border: Border.all(
            color: const Color(0xFFFF2255).withValues(alpha: 0.5),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF2255).withValues(alpha: 0.25),
              blurRadius: 40,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('💔', style: TextStyle(fontSize: 44)),
            const SizedBox(height: 12),
            const Text(
              'Wrong tile!',
              style: TextStyle(
                color: Color(0xFFFF4477),
                fontSize: 26,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You got $tappedCount of $totalCount correct\nbefore your memory slipped.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.65),
                fontSize: 15,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Streak reset.',
              style: TextStyle(
                color: const Color(0xFFFF4477).withValues(alpha: 0.8),
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 28),
            _DialogButton(
              label: 'Try Again',
              onTap: onTryAgain,
              gradient: const [Color(0xFFFF2255), Color(0xFF7B003A)],
            ),
          ],
        ),
      ),
    );
  }
}
