# /// script
# requires-python = ">=3.11"
# dependencies = ["pillow>=10", "fonttools[woff]>=4.50", "brotli>=1.1"]
#
# [tool.uv]
# # Don't adopt anything published in the last week — a fresh release is the
# # window where a compromised or broken one is still unnoticed. Bump this date
# # only when deliberately updating, then re-run `uv lock --script`.
# exclude-newer = "2026-08-08T00:00:00Z"
# ///
"""Render resources/svgs/intro.svg — the profile intro.

    uv run resources/script/intro.py                      # rebuild from what's here
    uv run resources/script/intro.py ~/Downloads/new.png  # swap wallpaper, then rebuild
    uv run resources/script/intro.py --focus 0.6 --zoom 1.3

Dependencies are declared inline (PEP 723) and pinned by intro.py.lock, which
uv reads and verifies on every run. Nothing is installed into the system or
pyenv interpreter — uv builds an isolated environment under ~/.cache/uv keyed to
this script. There is no .venv to create or keep in sync. After changing the
dependency list or the exclude-newer date above:

    uv lock --script resources/script/intro.py

The SVG is generated, never hand-edited: it carries ~80 KB of base64 wallpaper
and ~11 KB of embedded font, so editing it by hand is not a thing you want to
do. Everything meant to change lives in the CONFIG block below, or in the two
input files that sit next to this script:

    wallpaper.<ext>   the untouched original, in whatever format it arrived as.
                      Copied here from sanji's backdrop-source.png. Passing a
                      path copies that file in and re-renders from it, so this
                      folder always holds the source of the current render.
    ascii.txt         the Jolly Roger, in neofetch's own ${c1}/${c2}/${c3}
                      format — a drop-in copy of
                      ~/.config/neofetch/custom-ascii.txt from the dotfiles repo.

Why everything is inlined: GitHub renders README images inside an <img>, which
puts the SVG in the spec's secure animated mode — external references are not
loaded, and fail silently. Open the file directly and a linked wallpaper looks
fine; on GitHub it renders as an empty pane. Declarative animation *is* allowed,
which is why the cursor can blink. Consequences worth remembering:

    <image href="…">   blocked  -> the wallpaper is a base64 data: URI
    @font-face url()   blocked  -> JetBrains Mono is subset and embedded
    <a href="…">       inert    -> real links belong in README.md, not in here
    <animate>          allowed  -> the block cursor blinks

Design decisions that were measured rather than guessed are noted at the
constant they affect.
"""

from __future__ import annotations

import argparse
import base64
import io
import re
import shutil
import sys
from pathlib import Path

from fontTools.subset import Options, Subsetter
from fontTools.ttLib import TTFont
from PIL import Image

HERE = Path(__file__).resolve().parent
REPO = HERE.parent.parent
OUT = REPO / "resources" / "svgs" / "intro.svg"
ASCII = HERE / "ascii.txt"
WALLPAPER_EXTS = (".png", ".jpg", ".jpeg", ".webp", ".avif")

# ══ CONFIG ══════════════════════════════════════════════════════════════════
# Everything below here is meant to be edited. Everything after the CONFIG
# block is machinery.

# ── palette — Dracula (Official), the scheme wezterm.lua and sanji both use ──
BG_DEEP = "#21222c"
FG      = "#f8f8f2"
PINK    = "#ff79c6"
CYAN    = "#8be9fd"
GREEN   = "#50fa7b"
PURPLE  = "#bd93f9"
YELLOW  = "#f1fa8c"
ORANGE  = "#ffb86c"
RED     = "#ff5555"

# Dracula's comment colour is #6272a4; sanji lifts it to #8995ba for its own
# surfaces. Neither clears AA here — measured against the brightest 2% of the
# blurred cloud behind the pane, #8995ba is 3.88:1. Same hue (225.5) and
# saturation, lifted until it passes on both the pane (5.29:1) and the notch,
# which is laid over the same wallpaper at a similar opacity.
DIM = "#a4aecb"

# The neofetch palette row. Order is the ANSI one: red..white.
SWATCHES = [RED, ORANGE, YELLOW, GREEN, CYAN, PURPLE, PINK, FG]

# ascii.txt writes ${c1}/${c2}/${c3}; neofetch's config.conf sets
# ascii_colors=(1 3 7), so those resolve to ANSI red / yellow / white — which
# under Dracula are these. This is the exact palette a real neofetch run prints.
ASCII_COLOURS = {"c1": RED, "c2": YELLOW, "c3": FG}

