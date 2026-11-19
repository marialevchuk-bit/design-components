# Builds Lottie JSON for the three onboarding animations of
# "FLOW · NEW CUSTOMER WITHOUT AN ESIM" (Webapp redesign), matching the CSS in the design file.
# Usage: python3 -I make_lottie.py <paths.json> <measure.json> <Inter-variable.woff2> <outdir>
import sys, json, math, re, io, os
from fontTools.ttLib import TTFont
from fontTools.varLib.instancer import instantiateVariableFont
from fontTools.pens.basePen import BasePen
import uharfbuzz as hb

PATHS = json.load(open(sys.argv[1])); M = json.load(open(sys.argv[2]))
FONT_SRC, OUT = sys.argv[3], sys.argv[4]
FPS = 60
EASE = (.25, .1, .25, 1)          # CSS "ease"
EASE_OUT = (0, 0, .58, 1)         # CSS "ease-out"
BLUE, SOFT, LINE, INK, INK2, GREY = '#003DF5', '#E5EBFE', '#D5D8E0', '#0A0F24', '#5C6480', '#8A90A6'

def rgb(h):
    h = h.lstrip('#'); return [round(int(h[i:i+2], 16) / 255, 4) for i in (0, 2, 4)] + [1]
def fr(t): return round(t * FPS)

# ---------- SVG path -> cubic subpaths ----------
NUM = r'[-+]?(?:\d+\.?\d*|\.\d+)(?:[eE][-+]?\d+)?'
def tokenize(d):
    for m in re.finditer(r'([MmLlHhVvCcSsQqTtAaZz])|(' + NUM + ')', d):
        yield m.group(1) or float(m.group(2))

def arc_to_cubics(x1, y1, rx, ry, phi, fa, fs, x2, y2):
    if rx == 0 or ry == 0: return [((x1, y1), (x2, y2), (x2, y2))]
    rx, ry = abs(rx), abs(ry); p = math.radians(phi); cp, sp = math.cos(p), math.sin(p)
    dx, dy = (x1 - x2) / 2, (y1 - y2) / 2
    x1p, y1p = cp * dx + sp * dy, -sp * dx + cp * dy
    lam = x1p**2 / rx**2 + y1p**2 / ry**2
    if lam > 1: rx *= math.sqrt(lam); ry *= math.sqrt(lam)
    num = rx**2 * ry**2 - rx**2 * y1p**2 - ry**2 * x1p**2
    den = rx**2 * y1p**2 + ry**2 * x1p**2
    co = math.sqrt(max(0, num / den)) * (-1 if fa == fs else 1)
    cxp, cyp = co * rx * y1p / ry, -co * ry * x1p / rx
    cx, cy = cp * cxp - sp * cyp + (x1 + x2) / 2, sp * cxp + cp * cyp + (y1 + y2) / 2
    ang = lambda ux, uy, vx, vy: math.atan2(ux * vy - uy * vx, ux * vx + uy * vy)
    t1 = ang(1, 0, (x1p - cxp) / rx, (y1p - cyp) / ry)
    dt = ang((x1p - cxp) / rx, (y1p - cyp) / ry, (-x1p - cxp) / rx, (-y1p - cyp) / ry)
    if not fs and dt > 0: dt -= 2 * math.pi
    if fs and dt < 0: dt += 2 * math.pi
    n = max(1, math.ceil(abs(dt) / (math.pi / 2) - 1e-9)); seg = dt / n
    k = 4 / 3 * math.tan(seg / 4); out = []
    def pt(t): return (cx + rx * math.cos(t) * cp - ry * math.sin(t) * sp, cy + rx * math.cos(t) * sp + ry * math.sin(t) * cp)
    def dv(t): return (-rx * math.sin(t) * cp - ry * math.cos(t) * sp, -rx * math.sin(t) * sp + ry * math.cos(t) * cp)
    for i in range(n):
        a, b = t1 + i * seg, t1 + (i + 1) * seg
        pa, pb, da, db = pt(a), pt(b), dv(a), dv(b)
        out.append(((pa[0] + k * da[0], pa[1] + k * da[1]), (pb[0] - k * db[0], pb[1] - k * db[1]), pb))
    out[-1] = (out[-1][0], out[-1][1], (x2, y2))
    return out

