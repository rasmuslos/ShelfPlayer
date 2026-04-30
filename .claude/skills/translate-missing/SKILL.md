---
name: translate-missing
description: Fill in missing translations across all .xcstrings files in the ShelfPlayer project. Scans every xcstrings file, identifies keys with absent or `new`/`needs_review`-state localizations, derives an auto-generated comment from the call site of the key in Swift source, and writes translations for every missing target language. Use when the user asks to "translate missing keys", "fill in translations", "complete localization", or after pulling new strings into the catalogs.
user-invocable: true
allowed-tools:
  - Read
  - Edit
  - Write
  - Bash
  - Grep
  - Glob
---

# /translate-missing — Fill missing translations in .xcstrings

This skill closes translation gaps across every `.xcstrings` catalog in the project. It is **never** allowed to touch keys that are already fully translated, and it must not regenerate human-written comments.

## Catalogs in scope

```
App/Localizable.xcstrings
App/InfoPlist.xcstrings
WidgetExtension/Localizable.xcstrings
ShelfPlayerKit/Localizable.xcstrings
ShelfPlayerKit/AppShortcuts.xcstrings
```

The source language for every catalog is `en`. The current target languages (union across catalogs) are: `de, el, fr, it, nl, ru, sv, uk, zh-Hans`. Always re-derive this list per file from the catalog itself — do not hardcode.

## Plists in scope

In addition to the xcstrings catalogs, this skill also keeps Siri intent example phrases in sync across languages:

```
App/<lang>.lproj/AppIntentVocabulary.plist     # one per language
```

These XML plists contain natural-language Siri example phrases per `IntentName`. The English copy at `App/en.lproj/AppIntentVocabulary.plist` is the source of truth. Every other locale's plist must declare the same `IntentName` entries, with **one localized example per English example** under `IntentExamples`. Examples are end-user phrases ("Play the audiobook 1984 using ShelfPlayer") — translate them like any other UI string, but make them sound like something a person would actually say to Siri in that language. Keep the brand name `ShelfPlayer` untranslated.

> Note: `App/Settings.bundle/Root.plist` declares `StringsTable: Root` but no `Root.strings` files exist alongside it. That is a pre-existing setup gap, not something this skill resolves — do not invent localized `Root.strings` files unless the user explicitly asks.

## Workflow

Execute these phases in order. Do not skip phases. Phases 2–5 cover xcstrings; phase 5b covers the AppIntentVocabulary plists.

### Phase 1 — Scan

Run **both** scan helpers — one for xcstrings, one for the plists:

```bash
python3 .claude/skills/translate-missing/scripts/scan.py
python3 .claude/skills/translate-missing/scripts/scan_plists.py
```

For xcstrings, a "gap" is any of:
- The key's `localizations.<lang>` entry is absent.
- The entry exists but its `stringUnit.state` is `new`, `needs_review`, or `stale`.

Gaps include the source language (`en`) when the catalog otherwise uses explicit source-language localizations — i.e. at least one key has a populated `localizations.en` entry. Catalogs where the key itself is the English phrase (e.g. `AppShortcuts.xcstrings`) are exempt; the scanner skips source-language checks there automatically.

Keys with `shouldTranslate: false` are skipped — they are format fragments that must remain identical across languages.

For the plists, a "gap" is: an `IntentName` from `en.lproj` is missing in a target locale, **or** the target locale's `IntentExamples` array has fewer entries than the English one.

If both scans report zero gaps, stop and tell the user the catalogs and plists are complete. Do not modify any files.

### Phase 2 — Derive context for each key

For every key with a gap:

1. **Read the existing English source value** from `localizations.en.stringUnit.value`. This is the strongest signal.
2. **Grep the codebase for the literal key**. Strings are referenced via `String(localized: "key")`, `LocalizedStringKey("key")`, `LocalizedStringResource("key")`, plain `Text("key")`, or as table keys. Look at the surrounding view/function to understand what UI element this string belongs to (button label, alert title, accessibility hint, navigation title, error message, etc.).
3. **Inspect siblings.** Keys are dot-namespaced (e.g. `action.cancel`, `download.queue.empty`). Sibling keys often clarify the domain.
4. Compose a one-sentence comment that names the **kind of UI element** and its **purpose**. Keep it under ~120 characters, imperative-neutral. Examples that match the existing project style:
   - `"A button that cancels an action."`
   - `"Title shown when a library has no items."`
   - `"Accessibility label for the playback skip-forward control."`

If the key is genuinely opaque (e.g. used only via dynamic interpolation and the source value is a single ambiguous word), say so in the comment: `"Generic <noun> label; context unclear."` Do not fabricate context.

### Phase 3 — Write the comment field

For each key that has any gap, set both fields at the **key level** (siblings of `localizations`):

```json
{
  "comment": "<the sentence from Phase 2>",
  "isCommentAutoGenerated": true,
  "localizations": { ... }
}
```

