import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';
import 'package:intl/intl.dart';
import 'tambah_kontrakan_page.dart';

class KontrakanPage extends StatefulWidget {
  const KontrakanPage({Key? key}) : super(key: key);

  @override
  State<KontrakanPage> createState() => _KontrakanPageState();
}

class _KontrakanPageState extends State<KontrakanPage> {
  late Database database;
  List<Map<String, dynamic>> kontrakanList = [];

  @override
  void initState() {
    super.initState();
    _initializeDatabase();
  }

  Future<void> _initializeDatabase() async {
    final dbPath = path.join(await getDatabasesPath(), 'property_database.db');
    database = await openDatabase(
      dbPath,
      version: 3,
      onCreate: (db, version) async {
        await db.execute(
          'CREATE TABLE properties('
          'id INTEGER PRIMARY KEY AUTOINCREMENT, '
          'name TEXT, '
          'address TEXT'
          ')',
        );
        await db.execute(
          'CREATE TABLE rooms('
          'id INTEGER PRIMARY KEY AUTOINCREMENT, '
          'property_id INTEGER, '
          'price INTEGER, '
          'description TEXT, '
          'FOREIGN KEY(property_id) REFERENCES properties(id) ON DELETE CASCADE'
          ')',
        );
      },
    );
    _loadKontrakan();
  }

  Future<void> _loadKontrakan() async {
    final data = await database.query('properties');
    setState(() {
      kontrakanList = data;
    });
  }

  Future<List<Map<String, dynamic>>> _loadRooms(int propertyId) async {
    return await database.query('rooms', where: 'property_id = ?', whereArgs: [propertyId]);
  }

  Future<void> _deleteKontrakan(int id) async {
    final confirm = await _showDeleteConfirmation('Kontrakan');
    if (confirm) {
      await database.delete('properties', where: 'id = ?', whereArgs: [id]);
      _loadKontrakan();
    }
  }

  Future<void> _deleteRoom(int roomId) async {
    final confirm = await _showDeleteConfirmation('Kamar');
    if (confirm) {
      await database.delete('rooms', where: 'id = ?', whereArgs: [roomId]);
      _loadKontrakan();
    }
  }

  Future<bool> _showDeleteConfirmation(String type) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text('Hapus $type'),
              content: Text('Apakah Anda yakin ingin menghapus $type ini?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Batal'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Hapus'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  String _formatRupiah(int value) {
    final formatter = NumberFormat.currency(locale: 'id', symbol: 'Rp', decimalDigits: 0);
    return formatter.format(value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Kontrakan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25, color: Colors.white),),
        backgroundColor: Colors.blue,
        centerTitle: true,
        elevation: 4,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: kontrakanList.isEmpty
          ? const Center(
              child: Text(
                'Belum ada data kontrakan.',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            )
          : ListView.builder(
              itemCount: kontrakanList.length,
              itemBuilder: (context, index) {
                final kontrakan = kontrakanList[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 3,
                  child: ExpansionTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.home, size: 30, color: Colors.blue),
                    ),
                    title: Text(
                      kontrakan['name'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Text(
                      kontrakan['address'],
                      style: const TextStyle(color: Colors.grey),
                    ),
                    children: [
                      FutureBuilder<List<Map<String, dynamic>>>(
                        future: _loadRooms(kontrakan['id']),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: CircularProgressIndicator(),
                            );
                          } else if (snapshot.hasError) {
                            return const Text('Error loading rooms');
                          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text('Tidak ada kamar'),
                            );
                          } else {
                            return Column(
                              children: snapshot.data!.map((room) {
                                return ListTile(
                                  title: Text('Kamar: ${room['description']}'),
                                  subtitle: Text('Harga: ${_formatRupiah(room['price'])}'),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit, color: Colors.orange),
                                        onPressed: () async {
                                          await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => TambahKontrakanPage(
                                                database: database,
                                                room: room,
                                              ),
                                            ),
                                          );
                                          _loadKontrakan();
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () => _deleteRoom(room['id']),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            );
                          }
                        },
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => TambahKontrakanPage(
                                    database: database,
                                    kontrakan: kontrakan,
                                  ),
                                ),
                              );
                              _loadKontrakan();
                            },
                            child: const Text('Tambah Kamar'),
                          ),
                          TextButton(
                            onPressed: () => _deleteKontrakan(kontrakan['id']),
                            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
  onPressed: () async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TambahKontrakanPage(database: database),
      ),
    );
    _loadKontrakan();
  },
  backgroundColor: Colors.blue,
  icon: const Icon(Icons.add, color: Colors.white),
  label: const Text(
    "Tambah Kontrakan",
    style: TextStyle(color: Colors.white),
  ),
),

    );
  }
}
