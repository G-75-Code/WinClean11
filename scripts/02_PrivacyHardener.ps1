# ============================================================
#  WinClean 11 - Module 02: Privacy Hardener
#  Disables Microsoft telemetry, tracking, spying features
# ============================================================

#Requires -RunAsAdministrator

$LOG_FILE = "$env:TEMP\WinClean\winclean_log.txt"
function Write-Log { param([string]$m,[string]$l="INFO"); "$(Get-Date -f 'HH:mm:ss') [$l] $m" | Out-File -Append $LOG_FILE -Encoding UTF8 }
function Write-Step  { param([string]$m); Write-Host "  [»] $m" -ForegroundColor Cyan }
function Write-Done  { param([string]$m); Write-Host "  [✓] $m" -ForegroundColor Green; Write-Log $m "DONE" }
function Write-Warn  { param([string]$m); Write-Host "  [~] $m" -ForegroundColor Yellow }
function Write-Fail  { param([string]$m); Write-Host "  [!] $m" -ForegroundColor Red; Write-Log $m "ERROR" }

# ── Registry helper ──────────────────────────────────────────
function Set-Reg {
    param([string]$Path, [string]$Name, $Value, [string]$Type = "DWord")
    try {
        if (-not (Test-Path $Path)) { New-Item -Path $Path -Force | Out-Null }
        Set-ItemProperty -Path $Path -Name $Name -Value $Value -Type $Type -Force -ErrorAction Stop
        return $true
    } catch {
        Write-Fail "Registry set failed: $Path\$Name -> $_"
        return $false
    }
}

