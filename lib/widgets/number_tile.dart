import 'dart:math';
import 'package:flutter/material.dart';

// 12 feminine gradient pairs (pink → purple spectrum)
const List<List<Color>> kFeminineGradients = [
  [Color(0xFFFF6B9D), Color(0xFFB44FDE)],
  [Color(0xFFF72585), Color(0xFF560BAD)],
  [Color(0xFFFF85A1), Color(0xFFCC5FB4)],
  [Color(0xFFFF9A9E), Color(0xFFA855F7)],
  [Color(0xFFFFB3D1), Color(0xFF9C27B0)],
  [Color(0xFFF48FB1), Color(0xFF7209B7)],
  [Color(0xFFE91E8C), Color(0xFF6A0572)],
  [Color(0xFFFF69B4), Color(0xFF8B0057)],
  [Color(0xFFDDA0DD), Color(0xFF800080)],
  [Color(0xFFFFB6C1), Color(0xFF9B2D7A)],
  [Color(0xFFC71585), Color(0xFF6B1D8B)],
  [Color(0xFFFF1493), Color(0xFF4B0082)],
];

double _computeFontSize(String label) {
  final lines = label.split('\n');
  final maxLen = lines.map((l) => l.length).fold(0, max);
  if (lines.length >= 2 && maxLen >= 22) return 11;
  if (lines.length >= 2 && maxLen >= 16) return 13;
  if (lines.length >= 2) return 15;
  if (maxLen >= 16) return 16;
  if (maxLen >= 10) return 22;
  if (maxLen >= 7) return 28;
  if (maxLen >= 5) return 34;
  if (maxLen >= 4) return 40;
  return 46;
}

class NumberTile extends StatelessWidget {
  final String label;
  final int gradientIndex;
  final bool tapped;
  final bool showNumber;
  final bool shaking;
  final Animation<double>? shakeAnimation;
  final VoidCallback onTap;

  const NumberTile({
    super.key,
    required this.label,
    required this.gradientIndex,
    required this.tapped,
    required this.showNumber,
    required this.shaking,
    this.shakeAnimation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = kFeminineGradients[gradientIndex % kFeminineGradients.length];
    final fontSize = _computeFontSize(label);
    final multiLine = label.contains('\n');

    Widget tile = GestureDetector(
      onTap: tapped ? null : onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: tapped ? 0.38 : 1.0,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: tapped
                  ? [Colors.grey.shade600, Colors.grey.shade800]
                  : colors,
            ),
            boxShadow: tapped
                ? []
                : [
                    BoxShadow(
                      color: colors[0].withValues(alpha: 0.55),
                      blurRadius: 14,
                      spreadRadius: 1,
                      offset: const Offset(0, 3),
                    ),
                    BoxShadow(
                      color: colors[1].withValues(alpha: 0.30),
                      blurRadius: 24,
                      spreadRadius: 0,
                      offset: const Offset(0, 6),
                    ),
                  ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Glossy highlight
              if (!tapped)
                Positioned(
                  top: 5,
                  left: 8,
                  right: 8,
                  child: Container(
                    height: 14,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.32),
                          Colors.white.withValues(alpha: 0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
              // Number label
              if (showNumber)
                Padding(
                  padding: const EdgeInsets.all(6),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: tapped ? Colors.grey.shade500 : Colors.white,
                        fontSize: fontSize,
                        fontWeight: FontWeight.w700,
                        letterSpacing: multiLine ? 0.4 : 1.2,
                        height: multiLine ? 1.35 : 1.0,
                        shadows: tapped
                            ? []
                            : [
                                Shadow(
                                  color: Colors.black.withValues(alpha: 0.30),
                                  blurRadius: 4,
                                  offset: const Offset(1, 2),
                                ),
                              ],
                      ),
                    ),
                  ),
                ),
              // Checkmark on correct tap
              if (tapped)
                Icon(
                  Icons.check_rounded,
                  color: Colors.white.withValues(alpha: 0.4),
                  size: 30,
                ),
            ],
          ),
        ),
      ),
    );

    if (shaking && shakeAnimation != null) {
      tile = AnimatedBuilder(
        animation: shakeAnimation!,
        builder: (context, child) {
          final offset = sin(shakeAnimation!.value * pi * 6) * 10.0;
          return Transform.translate(
            offset: Offset(offset, 0),
            child: child,
          );
        },
        child: tile,
      );
    }

    return tile;
  }
}
