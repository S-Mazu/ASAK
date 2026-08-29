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

**Superseded by ADR-011.**

**Date:** 2026-08-21

**Context:** `winget upgrade` exits a distinct non-zero code when a package has no applicable upgrade — not a failure, but `Update-WingetApp`'s original `$LASTEXITCODE -eq 0` check (ADR-004) reported it as one, causing a false "Upgrade failed" warning for already-current apps (reported by the user for Claude Desktop App, reproduced directly).

**Decision:** `Update-WingetApp` now returns a status string (`Upgraded`/`UpToDate`/`Failed`/`Skipped`) instead of `[bool]`. `Install-WingetApp` and `Uninstall-WingetApp` keep their `[bool]` contract unchanged.

**Reasons:** Update is the only one of the three offered regardless of whether there's actually something to do — `Invoke-WingetAppAction` offers it whenever an app is installed, with no prior check for whether an upgrade exists. Install/Uninstall are only ever offered when the app's install state is already known (not-installed → Install offered; installed → Uninstall offered), so they don't have an analogous no-op-success case to distinguish from failure.

**Known drawbacks:** The three sibling functions (ADR-005) no longer share a uniform return type, which could read as an oversight rather than a deliberate choice without this ADR. If Install or Uninstall ever gain their own no-op-success case (e.g. Install called on an already-installed app), the same string-status treatment should be applied there too, not a different scheme.

---

## ADR-008: Position-based column parsing for Get-WingetUpgrade

**Superseded by ADR-010.**

**Date:** 2026-08-24

**Context:** `winget upgrade`'s column headers are localized by the OS locale (observed on this German-locale test machine: `Available` → `Verfügbar`, `Source` → `Quelle`), while `Name`/`ID`/`Version` and column order stay stable. `Get-InstalledApp`'s existing `Winget` parser looks up columns by hardcoded English header text and breaks silently under this localization (see the bug this ADR is paired with in `PROJECTPLAN.md`).

**Decision:** `Get-WingetUpgrade` derives column boundaries from the header row's word-start offsets (same technique as `Get-InstalledApp`), but reads each row's values by column **position** (Name=0, Id=1, Version=2, Available=3), not by header-text lookup.