def parse_path(d):
    """-> list of subpaths: {'start':(x,y),'segs':[(c1,c2,p)],'closed':bool}"""
    toks = list(tokenize(d)); i = 0; cmd = None; cur = (0, 0); start = (0, 0); subs = []; sub = None
    last_c = None; last_q = None
    def take(n):
        nonlocal i
        v = toks[i:i + n]; i += n; return v
    while i < len(toks):
        if isinstance(toks[i], str): cmd = toks[i]; i += 1
        elif cmd in 'Mm': cmd = 'L' if cmd == 'M' else 'l'
        rel = cmd.islower(); C = cmd.upper(); ox, oy = cur if rel else (0, 0)
        if C == 'Z':
            if sub: sub['closed'] = True
            cur = start; sub = None; last_c = last_q = None; continue
        if C == 'M':
            x, y = take(2); cur = start = (ox + x, oy + y); sub = {'start': cur, 'segs': [], 'closed': False}; subs.append(sub); last_c = last_q = None; continue
        if sub is None: sub = {'start': cur, 'segs': [], 'closed': False}; subs.append(sub); start = cur
        if C in 'LHV':
            if C == 'L': x, y = take(2); p = (ox + x, oy + y)
            elif C == 'H': (x,) = take(1); p = ((cur[0] if rel else 0) + x, cur[1])
            else: (y,) = take(1); p = (cur[0], (cur[1] if rel else 0) + y)
            sub['segs'].append((cur, p, p)); cur = p; last_c = last_q = None
        elif C in 'CS':
            if C == 'C': a, b, c, e, x, y = take(6); c1 = (ox + a, oy + b)
            else:
                c, e, x, y = take(4)
                c1 = (2 * cur[0] - last_c[0], 2 * cur[1] - last_c[1]) if last_c else cur
            c2 = (ox + c, oy + e); p = (ox + x, oy + y)
            sub['segs'].append((c1, c2, p)); last_c = c2; last_q = None; cur = p
        elif C in 'QT':
            if C == 'Q': a, b, x, y = take(4); q = (ox + a, oy + b)
            else: x, y = take(2); q = (2 * cur[0] - last_q[0], 2 * cur[1] - last_q[1]) if last_q else cur
            p = (ox + x, oy + y)
            c1 = (cur[0] + 2 / 3 * (q[0] - cur[0]), cur[1] + 2 / 3 * (q[1] - cur[1]))
            c2 = (p[0] + 2 / 3 * (q[0] - p[0]), p[1] + 2 / 3 * (q[1] - p[1]))
            sub['segs'].append((c1, c2, p)); last_q = q; last_c = None; cur = p
        elif C == 'A':
            rx, ry, phi, fa, fs, x, y = take(7); p = (ox + x, oy + y)
            sub['segs'].extend(arc_to_cubics(cur[0], cur[1], rx, ry, phi, int(fa), int(fs), p[0], p[1])); cur = p; last_c = last_q = None
    return subs

def sub_to_sh(sub, tf=lambda p: p, name='p'):
    v = [tf(sub['start'])]; ins = [[0, 0]]; outs = []
    for c1, c2, p in sub['segs']:
        a, b, c = tf(c1), tf(c2), tf(p); prev = v[-1]
        outs.append([a[0] - prev[0], a[1] - prev[1]]); v.append(c); ins.append([b[0] - c[0], b[1] - c[1]])
    outs.append([0, 0]); closed = sub['closed']
    if len(v) > 1 and abs(v[-1][0] - v[0][0]) < 1e-6 and abs(v[-1][1] - v[0][1]) < 1e-6:
        ins[0] = ins[-1]; v.pop(); ins.pop(); outs.pop(); closed = True
    r = lambda a: [round(a[0], 3), round(a[1], 3)]
    return {'ty': 'sh', 'nm': name, 'ks': {'a': 0, 'k': {'c': closed, 'v': [r(p) for p in v], 'i': [r(p) for p in ins], 'o': [r(p) for p in outs]}}}

def path_shapes(d, sx=1, sy=None, dx=0, dy=0):
    sy = sx if sy is None else sy
    return [sub_to_sh(s, lambda p: (p[0] * sx + dx, p[1] * sy + dy), 'p%d' % k) for k, s in enumerate(parse_path(d))]