# Markers may appear anywhere in a line, not just at the start, and each one
# recolours from that cell onward. That is how the crossbones stay bone-white
# where they pass through the hatband: the band line switches to ${c1} at the
# hat and back to ${c3} at the far bone, rather than painting the whole row red.
# Real neofetch does the same thing with the same file — verified against it —
# so ascii.txt owns the colouring completely and this script holds no
# coordinates describing the drawing.
ASCII_BONE = "c3"      # colour in force before the first marker on a line

# ── content ─────────────────────────────────────────────────────────────────
# Nothing here should need changing when a job does. Anything that moves faster
# than that belongs on the website, which SITE points at.
# Only the label on the prompt line. ascii.txt is still in neofetch's ${cN}
# format, which is what this script parses — fastfetch uses $1..$9 instead, so
# if the dotfiles move over, the art file needs converting before it is a
# drop-in again (or this parser needs to learn both).
COMMAND = "fastfetch"
TITLE_USER, TITLE_HOST = "prateek11rai", "github"

# Add or remove freely — the canvas height is derived from this list, so the
# pane always closes just under the last row.
FIELDS = [
    ("Name",      "Prateek Rai"),
    ("Role",      "Engineer, whichever part of the stack needs one"),
    ("Based",     "Kolkata, India"),
    ("Studied",   "B.Tech CSE · Thapar"),
    ("Site",      "prateek11rai.github.io/sanji"),
    ("Mail",      "prateek11rai@protonmail.com"),
    ("Social",    "linkedin.com/in/prateek11rai"),
    ("Off-clock", "football · anime · Yukio Mishima"),
]

# Shown instead of the grid below NARROW_BP. GitHub renders this file at 308px
# on a 390px phone, where the grid's 17px type would land at 5.2px.
#
# Keep these to glyphs JetBrains Mono actually has — the build warns about any
# it doesn't, which is how ✉ (U+2709, absent) was caught here. ↗ ● · — are all
# present; ✉ ★ ✔ ※ are not.
NARROW_NAME = "Prateek Rai"
NARROW_SUB = "Engineer · Kolkata"
NARROW_LINKS = [("site", "prateek11rai.github.io/sanji"),
                ("mail", "prateek11rai@protonmail.com")]

# The <title> and aria-label. Stated outright rather than assembled out of
# FIELDS, so reordering or renaming a field can't break it.
ALT_TEXT = "Prateek Rai — engineer, Kolkata. prateek11rai.github.io/sanji"

# ── notch ───────────────────────────────────────────────────────────────────
# Instead of a full-width status bar, one small module centred on the top edge:
# flush with it, rounded underneath, carrying the clock and nothing else. The
# rest of the top strip is left as wallpaper.
#
# The clock face is drawn as a path, not typed. Every icon in a normal Waybar
# config is a Nerd Font glyph in the Private Use Area, and plain JetBrains Mono
# has none of them — a patched build would be needed, and there is no way to
# ship one inside an img-rendered SVG. Paths sidestep that entirely.
NOTCH_CLOCK = "11:11"          # static. A real clock would be wrong within the
                               # minute; 11:11 nods to the 11 in the handle.
NOTCH_H = 34                   # height, and how far the pane below has to clear
NOTCH_R = 13                   # bottom-corner radius
NOTCH_PAD = 19                 # space either side of the clock
NOTCH_FS = 15
NOTCH_ICON = True              # False leaves just the time

# The notch is not repeated in the narrow branch. Above the pane there are only
# ~19 rendered px to work with on a phone, so a legible clock will not fit — but
# unlike the fields below it, this is chrome carrying a made-up time, and it
# reads as a notch on shape alone. Content gets the reflow; decoration does not.

# ── canvas ──────────────────────────────────────────────────────────────────
# Only the *width* ratio sets on-screen type size, so W is the number that
# matters. Measured on the live profile: GitHub renders this at 846px on a
# desktop profile page and 308px on a 390px phone, so 17 units here is 14.4px on
# a laptop and 5.2px on a phone. Height is derived below — it follows the number
# of FIELDS rather than being a number to keep in sync by hand.
W = 1000
NARROW_BP = 480        # rendered px, not canvas units
ADV = 0.6              # JetBrains Mono advance width, in em

PAD = 34               # pane padding
PANE_X = 46            # pane inset from the left and right edges
PANE_TOP = 62          # clears the notch, and leaves wallpaper either side of it
PANE_FOOT = 46         # wallpaper left visible below the pane
FS, STEP = 17, 27      # body size, row pitch
ART_W, GUTTER, LABEL_W = 196, 38, 118

