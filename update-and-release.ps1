# Script pour mettre à jour le repo et créer la release v3.3.4
# Utilisation: .\update-and-release.ps1

$repoOwner = "krvntzkl"
$repoName = "valorant-rpc"
$version = "3.3.4"
$exePath = "dist\valorant-rpc.exe"
$releaseNotes = @"
## Version 3.3.4 - Bug Fixes and Improvements

### Bug Fixes
- Fixed KeyError 'sessionLoopState': added checks to handle the absence of this key in presence data
- Fixed KeyError 'partyAccessibility': replaced direct accesses with .get() and default values in build_party_state()
- Fixed AttributeError 'systray': added hasattr() checks before calling systray.exit() in startup.py
- Fixed small_text error: ensured small_text is at least 2 characters long before sending to Discord
- Fixed SyntaxWarning: corrected invalid escape sequences in the ASCII art in main.py
- Fixed session loops: Game_Session and Range_Session no longer depend on sessionLoopState and now directly verify the game's state
- Fixed indentation errors in startup.py and presence.py

### Improvements
- Improved menu/in-game detection: coregame_fetch_player() is now checked to detect the in-game state before assuming the menu
- Improved build.bat with error handling, informative messages, and use of the .spec file
- Immediate presence update: ingame.presence() now updates presence instantly with basic information before the detailed loop
- KeyError protection: use of .get() with default values across all presence functions (default, queue, away, custom_setup)
- Added default values: added defaults for partyAccessibility, partySize, maxPartySize, accountLevel, partyId, etc.
- Created missing init.py files in all packages for PyInstaller compatibility
- Configured valorant-rpc.spec with automatic submodule collection, asset inclusion, and collection of pystray/PIL

### Content Updates
- Updated version to 3.3.4 in app_config.py and version.py
- Updated GitHub URLs to the fork krvntzkl/valorant-rpc in version_checker.py and startup.py
- Added support for agents: Harbour, Gekko, Deadlock, Iso, Clove, Vyse, Tejo, Waylay and Veto
- Added support for maps: Abyss and Corrode

### Installation
Download `valorant-rpc.exe` from the assets below and run it.
"@

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Mise a jour et release v$version" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Vérifier que Git est installé
try {
    $gitVersion = git --version 2>$null
    Write-Host "Git detecte" -ForegroundColor Green
} catch {
    Write-Host "ERREUR: Git n'est pas installe!" -ForegroundColor Red
    exit 1
}

# Vérifier que l'exe existe
if (-not (Test-Path $exePath)) {
    Write-Host "ERREUR: $exePath introuvable!" -ForegroundColor Red
    Write-Host "Assurez-vous que le fichier est compile." -ForegroundColor Yellow
    exit 1
}

Write-Host "Fichier exe trouve: $exePath ($((Get-Item $exePath).Length / 1MB) MB)" -ForegroundColor Green
Write-Host ""

# Vérifier l'état du repo
Write-Host "Verification de l'etat du repository..." -ForegroundColor Cyan
$status = git status --porcelain 2>$null

if (-not $status) {
    Write-Host "Aucun changement detecte. Voulez-vous continuer quand meme?" -ForegroundColor Yellow
    $response = Read-Host "(o/n)"
    if ($response -ne "o") {
        exit 0
    }
} else {
    Write-Host "Changements detectes:" -ForegroundColor Green
    git status --short
    Write-Host ""
}

# Vérifier si on est sur la bonne branche
$currentBranch = git branch --show-current 2>$null
if (-not $currentBranch) {
    Write-Host "Initialisation du repository Git..." -ForegroundColor Yellow
    git init
    git branch -M main
    $currentBranch = "main"
}

Write-Host "Branche actuelle: $currentBranch" -ForegroundColor Green
Write-Host ""

# Vérifier le remote
$remoteUrl = git remote get-url origin 2>$null
if (-not $remoteUrl) {
    Write-Host "Aucun remote 'origin' trouve." -ForegroundColor Yellow
    $remoteUrl = "https://github.com/$repoOwner/$repoName.git"
    Write-Host "Ajout du remote: $remoteUrl" -ForegroundColor Green
    git remote add origin $remoteUrl
} else {
    Write-Host "Remote trouve: $remoteUrl" -ForegroundColor Green
}

Write-Host ""

