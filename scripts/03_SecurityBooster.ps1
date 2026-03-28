# ============================================================
#  WinClean 11 - Module 03: Security Booster
#  Hardens Defender, Firewall, UAC, encryption settings
# ============================================================

#Requires -RunAsAdministrator

$LOG_FILE = "$env:TEMP\WinClean\winclean_log.txt"
function Write-Log  { param([string]$m,[string]$l="INFO"); "$(Get-Date -f 'HH:mm:ss') [$l] $m" | Out-File -Append $LOG_FILE -Encoding UTF8 }
function Write-Step { param([string]$m); Write-Host "  [»] $m" -ForegroundColor Cyan }
function Write-Done { param([string]$m); Write-Host "  [✓] $m" -ForegroundColor Green; Write-Log $m "DONE" }
function Write-Warn { param([string]$m); Write-Host "  [~] $m" -ForegroundColor Yellow }
function Write-Fail { param([string]$m); Write-Host "  [!] $m" -ForegroundColor Red; Write-Log $m "ERROR" }

function Set-Reg {
    param([string]$Path,[string]$Name,$Value,[string]$Type="DWord")
    try {
        if (-not (Test-Path $Path)) { New-Item -Path $Path -Force | Out-Null }
        Set-ItemProperty -Path $Path -Name $Name -Value $Value -Type $Type -Force
        return $true
    } catch { Write-Fail "Reg: $Path\$Name -> $_"; return $false }
}

$secTasks = [ordered]@{

    "Ensure Windows Defender Antivirus is fully ON" = {
        try {
            Set-MpPreference -DisableRealtimeMonitoring $false -ErrorAction SilentlyContinue
            Set-MpPreference -DisableBehaviorMonitoring $false -ErrorAction SilentlyContinue
            Set-MpPreference -DisableBlockAtFirstSeen $false -ErrorAction SilentlyContinue
            Set-MpPreference -DisableIOAVProtection $false -ErrorAction SilentlyContinue
            Set-MpPreference -DisablePrivacyMode $false -ErrorAction SilentlyContinue
            Set-MpPreference -SignatureDisableUpdateOnStartupWithoutEngine $false -ErrorAction SilentlyContinue
            Set-MpPreference -DisableArchiveScanning $false -ErrorAction SilentlyContinue
            Set-MpPreference -DisableIntrusionPreventionSystem $false -ErrorAction SilentlyContinue
            Set-MpPreference -DisableScriptScanning $false -ErrorAction SilentlyContinue
            Set-MpPreference -MAPSReporting Advanced -ErrorAction SilentlyContinue
            Set-MpPreference -SubmitSamplesConsent 1 -ErrorAction SilentlyContinue
            Set-MpPreference -CloudBlockLevel High -ErrorAction SilentlyContinue
            Set-MpPreference -EnableNetworkProtection Enabled -ErrorAction SilentlyContinue
            Write-Done "Windows Defender fully enabled and hardened"
        } catch { Write-Fail "Defender setup failed: $_" }
    }

    "Enable Ransomware Protection (Controlled Folder Access)" = {
        try {
            Set-MpPreference -EnableControlledFolderAccess Enabled -ErrorAction SilentlyContinue
            Write-Done "Controlled Folder Access (anti-ransomware) enabled"
            Write-Warn "If apps are blocked, add them via Windows Security > Ransomware protection > Allow an app"
        } catch { Write-Fail "Controlled folder access: $_" }
    }

    "Enable PUA/PUP Protection (Unwanted Software)" = {
        try {
            Set-MpPreference -PUAProtection Enabled -ErrorAction SilentlyContinue
            Write-Done "Potentially Unwanted App protection enabled"
        } catch { Write-Fail "PUA protection: $_" }
    }

    "Enable Windows Firewall on all profiles" = {
        try {
            Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled True -ErrorAction SilentlyContinue
            # Block inbound by default, allow outbound
            Set-NetFirewallProfile -Profile Domain,Public,Private -DefaultInboundAction Block -DefaultOutboundAction Allow -ErrorAction SilentlyContinue
            Write-Done "Firewall enabled (Domain/Public/Private) - Inbound blocked by default"
        } catch { Write-Fail "Firewall: $_" }
    }

    "Set UAC to highest level (Always Notify)" = {
        Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" "ConsentPromptBehaviorAdmin" 2
        Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" "ConsentPromptBehaviorUser" 3
        Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" "EnableLUA" 1
        Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" "PromptOnSecureDesktop" 1
        Write-Done "UAC set to Always Notify (highest)"
    }

    "Enable Tamper Protection (prevent AV being turned off)" = {
        Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows Defender\Features" "TamperProtection" 5
        Write-Done "Tamper Protection enabled"
    }

    "Disable AutoPlay (common malware vector)" = {
        Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" "NoDriveTypeAutoRun" 255
        Set-Reg "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers" "DisableAutoplay" 1
        Write-Done "AutoPlay disabled for all drives"
    }

    "Disable AutoRun (USB/CD malware)" = {
        Set-Reg "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" "NoDriveTypeAutoRun" 255
        Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer" "NoAutorun" 1
        Write-Done "AutoRun disabled"
    }

    "Enable Exploit Protection (DEP & ASLR)" = {
        try {
            # Enable DEP for all processes
            $null = cmd /c "bcdedit /set nx AlwaysOn 2>&1"
            # Enable ASLR via PowerShell
            Set-ProcessMitigation -System -Enable ASLR,ForceRelocateImages,HighEntropy -ErrorAction SilentlyContinue
            Write-Done "Exploit protection (DEP/ASLR) hardened"
        } catch { Write-Warn "Exploit protection partially applied" }
    }

    "Disable SMBv1 (major ransomware attack vector - WannaCry etc.)" = {
        try {
            Disable-WindowsOptionalFeature -Online -FeatureName SMB1Protocol -NoRestart -ErrorAction SilentlyContinue | Out-Null
            Set-SmbServerConfiguration -EnableSMB1Protocol $false -Force -ErrorAction SilentlyContinue
            Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" "SMB1" 0
            Write-Done "SMBv1 disabled (protects against WannaCry-style attacks)"
        } catch { Write-Fail "SMBv1 disable: $_" }
    }

    "Disable Remote Desktop (if not needed)" = {
        Write-Warn "Disabling RDP. Only do this if you don't use Remote Desktop."
        Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server" "fDenyTSConnections" 1
        Set-NetFirewallRule -DisplayGroup "Remote Desktop" -Enabled False -ErrorAction SilentlyContinue
        Write-Done "Remote Desktop disabled"
    }

    "Disable Remote Registry service" = {
        Stop-Service -Name RemoteRegistry -Force -ErrorAction SilentlyContinue
        Set-Service  -Name RemoteRegistry -StartupType Disabled -ErrorAction SilentlyContinue
        Write-Done "Remote Registry service disabled"
    }

    "Disable LLMNR (local network spoofing attack vector)" = {
        Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient" "EnableMulticast" 0
        Write-Done "LLMNR disabled (prevents local network spoofing)"
    }

    "Enable Secure Boot check (alert if disabled)" = {
        $sb = Confirm-SecureBootUEFI -ErrorAction SilentlyContinue
        if ($sb) { Write-Done "Secure Boot is enabled ✓" }
        else { Write-Warn "Secure Boot is DISABLED — enable it in your BIOS/UEFI settings" }
    }

    "Update Windows Defender Signatures now" = {
        Write-Step "Updating Defender signatures..."
        try {
            Update-MpSignature -ErrorAction Stop
            Write-Done "Defender signatures updated"
        } catch { Write-Fail "Signature update failed: $_" }
    }

    "Run a Quick Scan with Windows Defender" = {
        Write-Step "Starting quick scan (runs in background)..."
        try {
            Start-MpScan -ScanType QuickScan -ErrorAction Stop
            Write-Done "Quick scan initiated"
        } catch { Write-Fail "Scan failed: $_" }
    }
}