# ── Privacy option definitions ────────────────────────────────
$privacyTasks = [ordered]@{

    "Advertising ID (targeted ads tracker)" = {
        Set-Reg "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo" "Enabled" 0
        Set-Reg "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo" "DisabledByGroupPolicy" 1
        Write-Done "Advertising ID disabled"
    }

    "Telemetry & Diagnostic Data (Required only)" = {
        Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" "AllowTelemetry" 0
        Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" "AllowTelemetry" 0
        Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" "MaxTelemetryAllowed" 0
        # Disable DiagTrack service (Connected User Experiences and Telemetry)
        Stop-Service -Name DiagTrack -Force -ErrorAction SilentlyContinue
        Set-Service  -Name DiagTrack -StartupType Disabled -ErrorAction SilentlyContinue
        Write-Done "Telemetry/DiagTrack disabled"
    }

    "Inking & Typing (keylogging) collection" = {
        Set-Reg "HKCU:\SOFTWARE\Microsoft\InputPersonalization" "RestrictImplicitInkCollection" 1
        Set-Reg "HKCU:\SOFTWARE\Microsoft\InputPersonalization" "RestrictImplicitTextCollection" 1
        Set-Reg "HKCU:\SOFTWARE\Microsoft\InputPersonalization\TrainedDataStore" "HarvestContacts" 0
        Set-Reg "HKCU:\SOFTWARE\Microsoft\Personalization\Settings" "AcceptedPrivacyPolicy" 0
        Write-Done "Inking & typing data collection disabled"
    }

    "Activity History / Timeline" = {
        Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" "EnableActivityFeed" 0
        Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" "PublishUserActivities" 0
        Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" "UploadUserActivities" 0
        # Clear existing activity history
        $actPath = "$env:LOCALAPPDATA\ConnectedDevicesPlatform"
        if (Test-Path $actPath) {
            Get-ChildItem $actPath -Recurse -Filter "ActivitiesCache.db*" |
                Remove-Item -Force -ErrorAction SilentlyContinue
        }
        Write-Done "Activity history disabled & cleared"
    }

    "Location Tracking" = {
        Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location" "Value" "Deny" "String"
        Set-Reg "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location" "Value" "Deny" "String"
        Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors" "DisableLocation" 1
        Write-Done "Location tracking disabled"
    }

    "Tailored Experiences (using your data for ads/tips)" = {
        Set-Reg "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Privacy" "TailoredExperiencesWithDiagnosticDataEnabled" 0
        Set-Reg "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\CloudExperienceHost" "ShouldOfferRoamingProfileCompletion" 0
        Write-Done "Tailored experiences disabled"
    }

    "App Launch Tracking" = {
        Set-Reg "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "Start_TrackProgs" 0
        Write-Done "App launch tracking disabled"
    }

    "Suggested Content in Settings" = {
        Set-Reg "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "SubscribedContent-338393Enabled" 0
        Set-Reg "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "SubscribedContent-353694Enabled" 0
        Set-Reg "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "SubscribedContent-353696Enabled" 0
        Set-Reg "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "SystemPaneSuggestionsEnabled" 0
        Set-Reg "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "SoftLandingEnabled" 0
        Write-Done "Suggested content / ads in Settings disabled"
    }

    "Lock Screen Ads & Spotlight tracking" = {
        Set-Reg "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "RotatingLockScreenEnabled" 0
        Set-Reg "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "RotatingLockScreenOverlayEnabled" 0
        Set-Reg "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "ContentDeliveryAllowed" 0
        Write-Done "Lock screen ads disabled"
    }

    "Start Menu Suggestions & Promoted Apps" = {
        Set-Reg "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "OemPreInstalledAppsEnabled" 0
        Set-Reg "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "PreInstalledAppsEnabled" 0
        Set-Reg "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "PreInstalledAppsEverEnabled" 0
        Set-Reg "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "SilentInstalledAppsEnabled" 0
        Set-Reg "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "SubscribedContent-314559Enabled" 0
        Set-Reg "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "SubscribedContent-314563Enabled" 0
        Write-Done "Start menu suggestions & promoted apps disabled"
    }

    "Widgets & News Feed (MSN/Bing tracking)" = {
        Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Dsh" "AllowNewsAndInterests" 0
        Set-Reg "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Feeds" "ShellFeedsTaskbarViewMode" 2
        Write-Done "Widgets & news feed disabled"
    }

    "Search Highlights & Bing Web Search in Start" = {
        Set-Reg "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\SearchSettings" "IsDynamicSearchBoxEnabled" 0
        Set-Reg "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" "BingSearchEnabled" 0
        Set-Reg "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" "CortanaConsent" 0
        Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" "DisableWebSearch" 1
        Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" "ConnectedSearchUseWeb" 0
        Write-Done "Search highlights & Bing integration disabled"
    }

    "Send Error Reports to Microsoft" = {
        Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows\Windows Error Reporting" "Disabled" 1
        Set-Reg "HKCU:\SOFTWARE\Microsoft\Windows\Windows Error Reporting" "Disabled" 1
        Stop-Service -Name WerSvc -Force -ErrorAction SilentlyContinue
        Set-Service  -Name WerSvc -StartupType Disabled -ErrorAction SilentlyContinue
        Write-Done "Error reporting disabled"
    }

    "Microphone access for ALL apps" = {
        Set-Reg "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\microphone" "Value" "Deny" "String"
        Write-Warn "Microphone blocked for all apps. Re-enable in Settings > Privacy > Microphone if needed."
        Write-Done "Microphone access restricted"
    }

    "Camera access for ALL apps" = {
        Set-Reg "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\webcam" "Value" "Deny" "String"
        Write-Warn "Camera blocked for all apps. Re-enable in Settings > Privacy > Camera if needed."
        Write-Done "Camera access restricted"
    }

    "Online Speech Recognition" = {
        Set-Reg "HKCU:\SOFTWARE\Microsoft\Speech_OneCore\Settings\OnlineSpeechPrivacy" "HasAccepted" 0
        Write-Done "Online speech recognition disabled"
    }

    "Windows Recall (AI screenshot feature)" = {
        Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" "DisableAIDataAnalysis" 1
        Set-Reg "HKCU:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" "DisableAIDataAnalysis" 1
        # Disable the Recall scheduled task if it exists
        Get-ScheduledTask -TaskName "*Recall*" -ErrorAction SilentlyContinue | Disable-ScheduledTask -ErrorAction SilentlyContinue
        Write-Done "Windows Recall disabled"
    }

    "Telemetry Scheduled Tasks (background data uploads)" = {
        $tasks = @(
            "\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser",
            "\Microsoft\Windows\Application Experience\ProgramDataUpdater",
            "\Microsoft\Windows\Application Experience\StartupAppTask",
            "\Microsoft\Windows\Autochk\Proxy",
            "\Microsoft\Windows\Customer Experience Improvement Program\Consolidator",
            "\Microsoft\Windows\Customer Experience Improvement Program\KernelCeipTask",
            "\Microsoft\Windows\Customer Experience Improvement Program\UsbCeip",
            "\Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector",
            "\Microsoft\Windows\Feedback\Siuf\DmClient",
            "\Microsoft\Windows\Feedback\Siuf\DmClientOnScenarioDownload"
        )
        foreach ($t in $tasks) {
            Disable-ScheduledTask -TaskPath (Split-Path $t -Parent) -TaskName (Split-Path $t -Leaf) -ErrorAction SilentlyContinue | Out-Null
        }
        Write-Done "Telemetry scheduled tasks disabled ($($tasks.Count) tasks)"
    }

    "Delivery Optimization (P2P upload of Windows updates to strangers)" = {
        Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" "DODownloadMode" 0
        Write-Done "Delivery Optimization P2P disabled (only local network allowed)"
    }

    "Microsoft Consumer Experience / Cloud Content" = {
        Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" "DisableSoftLanding" 1
        Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" "DisableWindowsConsumerFeatures" 1
        Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" "DisableCloudOptimizedContent" 1
        Write-Done "Microsoft consumer experience features disabled"
    }
}