# ---------- Lottie building blocks ----------
def static(v): return {'a': 0, 'k': v}
def anim(points, dims):
    """points: [(t_sec, value, ease_tuple_or_None)]; ease applies to the segment that starts at that point."""
    ks = []
    for t, v, e in points:
        v = v if isinstance(v, list) else [v]
        k = {'t': fr(t), 's': v}
        if e: k['o'] = {'x': [e[0]] * dims, 'y': [e[1]] * dims}; k['i'] = {'x': [e[2]] * dims, 'y': [e[3]] * dims}
        ks.append(k)
    return {'a': 1, 'k': ks}
def fill(color, op=100, rule=1):
    return {'ty': 'fl', 'c': color if isinstance(color, dict) else static(rgb(color)), 'o': op if isinstance(op, dict) else static(op), 'r': rule}
def stroke(color, w, op=100, cap=2, join=2):
    return {'ty': 'st', 'c': static(rgb(color)), 'o': op if isinstance(op, dict) else static(op), 'w': static(w), 'lc': cap, 'lj': join, 'ml': 4}
def tr(): return {'ty': 'tr', 'p': static([0, 0]), 'a': static([0, 0]), 's': static([100, 100]), 'r': static(0), 'o': static(100), 'sk': static(0), 'sa': static(0)}
def group(name, items): return {'ty': 'gr', 'nm': name, 'it': items + [tr()]}
def ellipse(cx, cy, d): return {'ty': 'el', 'p': static([cx, cy]), 's': static([d, d])}
def rect(x, y, w, h, r): return {'ty': 'rc', 'p': static([x + w / 2, y + h / 2]), 's': static([w, h]), 'r': static(r)}
def layer(name, shapes, op, o=None, p=None, a=None, s=None, ip=0, st=0):
    return {'ddd': 0, 'ty': 4, 'nm': name, 'sr': 1, 'ip': ip, 'op': op, 'st': st, 'bm': 0,
            'ks': {'o': o or static(100), 'r': static(0), 'p': p or static([0, 0, 0]), 'a': a or static([0, 0, 0]), 's': s or static([100, 100, 100])},
            'shapes': shapes}
def comp(name, w, h, dur, layers, markers=None):
    return {'v': '5.7.4', 'fr': FPS, 'ip': 0, 'op': fr(dur), 'w': w, 'h': h, 'nm': name, 'ddd': 0, 'assets': [],
            'layers': layers[::-1],  # Lottie draws the first layer on top
            'markers': markers or []}

# ---------- text as outlines (Inter, shaped with HarfBuzz) ----------
_fonts = {}
def font(wght):
    if wght not in _fonts:
        f = TTFont(FONT_SRC); inst = instantiateVariableFont(f, {'wght': wght}); inst.flavor = None
        buf = io.BytesIO(); inst.save(buf); data = buf.getvalue()
        _fonts[wght] = (TTFont(io.BytesIO(data)), hb.Font(hb.Face(data)))
    return _fonts[wght]
class Rec(BasePen):
    def __init__(self, gs, tf): super().__init__(gs); self.tf = tf; self.subs = []; self.cur = None
    def _moveTo(self, p): self.cur = {'start': self.tf(p), 'segs': [], 'closed': False}; self.subs.append(self.cur); self.last = self.tf(p)
    def _lineTo(self, p): q = self.tf(p); self.cur['segs'].append((self.last, q, q)); self.last = q
    def _curveToOne(self, a, b, c): self.cur['segs'].append((self.tf(a), self.tf(b), self.tf(c))); self.last = self.tf(c)
    def _closePath(self): self.cur['closed'] = True
def text_shapes(s, size, wght, x, baseline, align='left'):
    tt, hf = font(wght); upm = tt['head'].unitsPerEm; sc = size / upm
    buf = hb.Buffer(); buf.add_str(s); buf.guess_segment_properties(); hb.shape(hf, buf, {'kern': True, 'liga': True})
    order = tt.getGlyphOrder(); gs = tt.getGlyphSet(); pen_x = 0; placed = []
    for info, pos in zip(buf.glyph_infos, buf.glyph_positions):
        placed.append((order[info.codepoint], pen_x + pos.x_offset, pos.y_offset)); pen_x += pos.x_advance
    width = pen_x * sc
    x0 = x - (width / 2 if align == 'center' else 0)
    shapes = []
    for gname, gx, gy in placed:
        rec = Rec(gs, lambda p, gx=gx, gy=gy: (x0 + (p[0] + gx) * sc, baseline - (p[1] + gy) * sc))
        gs[gname].draw(rec)
        shapes += [sub_to_sh(sb, name=gname) for sb in rec.subs]
    return shapes, width