Rules:
- **If the key already has `comment` AND `isCommentAutoGenerated` is absent or `false`**, the comment is human-written. Leave it alone — do not overwrite, do not add `isCommentAutoGenerated`.
- **If the key already has `comment` with `isCommentAutoGenerated: true`**, you may refine the comment if your derivation is materially better; otherwise leave it.
- **If the key has no comment**, add one and set `isCommentAutoGenerated: true`.

### Phase 4 — Translate

For each missing `(key, lang)` pair, write a translation as:

```json
"<lang>": {
  "stringUnit": {
    "state": "translated",
    "value": "<translation>"
  }
}
```

#### Tone and style — Apple Style Guide, friendly-neutral

Match the voice of system iOS apps. The English source already follows this tone; mirror it in every target language.

- **Sentence case** for buttons, menu items, alerts, and most UI strings (unless the source is clearly a proper noun or title-cased label, in which case follow the source).
- **Direct, active voice.** "Download episode", not "The episode will be downloaded."
- **Address the user as "you"** in languages that distinguish formality. Use the polite/formal register for European languages: `Sie` (de), `vous` (fr), `Lei`/3rd-person courtesy (it), `u` (nl), `ви` (uk), `Вы` (ru), `ni`/the neutral "du" depending on convention (sv — modern Swedish uses informal `du` even formally; follow that). For zh-Hans use neutral phrasing without `您` unless the source is conspicuously formal.
- **No exclamation marks** unless the source has one.
- **Preserve format specifiers exactly**: `%@`, `%1$@`, `%lld`, `%d`, line breaks (`\n`), and surrounding whitespace must be byte-identical to the source.
- **Preserve trailing punctuation and ellipses** (`…` is one character, not three dots).
- **Don't translate brand names**: ShelfPlayer, Audiobookshelf, Apple, AirPlay, CarPlay, Siri, iCloud, AVFoundation, etc.
- **Match length where possible.** UI strings are constrained; prefer the shorter idiomatic phrase.
- **Plural-aware variants**: introduce them whenever the source string contains a numeric count placeholder, even if the English source is flat. xcstrings allows the structure to differ per language — English may stay as a `stringUnit` while Russian, Ukrainian, Polish, etc. use `variations.plural`. See *Plural variations* below for the full rule.

#### Plural variations — when to introduce them

A target-language entry **must** use `variations.plural` (instead of a flat `stringUnit`) when **both** of these hold:

1. The English source contains an integer-count placeholder. The signals are:
   - `%lld`, `%d`, `%lu`, `%llu`, `%i` — these are always integer counts. Treat as count.
   - `%@` is **not** a count by default; it's an arbitrary substitution (name, version, date). Only treat `%@` as a count if the key name or surrounding context makes it unambiguous (e.g. a key like `inbox.unread %@` where the call site passes a number).
2. The grammar of the target language inflects on number for that string. Practically: whenever the count varies (1, 2, 5, …) the noun, verb, or article changes form. If the translation reads naturally with a single phrasing across all counts, a flat string is fine; otherwise you must use `variations.plural`.

When introducing plural variations for a target language, fill the CLDR plural categories that language requires:

| Language          | Required forms                             |
|-------------------|---------------------------------------------|
| `de, nl, sv, en`  | `one`, `other`                              |
| `fr, it`          | `one`, `many` (if needed for millions), `other` — `one` + `other` is sufficient for most UI counts |
| `el`              | `one`, `other`                              |
| `ru, uk`          | `one`, `few`, `many`, `other`               |
| `zh-Hans`         | `other` only (Chinese has no grammatical plural) |

Patch shape for a plural-varied language entry:

```json
"ru": {
  "variations": {
    "plural": {
      "one":   { "stringUnit": { "state": "translated", "value": "%lld объект" } },
      "few":   { "stringUnit": { "state": "translated", "value": "%lld объекта" } },
      "many":  { "stringUnit": { "state": "translated", "value": "%lld объектов" } },
      "other": { "stringUnit": { "state": "translated", "value": "%lld объекта" } }
    }
  }
}
```

If the English source already declares `variations.plural`, mirror that structure in every target language and fill every CLDR form the language requires.

If you are uncertain whether a given string is count-bearing (e.g. `%@` whose runtime value you cannot determine), prefer the **flat translation** and note it in your final report rather than guessing at a plural form.

#### Filling missing source-language (`en`) values

When the scanner reports `en` as a gap, the catalog is missing its source-of-truth English string for that key. Author it from the comment, the call-site context (Phase 2), and any sibling keys — same Apple Style Guide rules as for translations: sentence case, direct active voice, no exclamation marks unless contextually required, format specifiers preserved.

The writer refuses by default. Pass `--allow-source-language` to `apply.py` for the patch that includes `en` localizations. Even with the flag, the writer will *never* overwrite an existing translated `en` value — it only fills empty slots. If you tried to set `en` and the writer reports `source-language already translated, kept`, that means a value is already there; do not try to bypass it.

