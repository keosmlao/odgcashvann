import 'dart:convert';
import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utility/my_constant.dart';
import '../utility/app_colors.dart';

class StockBalance extends StatefulWidget {
  const StockBalance({super.key});

  @override
  State<StockBalance> createState() => _StockBalanceState();
}

class _StockBalanceState extends State<StockBalance> {
  final ScrollController _scroll = ScrollController();
  final TextEditingController _search = TextEditingController();

  List<dynamic> _data = [];
  int _offset = 0;
  final int _limit = 15;
  bool _loading = false;
  bool _hasMore = true;
  String _query = "";

  @override
  void initState() {
    super.initState();
    _fetch();
    _scroll.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 50 &&
        !_loading &&
        _hasMore) {
      _fetch();
    }
  }

  Future<void> _fetch() async {
    if (_loading) return;
    setState(() => _loading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final wh = prefs.getString('wh_code');
      final sh = prefs.getString('sh_code');

      if (wh?.isEmpty != false || sh?.isEmpty != false) {
        _error('ຂໍ້ມູນສາງບໍ່ຄົບຖ້ວນ');
        return;
      }

      final res = await http.post(
        Uri.parse('${MyConstant().domain}/vanstocksale'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "wh_code": wh,
          "sh_code": sh,
          "limit": _limit,
          "offset": _offset,
          "cust_group_1": "102",
          "search": _query.trim(),
        }),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final items = List<dynamic>.from(data['list'] ?? []);

        setState(() {
          _offset += _limit;
          _data.addAll(items);
          _hasMore = items.length == _limit;
        });
      } else {
        _error('ຂໍ້ຜິດພາດເຊີເວີ: ${res.statusCode}');
      }
    } catch (e) {
      _error('ເຊື່ອມຕໍ່ບໍ່ໄດ້: ${e.toString()}');
    } finally {
      setState(() => _loading = false);
    }
  }

  void _error(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg, style: const TextStyle(fontFamily: 'NotoSansLao')),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  void _searchItems(String q) {
    setState(() {
      _query = q;
      _offset = 0;
      _data.clear();
      _hasMore = true;
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      if (_query == q && mounted) _fetch();
    });
  }

  Future<void> _scan() async {
    try {
      final result = await BarcodeScanner.scan();
      if (result.rawContent.isNotEmpty) {
        _search.text = result.rawContent;
        _searchItems(result.rawContent);
      }
    } catch (e) {
      _error('ສະແກນລົ້ມເຫຼວ');
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _offset = 0;
      _data.clear();
      _hasMore = true;
    });
    await _fetch();
  }

  @override
  void dispose() {
    _scroll.dispose();
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Column(
        children: [
          // Modern Search Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _search,
                      onChanged: _searchItems,
                      style: const TextStyle(
                        fontFamily: 'NotoSansLao',
                        fontSize: 14,
                      ),
                      decoration: InputDecoration(
                        hintText: 'ຄົ້ນຫາສິນຄ້າ...',
                        hintStyle: TextStyle(
                          fontFamily: 'NotoSansLao',
                          color: Colors.grey.shade500,
                          fontSize: 14,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: Colors.grey.shade600,
                          size: 20,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: IconButton(
                    onPressed: _scan,
                    icon: const Icon(
                      Icons.qr_code_scanner,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content Area
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              color: AppColors.primaryBlue,
              child: _data.isEmpty && !_loading ? _buildEmpty() : _buildList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(60),
            ),
            child: Icon(
              Icons.inventory_2_outlined,
              size: 60,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _query.isEmpty ? "ຍັງບໍ່ມີຂໍ້ມູນສິນຄ້າ" : "ບໍ່ພົບສິນຄ້າ",
            style: const TextStyle(
              fontFamily: 'NotoSansLao',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _query.isEmpty ? "ດຶງລາຍການລົງມາເພື່ອເບິ່ງ" : "ລອງຄົ້ນຫາດ້ວຍຄຳອື່ນ",
            style: TextStyle(
              fontFamily: 'NotoSansLao',
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _data.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _data.length) {
          return Container(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: _loading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      "ສິ້ນສຸດລາຍການ",
                      style: TextStyle(
                        fontFamily: 'NotoSansLao',
                        color: Colors.grey.shade500,
                        fontSize: 13,
                      ),
                    ),
            ),
          );
        }

        return _buildItem(_data[index]);
      },
    );
  }

  Widget _buildItem(Map<String, dynamic> item) {
    final qty = double.tryParse(item['balance_qty']?.toString() ?? '0') ?? 0.0;
    final inStock = qty > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Status Indicator
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: inStock ? Colors.green : Colors.red.shade400,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(width: 16),

            // Product Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['ic_name'] ?? 'ບໍ່ມີຊື່',
                    style: const TextStyle(
                      fontFamily: 'NotoSansLao',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      item['ic_unit_code'] ?? 'N/A',
                      style: TextStyle(
                        fontFamily: 'NotoSansLao',
                        fontSize: 11,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Balance
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  qty.toStringAsFixed(0),
                  style: TextStyle(
                    fontFamily: 'NotoSansLao',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: inStock ? Colors.green : Colors.red.shade400,
                  ),
                ),
                Text(
                  'ຄົງເຫຼືອ',
                  style: TextStyle(
                    fontFamily: 'NotoSansLao',
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
