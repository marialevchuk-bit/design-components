// Hubby eSIM: top-up rolling counter for the eSIM plan card.
//
// When a top-up lands on a plan card, the balance rolls once from the old
// value to the new one, odometer style. The data meter fills along with the
// roll, a second digit slides in when the balance passes 9, and the
// "/ 3 GB" total cross-fades to the new total as the roll settles.
//
// Reference implementation for the handoff. Swap the `_Tokens` values for the
// app's own theme (AppColors / AppTextStyles); the names match tokens.css.
// Prototype: motion/topup-rolling/prototype.html in the design-components repo.

import 'package:flutter/material.dart';

/// Design tokens used by this widget. Names match tokens.css and the app.
class _Tokens {
  static const brand = Color(0xFFFF8800); // --brand (partner-overridable)
  static const meterTrack = Color(0xFFF0F0F0); // --grayscale200
  static const textPrimary = Color(0xFF0F0F11); // --grayscale900
  static const textHint = Color(0xFF666666); // --grayscale600

  // --dataMeterText: 600 42px / 1.25
  static const dataMeterText = TextStyle(
    fontFamily: 'GeneralSans',
    fontWeight: FontWeight.w600,
    fontSize: 42,
    height: 1.25,
    color: textPrimary,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  // --bodyM500: 500 18px / 1.4, hint colour
  static const totalLabel = TextStyle(
    fontFamily: 'GeneralSans',
    fontWeight: FontWeight.w500,
    fontSize: 18,
    height: 1.4,
    color: textHint,
  );
}

/// Motion tokens (hubby-motion). One new token: `roll`, the scaled duration
/// of the counter itself, see [TopUpMotion.rollDuration].
class TopUpMotion {
  /// Wait after the card is on screen before the roll starts, so the user's
  /// eye has landed on the card.
  static const landingDelay = Duration(milliseconds: 300);

  /// `standard`: tens digit entrance.
  static const tensEnter = Duration(milliseconds: 300);

  /// `quick`: total label and decimals swap.
  static const labelSwap = Duration(milliseconds: 200);

  /// Reduced motion: plain cross-fade between old and new state.
  static const reducedCrossFade = Duration(milliseconds: 150);

  /// Overshoot past the target digit before settling back, in digits.
  static const overshoot = 0.15;

  /// `roll`: 600ms for one step, +60ms per extra step, capped at 1200ms.
  /// 3 steps = 720ms, 5 steps = 840ms, 10 steps = 1140ms.
  static Duration rollDuration(int steps) {
    final ms = (600 + 60 * (steps - 1)).clamp(600, 1200);
    return Duration(milliseconds: ms);
  }
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
  String get fractionDigits {
    if (decimals == 0) return '';
    return remaining.toStringAsFixed(decimals).split('.').last;
  }

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

/// The number, total label and data meter of the eSIM plan card.
///
/// Pass the balance from before the top-up as [previous] and the new one as
/// [balance]. The widget plays the roll once, [TopUpMotion.landingDelay]
/// after it is first built. With no [previous], or when it equals [balance],
/// it renders the static card. A later change to [balance] while mounted
/// (a second top-up) plays again from the value currently shown.
class TopUpDataMeter extends StatefulWidget {
  const TopUpDataMeter({super.key, required this.balance, this.previous});

  final PlanBalance balance;
  final PlanBalance? previous;

  @override
  State<TopUpDataMeter> createState() => _TopUpDataMeterState();
}

class _TopUpDataMeterState extends State<TopUpDataMeter> with TickerProviderStateMixin {
  late final AnimationController _roll = AnimationController(vsync: this);
  late final AnimationController _tens =
      AnimationController(vsync: this, duration: TopUpMotion.tensEnter);
  late final AnimationController _label =
      AnimationController(vsync: this, duration: TopUpMotion.labelSwap);
  late Animation<double> _steps = const AlwaysStoppedAnimation(0);

  late PlanBalance _from;
  late PlanBalance _to;
  int _stepCount = 0;
  bool _reduced = false;

  @override
  void initState() {
    super.initState();
    _to = widget.balance;
    _from = widget.previous ?? widget.balance;
    _roll.addListener(_onRollTick);
    if (_from != _to) {
      Future.delayed(TopUpMotion.landingDelay, () {
        if (mounted) _start();
      });
    } else {
      _settle();
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
      // Interruption: a new balance mid-flight jumps to the end state, then
      // rolls from there to the new value.
      final shown = _to;
      _settle();
      _from = shown;
      _to = widget.balance;
      _start();
    }
  }

