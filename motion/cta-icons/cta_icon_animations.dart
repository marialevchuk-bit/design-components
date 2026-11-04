// Hubby eSIM: animated icons for the three eSIM call-to-action buttons.
//
//   Activate your eSIM  -> download arrow drops into the tray and back into place
//   Set up your eSIM    -> toggle switches on, then off again
//   Connect eSIM        -> lightning bolt draws itself, charges and settles
//
// Button and motion values are 1:1 from the approved animation video; the only
// change is the typeface, GeneralSans. Reference implementation for the
// handoff: swap `_Cta` for the app's own theme classes where they exist.
// Prototype: motion/cta-icons/prototype.html in the design-components repo.

import 'dart:math' as math;
import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';

/// Values from the video.
class _Cta {
  static const fill = Color(0xFF0D112E);
  static const onFill = Color(0xFFFFFFFF);
  static const height = 52.0;
  static const radius = 10.0;
  static const iconSize = 20.0;
  static const iconGap = 12.0;
  static const shadow = [BoxShadow(color: Color(0x380D112E), offset: Offset(0, 4), blurRadius: 14)];
  static const label = TextStyle(
    fontFamily: 'GeneralSans',
    fontWeight: FontWeight.w500,
    fontSize: 18,
    height: 1.4,
    color: onFill,
  );
}

/// Loop timings from the video, in milliseconds.
class CtaIconMotion {
  // Each loop ends with about 3 seconds of stillness.
  // Download arrow: 4500ms loop, first run 1000ms after the button appears.
  static const downloadPeriod = 4500;
  static const downloadDelay = 1000;
  static const downloadOut = 380; // arrow sinks into the tray (easeInCubic)
  static const downloadInStart = 440; // re-enters from above
  static const downloadInEnd = 820; // lands 1 unit low (easeOutCubic)
  static const downloadSettle = 1060; // settles back to rest (easeInOut)

  // Toggle: 5200ms loop, first run 1000ms after the button appears.
  static const togglePeriod = 5200;
  static const toggleDelay = 1000;
  static const toggleSwitch = 400; // on and off both take 400ms
  static const toggleHoldOn = 1400;

  // Lightning: 5600ms loop, first run 1000ms after the button appears.
  static const zapPeriod = 5600;
  static const zapDelay = 1000;
  static const zapErase = 400; // stroke retracts from its start
  static const zapDrawStart = 750; // empty for 350ms
  static const zapDraw = 550; // stroke draws from the top point
  static const zapPulse1 = 1400; // two gentle "charge" pulses, scale to 1.04
  static const zapPulse2 = 2050;
  static const zapPulseHalf = 300; // up 300ms, down 300ms
}

enum CtaIcon { download, toggle, zap }

