import 'dart:convert';
import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:http/http.dart' as http;
import 'package:odgcashvan/POS/stockdetailsale.dart';
import 'package:odgcashvan/stock/group_sub.dart';
import 'package:odgcashvan/stock/group_sub_2.dart';
import 'package:odgcashvan/utility/my_constant.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../stock/brand.dart';
import '../stock/cat.dart';
import '../stock/groupmain.dart';
import '../stock/pettern.dart';
import '../utility/my_style.dart';
import 'product_filter_modal.dart'; // Ensure this file exists and contains the ProductFilterModal

class StockSale extends StatefulWidget {
  final String custcode; // Use 'final' for StatefulWidget properties
  const StockSale({super.key, required this.custcode});

  @override
  State<StockSale> createState() => _StockSaleState();
}

class _StockSaleState extends State<StockSale> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  List<dynamic> _allData = [];
  int _offset = 0;
  final int _limit = 10;
  bool _isLoading = false;
  bool _hasMore = true;
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _fetchStock();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 100 &&
          !_isLoading &&
          _hasMore) {
        _fetchStock();
      }
    });
  }

  Future<void> _fetchStock() async {
    setState(() => _isLoading = true);

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? wh = prefs.getString('wh_code');
    String? sh = prefs.getString('sh_code');

    try {
      final res = await http.post(
        Uri.parse('${MyConstant().domain}/vanstocksale'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "wh_code": wh,
          "sh_code": sh,
          "limit": _limit,
          "offset": _offset,
          "cust_group_1": "102",
          "search": _searchQuery.trim(),
        }),
      );

      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        final List<dynamic> newItems = json['list'] ?? [];

        setState(() {
          _offset += _limit;
          _allData.addAll(newItems);
          _hasMore = newItems.length == _limit;
        });
      } else {
        print("Server error: ${res.statusCode} - ${res.body}");
      }
    } catch (e) {
      print("Network error: $e");
    }

    setState(() => _isLoading = false);
  }

  void _applyFilter(String query) {
    setState(() {
      _searchQuery = query;
      _offset = 0;
      _allData.clear();
      _hasMore = true;
    });
    _fetchStock();
  }

  Future<void> _scanBarcode() async {
    var result = await BarcodeScanner.scan();
    if (result.rawContent.isNotEmpty) {
      _searchController.text = result.rawContent;
      _applyFilter(result.rawContent);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("ສີນຄ້າສຳລັບຂາຍ")),
      backgroundColor: const Color(0xFFE3F2FD),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _offset = 0;
            _allData.clear();
            _hasMore = true;
          });
          await _fetchStock();
        },
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: _searchController,
                onChanged: _applyFilter,
                decoration: InputDecoration(
                  hintText: 'ຄົ້ນຫາສິນຄ້າ...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.qr_code_scanner),
                    onPressed: _scanBarcode,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                itemCount: _allData.length + (_hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index >= _allData.length) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final item = _allData[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    child: ListTile(
                      title: Text(item['ic_name'] ?? ''),
                      subtitle: Text(
                        "ຄົງເຫຼືອ: ${item['balance_qty']} | ຫົວໜ່ວຍ: ${item['ic_unit_code']}",
                      ),
                      trailing: Text(
                        '${item['sale_price'] ?? '0'} ',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      onTap: () async {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => StockDetailSale(
                              custcode: widget.custcode,
                              item_code: item['ic_code'],
                              barcode: item['barcode'],
                              item_name: item['ic_name'],
                              unit_code: item['ic_unit_code'],
                              averageCost: item['average_cost'],
                              qty: item['balance_qty'],
                              salePrice: item['sale_price'],
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
