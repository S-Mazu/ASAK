## Project

**ASAK** (Admin's Swiss Army Knife) — PowerShell 7 tooling for machine
management and information gathering on Windows.

## Where things are documented

- **Why it is that way** — `DECISIONS.md` (ADRs). Decisions that never got an ADR
  are in `HISTORY.md`, which also holds all completed work.
- **Which file owns which concern** — `FILEMAP.md`. Read it before creating a file
  or moving code.
- **Requirements, install, usage** — `README.md`.
- **Open work** — `PROJECTPLAN.md`.

## Change Control

- **`CLAUDE.md`, `DECISIONS.md`, `PROJECTPLAN.md` are approval-gated.** Present a draft for the change and wait for confirmation.

## Execution Boundary

Default stage: **no state change.** Read-only commands, `-WhatIf` runs and
`tools/verify.ps1` only. Present the result and stop.

- **`Live-Test.` lifts the boundary for the current execution only.** 
- **After a live test, report what changed on the Machine.**
- **Every state-changing function declares `[CmdletBinding(SupportsShouldProcess)]`**
  and gates on `$PSCmdlet.ShouldProcess()`.

## Verification

A change is verified by `tools/verify.ps1` passing, plus manual use. It runs
PSScriptAnalyzer (`-Severity ParseError,Error,Warning`) and Pester, and throws on
any finding.

- **Run it and report its actual output.**
- **Zero findings is the target.** Warnings count — list every one.
- **Suppress a rule only in `PSScriptAnalyzerSettings.psd1`**, never with an
  inline `SuppressMessage` attribute.
- **If a required module is missing, report it.**
- **Every function ships with Pester tests.** Mock the external call — winget,
  registry, filesystem.

## Code Style

- **PowerShell 7.6 LTS is the floor.** Every file starts `#requires -Version 7.6`.
- **PascalCase for variable names.**
- **Follow the Microsoft development guidelines for PowerShell.**

## Rules for working with the user

- **Implement only what was explicitly instructed.**
- **Answer only what was asked.**
- **Keep reports and decisions short.**
- **Prefer the polished, maintainable option over the cheapest.**
- **If several things need to be dicided name the total und present them one after the other, starting with highest priority and severety.**

## Documentation Style

Applies to `CLAUDE.md`, `PROJECTPLAN.md`, `DECISIONS.md`, `README.md`.

- **All project documentation is written in English.**
- **A rule stands alone.**
- **Deletion test:** cut the explanation. If the rule still holds, it stays cut.
  If it collapses, the reason belongs in an ADR — state the rule, link the ADR.
- **One bullet, one rule.**
- **Document what the code cannot state:** invariants, seams, order constraints.
- **Never document what the code already states.** No directory trees, no
  dependency lists, no file-by-file descriptions.
- **Only name the alternative where it is a mistake someone would actually make.**
- **Bold marks identifiers and rules.**
- **An adverb earns its place by changing the meaning.**
- **`PROJECTPLAN.md` holds open work.**
- **`HISTORY.md` is append-only.**

## Documentation Protocol

Triggered by the user with `Doku-Protokoll.` at the end of a work session.

**"No change" is a valid result for every step.**

### Phase A — report, write nothing

Respect Documentation Style. Work through steps 1–8 and collect the findings into **one** report, then wait
for approval.

1. **`PROJECTPLAN.md` and `HISTORY.md`**** — list the resolved bugs/features/housekeeping/technical dept/milestones to be marked
   done and removed from their open table an to be moved to `HISTORY.md`. `HISTORY.md` contains dated (`Get-Date -Format 'yyyy-MM-dd'`) 
   solved items. An Item can only be in `PROJECTPLAN.md` or `HISTORY.md`.
3. **`CLAUDE.md`** — propose a change only if a convention or one of these
   working agreements changed.
4. **`DECISIONS.md`** — if an architectural decision was made, draft the ADR.
5. **New bugs discovered** — describe with priority.
6. **`FILEMAP.md`** — propose a change only if a file gained, lost or handed over
   a concern.
7. **`README.md`** — propose a change only if requirements, install or usage
   changed.
8. **Consistency check** — compare `PROJECTPLAN.md` against `HISTORY.md`. Report
   duplicates.

### Phase B — user approval and apply

The user approval is needed to apply changes from Phase A. After applying do a verification: look for duplicates, check touched items against Documentation Style rules. Report findings.
