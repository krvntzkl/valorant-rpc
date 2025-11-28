# Script de diagnostic et correction pour forcer la mise à jour
# Utilisation: .\diagnostic-and-fix.ps1

$repoOwner = "krvntzkl"
$repoName = "valorant-rpc"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "DIAGNOSTIC ET CORRECTION" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Vérifier Git
try {
    $null = git --version 2>$null
} catch {
    Write-Host "ERREUR: Git n'est pas installe!" -ForegroundColor Red
    exit 1
}

# DIAGNOSTIC
Write-Host "=== DIAGNOSTIC ===" -ForegroundColor Yellow
Write-Host ""

# 1. Vérifier le remote
Write-Host "1. Remote:" -ForegroundColor Cyan
git remote -v
$remoteUrl = git remote get-url origin 2>$null
Write-Host ""

# 2. Vérifier la branche
Write-Host "2. Branche actuelle:" -ForegroundColor Cyan
$currentBranch = git branch --show-current 2>$null
if (-not $currentBranch) {
    Write-Host "  Aucune branche (repo non initialise?)" -ForegroundColor Red
} else {
    Write-Host "  $currentBranch" -ForegroundColor Green
}
Write-Host ""

# 3. Vérifier les commits locaux
Write-Host "3. Derniers commits locaux:" -ForegroundColor Cyan
$localCommits = git log --oneline -5 2>$null
if ($localCommits) {
    $localCommits | ForEach-Object { Write-Host "  $_" -ForegroundColor White }
} else {
    Write-Host "  Aucun commit local" -ForegroundColor Red
}
Write-Host ""

# 4. Essayer de fetch
Write-Host "4. Recuperation des infos distantes..." -ForegroundColor Cyan
try {
    git fetch origin 2>&1 | Out-Null
    Write-Host "  Fetch reussi" -ForegroundColor Green
    
    Write-Host "  Derniers commits distants:" -ForegroundColor Cyan
    $remoteCommits = git log origin/$currentBranch --oneline -5 2>$null
    if ($remoteCommits) {
        $remoteCommits | ForEach-Object { Write-Host "    $_" -ForegroundColor Gray }
    } else {
        Write-Host "    Aucun commit distant sur origin/$currentBranch" -ForegroundColor Yellow
    }
} catch {
    Write-Host "  Impossible de fetch (normal si premier push)" -ForegroundColor Yellow
}
Write-Host ""

# 5. Vérifier l'état des fichiers
Write-Host "5. Etat des fichiers:" -ForegroundColor Cyan
$status = git status --porcelain 2>$null
if ($status) {
    Write-Host "  Fichiers modifies:" -ForegroundColor Yellow
    $status | Select-Object -First 10 | ForEach-Object { Write-Host "    $_" -ForegroundColor White }
} else {
    Write-Host "  Aucun fichier modifie" -ForegroundColor Green
}
Write-Host ""

# 6. Vérifier si on a des fichiers non trackés
Write-Host "6. Fichiers non trackes:" -ForegroundColor Cyan
$untracked = git ls-files --others --exclude-standard 2>$null
if ($untracked) {
    Write-Host "  $($untracked.Count) fichiers non trackes" -ForegroundColor Yellow
    $untracked | Select-Object -First 5 | ForEach-Object { Write-Host "    $_" -ForegroundColor White }
} else {
    Write-Host "  Tous les fichiers sont trackes" -ForegroundColor Green
}
Write-Host ""

Write-Host "=== CORRECTION ===" -ForegroundColor Yellow
Write-Host ""

# CORRECTION 1: S'assurer que le remote est correct
if ($remoteUrl -ne "https://github.com/$repoOwner/$repoName.git") {
    Write-Host "Correction du remote..." -ForegroundColor Green
    if ($remoteUrl) {
        git remote remove origin
    }
    git remote add origin "https://github.com/$repoOwner/$repoName.git"
    Write-Host "Remote corrige: https://github.com/$repoOwner/$repoName.git" -ForegroundColor Green
    Write-Host ""
}

