import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class PenyewaPage extends StatefulWidget {
  final Database database;

  const PenyewaPage({Key? key, required this.database}) : super(key: key);

  @override
  State<PenyewaPage> createState() => _PenyewaPageState();
}

class _PenyewaPageState extends State<PenyewaPage> {
  List<Map<String, dynamic>> tenantList = [];
  List<Map<String, dynamic>> filteredTenantList = [];
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTenants();
    searchController.addListener(() {
      _filterTenants(searchController.text);
    });
  }

  Future<void> _loadTenants() async {
    final tenants = await widget.database.rawQuery('''
      SELECT tenants.*, 
             properties.name AS property_name, 
             rooms.description AS room_description
      FROM tenants
      LEFT JOIN properties ON tenants.property_id = properties.id
      LEFT JOIN rooms ON tenants.room_id = rooms.id
    ''');
    setState(() {
      tenantList = tenants;
      filteredTenantList = tenants; 
    });
  }

   void _filterTenants(String query) {
    final filtered = tenantList.where((tenant) {
      final name = tenant['name'].toString().toLowerCase();
      final phone = tenant['phone'].toString().toLowerCase();
      final propertyName = tenant['property_name'].toString().toLowerCase();
      return name.contains(query.toLowerCase()) ||
          phone.contains(query.toLowerCase()) ||
          propertyName.contains(query.toLowerCase());
    }).toList();
    setState(() {
      filteredTenantList = filtered;
    });
  }

  Future<void> _saveTenant(Map<String, dynamic> tenant) async {
    try {
      await widget.database.insert('tenants', tenant);
      await _loadTenants();
      print("Data penyewa berhasil disimpan");
    } catch (e) {
      print("Error menyimpan data penyewa: $e");
    }
  }

  Future<void> _editTenant(int id, Map<String, dynamic> updatedTenant) async {
    try {
      await widget.database.update(
        'tenants',
        updatedTenant,
        where: 'id = ?',
        whereArgs: [id],
      );
      await _loadTenants();
      print("Data penyewa berhasil diperbarui");
    } catch (e) {
      print("Error memperbarui data penyewa: $e");
    }
  }

  Future<void> _deleteTenant(int id) async {
    final confirm = await _showDeleteConfirmation();
    if (confirm) {
      await widget.database.delete('tenants', where: 'id = ?', whereArgs: [id]);
      _loadTenants();
    }
  }

  Future<bool> _showDeleteConfirmation() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Hapus Penyewa'),
              content:
                  const Text('Apakah Anda yakin ingin menghapus penyewa ini?'),
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

  void _showAddOrEditTenantDialog(BuildContext context, {Map<String, dynamic>? tenant}) {
  final nameController = TextEditingController(text: tenant?['name']);
  final phoneController = TextEditingController(text: tenant?['phone']);
  final occupationController = TextEditingController(text: tenant?['occupation']);
  int? selectedPropertyId = tenant?['property_id'];
  int? selectedRoomId = tenant?['room_id'];
  String? selectedGender = tenant?['gender'];

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              padding: EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      tenant == null ? 'Tambah Penyewa Baru' : 'Edit Data Penyewa',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepOrange[700],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 20),
                    _buildTextField(
                      controller: nameController,
                      label: 'Nama Penyewa',
                      icon: Icons.person,
                    ),
                    SizedBox(height: 12),
                    _buildTextField(
                      controller: phoneController,
                      label: 'Nomor Telepon',
                      icon: Icons.phone,
                      keyboardType: TextInputType.phone,
                    ),
                    SizedBox(height: 12),
                    _buildGenderDropdown(
                      value: selectedGender,
                      onChanged: (value) {
                        setDialogState(() {
                          selectedGender = value;
                        });
                      },
                    ),
                    SizedBox(height: 12),
                    _buildTextField(
                      controller: occupationController,
                      label: 'Pekerjaan',
                      icon: Icons.work,
                    ),
                    SizedBox(height: 12),
                    _buildPropertyDropdown(
                      selectedPropertyId: selectedPropertyId,
                      onChanged: (value) {
                        setDialogState(() {
                          selectedPropertyId = value;
                          selectedRoomId = null;
                        });
                      },
                    ),
                    SizedBox(height: 12),
                    if (selectedPropertyId != null)
                      _buildRoomDropdown(
                        selectedPropertyId: selectedPropertyId!,
                        selectedRoomId: selectedRoomId,
                        tenant: tenant,
                        onChanged: (value) {
                          setDialogState(() {
                            selectedRoomId = value;
                          });
                        },
                      ),
                    SizedBox(height: 20),
                    Row(
                      children: [
                        // Tombol Batal
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.deepOrange[600], // Warna teks deep orange
                              side: BorderSide(color: Colors.deepOrange[600]!),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: () => Navigator.pop(context),
                            child: Text('Batal'),
                          ),
                        ),
                        SizedBox(width: 12),
                        // Tombol Simpan
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepOrange[600], // Warna latar belakang deep orange
                              foregroundColor: Colors.white, // Warna teks putih
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: () async {
                              if (_validateInputs(
                                nameController.text,
                                phoneController.text,
                                selectedGender,
                                occupationController.text,
                                selectedPropertyId,
                                selectedRoomId,
                              )) {
                                final currentDate =
                                    DateFormat('yyyy-MM-dd').format(DateTime.now());
                                final tenantData = {
                                  'name': nameController.text,
                                  'phone': phoneController.text,
                                  'gender': selectedGender,
                                  'occupation': occupationController.text,
                                  'property_id': selectedPropertyId,
                                  'room_id': selectedRoomId,
                                  'date_rent': currentDate,
                                };
                                if (tenant == null) {
                                  await _saveTenant(tenantData);
                                } else {
                                  await _editTenant(tenant['id'], tenantData);
                                }
                                Navigator.pop(context);
                              } else {
                                _showValidationError(context);
                              }
                            },
                            child: Text(
                              tenant == null ? 'Simpan' : 'Perbarui',
                              style: TextStyle(color: Colors.white), // Warna teks putih
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}


  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.deepOrange[600]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.deepOrange[600]!)
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.deepOrange[600]!, width: 2)
        ),
      ),
    );
  }

  Widget _buildGenderDropdown({
    String? value,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: 'Jenis Kelamin',
        prefixIcon: Icon(Icons.people, color: Colors.deepOrange[600]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      hint: const Text('Pilih Jenis Kelamin'),
      onChanged: onChanged,
      items: const [
        DropdownMenuItem(
          value: 'Pria',
          child: Text('Pria'),
        ),
        DropdownMenuItem(
          value: 'Wanita',
          child: Text('Wanita'),
        ),
      ],
    );
  }

  Widget _buildPropertyDropdown({
    int? selectedPropertyId,
    required void Function(int?) onChanged,
  }) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: widget.database.query('properties'),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.deepOrange[600]!),
          );
        }
        final properties = snapshot.data!;
        return DropdownButtonFormField<int>(
          value: selectedPropertyId,
          decoration: InputDecoration(
            labelText: 'Pilih Kontrakan',
            prefixIcon: Icon(Icons.home, color: Colors.deepOrange[600]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          hint: const Text('Pilih Kontrakan'),
          onChanged: onChanged,
          items: properties.map((property) {
            return DropdownMenuItem<int>(
              value: property['id'],
              child: Text(property['name']),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildRoomDropdown({
    required int selectedPropertyId,
    int? selectedRoomId,
    Map<String, dynamic>? tenant,
    required void Function(int?) onChanged,
  }) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _getAvailableRooms(selectedPropertyId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.deepOrange[600]!),
          );
        }
        final rooms = snapshot.data!;
        
        // Add the previously selected room if it's not in the available rooms
        if (tenant != null && !rooms.any((room) => room['id'] == tenant['room_id'])) {
          final previousRoom = {'id': tenant['room_id'], 'description': tenant['room_description']};
          rooms.insert(0, previousRoom);
        }

        return DropdownButtonFormField<int>(
          value: selectedRoomId,
          decoration: InputDecoration(
            labelText: 'Pilih Kamar',
            prefixIcon: Icon(Icons.door_sliding, color: Colors.deepOrange[600]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          hint: const Text('Pilih Kamar'),
          onChanged: onChanged,
          items: rooms.map((room) {
            return DropdownMenuItem<int>(
              value: room['id'],
              child: Text(room['description']),
            );
          }).toList(),
        );
      },
    );
  }

  bool _validateInputs(
    String name, 
    String phone, 
    String? gender, 
    String occupation,
    int? propertyId,
    int? roomId
  ) {
    return name.isNotEmpty &&
           phone.isNotEmpty &&
           gender != null &&
           occupation.isNotEmpty &&
           propertyId != null &&
           roomId != null;
  }

  void _showValidationError(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16)
        ),
        title: Text(
          'Error', 
          style: TextStyle(color: Colors.red[600]),
        ),
        content: Text(
          'Semua field harus diisi!',
          style: TextStyle(color: Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK', 
              style: TextStyle(color: Colors.deepOrange[600]),
            ),
          ),
        ],
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _getAvailableRooms(int propertyId) async {
    final allRooms = await widget.database.query(
      'rooms',
      where: 'property_id = ?',
      whereArgs: [propertyId],
    );
    final occupiedRooms =
        await widget.database.query('tenants', columns: ['room_id']);
    final occupiedRoomIds =
        occupiedRooms.map((room) => room['room_id']).toSet();
    return allRooms
        .where((room) => !occupiedRoomIds.contains(room['id']))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Daftar Penyewa',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25, color: Colors.white),
        ),
        backgroundColor: Colors.deepOrange[600],
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // TextField untuk Searching
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                labelText: 'Cari Penyewa',
                prefixIcon: Icon(Icons.search, color: Colors.deepOrange[600]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.deepOrange[600]!),
                ),
              ),
            ),
          ),
          Expanded(
            child: filteredTenantList.isEmpty
                ? _buildEmptyState()
                : _buildTenantList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddOrEditTenantDialog(context),
        icon: Icon(Icons.add, color: Colors.white),
        label: Text('Tambah Penyewa', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.deepOrange[600],
      ),
    );
  }

  Widget _buildTenantList() {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: filteredTenantList.length,
      itemBuilder: (context, index) {
        final tenant = filteredTenantList[index];
        return _buildTenantCard(tenant);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_off_outlined, size: 100, color: Colors.grey[300]),
          SizedBox(height: 16),
          Text(
            'Belum Ada Data Penyewa',
            style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500),
          ),
          SizedBox(height: 8),
          Text(
            'Tekan tombol + untuk menambahkan penyewa baru',
            style: TextStyle(color: Colors.grey[500]),
            textAlign: TextAlign.center,
          )
        ],
      ),
    );
  }

  Widget _buildTenantCard(Map<String, dynamic> tenant) {
    return Card(
      elevation: 4,
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    tenant['name'],
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepOrange[700]),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit, color: Colors.blue),
                      onPressed: () =>
                          _showAddOrEditTenantDialog(context, tenant: tenant),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteTenant(tenant['id']),
                    ),
                  IconButton(
      icon: FaIcon(FontAwesomeIcons.whatsapp, color: Colors.green),
      onPressed: () => _sendWhatsAppMessage(tenant['name'],'kami ingin mengingatkan bahwa pembayaran sewa Anda telah jatuh tempo. Silakan segera melakukan pembayaran. Terima kasih.'),
    ),
                  ],
                )
              ],
            ),
            SizedBox(height: 8),
            _buildInfoRow(Icons.phone, 'Telepon', tenant['phone']),
            _buildInfoRow(
                Icons.calendar_today, 'Tanggal Sewa', tenant['date_rent']),
            _buildInfoRow(Icons.home, 'Kontrakan', tenant['property_name']),
            _buildInfoRow(
                Icons.door_sliding, 'Kamar', tenant['room_description']),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          SizedBox(width: 8),
          Text(
            '$label: ',
            style:
                TextStyle(fontWeight: FontWeight.w500, color: Colors.grey[700]),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Colors.black87),
              overflow: TextOverflow.ellipsis,
            ),
          )
        ],
      ),
    );
  }

