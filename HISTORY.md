# ASAK – History

- This file is the **completed** record.
- It is append-only.
---

## 2026-08-06

- **M1 — Skeleton + First Feature**: shipped and live-tested, no bugs found.
- **FF#1 — Menu Shell**: `ASAK.ps1` entry point, `#requires -RunAsAdministrator` elevation guard, dot-sources `Functions\`, text menu loop.
- **FF#2 — Installed Apps & Features Inventory**: split into three functions during implementation — `Get-InstalledApp` (multi-select across Registry, Win32_Product, Package, Winget, tagged by source), `Get-InstalledFeature` (single-select between `Get-WindowsOptionalFeature` and `Get-WindowsFeature`), `Export-InventoryCsv` (toggleable NoTypeInformation/Encoding/Delimiter, unconditional export).
- **M2 — Menu UX Overhaul**: shipped and live-tested, no bugs found (one non-bug: `docs:` links stay plain-text since the test machine runs the legacy `conhost.exe`, which has no clickable-link support regardless of setting — accepted as a known copy-paste fallback).
- **FF#4 — Paged onscreen output**: both inventory displays pipe through `Out-Host -Paging`.
- **FF#5 — Clear screen on layer transitions**: broader than the original "on start" wording — clears on launch and on every top-menu ↔ submenu transition, not while staying inside a submenu's own loop.
- **FF#6 — Explain app sources in menu**: `Show-AppsMenu` states what each source actually returns (not just behavior), each with an MS Learn link — corrected mid-milestone after research showed the original draft mischaracterized `Package` (PowerShell/NuGet modules, not desktop apps) and `Winget` (broader than winget-only installs).
- **FF#8 — Two-level menu restructure**: top menu is `App Management` / `Version Info`; App Management is a flat submenu (Show/Export × Apps/Features); export tracks `$LastAppResult`/`$LastFeatureResult` separately.
- **FF#9 — Version Info menu item**: shows `$AsakVersion`, a short static usage summary, and points to `HISTORY.md` for release notes.
- **FF#10 — Default export path**: empty path prompt defaults to `.\<function name>.csv`.
