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

