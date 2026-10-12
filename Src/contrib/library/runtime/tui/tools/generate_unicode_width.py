#!/usr/bin/env python3
"""
generate_unicode_width.py

Generates library/core/buffer/unicode_width.e from the Unicode Character Database.

Sources (pinned to UNICODE_VERSION):
  * ucd/EastAsianWidth.txt                     W / F            -> width 2
  * ucd/extracted/DerivedGeneralCategory.txt   Mn / Me / Cf     -> width 0 (except U+00AD)
  * ucd/emoji/emoji-data.txt                   Emoji_Presentation -> width 2
                                               Emoji                (VS16 widens only these)
                                               Extended_Pictographic (grapheme segmentation)
                                               Emoji_Modifier       (grapheme segmentation)
Hangul Jamo medial vowels / final consonants (U+1160..U+11FF, U+D7B0..U+D7FF) are width 0,
and C0/C1 controls are width 0 (they never occupy a cell).

Usage:
  python tools/generate_unicode_width.py                 # download and write the Eiffel class
  python tools/generate_unicode_width.py --cache DIR     # read/write the UCD files in DIR
  python tools/generate_unicode_width.py --stdout        # print the class instead of writing it
"""

import argparse
import datetime
import os
import re
import sys
import urllib.request

UNICODE_VERSION = "16.0.0"
BASE_URL = f"https://www.unicode.org/Public/{UNICODE_VERSION}/ucd/"
FILES = {
    "eaw": "EastAsianWidth.txt",
    "gc": "extracted/DerivedGeneralCategory.txt",
    "emoji": "emoji/emoji-data.txt",
}

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUTPUT = os.path.join(ROOT, "library", "core", "buffer", "unicode_width.e")

LINE_RE = re.compile(r"^([0-9A-Fa-f]{4,6})(?:\.\.([0-9A-Fa-f]{4,6}))?\s*;\s*([A-Za-z_]+)")
MISSING_RE = re.compile(r"^#\s*@missing:\s*([0-9A-Fa-f]{4,6})\.\.([0-9A-Fa-f]{4,6})\s*;\s*([A-Za-z_]+)")


def load(name, cache):
    rel = FILES[name]
    if cache:
        path = os.path.join(cache, os.path.basename(rel))
        if os.path.exists(path):
            with open(path, encoding="utf-8") as f:
                return f.read()
    with urllib.request.urlopen(BASE_URL + rel) as resp:
        text = resp.read().decode("utf-8")
    if cache:
        os.makedirs(cache, exist_ok=True)
        with open(os.path.join(cache, os.path.basename(rel)), "w", encoding="utf-8") as f:
            f.write(text)
    return text


def parse(text, wanted, include_missing=False):
    """Code point set of every line whose property value is in `wanted`."""
    result = set()
    for line in text.splitlines():
        m = LINE_RE.match(line)
        if not m and include_missing:
            m = MISSING_RE.match(line)
        if m and m.group(3) in wanted:
            lo = int(m.group(1), 16)
            hi = int(m.group(2), 16) if m.group(2) else lo
            result.update(range(lo, hi + 1))
    return result


def ranges(points):
    out = []
    for cp in sorted(points):
        if out and cp == out[-1][1] + 1:
            out[-1][1] = cp
        else:
            out.append([cp, cp])
    return out


def eiffel_table(name, comment, rs):
    values = []
    for lo, hi in rs:
        values.append(str(lo))
        values.append(str(hi))
    lines = []
    row = []
    for v in values:
        row.append(v)
        if len(row) == 12:
            lines.append(", ".join(row))
            row = []
    if row:
        lines.append(", ".join(row))
    body = ",\n\t\t\t\t".join(lines)
    return (
        f"\t{name}: SPECIAL [NATURAL_32]\n"
        f"\t\t\t-- {comment}\n"
        f"\t\t\t-- Sorted inclusive ranges stored as consecutive (low, high) pairs ({len(rs)} ranges).\n"
        f"\t\tonce\n"
        f"\t\t\tResult := ({{ARRAY [NATURAL_32]}} <<\n\t\t\t\t{body}\n\t\t\t>>).area\n"
        f"\t\tensure\n"
        f"\t\t\tinstance_free: class\n"
        f"\t\tend\n"
    )


