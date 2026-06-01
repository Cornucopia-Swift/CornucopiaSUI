# VIN model-layer consolidation (backlog)

**Goal:** make `Automotive-Swift/VIN` the single source of truth for VIN domain logic, and have CornucopiaSUI consume it instead of maintaining its own private copies. Strategy is **augment-then-consume**, not a blind swap.

**Status: ✅ done.** VIN package v2 released (`2.0.0`, breaking; old state tagged `pre-API-change`); CornucopiaSUI depends on it via `.package(url: …/VIN, from: "2.0.0")` and its VIN tables were replaced by thin wrappers. Both repos build and test green. This document is kept for the rationale/history.

## Why

Two implementations have already diverged:

| | `Automotive-Swift/VIN` | CornucopiaSUI (private) |
|---|---|---|
| Check digit (mod-11) | public, tested | private, **untested** |
| WMI → manufacturer | **561**, localized de/en/fr | 265, English only |
| Region/country | localized **name strings** + continent | ISO **alpha-2 code** → flag emoji + `Locale` |
| WMI/VDS/VIS split | yes | yes |
| Validity | tri-state | 6-state UI machine |
| Model-year (pos 10) | — | 30-entry table |
| Online decode (NHTSA) | — | `VINVehicleDecoder` |

## Hard blocker → the augmentation

CornucopiaSUI keys region off the **ISO 3166 alpha-2 code** (`"DE"`), which powers `VINIdentity.flag` (🇩🇪) and the `Locale`-based `countryName`. The VIN package exposes only localized *name strings*, no code. A straight swap would **regress** the flag + OS-localized country name. So first add to the VIN package the two pieces CornucopiaSUI has that it lacks.

### Phase 1 — VIN package v2 API (`Automotive-Swift/VIN`)

Tag the current state `pre-API-change` first; this is a deliberate, breaking v2.

