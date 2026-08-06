# ASAK – Project Plan

- This file owns open work only. 
- Finished items move to [HISTORY.md](HISTORY.md)


## Vision

PowerShell 7 tooling for machine management and information gathering on Windows.

---

## Milestones

| # | Milestone | Includes | Status |
|---|-----------|----------|--------|
| M2 | Menu UX Overhaul | FF#4, FF#5, FF#6, FF#8, FF#9, FF#10 | Open |

---

## Technical Debt

| # | Topic | Description | Priority |
|---|-------|-------------|----------|

---

## Open Bugs

| # | Bug | Description | Priority |
|---|-----|-------------|----------|

---

## Housekeeping (HK)

| # | Item | Description | Status |
|---|------|-------------|--------|

---

## Feature Backlog

| # | Feature | Description | Priority | Effort |
|---|---------|-------------|----------|--------|
| FF#3 | Get-AppxPackage integration | Add AppX/UWP packages as a fifth source for `Get-InstalledApp`. | Medium | S |
| FF#4 | Paged onscreen output | Long inventories scroll past the console; add paging (e.g. `Out-Host -Paging`) to the menu's display step. | Medium | S |
| FF#5 | Clear screen on start | `ASAK.ps1` clears the console on launch, before showing the menu. | Low | S |
| FF#6 | Explain app sources in menu | `Show-AppsMenu`'s source list has no explanation text, unlike `Show-FeaturesMenu`. Add each source's trade-offs inline (speed, side effects, coverage). | Medium | S |
| FF#7 | Outdated version check | Compare each inventoried app's installed version against its latest available version, flag outdated ones. | Medium | M |
| FF#8 | Two-level menu restructure | Top menu becomes `App Management` / `Version Info`. `Show Installed Apps` and `Show Installed Features` move under `App Management`. Export becomes a per-branch item instead of a separate top-level entry (e.g. App Management: 1) Show Installed App, 2) Export Installed Apps to CSV). | Medium | M |
| FF#9 | Version Info menu item | New top-level menu item showing ASAK's own version, release notes, and basic usage instructions. | Medium | S |
| FF#10 | Default export path | `Show-ExportMenu`'s path prompt defaults to `.\<function name>.csv` instead of requiring a full path every time. | Low | S |

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
