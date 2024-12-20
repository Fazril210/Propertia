import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title, required this.loggedInUser});

  final String title;
  final String loggedInUser;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with SingleTickerProviderStateMixin {
  int totalProperties = 10; // Dummy data
  int totalTenants = 20; // Dummy data
  int totalTransactions = 5; // Dummy data
  int totalRooms = 15; // Dummy data
  Map<String, double> monthlyTransactions = {
    "2023-01": 100000.0,
    "2023-02": 200000.0,
    "2023-03": 150000.0,
  }; // Dummy data

  @override
  Widget build(BuildContext context) {
    final String today = DateFormat.yMMMMd().format(DateTime.now());
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.green,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: screenWidth > 800
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sidebar untuk menu
                  SizedBox(
                    width: 300,
                    child: _buildSidebarMenu(),
                  ),
                  const SizedBox(width: 16),
                  // Konten utama
                  Expanded(child: _buildMainContent(today)),
                ],
              )
            : SingleChildScrollView(
                child: Column(
                  children: [
                    _buildUserInfo(today),
                    const SizedBox(height: 20),
                    _buildMenu(),
                    const SizedBox(height: 20),
                    _buildInformation(),
                    const SizedBox(height: 20),
                    _buildMonthlyChart(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildSidebarMenu() {
    final menuItems = [
      {'title': 'Dashboard', 'icon': Icons.dashboard, 'color': Colors.green},
      {'title': 'Kontrakan', 'icon': Icons.home, 'color': Colors.blue},
      {'title': 'Penyewa', 'icon': Icons.person, 'color': Colors.orange},
      {'title': 'Transaksi', 'icon': Icons.payment, 'color': Colors.red},
      {'title': 'Laporan', 'icon': Icons.bar_chart, 'color': Colors.purple},
    ];

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: menuItems.map((item) {
          return ListTile(
            leading: Icon(item['icon'] as IconData, color: item['color'] as Color),
            title: Text(item['title'] as String),
            onTap: () {
              // Handle navigation
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMainContent(String today) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildUserInfo(today),
          const SizedBox(height: 20),
          _buildInformation(),
          const SizedBox(height: 20),
          _buildMonthlyChart(),
        ],
      ),
    );
  }

  Widget _buildUserInfo(String today) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      color: Colors.green.shade300,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.white,
              child: Icon(Icons.person, size: 40, color: Colors.green.shade800),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pengguna: ${widget.loggedInUser}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tanggal: $today',
                  style: const TextStyle(fontSize: 16, color: Colors.white70),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenu() {
    final menuItems = [
      {'title': 'Kontrakan', 'icon': Icons.home, 'color': Colors.blue},
      {'title': 'Penyewa', 'icon': Icons.person, 'color': Colors.orange},
      {'title': 'Transaksi', 'icon': Icons.payment, 'color': Colors.red},
      {'title': 'Laporan', 'icon': Icons.bar_chart, 'color': Colors.purple},
    ];

    return GridView.builder(
      itemCount: menuItems.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemBuilder: (context, index) {
        final item = menuItems[index];
        return GestureDetector(
          onTap: () {
            // Handle menu click
          },
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            color: (item['color'] as Color).withOpacity(0.2),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(item['icon'] as IconData, size: 40, color: item['color'] as Color),
                  const SizedBox(height: 10),
                  Text(
                    item['title'] as String,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: item['color'] as Color,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInformation() {
    final data = [
      {'title': 'Kontrakan', 'value': totalProperties.toString(), 'color': Colors.blue},
      {'title': 'Penyewa', 'value': totalTenants.toString(), 'color': Colors.orange},
      {'title': 'Transaksi', 'value': totalTransactions.toString(), 'color': Colors.red},
      {'title': 'Kamar', 'value': totalRooms.toString(), 'color': Colors.purple},
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: data.map((item) {
        return Expanded(
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            color: (item['color'] as Color).withOpacity(0.2),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    item['title'] as String,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: item['color'] as Color,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    item['value'] as String,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: item['color'] as Color,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMonthlyChart() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pendapatan Per Bulan',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...monthlyTransactions.entries.map((entry) {
              final dateParts = entry.key.split('-');
              final month = DateFormat.MMMM('id').format(DateTime(0, int.parse(dateParts[1])));
              final year = dateParts[0];

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.green,
                  child: Text(
                    month[0],
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text('$month $year'),
                trailing: Text(
                  'Rp ${NumberFormat("#,##0").format(entry.value)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
