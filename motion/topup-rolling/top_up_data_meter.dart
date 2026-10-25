// Hubby eSIM: top-up rolling counter on the eSIM plan card.
//
// When a top-up lands on a plan card, the balance rolls once from the old
// value to the new one, odometer style. The data meter fills along with the
// roll, a second digit slides in when the balance passes 9, and the
// "/ 3 GB" total cross-fades to the new total as the roll settles.
//
// Card measurements and motion are 1:1 from the approved animation film; the
// only change is the typeface, GeneralSans. Reference implementation for the
// handoff: swap `_Card` for the app's own theme classes where they exist.
// Prototype: motion/topup-rolling/prototype.html in the design-components repo.

import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

/// Card values, 1:1 from the film.
class _Card {
  static const main = Color(0xFF0A0F24);
  static const muted = Color(0xFF6B7280);
  static const border = Color(0xFFA9DCC5);
  static const track = Color(0xFFE5E7EB);

  static const font = 'GeneralSans';
  static const numberSize = 72.0;
  static const lineH = 76.0;
  static const digitW = numberSize * 0.6; // 43.2: one slot per digit

  static const number = TextStyle(
    fontFamily: font,
    fontWeight: FontWeight.w600, // film: 800; GeneralSans is bundled at 400/500/600
    fontSize: numberSize,
    height: lineH / numberSize,
    color: main,
    fontFeatures: [FontFeature.tabularFigures()],
  );
  static const total = TextStyle(fontFamily: font, fontSize: 28, height: 1, color: main);
  static const name = TextStyle(
      fontFamily: font, fontSize: 30, fontWeight: FontWeight.w600, letterSpacing: -0.3, color: main);
  static const sub = TextStyle(fontFamily: font, fontSize: 21, color: muted);
  static const link = TextStyle(
    fontFamily: font,
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: main,
    decoration: TextDecoration.underline,
    decorationThickness: 2,
  );
}

/// Motion values, 1:1 from the film. All in milliseconds.
class TopUpMotion {
  static const landingDelay = Duration(milliseconds: 300);
  static const roll = 1300; // ease out to steps + overshoot, same for any step count
  static const settle = 220; // ease back to the target
  static const overshoot = 0.25; // digits
  static const tensLead = 100; // tens slot starts opening 100ms before units pass 9.5
  static const tensEnter = 420;
  static const labelLead = 100; // label swap starts 100ms before the roll ends
  static const labelSwap = 300;
  static const labelShift = 14.0; // px
  static const reducedCrossFade = Duration(milliseconds: 150);
}

/// One state of the plan balance, e.g. 2.40 of 3 GB, or 3 of 7 days.
@immutable
class PlanBalance {
  const PlanBalance({
    required this.remaining,
    required this.total,
    required this.unit,
    this.decimals = 2,
  });

  final double remaining;
  final double total;

  /// Shown after the total: "GB" or "days".
  final String unit;

  /// 2 for data ("2.40"), 0 for day-limited unlimited plans ("3").
  final int decimals;

  int get whole => remaining.floor();

  /// Fraction digits as shown, without the dot: "40" for 2.40.
  String get fractionDigits =>
      decimals == 0 ? '' : remaining.toStringAsFixed(decimals).split('.').last;

  String get totalLabel {
    final t = total == total.roundToDouble() ? total.toStringAsFixed(0) : total.toString();
    return '/ $t $unit';
  }

  double get meterFraction => total <= 0 ? 0 : (remaining / total).clamp(0.0, 1.0);

  @override
  bool operator ==(Object other) =>
      other is PlanBalance &&
      other.remaining == remaining &&
      other.total == total &&
      other.unit == unit &&
      other.decimals == decimals;

  @override
  int get hashCode => Object.hash(remaining, total, unit, decimals);
}

/// The eSIM plan card with the top-up roll.
///
/// Pass the balance from before the top-up as [previous] and the new one as
/// [balance]. The card plays the roll once, [TopUpMotion.landingDelay] after
/// it is first built. With no [previous], or when it equals [balance], it
/// renders the static card. A later change to [balance] while mounted (a
/// second top-up) plays again from the value currently shown.
class TopUpPlanCard extends StatelessWidget {
  const TopUpPlanCard({
    super.key,
    required this.country,
    required this.flag,
    required this.subtitle,
    required this.balance,
    this.previous,
    this.onDetails,
  });

  final String country;

  /// 44x30 flag image.
  final Widget flag;