def ascent(size, wght=400): tt, _ = font(wght); return tt['hhea'].ascent / tt['head'].unitsPerEm * size

CARD = PATHS['CARD']; CHIP = 'M42 56H78a8 8 0 0 1 8 8V108a8 8 0 0 1-8 8H42a8 8 0 0 1-8-8V64a8 8 0 0 1 8-8Z'
LINES = 'M34 78H86M34 94H86M60 56V78M60 94V116'
PIN = 'M12 1.5a8 8 0 0 0-8 8c0 5.1 5.6 10.4 7.4 12a.9.9 0 0 0 1.2 0c1.8-1.6 7.4-6.9 7.4-12a8 8 0 0 0-8-8Zm0 5.2a2.8 2.8 0 1 1 0 5.6 2.8 2.8 0 0 1 0-5.6Z'
os.makedirs(OUT, exist_ok=True)
def save(name, data):
    json.dump(data, open(os.path.join(OUT, name), 'w'), separators=(',', ':'))

# ===== 1. "What is an eSIM?" — pulsing SIM (170 x 170, seamless 2.4 s loop) =====
D = 2.4; OPF = fr(D)
def ring(name, st, ip, op):
    return layer(name, [group('ring', [ellipse(0, 0, 138), stroke(BLUE, 2, cap=1, join=1)])], op, ip=ip, st=st,
                 p=static([100, 100, 0]),
                 s=anim([(st / FPS, [82, 82, 100], EASE_OUT), (st / FPS + D, [140, 140, 100], None)], 3),  # keyframe times are comp time
                 o=anim([(st / FPS, 55, EASE_OUT), (st / FPS + D, 0, None)], 1))
k = min(56 / 120, 72 / 156); ox_, oy_ = 100 - 28 + (56 - 120 * k) / 2, 100 - 36 + (72 - 156 * k) / 2  # 200px canvas: the 170px art + room for the ring's 1.4x pulse
sim = [group('sim', path_shapes(CARD, k, k, ox_, oy_) + path_shapes(CHIP, k, k, ox_, oy_) + path_shapes(LINES, k, k, ox_, oy_) + [stroke(BLUE, 7 * k)])]
intro = comp('eSIM intro — pulsing SIM', 200, 200, D, [
    ring('ring 1', 0, 0, OPF),
    ring('ring 2 (2nd half)', -fr(1.2), 0, fr(1.2)),
    ring('ring 2', fr(1.2), fr(1.2), OPF),
    layer('disc', [group('disc', [ellipse(100, 100, 136), fill(SOFT)])], OPF),
    layer('sim icon', sim, OPF),
])
save('1-esim-intro.json', intro)

# ===== 2. "Choose your data plan" — globe, pin drop, plan chips (264 x 211, plays once) =====
S = M['search']; W2 = round(S['root']['w']); H2 = round(S['root']['h']); D2 = 2.5; OP2 = fr(D2)
gx = (S['root']['w'] - 140) / 2; g = 140 / 120
globe = [group('outline', [ellipse(60 * g + gx, 60 * g, 110 * g), stroke(BLUE, 2.4 * g, cap=1, join=1)]),
         group('land', path_shapes(PATHS['FC_LAND'], g, g, gx, 0) + [stroke(BLUE, .6 * g), fill(BLUE)]),
         group('sea', [ellipse(60 * g + gx, 60 * g, 110 * g), fill(SOFT)])]
L2 = [layer('globe', globe, OP2)]
px, py = S['pinBox']['x'], S['pinBox']['y']; ps = 32 / 24
L2.append(layer('pin', [group('pin', path_shapes(PIN, ps, ps, px, py) + [fill(SOFT, rule=2)])], OP2,
                p=anim([(0.3, [0, -60, 0], (.3, 1.5, .5, 1)), (0.92, [0, 0, 0], None)], 3),
                o=anim([(0.3, 0, (.3, 1, .5, 1)), (0.3 + .62 * .6, 100, None)], 1)))
