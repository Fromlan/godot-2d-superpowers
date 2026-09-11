<#
.SYNOPSIS
    Verify Godot API claims made by skill SKILL.md files against the
    official Godot 4.x docs (docs.godotengine.org).

.DESCRIPTION
    Cross-references a curated list of "API facts" against the live Godot
    stable docs. Each fact states: the skill file that asserts it, what is
    asserted, and how to verify it from the docs. Output is a markdown
    audit file at build/audit/godot-claims-<date>.md.

    By default, network failures produce a WARN, not a FAIL (so offline
    users can still complete release). Pass -Strict to make any FAIL or
    WARN exit with non-zero.

.PARAMETER ProjectPath
    Repo root. Default: current directory.

.PARAMETER Strict
    Exit non-zero on any FAIL or WARN (use in CI).

.PARAMETER SkipNetwork
    Skip the docs fetch; only do local file checks. Always returns OK if
    nothing failed locally.

.EXAMPLE
    .\scripts\verify-godot-claims.ps1
    .\scripts\verify-godot-claims.ps1 -Strict
#>
param(
    [string]$ProjectPath = ".",
    [switch]$Strict,
    [switch]$SkipNetwork
)

$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

function Write-Step {
    param([string]$Message, [string]$Color = "Cyan")
    Write-Host "[verify] $Message" -ForegroundColor $Color
}

# Resolve paths
$root = Resolve-Path -LiteralPath $ProjectPath
$auditDir = Join-Path $root "build\audit"
if (-not (Test-Path $auditDir)) {
    New-Item -ItemType Directory -Path $auditDir -Force | Out-Null
}
$dateStr = Get-Date -Format "yyyy-MM-dd"
$auditFile = Join-Path $auditDir "godot-claims-$dateStr.md"

# ---- The curated facts to verify ----
# Each: id, asserting-skill, claim-text, doc-url, regex (against fetched HTML), expected-match (true/false)
$facts = @(
    @{
        id = "F001"
        skill = "skills/godot-2d-physics/SKILL.md"
        claim = "CharacterBody2D has method move_and_collide (inherited from PhysicsBody2D)"
        url = "https://docs.godotengine.org/en/stable/classes/class_characterbody2d.html"
        regex = 'class-characterbody2d-method-move-and-collide'
        expect = $true
    },
    @{
        id = "F002"
        skill = "skills/godot-2d-physics/SKILL.md"
        claim = "CharacterBody2D has method move_and_slide"
        url = "https://docs.godotengine.org/en/stable/classes/class_characterbody2d.html"
        regex = 'class-characterbody2d-method-move-and-slide'
        expect = $true
    },
    @{
        id = "F003"
        skill = "skills/godot-2d-physics/SKILL.md"
        claim = "CharacterBody2D has method get_slide_collision"
        url = "https://docs.godotengine.org/en/stable/classes/class_characterbody2d.html"
        regex = 'class-characterbody2d-method-get-slide-collision'
        expect = $true
    },
    @{
        id = "F004"
        skill = "skills/godot-2d-physics/SKILL.md"
        claim = "test_move is a method on PhysicsBody2D (CharacterBody2D inherits it)"
        url = "https://docs.godotengine.org/en/stable/classes/class_physicsbody2d.html"
        regex = 'class-physicsbody2d-method-test-move'
        expect = $true
    },
    @{
        id = "F010"
        skill = "skills/asset-pipeline/SKILL.md"
        claim = "compress/mode = 0 means Lossless"
        url = "https://docs.godotengine.org/en/stable/classes/class_resourceimportertexture.html"
        regex = 'Lossless'
        expect = $true
    },
    @{
        id = "F011"
        skill = "skills/asset-pipeline/SKILL.md"
        claim = "VRAM Compressed is described in docs as 'Only use for textures in 3D scenes, not for 2D elements'"
        url = "https://docs.godotengine.org/en/stable/classes/class_resourceimportertexture.html"
        regex = 'Only use for textures in 3D scenes, not for 2D elements'
        expect = $true
    },
    @{
        id = "F020"
        skill = "skills/godot-audio/SKILL.md"
        claim = "AudioServer has method set_bus_volume_db(bus_idx: int, volume_db: float)"
        url = "https://docs.godotengine.org/en/stable/classes/class_audioserver.html"
        regex = 'set_bus_volume_db'
        expect = $true
    },
    @{
        id = "F021"
        skill = "skills/godot-audio/SKILL.md"
        claim = "AudioServer has method get_bus_index(bus_name: StringName)"
        url = "https://docs.godotengine.org/en/stable/classes/class_audioserver.html"
        regex = 'get_bus_index'
        expect = $true
    },
    @{
        id = "F030"
        mode = "stripped"
        skill = "skills/godot-audio/SKILL.md"
        claim = "Tween has method tween_method(method: Callable, from: Variant, to: Variant, duration: float)"
        url = "https://docs.godotengine.org/en/stable/classes/class_tween.html"
        regex = 'tween_method\s*\(\s*method:\s*Callable'
        expect = $true
    }
)


    @{
        id = "F005"
        skill = "skills/godot-2d-physics/SKILL.md"
        claim = "CharacterBody2D inherits from PhysicsBody2D (so it has move_and_collide, test_move, etc.)"
        url = "https://docs.godotengine.org/en/stable/classes/class_characterbody2d.html"
        regex = 'class-physicsbody2d'
        expect = $true
    },
    @{
        id = "F006"
        skill = "skills/godot-ui-best-practices/SKILL.md"
        claim = "Control.mouse_filter default is STOP (0) - eats events"
        url = "https://docs.godotengine.org/en/stable/classes/class_control.html"
        regex = 'MOUSE_FILTER_STOP'
        expect = $true
    },
    @{
        id = "F007"
        skill = "skills/godot-animation/SKILL.md"
        claim = "AnimatedSprite2D class exists in Godot 4"
        url = "https://docs.godotengine.org/en/stable/classes/class_animatedsprite2d.html"
        regex = 'class-animatedsprite2d-method-play'
        expect = $true
    },
    @{
        id = "F008"
        skill = "skills/godot-gdscript-patterns/SKILL.md"
        claim = "Typed Dictionary syntax Dictionary[K, V] supported (Godot 4.4+)"
        url = "https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_basics.html"
        regex = 'Dictionary\[K, V\]'
        expect = $true
    },
    @{
        id = "F009"
        skill = "skills/godot-audio/SKILL.md"
        claim = "AudioServer.get_bus_index accepts a StringName parameter"
        url = "https://docs.godotengine.org/en/stable/classes/class_audioserver.html"
        regex = 'get_bus_index'
        expect = $true
    }

