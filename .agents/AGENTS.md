# prateek11rai/prateek11rai — agent & contributor guide

The GitHub **profile repo**. Its whole job is `README.md`, which renders one
image: a terminal-on-a-desktop intro card. There is no site, no build pipeline,
no deploy — GitHub reads the README and that is the product.

This file is the source of truth for how to work here. `.claude/CLAUDE.md` is a
symlink to it, so [Claude Code](https://claude.com/claude-code) — which reads
`CLAUDE.md`, not `AGENTS.md` — and other agent tools all read the same rules
from one file.

## The one rule

**Never hand-edit `resources/svgs/intro.svg`.** It is generated. It carries
~78 KB of base64 wallpaper and ~9 KB of embedded font, so it is not a file
anyone can meaningfully edit by hand, and any edit is lost on the next build.

Everything you might want to change — text, palette, layout, the notch, the
wallpaper crop — is a constant in the `CONFIG` block at the top of
`resources/script/intro.py`. Change it there and re-run.

## The generator

`resources/script/intro.py` reads three things from its own directory and
writes one file:

| in | |
|---|---|
| `wallpaper.<ext>` | the untouched original, copied from sanji's `backdrop-source.png` |
| `ascii.txt` | the Jolly Roger, in neofetch's `${c1}`/`${c2}`/`${c3}` format |
| the `CONFIG` block | palette, fields, notch, canvas, layout |

| out | |
|---|---|
| `resources/svgs/intro.svg` | ~102 KB, self-contained, responsive |

The SVG reflows below 480 rendered px: GitHub shows it at ~846 px on a desktop
profile and ~308 px on a phone, where the desktop grid's type would land at
about 5 px. Both layouts live in the same file, switched by a CSS media query.

## Prerequisites

- **[uv](https://docs.astral.sh/uv/)** — `brew install uv`. Dependencies are
  declared inline (PEP 723) and pinned by `intro.py.lock`, which uv verifies on
  every run. Nothing installs into the system or pyenv interpreter, and there is
  no `.venv` to create.
- **JetBrains Mono**, installed — `brew install --cask font-jetbrains-mono`.
  The script subsets it at build time from the characters the SVG actually
  prints. It fails with the install command if the font is missing.

## Running it

```sh
uv run resources/script/intro.py                      # rebuild from what's here
uv run resources/script/intro.py ~/Downloads/new.png  # swap wallpaper, then rebuild
uv run resources/script/intro.py --focus 0.6 --zoom 1.3
```

Passing an image copies it in as `wallpaper.<ext>`, replacing the previous one,
so the folder always holds the source of the current render. Re-running from
the kept copy is a no-op, not a self-copy.

After changing the dependency list or the `exclude-newer` date:

```sh
uv lock --script resources/script/intro.py
```

Output is byte-reproducible: same inputs, same bytes. If a rebuild produces a
diff, something actually changed.

## What the build checks

Failures here are loud on purpose, because every one of them is silent in a
browser:

- **Well-formed XML** — SVG is parsed strictly, so a literal `<` anywhere,
  including inside a CSS comment, renders as a broken-image icon.
- **No external references** — see below.
- **No `<a>` or `<script>`** — both are inert in this context.
- **Text fits its column**, and the grid fits the pane. Both are assertions with
  the offending string in the message.
- **Every character has a glyph** — warns rather than silently falling back.

## Why everything is inlined

GitHub renders README images inside an `<img>`, which puts the SVG in the SVG
spec's *secure animated mode*. External references are not loaded, and they fail
**silently** — open the file directly and a linked wallpaper looks fine; on
GitHub the same file renders as an empty pane.

| | |
|---|---|
| `<image href="…">` | blocked → the wallpaper is a base64 `data:` URI |
| `@font-face url()` | blocked → JetBrains Mono is subset and embedded |
| `<a href="…">` | inert → real links belong in `README.md`, not the SVG |
| `<animate>` | **allowed** → the block cursor blinks |

That last row is why the cursor can animate but nothing can be clicked. Do not
"fix" the SVG by linking assets out of it; it will look correct locally and be
broken for every visitor.

## Layout

```
README.md                     the profile page — embeds the SVG, carries any real links
resources/script/intro.py     the generator, with the CONFIG block
resources/script/ascii.txt    the Jolly Roger
resources/script/wallpaper.*  the untouched source image
resources/script/intro.py.lock  pinned dependencies — committed
resources/svgs/intro.svg      GENERATED — do not edit
resources/gifs/sanji.gif      currently referenced by nothing
```

## Commits

- **No `Co-Authored-By` trailer, and no AI attribution in commits or PR
  descriptions.** This is a personal repo — commits are authored solely by the
  owner. No "Generated with Claude Code" footers either.
- Conventional-commit subjects (`feat:`, `fix:`, `chore:`), and a body that says
  *why* rather than restating the diff.
- Changes land through PRs.
- When a change alters the rendered image, rebuild and commit `intro.svg` in the
  same commit as the script change — the two must never disagree.
