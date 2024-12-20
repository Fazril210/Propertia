import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

class TambahKontrakanPage extends StatefulWidget {
  final Database database;
  final Map<String, dynamic>? kontrakan;
  final Map<String, dynamic>? room;

  const TambahKontrakanPage({
    Key? key,
    required this.database,
    this.kontrakan,
    this.room,
  }) : super(key: key);

  @override
  State<TambahKontrakanPage> createState() => _TambahKontrakanPageState();
}

class _TambahKontrakanPageState extends State<TambahKontrakanPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();

    if (widget.kontrakan != null) {
      _nameController.text = widget.kontrakan!['name'] ?? '';
      _addressController.text = widget.kontrakan!['address'] ?? '';
    }

    if (widget.room != null) {
      _priceController.text = widget.room!['price'].toString();
      _descriptionController.text = widget.room!['description'] ?? '';
    }
  }

  Future<void> _saveKontrakan() async {
    if (_formKey.currentState!.validate()) {
      if (widget.kontrakan == null) {
        await widget.database.insert('properties', {
          'name': _nameController.text,
          'address': _addressController.text,
        });
      } else {
        await widget.database.update(
          'properties',
          {
            'name': _nameController.text,
            'address': _addressController.text,
          },
          where: 'id = ?',
          whereArgs: [widget.kontrakan!['id']],
        );
      }
      Navigator.pop(context);
    }
  }

  Future<void> _saveRoom() async {
    if (_formKey.currentState!.validate()) {
      if (widget.room == null) {
        await widget.database.insert('rooms', {
          'property_id': widget.kontrakan!['id'],
          'price': int.parse(_priceController.text),
          'description': _descriptionController.text,
        });
      } else {
        await widget.database.update(
          'rooms',
          {
            'price': int.parse(_priceController.text),
            'description': _descriptionController.text,
          },
          where: 'id = ?',
          whereArgs: [widget.room!['id']],
        );
      }
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRoomMode = widget.room != null || widget.kontrakan != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.room == null
              ? (widget.kontrakan == null ? 'Tambah Kontrakan' : 'Tambah Kamar')
              : 'Edit Kamar',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 25, color: Colors.white),
        ),
        backgroundColor: Colors.blue,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isRoomMode) ...[ // Input untuk Kontrakan
                const Text(
                  'Informasi Kontrakan',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Nama Kontrakan',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Nama tidak boleh kosong'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _addressController,
                  decoration: InputDecoration(
                    labelText: 'Alamat Kontrakan',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Alamat tidak boleh kosong'
                      : null,
                ),
              ],
              if (isRoomMode) ...[ // Input untuk Kamar
                const Text(
                  'Informasi Kamar',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Harga Kamar',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Harga tidak boleh kosong'
                      : int.tryParse(value) == null
                          ? 'Harga harus berupa angka'
                          : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Nomor Kamar',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Nomor tidak boleh kosong'
                      : null,
                ),
              ],
              const SizedBox(height: 24),
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: isRoomMode ? _saveRoom : _saveKontrakan,
                  child: Text(
                    widget.room == null
                        ? (widget.kontrakan == null
                            ? 'Simpan Kontrakan'
                            : 'Simpan Kamar')
                        : 'Perbarui Kamar',
                    style: const TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
