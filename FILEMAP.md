# FILEMAP

Which file owns which concern. Read before creating a file or moving code.

- **`ASAK.ps1`** — entry point and menu. Dot-sources everything in `Functions\`.
- **`Functions\`** — one function per file, filename matches the function name. Does the actual work.
- **`Tests\`** — one Pester test file per function, filename mirrors its `Functions\` counterpart.
- **`tools\verify.ps1`** — runs PSScriptAnalyzer and Pester, throws on any finding.
- **`PSScriptAnalyzerSettings.psd1`** — rule suppressions for `verify.ps1`.
- **`README.md`** — requirements, install, usage.
- **`CLAUDE.md`** — working agreements and conventions.
- **`DECISIONS.md`** — architectural decisions (ADRs).
- **`HISTORY.md`** — dated log of completed work.
- **`PROJECTPLAN.md`** — open work.
- **`FILEMAP.md`** — this file.
