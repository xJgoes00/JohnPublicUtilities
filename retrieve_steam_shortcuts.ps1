# Create-SteamStartMenuShortcuts.ps1
# Creates Steam game shortcuts in the Windows Start Menu (searchable)

 $ErrorActionPreference = 'SilentlyContinue'

# ------------------------------------------------------------
# Find Steam installation
# ------------------------------------------------------------
 $steamPaths = @(
    "${env:ProgramFiles(x86)}\Steam",
    "${env:ProgramFiles}\Steam",
    "$env:LOCALAPPDATA\Programs\Steam"
)

 $steamPath = $null

foreach ($p in $steamPaths) {
    if (Test-Path (Join-Path $p "steam.exe")) {
        $steamPath = $p
        break
    }
}

if (-not $steamPath) {
    Write-Host "Steam not found automatically." -ForegroundColor Red
    $steamPath = Read-Host "Enter Steam installation path"

    if (-not (Test-Path (Join-Path $steamPath "steam.exe"))) {
        Write-Host "Invalid Steam path." -ForegroundColor Red
        exit
    }
}

# ------------------------------------------------------------
# Discover Steam libraries
# ------------------------------------------------------------
 $libraryFolders = @()
 $libraryFolders += Join-Path $steamPath "steamapps"

 $libraryVdf = Join-Path $steamPath "steamapps\libraryfolders.vdf"

if (Test-Path $libraryVdf) {
    $content = Get-Content $libraryVdf -Raw -Encoding UTF8

    $regexMatches = [regex]::Matches($content, '"path"\s+"([^"]+)"')

    foreach ($m in $regexMatches) {
        $lib = $m.Groups[1].Value -replace '\\\\', '\'
        $apps = Join-Path $lib "steamapps"

        if ((Test-Path $apps) -and ($apps -notin $libraryFolders)) {
            $libraryFolders += $apps
        }
    }
}

# ------------------------------------------------------------
# Start Menu folder
# ------------------------------------------------------------
 $startMenuFolder = Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs\Steam"

New-Item -ItemType Directory -Force -Path $startMenuFolder | Out-Null

 $shell = New-Object -ComObject WScript.Shell

Write-Host ""
Write-Host "Steam found at: $steamPath" -ForegroundColor Green
Write-Host "Libraries:" -ForegroundColor Cyan
 $libraryFolders | ForEach-Object { Write-Host "  $_" }

Write-Host ""
Write-Host "Creating shortcuts..." -ForegroundColor Cyan

# ------------------------------------------------------------
# Process every installed game
# ------------------------------------------------------------
foreach ($lib in $libraryFolders) {

    Get-ChildItem "$lib\appmanifest_*.acf" -File | ForEach-Object {

        $manifest = Get-Content $_.FullName -Raw -Encoding UTF8

        $appid = [regex]::Match($manifest, '"appid"\s+"(\d+)"').Groups[1].Value
        $name  = [regex]::Match($manifest, '"name"\s+"([^"]+)"').Groups[1].Value
        
        # NEW: Extract the specific install directory for this game
        $installdir = [regex]::Match($manifest, '"installdir"\s+"([^"]+)"').Groups[1].Value

        if ([string]::IsNullOrWhiteSpace($appid) -or [string]::IsNullOrWhiteSpace($name)) {
            Write-Host "Skipping $($_.Name)" -ForegroundColor DarkYellow
            return
        }

        $cleanName = $name -replace '[\\/:*?"<>|]', '_'

        $shortcutPath = Join-Path $startMenuFolder "$cleanName.lnk"

        if (Test-Path $shortcutPath) {
            Write-Host "Exists: $cleanName"
            return
        }

        $shortcut = $shell.CreateShortcut($shortcutPath)

        $shortcut.TargetPath = Join-Path $steamPath "steam.exe"
        $shortcut.Arguments = "-applaunch $appid"
        $shortcut.WorkingDirectory = $steamPath

        # ----------------------------------------------------
        # Icon selection (FIXED)
        # ----------------------------------------------------

        $iconPath = Join-Path $steamPath "steam\games\$appid.ico"

        # If Steam doesn't have a cached icon, look inside the specific game's folder
        if (-not (Test-Path $iconPath)) {

            if (-not [string]::IsNullOrWhiteSpace($installdir)) {
                # Path: steamapps\common\GameName
                $gameFolder = Join-Path $lib "common\$installdir"

                if (Test-Path $gameFolder) {
                    # Search ONLY inside the specific game's folder
                    $exe = Get-ChildItem $gameFolder -Recurse -Filter *.exe -File |
                        Where-Object {
                            # Exclude common non-game executables (crash handlers, uninstallers, etc.)
                            $_.Name -notmatch '^(setup|install|unins|dx|launcher|redist|crash|handler|report|cef|helper|broker|streaming|node)'
                        } |
                        Select-Object -First 1

                    if ($exe) {
                        $iconPath = $exe.FullName
                    }
                }
            }
        }

        if (Test-Path $iconPath) {
            $shortcut.IconLocation = "$iconPath,0"
        }
        else {
            $shortcut.IconLocation = (Join-Path $steamPath "steam.exe") + ",0"
        }

        $shortcut.Save()

        Write-Host "[OK] $cleanName (AppID $appid)" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "Done!" -ForegroundColor Green
Write-Host "Shortcuts were created in:"
Write-Host $startMenuFolder -ForegroundColor Yellow
Write-Host ""
Write-Host "You should now be able to search for your games from the Windows Start Menu."

# ------------------------------------------------------------
# Optional desktop shortcuts
# ------------------------------------------------------------
 $createDesktop = Read-Host "Also copy shortcuts to Desktop? (y/N)"

if ($createDesktop -match '^[Yy]$') {

    $desktop = [Environment]::GetFolderPath("Desktop")

    Get-ChildItem "$startMenuFolder\*.lnk" | ForEach-Object {
        Copy-Item $_.FullName $desktop -Force
    }

    Write-Host "Desktop shortcuts created." -ForegroundColor Green
}