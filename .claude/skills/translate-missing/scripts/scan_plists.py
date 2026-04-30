#!/usr/bin/env python3
"""
Scan AppIntentVocabulary.plist files across every App/<lang>.lproj directory
and report mismatches against the English source.

For each <IntentName> in en.lproj's IntentPhrases array, every other lproj
should declare the same IntentName entry with an IntentExamples array of
roughly the same length (one localized example per English example).

Output:
    <relpath>\t<intent-name>\t<missing-count>\t<en-example-count>\t<lang-example-count>

A "miss" is reported per IntentName when:
  - the IntentName is absent in the target locale, OR
  - the IntentExamples count is lower than the English count.
"""
import plistlib
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[4]
APP_DIR = REPO_ROOT / "App"
PLIST_NAME = "AppIntentVocabulary.plist"
SOURCE_LANG = "en"


def load(lproj: Path) -> dict | None:
    p = lproj / PLIST_NAME
    if not p.exists():
        return None
    with p.open("rb") as f:
        return plistlib.load(f)


def index_phrases(data: dict | None) -> dict[str, list[str]]:
    if not data:
        return {}
    out: dict[str, list[str]] = {}
    for entry in data.get("IntentPhrases", []):
        name = entry.get("IntentName")
        examples = entry.get("IntentExamples", []) or []
        if name:
            out[name] = list(examples)
    return out


def main() -> int:
    en = index_phrases(load(APP_DIR / f"{SOURCE_LANG}.lproj"))
    if not en:
        print(f"# no {PLIST_NAME} found in {SOURCE_LANG}.lproj — nothing to compare against", file=sys.stderr)
        return 0

    lprojs = sorted(p for p in APP_DIR.glob("*.lproj") if p.is_dir())
    any_gaps = False

    for lproj in lprojs:
        lang = lproj.name.removesuffix(".lproj")
        if lang == SOURCE_LANG:
            continue
        target = index_phrases(load(lproj))
        rel = lproj.relative_to(REPO_ROOT) / PLIST_NAME
        if not target:
            print(f"# {rel}: MISSING FILE — needs all {sum(len(v) for v in en.values())} examples")
            any_gaps = True
            for intent, examples in en.items():
                print(f"{rel}\t{intent}\t{len(examples)}\t{len(examples)}\t0")
            continue

        for intent, en_examples in en.items():
            t_examples = target.get(intent, [])
            short_by = max(0, len(en_examples) - len(t_examples))
            if short_by > 0:
                any_gaps = True
                print(f"{rel}\t{intent}\t{short_by}\t{len(en_examples)}\t{len(t_examples)}")

    if not any_gaps:
        print("# all AppIntentVocabulary.plist files are aligned with en.lproj")
    return 0


if __name__ == "__main__":
    sys.exit(main())