for i, (label, c) in enumerate(zip(['3 GB', '5 GB', '10 GB'], S['chips'])):
    t0 = 1.0 + i * .15; sel = i == 1
    cx = c['x'] + c['w'] / 2; base = c['y'] + 14 + ascent(18, 700)
    glyphs, _ = text_shapes(label, 18, 700, cx, base, 'center')
    txt_fill = fill(anim([(2.1, rgb(INK), EASE), (2.36, rgb('#FFFFFF'), None)], 4)) if sel else fill(INK)
    bg_fill = fill(anim([(2.1, rgb('#FFFFFF'), EASE), (2.36, rgb(BLUE), None)], 4)) if sel else fill('#FFFFFF')
    border = stroke(LINE, 1, op=anim([(2.1, 100, EASE), (2.36, 0, None)], 1) if sel else 100, cap=1, join=1)
    L2.append(layer('chip ' + label, [group('label', glyphs + [txt_fill]),
                                     group('border', [rect(c['x'] + .5, c['y'] + .5, c['w'] - 1, c['h'] - 1, 11.5), border]),
                                     group('bg', [rect(c['x'], c['y'], c['w'], c['h'], 12), bg_fill])], OP2,
                    p=anim([(t0, [0, 8, 0], EASE), (t0 + .32, [0, 0, 0], None)], 3),
                    o=anim([(t0, 0, EASE), (t0 + .32, 100, None)], 1)))
save('2-choose-data-plan.json', comp('Choose your data plan — globe, pin & plans', W2, H2, D2, L2))

# ===== 3. "Three steps to get online" — journey timeline (342 x 209, plays once) =====
J = M['journey']; W3 = round(J['root']['w']); H3 = round(J['root']['h']); D3 = 2.5; OP3 = fr(D3)
JR = [('dl', 'Activate your eSIM', 'Add it to your phone in one tap'),
      ('gear', 'Complete setup', 'Name it and turn it on in Settings'),
      ('plane', 'Connect at your destination', 'Turn it on when you land')]
L3 = []
def icon(k, color, x, y):
    s = 22 / 24; shapes = []
    for d in PATHS['P'][k]: shapes += path_shapes(d, s, s, x, y)
    return group('icon ' + k, shapes + [stroke(color, 1.8 * s)])
for i, (k, t, sub) in enumerate(JR):
    d = .35 + i * .7; c = J['circles'][i]; cx, cy = c['x'] + 23, c['y'] + 23
    L3.append(layer('step %d base' % (i + 1), [icon(k, GREY, c['x'] + 12, c['y'] + 12),
                                            group('ring', [ellipse(cx, cy, 44), stroke(LINE, 2, cap=1, join=1)])], OP3))
    L3.append(layer('step %d active' % (i + 1), [icon(k, '#FFFFFF', 12 - 23, 12 - 23), group('dot', [ellipse(0, 0, 46), fill(BLUE)])], OP3,
                    p=static([cx, cy, 0]),
                    s=anim([(d, [0, 0, 100], (.3, 1.4, .5, 1)), (d + .42 * .7, [112, 112, 100], (.3, 1.4, .5, 1)), (d + .42, [100, 100, 100], None)], 3)))
    if i < 2:
        ln = J['lines'][i]
        L3.append(layer('line %d track' % (i + 1), [group('track', [rect(ln['x'], ln['y'], 2, ln['h'], 0), fill(LINE)])], OP3))
        L3.append(layer('line %d fill' % (i + 1), [group('fill', [rect(0, 0, 2, ln['h'], 0), fill(BLUE)])], OP3,
                        p=static([ln['x'], ln['y'], 0]),
                        s=anim([(d + .3, [100, 0, 100], EASE), (d + .68, [100, 100, 100], None)], 3)))
    tt, ts = J['texts'][2 * i], J['texts'][2 * i + 1]
    g1, _ = text_shapes(t, 19, 700, tt['x'], tt['y'] + ascent(19, 700))
    g2, _ = text_shapes(sub, 16, 400, ts['x'], ts['y'] + ascent(16))
    L3.append(layer('step %d text' % (i + 1), [group('title', g1 + [fill(INK)]), group('subtitle', g2 + [fill(INK2)])], OP3,
                    p=anim([(d - .1, [0, 8, 0], EASE), (d + .22, [0, 0, 0], None)], 3),
                    o=anim([(d - .1, 0, EASE), (d + .22, 100, None)], 1)))
save('3-three-steps.json', comp('Three steps to get online — journey', W3, H3, D3, L3))
print('ok', W2, H2, W3, H3)
