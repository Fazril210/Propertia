  import 'package:flutter/material.dart';
  import 'package:intl/intl.dart';
  import 'package:pdf/pdf.dart';
  import 'package:pdf/widgets.dart' as pw;
  import 'package:printing/printing.dart';
  import 'package:sqflite/sqflite.dart';

  class LaporanPage extends StatefulWidget {
    final Database database;

    const LaporanPage({Key? key, required this.database}) : super(key: key);

    @override
    State<LaporanPage> createState() => _LaporanPageState();
  }

  class _LaporanPageState extends State<LaporanPage> {
    DateTime? _startDate;
    DateTime? _endDate;
    List<Map<String, dynamic>> _reportData = [];
    double _totalAmount = 0.0;

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text(
            'Laporan Transaksi',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 25,
              color: Colors.white
            ),
          ),
          backgroundColor: Colors.red.shade600,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.red.shade50,
                Colors.red.shade100,
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Date Range Picker with Modern Design
                _buildDatePickers(),
                const SizedBox(height: 20),
                
                // Load Report Button
                ElevatedButton(
                  onPressed: _loadReport,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 3,
                  ),
                  child: const Text(
                    'Tampilkan Laporan',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                
                // Report Table
                Expanded(
                  child: _buildReportTable(),
                ),
                const SizedBox(height: 20),
                
                // PDF Export Button
                Center(
                  child: ElevatedButton.icon(
                    onPressed: _generatePDF,
                    icon: const Icon(Icons.picture_as_pdf, color: Colors.white,),
                    label: const Text('Cetak Laporan PDF', style: TextStyle(color: Colors.white),),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Date Pickers with Modern Design
    Widget _buildDatePickers() {
      return Row(
        children: [
          Expanded(
            child: _buildDatePickerCard(
              context, 
              title: 'Tanggal Mulai',
              date: _startDate,
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
                  builder: (context, child) {
                    return Theme(
                      data: ThemeData.light().copyWith(
                        colorScheme: ColorScheme.light(
                          primary: Colors.red.shade600,
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (picked != null) {
                  setState(() {
                    _startDate = picked;
                  });
                }
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildDatePickerCard(
              context, 
              title: 'Tanggal Akhir',
              date: _endDate,
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
                  builder: (context, child) {
                    return Theme(
                      data: ThemeData.light().copyWith(
                        colorScheme: ColorScheme.light(
                          primary: Colors.red.shade600,
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (picked != null) {
                  setState(() {
                    _endDate = picked;
                  });
                }
              },
            ),
          ),
        ],
      );
    }

    // Modern Date Picker Card
    Widget _buildDatePickerCard(
      BuildContext context, {
      required String title,
      required DateTime? date,
      required VoidCallback onTap,
    }) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.red.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.red.shade100.withOpacity(0.5),
                spreadRadius: 1,
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.calendar_today, color: Colors.red.shade600),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  date != null
                      ? DateFormat('yyyy-MM-dd').format(date)
                      : title,
                  style: TextStyle(
                    color: date != null ? Colors.red.shade900 : Colors.red.shade600,
                    fontWeight: date != null ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Load Report Method (unchanged)
    Future<void> _loadReport() async {
      if (_startDate == null || _endDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pilih rentang tanggal terlebih dahulu!')),
        );
        return;
      }

      final result = await widget.database.rawQuery('''
        SELECT transactions.id, tenants.name AS tenant_name, 
              transactions.amount, transactions.payment_date, transactions.description
        FROM transactions
        LEFT JOIN tenants ON transactions.tenant_id = tenants.id
        WHERE DATE(transactions.payment_date) BETWEEN ? AND ?
        ORDER BY transactions.payment_date ASC
      ''', [
        DateFormat('yyyy-MM-dd').format(_startDate!),
        DateFormat('yyyy-MM-dd').format(_endDate!),
      ]);

      setState(() {
        _reportData = result;
        _totalAmount = _reportData.fold(0.0, (sum, item) {
          return sum + (item['amount'] as num).toDouble();
        });
      });
    }

    // Modern Report Table
    Widget _buildReportTable() {
      if (_reportData.isEmpty) {
        return Center(
          child: Text(
            'Tidak ada data laporan.',
            style: TextStyle(
              color: Colors.red.shade600,
              fontSize: 16,
            ),
          ),
        );
      }

      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.red.shade100.withOpacity(0.5),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: MaterialStateColor.resolveWith(
                      (states) => Colors.red.shade50,
                    ),
                    columns: [
                      DataColumn(
                        label: Text(
                          'No',
                          style: TextStyle(
                            color: Colors.red.shade800,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Penyewa',
                          style: TextStyle(
                            color: Colors.red.shade800,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Jumlah',
                          style: TextStyle(
                            color: Colors.red.shade800,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Tanggal',
                          style: TextStyle(
                            color: Colors.red.shade800,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Deskripsi',
                          style: TextStyle(
                            color: Colors.red.shade800,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                    rows: List<DataRow>.generate(
                      _reportData.length,
                      (index) {
                        final item = _reportData[index];
                        return DataRow(
                          color: MaterialStateColor.resolveWith(
                            (states) => index % 2 == 0 
                              ? Colors.white 
                              : Colors.red.shade50.withOpacity(0.5),
                          ),
                          cells: [
                            DataCell(Text('${index + 1}')),
                            DataCell(Text(item['tenant_name'] ?? '-')),
                            DataCell(Text('Rp ${NumberFormat("#,##0").format(item['amount'])}')),
                            DataCell(Text(item['payment_date'] ?? '-')),
                            DataCell(Text(item['description'] ?? '-')),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Total Pendapatan: Rp ${NumberFormat("#,##0").format(_totalAmount)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade800,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Generate PDF Method (unchanged)
    Future<void> _generatePDF() async {
      if (_reportData.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak ada data untuk dicetak.')),
        );
        return;
      }

      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(24),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(
                  child: pw.Text(
                    'Laporan Transaksi',
                    style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  'Tanggal Cetak: ${DateFormat('yyyy-MM-dd').format(DateTime.now())}',
                  style: const pw.TextStyle(fontSize: 12),
                ),
                pw.Text(
                  'Periode: ${DateFormat('yyyy-MM-dd').format(_startDate!)} s/d ${DateFormat('yyyy-MM-dd').format(_endDate!)}',
                  style: const pw.TextStyle(fontSize: 12),
                ),
                pw.Divider(),
                pw.SizedBox(height: 10),
                pw.Table.fromTextArray(
                  border: pw.TableBorder.all(width: 0.5),
                  cellAlignment: pw.Alignment.centerLeft,
                  headerStyle: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                  headerDecoration: const pw.BoxDecoration(color: PdfColors.blue),
                  headers: ['No', 'Penyewa', 'Jumlah', 'Tanggal', 'Deskripsi'],
                  data: List<List<String>>.generate(_reportData.length, (index) {
                    final item = _reportData[index];
                    return [
                      '${index + 1}',
                      item['tenant_name'] ?? '-',
                      'Rp ${NumberFormat("#,##0").format(item['amount'])}',
                      item['payment_date'] ?? '-',
                      item['description'] ?? '-',
                    ];
                  }),
                ),
                pw.SizedBox(height: 10),
                pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Text(
                    'Total Pendapatan: Rp ${NumberFormat("#,##0").format(_totalAmount)}',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.green,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );
    }
  }