# Étape 1: Commit et push des fichiers modifiés
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "ETAPE 1: Commit et push des fichiers" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$response = Read-Host "Voulez-vous committer et pusher les changements? (o/n)"
if ($response -eq "o") {
    Write-Host "Ajout des fichiers..." -ForegroundColor Green
    git add .
    
    # Vérifier s'il y a des changements à committer
    $changes = git diff --cached --name-only 2>$null
    if ($changes) {
        Write-Host "Creation du commit..." -ForegroundColor Green
        git commit -m "Update to version $version - Bug fixes and improvements"
        
        Write-Host "Push vers GitHub..." -ForegroundColor Green
        Write-Host "Utilisez votre token GitHub comme mot de passe si demande." -ForegroundColor Yellow
        git push -u origin $currentBranch
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "SUCCES: Fichiers pushes!" -ForegroundColor Green
        } else {
            Write-Host "ERREUR lors du push" -ForegroundColor Red
            exit 1
        }
    } else {
        Write-Host "Aucun changement a committer" -ForegroundColor Yellow
    }
} else {
    Write-Host "Etape 1 skippee" -ForegroundColor Yellow
}

Write-Host ""

# Étape 2: Créer le tag
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "ETAPE 2: Creation du tag v$version" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Vérifier si le tag existe déjà
$existingTag = git tag -l "v$version" 2>$null
if ($existingTag) {
    Write-Host "Le tag v$version existe deja!" -ForegroundColor Yellow
    $response = Read-Host "Voulez-vous le supprimer et le recreer? (o/n)"
    if ($response -eq "o") {
        git tag -d "v$version" 2>$null
        git push origin ":refs/tags/v$version" 2>$null
    } else {
        Write-Host "Utilisation du tag existant" -ForegroundColor Yellow
    }
}

if (-not $existingTag -or $response -eq "o") {
    Write-Host "Creation du tag v$version..." -ForegroundColor Green
    git tag -a "v$version" -m "Release version $version"
    
    Write-Host "Push du tag vers GitHub..." -ForegroundColor Green
    git push origin "v$version"
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "SUCCES: Tag v$version cree!" -ForegroundColor Green
    } else {
        Write-Host "ERREUR lors de la creation du tag" -ForegroundColor Red
    }
}

Write-Host ""

# Étape 3: Créer la release GitHub
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "ETAPE 3: Creation de la release GitHub" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Pour creer la release avec l'exe, vous avez deux options:" -ForegroundColor Yellow
Write-Host ""
Write-Host "OPTION A - Via GitHub CLI (recommandee si installee):" -ForegroundColor Cyan
Write-Host "  gh release create v$version $exePath --title `"v$version`" --notes `"$releaseNotes`"" -ForegroundColor White
Write-Host ""
Write-Host "OPTION B - Via l'interface GitHub:" -ForegroundColor Cyan
Write-Host "  1. Allez sur: https://github.com/$repoOwner/$repoName/releases/new" -ForegroundColor White
Write-Host "  2. Selectionnez le tag: v$version" -ForegroundColor White
Write-Host "  3. Titre: v$version" -ForegroundColor White
Write-Host "  4. Description: Copiez-collez les notes ci-dessous" -ForegroundColor White
Write-Host "  5. Uploadez le fichier: $exePath" -ForegroundColor White
Write-Host "  6. Cliquez sur 'Publish release'" -ForegroundColor White
Write-Host ""

# Vérifier si GitHub CLI est installé
$ghInstalled = $false
try {
    $ghVersion = gh --version 2>$null
    if ($ghVersion) {
        $ghInstalled = $true
        Write-Host "GitHub CLI detecte!" -ForegroundColor Green
        $response = Read-Host "Voulez-vous creer la release automatiquement avec gh? (o/n)"
        if ($response -eq "o") {
            Write-Host "Creation de la release..." -ForegroundColor Green
            $releaseNotesFile = "release-notes-$version.md"
            $releaseNotes | Out-File -FilePath $releaseNotesFile -Encoding UTF8
            
            gh release create "v$version" $exePath --title "v$version" --notes-file $releaseNotesFile
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host "SUCCES: Release v$version creee!" -ForegroundColor Green
                Remove-Item $releaseNotesFile
            } else {
                Write-Host "ERREUR lors de la creation de la release" -ForegroundColor Red
            }
        }
    }
} catch {
    $ghInstalled = $false
}

if (-not $ghInstalled -or $response -ne "o") {
    Write-Host ""
    Write-Host "Notes de release a copier:" -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host $releaseNotes -ForegroundColor White
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Fichier exe a uploader: $exePath" -ForegroundColor Yellow
    Write-Host "Chemin complet: $((Get-Item $exePath).FullName)" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Termine!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

