# ============================================================
#  WinClean 11 - Module 05: Bloatware Remover
#  Removes pre-installed junk apps from Windows 11
# ============================================================

#Requires -RunAsAdministrator

$LOG_FILE = "$env:TEMP\WinClean\winclean_log.txt"
function Write-Log  { param([string]$m,[string]$l="INFO"); "$(Get-Date -f 'HH:mm:ss') [$l] $m" | Out-File -Append $LOG_FILE -Encoding UTF8 }
function Write-Done { param([string]$m); Write-Host "  [✓] $m" -ForegroundColor Green; Write-Log $m "DONE" }
function Write-Skip { param([string]$m); Write-Host "  [~] $m" -ForegroundColor DarkGray }
function Write-Fail { param([string]$m); Write-Host "  [!] $m" -ForegroundColor Red; Write-Log $m "ERROR" }

# ── App categories ────────────────────────────────────────────
$bloatCategories = [ordered]@{

    "Microsoft Gaming Bloat (Xbox, Game Bar, etc.)" = @(
        "Microsoft.XboxApp",
        "Microsoft.XboxGameCallableUI",
        "Microsoft.XboxIdentityProvider",
        "Microsoft.XboxSpeechToTextOverlay",
        "Microsoft.XboxGamingOverlay",
        "Microsoft.XboxGameOverlay",
        "Microsoft.GamingApp"
    )

    "Microsoft Office / Productivity Trials" = @(
        "Microsoft.Office.OneNote",
        "Microsoft.MicrosoftOfficeHub",
        "Microsoft.OutlookForWindows",
        "Microsoft.Todos",
        "Microsoft.MicrosoftStickyNotes"
    )

    "Microsoft Entertainment & Media" = @(
        "Microsoft.ZuneMusic",
        "Microsoft.ZuneVideo",
        "Microsoft.WindowsCamera",
        "Microsoft.People",
        "Microsoft.Messaging",
        "Microsoft.WindowsMaps",
        "Microsoft.WindowsSoundRecorder",
        "Microsoft.MSPaint",
        "Clipchamp.Clipchamp"
    )

    "Microsoft News, Weather & Feeds" = @(
        "Microsoft.BingNews",
        "Microsoft.BingWeather",
        "Microsoft.BingFinance",
        "Microsoft.BingSports",
        "Microsoft.BingTranslator",
        "Microsoft.BingSearch"
    )

    "Skype & Communication" = @(
        "Microsoft.SkypeApp",
        "Microsoft.Teams",
        "MicrosoftTeams"
    )

    "Cortana (voice assistant)" = @(
        "Microsoft.549981C3F5F10"
    )

    "Third-Party OEM Bloat (common pre-installs)" = @(
        "SpotifyAB.SpotifyMusic",
        "Disney.37853D22215B2",
        "AmazonVideo.PrimeVideo",
        "Facebook.Facebook",
        "Facebook.InstagramApp",
        "TikTok.TikTok",
        "BytedancePte.Ltd.TikTok",
        "king.com.CandyCrushSaga",
        "king.com.CandyCrushSodaSaga",
        "king.com.FarmHeroesSaga",
        "Playtika.CaesarsSlotsFreeCasino",
        "WinZipComputing.WinZipUniversal"
    )

    "Microsoft Solitaire & Games" = @(
        "Microsoft.MicrosoftSolitaireCollection",
        "Microsoft.MicrosoftMahjong",
        "Microsoft.MicrosoftSudoku",
        "Microsoft.Minesweeper",
        "Microsoft.HiddenCity",
        "Microsoft.MixedReality.Portal"
    )

    "Feedback & Help Apps" = @(
        "Microsoft.WindowsFeedbackHub",
        "Microsoft.GetHelp",
        "Microsoft.Getstarted",
        "Microsoft.MicrosoftEdge.Stable"
    )

    "Power Automate & Dev Tools (if unused)" = @(
        "Microsoft.PowerAutomateDesktop",
        "Microsoft.WindowsTerminal",
        "Windows.DevHome"
    )

    "Mixed Reality & 3D" = @(
        "Microsoft.Microsoft3DViewer",
        "Microsoft.MixedReality.Portal",
        "Microsoft.Print3D"
    )

    "Wallet & Pay apps" = @(
        "Microsoft.Wallet",
        "Microsoft.Pay"
    )
}

# Apps that are safe to remove and well-known
$safeKeep = @(
    "Microsoft.WindowsStore",
    "Microsoft.WindowsCalculator",
    "Microsoft.Windows.Photos",
    "Microsoft.WindowsNotepad",
    "Microsoft.WindowsAlarms",
    "Microsoft.ScreenSketch"
)