#### Per-language reference notes

- **de** — Polite `Sie`. Capitalise nouns. Avoid Anglicisms when a clear native term exists ("Lesezeichen" not "Bookmark").
- **fr** — Polite `vous`. Use proper French typography: non-breaking space before `: ; ! ?` and inside `« »` quotes if the source uses quotes.
- **it** — Courtesy form (3rd person singular) where addressing the user. Use `é` vs `è` correctly.
- **nl** — Polite `u`. Compound nouns are written as one word.
- **el** — Polite plural (`εσείς`-form verbs). Use Greek question mark `;` only if the source is a question.
- **ru** — Polite `Вы` capitalised when addressing one user directly. Watch plural forms (1, 2–4, 5+).
- **sv** — Informal `du` (Swedish convention even in formal UI). No capitalised nouns.
- **uk** — Polite `Ви`. Watch plural forms similar to Russian.
- **zh-Hans** — Simplified Chinese, mainland conventions. Use full-width punctuation (`，。：；？！`) in running prose, but keep half-width for technical tokens. No spaces between Chinese characters.

### Phase 5 — Write back

Use the writer helper, which preserves the catalog's existing key order, indentation (2 spaces), and only mutates the keys you pass to it:

```bash
python3 .claude/skills/translate-missing/scripts/apply.py <catalog-path> <patch-json> [--allow-source-language]
```

Pass `--allow-source-language` only when the patch needs to fill empty source-language (`en`) slots. Without the flag, any `localizations.en` entry in the patch is refused and reported in `skipped`. The flag never authorizes overwriting an existing translated source-language value — that case is always refused.

`patch-json` is the path to a temp file you write containing:

```json
{
  "<key>": {
    "comment": "...",          // optional; only include if you are setting/changing it
    "isCommentAutoGenerated": true,  // optional; pair with comment
    "localizations": {
      "<lang>": { "stringUnit": { "state": "translated", "value": "..." } }
    }
  }
}
```

The writer **merges** — it never deletes existing translations or unrelated keys. After every catalog, re-run the scanner and verify the gap count for that file is `0`.

### Phase 5b — AppIntentVocabulary plists

For each gap reported by `scan_plists.py`:

1. Read the English plist at `App/en.lproj/AppIntentVocabulary.plist` and the target locale's plist.
2. For each `IntentName` block, append translated entries to the target's `IntentExamples` array until its length matches the English one. **Order matters** — the *n*-th localized example should correspond to the *n*-th English example.
3. Write each example as the user would naturally phrase the request to Siri in the target language. Keep `ShelfPlayer` untranslated. Mirror the source's punctuation conventions (smart vs straight quotes can stay as in the existing file).
4. Use the `Edit` tool to insert new `<string>...</string>` lines inside the relevant `<array>`. Preserve tab indentation and the existing XML structure exactly. Do not rewrite the whole file with `Write`.
5. If a target plist is missing entirely, copy the English file's structure and translate every example. Keep the `IntentName` value (`INPlayMediaIntent`, etc.) byte-identical to the English copy.
6. After editing, re-run `scan_plists.py` and confirm the file no longer appears in the output.

Hard rules for plists:
- Never modify `App/en.lproj/AppIntentVocabulary.plist` — it is the source of truth.
- Never delete existing localized examples; only **add** to bring counts up to parity.
- Do not change `<key>IntentName</key>` values.

### Phase 6 — Report

Print a per-catalog summary: how many keys received comments, how many `(key, lang)` pairs were translated, and any keys you flagged as opaque. Do not commit — leave staging to the user.

## Hard rules

- **Never overwrite an existing translated English (`en`) value.** The writer enforces this even when `--allow-source-language` is passed — empty `en` slots may be filled, translated `en` values are immutable through this skill. To change a translated `en` value, edit the catalog directly in Xcode's String Catalog editor.
- **Only pass `--allow-source-language` to `apply.py` when the patch intentionally fills empty `en` slots.** Without the flag, the writer refuses any `localizations.en` entry in the patch.
- **Never change `shouldTranslate: false` keys.**
- **Never set `state: "translated"` on a value you did not actually translate** (e.g. don't copy English into another language as a placeholder).
- **Never delete or rewrite a comment that lacks `isCommentAutoGenerated: true`** — that is a human-authored comment.
- **Never reorder keys** in the catalog. Use the writer script.
- The CLAUDE.md says not to modify `.xcstrings` files unless specifically tasked. This skill **is** that explicit task — but only proceed when invoked. Do not run it speculatively from other skills.

## When you finish

Tell the user: which catalogs you touched, how many translations you added, any keys you skipped because the context was unclear (and why), and the exact command to regenerate the Xcode project if needed (`xcodegen generate`).