  void _settle() {
    _stepCount = 0;
    _roll.value = 1;
    _tens.value = 1;
    _label.value = 1;
    _from = _to;
    _steps = const AlwaysStoppedAnimation(0);
  }

  void _start() {
    _stepCount = (_to.whole - _from.whole).clamp(0, 99);
    final s = _stepCount.toDouble();
    const o = TopUpMotion.overshoot;
    _steps = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: s + o).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 85,
      ),
      TweenSequenceItem(
        tween: Tween(begin: s + o, end: s).chain(CurveTween(curve: Curves.easeInOutCubic)),
        weight: 15,
      ),
    ]).animate(_roll);
    _tens.value = 0;
    _label.value = 0;

    if (_reduced) {
      // Reduced motion: flip to the new state; AnimatedSwitcher cross-fades.
      setState(() => _label.value = 1);
      return;
    }
    if (_stepCount == 0) {
      // Nothing to roll (a top-up under 1 GB): label, decimals and meter swap.
      _tens.value = 1;
      _label.forward();
      return;
    }
    _roll.duration = TopUpMotion.rollDuration(_stepCount);
    _roll.forward(from: 0);
  }

  void _onRollTick() {
    if (_stepCount == 0 || _roll.duration == null) return;
    final v = _from.whole + _steps.value;
    // Tens digit slides in as the units pass 9 (only when it is new).
    if (_from.whole < 10 && _to.whole >= 10 && v >= 9 && !_tens.isAnimating && _tens.value == 0) {
      _tens.forward();
    }
    // Total label swaps 100ms before the roll ends.
    final ms = _roll.duration!.inMilliseconds;
    if (!_label.isAnimating && _label.value == 0 && _roll.value >= 1 - 100 / ms) {
      _label.forward();
    }
  }

  @override
  void dispose() {
    _roll.dispose();
    _tens.dispose();
    _label.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_reduced) {
      // Reduced motion: one 150ms cross-fade from the old card to the new one.
      final shown = _label.value == 0 ? _from : _to;
      return AnimatedSwitcher(
        duration: TopUpMotion.reducedCrossFade,
        switchInCurve: Curves.decelerate,
        switchOutCurve: Curves.easeIn,
        child: _StaticMeter(key: ValueKey(shown), balance: shown),
      );
    }

    return AnimatedBuilder(
      animation: Listenable.merge([_roll, _tens, _label]),
      builder: (context, _) {
        final k = _steps.value;
        final value = _from.whole + k;
        // The meter follows the roll; with nothing to roll it follows the swap.
        final progress =
            _stepCount == 0 ? _label.value : (k / _stepCount).clamp(0.0, 1.0);
        final meter = _from.meterFraction + (_to.meterFraction - _from.meterFraction) * progress;
        final tensIsNew = _from.whole < 10 && _to.whole >= 10;
        final tensIn = tensIsNew
            ? Curves.decelerate.transform(_tens.value)
            : (_to.whole >= 10 ? 1.0 : 0.0);
        final swap = Curves.fastOutSlowIn.transform(_label.value);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _NumberRow(
              value: value,
              tensIn: tensIn,
              swap: swap,
              fromFraction: _from.fractionDigits,
              toFraction: _to.fractionDigits,
              fromLabel: _from.totalLabel,
              toLabel: _to.totalLabel,
            ),
            const SizedBox(height: 16),
            _Meter(fraction: meter),
          ],
        );
      },
    );
  }
}

/// Integer reels + fixed decimals + total label, all on one baseline row.
class _NumberRow extends StatelessWidget {
  const _NumberRow({
    required this.value,
    required this.tensIn,
    required this.swap,
    required this.fromFraction,
    required this.toFraction,
    required this.fromLabel,
    required this.toLabel,
  });

  /// Continuous odometer value, e.g. 7.63 while rolling from 2 to 12.
  final double value;

  /// 0..1: tens digit entrance (fade + push the rest right by one digit).
  final double tensIn;

  /// 0..1: total label (and decimals, if they change) cross-fade.
  final double swap;
  final String fromFraction, toFraction, fromLabel, toLabel;

