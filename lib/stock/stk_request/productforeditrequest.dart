import 'dart:convert';

import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import '../../utility/my_constant.dart';
import '../cat.dart';
import '../group_sub.dart';
import '../group_sub_2.dart';
import '../groupmain.dart';
import '../pettern.dart';
import 'productforeditdetail.dart';

class ProductForEditRequest extends StatefulWidget {
  final String wh_code, sh_code, doc_no, doc_date;
  const ProductForEditRequest({
    super.key,
    required this.wh_code,
    required this.sh_code,
    required this.doc_no,
    required this.doc_date,
  });

  @override
  State<ProductForEditRequest> createState() => _ProductForEditRequestState();
}

class _ProductForEditRequestState extends State<ProductForEditRequest> {
  var data = [];
  String filter = 'all';
  TextEditingController txtQuery = TextEditingController();
  String? group_main = '',
      group_sub = '',
      group_sun_2 = '',
      cat_code = '',
      brand_code = '',
      pattern_code = '';
  TextEditingController group_main_name = TextEditingController();
  TextEditingController group_sub_name = TextEditingController();
  TextEditingController group_sub_name_2 = TextEditingController();
  TextEditingController cat = TextEditingController();
  TextEditingController brand = TextEditingController();
  TextEditingController petten = TextEditingController();
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    showdata();
  }

  Future<void> showdata() async {
    setState(() => isLoading = true);
    try {
      String datas = json.encode({
        "wh_code": widget.wh_code,
        "sh_code": widget.sh_code,
        "group_main": group_main,
        "group_sub": group_sub,
        "group_sub_2": group_sun_2,
        "cat": cat_code,
        "pattern": pattern_code,
        "item_brand": brand_code,
        "query": txtQuery.text,
      });
      var response = await post(
        Uri.parse("${MyConstant().domain}/vanstockforrequest"),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: datas,
      );
      if (response.statusCode == 200) {
        var result = json.decode(response.body);
        setState(() => data = result['list']);
      }
    } catch (e) {
      print("Error: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> scan() async {
    try {
      var barcode = await BarcodeScanner.scan();
      setState(() {
        txtQuery.text = barcode.rawContent;
      });
      showdata();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 600;
    final crossAxisCount = isTablet ? 4 : 2;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "ລາຍການສິນຄ້າ",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.deepOrange,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextFormField(
              controller: txtQuery,
              decoration: InputDecoration(
                hintText: "ຄົ້ນຫາສິນຄ້າ",
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.qr_code_scanner_sharp),
                  onPressed: scan,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onFieldSubmitted: (_) => showdata(),
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : data.isEmpty
                ? const Center(child: Text("ບໍ່ພົບຂໍ້ມູນ"))
                : GridView.builder(
                    padding: const EdgeInsets.all(10),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 0.7,
                    ),
                    itemCount: data.length,
                    itemBuilder: (context, index) {
                      final item = data[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ProductForEditDetail(
                                item_code: item['ic_code'],
                                item_name: item['ic_name'],
                                unit_code: item['ic_unit_code'],
                                barcode: item['barcode'],
                                qty: item['balance_qty'],
                                doc_no: widget.doc_no,
                                doc_date: widget.doc_date,
                                wh_code: widget.wh_code,
                                sh_code: widget.sh_code,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.3),
                                blurRadius: 5,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(12),
                                ),
                                child: Image.network(
                                  item['image_url'] ??
                                      'https://via.placeholder.com/200',
                                  height: 100,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(
                                        Icons.image_not_supported,
                                        size: 50,
                                      ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['ic_name'],
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'ຄົງເຫຼືອ: ${item['balance_qty']}',
                                      style: const TextStyle(
                                        color: Colors.deepOrange,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
