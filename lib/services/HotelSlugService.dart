import 'package:cloud_firestore/cloud_firestore.dart';

class HotelSlugService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Génère un slug unique à partir du nom de l'hôtel
  static String generateSlug(String hotelName) {
    // Convertir en minuscules
    String slug = hotelName.toLowerCase();
    
    // Remplacer les espaces par des tirets
    slug = slug.replaceAll(' ', '-');
    
    // Remplacer les caractères accentués
    final accents = {
      'à': 'a', 'â': 'a', 'ä': 'a', 'á': 'a', 'ã': 'a',
      'è': 'e', 'ê': 'e', 'ë': 'e', 'é': 'e',
      'ì': 'i', 'î': 'i', 'ï': 'i', 'í': 'i',
      'ò': 'o', 'ô': 'o', 'ö': 'o', 'ó': 'o', 'õ': 'o',
      'ù': 'u', 'û': 'u', 'ü': 'u', 'ú': 'u',
      'ç': 'c', 'ñ': 'n',
    };
    
    accents.forEach((key, value) {
      slug = slug.replaceAll(key, value);
    });
    
    // Supprimer tous les caractères non alphanumériques sauf les tirets
    slug = slug.replaceAll(RegExp(r'[^a-z0-9-]'), '');
    
    // Supprimer les tirets multiples
    slug = slug.replaceAll(RegExp(r'-+'), '-');
    
    // Supprimer les tirets en début et fin
    slug = slug.trim().replaceAll(RegExp(r'^-|-$'), '');
    
    return slug;
  }

  /// Vérifie si un slug est disponible
  static Future<bool> isSlugAvailable(String slug) async {
    try {
      final querySnapshot = await _firestore
          .collection('hotels')
          .where('slug', isEqualTo: slug)
          .limit(1)
          .get();
      
      return querySnapshot.docs.isEmpty;
    } catch (e) {
      print('Erreur lors de la vérification du slug: $e');
      return false;
    }
  }

  /// Génère un slug unique en ajoutant un numéro si nécessaire
  static Future<String> generateUniqueSlug(String hotelName) async {
    String baseSlug = generateSlug(hotelName);
    String slug = baseSlug;
    int counter = 1;
    
    while (!await isSlugAvailable(slug)) {
      slug = '$baseSlug-$counter';
      counter++;
    }
    
    return slug;
  }

  /// Crée ou met à jour le document hotel avec le slug
  static Future<bool> createOrUpdateHotelDocument({
    required String userId,
    required String hotelName,
    required String address,
    String? description,
    String? phone,
    String? email,
    String? coverImage,
    bool isPublic = true,
    List<String>? amenities,
    String? facebook,
    String? instagram,
    String? website,
    String? tripadvisor,
    String? startingPrice,
    String? promoTitle,
    String? promoDescription,
    String? promoCode,
  }) async {
    try {
      // Vérifier si le document existe déjà
      final doc = await _firestore.collection('hotels').doc(userId).get();
      String slug;

      if (doc.exists && doc.data()?['slug'] != null) {
        // Utiliser le slug existant
        slug = doc.data()!['slug'];
      } else {
        // Générer un nouveau slug unique
        slug = await generateUniqueSlug(hotelName);
      }

      // Créer ou mettre à jour le document
      await _firestore.collection('hotels').doc(userId).set({
        'userId': userId,
        'slug': slug,
        'hotelName': hotelName,
        'address': address,
        'description': description,
        'phone': phone,
        'email': email,
        'coverImage': coverImage,
        'isPublic': isPublic,
        'amenities': amenities ?? [],
        'facebook': facebook,
        'instagram': instagram,
        'website': website,
        'tripadvisor': tripadvisor,
        'startingPrice': startingPrice,
        'promoTitle': promoTitle,
        'promoDescription': promoDescription,
        'promoCode': promoCode,
        'createdAt': doc.exists ? doc.data()!['createdAt'] : FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      print('✅ Page hôtel créée avec succès: $slug');
      return true;
    } catch (e) {
      print('❌ Erreur lors de la création de la page hôtel: $e');
      return false;
    }
  }

  /// Récupère le slug d'un hôtel par userId
  static Future<String?> getHotelSlug(String userId) async {
    try {
      final doc = await _firestore.collection('hotels').doc(userId).get();
      if (doc.exists) {
        return doc.data()?['slug'] as String?;
      }
      return null;
    } catch (e) {
      print('Erreur lors de la récupération du slug: $e');
      return null;
    }
  }

  /// Met à jour la visibilité publique de l'hôtel
  static Future<bool> updateHotelVisibility(String userId, bool isPublic) async {
    try {
      await _firestore.collection('hotels').doc(userId).update({
        'isPublic': isPublic,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Erreur lors de la mise à jour de la visibilité: $e');
      return false;
    }
  }

  /// Génère l'URL complète de la page publique
  static String getPublicUrl(String slug, {String baseUrl = 'gestoapp.cloud'}) {
    return 'https://$baseUrl/hotel/$slug';
  }

  /// Copie l'URL publique dans le presse-papiers (pour partage)
  static Future<void> shareHotelUrl(String slug) async {
    final url = getPublicUrl(slug);
    // TODO: Implémenter le partage (share package ou clipboard)
    print('URL à partager: $url');
  }
}
