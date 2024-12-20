import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

class PenyewaDetailPage extends StatefulWidget {
  final Database database;

  const PenyewaDetailPage({Key? key, required this.database}) : super(key: key);

  @override
  _PenyewaDetailPageState createState() => _PenyewaDetailPageState();
}

class _PenyewaDetailPageState extends State<PenyewaDetailPage> {
  late Future<List<Map<String, dynamic>>> _tenantsFuture;
  List<Map<String, dynamic>> _allTenants = [];
  List<Map<String, dynamic>> _filteredTenants = [];
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _tenantsFuture = _fetchTenants();
  }

  Future<List<Map<String, dynamic>>> _fetchTenants() async {
    final tenants = await widget.database.query('tenants');
    _allTenants = tenants;
    _filteredTenants = tenants; // Default, semua data ditampilkan
    return tenants;
  }

  void _filterTenants(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      _filteredTenants = _allTenants.where((tenant) {
        final name = tenant['name']?.toString().toLowerCase() ?? '';
        final occupation = tenant['occupation']?.toString().toLowerCase() ?? '';
        final phone = tenant['phone']?.toString().toLowerCase() ?? '';
        return name.contains(_searchQuery) ||
            occupation.contains(_searchQuery) ||
            phone.contains(_searchQuery);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Daftar Penyewa',
          style: TextStyle(
            color: Colors.white,
            fontSize: 25,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.orange,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Field pencarian
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Cari penyewa...",
                prefixIcon: const Icon(Icons.search, color: Colors.orange),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.orange),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: _filterTenants,
            ),
          ),
          // Daftar penyewa
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _tenantsFuture,
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
                      'Tidak ada data penyewa.',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                  );
                } else {
                  return ListView.builder(
                    itemCount: _filteredTenants.length,
                    padding: const EdgeInsets.all(16),
                    itemBuilder: (context, index) {
                      final tenant = _filteredTenants[index];
                      return _buildTenantCard(tenant);
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTenantCard(Map<String, dynamic> tenant) {
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
            // Ikon penyewa
            Container(
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(12),
              child: const Icon(
                Icons.person,
                size: 32,
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 16),
            // Informasi penyewa
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tenant['name'] ?? 'Nama tidak tersedia',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Pekerjaan: ${tenant['occupation'] ?? "Tidak diketahui"}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Nomor HP: ${tenant['phone'] ?? "Tidak tersedia"}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Jenis Kelamin: ${tenant['gender'] ?? "Tidak diketahui"}',
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
