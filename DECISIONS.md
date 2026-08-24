# ASAK – Architecture Decision Records

Each entry follows the ADR format: context, decision, reasons, known drawbacks, date.
Entries are in chronological order. Do not delete entries – mark superseded ones as such.

---

## ADR-001: Write-Information over Write-Host for menu output

**Date:** 2026-08-06

**Context:** `PSAvoidUsingWriteHost` flagged six `Write-Host` calls in `ASAK.ps1`'s menu. `verify.ps1` targets zero findings.

**Decision:** Switched to `Write-Information`, with `$InformationPreference = 'Continue'` set once at the top of `ASAK.ps1`.

**Reasons:** A `PSScriptAnalyzerSettings.psd1` suppression applies repo-wide, weakening the linter's ability to catch a genuine future `Write-Host` misuse elsewhere. `Write-Information` keeps the check fully live and is redirectable/capturable, unlike `Write-Host`.

**Known drawbacks:** Requires `$InformationPreference = 'Continue'` to be set explicitly, or the menu prints nothing.

---

## ADR-002: Scope the PSAvoidOverwritingBuiltInCmdlets exclusion to Tests\ only

**Date:** 2026-08-06

**Context:** `Get-InstalledApp`'s Pester tests stub `function Get-Package { }` before mocking it, working around `Get-Package`'s provider-injected dynamic parameters breaking Pester's mock-proxy generation (confirmed by isolated reproduction). `PSAvoidOverwritingBuiltInCmdlets` correctly flags the stub as shadowing a built-in cmdlet.

