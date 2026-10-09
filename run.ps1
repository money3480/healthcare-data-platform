# Healthcare Platform — full pipeline runner
# Usage:
#   . .\set-env.ps1          (once per terminal session)
#   .\run.ps1                (full run: snapshot + build)
#   .\run.ps1 -Target dev -- Run for dev schema
#   .\run.ps1 -FullRefresh -- force full rebuild of incremental models
#   .\run.ps1 -Select fct_claims -- rebuild one model only (still runs snapshot first)
#
param(
    [string]$Target      = "dev",
    [switch]$FullRefresh,
    [string]$Select      = ""
)

$ErrorActionPreference = "Stop"

if (-not $env:SNOWFLAKE_ACCOUNT) {
    Write-Error "Environment not set. Run:  . .\set-env.ps1  first."
    exit 1
}

$flags    = "--profiles-dir _prod_profiles --target $Target"
$refresh  = if ($FullRefresh) { "--full-refresh" } else { "" }
$selector = if ($Select)      { "--select $Select" } else { "" }

Push-Location "$PSScriptRoot\healthcare"
try {
    Write-Host ""
    Write-Host "==> Step 1/3: dbt deps" -ForegroundColor Cyan
    uv run dbt deps $flags.Split(" ")

    Write-Host ""
    Write-Host "==> Step 2/3: dbt snapshot (SCD2)" -ForegroundColor Cyan
    uv run dbt snapshot $flags.Split(" ")

    Write-Host ""
    Write-Host "==> Step 3/3: dbt build (models + tests)" -ForegroundColor Cyan
    $buildArgs = ($flags + " " + $refresh + " " + $selector).Trim().Split(" ") | Where-Object { $_ -ne "" }
    uv run dbt build @buildArgs
}
finally {
    Pop-Location
}

Write-Host ""
Write-Host "Pipeline complete." -ForegroundColor Green
