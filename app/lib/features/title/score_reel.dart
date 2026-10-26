import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/format.dart';

/// The score picker: a strip of film pulled through a gate. Frames run from
/// 1 to 10 in steps of 0.5; whatever stands in the gate — outlined in red,
/// the editor's grease pencil — is the score. Each step clicks.
///
/// The strip starts with a blank leader frame: an unrated title starts there
/// rather than on a default score, which would nudge the choice.
class ScoreReel extends StatefulWidget {
  const ScoreReel({super.key, this.initialScoreHalf, required this.onChanged});

  /// 2…20; `null` — start on the leader.
  final int? initialScoreHalf;

  /// The score now in the gate; `null` on the leader.
  final ValueChanged<int?> onChanged;

  /// Frame width including its share of the strip.
  static const extent = 64.0;
  static const height = 116.0;

  @override
  State<ScoreReel> createState() => _ScoreReelState();
}

class _ScoreReelState extends State<ScoreReel> {
  /// 0 is the leader, 1…19 are the scores 1…10.
  static const _count = 20;

  late int _index = _indexOf(widget.initialScoreHalf);
  late final _controller = ScrollController(
    initialScrollOffset: _index * ScoreReel.extent,
  )..addListener(_moved);

  static int _indexOf(int? half) => half == null ? 0 : half - 1;
  static int? _halfAt(int index) => index == 0 ? null : index + 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _moved() {
    final index = (_controller.offset / ScoreReel.extent).round().clamp(
      0,
      _count - 1,
    );
    if (index == _index) return;
    HapticFeedback.selectionClick();
    setState(() => _index = index);
    widget.onChanged(_halfAt(index));
  }

  void _goTo(int index) => _controller.animateTo(
    index.clamp(0, _count - 1) * ScoreReel.extent,
    duration: const Duration(milliseconds: 220),
    curve: Curves.easeOutCubic,
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final half = _halfAt(_index);
    return Semantics(
      slider: true,
      label: l10n.ratingEditorTitle,
      value: half == null ? '—' : formatMyScore(half),
      // From the leader, "increase" lands on 1; nothing goes below 1 or
      // back onto the leader.
      increasedValue: _index < _count - 1 ? formatMyScore(_index + 2) : null,
      decreasedValue: _index > 1 ? formatMyScore(_index) : null,
      onIncrease: _index < _count - 1 ? () => _goTo(_index + 1) : null,
      onDecrease: _index > 1 ? () => _goTo(_index - 1) : null,
      child: SizedBox(
        height: ScoreReel.height,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final side = (constraints.maxWidth - ScoreReel.extent) / 2;
            return Stack(
              children: [
                // The strip fades out at the edges of the table.
                ShaderMask(
                  blendMode: BlendMode.dstIn,
                  shaderCallback: (rect) => const LinearGradient(
                    colors: [
                      Color(0x00000000),
                      Color(0xFF000000),
                      Color(0xFF000000),
                      Color(0x00000000),
                    ],
                    stops: [0, 0.18, 0.82, 1],
                  ).createShader(rect),
                  child: ListView.builder(
                    controller: _controller,
                    scrollDirection: Axis.horizontal,
                    physics: const _FramePhysics(),
                    itemExtent: ScoreReel.extent,
                    padding: EdgeInsets.symmetric(horizontal: side),
                    itemCount: _count,
                    itemBuilder: (context, index) => GestureDetector(
                      onTap: () => _goTo(index),
                      child: _Frame(
                        half: _halfAt(index),
                        inGate: index == _index,
                      ),
                    ),
                  ),
                ),
                const IgnorePointer(child: Center(child: _Gate())),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// One frame with its stretch of film: perforations above and below.
class _Frame extends StatelessWidget {
  const _Frame({required this.half, required this.inGate});

  final int? half;
  final bool inGate;

  @override
  Widget build(BuildContext context) {
    final reel = Reel.of(context);
    final theme = Theme.of(context);
    final half = this.half;
    final whole = half != null && half.isEven;
    final style =
        (whole ? theme.textTheme.displaySmall : theme.textTheme.headlineSmall)
            ?.copyWith(
              color: inGate ? theme.colorScheme.primary : reel.onFrame,
              fontWeight: FontWeight.w800,
            );
    return CustomPaint(
      painter: _StripPainter(strip: reel.strip, sprocket: reel.sprocket),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 22, 4, 22),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          decoration: BoxDecoration(
            color: inGate ? reel.gate : reel.frame,
            borderRadius: BorderRadius.circular(4),
          ),
          alignment: Alignment.center,
          child: Text(half == null ? '—' : formatMyScore(half), style: style),
        ),
      ),
    );
  }
}

/// The film base and its perforations: four holes per frame along each
/// edge, spaced so that neighbouring frames tile into one strip.
class _StripPainter extends CustomPainter {
  const _StripPainter({required this.strip, required this.sprocket});

  final Color strip;
  final Color sprocket;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = strip);
    final hole = Paint()..color = sprocket;
    const holes = 4;
    final step = size.width / holes;
    for (var i = 0; i < holes; i++) {
      final x = step * i + step / 2;
      for (final y in [11.0, size.height - 11]) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(x, y), width: 8, height: 7),
            const Radius.circular(1.5),
          ),
          hole,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_StripPainter old) =>
      old.strip != strip || old.sprocket != sprocket;
}

/// The grease-pencil box around the frame in the gate.
class _Gate extends StatelessWidget {
  const _Gate();

  @override
  Widget build(BuildContext context) => Container(
    width: ScoreReel.extent + 4,
    height: ScoreReel.height - 30,
    decoration: BoxDecoration(
      border: Border.all(
        color: Theme.of(context).colorScheme.primary,
        width: 2.5,
      ),
      borderRadius: BorderRadius.circular(7),
    ),
  );
}

/// Lands the strip on a whole frame, carrying the fling's momentum to the
/// nearest frame where it would have stopped.
class _FramePhysics extends ScrollPhysics {
  const _FramePhysics({super.parent});

  @override
  _FramePhysics applyTo(ScrollPhysics? ancestor) =>
      _FramePhysics(parent: buildParent(ancestor));

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    final tolerance = toleranceFor(position);
    final free = ClampingScrollSimulation(
      position: position.pixels,
      velocity: velocity,
      tolerance: tolerance,
    );
    final landing = free.x(double.infinity);
    final target = ((landing / ScoreReel.extent).round() * ScoreReel.extent)
        .clamp(position.minScrollExtent, position.maxScrollExtent);
    if ((target - position.pixels).abs() < tolerance.distance &&
        velocity.abs() < tolerance.velocity) {
      return null;
    }
    return ScrollSpringSimulation(
      SpringDescription.withDampingRatio(mass: 0.5, stiffness: 120, ratio: 1),
      position.pixels,
      target,
      velocity,
      tolerance: tolerance,
    );
  }
}