# Row offsets inside the pane, all relative to its top edge.
CMD_Y = PAD + 8                 # the `❯ neofetch` line
TITLE_Y = PAD + 46              # user@host
RULE_Y = TITLE_Y + 22           # the ---- under it
GRID_Y = TITLE_Y + 48           # first field row
SWATCH_DROP = 34                # palette row -> prompt
NARROW_Y = PAD + 104            # the big name, on phones
NARROW_SWATCH = 224             # from NARROW_Y down to the palette row
NARROW_CELL = 40

# The wallpaper is dimmed globally, then the pane is laid over it. At the 0.62
# pane opacity that reads as "glass", the pink labels measured 1.97:1 against
# the brightest 2% of the blurred cloud. 0.90 puts them at 4.91:1, foreground at
# 10.99:1 — and is nearer wezterm.lua's own window_background_opacity (0.99)
# than 0.62 ever was. Raise DIM_GLOBAL instead if you swap in a brighter image.
DIM_GLOBAL, DIM_COLOUR = 0.22, "#0d0e16"
PANE_OPACITY = 0.90
NOTCH_OPACITY = 0.88
BLUR = 20              # == macos_window_background_blur in wezterm.lua

# Embedded wallpaper. Two thirds of it ends up dimmed or behind the blur, so it
# survives a low quality setting; this is the single biggest part of the file.
EMBED_WIDTH, EMBED_QUALITY = 1280, 70
FOCUS, ZOOM = 0.42, 1.0            # matches the website's `position: 50% 42%`

# ── fonts ───────────────────────────────────────────────────────────────────
# Subset from the installed family at build time, so adding a character to
# CONFIG above just works. The dotfiles bootstrap installs this via
# `brew install --cask font-jetbrains-mono`.
FONT_FILES = {400: "JetBrainsMono-Regular.ttf", 700: "JetBrainsMono-Bold.ttf"}
FONT_DIRS = [Path.home() / "Library/Fonts", Path("/Library/Fonts"),
             Path.home() / ".local/share/fonts", Path("/usr/share/fonts"),
             Path("/usr/local/share/fonts")]

# ══ MACHINERY ═══════════════════════════════════════════════════════════════

# ── derived geometry ────────────────────────────────────────────────────────
# The pane closes under whichever branch runs taller, and the canvas closes
# under the pane. Editing FIELDS is therefore the whole edit: no height to
# retune, and no chance of the grid growing through the bottom of the window.

SWATCH_Y = GRID_Y + len(FIELDS) * STEP - 6          # palette row, wide branch
PROMPT_Y = SWATCH_Y + SWATCH_DROP
_WIDE_BOTTOM = PROMPT_Y + FS * 0.58                 # bottom of the block cursor
_NARROW_BOTTOM = NARROW_Y + NARROW_SWATCH + NARROW_CELL / 2

PANE_H = round(max(_WIDE_BOTTOM, _NARROW_BOTTOM) + PAD)
H = PANE_TOP + PANE_H + PANE_FOOT
PANE = (PANE_X, PANE_TOP, W - 2 * PANE_X, PANE_H)


class Canvas:
    """Collects SVG nodes and, as a side effect, every character that will be
    printed — so the font subset is derived from the content instead of a
    hand-kept list that silently drifts out of date."""

    def __init__(self) -> None:
        self.parts: list[str] = []
        self.chars: set[str] = set()

    def raw(self, node: str) -> None:
        self.parts.append(node)

    def text(self, x: float, y: float, runs, cls: str = "", anchor: str = "",
             fill: str = "") -> None:
        if isinstance(runs, str):
            runs = [(runs, "")]
        body = ""
        for s, colour in runs:
            self.chars.update(s)
            body += f'<tspan fill="{colour}">{esc(s)}</tspan>' if colour else esc(s)
        a = f' class="{cls}"' if cls else ""
        a += f' text-anchor="{anchor}"' if anchor else ""
        a += f' fill="{fill}"' if fill else ""
        self.parts.append(f'<text{a} x="{x:g}" y="{y:g}">{body}</text>')

    def __str__(self) -> str:
        return "".join(self.parts)


def esc(t: str) -> str:
    return t.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")


def fits(text: str, size: float, avail: float, what: str) -> None:
    need = len(text) * size * ADV
    if need > avail:
        raise SystemExit(
            f"error: {what} does not fit — needs {need:.0f} units, has {avail:.0f}.\n"
            f"       {text!r}\n"
            f"       Shorten it, or widen the column in the CONFIG block.")


# ── the Jolly Roger ─────────────────────────────────────────────────────────
# Each Braille cell encodes a 2x4 dot grid, so the 48x22 character block in
# ascii.txt is really a 96x88 bitmap. Decoding it and re-emitting the dots as
# geometry drops the dependency on the viewer owning a Braille-capable
# monospace font — which is a real dependency: rendered as text, the glyphs fall
# back to whatever font on the machine has coverage, at the wrong advance width,
# and the art shears.
BRAILLE_BITS = {0: (0, 0), 1: (0, 1), 2: (0, 2), 3: (1, 0),
                4: (1, 1), 5: (1, 2), 6: (0, 3), 7: (1, 3)}


