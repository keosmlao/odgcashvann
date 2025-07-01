import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utility/my_constant.dart';
import '../Sale/imagePrint.dart';
// import เหมือนเดิมทั้งหมด

class SaleInvoice extends StatefulWidget {
  const SaleInvoice({super.key});
  @override
  State<SaleInvoice> createState() => _SaleInvoiceState();
}

class _SaleInvoiceState extends State<SaleInvoice> {
  TextEditingController dateInput = TextEditingController();
  List<dynamic> data = [];
  DateTime now = DateTime.now();
  final formatter = DateFormat('yyyy-MM-dd');
  bool isLoading = false;

  double get totalSales => data.fold(
        0,
        (sum, item) => sum + double.parse(item['total_amount']),
      );

  @override
  void initState() {
    super.initState();
    dateInput.text = DateFormat('dd-MM-yyyy').format(now);
    showData(formatter.format(now));
  }

  Future<void> showData(String dateStr) async {
    setState(() => isLoading = true);
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var payload = json.encode({
      "sale_code": prefs.getString('usercode') ?? '',
      "doc_date": dateStr,
    });
    try {
      var response = await post(
        Uri.parse("${MyConstant().domain}/listinvoice"),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: payload,
      );
      var result = json.decode(response.body);
      setState(() {
        data = result['list'] ?? [];
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      print("Error: $e");
    }
  }

  Color getStatusColor(String status) {
    switch (status) {
      case 'ສຳເລັດ':
        return Colors.green.shade600;
      case 'ຄ້າງຊຳລະ':
        return Colors.red.shade300;
      default:
        return Colors.orange.shade400;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF4E6),
      appBar: AppBar(
        title: const Text("ບິນຂາຍປະຈຳວັນ"),
        centerTitle: true,
        backgroundColor: const Color(0xFFFF6F3C),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // 🔶 วันที่ + ปุ่ม Refresh
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: dateInput,
                    readOnly: true,
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      hintText: 'ເລືອກວັນທີ',
                      prefixIcon: const Icon(Icons.calendar_today),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: now,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        dateInput.text =
                            DateFormat('dd-MM-yyyy').format(picked);
                        showData(formatter.format(picked));
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.deepOrange),
                  onPressed: () => showData(formatter.format(now)),
                )
              ],
            ),
          ),

          // 🔶 กล่องสรุปยอดรวม
          if (!isLoading && data.isNotEmpty)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFF914D),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.attach_money, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "ຍອດຂາຍລວມ: ${NumberFormat('#,##0').format(totalSales)} ₭",
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    ),
                  )
                ],
              ),
            ),

          // 🔶 รายการบิล
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : data.isEmpty
                    ? const Center(child: Text("ບໍ່ມີຂໍ້ມູນ"))
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: data.length,
                        itemBuilder: (context, index) {
                          final inv = data[index];
                          return Card(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            elevation: 3,
                            color: Colors.white,
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Header Row
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text("📄 ${inv['doc_no']}",
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16)),
                                      Chip(
                                        label: Text(inv['status']),
                                        backgroundColor:
                                            getStatusColor(inv['status']),
                                        labelStyle: const TextStyle(
                                            color: Colors.white),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text("🗓 ວັນທີ: ${inv['doc_date']}"),
                                  Text("📦 ລາຍການ: ${inv['count_item']}"),
                                  Text(
                                    "💰 ລວມ: ${NumberFormat('#,##0').format(double.parse(inv['total_amount']))} ₭",
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 6),
                                  ListView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: inv['list'].length,
                                    itemBuilder: (context, i) {
                                      final item = inv['list'][i];
                                      return Text(
                                        '• ${item['item_name']} ${item['qty']} ${item['unit_code']}',
                                        style: TextStyle(
                                          color: item['remark'] == 'free'
                                              ? Colors.orange
                                              : Colors.green.shade800,
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 10),
                                  if (inv['status'] == 'ສຳເລັດ')
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: FilledButton.icon(
                                        icon: const Icon(Icons.print),
                                        label: const Text("ພິມບິນ"),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => PrintImage(
                                                  doc_no: inv['doc_no']),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          )
        ],
      ),
    );
  }
}
