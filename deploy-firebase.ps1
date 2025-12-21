# Script de déploiement Firebase pour Flutter Web
# Ce script compile et déploie automatiquement votre application

Write-Host "🚀 Début du déploiement Firebase..." -ForegroundColor Cyan

# 1. Nettoyer le build précédent
Write-Host "`n📦 Nettoyage des builds précédents..." -ForegroundColor Yellow
flutter clean

# 2. Récupérer les dépendances
Write-Host "`n📥 Récupération des dépendances..." -ForegroundColor Yellow
flutter pub get

# 3. Build pour le web avec optimisations
Write-Host "`n🔨 Compilation de l'application web..." -ForegroundColor Yellow
Write-Host "   Mode: Release" -ForegroundColor Gray
Write-Host "   Renderer: CanvasKit (meilleure performance)" -ForegroundColor Gray
flutter build web --release --web-renderer canvaskit

# 4. Vérifier que le build existe
if (!(Test-Path "build/web")) {
    Write-Host "`n❌ Erreur: Le dossier build/web n'existe pas!" -ForegroundColor Red
    exit 1
}

Write-Host "`n✅ Build réussi!" -ForegroundColor Green

# 5. Déployer sur Firebase
Write-Host "`n🌐 Déploiement sur Firebase Hosting..." -ForegroundColor Yellow
firebase deploy --only hosting

Write-Host "`n✨ =========================================" -ForegroundColor Cyan
Write-Host "✅ Déploiement terminé avec succès!" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Cyan

Write-Host "`n🌍 Votre application est maintenant accessible avec des URLs propres:" -ForegroundColor Cyan
Write-Host "   ✓ gestoapp.cloud" -ForegroundColor White
Write-Host "   ✓ gestoapp.cloud/tarif" -ForegroundColor White
Write-Host "   ✓ gestoapp.cloud/login" -ForegroundColor White
Write-Host "   ✓ gestoapp.cloud/register" -ForegroundColor White
Write-Host "   ✓ gestoapp.cloud/contact" -ForegroundColor White

Write-Host "`n📝 Nouvelles fonctionnalités:" -ForegroundColor Yellow
Write-Host "   ✓ URLs sans # (deep linking)" -ForegroundColor Gray
Write-Host "   ✓ Persistance de connexion (reste connecté)" -ForegroundColor Gray
Write-Host "   ✓ Reconnexion automatique au chargement" -ForegroundColor Gray
Write-Host "   ✓ Déconnexion manuelle avec confirmation" -ForegroundColor Gray

Write-Host "`n🧪 Tests à effectuer:" -ForegroundColor Cyan
Write-Host "   1. Navigation publique:" -ForegroundColor Yellow
Write-Host "      • Accéder directement à gestoapp.cloud/tarif" -ForegroundColor White
Write-Host "      • Vérifier que l'URL change en cliquant sur menu" -ForegroundColor White
Write-Host "      • Cliquer sur logo → retour à l'accueil" -ForegroundColor White
Write-Host ""
Write-Host "   2. Authentification:" -ForegroundColor Yellow
Write-Host "      • Se connecter et fermer le navigateur" -ForegroundColor White
Write-Host "      • Rouvrir → Vérifier reconnexion auto" -ForegroundColor White
Write-Host "      • Cliquer sur déconnexion → Vérifier retour accueil" -ForegroundColor White
Write-Host ""
Write-Host "   3. Deep linking:" -ForegroundColor Yellow
Write-Host "      • Ouvrir gestoapp.cloud/contactpage directement" -ForegroundColor White
Write-Host "      • Ouvrir gestoapp.cloud/mobile-download directement" -ForegroundColor White
Write-Host "      • Vérifier que les pages s'affichent correctement" -ForegroundColor White

