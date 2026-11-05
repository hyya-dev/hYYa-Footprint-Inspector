#!/usr/bin/env python3
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.
"""Builds the App Store creative assets: the product page header and the search results card.

    python3 scripts/make-creative-assets.py <raw-iphone-dir> <out-dir>

- Header, 21:9 at 3840 x 1646: theatrical, no headline. The detective in a spotlight on a dark stage,
  his glowing digital footprint at his feet, between six things an app can learn on a detective's sticky notes. Laid out inside the area that both
  the iPhone and the iPad crop keep (see header()).
- Search results, 3:2 at 3840 x 2560: says what the app does at a glance and shows the real
  interface, as Apple advises. The headline, three iPhone screens (the mascot is on the centre one) are all centred.
Quiet Noir palette, shared with the slides. No alpha channel (Apple rejects transparency).
"""
import importlib.util, sys
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter, ImageFont

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


def sticky_note(canvas, cx, cy, label, value, angle, colour, wear, pin):
    """A detective's sticky note, aged: each one its own colour, pin and wear (a rolled corner, a
    cut corner, a torn edge, a coffee ring, a dog-ear, tape and yellowing), slightly askew, with a
    soft shadow on the stage. Clue in marker, where it comes from in pen."""
    import random
    rnd = random.Random(label)
    marker = ImageFont.truetype("/System/Library/Fonts/Supplemental/MarkerFelt.ttc", 64, index=1)
    pen = ImageFont.truetype("/System/Library/Fonts/Supplemental/Noteworthy.ttc", 42, index=0)
    probe = ImageDraw.Draw(Image.new("RGB", (8, 8)))
    nw = int(max(probe.textlength(label, font=marker), probe.textlength(value, font=pen)) + 100)
    nh = 250
    pad = 60
    W, H = nw + pad * 2, nh + pad * 2
    x0, y0, x1, y1 = pad, pad, pad + nw, pad + nh
    # The paper's outline, shaped by the wear.
    shape = [(x0, y0), (x1, y0), (x1, y1), (x0, y1)]
    if wear == "cut":                       # a corner snipped off
        shape = [(x0 + 70, y0), (x1, y0), (x1, y1), (x0, y1), (x0, y0 + 70)]
    elif wear == "torn":                    # a ragged bottom edge
        edge = [(x1, y1 - 6)]
        x = x1
        while x > x0:
            x -= rnd.randint(14, 30); edge.append((max(x, x0), y1 - rnd.randint(0, 22)))
        shape = [(x0, y0), (x1, y0)] + edge + [(x0, y1 - 10)]
    elif wear == "curl":                    # bottom-right corner rolled up
        shape = [(x0, y0), (x1, y0), (x1, y1 - 80), (x1 - 80, y1), (x0, y1)]
    elif wear == "dogear":                  # top-right corner folded over
        shape = [(x0, y0), (x1 - 64, y0), (x1, y0 + 64), (x1, y1), (x0, y1)]
    mask = Image.new("L", (W, H), 0); ImageDraw.Draw(mask).polygon(shape, fill=255)
    note = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    shadow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    shadow.putalpha(mask.point(lambda v: int(v * 0.8)))
    note.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(20)), (10, 22))
    # Paper: its colour dimmed for a dark room, a darker sticky strip, light falling off downwards.
    r, g, b = (int(v * 0.84) for v in colour)
    paper = Image.new("RGBA", (W, H), (0, 0, 0, 0)); pd = ImageDraw.Draw(paper)
    for i in range(nh):
        k = 1.0 - 0.12 * i / nh
        pd.line((x0, y0 + i, x1, y0 + i), fill=(int(r * k), int(g * k), int(b * k), 255))
    pd.rectangle((x0, y0, x1, y0 + 44), fill=(int(r * 0.9), int(g * 0.9), int(b * 0.88), 255))
    if wear == "aged":                      # yellowed, browned edges and a crease
        edge = Image.new("L", (W, H), 0)
        ImageDraw.Draw(edge).rectangle((x0, y0, x1, y1), outline=255, width=26)
        brown = Image.new("RGBA", (W, H), (120, 84, 30, 0)); brown.putalpha(edge.filter(ImageFilter.GaussianBlur(18)).point(lambda v: int(v * 0.55)))
        paper.alpha_composite(brown)
        pd.line((x0 + nw * 0.62, y0, x0 + nw * 0.55, y1), fill=(int(r * 0.78), int(g * 0.78), int(b * 0.76), 255), width=3)
    if wear == "coffee":                    # a coffee ring in the corner
        ring = Image.new("RGBA", (W, H), (0, 0, 0, 0)); rd = ImageDraw.Draw(ring)
        cx2, cy2, rr = x1 - 70, y1 - 60, 78
        rd.ellipse((cx2 - rr, cy2 - rr, cx2 + rr, cy2 + rr), outline=(110, 70, 30, 120), width=9)
        rd.ellipse((cx2 - rr + 8, cy2 - rr + 4, cx2 + rr - 4, cy2 + rr - 6), outline=(110, 70, 30, 50), width=4)
        paper.alpha_composite(ring.filter(ImageFilter.GaussianBlur(2)))
    paper.putalpha(Image.composite(paper.getchannel("A"), Image.new("L", (W, H), 0), mask))
    note.alpha_composite(paper)
    nd = ImageDraw.Draw(note)
    if wear == "curl":                      # the rolled-up flap, lit on its back
        nd.polygon([(x1, y1 - 80), (x1 - 80, y1), (x1 - 92, y1 - 92)], fill=(int(r * 1.0), int(g * 0.98), int(b * 0.9), 255))
        nd.line((x1, y1 - 80, x1 - 92, y1 - 92), fill=(int(r * 0.7), int(g * 0.7), int(b * 0.65), 255), width=2)
    if wear == "dogear":                    # the folded-over corner
        nd.polygon([(x1 - 64, y0), (x1, y0 + 64), (x1 - 64, y0 + 64)], fill=(int(r * 0.74), int(g * 0.74), int(b * 0.7), 255))
    # Fixing: a pin of its own colour, or a strip of tape.
    if pin == "tape":
        tape = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        ImageDraw.Draw(tape).rectangle((x0 + nw / 2 - 70, y0 - 22, x0 + nw / 2 + 70, y0 + 26), fill=(235, 230, 210, 120))
        note.alpha_composite(tape.rotate(-6, resample=Image.BICUBIC, center=(x0 + nw / 2, y0)))
    else:
        px, py = x0 + nw // 2, y0 + 24
        nd.ellipse((px - 22, py - 22, px + 22, py + 22), fill=(*pin, 255))
        nd.ellipse((px - 10, py - 14, px + 2, py - 2), fill=tuple(min(255, int(v * 1.5) + 40) for v in pin) + (255,))
    ink, pen_ink = (34, 30, 40, 255), (60, 56, 70, 255)
    nd.text((x0 + 50, y0 + 70), label, font=marker, fill=ink)
    nd.text((x0 + 50, y0 + 158), value, font=pen, fill=pen_ink)
    note = note.rotate(angle, resample=Image.BICUBIC, expand=True)
    canvas.alpha_composite(note, (int(cx - note.width / 2), int(cy - note.height / 2)))


