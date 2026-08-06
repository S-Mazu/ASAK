# ASAK – Project Plan

- This file owns open work only. 
- Finished items move to [HISTORY.md](HISTORY.md)


## Vision

PowerShell 7 tooling for machine management and information gathering on Windows.

---

## Milestones

| # | Milestone | Includes | Status |
|---|-----------|----------|--------|
| M1 | Skeleton + First Feature | FF#1, FF#2 | Open |

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
| FF#1 | Menu Shell | `ASAK.ps1` entry point: interactive menu, admin-elevation check, dot-sources `Functions\`. | High | M |
| FF#2 | Installed Apps & Features Inventory | Function listing installed applications and Windows features/roles; onscreen display or CSV export. | High | M |

---

---

## Glossary

### Effort

| Size | Definition | Example |
|------|------------|---------|
| S | One turn. Clear scope. | FF#15 (footer + Impressum), FF#18 (allow negative HP), HK#1 (`.gitattributes`) |
| M | Multiple turns with challenge/review. No architectural decision needed. | FF#17 (combat undo), FF#4 (configurable initiative roll) |
| L | Leads to an ADR — requires discussion, trade-offs, likely broader code changes. | FF#7 (game-system templates), FF#5 (theming → ADR-007) |
| XL | L-sized decision + weeks of execution or full codebase impact. | ADR-001 (monolith → Vite+React migration), FF#3 (responsive layout → ADR-004) |

### Priority

| Level | Definition |
|-------|------------|
| Low | No impact on core workflow. Address when convenient. |
| Medium | Affects quality or developer experience. Address before next major release. |
| High | Blocks core functionality or causes data loss. Address immediately. |