MARKER = re.compile(r"\$\{(c\d)\}")


def read_ascii() -> tuple[int, int, list[list[str | None]]]:
    """Decode ascii.txt into a per-dot colour grid.

    A ${cN} marker recolours everything after it until the next one, wherever it
    sits in the line — the same rule neofetch applies, since it just expands
    these as shell variables holding escape sequences.
    """
    if not ASCII.is_file():
        raise SystemExit(f"error: no ascii art at {ASCII}")

    rows: list[list[tuple[str, str]]] = []
    for line in ASCII.read_text(encoding="utf-8").splitlines():
        parts = MARKER.split(line)          # [text, key, text, key, text, ...]
        key, spans = ASCII_BONE, []
        if parts[0]:
            spans.append((key, parts[0]))
        for k, text in zip(parts[1::2], parts[2::2]):
            key = k
            if text:
                spans.append((key, text))
        if any(t.strip("⠀ ") for _, t in spans):
            rows.append(spans)
    if not rows:
        raise SystemExit(f"error: {ASCII} has no art in it")

    stray = {c for spans in rows for _, t in spans for c in t
             if not 0x2800 <= ord(c) <= 0x28FF}
    if stray:
        raise SystemExit(
            f"error: {ASCII.name} must be Braille art (U+2800–U+28FF).\n"
            f"       Found: {''.join(sorted(stray))!r}\n"
            f"       The dot geometry is decoded from the Braille cell encoding, "
            f"so plain ASCII art cannot be converted.")

    unknown = {k for spans in rows for k, _ in spans} - set(ASCII_COLOURS)
    if unknown:
        raise SystemExit(
            f"error: {ASCII.name} uses {sorted(unknown)}, which ASCII_COLOURS "
            f"does not define (it has {sorted(ASCII_COLOURS)}).")

    w = max(sum(len(t) for _, t in spans) for spans in rows) * 2
    h = len(rows) * 4
    grid: list[list[str | None]] = [[None] * w for _ in range(h)]
    for r, spans in enumerate(rows):
        c = 0
        for key, text in spans:
            colour = ASCII_COLOURS[key]
            for ch in text:
                bits = ord(ch) - 0x2800
                for bit, (dx, dy) in BRAILLE_BITS.items():
                    if bits >> bit & 1:
                        grid[r * 4 + dy][c * 2 + dx] = colour
                c += 1

    xs = [x for y in range(h) for x in range(w) if grid[y][x]]
    ys = [y for y in range(h) for x in range(w) if grid[y][x]]
    x0, x1, y0, y1 = min(xs), max(xs), min(ys), max(ys)
    grid = [[grid[y][x] for x in range(x0, x1 + 1)] for y in range(y0, y1 + 1)]
    return x1 - x0 + 1, y1 - y0 + 1, grid


def runs_path(w: int, h: int, grid, want: str | None, fill: str) -> str:
    """Merge each row of lit dots into horizontal runs — 343 rects instead of
    3177, and one <path> per colour."""
    d = []
    for y in range(h):
        x = 0
        while x < w:
            if grid[y][x] is None or (want is not None and grid[y][x] != want):
                x += 1
                continue
            n = 1
            while x + n < w and grid[y][x + n] == grid[y][x]:
                n += 1
            d.append(f"M{x} {y}h{n}v1h-{n}z")
            x += n
    return f'<path fill="{fill}" d="{"".join(d)}"/>' if d else ""


class Mark:
    """The art, as one mask per ink colour filled with a tiled dot pattern —
    a dot-matrix panel rather than a solid fill, which keeps the terminal
    texture and costs the same ~5 KB."""

    # Below this width the dot grid is finer than a device pixel and averages
    # out to a flat blob, so small placements use the merged runs instead.
    DOT_FLOOR = 60

    def __init__(self) -> None:
        self.w, self.h, grid = read_ascii()
        self.colours = sorted({c for row in grid for c in row if c})
        self.defs = "".join(
            f'<mask id="mk{i}">{runs_path(self.w, self.h, grid, col, "#fff")}</mask>'
            f'<pattern id="dt{i}" width="1" height="1" patternUnits="userSpaceOnUse">'
            f'<circle cx=".5" cy=".5" r=".4" fill="{col}"/></pattern>'
            for i, col in enumerate(self.colours))
        self.dotted = "".join(
            f'<g mask="url(#mk{i})"><rect width="{self.w}" height="{self.h}" '
            f'fill="url(#dt{i})"/></g>' for i in range(len(self.colours)))
        self.solid = "".join(runs_path(self.w, self.h, grid, col, col)
                             for col in self.colours)

    def place(self, x: float, y: float, w: float, opacity: float = 1.0) -> str:
        o = f' opacity="{opacity}"' if opacity != 1.0 else ""
        body = self.dotted if w >= self.DOT_FLOOR else self.solid
        return (f'<g{o} transform="translate({x:g} {y:g}) '
                f'scale({w / self.w:g})">{body}</g>')


