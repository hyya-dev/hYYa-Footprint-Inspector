#!/usr/bin/env python3
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.
"""Builds the App Store creative assets: the product page header and the search results card.

    python3 scripts/make-creative-assets.py <raw-iphone-dir> <out-dir>

- Header, 21:9 at 3840 x 1646: one idea and no headline. The mascot studies the footprint between
  six things an app can learn, everyday and sensitive, flagged like the app's findings. Laid out inside the
  area that both the iPhone and the iPad crop keep (see header()).
- Search results, 3:2 at 3840 x 2560: says what the app does at a glance and shows the real
  interface, as Apple advises. The headline, three iPhone screens (the mascot is on the centre one) are all centred.
Quiet Noir palette, shared with the slides. No alpha channel (Apple rejects transparency).
"""
import importlib.util, sys
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parent.parent
spec = importlib.util.spec_from_file_location("slides", ROOT / "scripts/make-store-slides.py")
slides = importlib.util.module_from_spec(spec); spec.loader.exec_module(slides)
font, device, draw_headline = slides.font, slides.device, slides.draw_headline
SAND, SAND_DEEP, INK, MUTED = slides.SAND, slides.SAND_DEEP, slides.INK, slides.MUTED

# A mix of everyday signals and sensitive inferences from installed apps. Sensitive ones use only
# categories the app really checks (App/Sources/Sensitive/SensitiveCatalogue.swift), so the header
# never promises more than the app shows. Coral dot, like the app's "worth a look" findings.
CONCERNS = [
    ("Your dating life", "dating and LGBTQ+ apps"), ("Your first name", "from your headphones’ name"),
    ("Your health", "period, fertility, therapy apps"), ("A unique fingerprint", "links you across apps"),
    ("Your money", "crypto and betting apps"), ("Where you’ve been", "with Photos access"),
]
CORAL = (236, 127, 106)

def glow(w, h, centre_y=0.5):
    bg = Image.new("RGB", (w, h), (0, 0, 0))
    layer = Image.new("RGB", (w, h), (0, 0, 0))
    d = ImageDraw.Draw(layer)
    d.ellipse((w * 0.18, h * (centre_y - 0.55), w * 0.82, h * (centre_y + 0.55)), fill=(44, 33, 23))
    return Image.blend(bg, layer.filter(ImageFilter.GaussianBlur(w * 0.09)), 1.0).convert("RGBA")


def mascot(height):
    m = Image.open(slides.MASCOT).convert("RGBA")
    return m.resize((int(m.width * height / m.height), height), Image.LANCZOS)


def concern_width(label, value):
    d = ImageDraw.Draw(Image.new("RGB", (8, 8)))
    return max(d.textlength(label, font=font(72, "Semibold")), d.textlength(value, font=font(54, "Regular"))) + 46 * 2 + 22 + 26


def concern(canvas, x, y, label, value, anchor, w):
    """A two-line hairline card: coral dot and white label, muted source underneath."""
    d = ImageDraw.Draw(canvas)
    lf, vf = font(72, "Semibold"), font(54, "Regular")
    pad_x, pad_y, dot = 46, 30, 22
    h = 72 + 54 + 18 + pad_y * 2
    x0 = x - w if anchor == "right" else x
    y0 = y - h / 2
    d.rounded_rectangle((x0, y0, x0 + w, y0 + h), 40, fill=(20, 17, 14), outline=SAND_DEEP, width=3)
    tx = x0 + pad_x + dot + 26
    d.ellipse((x0 + pad_x, y0 + pad_y + 30, x0 + pad_x + dot, y0 + pad_y + 30 + dot), fill=CORAL)
    d.text((tx, y0 + pad_y - 6), label, font=lf, fill=INK)
    d.text((tx, y0 + pad_y + 72 + 12), value, font=vf, fill=MUTED)


def header(out):
    """Everything sits in the area both crops keep: iPhone shows the full height but only the middle
    ~84% of the width, with buttons over the top corners; iPad shows the full width but loses ~15%
    top and bottom, with the tab bar over the top centre. Safe: x 0.10–0.90, y 0.30–0.85."""
    w, h = 3840, 1646
    c = glow(w, h, 0.57)
    m = mascot(int(h * 0.55))
    c.alpha_composite(m, ((w - m.width) // 2, int(h * 0.85) - m.height))
    gap = 70
    left_edge, right_edge = (w - m.width) / 2 - gap, (w + m.width) / 2 + gap
    lw = max(concern_width(*x) for x in CONCERNS[:3])
    rw = max(concern_width(*x) for x in CONCERNS[3:])
    for i, fy in enumerate((0.445, 0.60, 0.755)):
        concern(c, left_edge, h * fy, *CONCERNS[i], anchor="right", w=lw)
        concern(c, right_edge, h * fy, *CONCERNS[3 + i], anchor="left", w=rw)
    c.convert("RGB").save(out / "header-3840x1646.png", optimize=True)


def search_results(raw, out):
    w, h = 3840, 2560
    c = glow(w, h, 0.62)
    d = ImageDraw.Draw(c)
    # Headline, centred
    text = "See what apps can *learn about your device*"
    f = font(150, "Bold")
    probe = ImageDraw.Draw(Image.new("RGB", (10, 10)))
    plain = text.replace("*", "")
    tw = probe.textlength(plain, font=f)
    y = draw_headline(d, text, (w - tw) / 2, 170, w, 150)
    sub = "A calm privacy checkup, with a fix for each finding"
    sf = font(78, "Regular")
    d.text(((w - d.textlength(sub, font=sf)) / 2, y + 40), sub, font=sf, fill=MUTED)
    d.rounded_rectangle((w / 2 - 70, y + 170, w / 2 + 70, y + 178), 4, fill=SAND)

    # Three real screens, the middle one raised, running off the bottom edge
    top = y + 300
    screens = [("store-06-checkup", -1), ("store-02-results", 0), ("store-04-finding", 1)]
    for name, pos in sorted(screens, key=lambda s: abs(s[1]), reverse=True):
        fw = 900 if pos == 0 else 800
        frame = device(Image.open(raw / f"{name}.png"), fw)
        x = w / 2 - frame.width / 2 + pos * 980
        fy = top + (0 if pos == 0 else 160)
        shadow = Image.new("RGBA", c.size, (0, 0, 0, 0))
        ImageDraw.Draw(shadow).rounded_rectangle((x + 20, fy + 40, x + frame.width + 20, fy + frame.height + 40), 120, fill=(0, 0, 0, 210))
        c.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(50)))
        c.alpha_composite(frame, (int(x), int(fy)))
    c.convert("RGB").save(out / "search-results-3840x2560.png", optimize=True)


if __name__ == "__main__":
    raw, out = Path(sys.argv[1]), Path(sys.argv[2])
    out.mkdir(parents=True, exist_ok=True)
    header(out)
    search_results(raw, out)
    print(out)