def build(cache):
    eaw = load("eaw", cache)
    gc = load("gc", cache)
    emoji = load("emoji", cache)

    wide = parse(eaw, {"W", "F"}, include_missing=True)
    wide |= parse(emoji, {"Emoji_Presentation"})

    zero = parse(gc, {"Mn", "Me", "Cf"})
    zero.discard(0x00AD)  # SOFT HYPHEN is displayed by terminals
    zero |= set(range(0x0000, 0x0020)) | set(range(0x007F, 0x00A0))
    zero |= set(range(0x1160, 0x1200)) | set(range(0xD7B0, 0xD800))
    wide -= zero
    # A lone regional indicator is narrow; a pair (a flag) is measured as one wide cluster
    # (same as the unicode-width crate used by Ratatui).
    wide -= set(range(0x1F1E6, 0x1F200))

    pictographic = parse(emoji, {"Extended_Pictographic"})
    modifiers = parse(emoji, {"Emoji_Modifier"})
    # Characters that VS16 (emoji presentation) can widen: the Emoji property, which also
    # holds the keycap bases 0-9 # *. Other bases (A + VS16) keep their width.
    emoji_chars = parse(emoji, {"Emoji"})

    # Unassigned surrogates / private use never appear in these sets; sanity checks:
    assert 0x4E00 in wide and 0x1F600 in wide and 0x0301 in zero and 0x0E31 in zero
    assert 0x1160 in zero and 0x1F468 in pictographic and 0x1F3FB in modifiers
    assert 0x2764 in emoji_chars and 0x23 in emoji_chars and 0x41 not in emoji_chars
    assert all(cp in zero for cp in BIDI_CONTROLS)
    return ranges(zero), ranges(wide), ranges(pictographic), ranges(modifiers), ranges(emoji_chars)


# Explicit bidi formatting characters (UAX #9): embeddings, overrides and isolates.
BIDI_CONTROLS = list(range(0x202A, 0x202F)) + list(range(0x2066, 0x206A))