# ── notch icon ──────────────────────────────────────────────────────────────
# Drawn in a 16x16 box, then scaled. `currentColor` picks up the `color` set on
# the wrapping group, so one definition serves any tint.
ICONS = {
    "clock": ('<circle cx="8" cy="8" r="6.4" fill="none" stroke="currentColor" '
              'stroke-width="1.4"/>'
              '<path d="M8 4.4V8l2.6 1.8" fill="none" stroke="currentColor" '
              'stroke-width="1.4" stroke-linecap="round" stroke-linejoin="round"/>'),
}


def icon(name: str, x: float, y: float, size: float = 15, colour: str = FG) -> str:
    return (f'<g transform="translate({x:g} {y:g}) scale({size / 16:g})" '
            f'fill="{colour}" color="{colour}">{ICONS[name]}</g>')


# ── wallpaper ───────────────────────────────────────────────────────────────
def find_wallpaper() -> Path:
    found = [p for ext in WALLPAPER_EXTS
             for p in HERE.glob(f"wallpaper{ext}")]
    if not found:
        raise SystemExit(
            f"error: no wallpaper in {HERE}\n"
            f"       Expected wallpaper{{{','.join(WALLPAPER_EXTS)}}}.\n"
            f"       Pass one to copy it in:  uv run {rel(Path(__file__))} <image>")
    if len(found) > 1:
        raise SystemExit("error: more than one wallpaper.* here — keep exactly one:\n"
                         + "\n".join(f"       {p.name}" for p in found))
    return found[0]


def adopt(source: Path) -> Path:
    """Copy a new wallpaper in, replacing whatever is here. Mirrors sanji's
    backdrop.py: the repo always holds the source of the current render."""
    if not source.is_file():
        raise SystemExit(f"error: no such file: {source}")
    dst = HERE / f"wallpaper{source.suffix.lower()}"
    # Re-running from the kept copy must be a no-op, not a self-copy.
    if source.resolve() != dst.resolve():
        for old in (p for ext in WALLPAPER_EXTS for p in HERE.glob(f"wallpaper{ext}")):
            if old.resolve() != dst.resolve():
                old.unlink()
        shutil.copy2(source, dst)
    return dst


def encode_wallpaper(path: Path, focus: float, zoom: float) -> tuple[str, int, tuple]:
    img = Image.open(path).convert("RGB")
    target = W / H
    if img.width / img.height > target:
        keep_w, keep_h = round(img.height * target), img.height
    else:
        keep_w, keep_h = img.width, round(img.width / target)
    keep_w = min(img.width, round(keep_w / zoom))
    keep_h = min(img.height, round(keep_h / zoom))
    left = round((img.width - keep_w) * focus)
    top = round((img.height - keep_h) * focus)
    frame = img.resize((EMBED_WIDTH, round(EMBED_WIDTH / target)), Image.LANCZOS,
                       box=(left, top, left + keep_w, top + keep_h))
    buf = io.BytesIO()
    frame.save(buf, "JPEG", quality=EMBED_QUALITY, optimize=True, progressive=True)
    return base64.b64encode(buf.getvalue()).decode(), buf.tell(), img.size


# ── fonts ───────────────────────────────────────────────────────────────────
def find_font(name: str) -> Path:
    for d in FONT_DIRS:
        if d.is_dir():
            hit = next(d.rglob(name), None)
            if hit:
                return hit
    raise SystemExit(
        f"error: {name} not found in any of:\n"
        + "\n".join(f"       {d}" for d in FONT_DIRS)
        + "\n       Install it:  brew install --cask font-jetbrains-mono")


