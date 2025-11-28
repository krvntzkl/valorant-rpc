# Script CORRIGE pour mettre à jour le repo et créer la release v3.3.4
# Utilisation: .\update-and-release-FIXED.ps1

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
Write-Host "Mise a jour et release v$version (CORRIGE)" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Vérifier que Git est installé
try {
    $null = git --version 2>$null
    Write-Host "Git detecte" -ForegroundColor Green
} catch {
    Write-Host "ERREUR: Git n'est pas installe!" -ForegroundColor Red
    exit 1
}

# Vérifier que l'exe existe
if (-not (Test-Path $exePath)) {
    Write-Host "ERREUR: $exePath introuvable!" -ForegroundColor Red
    exit 1
}

$exeSize = [math]::Round((Get-Item $exePath).Length / 1MB, 2)
Write-Host "Fichier exe trouve: $exePath ($exeSize MB)" -ForegroundColor Green
Write-Host ""

# Vérifier l'état du repo
Write-Host "Verification de l'etat du repository..." -ForegroundColor Cyan
$status = git status --porcelain 2>$null

if ($status) {
    Write-Host "Changements detectes:" -ForegroundColor Green
    git status --short
    Write-Host ""
} else {
    Write-Host "Aucun changement detecte dans les fichiers" -ForegroundColor Yellow
    Write-Host ""
}

# Vérifier la branche
$currentBranch = git branch --show-current 2>$null
if (-not $currentBranch) {
    Write-Host "Initialisation du repository Git..." -ForegroundColor Yellow
    git init
    git branch -M main
    $currentBranch = "main"
}

Write-Host "Branche actuelle: $currentBranch" -ForegroundColor Green

# Vérifier le remote
$remoteUrl = git remote get-url origin 2>$null
if (-not $remoteUrl) {
    $remoteUrl = "https://github.com/$repoOwner/$repoName.git"
    Write-Host "Ajout du remote: $remoteUrl" -ForegroundColor Green
    git remote add origin $remoteUrl
} else {
    Write-Host "Remote: $remoteUrl" -ForegroundColor Green
}

Write-Host ""

# ÉTAPE 1: FORCER LE PUSH DE TOUS LES FICHIERS
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "ETAPE 1: FORCER LE PUSH DES FICHIERS" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Cette etape va:" -ForegroundColor Yellow
Write-Host "  1. Ajouter TOUS les fichiers (sauf .gitignore)" -ForegroundColor White
Write-Host "  2. Creer un commit" -ForegroundColor White
Write-Host "  3. FORCER le push vers GitHub (ecrase l'ancien code)" -ForegroundColor White
Write-Host ""

$response = Read-Host "Continuer? (o/n)"
if ($response -ne "o") {
    exit 0
}

Write-Host "Ajout de tous les fichiers..." -ForegroundColor Green
git add .

$changes = git diff --cached --name-only 2>$null
if (-not $changes) {
    # Vérifier s'il y a des fichiers non trackés
    $untracked = git ls-files --others --exclude-standard 2>$null
    if ($untracked) {
        Write-Host "Fichiers non trackes detectes, ajout..." -ForegroundColor Yellow
        git add -A
    } else {
        Write-Host "Aucun changement a committer" -ForegroundColor Yellow
    }
}

# Vérifier à nouveau
$changes = git diff --cached --name-only 2>$null
if ($changes) {
    Write-Host "Creation du commit..." -ForegroundColor Green
    git commit -m "Update to version $version - Bug fixes and improvements"
} else {
    # Forcer un commit même s'il n'y a pas de changements (amend)
    Write-Host "Creation d'un commit vide pour forcer le push..." -ForegroundColor Yellow
    git commit --allow-empty -m "Update to version $version - Bug fixes and improvements"
}

Write-Host "FORCE PUSH vers GitHub..." -ForegroundColor Green
Write-Host "Utilisez votre token GitHub comme mot de passe si demande." -ForegroundColor Yellow
Write-Host ""

# Force push pour écraser l'ancien code
git push -f origin $currentBranch

if ($LASTEXITCODE -eq 0) {
    Write-Host "SUCCES: Fichiers pushes!" -ForegroundColor Green
} else {
    Write-Host "ERREUR lors du push" -ForegroundColor Red
    Write-Host "Verifiez votre authentification (token GitHub)" -ForegroundColor Yellow
    exit 1
}

Write-Host ""

# ÉTAPE 2: CRÉER LE TAG
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "ETAPE 2: CREATION DU TAG v$version" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Supprimer le tag s'il existe déjà
$existingTag = git tag -l "v$version" 2>$null
if ($existingTag) {
    Write-Host "Suppression de l'ancien tag v$version..." -ForegroundColor Yellow
    git tag -d "v$version" 2>$null
    git push origin ":refs/tags/v$version" 2>$null
}

Write-Host "Creation du tag v$version..." -ForegroundColor Green
git tag -a "v$version" -m "Release version $version"

Write-Host "Push du tag vers GitHub..." -ForegroundColor Green
git push origin "v$version"

if ($LASTEXITCODE -eq 0) {
    Write-Host "SUCCES: Tag v$version cree!" -ForegroundColor Green
} else {
    Write-Host "ERREUR lors de la creation du tag" -ForegroundColor Red
    exit 1
}

Write-Host ""

# ÉTAPE 3: CRÉER LA VRAIE RELEASE AVEC L'EXE
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "ETAPE 3: CREATION DE LA RELEASE GITHUB" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Pour creer une VRAIE release avec l'exe, vous avez besoin d'un Personal Access Token." -ForegroundColor Yellow
Write-Host "Si vous n'en avez pas, creez-en un sur: https://github.com/settings/tokens" -ForegroundColor Cyan
Write-Host "Permissions necessaires: 'repo' (toutes les permissions)" -ForegroundColor Yellow
Write-Host ""

