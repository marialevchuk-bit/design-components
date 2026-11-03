"""Builds prototype.html: inlines GeneralSans, the shared bench styles, the spec
and the Flutter code.

Run from the repo root:  python3 motion/cta-icons/build.py
"""
import base64
import html
import pathlib
import re

here = pathlib.Path(__file__).parent
root = here.parent.parent

faces = []
for weight, name in [(400, "Regular"), (500, "Medium"), (600, "Semibold")]:
    data = base64.b64encode((root / "fonts" / f"GeneralSans-{name}.woff2").read_bytes()).decode()
    faces.append(
        '@font-face{font-family:"GeneralSans";font-style:normal;font-weight:%d;font-display:swap;'
        'src:url(data:font/woff2;base64,%s) format("woff2")}' % (weight, data)
    )

# Controls, timeline and handoff styles are shared with the top-up prototype.
topup = (root / "motion" / "topup-rolling" / "prototype.src.html").read_text()
bench = re.search(r"/\* ---- Controls ---- \*/.*?\.tscroll \{[^}]*\}", topup, re.S).group(0)

page = (here / "prototype.src.html").read_text()
page = page.replace("/*@@FONTS@@*/", "\n".join(faces))
page = page.replace("/*@@BENCH@@*/", bench)
page = page.replace("@@SPEC@@", html.escape((here / "spec.txt").read_text()))
page = page.replace("@@DART@@", html.escape((here / "cta_icon_animations.dart").read_text()))
(here / "prototype.html").write_text(page)
print("wrote", here / "prototype.html", len(page), "bytes")