def embed_fonts(chars: set[str]) -> tuple[str, int]:
    text = "".join(sorted(chars))
    faces, total = [], 0
    for weight, name in FONT_FILES.items():
        path = find_font(name)
        # recalcTimestamp=False, or fontTools rewrites head.modified to "now" at
        # compile time and every rebuild differs by a few bytes inside the
        # base64 — a diff on every run even when nothing changed. Setting the
        # field by hand does not work: the compiler overwrites it.
        font = TTFont(path, recalcTimestamp=False)
        have = set()
        for table in font["cmap"].tables:
            have.update(chr(c) for c in table.cmap)
        missing = set(chars) - have - {" "}
        if missing:
            print(f"warning: {name} has no glyph for {''.join(sorted(missing))!r} "
                  f"— it will fall back", file=sys.stderr)
        opts = Options()
        opts.flavor = "woff2"
        opts.layout_features = []
        opts.hinting = False
        opts.desubroutinize = True
        opts.notdef_outline = False
        sub = Subsetter(options=opts)
        sub.populate(text=text)
        sub.subset(font)
        buf = io.BytesIO()
        font.save(buf)
        total += buf.tell()
        faces.append(f'@font-face{{font-family:"JBM";font-weight:{weight};'
                     f'src:url(data:font/woff2;base64,'
                     f'{base64.b64encode(buf.getvalue()).decode()}) format("woff2")}}')
    return "".join(faces), total


def rel(p: Path) -> str:
    try:
        return str(p.resolve().relative_to(REPO))
    except ValueError:
        return str(p)


# ── the drawing ─────────────────────────────────────────────────────────────
def compose(mark: Mark) -> tuple[str, str, set[str]]:
    px, py, pw, _ = PANE
    cx, cy = px + PAD, py + PAD
    right = px + pw - PAD
    ix = cx + ART_W + GUTTER
    vx = ix + LABEL_W

    wide = Canvas()
    wide.text(cx, py + CMD_Y, [("❯", GREEN), ("  " + COMMAND, "")], cls="c")

    wide.text(ix, py + TITLE_Y, [(TITLE_USER, ""), ("@", DIM), (TITLE_HOST, "")],
              cls="t")
    wide.text(ix, py + RULE_Y, "-" * (len(TITLE_USER) + 1 + len(TITLE_HOST)),
              cls="u")

    for i, (key, value) in enumerate(FIELDS):
        fits(key + ":", FS, LABEL_W, f"label {key!r}")
        fits(value, FS, right - vx, f"value for {key!r}")
        wide.text(ix, py + GRID_Y + i * STEP, key + ":", cls="k")
        wide.text(vx, py + GRID_Y + i * STEP, value, cls="v")

    wide.raw(swatches(ix, py + SWATCH_Y, 22, 4))
    wide.raw(prompt(cx, py + PROMPT_Y, FS, wide))

    # Centred on the block it sits beside, not on the pane.
    mh = ART_W * mark.h / mark.w
    wide.raw(mark.place(cx, py + (TITLE_Y - 12 + SWATCH_Y + 11) / 2 - mh / 2, ART_W))

    # ── narrow ──
    narrow = Canvas()
    narrow.raw(mark.place(right - 150, cy - 10, 150, 0.95))
    narrow.text(cx, cy + 14, [("❯", GREEN), (" " + COMMAND, "")], cls="nc")
    ny = py + NARROW_Y
    narrow.text(cx, ny, NARROW_NAME, cls="nt")
    narrow.text(cx, ny + 54, NARROW_SUB, cls="ns")
    for i, (glyph, value) in enumerate(NARROW_LINKS):
        narrow.text(cx, ny + 130 + i * 52, [(glyph, ""), ("  " + value, FG)], cls="nl")
    narrow.raw(swatches(cx, ny + NARROW_SWATCH, NARROW_CELL, 8))
    for t, size in ((NARROW_NAME, 41), (NARROW_SUB, 37),
                    *((f"{g}  {v}", 37) for g, v in NARROW_LINKS)):
        fits(t, size, right - cx, f"narrow row {t[:16]!r}")

    # ── notch ──
    # Sized to its contents so the clock is never off-centre inside it.
    mid = NOTCH_H / 2
    gap = 8
    icon_w = NOTCH_FS if NOTCH_ICON else -gap
    text_w = len(NOTCH_CLOCK) * NOTCH_FS * ADV
    nw = round(icon_w + gap + text_w + 2 * NOTCH_PAD)
    nx = (W - nw) / 2

    bar = Canvas()
    # Square at the top so it reads as part of the screen edge, rounded below.
    bar.raw(f'<path d="M{nx:g} 0h{nw}v{NOTCH_H - NOTCH_R}'
            f'a{NOTCH_R} {NOTCH_R} 0 0 1 -{NOTCH_R} {NOTCH_R}'
            f'h-{nw - 2 * NOTCH_R}'
            f'a{NOTCH_R} {NOTCH_R} 0 0 1 -{NOTCH_R} -{NOTCH_R}z" '
            f'fill="{BG_DEEP}" opacity="{NOTCH_OPACITY}"/>')
    cx0 = nx + NOTCH_PAD
    if NOTCH_ICON:
        bar.raw(icon("clock", cx0, mid - NOTCH_FS / 2, NOTCH_FS, DIM))
        cx0 += icon_w + gap
    bar.text(cx0, mid, NOTCH_CLOCK, cls="bc")

    chars = wide.chars | narrow.chars | bar.chars
    return f'{bar}<g class="w">{wide}</g><g class="n">{narrow}</g>', "", chars