  @override
  Widget build(BuildContext context) {
    const style = _Tokens.dataMeterText;
    final digitW = _digitWidth(context, style);
    final lineH = style.fontSize! * style.height!;

    final units = value % 10;
    final carry = (units - 9).clamp(0.0, 1.0);
    final tens = (value / 10).floorToDouble() + carry;

    Widget swapText(String a, String b, TextStyle s) {
      if (a == b) return Text(a, style: s);
      return Stack(children: [
        Opacity(
          opacity: 1 - swap,
          child: Transform.translate(offset: Offset(0, -8 * swap), child: Text(a, style: s)),
        ),
        Opacity(
          opacity: swap,
          child: Transform.translate(offset: Offset(0, 8 * (1 - swap)), child: Text(b, style: s)),
        ),
      ]);
    }

    final trailing = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _Reel(position: units, width: digitW, height: lineH, style: style),
        if (toFraction.isNotEmpty) swapText('.$fromFraction', '.$toFraction', style),
        Padding(
          // Sits the 18px label on the 42px numeral baseline.
          padding: const EdgeInsets.only(left: 6, bottom: 8),
          child: swapText(fromLabel, toLabel, _Tokens.totalLabel),
        ),
      ],
    );

    // Transform-only: the tens reel fades in at x=0 while the rest of the row
    // slides right by one digit width. No layout animates.
    return SizedBox(
      height: lineH,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (tensIn > 0)
            Opacity(
              opacity: tensIn,
              child: _Reel(position: tens % 10, width: digitW, height: lineH, style: style),
            ),
          Transform.translate(offset: Offset(digitW * tensIn, 0), child: trailing),
        ],
      ),
    );
  }

  static double _digitWidth(BuildContext context, TextStyle style) {
    var w = 0.0;
    for (var d = 0; d <= 9; d++) {
      final tp = TextPainter(
        text: TextSpan(text: '$d', style: style),
        textDirection: TextDirection.ltr,
        textScaler: MediaQuery.textScalerOf(context),
      )..layout();
      if (tp.width > w) w = tp.width;
    }
    return w.ceilToDouble();
  }
}

/// A single odometer column: 0-9 then 0 again, translated by [position].
class _Reel extends StatelessWidget {
  const _Reel({
    required this.position,
    required this.width,
    required this.height,
    required this.style,
  });

  /// 0..10. 2.0 shows "2"; 9.5 shows half of "9" and half of the next "0".
  final double position;
  final double width, height;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: ClipRect(
        child: OverflowBox(
          alignment: Alignment.topCenter,
          minHeight: height * 11,
          maxHeight: height * 11,
          child: Transform.translate(
            offset: Offset(0, -position * height),
            child: Column(
              children: [
                for (var i = 0; i <= 10; i++)
                  SizedBox(
                    height: height,
                    width: width,
                    child: Center(child: Text('${i % 10}', style: style)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 4px meter: --grayscale200 track, --brand fill, 4px radius.
class _Meter extends StatelessWidget {
  const _Meter({required this.fraction});
  final double fraction;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value: fraction,
        minHeight: 4,
        backgroundColor: _Tokens.meterTrack,
        color: _Tokens.brand,
      ),
    );
  }
}

/// The settled card content, used for the reduced-motion cross-fade.
class _StaticMeter extends StatelessWidget {
  const _StaticMeter({super.key, required this.balance});
  final PlanBalance balance;

  @override
  Widget build(BuildContext context) {
    final f = balance.fractionDigits;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('${balance.whole}${f.isEmpty ? '' : '.$f'}', style: _Tokens.dataMeterText),
            Padding(
              padding: const EdgeInsets.only(left: 6, bottom: 8),
              child: Text(balance.totalLabel, style: _Tokens.totalLabel),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _Meter(fraction: balance.meterFraction),
      ],
    );
  }
}

// Usage on the plan card, after a successful top-up:
//
//   TopUpDataMeter(
//     previous: const PlanBalance(remaining: 2.40, total: 3, unit: 'GB'),
//     balance: const PlanBalance(remaining: 12.40, total: 13, unit: 'GB'),
//   )
//
// Unlimited (day-limited) plan:
//
//   TopUpDataMeter(
//     previous: const PlanBalance(remaining: 3, total: 7, unit: 'days', decimals: 0),
//     balance: const PlanBalance(remaining: 6, total: 10, unit: 'days', decimals: 0),
//   )
