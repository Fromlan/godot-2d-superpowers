<#
.SYNOPSIS
    Lint all SKILL.md files in skills/ for required frontmatter fields and link reachability.

.DESCRIPTION
    Scans every skills/**/SKILL.md, validates:
      - frontmatter contains: name, description, last_reviewed, <!-- argument-hint: ... -->
      - last_reviewed matches YYYY-MM-DD
      - description length <= 300 characters
      - markdown links of the form references/<file>.md resolve to an existing file

    Output is a one-line summary per skill. Exit 0 if all pass, 1 if any fail.
    Designed for Windows PowerShell; portable enough for POSIX pwsh.

.PARAMETER ProjectPath
    Repo root. Default: current directory.

.EXAMPLE
    .\scripts\lint-skills.ps1
    .\scripts\lint-skills.ps1 -ProjectPath .
#>
param(
    [string]$ProjectPath = ".",
    [switch]$CheckLocaleRatio
)

$ErrorActionPreference = "Stop"

function Write-Step {
    param([string]$Message, [string]$Color = "Cyan")
    Write-Host "[lint-skills] $Message" -ForegroundColor $Color
}

$root = Resolve-Path -LiteralPath $ProjectPath
$skillsRoot = Join-Path $root "skills"

if (-not (Test-Path $skillsRoot)) {
    Write-Step "skills/ not found at $skillsRoot" "Red"
    exit 2
}

# Find all SKILL.md
$skillFiles = Get-ChildItem -Path $skillsRoot -Recurse -Filter SKILL.md | Sort-Object FullName

$failCount = 0
$passCount = 0

foreach ($sf in $skillFiles) {
    $rel = $sf.FullName.Substring($skillsRoot.Length + 1)
    $content = Get-Content -LiteralPath $sf.FullName -Raw -Encoding UTF8
    $issues = @()

    # Extract frontmatter (between first two --- lines)
    $fmMatch = [regex]::Match($content, "(?ms)^---\s*\n(.*?)\n---\s*\n")
    if (-not $fmMatch.Success) {
        $issues += "missing or malformed frontmatter"
    } else {
        $fm = $fmMatch.Groups[1].Value
        $skillDir = Split-Path -Parent $sf.FullName

        # Required: name
        if (-not ($fm -match "(?m)^name:\s*\S+")) {
            $issues += "missing name:"
        }

        # Required: description
        if (-not ($fm -match "(?ms)^description:(\s*\|.*?)(?=^[a-z_]+:|^---)|(?m)^description:\s*.+")) {
            $issues += "missing description:"
        } else {
            # Compute description length (strip block-marker and leading indent)
            $descMatch = [regex]::Match($fm, "(?ms)^description:\s*(?:\|\s*)?\n(.*?)(?=^[a-z_]+:\s|\Z)")
            if (-not $descMatch.Success) {
                $descMatch = [regex]::Match($fm, "(?m)^description:\s*(.+?)\s*$")
            }
            if ($descMatch.Success) {
                $desc = $descMatch.Groups[1].Value
                # Collapse whitespace
                $descNorm = ($desc -replace "\s+", " ").Trim()
                if ($descNorm.Length -gt 300) {
                    $issues += "description too long: $($descNorm.Length) chars (>300)"
                }
            }
        }

        # Required: last_reviewed (YYYY-MM-DD)
        $lrMatch = [regex]::Match($fm, "(?m)^last_reviewed:\s*(\S+)")
        if (-not $lrMatch.Success) {
            $issues += "missing last_reviewed:"
        } elseif (-not ($lrMatch.Groups[1].Value -match "^\d{4}-\d{2}-\d{2}$")) {
            $issues += "last_reviewed not YYYY-MM-DD: $($lrMatch.Groups[1].Value)"
        }

        # Required: <!-- argument-hint: ... -->
        if (-not ($content -match "<!-- argument-hint:")) {
            $issues += "missing <!-- argument-hint: ... -->"
        }

        # Link reachability: references/<file>.md
        $refMatches = [regex]::Matches($content, "(?<=\(|\]\()references/([\w\-\.\d]+\.md)")
        foreach ($m in $refMatches) {
            $refName = $m.Groups[1].Value
            $refPath = Join-Path $skillDir "references/$refName"
            if (-not (Test-Path -LiteralPath $refPath)) {
                $issues += "broken link: references/$refName"
            }
        }
    }

    if ($issues.Count -eq 0) {
        Write-Host ("PASS  {0}" -f $rel) -ForegroundColor Green
        $passCount++
    } else {
        Write-Host ("FAIL  {0}" -f $rel) -ForegroundColor Red
        foreach ($i in $issues) {
            Write-Host ("        - {0}" -f $i) -ForegroundColor DarkRed
        }
        $failCount++
    }
}


$localeRatioFail = 0
if ($CheckLocaleRatio) {
    Write-Step ""
    Write-Step "Locale ratio check (CN char count)..." "Cyan"
    foreach ($sf in $skillFiles) {
        $rel = $sf.FullName.Substring($skillsRoot.Length + 1)
        $contentFull = Get-Content -LiteralPath $sf.FullName -Raw -Encoding UTF8
        $cn = ([regex]::Matches($contentFull, "[\u4e00-\u9fff]")).Count
        $en = ([regex]::Matches($contentFull, "[A-Za-z]")).Count
        $total = $cn + $en
        $pct = if ($total -gt 0) { [int]($cn * 100 / $total) } else { 0 }
        $status = if ($pct -ge 50) { "PASS" } else { "WARN" }
        $color = if ($pct -ge 50) { "Green" } else { "Yellow" }
        Write-Host ("{0,-50} CN={1,4} EN={2,5} {3,3}%" -f $rel, $cn, $en, $pct) -ForegroundColor $color
        if ($pct -lt 50) { $localeRatioFail++ }
    }
}

Write-Step ""
Write-Step ("Summary: PASS={0}  FAIL={1}" -f $passCount, $failCount) $(if ($failCount -gt 0) { "Red" } else { "Green" })

if ($CheckLocaleRatio) {
    Write-Step ("Locale warnings (CN < 50%): {0}" -f $localeRatioFail) $(if ($localeRatioFail -gt 0) { "Yellow" } else { "Green" })
}

if ($failCount -gt 0) { exit 1 } else { exit 0 }
