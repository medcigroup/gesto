import 'package:flutter/material.dart';

class CustomerInfoSection extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final TextEditingController idNumberController;
  final TextEditingController nationalityController;
  final TextEditingController addressController;

  const CustomerInfoSection({
    Key? key,
    required this.nameController,
    required this.emailController,
    required this.phoneController,
    required this.idNumberController,
    required this.nationalityController,
    required this.addressController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informations client',
              style: Theme.of(context).textTheme.titleLarge!.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Divider(),
            SizedBox(height: 10),
            TextFormField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Nom complet',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              validator: (value) =>
              value!.isEmpty ? 'Veuillez entrer le nom du client' : null,
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: phoneController,
              decoration: InputDecoration(
                labelText: 'Téléphone',
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              keyboardType: TextInputType.phone,
              validator: (value) =>
              value!.isEmpty ? 'Veuillez entrer le téléphone du client' : null,
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: idNumberController,
              decoration: InputDecoration(
                labelText: 'Numéro de pièce d\'identité',
                prefixIcon: Icon(Icons.badge),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              keyboardType: TextInputType.number,
              validator: (value) =>
              value!.isEmpty ? 'Veuillez entrer le numéro de pièce d\'identité' : null,
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: nationalityController,
              decoration: InputDecoration(
                labelText: 'Nationalité',
                prefixIcon: Icon(Icons.public),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              validator: (value) =>
              value!.isEmpty ? 'Veuillez entrer la nationalité du client' : null,
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: addressController,
              decoration: InputDecoration(
                labelText: 'Adresse',
                prefixIcon: Icon(Icons.location_on),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              validator: (value) =>
              value!.isEmpty ? 'Veuillez entrer l\'adresse du client' : null,
            ),
          ],
        ),
      ),
    );
  }
}
