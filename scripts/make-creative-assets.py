#!/usr/bin/env python3
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.
"""Builds the App Store creative assets: the product page header and the search results card.

    python3 scripts/make-creative-assets.py <raw-iphone-dir> <out-dir>

- Header, 21:9 at 3840 x 1646: theatrical, no headline. The detective in a spotlight on a dark stage,
  his glowing digital footprint at his feet, between six things an app can learn on digital glass cards. Laid out inside the area that both
  the iPhone and the iPad crop keep (see header()).
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
    ("Your dating life", "from your dating apps"), ("Your first name", "from your headphones’ name"),
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


CYAN = (110, 210, 255)


def glass_width(label, value):
    d = ImageDraw.Draw(Image.new("RGB", (8, 8)))
    return max(d.textlength(label, font=font(66, "Semibold")), d.textlength(value, font=font(50, "Regular"))) + 44 * 2 + 20 + 26


def glass_card(canvas, x, y, label, value, anchor, w):
    """Digital glass: the stage behind it frosted, a faint cyan tint and a bright hairline edge
    that catches the light on top, with a soft cyan glow around it."""
    lf, vf = font(66, "Semibold"), font(50, "Regular")
    pad_x, pad_y, dot, r = 44, 28, 20, 38
    h = int(66 + 50 + 16 + pad_y * 2)
    x0 = int(x - w if anchor == "right" else x); y0 = int(y - h / 2); x1, y1 = int(x0 + w), y0 + h
    mask = Image.new("L", canvas.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((x0, y0, x1, y1), r, fill=255)
    # Outer glow
    glow_l = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    ImageDraw.Draw(glow_l).rounded_rectangle((x0, y0, x1, y1), r, outline=(*CYAN, 230), width=16)
    canvas.alpha_composite(glow_l.filter(ImageFilter.GaussianBlur(34)))
    # Frosted body: blurred, lifted background plus a cool tint
    frost = canvas.filter(ImageFilter.GaussianBlur(30))
    tint = Image.new("RGBA", canvas.size, (90, 180, 255, 30))
    frost = Image.alpha_composite(frost, tint)
    canvas.paste(frost, (0, 0), mask)
    # Light catching the top edge, and the hairline border
    top = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    td = ImageDraw.Draw(top)
    for i in range(h // 2):
        td.line((x0, y0 + i, x1, y0 + i), fill=(200, 235, 255, int(40 * (1 - i / (h / 2)))))
    canvas.paste(Image.alpha_composite(canvas, top), (0, 0), mask)
    d = ImageDraw.Draw(canvas)
    d.rounded_rectangle((x0, y0, x1, y1), r, outline=(150, 220, 255, 210), width=3)
    d.line((x0 + r, y0 + 1, x1 - r, y0 + 1), fill=(235, 248, 255, 230), width=2)
    tx = x0 + pad_x + dot + 26
    d.ellipse((x0 + pad_x, y0 + pad_y + 26, x0 + pad_x + dot, y0 + pad_y + 26 + dot), fill=CORAL)
    d.text((tx, y0 + pad_y - 6), label, font=lf, fill=INK)
    d.text((tx, y0 + pad_y + 66 + 10), value, font=vf, fill=(196, 214, 228))


def header(out):
    """Theatrical (owner, 2026-11-05): a dark stage, one spotlight on the detective and the glowing
    digital footprint at his feet, six things an app can learn on digital glass cards. No curtains
    (owner). No headline. Everything that matters
    sits in the area both crops keep: iPhone shows the full height but only the middle ~84% of the
    width, with buttons over the top corners; iPad shows the full width but loses ~15% top and
    bottom, with the tab bar over the top centre. Safe: x 0.10-0.90, y 0.30-0.85."""
    import random
    random.seed(7)
    w, h = 3840, 1646
    c = Image.new("RGBA", (w, h), (0, 0, 0, 255))
    floor_y = int(h * 0.84)
    # Stage floor: warm boards rising out of the dark behind the detective, fading again at the front.
    floor = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    fd = ImageDraw.Draw(floor)
    top = int(h * 0.62)
    for y in range(top, h):
        t = (y - top) / (h - top)
        a = int(170 * min(1, t / 0.35) * (1 - max(0, t - 0.55) / 0.45))
        fd.line((0, y, w, y), fill=(36, 27, 19, a))
    c.alpha_composite(floor.filter(ImageFilter.GaussianBlur(12)))
    # The spotlight: a beam from above the centre, widening onto a pool of light on the boards.
    beam = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    bd = ImageDraw.Draw(beam)
    bd.polygon([(w * 0.47, -40), (w * 0.53, -40), (w * 0.66, floor_y), (w * 0.34, floor_y)], fill=(255, 236, 205, 46))
    c.alpha_composite(beam.filter(ImageFilter.GaussianBlur(90)))
    pool = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    ImageDraw.Draw(pool).ellipse((w * 0.31, floor_y - h * 0.07, w * 0.69, floor_y + h * 0.08), fill=(255, 226, 180, 120))
    c.alpha_composite(pool.filter(ImageFilter.GaussianBlur(70)))
    # Dust drifting in the beam.
    dust = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    dd = ImageDraw.Draw(dust)
    for _ in range(160):
        y = random.uniform(0.02, 0.80) * h
        half = (0.03 + 0.13 * y / floor_y) * w
        x = w / 2 + random.uniform(-half, half)
        r = random.uniform(2, 6)
        dd.ellipse((x - r, y - r, x + r, y + r), fill=(255, 240, 215, random.randint(40, 130)))
    c.alpha_composite(dust.filter(ImageFilter.GaussianBlur(1.5)))
    # The detective, centre stage, feet on the boards.
    m = mascot(int(h * 0.60))
    c.alpha_composite(m, ((w - m.width) // 2 + int(w * 0.02), floor_y + int(h * 0.04) - m.height))
    # A soft vignette pulls the eye to the light.
    vig = Image.new("L", (w, h), 0)
    ImageDraw.Draw(vig).ellipse((-w * 0.15, -h * 0.35, w * 1.15, h * 1.25), fill=255)
    vig = vig.filter(ImageFilter.GaussianBlur(260))
    black = Image.new("RGBA", (w, h), (0, 0, 0, 255))
    c = Image.composite(c, black, vig)
    # Six things an app can learn, on digital glass cards either side of the spotlight.
    m_left, m_right = w / 2 - w * 0.125, w / 2 + w * 0.15
    lw = max(glass_width(*x) for x in CONCERNS[:3])
    rw = max(glass_width(*x) for x in CONCERNS[3:])
    for i, fy in enumerate((0.42, 0.58, 0.74)):
        glass_card(c, m_left, h * fy, *CONCERNS[i], anchor="right", w=lw)
        glass_card(c, m_right, h * fy, *CONCERNS[3 + i], anchor="left", w=rw)
    c.convert("RGB").save(out / "header-3840x1646.png", optimize=True)


def play_feature(out, header_png):
    """Google Play's feature graphic, 1024 x 500: the same stage as the App Store header, cropped
    to its centre so the curtains still frame the spotlight."""
    h = Image.open(header_png).convert("RGB")
    cw = int(h.height * 1024 / 500)
    x0 = (h.width - cw) // 2
    h.crop((x0, 0, x0 + cw, h.height)).resize((1024, 500), Image.LANCZOS).save(out / "play-feature-1024x500.png", optimize=True)


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
    play_feature(out, out / "header-3840x1646.png")
    print(out)