/// The dark eSIM call-to-action button with its animated icon.
class EsimCtaButton extends StatelessWidget {
  const EsimCtaButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.width,
  });

  final CtaIcon icon;
  final String label;
  final VoidCallback onPressed;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final Widget glyph = switch (icon) {
      CtaIcon.download => const DownloadDropIcon(),
      CtaIcon.toggle => const ToggleSwitchIcon(),
      CtaIcon.zap => const ZapChargeIcon(),
    };
    return Container(
      width: width,
      height: _Cta.height,
      decoration: BoxDecoration(
        color: _Cta.fill,
        borderRadius: BorderRadius.circular(_Cta.radius),
        boxShadow: _Cta.shadow,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(_Cta.radius),
          onTap: onPressed,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              glyph,
              const SizedBox(width: _Cta.iconGap),
              Text(label, style: _Cta.label),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shared loop driver: a repeating controller over one period, started after
/// [delay]. With reduced motion it never starts and the icon stays at rest.
abstract class _LoopIconState<T extends StatefulWidget> extends State<T>
    with SingleTickerProviderStateMixin {
  int get period;
  int get delay;

  late final AnimationController _c =
      AnimationController(vsync: this, duration: Duration(milliseconds: period));
  bool _reduced = false;

  /// Milliseconds into the current loop.
  double get ms => _c.value * period;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduced = MediaQuery.disableAnimationsOf(context);
    if (reduced == _reduced && (_c.isAnimating || reduced)) return;
    _reduced = reduced;
    if (_reduced) {
      _c.stop();
      _c.value = 0;
    } else {
      Future.delayed(Duration(milliseconds: delay), () {
        if (mounted && !_reduced) _c.repeat();
      });
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  double seg(double t, num a, num b) => ((t - a) / (b - a)).clamp(0.0, 1.0);

  Widget paint(CustomPainter Function() painter) => AnimatedBuilder(
        animation: _c,
        builder: (_, __) => CustomPaint(
          size: const Size.square(_Cta.iconSize),
          painter: painter(),
        ),
      );
}

// ---------------------------------------------------------------------------
// Download: the arrow drops through the tray, then falls back into place.
// ---------------------------------------------------------------------------

class DownloadDropIcon extends StatefulWidget {
  const DownloadDropIcon({super.key});
  @override
  State<DownloadDropIcon> createState() => _DownloadDropIconState();
}

class _DownloadDropIconState extends _LoopIconState<DownloadDropIcon> {
  @override
  int get period => CtaIconMotion.downloadPeriod;
  @override
  int get delay => CtaIconMotion.downloadDelay;

  /// Arrow offset in 24-grid units, positive is down.
  double _offset(double t) {
    const m = CtaIconMotion;
    if (t < m.downloadOut) return 22 * Curves.easeInCubic.transform(seg(t, 0, m.downloadOut));
    if (t < m.downloadInStart) return 22;
    if (t < m.downloadInEnd) {
      return -16 + 17 * Curves.easeOutCubic.transform(seg(t, m.downloadInStart, m.downloadInEnd));
    }
    return 1 * (1 - Curves.easeInOut.transform(seg(t, m.downloadInEnd, m.downloadSettle)));
  }

  @override
  Widget build(BuildContext context) => paint(() => _DownloadPainter(_offset(ms)));
}

class _DownloadPainter extends CustomPainter {
  _DownloadPainter(this.offset);
  final double offset;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24;
    canvas.scale(s);
    final p = _stroke();
    canvas.drawLine(const Offset(5, 21), const Offset(19, 21), p); // tray
    // Arrow only shows in the window above the tray.
    canvas.save();
    canvas.clipRect(const Rect.fromLTRB(0, 0.7, 24, 19.2));
    canvas.translate(0, offset);
    canvas.drawLine(const Offset(12, 3), const Offset(12, 17), p);
    canvas.drawPath(
      Path()
        ..moveTo(6, 11)
        ..lineTo(12, 17)
        ..lineTo(18, 11),
      p,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_DownloadPainter old) => old.offset != offset;
}

// ---------------------------------------------------------------------------
// Toggle: switches on, holds, switches off, holds.
// ---------------------------------------------------------------------------

class ToggleSwitchIcon extends StatefulWidget {
  const ToggleSwitchIcon({super.key});
  @override
  State<ToggleSwitchIcon> createState() => _ToggleSwitchIconState();
}

class _ToggleSwitchIconState extends _LoopIconState<ToggleSwitchIcon> {
  @override
  int get period => CtaIconMotion.togglePeriod;
  @override
  int get delay => CtaIconMotion.toggleDelay;

  /// 0 = off, 1 = on. The off move is the on move played backwards.
  double _on(double t) {
    const m = CtaIconMotion;
    const offAt = m.toggleSwitch + m.toggleHoldOn;
    if (t < offAt) return Curves.fastOutSlowIn.transform(seg(t, 0, m.toggleSwitch));
    return Curves.fastOutSlowIn.transform(1 - seg(t, offAt, offAt + m.toggleSwitch));
  }

  @override
  Widget build(BuildContext context) => paint(() => _TogglePainter(_on(ms)));
}

class _TogglePainter extends CustomPainter {
  _TogglePainter(this.on);
  final double on;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24);
    final track = RRect.fromRectAndRadius(const Rect.fromLTWH(2, 6, 20, 12), const Radius.circular(6));
    // Track fill fades in from the button colour to white.
    canvas.drawRRect(track, Paint()..color = Color.lerp(_Cta.fill, _Cta.onFill, on)!);
    canvas.drawRRect(track, _stroke());
    // Knob slides right and turns from white to the button colour.
    canvas.drawCircle(
      Offset(8 + 8 * on, 12),
      3,
      Paint()..color = Color.lerp(_Cta.onFill, _Cta.fill, on)!,
    );
  }

  @override
  bool shouldRepaint(_TogglePainter old) => old.on != on;
}

// ---------------------------------------------------------------------------
// Lightning: the stroke retracts, redraws from the top, then pulses twice.
// ---------------------------------------------------------------------------

class ZapChargeIcon extends StatefulWidget {
  const ZapChargeIcon({super.key});
  @override
  State<ZapChargeIcon> createState() => _ZapChargeIconState();
}

class _ZapChargeIconState extends _LoopIconState<ZapChargeIcon> {
  @override
  int get period => CtaIconMotion.zapPeriod;
  @override
  int get delay => CtaIconMotion.zapDelay;

  @override
  Widget build(BuildContext context) => paint(() {
        const m = CtaIconMotion;
        final t = ms;
        // Visible part of the stroke, as fractions of its length.
        double from = 0, to = 1;
        if (t < m.zapErase) {
          from = Curves.easeInOut.transform(seg(t, 0, m.zapErase));
        } else if (t < m.zapDrawStart) {
          from = to = 0;
        } else {
          to = Curves.easeOutCubic.transform(seg(t, m.zapDrawStart, m.zapDrawStart + m.zapDraw));
        }
        double pulse(int at) {
          const h = m.zapPulseHalf;
          final up = Curves.easeOut.transform(seg(t, at, at + h));
          final down = Curves.easeInOut.transform(seg(t, at + h, at + 2 * h));
          return up - down;
        }

        final scale = 1 + 0.04 * math.max(pulse(m.zapPulse1), pulse(m.zapPulse2));
        return _ZapPainter(from, to, scale);
      });
}

class _ZapPainter extends CustomPainter {
  _ZapPainter(this.from, this.to, this.scale);
  final double from, to, scale;

  // Drawn from the top point: down-left, across, down to the tip, up-right, back.
  static final Path _bolt = Path()
    ..moveTo(13, 2)
    ..lineTo(3, 14)
    ..lineTo(12, 14)
    ..lineTo(11, 22)
    ..lineTo(21, 10)
    ..lineTo(12, 10)
    ..lineTo(13, 2);

  @override
  void paint(Canvas canvas, Size size) {
    if (to <= from) return;
    canvas.scale(size.width / 24);
    canvas.translate(12, 12);
    canvas.scale(scale);
    canvas.translate(-12, -12);
    final PathMetric metric = _bolt.computeMetrics().first;
    final part = metric.extractPath(metric.length * from, metric.length * to);
    canvas.drawPath(part, _stroke());
  }

  @override
  bool shouldRepaint(_ZapPainter old) => old.from != from || old.to != to || old.scale != scale;
}

Paint _stroke() => Paint()
  ..color = _Cta.onFill
  ..style = PaintingStyle.stroke
  ..strokeWidth = 2
  ..strokeCap = StrokeCap.round
  ..strokeJoin = StrokeJoin.round;

// Usage:
//
//   EsimCtaButton(icon: CtaIcon.download, label: 'Activate your eSIM', onPressed: ...)
//   EsimCtaButton(icon: CtaIcon.toggle,   label: 'Set up your eSIM',   onPressed: ...)
//   EsimCtaButton(icon: CtaIcon.zap,      label: 'Connect eSIM',       onPressed: ...)
