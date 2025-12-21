import 'package:flutter/material.dart';
import 'package:gesto/Screens/client/HotelOptionsStorePage.dart';
import '../config/getConnectedUserAdminId.dart';

/// Widget exemple pour intégrer la boutique d'options dans un dashboard
class OptionsStoreWidget extends StatelessWidget {
  final String? bookingId;
  final String? customerName;
  final String? customerEmail;
  final String? customerPhone;
  final String? roomNumber;

  const OptionsStoreWidget({
    Key? key,
    this.bookingId,
    this.customerName,
    this.customerEmail,
    this.customerPhone,
    this.roomNumber,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.purple, Colors.deepPurple],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          onTap: () => _openOptionsStore(context),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.storefront,
                  size: 50,
                  color: Colors.white,
                ),
                SizedBox(height: 12),
                Text(
                  'Boutique d\'options',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Text(
                  'Services supplémentaires payants',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.arrow_forward, size: 18, color: Colors.purple),
                      SizedBox(width: 8),
                      Text(
                        'Découvrir',
                        style: TextStyle(
                          color: Colors.purple,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openOptionsStore(BuildContext context) async {
    try {
      // Récupérer l'ID de l'hôtel
      final hotelId = await getConnectedUserAdminId();
      
      if (hotelId == null) {
        _showError(context, 'Impossible de récupérer les informations de l\'hôtel');
        return;
      }

      // Naviguer vers la boutique d'options
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => HotelOptionsStorePage(
            hotelId: hotelId,
            bookingId: bookingId,
            customerName: customerName,
            customerEmail: customerEmail,
            customerPhone: customerPhone,
            roomNumber: roomNumber,
          ),
        ),
      );
    } catch (e) {
      _showError(context, 'Erreur : ${e.toString()}');
    }
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}

/// Bouton compact pour intégrer dans une barre d'actions
class OptionsStoreButton extends StatelessWidget {
  final String? bookingId;
  final String? customerName;
  final String? customerEmail;
  final String? customerPhone;
  final String? roomNumber;
  final bool isCompact;

  const OptionsStoreButton({
    Key? key,
    this.bookingId,
    this.customerName,
    this.customerEmail,
    this.customerPhone,
    this.roomNumber,
    this.isCompact = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isCompact) {
      return IconButton(
        onPressed: () => _openOptionsStore(context),
        icon: Icon(Icons.shopping_cart),
        tooltip: 'Boutique d\'options',
        color: Colors.purple,
      );
    }

    return ElevatedButton.icon(
      onPressed: () => _openOptionsStore(context),
      icon: Icon(Icons.storefront),
      label: Text('Options payantes'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Future<void> _openOptionsStore(BuildContext context) async {
    try {
      final hotelId = await getConnectedUserAdminId();
      
      if (hotelId == null) {
        _showError(context, 'Impossible de récupérer les informations de l\'hôtel');
        return;
      }

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => HotelOptionsStorePage(
            hotelId: hotelId,
            bookingId: bookingId,
            customerName: customerName,
            customerEmail: customerEmail,
            customerPhone: customerPhone,
            roomNumber: roomNumber,
          ),
        ),
      );
    } catch (e) {
      _showError(context, 'Erreur : ${e.toString()}');
    }
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}

/// Liste item pour menu de navigation
class OptionsStoreMenuItem extends StatelessWidget {
  const OptionsStoreMenuItem({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.purple.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.storefront, color: Colors.purple),
      ),
      title: Text(
        'Boutique d\'options',
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text('Vendre des options aux clients'),
      trailing: Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () async {
        try {
          final hotelId = await getConnectedUserAdminId();
          
          if (hotelId != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => HotelOptionsStorePage(
                  hotelId: hotelId,
                ),
              ),
            );
          }
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur : ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
    );
  }
}

/// Floating Action Button pour accès rapide
class OptionsStoreFAB extends StatelessWidget {
  final String? hotelId;

  const OptionsStoreFAB({
    Key? key,
    this.hotelId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () async {
        String? id = hotelId;
        
        if (id == null) {
          id = await getConnectedUserAdminId();
        }
        
        if (id != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => HotelOptionsStorePage(
                hotelId: id,
              ),
            ),
          );
        }
      },
      icon: Icon(Icons.storefront),
      label: Text('Boutique'),
      backgroundColor: Colors.purple,
      foregroundColor: Colors.white,
    );
  }
}