def header(out):
    """Theatrical (owner, 2026-11-05): a dark stage, one spotlight on the detective and the glowing
    digital footprint at his feet, six things an app can learn on a detective's sticky notes. No curtains
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
    # A pool of light on the boards where he stands (no beam from above: owner).
    pool = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    ImageDraw.Draw(pool).ellipse((w * 0.31, floor_y - h * 0.07, w * 0.69, floor_y + h * 0.08), fill=(255, 226, 180, 120))
    c.alpha_composite(pool.filter(ImageFilter.GaussianBlur(70)))
    # The detective, centre stage: the owner's dark artwork (store/creative/mascot-dark.jpg), its
    # near-black ground feathered into the stage so only he and his glowing footprint show.
    art = Image.open(ROOT / "store/creative/mascot-dark.jpg").convert("RGB")
    size = int(h * 0.86)
    art = art.resize((size, size), Image.LANCZOS)
    feather = Image.new("L", (size, size), 0)
    ImageDraw.Draw(feather).ellipse((size * 0.06, size * 0.04, size * 0.94, size * 1.02), fill=255)
    feather = feather.filter(ImageFilter.GaussianBlur(size * 0.07))
    # Keep only what is lighter than the artwork's ground, so no dark square shows on the stage.
    lum = art.convert("L").point(lambda v: 0 if v < 14 else min(255, (v - 14) * 6))
    from PIL import ImageChops
    alpha = ImageChops.multiply(feather, lum)
    piece = art.convert("RGBA"); piece.putalpha(alpha)
    c.alpha_composite(piece, ((w - size) // 2, int(h * 0.95) - size))
    # A soft vignette pulls the eye to the light.
    vig = Image.new("L", (w, h), 0)
    ImageDraw.Draw(vig).ellipse((-w * 0.15, -h * 0.35, w * 1.15, h * 1.25), fill=255)
    vig = vig.filter(ImageFilter.GaussianBlur(260))
    black = Image.new("RGBA", (w, h), (0, 0, 0, 255))
    c = Image.composite(c, black, vig)
    # Six things an app can learn, on a detective's aged sticky notes either side of him.
    spots = [(0.27, 0.40, -4), (0.225, 0.575, 3), (0.28, 0.745, -2), (0.73, 0.40, 3), (0.775, 0.575, -3), (0.72, 0.745, 2)]
    # Each note its own colour, wear and fixing (owner, 2026-11-05): no two alike.
    notes = [((240, 214, 110), "curl", (178, 34, 34)),     # yellow, rolled corner, red pin
             ((236, 170, 170), "cut", (40, 90, 170)),      # pink, snipped corner, blue pin
             ((170, 214, 170), "coffee", (40, 130, 70)),   # mint, coffee ring, green pin
             ((160, 200, 230), "torn", (220, 180, 40)),    # blue, torn edge, yellow pin
             ((240, 178, 110), "dogear", (230, 230, 230)), # orange, folded corner, white pin
             ((236, 224, 196), "aged", "tape")]            # cream, yellowed and creased, taped
    for (fx, fy, angle), (colour, wear, pin), (label, value) in zip(spots, notes, CONCERNS):
        sticky_note(c, w * fx, h * fy, label, value, angle, colour, wear, pin)
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
