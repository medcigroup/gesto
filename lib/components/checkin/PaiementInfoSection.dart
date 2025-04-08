import 'package:flutter/material.dart';

class PaimentInfoSection extends StatefulWidget {
  final ValueChanged<String?> onPaymentMethodChanged;

  const PaimentInfoSection({
    Key? key,
    required this.onPaymentMethodChanged,
  }) : super(key: key);

  @override
  _PaimentInfoSectionState createState() => _PaimentInfoSectionState();
}

class _PaimentInfoSectionState extends State<PaimentInfoSection> {
  String? _selectedPaymentMethod;
  final List<String> _paymentMethods = ['Espèces', 'Mobile Money', 'Carte de Crédit'];

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
              'Informations paiement',
              style: Theme.of(context).textTheme.titleLarge!.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Divider(),
            SizedBox(height: 10),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Mode de paiement',
                prefixIcon: Icon(Icons.payment),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              value: _selectedPaymentMethod,
              validator: (value) =>
              value == null ? 'Veuillez sélectionner un mode de paiement' : null,
              items: _paymentMethods.map((method) {
                return DropdownMenuItem<String>(
                  value: method,
                  child: Text(method),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedPaymentMethod = value;
                });
                widget.onPaymentMethodChanged(value); // Call the callback
              },
            ),

          ],
        ),
      ),
    );
  }
}