# CORRECTION 2: S'assurer qu'on est sur main
if (-not $currentBranch -or $currentBranch -ne "main") {
    Write-Host "Creation/switch vers la branche main..." -ForegroundColor Green
    git checkout -B main 2>$null
    $currentBranch = "main"
    Write-Host "Branche: $currentBranch" -ForegroundColor Green
    Write-Host ""
}

# CORRECTION 3: Ajouter TOUS les fichiers
Write-Host "Ajout de TOUS les fichiers..." -ForegroundColor Green
git add -A
git add --force . 2>$null

# Afficher ce qui va être commité
$staged = git diff --cached --name-only 2>$null
if ($staged) {
    Write-Host "Fichiers a committer: $($staged.Count)" -ForegroundColor Green
} else {
    Write-Host "Aucun fichier nouveau a committer" -ForegroundColor Yellow
    Write-Host "Mais on va quand meme creer un commit pour forcer le push..." -ForegroundColor Yellow
}
Write-Host ""

# CORRECTION 4: Créer un commit FORCE
Write-Host "Creation d'un commit FORCE..." -ForegroundColor Green
$commitMessage = "Force update to version 3.3.4 - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"

# Toujours créer un commit, même vide
git commit --allow-empty -m $commitMessage

# Si on a des changements, créer un autre commit
$hasChanges = git diff --cached --quiet 2>$null
if (-not $hasChanges) {
    git commit -m "Update all files to version 3.3.4"
}

Write-Host "Commit(s) cree(s)!" -ForegroundColor Green
Write-Host ""

# Afficher le dernier commit
$lastCommit = git log -1 --oneline 2>$null
Write-Host "Dernier commit: $lastCommit" -ForegroundColor Cyan
Write-Host ""

# CORRECTION 5: FORCE PUSH
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "FORCE PUSH VERS GITHUB" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Cela va ECRASER le code sur GitHub avec votre version locale!" -ForegroundColor Yellow
Write-Host "Remote: https://github.com/$repoOwner/$repoName.git" -ForegroundColor Cyan
Write-Host "Branche: $currentBranch" -ForegroundColor Cyan
Write-Host ""
Write-Host "Utilisez votre token GitHub comme mot de passe." -ForegroundColor Yellow
Write-Host ""

$response = Read-Host "Continuer? (o/n)"
if ($response -ne "o") {
    Write-Host "Annule" -ForegroundColor Yellow
    exit 0
}

Write-Host "Execution du force push..." -ForegroundColor Green
Write-Host ""

# Force push avec verbose pour voir les erreurs
git push -f -v origin $currentBranch 2>&1 | ForEach-Object {
    Write-Host $_ -ForegroundColor $(if ($_ -match "error|fatal") { "Red" } else { "White" })
}

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "SUCCES!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Le code devrait maintenant etre mis a jour sur:" -ForegroundColor Green
    Write-Host "https://github.com/$repoOwner/$repoName" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Actualisez la page dans votre navigateur!" -ForegroundColor Yellow
} else {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Red
    Write-Host "ERREUR!" -ForegroundColor Red
    Write-Host "========================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "Le push a echoue. Causes possibles:" -ForegroundColor Yellow
    Write-Host "  1. Token GitHub incorrect ou expire" -ForegroundColor White
    Write-Host "  2. Pas de droits d'ecriture sur le repo" -ForegroundColor White
    Write-Host "  3. Le repo n'existe pas ou est prive" -ForegroundColor White
    Write-Host ""
    Write-Host "Verifiez:" -ForegroundColor Yellow
    Write-Host "  - Le repo existe: https://github.com/$repoOwner/$repoName" -ForegroundColor Cyan
    Write-Host "  - Vous avez les droits d'ecriture" -ForegroundColor Cyan
    Write-Host "  - Votre token a la permission 'repo'" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Essayez manuellement:" -ForegroundColor Yellow
    Write-Host "  git push -f origin $currentBranch" -ForegroundColor White
}

