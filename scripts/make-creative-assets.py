#!/usr/bin/env python3
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.
"""Builds the App Store creative assets: the product page header and the search results card.

    python3 scripts/make-creative-assets.py <raw-iphone-dir> <out-dir>

- Header, 21:9 at 3840 x 1646: one idea and no headline. The mascot studies the footprint while
  the details any app can read float around him as clues. Everything important sits in the centre
  so nothing is lost when the store crops it.
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

# Illustrative values only: what any app can read without asking.
CLUES = [
    ("Set up", "12 Mar 2024, 09:41:07"), ("Last restart", "3 days, 4 h ago"),
    ("Free space", "41,273,856,512 bytes"), ("Headphones", "“Alex’s Earbuds”"),
    ("Keyboards", "English, Arabic, Emoji"), ("Time zone", "GMT+3"),
    ("Text size", "Larger"), ("Carrier region", "SA"),
    ("Screen", "120 Hz · 460 ppi"), ("Languages", "en-GB, ar"),
]


def glow(w, h, centre_y=0.5):
    bg = Image.new("RGB", (w, h), (0, 0, 0))
    layer = Image.new("RGB", (w, h), (0, 0, 0))
    d = ImageDraw.Draw(layer)
    d.ellipse((w * 0.18, h * (centre_y - 0.55), w * 0.82, h * (centre_y + 0.55)), fill=(44, 33, 23))
    return Image.blend(bg, layer.filter(ImageFilter.GaussianBlur(w * 0.09)), 1.0).convert("RGBA")


def clue(canvas, x, y, label, value, size, alpha, anchor="centre"):
    """A hairline pill: sand label, white value. Faded by distance from the centre."""
    layer = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    lf, vf = font(size, "Semibold"), font(size, "Regular")
    pad_x, pad_y = size * 0.8, size * 0.5
    lw, vw = d.textlength(label, font=lf), d.textlength(value, font=vf)
    w, h = lw + vw + size * 0.7 + pad_x * 2, size + pad_y * 2
    x0 = {"left": x, "right": x - w}.get(anchor, x - w / 2)
    y0 = y - h / 2
    d.rounded_rectangle((x0, y0, x0 + w, y0 + h), h / 2, fill=(20, 17, 14, 255), outline=SAND_DEEP + (255,), width=3)
    d.text((x0 + pad_x, y0 + pad_y - size * 0.1), label, font=lf, fill=SAND + (255,))
    d.text((x0 + pad_x + lw + size * 0.7, y0 + pad_y - size * 0.1), value, font=vf, fill=INK + (255,))
    a = layer.getchannel("A").point(lambda v: int(v * alpha))
    layer.putalpha(a)
    canvas.alpha_composite(layer)


def mascot(height):
    m = Image.open(slides.MASCOT).convert("RGBA")
    return m.resize((int(m.width * height / m.height), height), Image.LANCZOS)


def header(out):
    w, h = 3840, 1646
    c = glow(w, h, 0.55)
    # Clues in two columns either side of the mascot, aligned to its edges and fading outwards.
    rows = [0.18, 0.38, 0.58, 0.78]
    left = [(0.335, rows[0], 0.0), (0.335, rows[1], 0.07), (0.335, rows[2], 0.0), (0.335, rows[3], 0.07)]
    right = [(0.665, rows[0], 0.07), (0.665, rows[1], 0.0), (0.665, rows[2], 0.07), (0.665, rows[3], 0.0)]
    for i, (fx, fy, step) in enumerate(left):
        label, value = CLUES[i]
        clue(c, w * (fx - step), h * fy, label, value, 58, 1.0 - step * 4, anchor="right")
    for i, (fx, fy, step) in enumerate(right):
        label, value = CLUES[4 + i]
        clue(c, w * (fx + step), h * fy, label, value, 58, 1.0 - step * 4, anchor="left")
    m = mascot(1240)
    c.alpha_composite(m, ((w - m.width) // 2, h - m.height - 40))
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