def swatches(x: float, y: float, cell: float, gap: float) -> str:
    return "".join(
        f'<rect x="{x + i * (cell + gap):g}" y="{y:g}" width="{cell:g}" '
        f'height="{cell / 2:g}" rx="1.5" fill="{c}"/>'
        for i, c in enumerate(SWATCHES))


def prompt(x: float, y: float, size: float, canvas: Canvas) -> str:
    """A live prompt. SMIL is the one dynamic thing an <img>-rendered SVG keeps."""
    canvas.chars.add("❯")
    return (f'<text x="{x:g}" y="{y:g}" font-size="{size}" fill="{GREEN}">❯</text>'
            f'<rect x="{x + size * ADV * 2:.1f}" y="{y - size * .58:.1f}" '
            f'width="{size * ADV:.1f}" height="{size * 1.12:.1f}" fill="{FG}">'
            f'<animate attributeName="opacity" values="0;0;.8;.8" dur="1.1s" '
            f'calcMode="discrete" repeatCount="indefinite"/></rect>')


STYLE = """%(faces)s
text{font-family:"JBM",ui-monospace,SFMono-Regular,Menlo,Consolas,monospace;
white-space:pre;dominant-baseline:middle}
.c{font-size:18px;fill:%(fg)s;font-weight:700}
.t{font-size:18px;fill:%(cyan)s;font-weight:700}
.u{font-size:%(fs)dpx;fill:%(dim)s}
.k{font-size:%(fs)dpx;fill:%(pink)s;font-weight:700}
.v{font-size:%(fs)dpx;fill:%(fg)s}
.bc{font-size:%(nfs)dpx;fill:%(fg)s;font-weight:700}
.nc{font-size:34px;fill:%(fg)s;font-weight:700}
.nt{font-size:41px;fill:%(cyan)s;font-weight:700}
.ns{font-size:37px;fill:%(dim)s}
.nl{font-size:37px;fill:%(pink)s}
.n{display:none}
/* Rendered width, not canvas units: an SVG inside an img element gets a
   viewport the size of that box, so this fires on phones and nowhere else.
   Angle brackets are deliberately absent — SVG is parsed as strict XML, and a
   literal tag in here is a tag, even inside a comment inside a style block. */
@media (max-width:%(bp)dpx){.w{display:none}.n{display:inline}}"""


def verify(svg: str) -> None:
    """Check the output before it lands, because both ways this file can break
    are silent. Bad XML renders as a broken-image icon rather than an error —
    a literal angle bracket in a CSS comment did exactly that once. An external
    reference renders as an empty pane, and only when viewed through GitHub.
    """
    import xml.etree.ElementTree as ET

    try:
        root = ET.fromstring(svg)
    except ET.ParseError as e:
        line, col = e.position
        context = svg.splitlines()[line - 1][max(0, col - 70):col + 70]
        raise SystemExit(
            f"error: generated SVG is not well-formed XML — {e}\n"
            f"       line {line}: ...{context}...\n"
            f"       SVG is strict XML: escape any literal angle bracket, "
            f"including inside a style block.")

    external = [e.get("href") or e.get("{http://www.w3.org/1999/xlink}href")
                for e in root.iter()]
    external = [h for h in external if h and not h.startswith(("data:", "#"))]
    if external:
        raise SystemExit(
            "error: generated SVG references something external:\n"
            + "\n".join(f"       {h}" for h in external)
            + "\n       An img-rendered SVG will not load these, and fails "
              "silently. Inline it as a data: URI instead.")

    for tag, why in (("a", "links are inert in an img-rendered SVG — "
                           "put real links in README.md"),
                     ("script", "scripting is disabled in an img-rendered SVG")):
        found = [e for e in root.iter() if e.tag.endswith("}" + tag)]
        if found:
            raise SystemExit(f"error: generated SVG contains {len(found)} "
                             f"<{tag}> element(s): {why}")