TEMPLATE = '''note
	description: "[
		Display width of code points and grapheme clusters, and grapheme cluster segmentation.

		GENERATED by tools/generate_unicode_width.py from the Unicode {version} Character Database
		(EastAsianWidth.txt, extracted/DerivedGeneralCategory.txt, emoji/emoji-data.txt) on {date}.
		Do not edit the tables by hand: change the generator and run it again.

		Widths: 0 for controls, nonspacing/enclosing marks, format characters and Hangul medial/final
		jamo; 2 for East Asian Wide/Fullwidth and Emoji_Presentation (except lone regional
		indicators, which are 1: a pair forms a 2-column flag cluster); 1 otherwise.
		A cluster with VS16 is 2 wide only if its base has the Emoji property.

		Grapheme clusters follow the subset of UAX #29 that matters for terminal cells: CR LF,
		combining/format/variation-selector extension, emoji modifiers, emoji ZWJ sequences
		(Extended_Pictographic ZWJ Extended_Pictographic) and regional indicator pairs (flags).
		C0/C1 controls and the explicit bidi formatting characters (U+202A..U+202E,
		U+2066..U+2069) are clusters of their own (`is_never_drawn'): BUFFER drops them, so
		user text cannot reorder what the terminal displays.

		Known gaps, by choice (see the class notes of BUFFER for tabs):
		- No SpacingMark / Prepend rules (GB9a, GB9b): a spacing mark such as Devanagari
		  U+093F is a cluster of its own, 1 column wide, as with wcwidth. Terminals that shape
		  Indic text draw such pairs in fewer columns; most terminals do not.
		- East Asian Ambiguous characters are 1 column wide. Terminals set to CJK widths draw
		  them in 2, and the layout then drifts on those characters.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	UNICODE_WIDTH

feature -- Query

	width (a_code: NATURAL_32): NATURAL_8
			-- Display width in columns of code point `a_code` (0, 1 or 2).
		do
			if a_code >= 32 and a_code < 127 then
				Result := 1
			elseif is_zero_width_code (a_code) then
				Result := 0
			elseif is_wide_code (a_code) then
				Result := 2
			else
				Result := 1
			end
		ensure
			instance_free: class
			valid_cell_width: Result <= 2
		end

	grapheme_width (a_grapheme: READABLE_STRING_GENERAL): NATURAL_8
			-- Display width of the grapheme cluster `a_grapheme` (0, 1 or 2).
		local
			i: INTEGER
			l_base, l_code: NATURAL_32
			l_has_vs15, l_has_vs16, l_has_emoji_zwj: BOOLEAN
		do
			if not a_grapheme.is_empty then
				l_base := a_grapheme.code (1)
				Result := width (l_base)
				if a_grapheme.count > 1 then
					if is_regional_indicator (l_base) and then is_regional_indicator (a_grapheme.code (2)) then
						Result := 2
					else
						from
							i := 2
						until
							i > a_grapheme.count
						loop
							l_code := a_grapheme.code (i)
							if l_code = Vs16 then
								l_has_vs16 := True
							elseif l_code = Vs15 then
								l_has_vs15 := True
							elseif l_code = Zwj and then i < a_grapheme.count and then is_extended_pictographic (a_grapheme.code (i + 1)) then
								l_has_emoji_zwj := True
							end
							i := i + 1
						end
						if (l_has_vs16 and is_emoji_code (l_base)) or (l_has_emoji_zwj and is_extended_pictographic (l_base)) then
							Result := 2
						elseif l_has_vs15 and is_extended_pictographic (l_base) then
							Result := 1
						end
					end
				end
			end
		ensure
			instance_free: class
			valid_cell_width: Result <= 2
		end

	string_width (a_string: READABLE_STRING_GENERAL): NATURAL_16
			-- Display width in columns of `a_string`, measured grapheme by grapheme
			-- (the same way BUFFER places it), saturating at 65535.
		local
			i, l_end: INTEGER
			l_sum: NATURAL_32
		do
			from
				i := 1
			until
				i > a_string.count or l_sum >= 65535
			loop
				l_end := grapheme_end (a_string, i)
				if l_end = i then
					l_sum := l_sum + width (a_string.code (i)).to_natural_32
				else
					l_sum := l_sum + grapheme_width (a_string.substring (i, l_end)).to_natural_32
				end
				i := l_end + 1
			end
			Result := l_sum.min (65535).to_natural_16
		ensure
			instance_free: class
		end

	grapheme_end (a_string: READABLE_STRING_GENERAL; a_start: INTEGER): INTEGER
			-- Index of the last code point of the grapheme cluster starting at `a_start`.
		require
			valid_start: a_start >= 1 and a_start <= a_string.count
		local
			l_base, l_code, l_prev: NATURAL_32
			l_stop: BOOLEAN
		do
			Result := a_start
			l_base := a_string.code (a_start)
			if l_base = 13 then
				if a_start < a_string.count and then a_string.code (a_start + 1) = 10 then
					Result := a_start + 1
				end
			elseif not is_never_drawn (l_base) then
				if is_regional_indicator (l_base) and then a_start < a_string.count
					and then is_regional_indicator (a_string.code (a_start + 1)) then
					Result := a_start + 1
				end
				from
					l_prev := a_string.code (Result)
				until
					l_stop or Result >= a_string.count
				loop
					l_code := a_string.code (Result + 1)
					if is_extend (l_code) then
						Result := Result + 1
					elseif l_prev = Zwj and is_extended_pictographic (l_code) and is_extended_pictographic (l_base) then
						Result := Result + 1
					else
						l_stop := True
					end
					l_prev := l_code
				end
			end
		ensure
			instance_free: class
			in_range: Result >= a_start and Result <= a_string.count
		end

feature -- Status report

	is_zero_width_code (a_code: NATURAL_32): BOOLEAN
			-- Does `a_code` take no column (control, combining mark, format character, ...)?
		do
			Result := in_table (a_code, Zero_width_table)
		ensure
			instance_free: class
		end

	is_wide_code (a_code: NATURAL_32): BOOLEAN
			-- Is `a_code` East Asian Wide/Fullwidth or an emoji with default emoji presentation?
		do
			Result := in_table (a_code, Wide_table)
		ensure
			instance_free: class
		end

	is_emoji_code (a_code: NATURAL_32): BOOLEAN
			-- Does `a_code` have the Emoji property (so VS16 can give it emoji presentation)?
		do
			Result := in_table (a_code, Emoji_table)
		ensure
			instance_free: class
		end

	is_extended_pictographic (a_code: NATURAL_32): BOOLEAN
			-- Does `a_code` have the Extended_Pictographic property?
		do
			Result := in_table (a_code, Extended_pictographic_table)
		ensure
			instance_free: class
		end

	is_emoji_modifier (a_code: NATURAL_32): BOOLEAN
			-- Is `a_code` a skin tone modifier (U+1F3FB..U+1F3FF)?
		do
			Result := in_table (a_code, Emoji_modifier_table)
		ensure
			instance_free: class
		end

	is_regional_indicator (a_code: NATURAL_32): BOOLEAN
			-- Is `a_code` a regional indicator letter (flag halves)?
		do
			Result := a_code >= 0x1F1E6 and a_code <= 0x1F1FF
		ensure
			instance_free: class
		end

	is_control (a_code: NATURAL_32): BOOLEAN
			-- Is `a_code` a C0 or C1 control character?
		do
			Result := a_code < 32 or (a_code >= 127 and a_code < 160)
		ensure
			instance_free: class
		end

	is_bidi_control (a_code: NATURAL_32): BOOLEAN
			-- Is `a_code` an explicit bidi formatting character (embedding, override or isolate:
			-- U+202A..U+202E, U+2066..U+2069)?
		do
			Result := (a_code >= 0x202A and a_code <= 0x202E) or (a_code >= 0x2066 and a_code <= 0x2069)
		ensure
			instance_free: class
		end

	is_never_drawn (a_code: NATURAL_32): BOOLEAN
			-- Is `a_code` a C0/C1 control or an explicit bidi formatting character? Each forms a
			-- cluster of its own (UAX #29 Control), which BUFFER drops.
		do
			Result := is_control (a_code) or is_bidi_control (a_code)
		ensure
			instance_free: class
		end

	is_extend (a_code: NATURAL_32): BOOLEAN
			-- Does `a_code` extend the preceding grapheme cluster (zero-width character that is
			-- drawn, ZWJ, variation selector, emoji modifier)?
		do
			Result := (not is_never_drawn (a_code) and is_zero_width_code (a_code)) or is_emoji_modifier (a_code)
		ensure
			instance_free: class
		end

feature -- Constants

	Zwj: NATURAL_32 = 0x200D
			-- ZERO WIDTH JOINER

	Vs15: NATURAL_32 = 0xFE0E
			-- VARIATION SELECTOR-15 (text presentation)

	Vs16: NATURAL_32 = 0xFE0F
			-- VARIATION SELECTOR-16 (emoji presentation)

feature {NONE} -- Implementation

	in_table (a_code: NATURAL_32; a_table: SPECIAL [NATURAL_32]): BOOLEAN
			-- Is `a_code` inside one of the (low, high) ranges of `a_table`? (binary search)
		require
			pairs: a_table.count \\\\ 2 = 0
		local
			l_lo, l_hi, l_mid: INTEGER
		do
			from
				l_lo := 0
				l_hi := a_table.count // 2 - 1
			until
				Result or l_lo > l_hi
			loop
				l_mid := (l_lo + l_hi) // 2
				if a_code < a_table [2 * l_mid] then
					l_hi := l_mid - 1
				elseif a_code > a_table [2 * l_mid + 1] then
					l_lo := l_mid + 1
				else
					Result := True
				end
			end
		ensure
			instance_free: class
		end

feature {NONE} -- Generated tables

{tables}
end
'''


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--cache", help="directory holding (or receiving) the UCD files")
    ap.add_argument("--stdout", action="store_true", help="print the class instead of writing it")
    args = ap.parse_args()

    zero, wide, pict, mods, emoji_chars = build(args.cache)
    tables = "\n".join([
        eiffel_table("Zero_width_table", "Code points of width 0.", zero),
        eiffel_table("Wide_table", "Code points of width 2.", wide),
        eiffel_table("Extended_pictographic_table", "Extended_Pictographic code points.", pict),
        eiffel_table("Emoji_modifier_table", "Emoji_Modifier code points.", mods),
        eiffel_table("Emoji_table", "Emoji code points.", emoji_chars),
    ])
    text = (TEMPLATE
            .replace("{version}", UNICODE_VERSION)
            .replace("{date}", datetime.date.today().isoformat())
            .replace("{tables}", tables))
    if args.stdout:
        sys.stdout.write(text)
    else:
        with open(OUTPUT, "w", encoding="utf-8", newline="\n") as f:
            f.write(text)
        print(f"wrote {OUTPUT}: {len(zero)} zero-width, {len(wide)} wide, "
              f"{len(pict)} pictographic, {len(mods)} modifier, {len(emoji_chars)} emoji ranges (Unicode {UNICODE_VERSION})")


if __name__ == "__main__":
    main()
