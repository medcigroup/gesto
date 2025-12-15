import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:convert';
// Pour Flutter Web
import 'dart:html' as html;
import '../../config/getConnectedUserAdminId.dart';
import '../../config/restaurant_models.dart';

class RestaurantExportReports extends StatefulWidget {
  @override
  _RestaurantExportReportsState createState() => _RestaurantExportReportsState();
}

class _RestaurantExportReportsState extends State<RestaurantExportReports> {
  String? _userId;
  bool _isLoading = false;

  // Type de rapport sélectionné
  String _selectedReportType = 'daily'; // daily, weekly, monthly, transactions, inventory, complete

  // Période sélectionnée
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();

  // Format d'export
  String _exportFormat = 'pdf'; // pdf, csv, both

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    try {
      _userId = await getConnectedUserAdminId();
      setState(() {});
    } catch (e) {
      print('❌ Erreur initialisation: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        title: Text('Export & Impression de Rapports'),
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            SizedBox(height: 24),
            _buildReportTypeSelector(),
            SizedBox(height: 24),
            _buildPeriodSelector(),
            SizedBox(height: 24),
            _buildExportFormatSelector(),
            SizedBox(height: 32),
            _buildReportPreview(),
            SizedBox(height: 32),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.deepPurple, Colors.purple.shade300],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.3),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.print, size: 40, color: Colors.white),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Exportation de Rapports',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Générez et exportez vos rapports en PDF ou CSV',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportTypeSelector() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.description, color: Colors.deepPurple),
              SizedBox(width: 8),
              Text(
                'Type de rapport',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          SizedBox(height: 16),
          _buildReportTypeCard(
            'daily',
            'Rapport Journalier',
            'Rapport détaillé des ventes du jour',
            Icons.today,
            Colors.blue,
          ),
          SizedBox(height: 12),
          _buildReportTypeCard(
            'weekly',
            'Rapport Hebdomadaire',
            'Résumé des 7 derniers jours',
            Icons.calendar_view_week,
            Colors.green,
          ),
          SizedBox(height: 12),
          _buildReportTypeCard(
            'monthly',
            'Rapport Mensuel',
            'Synthèse mensuelle complète',
            Icons.calendar_month,
            Colors.orange,
          ),
          SizedBox(height: 12),
          _buildReportTypeCard(
            'transactions',
            'Rapport de Transactions',
            'Liste détaillée de toutes les transactions',
            Icons.receipt_long,
            Colors.purple,
          ),
          SizedBox(height: 12),
          _buildReportTypeCard(
            'inventory',
            'Rapport d\'Inventaire',
            'Articles vendus et stock',
            Icons.inventory,
            Colors.teal,
          ),
          SizedBox(height: 12),
          _buildReportTypeCard(
            'complete',
            'Rapport Complet',
            'Rapport exhaustif avec toutes les statistiques',
            Icons.analytics,
            Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildReportTypeCard(String value, String title, String description, IconData icon, Color color) {
    final isSelected = _selectedReportType == value;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedReportType = value;
          _updateDateRange();
        });
      },
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? color.withOpacity(0.2) : Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? color : Colors.black87,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: color, size: 28),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.date_range, color: Colors.deepPurple),
              SizedBox(width: 8),
              Text(
                'Période',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _selectStartDate(),
                  child: Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.deepPurple.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.calendar_today, size: 16, color: Colors.deepPurple),
                            SizedBox(width: 8),
                            Text(
                              'Date de début',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          DateFormat('dd/MM/yyyy').format(_startDate),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: GestureDetector(
                  onTap: () => _selectEndDate(),
                  child: Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.deepPurple.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.calendar_today, size: 16, color: Colors.deepPurple),
                            SizedBox(width: 8),
                            Text(
                              'Date de fin',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          DateFormat('dd/MM/yyyy').format(_endDate),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 18, color: Colors.amber.shade700),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Durée: ${_endDate.difference(_startDate).inDays + 1} jour(s)',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.amber.shade900,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExportFormatSelector() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.file_download, color: Colors.deepPurple),
              SizedBox(width: 8),
              Text(
                'Format d\'export',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildFormatCard('pdf', 'PDF', Icons.picture_as_pdf, Colors.red),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildFormatCard('csv', 'CSV', Icons.table_chart, Colors.green),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildFormatCard('both', 'Les deux', Icons.file_copy, Colors.blue),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFormatCard(String value, String label, IconData icon, Color color) {
    final isSelected = _exportFormat == value;

    return InkWell(
      onTap: () => setState(() => _exportFormat = value),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? color : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportPreview() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.preview, color: Colors.deepPurple),
              SizedBox(width: 8),
              Text(
                'Aperçu du rapport',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          SizedBox(height: 16),
          _buildPreviewContent(),
        ],
      ),
    );
  }

  Widget _buildPreviewContent() {
    final reportInfo = _getReportInfo();

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPreviewRow('Type de rapport', reportInfo['title']!),
          Divider(),
          _buildPreviewRow('Période', '${DateFormat('dd/MM/yyyy').format(_startDate)} - ${DateFormat('dd/MM/yyyy').format(_endDate)}'),
          Divider(),
          _buildPreviewRow('Durée', '${_endDate.difference(_startDate).inDays + 1} jour(s)'),
          Divider(),
          _buildPreviewRow('Format', _getFormatLabel()),
          Divider(),
          _buildPreviewRow('Contenu', reportInfo['content']!),
        ],
      ),
    );
  }

  Widget _buildPreviewRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: _generateReport,
            icon: Icon(Icons.download, size: 24),
            label: Text(
              'Générer et Télécharger',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 3,
            ),
          ),
        ),
        SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton.icon(
            onPressed: _printReport,
            icon: Icon(Icons.print, size: 24),
            label: Text(
              'Imprimer directement',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.deepPurple,
              side: BorderSide(color: Colors.deepPurple, width: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ========== MÉTHODES UTILITAIRES ==========

  void _updateDateRange() {
    final now = DateTime.now();
    setState(() {
      switch (_selectedReportType) {
        case 'daily':
          _startDate = DateTime(now.year, now.month, now.day);
          _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
          break;
        case 'weekly':
          _startDate = now.subtract(Duration(days: now.weekday - 1));
          _endDate = _startDate.add(Duration(days: 6, hours: 23, minutes: 59));
          break;
        case 'monthly':
          _startDate = DateTime(now.year, now.month, 1);
          _endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
          break;
        default:
          _startDate = DateTime(now.year, now.month, now.day);
          _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
      }
    });
  }

  Map<String, String> _getReportInfo() {
    switch (_selectedReportType) {
      case 'daily':
        return {
          'title': 'Rapport Journalier',
          'content': 'CA du jour, commandes, articles vendus, méthodes de paiement',
        };
      case 'weekly':
        return {
          'title': 'Rapport Hebdomadaire',
          'content': 'CA hebdo, évolution journalière, top articles, comparaisons',
        };
      case 'monthly':
        return {
          'title': 'Rapport Mensuel',
          'content': 'Synthèse mensuelle, tendances, statistiques complètes',
        };
      case 'transactions':
        return {
          'title': 'Rapport de Transactions',
          'content': 'Liste détaillée de toutes les transactions avec détails',
        };
      case 'inventory':
        return {
          'title': 'Rapport d\'Inventaire',
          'content': 'Articles vendus, quantités, chiffres par article',
        };
      case 'complete':
        return {
          'title': 'Rapport Complet',
          'content': 'Toutes les statistiques, graphiques, analyses détaillées',
        };
      default:
        return {'title': '', 'content': ''};
    }
  }

  String _getFormatLabel() {
    switch (_exportFormat) {
      case 'pdf':
        return 'PDF uniquement';
      case 'csv':
        return 'CSV uniquement';
      case 'both':
        return 'PDF + CSV';
      default:
        return '';
    }
  }

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: _endDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: Colors.deepPurple),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _startDate = picked);
    }
  }

  Future<void> _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate,
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: Colors.deepPurple),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _endDate = picked);
    }
  }

  // ========== GÉNÉRATION DES RAPPORTS ==========

  Future<void> _generateReport() async {
    if (_userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Erreur: Utilisateur non identifié')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Charger les données
      final data = await _loadReportData();

      // Générer selon le format
      if (_exportFormat == 'pdf' || _exportFormat == 'both') {
        await _generatePDF(data);
      }

      if (_exportFormat == 'csv' || _exportFormat == 'both') {
        await _generateCSV(data);
      }

      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('✅ Rapport généré avec succès'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur lors de la génération: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<Map<String, dynamic>> _loadReportData() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('restaurant_orders')
        .where('userId', isEqualTo: _userId)
        .where('status', isEqualTo: 'payée')
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(_startDate))
        .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(_endDate))
        .get();

    double totalRevenue = 0;
    int totalOrders = snapshot.docs.length;
    Map<String, double> paymentMethods = {};
    Map<String, int> itemsSold = {};
    List<Map<String, dynamic>> transactions = [];

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final order = RestaurantOrder.fromFirestore(doc);

      totalRevenue += (data['total'] as num).toDouble();

      // Méthodes de paiement
      final paymentMethod = data['paymentMethod'] as String? ?? 'Non spécifié';
      paymentMethods[paymentMethod] = (paymentMethods[paymentMethod] ?? 0) + (data['total'] as num).toDouble();

      // Articles vendus
      for (var item in order.items) {
        itemsSold[item.name] = (itemsSold[item.name] ?? 0) + item.quantity;
      }

      // Transactions
      transactions.add({
        'date': order.createdAt,
        'orderNumber': doc.id.substring(0, 8),
        'table': order.tableNumber,
        'customerType': order.customerType,
        'items': order.items.length,
        'total': order.total,
        'paymentMethod': order.paymentMethod,
      });
    }

    return {
      'totalRevenue': totalRevenue,
      'totalOrders': totalOrders,
      'averageOrder': totalOrders > 0 ? totalRevenue / totalOrders : 0,
      'paymentMethods': paymentMethods,
      'itemsSold': itemsSold,
      'transactions': transactions,
    };
  }

  Future<void> _generatePDF(Map<String, dynamic> data) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // En-tête
            pw.Header(
              level: 0,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    _getReportInfo()['title']!,
                    style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'Période: ${DateFormat('dd/MM/yyyy').format(_startDate)} - ${DateFormat('dd/MM/yyyy').format(_endDate)}',
                    style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
                  ),
                  pw.Text(
                    'Généré le: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
                    style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
                  ),
                  pw.Divider(thickness: 2),
                ],
              ),
            ),

            // Statistiques principales
            pw.SizedBox(height: 20),
            pw.Text('Résumé', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            _buildPDFStatRow('Chiffre d\'affaires total', '${data['totalRevenue'].toStringAsFixed(0)} FCFA'),
            _buildPDFStatRow('Nombre de commandes', '${data['totalOrders']}'),
            _buildPDFStatRow('Ticket moyen', '${data['averageOrder'].toStringAsFixed(0)} FCFA'),

            // Méthodes de paiement
            pw.SizedBox(height: 20),
            pw.Text('Répartition par méthode de paiement', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            ...((data['paymentMethods'] as Map<String, double>).entries.map((entry) {
              return _buildPDFStatRow(entry.key, '${entry.value.toStringAsFixed(0)} FCFA');
            }).toList()),

            // Articles vendus
            if (_selectedReportType == 'inventory' || _selectedReportType == 'complete') ...[
              pw.SizedBox(height: 20),
              pw.Text('Articles vendus', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              ...((data['itemsSold'] as Map<String, int>).entries.take(20).map((entry) {
                return _buildPDFStatRow(entry.key, '${entry.value} unités');
              }).toList()),
            ],

            // Transactions
            if (_selectedReportType == 'transactions' || _selectedReportType == 'complete') ...[
              pw.SizedBox(height: 20),
              pw.Text('Détail des transactions', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Table.fromTextArray(
                headers: ['Date', 'N°', 'Table', 'Articles', 'Total'],
                data: (data['transactions'] as List<Map<String, dynamic>>).map((transaction) {
                  return [
                    DateFormat('dd/MM HH:mm').format(transaction['date']),
                    transaction['orderNumber'],
                    transaction['table'],
                    '${transaction['items']}',
                    '${transaction['total'].toStringAsFixed(0)} F',
                  ];
                }).toList(),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                cellAlignment: pw.Alignment.centerLeft,
              ),
            ],
          ];
        },
      ),
    );

    // ✅ FLUTTER WEB : Téléchargement direct du PDF
    final bytes = await pdf.save();
    final blob = html.Blob([bytes], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', 'rapport_${_selectedReportType}_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf')
      ..click();
    html.Url.revokeObjectUrl(url);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text('✅ PDF téléchargé avec succès'),
          ],
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

  pw.Widget _buildPDFStatRow(String label, String value) {
    return pw.Padding(
      padding: pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: 12)),
          pw.Text(value, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  Future<void> _generateCSV(Map<String, dynamic> data) async {
    List<List<dynamic>> rows = [];

    if (_selectedReportType == 'transactions' || _selectedReportType == 'complete') {
      // En-tête
      rows.add(['Date', 'Heure', 'Numéro', 'Table', 'Type Client', 'Articles', 'Total', 'Paiement']);

      // Données
      for (var transaction in (data['transactions'] as List<Map<String, dynamic>>)) {
        final date = transaction['date'] as DateTime;
        rows.add([
          DateFormat('dd/MM/yyyy').format(date),
          DateFormat('HH:mm').format(date),
          transaction['orderNumber'],
          transaction['table'],
          transaction['customerType'],
          transaction['items'],
          transaction['total'].toStringAsFixed(2),
          transaction['paymentMethod'],
        ]);
      }
    } else {
      // Rapport résumé
      rows.add(['Type', 'Valeur']);
      rows.add(['Chiffre d\'affaires', data['totalRevenue'].toStringAsFixed(2)]);
      rows.add(['Commandes', data['totalOrders']]);
      rows.add(['Ticket moyen', data['averageOrder'].toStringAsFixed(2)]);
      rows.add([]);
      rows.add(['Méthode de paiement', 'Montant']);
      (data['paymentMethods'] as Map<String, double>).forEach((key, value) {
        rows.add([key, value.toStringAsFixed(2)]);
      });
    }

    String csv = const ListToCsvConverter().convert(rows);

    // ✅ FLUTTER WEB : Téléchargement direct du CSV
    final bytes = utf8.encode(csv);
    final blob = html.Blob([bytes], 'text/csv');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', 'rapport_${_selectedReportType}_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv')
      ..click();
    html.Url.revokeObjectUrl(url);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text('✅ CSV téléchargé avec succès'),
          ],
        ),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _printReport() async {
    if (_userId == null) return;

    setState(() => _isLoading = true);

    try {
      final data = await _loadReportData();

      // Créer le PDF
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return [
              // En-tête
              pw.Header(
                level: 0,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      _getReportInfo()['title']!,
                      style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'Période: ${DateFormat('dd/MM/yyyy').format(_startDate)} - ${DateFormat('dd/MM/yyyy').format(_endDate)}',
                      style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
                    ),
                    pw.Text(
                      'Généré le: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
                      style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
                    ),
                    pw.Divider(thickness: 2),
                  ],
                ),
              ),

              // Statistiques principales
              pw.SizedBox(height: 20),
              pw.Text('Résumé', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              _buildPDFStatRow('Chiffre d\'affaires total', '${data['totalRevenue'].toStringAsFixed(0)} FCFA'),
              _buildPDFStatRow('Nombre de commandes', '${data['totalOrders']}'),
              _buildPDFStatRow('Ticket moyen', '${data['averageOrder'].toStringAsFixed(0)} FCFA'),

              // Méthodes de paiement
              pw.SizedBox(height: 20),
              pw.Text('Répartition par méthode de paiement', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              ...((data['paymentMethods'] as Map<String, double>).entries.map((entry) {
                return _buildPDFStatRow(entry.key, '${entry.value.toStringAsFixed(0)} FCFA');
              }).toList()),

              // Articles vendus
              if (_selectedReportType == 'inventory' || _selectedReportType == 'complete') ...[
                pw.SizedBox(height: 20),
                pw.Text('Articles vendus', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 10),
                ...((data['itemsSold'] as Map<String, int>).entries.take(20).map((entry) {
                  return _buildPDFStatRow(entry.key, '${entry.value} unités');
                }).toList()),
              ],

              // Transactions
              if (_selectedReportType == 'transactions' || _selectedReportType == 'complete') ...[
                pw.SizedBox(height: 20),
                pw.Text('Détail des transactions', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 10),
                pw.Table.fromTextArray(
                  headers: ['Date', 'N°', 'Table', 'Articles', 'Total'],
                  data: (data['transactions'] as List<Map<String, dynamic>>).map((transaction) {
                    return [
                      DateFormat('dd/MM HH:mm').format(transaction['date']),
                      transaction['orderNumber'],
                      transaction['table'],
                      '${transaction['items']}',
                      '${transaction['total'].toStringAsFixed(0)} F',
                    ];
                  }).toList(),
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  cellAlignment: pw.Alignment.centerLeft,
                ),
              ],
            ];
          },
        ),
      );

      // ✅ FLUTTER WEB : Ouvrir la boîte de dialogue d'impression
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'rapport_${_selectedReportType}_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
      );

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur lors de l\'impression: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}