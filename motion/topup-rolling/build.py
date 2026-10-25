"""Builds prototype.html: inlines GeneralSans, the spec and the Flutter widget.

Run from the repo root:  python3 motion/topup-rolling/build.py
"""
import base64
import html
import pathlib
import sys

here = pathlib.Path(__file__).parent
root = here.parent.parent
src = pathlib.Path(sys.argv[1]) if len(sys.argv) > 1 else here / "prototype.src.html"

faces = []
for weight, name in [(400, "Regular"), (500, "Medium"), (600, "Semibold")]:
    data = base64.b64encode((root / "fonts" / f"GeneralSans-{name}.woff2").read_bytes()).decode()
    faces.append(
        '@font-face{font-family:"GeneralSans";font-style:normal;font-weight:%d;font-display:swap;'
        'src:url(data:font/woff2;base64,%s) format("woff2")}' % (weight, data)
    )

page = src.read_text()
page = page.replace("/*@@FONTS@@*/", "\n".join(faces))
page = page.replace("@@SPEC@@", html.escape((here / "spec.txt").read_text()))
page = page.replace("@@DART@@", html.escape((here / "top_up_data_meter.dart").read_text()))
(here / "prototype.html").write_text(page)
print("wrote", here / "prototype.html", len(page), "bytes")
