# VIN model-layer consolidation (backlog)

**Goal:** make `Automotive-Swift/VIN` the single source of truth for VIN domain logic, and have CornucopiaSUI consume it instead of maintaining its own private copies. Strategy is **augment-then-consume**, not a blind swap.

**Status:** agreed, low urgency. Schedule after the keypad-toolkit milestone. Nothing is broken today — the ISO check-digit algorithm is stable, and the offline manufacturer table is only a fallback (NHTSA gives authoritative make/model when online). This is hygiene: one source of truth, richer + localized data, fewer tables to drift.

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

### Phase 1 — enhance `Automotive-Swift/VIN`

1. **ISO 3166 alpha-2 region code** accessor (e.g. `var wmiRegionCode: String?`). Port CornucopiaSUI's 54 ISO-3780 ranges (`vinRegionRanges` in `VINIdentity.swift`) + rank logic. This is the gating change — without it, do **not** migrate.
2. **Model-year decoding** from position 10 (e.g. `var modelYear: Int?` / `func modelYear() -> Int?`). Port `modelYearCodes` (30 entries) from `VINTextField.swift`. Pure VIN logic that belongs here. Note the NA 30-year cycle ambiguity (Y=2000 repeats 2030) — document it.
3. **Expected check digit** accessor, if not already derivable cleanly. CornucopiaSUI's `validWithCheckDigitWarning` needs the *computed* digit to show the user. `propose().checksumDigit` works but expose it directly (e.g. `var expectedCheckDigit: Character?`).
4. Tests for the new accessors (the package already has good coverage; match its style).

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