**Structured identity (replaces localized-string accessors).** The current `wmiRegion`/`wmiCountry`/`wmiManufacturer` return pre-localized `NSLocalizedString` lookups (`?`/`""` sentinels) and hide the ISO code. Replace with:
- `var regionCode: String?` — ISO 3166-1 alpha-2. Port CornucopiaSUI's 54 ISO-3780 ranges + rank logic (`VINIdentity.swift`). **Gating change** — without it, flag/`Locale` localization can't be derived; do not migrate without it.
- `var countryName: String?` — derived via `Locale.localizedString(forRegionCode:)` (localizes in *every* OS language, not just the bundled en/de/fr).
- `var flag: String?` — emoji from the region code.
- `var region: Continent?` — a `Continent` enum (africa/asia/europe/northAmerica/oceania/southAmerica) from the first WMI char (structured, no `.strings`).
- `var manufacturer: String?` — `nil` when unknown (no more `?`). Migrate the 561-entry manufacturer table out of the three duplicated `.strings` files into Swift data (proper nouns aren't localized — en/de/fr are identical). Lookup tries 3-char WMI then 2-char.

**Work on partial input.** `wmi`/`vds`/`vis`/`regionCode`/`manufacturer`/`modelYear` must decode from any prefix of sufficient length (≥1/≥2/≥3/≥10 chars) — drop the "return `""` unless full 17-char `isValid`" gate. This is what makes live as-you-type decoding possible (the whole reason CornucopiaSUI needs it).

**Missing VIN anatomy.**
- `var modelYear: Int?` — position 10. Port `modelYearCodes` (30 entries) from `VINTextField.swift`; document the NA 30-year-cycle ambiguity (Y=2000 repeats 2030).
- `var assemblyPlant: Character?` — position 11.
- `var serialNumber: String?` — positions 12–17.

**Check digit.**
- Rename `checksumDigit` → `actualCheckDigit` (it returns the existing 9th char, not the computed one).
- Add public `var expectedCheckDigit: Character?` (the computed digit; `calculateChecksum` is currently private) — needed for CornucopiaSUI's `validWithCheckDigitWarning`.

**Correctness / hygiene fixes.**
- Fix the cross-string index bug in `wmiRegion`/`wmiCountry` (`wmi.index(self.content.startIndex, …)` advances `content`'s index against `wmi`; use `wmi.startIndex` / `prefix(n)`).
- Replace the muddled single-`removeLast()` fallback in `computeLocalization` with explicit, structured lookups.
- `init(content:)` should **uppercase** so `VIN(content: "1hg…")` isn't spuriously invalid — but keep invalid chars/length intact so `validity` still reports them (only `propose()` sanitizes aggressively).
- Add `Sendable` conformance; bump `swift-tools-version` 5.4 → 5.9.
- Drop the `Resources/*.lproj` and `defaultLocalization` from `Package.swift` once the `.strings` data store is gone.

**Tests/docs.** Add coverage for the previously-untested check-digit math, model year, regionCode, and partial-input decoding; update README + the package's CLAUDE.md to the v2 API.

### Phase 2 — consume it from CornucopiaSUI

1. Add the `VIN` package dependency in `Package.swift` (zero-dep, iOS 13+/macOS 11+ — below our floor, so compatible).
2. Delete the private tables/logic now owned by the package:
   - `VINIdentity.swift`: `vinManufacturers` (265), `vinRegionRanges` (54), `vinCharacterOrder`, `vinRank`/`vinRegionCode`, `VINRegionRange`.
   - `VINTextField.swift`: `vinWeights`, `vinTransliteration`, `calculateCheckDigit`, `isValidCheckDigit`, `modelYearCodes`, `validVINCharacters`/`isValidVINCharacter`.
3. Re-express as **thin wrappers over `VIN`**, keeping the **same public API shape** so downstream consumers don't break:
   - `VINIdentity.decoding(_:)` → build from `VIN.wmiRegionCode` + `VIN.wmiManufacturer`. Keep `regionCode`, `manufacturer`, `countryName`, `flag` unchanged.
   - `VINComponents` → from `VIN.wmi`/`.vds`/`.vis` + `VIN.modelYear`.
   - `validateVIN(_:)` / `ValidationState` → drive char/length/check-digit checks off `VIN.validity` + `expectedCheckDigit`. The 6-state UI machine **stays in CornucopiaSUI** (it's UI, not model).
4. **Keep in CornucopiaSUI** (not the model package's job): `VINTextField`, `VINKeyboardInput`, `ValidationState`, and `VINVehicleDecoder`/`.nhtsa` online enrichment.

## Compatibility / risk notes

- **Public API:** preserve `VINIdentity` / `VINComponents` / `ValidationState` shapes. The one behavioral change is that **manufacturer name strings will shift** (561-table values + localization differ from the old 265). That's an improvement but a versioned, deliberate change — call it out in release notes.
- **Localization:** country name currently comes from `Locale` (free OS localization). Keep that path — i.e. keep deriving from the ISO code, not from the package's localized strings, so behavior is unchanged.
- **Two-repo change**, public-API-touching → deliberate, versioned; not a silent refactor.

## Verification checklist

- [ ] `VINIdentityTests` still pass (region/manufacturer/flag for the 15 sample VINs) — plus add the previously-untested check-digit and model-year coverage.
- [ ] `VINKeyboardInput` offline preview still shows flag + country + manufacturer + model-year while typing.
- [ ] NHTSA online path unchanged (verified VINs in CLAUDE.md still decode).
- [ ] No remaining private VIN tables in CornucopiaSUI (grep `vinManufacturers`, `vinRegionRanges`, `modelYearCodes`, `vinWeights`).

## Non-goals / rejected alternative

- Do **not** straight-swap to the package's string-based region (drops ISO-code/flag/`Locale`). Augment first.
- If we're unwilling to touch the VIN package, the acceptable fallback is to **leave them separate** and accept that the manufacturer tables diverge.