  /// "Valid for 1 day 5 hours" or "Unlimited data".
  final String subtitle;
  final PlanBalance balance;
  final PlanBalance? previous;
  final VoidCallback? onDetails;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 440,
      padding: const EdgeInsets.fromLTRB(26, 34, 26, 26),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _Card.border, width: 2),
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [BoxShadow(color: Color(0x0A000000), offset: Offset(0, 1), blurRadius: 2)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 34,
            child: Row(children: [
              Container(
                width: 44,
                height: 30,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5),
                  boxShadow: const [BoxShadow(color: Color(0x0F000000), spreadRadius: 1)],
                ),
                child: flag,
              ),
              const SizedBox(width: 18),
              Text(country, style: _Card.name),
            ]),
          ),
          const SizedBox(height: 26),
          TopUpDataMeter(balance: balance, previous: previous, subtitle: subtitle),
          const SizedBox(height: 28),
          GestureDetector(
            onTap: onDetails,
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: const [
              Icon(Icons.info_outline, size: 22, color: _Card.main),
              SizedBox(width: 10),
              Text('Your plan details', style: _Card.link),
            ]),
          ),
        ],
      ),
    );
  }
}

/// Number row, subtitle and meter: the part of the card that animates.
class TopUpDataMeter extends StatefulWidget {
  const TopUpDataMeter({super.key, required this.balance, required this.subtitle, this.previous});

  final PlanBalance balance;
  final PlanBalance? previous;
  final String subtitle;

  @override
  State<TopUpDataMeter> createState() => _TopUpDataMeterState();
}

class _TopUpDataMeterState extends State<TopUpDataMeter> with SingleTickerProviderStateMixin {
  // One clock drives everything; each phase is a pure function of its time.
  late final AnimationController _c = AnimationController(vsync: this);

  late PlanBalance _from;
  late PlanBalance _to;
  int _steps = 0;
  double _tc = double.infinity; // ms where the units pass 9.5
  bool _started = false;
  bool _reduced = false;

  bool get _tensNew => _from.whole < 10 && _to.whole >= 10;
  double get _ms => _c.value * (_c.duration?.inMilliseconds ?? 0);

  @override
  void initState() {
    super.initState();
    _to = widget.balance;
    _from = widget.previous ?? widget.balance;
    if (_from != _to) {
      Future.delayed(TopUpMotion.landingDelay, () {
        if (mounted) _start();
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduced = MediaQuery.disableAnimationsOf(context);
  }

  @override
  void didUpdateWidget(TopUpDataMeter old) {
    super.didUpdateWidget(old);
    if (widget.balance != _to) {
      // Interruption: jump to the end state, then roll from there.
      _from = _to;
      _to = widget.balance;
      _start();
    }
  }

  void _start() {
    _steps = (_to.whole - _from.whole).clamp(0, 99);
    _tc = double.infinity;
    if (_tensNew) {
      for (var t = 0; t <= TopUpMotion.roll; t++) {
        if (_from.whole + _k(t.toDouble()) >= 9.5) {
          _tc = t.toDouble();
          break;
        }
      }
    }
    final labelAt = _steps > 0 ? TopUpMotion.roll - TopUpMotion.labelLead : 0;
    final end = [
      if (_steps > 0) TopUpMotion.roll + TopUpMotion.settle,
      labelAt + TopUpMotion.labelSwap,
      if (_tensNew) (_tc - TopUpMotion.tensLead + TopUpMotion.tensEnter).ceil(),
    ].reduce(math.max);
    setState(() => _started = true);
    if (_reduced) return; // AnimatedSwitcher cross-fades to the new state
    _c.duration = Duration(milliseconds: end);
    _c.forward(from: 0);
  }

  /// Rolled steps at [t] ms: ease out past the target, then settle back.
  double _k(double t) {
    if (_steps == 0) return 0;
    const o = TopUpMotion.overshoot;
    final p = (t / TopUpMotion.roll).clamp(0.0, 1.0);
    final q = ((t - TopUpMotion.roll) / TopUpMotion.settle).clamp(0.0, 1.0);
    return (_steps + o) * Curves.easeOutCubic.transform(p) - o * Curves.easeInOutCubic.transform(q);
  }

  double _seg(double t, num a, num b) => ((t - a) / (b - a)).clamp(0.0, 1.0);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_reduced) {
      final shown = _started ? _to : _from;
      return AnimatedSwitcher(
        duration: TopUpMotion.reducedCrossFade,
        child: KeyedSubtree(
          key: ValueKey(shown),
          child: _frame(
            value: shown.whole.toDouble(),
            tensIn: shown.whole >= 10 ? 1 : 0,
            tensPos: (shown.whole ~/ 10).toDouble(),
            swap: 1,
            from: shown,
            to: shown,
            meter: shown.meterFraction,
            blur: 0,
          ),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = _started ? _ms : 0.0;
        final k = _k(t);
        final v = _from.whole + k;
        final labelAt = _steps > 0 ? TopUpMotion.roll - TopUpMotion.labelLead : 0;
        final swap = Curves.easeOutCubic.transform(_seg(t, labelAt, labelAt + TopUpMotion.labelSwap));
        final progress = _steps == 0 ? swap : (k / _steps).clamp(0.0, 1.0);

        // Tens: slot opens and the digit rises in (only when it is new);
        // otherwise a plain odometer with carry.
        final units = v % 10;
        final odo = (v / 10).floorToDouble() + (units - 9).clamp(0.0, 1.0);
        final tensIn = _tensNew
            ? Curves.easeOutCubic.transform(
                _seg(t, _tc - TopUpMotion.tensLead, _tc - TopUpMotion.tensLead + TopUpMotion.tensEnter))
            : (_from.whole >= 10 ? 1.0 : 0.0);
        final tensPos = _tensNew && odo < 2 ? tensIn + math.max(0, odo - 1) : odo;

        // Motion blur while the reel moves faster than 1 digit/s, max 2px.
        final speed = (_k(t + 8) - k).abs() / 0.008;
        final blur = speed > 1 ? math.min(2.0, speed * 0.12) : 0.0;

        return _frame(
          value: v,
          tensIn: tensIn,
          tensPos: tensPos,
          swap: swap,
          from: _from,
          to: _to,
          meter: _from.meterFraction + (_to.meterFraction - _from.meterFraction) * progress,
          blur: blur,
        );
      },
    );
  }

  Widget _frame({
    required double value,
    required double tensIn,
    required double tensPos,
    required double swap,
    required PlanBalance from,
    required PlanBalance to,
    required double meter,
    required double blur,
  }) {
    final dec = swap < 0.5 ? from.fractionDigits : to.fractionDigits;
    Widget units = _Reel(position: value % 10, labels: List.generate(11, (i) => '${i % 10}'));
    if (blur > 0) {
      units = ImageFiltered(imageFilter: ImageFilter.blur(sigmaX: 0, sigmaY: blur), child: units);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: _Card.lineH,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Tens slot: opens from 0 to one digit; the reel is anchored right.
              ClipRect(
                child: Align(
                  alignment: Alignment.centerRight,
                  widthFactor: tensIn,
                  child: _Reel(
                    position: tensPos,
                    labels: const [' ', '1', '2', '3', '4', '5', '6', '7', '8', '9'],
                  ),
                ),
              ),
              units,
              if (dec.isNotEmpty) ...[
                Transform.translate(
                  offset: const Offset(-0.02 * _Card.numberSize, 0),
                  child: const Text('.', style: _Card.number),
                ),
                for (final d in dec.split(''))
                  SizedBox(
                    width: _Card.digitW,
                    height: _Card.lineH,
                    child: Center(child: Text(d, style: _Card.number)),
                  ),
              ],
              Padding(
                padding: const EdgeInsets.only(left: 10, bottom: 8),
                child: _SwapText(from: from.totalLabel, to: to.totalLabel, p: swap),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text(widget.subtitle, style: _Card.sub),
        const SizedBox(height: 26),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: meter,
            minHeight: 7,
            backgroundColor: _Card.track,
            color: _Card.main,
          ),
        ),
      ],
    );
  }
}