$useAPI = Read-Host "Voulez-vous creer la release via l'API GitHub? (o/n)"
if ($useAPI -eq "o") {
    $token = Read-Host "Entrez votre Personal Access Token GitHub" -AsSecureString
    $tokenPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($token))
    
    if (-not $tokenPlain) {
        Write-Host "Token vide, utilisation de GitHub CLI ou methode manuelle" -ForegroundColor Yellow
        $useAPI = "n"
    } else {
        Write-Host ""
        Write-Host "Creation de la release via l'API GitHub..." -ForegroundColor Green
        
        # Créer la release via l'API
        $releaseBody = @{
            tag_name = "v$version"
            name = "v$version"
            body = $releaseNotes
            draft = $false
            prerelease = $false
        } | ConvertTo-Json
        
        $headers = @{
            "Authorization" = "token $tokenPlain"
            "Accept" = "application/vnd.github.v3+json"
        }
        
        $releaseUrl = "https://api.github.com/repos/$repoOwner/$repoName/releases"
        
        Write-Host "Envoi de la requete de creation de release..." -ForegroundColor Green
        try {
            $releaseResponse = Invoke-RestMethod -Uri $releaseUrl -Method Post -Headers $headers -Body $releaseBody -ContentType "application/json"
            $releaseId = $releaseResponse.id
            Write-Host "SUCCES: Release creee (ID: $releaseId)" -ForegroundColor Green
            
            # Uploader l'exe
            Write-Host "Upload de l'exe ($exeSize MB)..." -ForegroundColor Green
            $uploadUrl = "https://uploads.github.com/repos/$repoOwner/$repoName/releases/$releaseId/assets?name=valorant-rpc.exe"
            
            $fileBytes = [System.IO.File]::ReadAllBytes((Resolve-Path $exePath))
            $fileEnc = [System.Text.Encoding]::GetEncoding("ISO-8859-1").GetString($fileBytes)
            $boundary = [System.Guid]::NewGuid().ToString()
            $LF = "`r`n"
            
            $bodyLines = (
                "--$boundary",
                "Content-Disposition: form-data; name=`"file`"; filename=`"valorant-rpc.exe`"",
                "Content-Type: application/octet-stream$LF",
                $fileEnc,
                "--$boundary--$LF"
            ) -join $LF
            
            $uploadHeaders = @{
                "Authorization" = "token $tokenPlain"
                "Accept" = "application/vnd.github.v3+json"
                "Content-Type" = "multipart/form-data; boundary=$boundary"
            }
            
            # Méthode alternative avec Invoke-WebRequest
            $exeFullPath = (Resolve-Path $exePath).Path
            $uploadResponse = Invoke-RestMethod -Uri $uploadUrl -Method Post -Headers @{
                "Authorization" = "token $tokenPlain"
                "Accept" = "application/vnd.github.v3+json"
            } -InFile $exeFullPath -ContentType "application/octet-stream"
            
            Write-Host "SUCCES: Exe uploade!" -ForegroundColor Green
            Write-Host "Release disponible sur: $($releaseResponse.html_url)" -ForegroundColor Cyan
            
        } catch {
            Write-Host "ERREUR lors de la creation de la release:" -ForegroundColor Red
            Write-Host $_.Exception.Message -ForegroundColor Red
            Write-Host ""
            Write-Host "Falling back to GitHub CLI or manual method..." -ForegroundColor Yellow
            $useAPI = "n"
        }
        
        # Nettoyer le token de la mémoire
        $tokenPlain = $null
        $token = $null
    }
}

# Fallback: GitHub CLI ou méthode manuelle
if ($useAPI -ne "o") {
    # Vérifier GitHub CLI
    try {
        $null = gh --version 2>$null
        Write-Host "GitHub CLI detecte!" -ForegroundColor Green
        $response = Read-Host "Voulez-vous creer la release avec GitHub CLI? (o/n)"
        if ($response -eq "o") {
            $releaseNotesFile = "release-notes-$version.md"
            $releaseNotes | Out-File -FilePath $releaseNotesFile -Encoding UTF8
            
            Write-Host "Creation de la release avec GitHub CLI..." -ForegroundColor Green
            gh release create "v$version" $exePath --title "v$version" --notes-file $releaseNotesFile
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host "SUCCES: Release v$version creee!" -ForegroundColor Green
                Remove-Item $releaseNotesFile
            } else {
                Write-Host "ERREUR lors de la creation de la release" -ForegroundColor Red
            }
        }
    } catch {
        Write-Host ""
        Write-Host "========================================" -ForegroundColor Yellow
        Write-Host "METHODE MANUELLE" -ForegroundColor Yellow
        Write-Host "========================================" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "1. Allez sur: https://github.com/$repoOwner/$repoName/releases/new" -ForegroundColor White
        Write-Host "2. Selectionnez le tag: v$version" -ForegroundColor White
        Write-Host "3. Titre: v$version" -ForegroundColor White
        Write-Host "4. Description: Copiez-collez les notes ci-dessous" -ForegroundColor White
        Write-Host "5. Uploadez le fichier: $exePath" -ForegroundColor White
        Write-Host "   Chemin complet: $((Get-Item $exePath).FullName)" -ForegroundColor Cyan
        Write-Host "6. Cliquez sur 'Publish release'" -ForegroundColor White
        Write-Host ""
        Write-Host "Notes de release:" -ForegroundColor Yellow
        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host $releaseNotes -ForegroundColor White
        Write-Host "========================================" -ForegroundColor Cyan
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Termine!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

