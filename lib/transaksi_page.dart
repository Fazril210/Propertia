import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';

class TransaksiPage extends StatefulWidget {
  final Database database;

  const TransaksiPage({Key? key, required this.database}) : super(key: key);

  @override
  State<TransaksiPage> createState() => _TransaksiPageState();
}

class _TransaksiPageState extends State<TransaksiPage> {
  List<Map<String, dynamic>> transaksiList = [];
  List<Map<String, dynamic>> filteredTransaksiList = [];
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTransaksi();
    searchController.addListener(() {
      _filterTransaksi(searchController.text);
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTransaksi() async {
    final result = await widget.database.rawQuery('''
      SELECT transactions.*, tenants.name AS tenant_name
      FROM transactions
      LEFT JOIN tenants ON transactions.tenant_id = tenants.id
      ORDER BY payment_date DESC
    ''');
    setState(() {
      transaksiList = result;
      filteredTransaksiList = result;
    });
  }

  void _filterTransaksi(String query) {
    final filtered = transaksiList.where((transaksi) {
      final tenantName = transaksi['tenant_name'].toString().toLowerCase();
      final description = transaksi['description'].toString().toLowerCase();
      final paymentDate = transaksi['payment_date'].toString().toLowerCase();
      return tenantName.contains(query.toLowerCase()) ||
          description.contains(query.toLowerCase()) ||
          paymentDate.contains(query.toLowerCase());
    }).toList();
    setState(() {
      filteredTransaksiList = filtered;
    });
  }

  Future<void> _saveTransaksi(Map<String, dynamic> transaksi) async {
    try {
      await widget.database.insert('transactions', transaksi);
      await _loadTransaksi();
      print("Transaksi berhasil disimpan.");
    } catch (e) {
      print("Error menyimpan transaksi: $e");
    }
  }

  Future<void> _deleteTransaksi(int id) async {
    final confirm = await _showDeleteConfirmation();
    if (confirm) {
      await widget.database.delete('transactions', where: 'id = ?', whereArgs: [id]);
      _loadTransaksi();
    }
  }

  Future<bool> _showDeleteConfirmation() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              title: Text(
                'Hapus Transaksi',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red[700],
                ),
              ),
              content: const Text(
                'Apakah Anda yakin ingin menghapus transaksi ini?',
                style: TextStyle(color: Colors.black87),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(
                    'Batal',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[700],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text(
                    'Hapus',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  void _showAddTransaksiDialog() {
    int? selectedTenantId;
    double? roomPrice;
    final descriptionController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(25),
        ),
      ),
      backgroundColor: Colors.white,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Tambah Transaksi Baru',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[800],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    FutureBuilder<List<Map<String, dynamic>>>(
                      future: widget.database.rawQuery('''
                        SELECT tenants.id AS tenant_id, 
                               tenants.name AS tenant_name, 
                               rooms.price AS room_price
                        FROM tenants
                        LEFT JOIN rooms ON tenants.room_id = rooms.id
                      '''),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        final tenants = snapshot.data!;
                        return Column(
                          children: [
                            DropdownButtonFormField<int>(
                              decoration: InputDecoration(
                                labelText: 'Pilih Penyewa',
                                labelStyle: TextStyle(color: Colors.green[700]),
                                filled: true,
                                fillColor: Colors.green.shade50,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide: BorderSide.none,
                                ),
                                prefixIcon: Icon(
                                  Icons.person_outline,
                                  color: Colors.green[700],
                                ),
                              ),
                              value: selectedTenantId,
                              onChanged: (value) {
                                final selectedTenant = tenants.firstWhere(
                                    (tenant) => tenant['tenant_id'] == value);
                                setDialogState(() {
                                  selectedTenantId = value;
                                  roomPrice = selectedTenant['room_price'] != null
                                      ? double.parse(selectedTenant['room_price'].toString())
                                      : 0.0;
                                });
                              },
                              items: tenants.map((tenant) {
                                return DropdownMenuItem<int>(
                                  value: tenant['tenant_id'],
                                  child: Text(
                                    '${tenant['tenant_name']} - Rp ${tenant['room_price'] ?? '0'}',
                                    style: TextStyle(color: Colors.green[800]),
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 15),
                            TextField(
                              controller: TextEditingController(
                                text: roomPrice != null
                                    ? NumberFormat.currency(
                                        locale: 'id_ID', symbol: 'Rp ').format(roomPrice)
                                    : '',
                              ),
                              readOnly: true,
                              decoration: InputDecoration(
                                labelText: 'Jumlah Pembayaran',
                                labelStyle: TextStyle(color: Colors.green[700]),
                                prefixIcon: Icon(
                                  Icons.monetization_on_outlined,
                                  color: Colors.green[700],
                                ),
                                filled: true,
                                fillColor: Colors.green.shade50,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                            const SizedBox(height: 15),
                            TextField(
                              controller: descriptionController,
                              decoration: InputDecoration(
                                labelText: 'Catatan Tambahan',
                                labelStyle: TextStyle(color: Colors.green[700]),
                                prefixIcon: Icon(
                                  Icons.notes,
                                  color: Colors.green[700],
                                ),
                                filled: true,
                                fillColor: Colors.green.shade50,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green[700],
                                padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                              onPressed: () async {
                                if (selectedTenantId != null && roomPrice != null) {
                                  final transaksiData = {
                                    'tenant_id': selectedTenantId,
                                    'amount': roomPrice,
                                    'payment_date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
                                    'description': descriptionController.text,
                                  };
                                  await _saveTransaksi(transaksiData);
                                  Navigator.pop(context);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Pilih penyewa terlebih dahulu',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      backgroundColor: Colors.red.shade400,
                                    ),
                                  );
                                }
                              },
                              child: const Text(
                                'Simpan Transaksi',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'Transaksi',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 25,
            color: Colors.white,
            letterSpacing: 1.1,
          ),
        ),
        backgroundColor: Colors.green[700],
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(70),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: 'Cari Transaksi...',
                  hintStyle: TextStyle(color: Colors.green[300]),
                  prefixIcon: Icon(Icons.search, color: Colors.green[700]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredTransaksiList.length,
        itemBuilder: (context, index) {
          final transaksi = filteredTransaksiList[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.receipt_long,
                  color: Colors.green[700],
                ),
              ),
              title: Text(
                'Penyewa: ${transaksi['tenant_name']}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green[800],
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    'Jumlah: ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ').format(transaksi['amount'])}',
                    style: TextStyle(color: Colors.green[700]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tanggal: ${transaksi['payment_date']}',
                    style: TextStyle(color: Colors.green[600]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Deskripsi: ${transaksi['description']}',
                    style: TextStyle(color: Colors.green[600]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              trailing: IconButton(
                icon: Icon(
                  Icons.delete_forever_rounded,
                  color: Colors.red[700],
                ),
                onPressed: () => _deleteTransaksi(transaksi['id']),
              ),
            ),
          );
        },
      ),
    floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddTransaksiDialog,
        backgroundColor: Colors.green[700],
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        icon: const Icon(
          Icons.add,
          color: Colors.white,
        ),
        label: const Text(
          'Tambah Transaksi',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}