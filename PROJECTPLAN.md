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

---

## Housekeeping (HK)

| # | Item | Description | Status |
|---|------|-------------|--------|

---

## Feature Backlog

| # | Feature | Description | Priority | Effort |
|---|---------|-------------|----------|--------|
| FF#3 | Get-AppxPackage integration | Add AppX/UWP packages as a fifth source for `Get-InstalledApp`. | Medium | S |
| FF#7 | Outdated version check | Compare each inventoried app's installed version against its latest available version, flag outdated ones. | Medium | M |
| FF#11 | Independent export collection | Exporting Apps/Features currently requires running Show first (which also pages the result onscreen) since Export reads `$LastAppResult`/`$LastFeatureResult`. Give Export its own source selection and collection step, independent of Show, so exporting doesn't force an unwanted onscreen display first. | Medium | S |

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