Future<void> _sendWhatsAppMessage(String namaPenyewa, String message) async {
  try {
    // Open the SQLite database
    final Database db = await openDatabase('property_database.db');

    // Query the database for the phone number
    final List<Map<String, dynamic>> result = await db.query(
      'tenants', // Table name
      columns: ['phone'], // Column to fetch
      where: 'name = ?', // Query condition
      whereArgs: [namaPenyewa], // Arguments for the query
      limit: 1,
    );

    if (result.isNotEmpty) {
      // Get the phone number and format it
      String phoneNumber = '62' + result.first['phone'].toString().replaceAll('+', '');
      
      // Prepare the WhatsApp URL
      final whatsappUrl = Uri.parse("https://api.whatsapp.com/send?phone=$phoneNumber&text=${Uri.encodeComponent(message)}");

      // Check if WhatsApp is installed and can be launched
      if (await canLaunchUrl(whatsappUrl)) {
        await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
      } else {
        // Fallback if the URL can't be launched
        final fallbackUrl = Uri.parse(whatsappUrl.toString());
        await launchUrl(fallbackUrl, mode: LaunchMode.externalApplication);
      }
    } else {
      print('Phone number not found for $namaPenyewa');
    }
  } catch (e) {
    print('Error sending WhatsApp message: $e');
  }
}



}