# ---- Run checks ----
$results = @()
$failCount = 0
$skipCount = 0
$warnCount = 0
$passCount = 0

# Cache fetched HTML by URL
$cache = @{}

foreach ($f in $facts) {
    $status = "PASS"
    $detail = ""
    $skipped = $false

    if ($SkipNetwork) {
        $status = "SKIP"
        $detail = "network skipped"
        $skipped = $true
    } else {
        try {
            $url = $f.url
            if (-not $cache.ContainsKey($url)) {
                $tmp = Join-Path $env:TEMP ("godot_" + [guid]::NewGuid() + ".html")
                & curl.exe -sSLk --max-time 20 $url -o $tmp 2>&1 | Out-Null
                if (Test-Path $tmp) {
                    $cache[$url] = [System.IO.File]::ReadAllText($tmp)
                    Remove-Item $tmp -Force -ErrorAction SilentlyContinue
                } else {
                    $cache[$url] = ""
                }
            }
            $html = $cache[$url]
            if ($html.Length -lt 1000) {
                $status = "WARN"
                $detail = "fetched page too small (network?)"
                $warnCount++
            } else {
                if ($f.mode -eq "stripped") {
                    $haystack = $html -replace '<[^>]+>', ' ' -replace '\s+', ' '
                } else {
                    $haystack = $html
                }
                $matched = $haystack -match $f.regex
                if ($matched -eq $f.expect) {
                    $status = "PASS"
                    $detail = "regex matched as expected"
                    $passCount++
                } else {
                    $status = "FAIL"
                    $detail = "regex match=$matched, expected=$($f.expect)"
                    $failCount++
                }
            }
        } catch {
            $status = "WARN"
            $detail = "fetch error: $($_.Exception.Message)"
            $warnCount++
        }
    }

    if ($status -eq "SKIP") { $skipped = $true; $skipCount++ }

    $color = switch ($status) {
        "PASS" { "Green" }
        "FAIL" { "Red" }
        "WARN" { "Yellow" }
        "SKIP" { "DarkGray" }
    }
    Write-Host ("{0} {1}  {2}" -f $f.id, $status, $f.claim) -ForegroundColor $color

    $results += [pscustomobject]@{
        Id = $f.id
        Status = $status
        Skill = $f.skill
        Claim = $f.claim
        Url = $f.url
        Detail = $detail
    }
}

# ---- Write audit markdown ----
$md = New-Object System.Text.StringBuilder
$null = $md.AppendLine("# Godot API Claims Audit - $dateStr")
$null = $md.AppendLine("")
$null = $md.AppendLine("- PASS: {0}" -f $passCount)
$null = $md.AppendLine("- FAIL: {0}" -f $failCount)
$null = $md.AppendLine("- WARN: {0}" -f $warnCount)
$null = $md.AppendLine("- SKIP: {0}" -f ($results | Where-Object Status -eq "SKIP").Count)
$null = $md.AppendLine("")
$null = $md.AppendLine("| ID | Status | Skill | Claim | Detail |")
$null = $md.AppendLine("|----|--------|-------|-------|--------|")
foreach ($r in $results) {
    $null = $md.AppendLine( ("| {0} | {1} | {2} | {3} | {4} |" -f $r.Id, $r.Status, $r.Skill, $r.Claim, $r.Detail) )
}
$null = $md.AppendLine("")
$null = $md.AppendLine("_Generated by `scripts/verify-godot-claims.ps1`._")
Set-Content -LiteralPath $auditFile -Value $md.ToString() -Encoding UTF8

Write-Step ""
Write-Step ("Audit written: {0}" -f $auditFile) "Cyan"
Write-Step ("Summary: PASS={0} FAIL={1} WARN={2}" -f $passCount, $failCount, $warnCount) $(if($failCount -gt 0){"Red"}else{"Green"})

# Exit code
if ($Strict) {
    if ($failCount -gt 0 -or $warnCount -gt 0) { exit 1 }
} else {
    if ($failCount -gt 0) { exit 1 }
}
exit 0
