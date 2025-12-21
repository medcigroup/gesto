/// FICHIER TEMPORAIRE POUR TESTER LE DIAGNOSTIC
///
/// Ajoutez ce code dans votre DashboardManager.dart temporairement
/// pour accéder rapidement au diagnostic

/*

ÉTAPE 1 : Ajoutez cet import en haut de DashboardManager.dart (ligne ~1-41)

import 'diagnostic_complete.dart';


ÉTAPE 2 : Ajoutez ce bouton dans les actions de l'AppBar (ligne ~645-920)

Cherchez cette ligne dans DashboardManager.dart :
  actions: <Widget>[

Juste après, ajoutez :

              // 🔍 BOUTON DIAGNOSTIC TEMPORAIRE
              IconButton(
                icon: const Icon(Icons.bug_report, color: Colors.red),
                tooltip: '🔍 Diagnostic - Pourquoi mes pages ne s\'affichent pas ?',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DiagnosticCompletePage(),
                    ),
                  );
                },
              ),


ÉTAPE 3 : Lancez l'app et cliquez sur l'icône 🐛 dans la barre du haut


ÉTAPE 4 : Le diagnostic vous dira exactement :
- ✅ Quelle est votre licence actuelle (devrait être "pro")
- ✅ Quel est votre rôle (devrait être "manager")
- ✅ Quelles pages DEVRAIENT être visibles
- ✅ Quelles pages SONT effectivement visibles
- ✅ Le problème exact (ex: "licenceType" est "Pro" au lieu de "pro")


ÉTAPE 5 : Suivez les instructions affichées par le diagnostic


ÉTAPE 6 : Une fois résolu, supprimez le code ajouté aux étapes 1 et 2

*/

// ============================================================================
// ALTERNATIVE : Si vous ne voulez pas modifier DashboardManager.dart
// ============================================================================

/*

Créez un nouveau fichier : lib/test_diagnostic_page.dart

Copiez-collez ce code :

import 'package:flutter/material.dart';
import 'diagnostic_complete.dart';

class TestDiagnosticPage extends StatelessWidget {
  const TestDiagnosticPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Diagnostic'),
        backgroundColor: Colors.red,
      ),
      body: Center(
        child: ElevatedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const DiagnosticCompletePage(),
              ),
            );
          },
          icon: const Icon(Icons.bug_report, size: 32),
          label: const Text(
            'Lancer le diagnostic',
            style: TextStyle(fontSize: 18),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
          ),
        ),
      ),
    );
  }
}


Puis dans votre main.dart, ajoutez temporairement cette route :

import 'test_diagnostic_page.dart';

// Dans MaterialApp → routes ou onGenerateRoute
'/test-diagnostic': (context) => const TestDiagnosticPage(),


Pour y accéder, utilisez :
Navigator.pushNamed(context, '/test-diagnostic');

Ou créez un bouton temporaire n'importe où dans l'app.

*/

void main() {
  print('Ce fichier est un guide - lisez les commentaires ci-dessus');
  print('Ajoutez le code dans DashboardManager.dart pour accéder au diagnostic');
}
