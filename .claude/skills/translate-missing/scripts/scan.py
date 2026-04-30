#!/usr/bin/env python3
"""
Scan all .xcstrings catalogs in the ShelfPlayer project and report keys
that have missing or stale localizations.

Output format (one line per gap):
    <catalog>\t<key>\t<missing-langs-comma-separated>\t<has-comment:0|1>\t<plural:0|1>\t<count-placeholder:0|1>

`plural` is 1 when the English source already declares `variations.plural`.
`count-placeholder` is 1 when the English source contains an integer-count
placeholder (%lld, %d, %lu, %llu, %i) — i.e. translations *should* introduce
per-language plural variations even though the source is flat.

A "gap" means: for a language we expect, the localization entry is absent or
its stringUnit.state is in {new, needs_review, stale}. Keys with
shouldTranslate=false are skipped.

The source language (typically `en`) is flagged as a gap only when the catalog
otherwise uses explicit source-language localizations — i.e. at least one key
has a populated `localizations.<src>` entry. This skips catalogs like
AppShortcuts.xcstrings where the key itself is the English phrase.
"""
import json
import re
import sys
from pathlib import Path

INT_COUNT_RE = re.compile(r"%(?:\d+\$)?(?:lld|llu|ll[di]|l[diu]|[diu])\b")

REPO_ROOT = Path(__file__).resolve().parents[4]

CATALOGS = [
    "App/Localizable.xcstrings",
    "App/InfoPlist.xcstrings",
    "WidgetExtension/Localizable.xcstrings",
    "ShelfPlayerKit/Localizable.xcstrings",
    "ShelfPlayerKit/AppShortcuts.xcstrings",
]

STALE_STATES = {"new", "needs_review", "stale"}


def collect_target_langs(strings: dict, source_lang: str) -> list[str]:
    langs: set[str] = set()
    for entry in strings.values():
        for lang in entry.get("localizations", {}).keys():
            langs.add(lang)
    langs.discard(source_lang)
    return sorted(langs)


def is_translated(unit: dict | None) -> bool:
    if not unit:
        return False
    return unit.get("state") == "translated" and unit.get("value", "") != ""


def lang_has_gap(loc: dict | None) -> bool:
    """A language entry has a gap if it's missing, or any nested stringUnit
    is missing/stale. Handles plural variations and AppShortcuts stringSets."""
    if loc is None:
        return True
    if "stringUnit" in loc:
        u = loc["stringUnit"]
        return (not u) or u.get("state") in STALE_STATES or u.get("value", "") == ""
    if "variations" in loc:
        plural = loc["variations"].get("plural", {})
        if not plural:
            return True
        for form in plural.values():
            if not is_translated(form.get("stringUnit")):
                return True
        return False
    if "stringSet" in loc:
        s = loc["stringSet"]
        if not s or s.get("state") in STALE_STATES:
            return True
        return not s.get("values")
    return True


def source_value(en_loc: dict | None) -> str:
    if not en_loc:
        return ""
    if "stringUnit" in en_loc:
        return en_loc["stringUnit"].get("value", "")
    if "variations" in en_loc:
        plural = en_loc["variations"].get("plural", {})
        return " | ".join(
            form.get("stringUnit", {}).get("value", "") for form in plural.values()
        )
    return ""


def expects_source_localization(strings: dict, src_lang: str) -> bool:
    """True iff at least one translatable key already declares an explicit
    source-language localization. AppShortcuts-style catalogs (key == English
    phrase) return False and skip source-language gap checks."""
    for entry in strings.values():
        if entry.get("shouldTranslate") is False:
            continue
        if src_lang in entry.get("localizations", {}):
            return True
    return False


def scan_catalog(path: Path) -> tuple[list[tuple[str, list[str], bool, bool, bool]], int, list[str], bool]:
    data = json.loads(path.read_text(encoding="utf-8"))
    src = data.get("sourceLanguage", "en")
    strings = data.get("strings", {})
    target_langs = collect_target_langs(strings, src)
    expects_source = expects_source_localization(strings, src)

    rows: list[tuple[str, list[str], bool, bool, bool]] = []
    total_pairs = 0
    for key, entry in strings.items():
        if entry.get("shouldTranslate") is False:
            continue
        locs = entry.get("localizations", {})
        en_loc = locs.get(src)
        is_plural = bool(en_loc and "variations" in en_loc)
        en_text = source_value(en_loc) or key  # keys themselves are sometimes the source
        has_count = bool(INT_COUNT_RE.search(en_text))
        missing: list[str] = []
        if expects_source and lang_has_gap(en_loc):
            missing.append(src)
        for lang in target_langs:
            if lang_has_gap(locs.get(lang)):
                missing.append(lang)
        if missing:
            has_comment = bool(entry.get("comment"))
            rows.append((key, missing, has_comment, is_plural, has_count))
            total_pairs += len(missing)
    return rows, total_pairs, target_langs, expects_source


def main() -> int:
    grand_total = 0
    any_gaps = False
    for rel in CATALOGS:
        path = REPO_ROOT / rel
        if not path.exists():
            print(f"# MISSING CATALOG: {rel}", file=sys.stderr)
            continue
        rows, pairs, langs, expects_source = scan_catalog(path)
        src_note = "; source-language gaps reported" if expects_source else "; key is source"
        if not rows:
            print(f"# {rel}: 0 gaps  (target langs: {','.join(langs)}{src_note})")
            continue
        any_gaps = True
        grand_total += pairs
        print(f"# {rel}: {len(rows)} keys, {pairs} (key,lang) pairs  (target langs: {','.join(langs)}{src_note})")
        for key, missing, has_comment, is_plural, has_count in rows:
            print(
                f"{rel}\t{key}\t{','.join(missing)}\t"
                f"{'1' if has_comment else '0'}\t"
                f"{'1' if is_plural else '0'}\t"
                f"{'1' if has_count else '0'}"
            )
    print(f"# TOTAL: {grand_total} (key,lang) pairs across all catalogs")
    return 0 if any_gaps else 0


if __name__ == "__main__":
    sys.exit(main())
