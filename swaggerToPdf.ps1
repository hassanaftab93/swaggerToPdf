# ============================================================
#  swaggerToPdf.ps1
#  Converts a Swagger/OpenAPI JSON spec to a PDF document
#  Usage: .\swaggerToPdf.ps1 [-SwaggerUrl <url>] [-OutputPdf <filename>]
# ============================================================

[CmdletBinding()]
param (
    [string]$SwaggerUrl = "https://azdev-bffweb.reeft.com/swagger/v1/swagger.json",
    [string]$OutputPdf  = "api-docs.pdf"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ── Colours ──────────────────────────────────────────────────
function Write-Info    ($msg) { Write-Host "  [INFO]  $msg" -ForegroundColor Cyan }
function Write-Success ($msg) { Write-Host "  [OK]    $msg" -ForegroundColor Green }
function Write-Warn    ($msg) { Write-Host "  [WARN]  $msg" -ForegroundColor Yellow }
function Write-Fail    ($msg) { Write-Host "  [ERROR] $msg" -ForegroundColor Red; exit 1 }

# ── Banner ────────────────────────────────────────────────────
function Print-Banner {
    Write-Host ""
    Write-Host "  ╔══════════════════════════════════════╗" -ForegroundColor Magenta
    Write-Host "  ║       Swagger → PDF Generator        ║" -ForegroundColor Magenta
    Write-Host "  ╚══════════════════════════════════════╝" -ForegroundColor Magenta
    Write-Host ""
}

# ── Cleanup ───────────────────────────────────────────────────
function Invoke-Cleanup {
    Write-Info "Cleaning up temporary files..."
    $filesToRemove = @("swagger.json", "index.html", ".openapi-generator-ignore")
    foreach ($file in $filesToRemove) {
        if (Test-Path $file) { Remove-Item $file -Force }
    }
    if (Test-Path ".openapi-generator") {
        Remove-Item ".openapi-generator" -Recurse -Force
    }
    Write-Success "Cleanup complete."
}

# ── Dependency Check ──────────────────────────────────────────
function Check-Dependencies {
    Write-Info "Checking dependencies..."

    # Check curl (use curl.exe explicitly to avoid alias conflict with Invoke-WebRequest)
    if (-not (Get-Command "curl.exe" -ErrorAction SilentlyContinue)) {
        Write-Fail "'curl' is not installed or not in PATH. Install it from https://curl.se/windows/"
    }

    # Check docker
    if (-not (Get-Command "docker" -ErrorAction SilentlyContinue)) {
        Write-Fail "'docker' is not installed or not in PATH. Install Docker Desktop from https://www.docker.com/products/docker-desktop/"
    }

    # Check docker daemon is running
    $dockerInfo = docker info 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Fail "Docker daemon is not running. Please start Docker Desktop."
    }

    Write-Success "All dependencies found."
}

# ── Step 1: Download Swagger JSON ─────────────────────────────
function Get-SwaggerJson {
    Write-Host ""
    Write-Info "Step 1/3 - Downloading Swagger spec from:"
    Write-Host "           $SwaggerUrl" -ForegroundColor Cyan

    curl.exe -sf --max-time 30 $SwaggerUrl -o "swagger.json"

    if ($LASTEXITCODE -ne 0) {
        Write-Fail "Failed to download Swagger JSON. Check the URL and network access."
    }

    if (-not (Test-Path "swagger.json") -or (Get-Item "swagger.json").Length -eq 0) {
        Write-Fail "Downloaded file is empty. The URL may not return a valid JSON spec."
    }

    Write-Success "Swagger JSON saved -> swagger.json"
}

# ── Step 2: Generate HTML from Swagger JSON ───────────────────
function New-SwaggerHtml {
    Write-Host ""
    Write-Info "Step 2/3 - Generating HTML documentation..."

    $workDir = (Get-Location).Path -replace '\\', '/'
    # Handle Windows drive letters for Docker volume mount (e.g. C:/... -> /c/...)
    if ($workDir -match '^([A-Za-z]):(.*)') {
        $workDir = "/$($Matches[1].ToLower())$($Matches[2])"
    }

    docker run --rm `
        -v "${workDir}:/local" `
        openapitools/openapi-generator-cli generate `
        -i /local/swagger.json `
        -g html `
        -o /local `
        --skip-validate-spec 2>&1 | Where-Object { $_ -match "(ERROR|WARN|Successfully)" }

    if (-not (Test-Path "index.html")) {
        Write-Fail "HTML generation failed. 'index.html' not found."
    }

    Write-Success "HTML documentation generated -> index.html"
}

# ── Step 3: Convert HTML to PDF ───────────────────────────────
function New-ApiPdf {
    Write-Host ""
    Write-Info "Step 3/3 - Converting HTML to PDF..."

    $workDir = (Get-Location).Path -replace '\\', '/'
    if ($workDir -match '^([A-Za-z]):(.*)') {
        $workDir = "/$($Matches[1].ToLower())$($Matches[2])"
    }

    docker run --rm `
        -v "${workDir}:/output" `
        zenika/alpine-chrome:with-node `
        chromium-browser --headless --no-sandbox `
        --print-to-pdf="/output/$OutputPdf" `
        "file:///output/index.html" 2>&1 | Where-Object { $_.Trim() -ne "" }

    if (-not (Test-Path $OutputPdf)) {
        Write-Fail "PDF generation failed. Output file '$OutputPdf' not found."
    }

    Write-Success "PDF generated -> $((Get-Location).Path)\$OutputPdf"
}

# ── Main ──────────────────────────────────────────────────────
Print-Banner
Check-Dependencies
Get-SwaggerJson
New-SwaggerHtml
New-ApiPdf

Write-Host ""
Invoke-Cleanup

Write-Host ""
Write-Host "  ✔ Done! Your API documentation is ready:" -ForegroundColor Green
Write-Host "  📄 $((Get-Location).Path)\$OutputPdf" -ForegroundColor White
Write-Host ""