# ── Header ───────────────────────────────────────────────────
Clear-Host
Write-Host ""
Write-Host "  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Magenta
Write-Host "    👁️  PRIVACY HARDENER" -ForegroundColor Magenta
Write-Host "  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Magenta
Write-Host ""
Write-Host "  ⚠  These settings are ON by default in Windows 11." -ForegroundColor Yellow
Write-Host "     This script turns them OFF. You can re-enable" -ForegroundColor DarkYellow
Write-Host "     anything in Settings > Privacy & Security." -ForegroundColor DarkYellow
Write-Host ""

# ── Ask user what to disable ─────────────────────────────────
Write-Host "  Select what to disable (Enter = Yes by default):" -ForegroundColor White
Write-Host ""

$selected = @{}
foreach ($task in $privacyTasks.Keys) {
    $ans = Read-Host "  ➤ Disable: $task ? [Y/n]"
    $selected[$task] = ($ans -eq '' -or $ans -match '^[Yy]')
}

# ── Run selected ──────────────────────────────────────────────
Write-Host ""
Write-Host "  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkMagenta
Write-Host "  Applying privacy settings..." -ForegroundColor White
Write-Host "  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkMagenta
Write-Host ""

$i = 0
foreach ($task in $privacyTasks.Keys) {
    if ($selected[$task]) {
        $i++
        Write-Progress -Activity "WinClean - Privacy Hardener" -Status $task -PercentComplete (($i / $privacyTasks.Count) * 100)
        & $privacyTasks[$task]
        Write-Host ""
    }
}
Write-Progress -Activity "WinClean - Privacy Hardener" -Completed

# ── Summary ───────────────────────────────────────────────────
Write-Host "  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
Write-Host "  ✅ PRIVACY HARDENER COMPLETE" -ForegroundColor Green
Write-Host "     $i privacy settings applied." -ForegroundColor Yellow
Write-Host "  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
Write-Host ""
Write-Log "Privacy Hardener complete. $i settings applied." "DONE"
