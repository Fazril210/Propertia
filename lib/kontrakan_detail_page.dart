import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

class KontrakanDetailPage extends StatelessWidget {
  final Database database;

  const KontrakanDetailPage({Key? key, required this.database}) : super(key: key);

  Future<List<Map<String, dynamic>>> _fetchProperties() async {
    return await database.query('properties');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Kontrakan', style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold, color: Colors.white),),
        backgroundColor: Colors.blue,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchProperties(),
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
                'Tidak ada data kontrakan.',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            );
          } else {
            final properties = snapshot.data!;
            return ListView.builder(
              itemCount: properties.length,
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) {
                final property = properties[index];
                return _buildPropertyCard(property);
              },
            );
          }
        },
      ),
    );
  }

  Widget _buildPropertyCard(Map<String, dynamic> property) {
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
            // Ikon kontrakan
            Container(
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(12),
              child: const Icon(
                Icons.home,
                size: 32,
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 16),
            // Informasi kontrakan
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    property['name'] ?? 'Nama tidak tersedia',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    property['address'] ?? 'Alamat tidak tersedia',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
