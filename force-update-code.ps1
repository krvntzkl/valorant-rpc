# Script pour FORCER la mise à jour du code source sur GitHub
# Utilisation: .\force-update-code.ps1

$repoOwner = "krvntzkl"
$repoName = "valorant-rpc"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "FORCE UPDATE DU CODE SOURCE" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Vérifier Git
try {
    $null = git --version 2>$null
    Write-Host "Git detecte" -ForegroundColor Green
} catch {
    Write-Host "ERREUR: Git n'est pas installe!" -ForegroundColor Red
    exit 1
}

# Vérifier qu'on est dans un repo Git
if (-not (Test-Path ".git")) {
    Write-Host "Initialisation du repository Git..." -ForegroundColor Yellow
    git init
    git branch -M main
}

# Vérifier le remote
Write-Host "Verification du remote..." -ForegroundColor Cyan
$remoteUrl = git remote get-url origin 2>$null

if (-not $remoteUrl) {
    Write-Host "Ajout du remote..." -ForegroundColor Yellow
    git remote add origin "https://github.com/$repoOwner/$repoName.git"
} else {
    Write-Host "Remote: $remoteUrl" -ForegroundColor Green
    
    # S'assurer que c'est le bon remote
    if ($remoteUrl -ne "https://github.com/$repoOwner/$repoName.git") {
        Write-Host "Correction du remote..." -ForegroundColor Yellow
        git remote set-url origin "https://github.com/$repoOwner/$repoName.git"
    }
}

# Vérifier la branche
$currentBranch = git branch --show-current 2>$null
if (-not $currentBranch) {
    git branch -M main
    $currentBranch = "main"
}

Write-Host "Branche: $currentBranch" -ForegroundColor Green
Write-Host ""

# Afficher l'état
Write-Host "Etat actuel:" -ForegroundColor Cyan
git status --short
Write-Host ""

# ÉTAPE 1: Ajouter TOUS les fichiers
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "ETAPE 1: Ajout de TOUS les fichiers" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Ajout de tous les fichiers (sauf .gitignore)..." -ForegroundColor Green
git add -A
git add --force . 2>$null

$staged = git diff --cached --name-only 2>$null
if ($staged) {
    Write-Host "Fichiers a committer: $($staged.Count)" -ForegroundColor Green
    $staged | Select-Object -First 10 | ForEach-Object { Write-Host "  + $_" -ForegroundColor White }
    if ($staged.Count -gt 10) {
        Write-Host "  ... et $($staged.Count - 10) autres fichiers" -ForegroundColor Gray
    }
} else {
    Write-Host "Aucun fichier nouveau a committer" -ForegroundColor Yellow
}

Write-Host ""

# ÉTAPE 2: Créer le commit
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "ETAPE 2: Creation du commit" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$commitMessage = "Update codebase to version 3.3.4 - Bug fixes and improvements"

# Vérifier s'il y a des changements
$hasStagedChanges = git diff --cached --quiet 2>$null
$hasUnstagedChanges = git diff --quiet 2>$null

if (-not $hasStagedChanges) {
    Write-Host "Creation du commit avec les fichiers stages..." -ForegroundColor Green
    git commit -m $commitMessage
} elseif (-not $hasUnstagedChanges) {
    Write-Host "Pas de changements stages, creation d'un commit vide pour forcer le push..." -ForegroundColor Yellow
    git commit --allow-empty -m $commitMessage
} else {
    Write-Host "Ajout des fichiers non stages..." -ForegroundColor Yellow
    git add -A
    git commit -m $commitMessage
}

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERREUR lors de la creation du commit" -ForegroundColor Red
    Write-Host "Verifiez votre configuration Git (user.name et user.email)" -ForegroundColor Yellow
    exit 1
}

Write-Host "SUCCES: Commit cree!" -ForegroundColor Green
Write-Host ""

# Afficher le dernier commit
$lastCommit = git log -1 --oneline 2>$null
Write-Host "Dernier commit: $lastCommit" -ForegroundColor Cyan
Write-Host ""

# ÉTAPE 3: FORCER le push
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "ETAPE 3: FORCE PUSH vers GitHub" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "ATTENTION: Cela va ECRASER le code sur GitHub!" -ForegroundColor Yellow
Write-Host "Remote: https://github.com/$repoOwner/$repoName.git" -ForegroundColor Cyan
Write-Host "Branche: $currentBranch" -ForegroundColor Cyan
Write-Host ""
Write-Host "Utilisez votre token GitHub comme mot de passe si demande." -ForegroundColor Yellow
Write-Host ""

$response = Read-Host "Continuer avec le force push? (o/n)"
if ($response -ne "o") {
    Write-Host "Push annule" -ForegroundColor Yellow
    exit 0
}

Write-Host "Execution du force push..." -ForegroundColor Green
Write-Host ""

# Force push
git push -f origin $currentBranch

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "SUCCES: Code source mis a jour!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Verifiez sur: https://github.com/$repoOwner/$repoName" -ForegroundColor Cyan
    Write-Host "Actualisez la page dans quelques secondes!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Les fichiers devraient maintenant montrer:" -ForegroundColor Green
    Write-Host "  - Vos derniers commits" -ForegroundColor White
    Write-Host "  - Les dates recentes (au lieu de '4 years ago')" -ForegroundColor White
} else {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Red
    Write-Host "ERREUR lors du push" -ForegroundColor Red
    Write-Host "========================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "Causes possibles:" -ForegroundColor Yellow
    Write-Host "  1. Token GitHub incorrect ou expire" -ForegroundColor White
    Write-Host "  2. Pas de droits d'ecriture sur le repo" -ForegroundColor White
    Write-Host "  3. Probleme de connexion" -ForegroundColor White
    Write-Host ""
    Write-Host "Essayez manuellement:" -ForegroundColor Yellow
    Write-Host "  git push -f origin $currentBranch" -ForegroundColor White
    Write-Host ""
    Write-Host "Ou verifiez votre remote:" -ForegroundColor Yellow
    git remote -v
}
