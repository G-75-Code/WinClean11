# ============================================================
#  WinClean 11 - Bootstrap Entry Point
#  User runs:
#  & ([scriptblock]::Create((irm "https://raw.githubusercontent.com/G-75-Code/WinClean11/main/bootstrap.ps1")))
# ============================================================

# Check admin
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host ""
    Write-Host "  [!] Please run PowerShell as Administrator!" -ForegroundColor Red
    Write-Host "      Right-click PowerShell > Run as administrator" -ForegroundColor Yellow
    Write-Host ""
    Read-Host "  Press Enter to exit"
    exit
}

# Check execution policy and fix if needed
$policy = Get-ExecutionPolicy
if ($policy -eq "Restricted") {
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process -Force
}

# ── Configuration ──────────────────────────────────────────────────────────
$LAUNCHER_URL = "https://raw.githubusercontent.com/G-75-Code/WinClean11/main/scripts/LAUNCH.ps1"
$TEMP_DIR     = "$env:TEMP\WinClean"

# Create temp dir
if (-not (Test-Path $TEMP_DIR)) { New-Item -ItemType Directory -Path $TEMP_DIR -Force | Out-Null }

# Download & run LAUNCH.ps1
Write-Host ""
Write-Host "  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "         WinClean 11 — Downloading...               " -ForegroundColor White
Write-Host "  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host ""
try {
    $launchPath = "$TEMP_DIR\LAUNCH.ps1"
    $webClient = New-Object System.Net.WebClient
    $webClient.Encoding = [System.Text.Encoding]::UTF8
    $scriptContent = $webClient.DownloadString($LAUNCHER_URL)
    [System.IO.File]::WriteAllText($launchPath, $scriptContent, [System.Text.Encoding]::UTF8)
    $webClient.Dispose()
    Write-Host "  [+] Launcher downloaded successfully." -ForegroundColor Green
    & $launchPath
} catch {
    Write-Host "  [!] Download failed: $_" -ForegroundColor Red
    Write-Host "  Check your internet connection or the script URL." -ForegroundColor DarkYellow
}
