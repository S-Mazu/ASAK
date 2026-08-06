# ASAK – History

- This file is the **completed** record.
- It is append-only.
---

## 2026-08-06

- **M1 — Skeleton + First Feature**: shipped and live-tested, no bugs found.
- **FF#1 — Menu Shell**: `ASAK.ps1` entry point, `#requires -RunAsAdministrator` elevation guard, dot-sources `Functions\`, text menu loop.
- **FF#2 — Installed Apps & Features Inventory**: split into three functions during implementation — `Get-InstalledApp` (multi-select across Registry, Win32_Product, Package, Winget, tagged by source), `Get-InstalledFeature` (single-select between `Get-WindowsOptionalFeature` and `Get-WindowsFeature`), `Export-InventoryCsv` (toggleable NoTypeInformation/Encoding/Delimiter, unconditional export).
