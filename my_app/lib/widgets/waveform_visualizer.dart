import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../constants.dart';

class WaveformVisualizer extends StatefulWidget {
  final bool isActive;
  final Color activeColor;
  final Color inactiveColor;
  final int barCount;
  final double maxHeight;
  final double barWidth;

  const WaveformVisualizer({
    super.key,
    required this.isActive,
    this.activeColor = AppColors.accent,
    this.inactiveColor = const Color(0xFFB0BEC5),
    this.barCount = 9,
    this.maxHeight = 44.0,
    this.barWidth = 5.0,
  });

  @override
  State<WaveformVisualizer> createState() => _WaveformVisualizerState();
}

class _WaveformVisualizerState extends State<WaveformVisualizer> {
  late Timer _timer;
  final Random _rng = Random();
  final double _minHeight = 5.0;
  late List<double> _heights;

  @override
  void initState() {
    super.initState();
    _heights = List.filled(widget.barCount, _minHeight);
    _timer = Timer.periodic(const Duration(milliseconds: 90), (_) {
      if (!mounted) return;
      setState(() {
        if (widget.isActive) {
          _heights = List.generate(widget.barCount, (i) {
            // Centre bars taller for a natural wave look
            final centre = (widget.barCount - 1) / 2;
            final proximity = 1 - (i - centre).abs() / centre;
            final max = _minHeight +
                (widget.maxHeight - _minHeight) * (0.3 + proximity * 0.7);
            return _minHeight + _rng.nextDouble() * (max - _minHeight);
          });
        } else {
          _heights = List.filled(widget.barCount, _minHeight);
        }
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: List.generate(widget.barCount, (i) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 90),
          curve: Curves.easeInOut,
          margin: EdgeInsets.symmetric(horizontal: widget.barWidth * 0.4),
          width: widget.barWidth,
          height: _heights[i],
          decoration: BoxDecoration(
            color: widget.isActive
                ? widget.activeColor
                : widget.inactiveColor.withOpacity(0.5),
            borderRadius: BorderRadius.circular(widget.barWidth),
          ),
        );
      }),
    );
  }
}