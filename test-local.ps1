# Script de test en local pour Flutter Web
# Lance l'application sur localhost pour tester les URLs dynamiques

Write-Host "🧪 Lancement du serveur de test local..." -ForegroundColor Cyan

Write-Host "`n📝 Instructions de test :" -ForegroundColor Yellow
Write-Host "   Après le démarrage, testez ces URLs dans votre navigateur:" -ForegroundColor Gray
Write-Host "   • http://localhost:5000" -ForegroundColor White
Write-Host "   • http://localhost:5000/tarif" -ForegroundColor White
Write-Host "   • http://localhost:5000/login" -ForegroundColor White
Write-Host "   • http://localhost:5000/contact" -ForegroundColor White
Write-Host ""
Write-Host "   ⚠️  Les URLs doivent fonctionner directement (pas de redirection)" -ForegroundColor Yellow
Write-Host "   ⚠️  Appuyez sur 'q' dans le terminal pour arrêter le serveur" -ForegroundColor Yellow
Write-Host ""

# Lancer Flutter en mode debug web
flutter run -d chrome --web-hostname localhost --web-port 5000
