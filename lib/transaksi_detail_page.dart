import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Untuk format tanggal dan angka
import 'package:sqflite/sqflite.dart';

class TransaksiDetailPage extends StatelessWidget {
  final Database database;

  const TransaksiDetailPage({Key? key, required this.database}) : super(key: key);

  Future<List<Map<String, dynamic>>> _fetchTransactions() async {
    return await database.query('transactions');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Transaksi', style: TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.bold),),
        backgroundColor: Colors.green,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchTransactions(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'Tidak ada data transaksi.',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            );
          } else {
            final transactions = snapshot.data!;
            return ListView.builder(
              itemCount: transactions.length,
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) {
                final transaction = transactions[index];
                return _buildTransactionCard(transaction);
              },
            );
          }
        },
      ),
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> transaction) {
    // Format tanggal dan jumlah uang
    final String formattedDate = _formatDate(transaction['payment_date']);
    final String formattedAmount =
        'Rp ${NumberFormat("#,##0", "id_ID").format(transaction['amount'] ?? 0)}';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Ikon transaksi
            Container(
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(12),
              child: const Icon(
                Icons.payment,
                size: 32,
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 16),
            // Informasi transaksi
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Transaksi ID: ${transaction['id']}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Jumlah: $formattedAmount',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tanggal: $formattedDate',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Deskripsi: ${transaction['description'] ?? "Tidak ada deskripsi"}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  String _formatDate(String? date) {
    if (date == null || date.isEmpty) return "Tidak diketahui";
    try {
      final parsedDate = DateTime.parse(date);
      return DateFormat('dd MMM yyyy', 'id_ID').format(parsedDate);
    } catch (e) {
      return "Format tanggal tidak valid";
    }
  }
}
