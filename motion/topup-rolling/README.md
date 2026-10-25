# Top-up rolling counter

When a top-up lands on the eSIM plan card, the balance rolls once to the new
value, odometer style. Built on the app design system (GeneralSans,
`dataMeterText`, the 4px `--brand` meter, the emphasised card).

| File | For |
|------|-----|
| `prototype.html` | Interactive prototype: four scenarios plus your own numbers, replay, 0.25x, reduced motion, timeline scrubber. Self-contained (fonts inlined). |
| `spec.txt` | The animation spec for developers: phases, durations, curves, interruption, reduced motion, tokens. |
| `top_up_data_meter.dart` | Flutter reference widget (`TopUpDataMeter`). Swap `_Tokens` for the app's theme classes. |
| `prototype.src.html`, `build.py` | Source of the prototype. Edit the source, then run `python3 motion/topup-rolling/build.py`. |

## Scenarios

| Scenario | Before | After | What moves |
|----------|--------|-------|------------|
| Unused plan | 3.00 / 3 GB | 8.00 / 8 GB | Number rolls; meter stays full |
| Used plan | 0.48 / 3 GB | 5.48 / 8 GB | Number rolls; meter fills with it |
| Into two digits | 2.40 / 3 GB | 12.40 / 13 GB | Tens digit slides in as the units pass 9 |
| Unlimited, days | 3 / 7 days | 6 / 10 days | Whole numbers; meter fills |

One logic covers all four: the widget only needs the balance before and after.
