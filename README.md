# WinClean 11

**Windows 11 PowerShell Cleanup & Security Suite**

A modular PowerShell script suite that lets you clean, harden, and optimize Windows 11 with a single one-liner command. No installation required — everything runs directly in PowerShell as Administrator.

---

## Quick Start

Open **PowerShell as Administrator** and paste this:

```powershell
& ([scriptblock]::Create((irm "https://raw.githubusercontent.com/G-75-Code/WinClean11/main/bootstrap.ps1")))
```

That's it. The interactive menu will appear and walk you through everything.

---

## Modules

### 1. Junk Cleaner
Deletes temp files, caches, and system junk to free disk space.
- User & system temp files, Prefetch, Recycle Bin
- Windows Update cache, browser caches (Edge, Chrome, Firefox, Brave)
- Thumbnail cache, crash dumps, Windows Error Reporting
- DirectX shader cache, Delivery Optimization cache, font cache
- Windows.old folder, hibernation file (with warning)
- DISM component store cleanup
- Shows total MB freed at the end

### 2. Privacy Hardener
Disables Microsoft telemetry, tracking, and data collection.
- Advertising ID, telemetry & DiagTrack service
- Inking & typing keylogging, activity history
- Location tracking, tailored experiences, app launch tracking
- Suggested content, lock screen ads, Start menu promoted apps
- Widgets & news feed, search highlights & Bing in Start
- Error reporting, microphone/camera access for all apps
- Online speech recognition, Windows Recall (AI screenshots)
- 10 telemetry scheduled tasks, Delivery Optimization P2P
- Microsoft consumer experience / cloud content

### 3. Security Booster
Hardens Windows Defender, Firewall, UAC, and disables common attack vectors.
- Windows Defender fully enabled & hardened (cloud protection, network protection)
- Controlled Folder Access (anti-ransomware), PUA protection
- Firewall on all profiles with inbound blocked by default
- UAC set to Always Notify, Tamper Protection
- AutoPlay & AutoRun disabled, Exploit Protection (DEP/ASLR)
- SMBv1 disabled, Remote Desktop & Remote Registry disabled
- LLMNR disabled, Secure Boot check
- Defender signature update & Quick Scan

### 4. Speed Optimizer
Speeds up boot, frees RAM, and reduces background noise.
- Disable bloat startup entries, Widgets background service
- Visual effects set to Best Performance, transparency off
- Fast Startup enabled, SysMain/Superfetch disabled on SSDs
- Xbox Game Bar & DVR disabled, background app access off
- Cortana disabled, High Performance power plan
- Search Indexing disabled on SSDs, Windows tips off
- Hardware GPU Scheduling enabled
- DNS set to Cloudflare (1.1.1.1 / 1.0.0.1)

### 5. Bloatware Remover
Removes pre-installed junk apps by category.
- Microsoft Gaming (Xbox apps, Game Bar)
- Office/Productivity trials (OneNote, OfficeHub, Outlook, ToDo)
- Entertainment (Zune, Camera, Maps, Clipchamp)
- News/Weather (Bing apps)
- Communication (Skype, Teams)
- Cortana, third-party OEM bloat (Spotify, Disney+, TikTok, Candy Crush)
- Games (Solitaire, Mahjong, etc.)
- Feedback apps, Mixed Reality & 3D
- Also removes provisioned packages so apps don't reinstall for new users

---

## Features

- **Nothing is forced** — you pick every action with Y/n prompts
- **Full logging** — every change is logged to `%TEMP%\WinClean\winclean_log.txt`
- **View log** from the main menu to see what was changed
- **Run Everything** option to apply all modules in sequence
- **Self-contained modules** — each script can run standalone
- **No installation** — scripts run from memory, nothing is permanently installed

---

## Screenshots

> *Screenshots coming soon*

---

## File Structure

```
WinClean11/
├── bootstrap.ps1              <- Entry point (users run this)
├── scripts/
│   ├── LAUNCH.ps1             <- Main interactive menu
│   ├── 01_JunkCleaner.ps1
│   ├── 02_PrivacyHardener.ps1
│   ├── 03_SecurityBooster.ps1
│   ├── 04_SpeedOptimizer.ps1
│   └── 05_BloatwareRemover.ps1
└── README.md
```

---

## Requirements

- Windows 11 (Windows 10 will prompt a warning but still works)
- PowerShell 5.1 or later
- Run as Administrator
- Internet connection (for initial download only)

---

## Safety & Disclaimer

> **Use at your own risk.** This suite modifies Windows registry settings, disables services, and removes apps. While every change is logged and can be reversed, always create a System Restore Point before running.

All changes are reversible:
- Registry settings can be changed back via `regedit` or Settings
- Removed apps can be reinstalled from the Microsoft Store
- Disabled services can be re-enabled via `services.msc`

This project is not affiliated with Microsoft. All trademarks belong to their respective owners.

---

## License

MIT License - free to use, modify, and distribute.
