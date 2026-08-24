# ASAK – Project Plan

- This file owns open work only. 
- Finished items move to [HISTORY.md](HISTORY.md)


## Vision

PowerShell 7 tooling for machine management and information gathering on Windows.

---

## Milestones

| # | Milestone | Includes | Status |
|---|-----------|----------|--------|

---

## Technical Debt

| # | Topic | Description | Priority |
|---|-------|-------------|----------|

---

## Open Bugs

| # | Bug | Description | Priority |
|---|-----|-------------|----------|
| BUG#1 | `Get-InstalledApp` Winget source drops Publisher on non-English Windows | The `Winget` branch looks up the winget-list `Source` column by the literal header text `'Source'`; winget localizes that header (observed on this machine's German locale: `Quelle`), so `Publisher` is silently `$null` for every Winget-sourced row. | Medium |

---

## Housekeeping (HK)

| # | Item | Description | Status |
|---|------|-------------|--------|

---

## Feature Backlog

| # | Feature | Description | Priority | Effort |
|---|---------|-------------|----------|--------|
| FF#7 | Outdated version check | Compare each inventoried app's installed version against its latest available version, flag outdated ones. | Medium | M |
| FF#12 | Show Windows license key | Retrieve and display the Windows product/license key. | Low | S |
| FF#13 | Get Autopilot hardware hash | Retrieve the hardware hash/ID needed for Windows Autopilot device registration. | Medium | S |
| FF#14 | Comparable inventory output | Add comparison capability to inventory results where sensible (e.g. diff two exports, or cross-check sources against each other). | Medium | M |
| FF#15 | Uninstall packages | Add uninstall capability for installed apps/packages. State-changing — needs `ShouldProcess` per the Execution Boundary. | Medium | M |
| FF#16 | Install via winget | Install applications via winget from the menu. State-changing — needs `ShouldProcess`. | Medium | M |
| FF#17 | Install common PowerShell modules | Menu shortcut to install frequently-used modules (e.g. ExchangeOnlineManagement, PnP.PowerShell, Microsoft.Graph/Entra). State-changing — needs `ShouldProcess`. | Medium | M |
| FF#18 | Recent System/Security event log errors | Show the last 10 Error/Critical entries from the System and Security event logs. | Medium | S |
| FF#19 | Get Intune enrollment status | Show the device's Intune management/enrollment status. | Medium | S |
| FF#20 | Local admin group members | List local users who are members of the local Administrators group. | Medium | S |
| FF#21 | Detect duplicate app installs | Flag apps with multiple installed versions present at once (e.g. two versions of the same app) in the inventory output. | Medium | S |
| FF#22 | Windows version check | Compare the installed Windows version/build against the most recent available version, flag if outdated. | Medium | S |
| FF#23 | SCCM vs Intune management status | Show which management is configured (SCCM, Intune, or co-management). | Medium | S |
| FF#24 | AD join status | Show Active Directory domain join status (domain-joined, Azure AD/Entra joined, or workgroup). | Medium | S |
| FF#25 | TPM status and version | Show TPM presence, status, and version. | Medium | S |
| FF#26 | Clear Teams cache | Clear Microsoft Teams cache. State-changing — needs `ShouldProcess`. | Low | S |
| FF#27 | Clear temp files | Clear temporary files. State-changing — needs `ShouldProcess`. | Low | S |
| FF#28 | Remove old Windows version | Remove `Windows.old` after an OS upgrade. State-changing — needs `ShouldProcess`. | Low | S |
| FF#29 | Delete Edge cache | Clear Microsoft Edge browser cache. State-changing — needs `ShouldProcess`. | Low | S |
| FF#30 | Reset Edge | Reset Microsoft Edge to its default state. State-changing — needs `ShouldProcess`. | Low | M |
| FF#31 | DISM and SFC troubleshooting | Run DISM `/RestoreHealth` and SFC `/scannow` for system file repair. State-changing — needs `ShouldProcess`. | Medium | M |
| FF#32 | Join domain | Join the computer to an Active Directory domain. State-changing — needs `ShouldProcess`. | Medium | M |
| FF#33 | Network stats | Show IP configuration, gateway, and DNS servers. | Medium | S |
| FF#39 | Add Notepad++ to curated apps | Add Notepad++ (`Notepad++.Notepad++`) to `Script:WingetCuratedApps` so it's installable/upgradable/uninstallable from the Software Install menu. Implemented, `tools/verify.ps1` passes, awaiting `Live-Test.`. | Low | S |
| FF#40 | Bulk-upgrade winget apps | Menu command to upgrade all pending winget updates in one step; user chooses curated-list-only or all machine-detected upgrades. State-changing — needs `ShouldProcess`. Implemented, `tools/verify.ps1` passes, awaiting `Live-Test.`. | Medium | M |

---

---

## Glossary

### Effort

| Size | Definition |
|------|------------|
| S | One turn. Clear scope. |
| M | Multiple turns with challenge/review. No architectural decision needed. |
| L | Leads to an ADR. |
| XL | L-sized decision with full codebase impact. |

### Priority

| Level | Definition |
|-------|------------|
| Low | No impact on core workflow. Address when convenient. |
| Medium | Affects quality or developer experience. Address before next major release. |
| High | Blocks core functionality or causes data loss. Address immediately. |