def build(wallpaper: Path, focus: float, zoom: float) -> dict:
    mark = Mark()
    body, _, chars = compose(mark)
    faces, font_bytes = embed_fonts(chars)
    b64, jpeg_bytes, source_size = encode_wallpaper(wallpaper, focus, zoom)
    px, py, pw, ph = PANE

    style = STYLE % {"faces": faces, "fg": FG, "cyan": CYAN, "dim": DIM,
                     "pink": PINK, "fs": FS, "bp": NARROW_BP,
                     "nfs": NOTCH_FS}

    svg = f"""<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" width="{W}" height="{H}" role="img" aria-label="{esc(ALT_TEXT)}">
<!-- Generated by resources/script/intro.py — do not edit by hand.
     Rebuild:  uv run resources/script/intro.py -->
<title>{esc(ALT_TEXT)}</title>
<defs>
<style>{style}</style>
<linearGradient id="edge" x1="0" y1="0" x2="1" y2="1">
<stop offset="0" stop-color="{PINK}"/><stop offset=".5" stop-color="{PURPLE}"/>
<stop offset="1" stop-color="{CYAN}"/></linearGradient>
<filter id="blur" x="-8%" y="-8%" width="116%" height="116%"><feGaussianBlur stdDeviation="{BLUR}"/></filter>
<clipPath id="pane"><rect x="{px}" y="{py}" width="{pw}" height="{ph}" rx="14"/></clipPath>
<image id="wall" href="data:image/jpeg;base64,{b64}" x="0" y="0" width="{W}" height="{H}" preserveAspectRatio="xMidYMid slice"/>
{mark.defs}
</defs>
<use href="#wall"/>
<rect width="{W}" height="{H}" fill="{DIM_COLOUR}" opacity="{DIM_GLOBAL}"/>
<g clip-path="url(#pane)">
<use href="#wall" filter="url(#blur)"/>
<rect x="{px}" y="{py}" width="{pw}" height="{ph}" fill="{BG_DEEP}" opacity="{PANE_OPACITY}"/>
</g>
<rect x="{px}" y="{py}" width="{pw}" height="{ph}" rx="14" fill="none" stroke="url(#edge)" stroke-width="2.5"/>
{body}
</svg>
"""
    verify(svg)
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(svg, encoding="utf-8")
    return {"svg": len(svg.encode()), "jpeg": jpeg_bytes, "font": font_bytes,
            "glyphs": len(chars), "source": source_size,
            "mark": (mark.w, mark.h, len(mark.colours))}


def main() -> int:
    ap = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("source", type=Path, nargs="?",
                    help="a new wallpaper. It is copied in next to this script as "
                         "wallpaper.<ext>, replacing the current one, and becomes "
                         "the source for every later run. Omit to rebuild from "
                         "the wallpaper already here.")
    ap.add_argument("--focus", type=float, default=FOCUS,
                    help=f"0 = keep the top of the frame, 1 = the bottom "
                         f"(default {FOCUS}, matching the website's crop). Only "
                         f"affects the axis being trimmed.")
    ap.add_argument("--zoom", type=float, default=ZOOM,
                    help=f"crop tighter than necessary (default {ZOOM}). Needed for "
                         f"--focus to do anything: the source is 16:9 and the canvas "
                         f"is {W}:{H}, which leaves almost nothing to trim.")
    args = ap.parse_args()

    if not 0.0 <= args.focus <= 1.0:
        raise SystemExit("error: --focus must be between 0 and 1")
    if args.zoom < 1.0:
        raise SystemExit("error: --zoom must be at least 1.0")

    wallpaper = adopt(args.source) if args.source else find_wallpaper()
    r = build(wallpaper, args.focus, args.zoom)

    print(f"wallpaper  {rel(wallpaper)}  {r['source'][0]}x{r['source'][1]}")
    print(f"ascii      {rel(ASCII)}  {r['mark'][0]}x{r['mark'][1]} dots, "
          f"{r['mark'][2]} colours")
    print(f"\nwrote {rel(OUT)}  {r['svg'] / 1024:.1f} KB")
    print(f"  wallpaper  {r['jpeg'] / 1024:6.1f} KB jpeg "
          f"-> {r['jpeg'] * 4 / 3 / 1024:.1f} KB base64")
    print(f"  fonts      {r['font'] / 1024:6.1f} KB woff2, "
          f"{r['glyphs']} glyphs subset from content")
    print(f"  rest       {(r['svg'] - r['jpeg'] * 4 / 3 - r['font'] * 4 / 3) / 1024:6.1f} KB"
          f"  markup, art geometry, css")
    if args.focus != FOCUS or args.zoom != ZOOM:
        print(f"\nreproduce:  uv run {rel(Path(__file__))} "
              f"--focus {args.focus} --zoom {args.zoom}")
        print("(set FOCUS/ZOOM in the CONFIG block to make it the default)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