**Reasons:** The only approach immune to header localization; winget has no structured/JSON output mode to fall back to (confirmed by `Get-InstalledApp`'s own comment).

**Known drawbacks:** Silently misreads output if winget ever reorders columns; a second, differently-keyed text parser now exists alongside `Get-InstalledApp`'s rather than one shared, fixed implementation.

---

## ADR-009: Batch-level ShouldProcess for Invoke-WingetBulkUpgrade

**Amended by ADR-012.**

**Date:** 2026-08-24

**Context:** `Invoke-WingetBulkUpgrade` loops `Update-WingetApp`, which already gates itself with its own `ShouldProcess`. ADR-005 established one verb-named function per winget action, no shared helper, for Install/Update/Uninstall.

**Decision:** `Invoke-WingetBulkUpgrade` is a new orchestrating function — not a peer of Install/Update/Uninstall, a caller of one of them — with a single `ShouldProcess` gate for the whole batch, relying on `$WhatIfPreference` propagating automatically into each nested `Update-WingetApp` call.

**Reasons:** A second per-app gate here would double the `What if:` output and add nothing, since the nested call already gates itself.

**Known drawbacks:** `Invoke-WingetBulkUpgrade`'s `-WhatIf` output describes the batch, not each app individually, unlike every other `ShouldProcess` function in the repo.

---

## ADR-010: One shared winget table parser, read by column position

**Date:** 2026-08-26

**Context:** ADR-008 made `Get-WingetUpgrade` read columns by position, but left `Get-InstalledApp`'s header-text lookup in place — a second parser and an open bug. `winget list` additionally emits 4 or 5 columns depending on whether any row has a pending upgrade, so the source column has no fixed index.

**Decision:** `ConvertFrom-WingetTable` is the single parser for every winget table. It emits one value array per data row, padded to the header's column count, read by position. `Get-InstalledApp` and `Get-WingetUpgrade` both consume it. Supersedes ADR-008.

**Reasons:** Immune to header localization; winget offers no structured output mode. Padding to the column count lets callers index a trailing column without a length check, which the variable `Available` column requires.

**Known drawbacks:** Still misreads output if winget reorders columns. `^Name\s` remains the one piece of header text relied on.

---

## ADR-011: Update-WingetApp returns an outcome object

**Date:** 2026-08-28

**Context:** ADR-007 gave `Update-WingetApp` a status-string return to separate "no applicable upgrade" from a real failure. Everything else collapsed into `Failed`, so reboot-required, another-install-in-progress and package-not-found were indistinguishable — the drawback ADR-004 named in advance. Bulk upgrade made it acute: a failure inside a batch was unactionable (BUG#3).

**Decision:** `Update-WingetApp` returns `[PSCustomObject]@{ Result; ExitCode }`. `Result` keeps ADR-007's four values (`Upgraded`/`UpToDate`/`Failed`/`Skipped`); `ExitCode` is the raw winget exit code, `$null` when the `ShouldProcess` gate declined. Supersedes ADR-007. `Install-WingetApp` and `Uninstall-WingetApp` keep their `[bool]` contract.

**Reasons:** The exit code is the only thing distinguishing one winget failure from another, and winget offers no structured output mode. Carrying it alongside the status keeps the classification in one place instead of making every caller re-derive it.

**Known drawbacks:** The three sibling functions (ADR-005) now have three different return shapes — bool, bool, object. Callers must reach through `.Result`, so a bare `switch (Update-WingetApp …)` silently stops matching rather than failing loudly.

---

## ADR-012: Batch approval suppresses the nested per-app gate

**Date:** 2026-08-28

**Context:** ADR-009 gave `Invoke-WingetBulkUpgrade` a single batch-level `ShouldProcess` gate and left `Update-WingetApp`'s own gate in place. It reasoned only about `-WhatIf` output, not about `-Confirm`: the operator was prompted once for the batch and again for every app (BUG#4).

**Decision:** After the batch gate passes, `Invoke-WingetBulkUpgrade` calls `Update-WingetApp` with `-Confirm:$false`. The nested gate stays in place for `Invoke-WingetAppAction`, where it is the only gate. Amends ADR-009.

**Reasons:** One approval decision should be asked once. Suppressing at the call site, rather than removing the nested gate, keeps `Update-WingetApp` safe to call directly.

**Known drawbacks:** `Invoke-WingetBulkUpgrade` now decides on the operator's behalf that batch approval covers every app in it; declining an individual app mid-batch is no longer possible. The suppression lives at the call site, so a future caller that also pre-approves must remember to repeat it.

---

## ADR-013: Windows currency is checked against endoflife.date and a local Windows Update scan

**Date:** 2026-08-29

**Context:** FF#22 asks whether the installed Windows is outdated. That is two questions. The feature-update level needs a published release list, and Microsoft publishes release health as HTML only. The patch level needs the machine's own view of what it is missing. Neither source answers both: endoflife.date publishes `latest` as `10.0.26200`, with no UBR.

**Decision:** `Get-WindowsVersion` reads local identity and compares the build against `https://endoflife.date/api/windows.json` (`windows-server.json` on Server), matching the cycle by `latest -eq "10.0.<CurrentBuild>"` and by edition track (`-e` for Enterprise/Education, `-w` otherwise). `Get-PendingWindowsUpdate` answers the patch level through the Windows Update Agent COM API. A failed lookup fills `CheckError` and the local half is still returned.

**Reasons:** endoflife.date is the only free source publishing latest build and support dates as JSON. The two functions stay separate because they fail differently: one needs the internet, the other needs minutes and a working update agent. Recording the failure instead of throwing keeps ASAK usable offline. Product identity comes from `Win32_OperatingSystem.Caption`, never the registry `ProductName`, which reads "Windows 10 Pro" on Windows 11.

**Known drawbacks:** A third-party service now sits in a code path; if it stops publishing, the comparison degrades to `CheckError` rather than breaking. The edition track is inferred from `EditionID`, so an unlisted edition reads as consumer. The scan refreshes the Windows Update metadata cache — read-only from the operator's view, not side-effect free — and `Get-PendingWindowsUpdate` deliberately carries no timeout of its own, since the caller bounds it per ADR-003.

---

## ADR-014: ConfigMgr presence is decided by the root\ccm namespace

**Date:** 2026-08-29

**Context:** FF#23 asks whether a machine is managed by Intune, ConfigMgr, or both. The Intune half reads `HKLM:\SOFTWARE\Microsoft\Enrollments`, and the same hive appears to answer the ConfigMgr half: a key on the test machine carries `ProviderID = WMI_Bridge_SCCM_Server`. That machine has no ConfigMgr client, and `root\ccm` is absent.

**Decision:** `Get-ConfigMgrClient` decides installed/not by whether `root\ccm`'s `SMS_Client` class responds. The Enrollments registry serves only the Intune side, keyed on `ProviderID -eq 'MS DM Server'` with `EnrollmentState -eq 1`. `Get-DeviceManagement` composes both and derives `CoManaged` / `Intune` / `ConfigMgr` / `None`.

**Reasons:** The namespace is created by the client installer and removed with it, so its presence is the fact being asked about. The WMI bridge entry is a provider registration that ships with Windows, not evidence of management — keying off it reports every machine as ConfigMgr-managed.

**Known drawbacks:** A ConfigMgr client broken enough that WMI does not answer reads as unmanaged. Domain and Entra join state are deliberately excluded (FF#24 covers those), so `ManagementMode` describes management only.

---