# ── Header ────────────────────────────────────────────────────
Clear-Host
Write-Host ""
Write-Host "  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Red
Write-Host "    📦  BLOATWARE REMOVER" -ForegroundColor Red
Write-Host "  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Red
Write-Host ""
Write-Host "  ⚠  Removes pre-installed apps by category." -ForegroundColor Yellow
Write-Host "     Apps from Microsoft Store can be re-installed later." -ForegroundColor DarkYellow
Write-Host "     Windows Store itself is kept." -ForegroundColor DarkYellow
Write-Host ""

# ── Show what's actually installed first ──────────────────────
Write-Host "  Scanning for installed bloatware..." -ForegroundColor DarkCyan
$allBloat = $bloatCategories.Values | ForEach-Object { $_ } | Select-Object -Unique
$installed = @()
foreach ($app in $allBloat) {
    $pkg = Get-AppxPackage -Name $app -ErrorAction SilentlyContinue
    if ($pkg) { $installed += $app }
}
Write-Host "  Found $($installed.Count) bloatware packages installed." -ForegroundColor White
Write-Host ""

# ── Category selection ────────────────────────────────────────
Write-Host "  Select categories to remove:" -ForegroundColor White
Write-Host ""

$selectedCats = @{}
foreach ($cat in $bloatCategories.Keys) {
    $appsInCat = $bloatCategories[$cat] | Where-Object { $installed -contains $_ }
    if ($appsInCat.Count -eq 0) {
        Write-Host "  [—] $cat (none installed)" -ForegroundColor DarkGray
        $selectedCats[$cat] = $false
        continue
    }
    $ans = Read-Host "  ➤ Remove: $cat ($($appsInCat.Count) apps) ? [Y/n]"
    $selectedCats[$cat] = ($ans -eq '' -or $ans -match '^[Yy]')
}

# ── Remove selected ───────────────────────────────────────────
Write-Host ""
Write-Host "  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkRed
Write-Host "  Removing selected bloatware..." -ForegroundColor White
Write-Host "  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkRed
Write-Host ""

$removed = 0
$total = ($selectedCats.Values | Where-Object { $_ } | Measure-Object).Count

foreach ($cat in $selectedCats.Keys) {
    if (-not $selectedCats[$cat]) { continue }
    Write-Host "  ── $cat ──" -ForegroundColor DarkGray
    foreach ($app in $bloatCategories[$cat]) {
        if ($safeKeep -contains $app) { Write-Skip "Keeping $app (safe app)"; continue }
        Write-Progress -Activity "Removing Bloatware" -Status $app -PercentComplete (($removed / [math]::Max($installed.Count,1)) * 100)
        $pkg = Get-AppxPackage -Name $app -AllUsers -ErrorAction SilentlyContinue
        if ($pkg) {
            try {
                Remove-AppxPackage -Package $pkg.PackageFullName -AllUsers -ErrorAction SilentlyContinue
                # Also remove provisioned package so it doesn't reinstall
                $prov = Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -like "*$app*" }
                if ($prov) { Remove-AppxProvisionedPackage -Online -PackageName $prov.PackageName -ErrorAction SilentlyContinue | Out-Null }
                Write-Done "Removed $app"
                $removed++
            } catch {
                Write-Fail "Failed to remove $app : $_"
            }
        } else {
            Write-Skip "$app not installed"
        }
    }
    Write-Host ""
}
Write-Progress -Activity "Removing Bloatware" -Completed

# ── Also clean provisioned packages ──────────────────────────
Write-Host "  Cleaning provisioned (will-reinstall-on-new-user) packages..." -ForegroundColor DarkCyan
$provisioned = Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue
$provBloat = $provisioned | Where-Object { $allBloat -contains $_.DisplayName }
foreach ($pkg in $provBloat) {
    Remove-AppxProvisionedPackage -Online -PackageName $pkg.PackageName -ErrorAction SilentlyContinue | Out-Null
}
if ($provBloat.Count -gt 0) { Write-Done "Removed $($provBloat.Count) provisioned packages" }

# ── Summary ───────────────────────────────────────────────────
Write-Host "  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
Write-Host "  ✅ BLOATWARE REMOVER COMPLETE" -ForegroundColor Green
Write-Host "     Removed $removed apps." -ForegroundColor Yellow
Write-Host "  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
Write-Host ""
Write-Log "Bloatware Remover: removed $removed apps." "DONE"