**Decision:** `tools/verify.ps1` runs `Invoke-ScriptAnalyzer` twice — full ruleset over production paths, `PSAvoidOverwritingBuiltInCmdlets` excluded (via an in-memory settings hashtable) over `Tests\` only.

**Reasons:** A repo-wide exclusion would also stop the rule from catching accidental cmdlet-shadowing in production code — the one place it actually matters. Shadowing built-ins in test doubles is a standard, accepted Pester pattern.

**Known drawbacks:** `verify.ps1` is more complex (two analyzer passes) than the single-settings-file model `CLAUDE.md` describes; the exclusion's scope lives in `verify.ps1`, not solely in `PSScriptAnalyzerSettings.psd1`.

---

## ADR-003: Background job with timeout for feature queries

**Date:** 2026-08-07

**Context:** `Get-WindowsOptionalFeature`/`Get-WindowsFeature` can hang indefinitely when the underlying DISM COM registration is broken, freezing the menu with no way out.

**Decision:** Run the feature query in a background job (`Start-Job`), capped by a 30-second timeout (`$FeatureQueryTimeoutSeconds`); on timeout or job error, abort the job and show a remediation message (`sfc /scannow`, DISM `/RestoreHealth`) instead of the raw error.

**Reasons:** A hung DISM call has no other cancellation point; a background job is the only way to enforce a deadline on it. The remediation message turns an opaque hang into an actionable fix.

**Known drawbacks:** The job script block re-dot-sources the function file by path instead of inheriting session state, since jobs run in a separate process. Timeout is fixed, not user-configurable.

---

## ADR-004: Exit-code check for winget install-status, not text parsing

**Date:** 2026-08-21

**Context:** `Get-InstalledApp`'s `Winget` source parses `winget list`'s fixed-width text output, a parser the code itself flags as breaking on any winget CLI format change. FF#36 needed a per-app install-status check.

**Decision:** `Test-WingetAppInstalled` runs `winget list --id <Id> --exact` and checks `$LASTEXITCODE -eq 0`, instead of parsing output text.

**Reasons:** winget's exit code reliably distinguishes found from not-found — confirmed empirically against real installed and not-installed packages — without depending on column layout at all.

**Known drawbacks:** `Install-WingetApp`/`Update-WingetApp`/`Uninstall-WingetApp` follow the same exit-code-only approach, so callers get a boolean success/fail with no more specific failure reason (e.g. can't distinguish "already installed" from "network error").

---

## ADR-005: One verb-named function per winget action, no shared helper

**Date:** 2026-08-21

**Context:** `Install-WingetApp`, `Update-WingetApp`, and `Uninstall-WingetApp` — the first `SupportsShouldProcess` functions in the repo — share near-identical shape: `ShouldProcess` gate, `& winget <verb> --id $Id ...`, `$LASTEXITCODE -eq 0`.

**Decision:** Kept as three separate functions/files rather than one function with an `-Action` parameter or a shared private helper.

**Reasons:** Install/Update/Uninstall are each approved PowerShell verbs; matches `FILEMAP.md`'s one-function-per-file convention; keeps each function's `ShouldProcess` message accurate to what it actually does.

**Known drawbacks:** The `ShouldProcess` gate, exit-code check, and argument shape are duplicated three times; a future winget action repeats the pattern rather than extending a parameter set.

---

## ADR-006: PowerShell 7 self-upgrade runs detached and never offers uninstall

**Date:** 2026-08-21

**Context:** ASAK requires PowerShell 7.6 to run at all. FF#38 needed to add PowerShell 7 (`Microsoft.PowerShell`) to the winget curated app list without letting the tool upgrade or remove the very interpreter it's currently running under.

**Decision:** `Update-WingetApp` gained a `-Detached` switch that runs `winget upgrade` via a spawned `cmd.exe` process (`Start-Process ... -Wait -PassThru`) instead of in-process. The curated-app data model gained `UpgradeOnly`/`DetachedUpgrade` flags; `Invoke-WingetAppAction` uses them to skip the install/uninstall offers entirely for the PowerShell 7 entry — only `Upgrade` is ever shown, and the `X` (uninstall) switch case explicitly refuses rather than falling through to the normal uninstall path.

**Reasons:** Upgrading the running `pwsh.exe` in-process risks the installer trying to replace files the current session has locked; a detached process keeps that risk out of ASAK's own process tree. Uninstalling the interpreter running ASAK would kill the session mid-action — not a recoverable mistake, so it's blocked structurally rather than relying on the usual confirmation prompt.

**Known drawbacks:** PowerShell 7 is the only curated app with this special-cased behavior, so `Invoke-WingetAppAction` now has two behavior paths instead of one uniform flow; the two flags have so far only ever co-occurred on this one entry, so a future app needing just one of the two behaviors isn't cleanly expressible yet.

---

## ADR-007: Update-WingetApp returns a status string; Install-/Uninstall-WingetApp stay bool

**Date:** 2026-08-21

**Context:** `winget upgrade` exits a distinct non-zero code when a package has no applicable upgrade — not a failure, but `Update-WingetApp`'s original `$LASTEXITCODE -eq 0` check (ADR-004) reported it as one, causing a false "Upgrade failed" warning for already-current apps (reported by the user for Claude Desktop App, reproduced directly).

**Decision:** `Update-WingetApp` now returns a status string (`Upgraded`/`UpToDate`/`Failed`/`Skipped`) instead of `[bool]`. `Install-WingetApp` and `Uninstall-WingetApp` keep their `[bool]` contract unchanged.

**Reasons:** Update is the only one of the three offered regardless of whether there's actually something to do — `Invoke-WingetAppAction` offers it whenever an app is installed, with no prior check for whether an upgrade exists. Install/Uninstall are only ever offered when the app's install state is already known (not-installed → Install offered; installed → Uninstall offered), so they don't have an analogous no-op-success case to distinguish from failure.

**Known drawbacks:** The three sibling functions (ADR-005) no longer share a uniform return type, which could read as an oversight rather than a deliberate choice without this ADR. If Install or Uninstall ever gain their own no-op-success case (e.g. Install called on an already-installed app), the same string-status treatment should be applied there too, not a different scheme.

---

## ADR-008: Position-based column parsing for Get-WingetUpgrade

**Date:** 2026-08-24

**Context:** `winget upgrade`'s column headers are localized by the OS locale (observed on this German-locale test machine: `Available` → `Verfügbar`, `Source` → `Quelle`), while `Name`/`ID`/`Version` and column order stay stable. `Get-InstalledApp`'s existing `Winget` parser looks up columns by hardcoded English header text and breaks silently under this localization (see the bug this ADR is paired with in `PROJECTPLAN.md`).

**Decision:** `Get-WingetUpgrade` derives column boundaries from the header row's word-start offsets (same technique as `Get-InstalledApp`), but reads each row's values by column **position** (Name=0, Id=1, Version=2, Available=3), not by header-text lookup.

**Reasons:** The only approach immune to header localization; winget has no structured/JSON output mode to fall back to (confirmed by `Get-InstalledApp`'s own comment).

**Known drawbacks:** Silently misreads output if winget ever reorders columns; a second, differently-keyed text parser now exists alongside `Get-InstalledApp`'s rather than one shared, fixed implementation.

---

## ADR-009: Batch-level ShouldProcess for Invoke-WingetBulkUpgrade

**Date:** 2026-08-24

**Context:** `Invoke-WingetBulkUpgrade` loops `Update-WingetApp`, which already gates itself with its own `ShouldProcess`. ADR-005 established one verb-named function per winget action, no shared helper, for Install/Update/Uninstall.

**Decision:** `Invoke-WingetBulkUpgrade` is a new orchestrating function — not a peer of Install/Update/Uninstall, a caller of one of them — with a single `ShouldProcess` gate for the whole batch, relying on `$WhatIfPreference` propagating automatically into each nested `Update-WingetApp` call.

**Reasons:** A second per-app gate here would double the `What if:` output and add nothing, since the nested call already gates itself.

**Known drawbacks:** `Invoke-WingetBulkUpgrade`'s `-WhatIf` output describes the batch, not each app individually, unlike every other `ShouldProcess` function in the repo.

---