/// One odometer column: [labels] stacked, translated by [position] rows.
class _Reel extends StatelessWidget {
  const _Reel({required this.position, required this.labels});

  final double position;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    const h = _Card.lineH;
    return SizedBox(
      width: _Card.digitW,
      height: h,
      child: ClipRect(
        child: OverflowBox(
          alignment: Alignment.topCenter,
          minHeight: h * labels.length,
          maxHeight: h * labels.length,
          child: Transform.translate(
            offset: Offset(0, -position * h),
            child: Column(children: [
              for (final l in labels)
                SizedBox(height: h, child: Center(child: Text(l, style: _Card.number))),
            ]),
          ),
        ),
      ),
    );
  }
}

/// "/ 3 GB" to "/ 13 GB": old rises 14px and fades out, new rises 14px in.
class _SwapText extends StatelessWidget {
  const _SwapText({required this.from, required this.to, required this.p});

  final String from, to;
  final double p;

  @override
  Widget build(BuildContext context) {
    if (from == to) return Text(to, style: _Card.total);
    const d = TopUpMotion.labelShift;
    return Stack(children: [
      Opacity(
        opacity: 1 - p,
        child: Transform.translate(offset: Offset(0, -d * p), child: Text(from, style: _Card.total)),
      ),
      Opacity(
        opacity: p,
        child: Transform.translate(offset: Offset(0, d * (1 - p)), child: Text(to, style: _Card.total)),
      ),
    ]);
  }
}

// Usage, after a successful top-up:
//
//   TopUpPlanCard(
//     country: 'Turkey',
//     flag: Image.asset('assets/flags/tr.png', fit: BoxFit.cover),
//     subtitle: 'Valid for 1 day 5 hours',
//     previous: const PlanBalance(remaining: 2.40, total: 3, unit: 'GB'),
//     balance: const PlanBalance(remaining: 12.40, total: 13, unit: 'GB'),
//   )
//
// Unlimited (day-limited) plan:
//
//   TopUpPlanCard(
//     country: 'Turkey',
//     flag: ...,
//     subtitle: 'Unlimited data',
//     previous: const PlanBalance(remaining: 3, total: 7, unit: 'days', decimals: 0),
//     balance: const PlanBalance(remaining: 6, total: 10, unit: 'days', decimals: 0),
//   )