# ── Header ────────────────────────────────────────────────────
Clear-Host
Write-Host ""
Write-Host "  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
Write-Host "    🔒  SECURITY BOOSTER" -ForegroundColor Yellow
Write-Host "  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
Write-Host ""
Write-Host "  Hardens Windows Defender, Firewall, UAC, and" -ForegroundColor White
Write-Host "  disables common attack vectors." -ForegroundColor White
Write-Host ""

# ── Ask user ──────────────────────────────────────────────────
Write-Host "  Select security hardening to apply:" -ForegroundColor White
Write-Host ""

$selected = @{}
foreach ($task in $secTasks.Keys) {
    $ans = Read-Host "  ➤ $task ? [Y/n]"
    $selected[$task] = ($ans -eq '' -or $ans -match '^[Yy]')
}

# ── Apply ─────────────────────────────────────────────────────
Write-Host ""
Write-Host "  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkYellow
Write-Host "  Applying security settings..." -ForegroundColor White
Write-Host "  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkYellow
Write-Host ""

$i = 0
foreach ($task in $secTasks.Keys) {
    if ($selected[$task]) {
        $i++
        Write-Progress -Activity "WinClean - Security Booster" -Status $task -PercentComplete (($i / $secTasks.Count)*100)
        & $secTasks[$task]
        Write-Host ""
    }
}
Write-Progress -Activity "WinClean - Security Booster" -Completed

Write-Host "  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
Write-Host "  ✅ SECURITY BOOSTER COMPLETE" -ForegroundColor Green
Write-Host "     $i security settings applied." -ForegroundColor Yellow
Write-Host "  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
Write-Host ""
Write-Log "Security Booster complete. $i settings applied." "DONE"
