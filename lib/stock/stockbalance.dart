import 'dart:convert';
import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utility/my_constant.dart';
import '../utility/app_colors.dart'; // Assuming you have this from the previous interaction

class StockBalance extends StatefulWidget {
  const StockBalance({super.key});

  @override
  State<StockBalance> createState() => _StockBalanceState();
}

class _StockBalanceState extends State<StockBalance> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  List<dynamic> _allData = [];
  int _offset = 0;
  final int _limit = 10;
  bool _isLoading = false;
  bool _hasMore = true;
  String _searchQuery = "";

  // Define consistent text styles
  final TextStyle _titleTextStyle = const TextStyle(
    fontFamily: 'NotoSansLao',
    fontWeight: FontWeight.bold,
    fontSize: 16,
    color: AppColors.black87,
  );
  final TextStyle _subtitleTextStyle = const TextStyle(
    fontFamily: 'NotoSansLao',
    fontSize: 13,
    color: AppColors.textMutedColor,
  );
  final TextStyle _balanceTextStyle = const TextStyle(
    fontFamily: 'NotoSansLao',
    fontWeight: FontWeight.bold,
    fontSize: 15,
    color: AppColors.salesAccentColor, // Using green for positive balance
  );
  final TextStyle _noDataTextStyle = TextStyle(
    fontFamily: 'NotoSansLao',
    fontSize: 18,
    color: AppColors.textMutedColor,
    fontWeight: FontWeight.w500,
  );
  final TextStyle _loadingTextStyle = const TextStyle(
    fontFamily: 'NotoSansLao',
    fontSize: 14,
    color: AppColors.textMutedColor,
  );

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
    if (_isLoading) return; // Prevent multiple simultaneous fetches
    setState(() => _isLoading = true);

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? wh = prefs.getString('wh_code');
    String? sh = prefs.getString('sh_code');

    if (wh == null || wh.isEmpty || sh == null || sh.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'ຂໍ້ມູນສາງບໍ່ຄົບຖ້ວນ. ບໍ່ສາມາດໂຫຼດສິນຄ້າ.',
              style: TextStyle(
                fontFamily: 'NotoSansLao',
                color: AppColors.white,
              ),
            ),
            backgroundColor: AppColors.redAccent,
          ),
        );
      }
      setState(() => _isLoading = false);
      return;
    }

    try {
      final res = await http.post(
        Uri.parse('${MyConstant().domain}/vanstocksale'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "wh_code": wh,
          "sh_code": sh,
          "limit": _limit,
          "offset": _offset,
          // IMPORTANT: "cust_group_1": "102" might be too restrictive here.
          // For general stock balance, you might not want to filter by customer group.
          // Consider if this filter is truly needed for a "Stock Balance" screen.
          // If it is, keep it. If not, remove it for a broader stock view.
          "cust_group_1": "102", // Keep if this is a business requirement
          "search": _searchQuery.trim(),
        }),
      );

      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        final List<dynamic> newItems = json['list'] ?? [];

        setState(() {
          _offset += _limit;
          _allData.addAll(newItems);
          _hasMore =
              newItems.length ==
              _limit; // Check if less than limit, means no more data
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'ຂໍ້ຜິດພາດຈາກເຊີເວີ: ${res.statusCode}',
                style: const TextStyle(
                  fontFamily: 'NotoSansLao',
                  color: AppColors.white,
                ),
              ),
              backgroundColor: AppColors.redAccent,
            ),
          );
        }
        print("Server error: ${res.statusCode} - ${res.body}");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'ເກີດຂໍ້ຜິດພາດໃນການເຊື່ອມຕໍ່: $e',
              style: const TextStyle(
                fontFamily: 'NotoSansLao',
                color: AppColors.white,
              ),
            ),
            backgroundColor: AppColors.redAccent,
          ),
        );
      }
      print("Network error: $e");
    }

    setState(() => _isLoading = false);
  }

  void _applyFilter(String query) {
    setState(() {
      _searchQuery = query;
      _offset = 0;
      _allData.clear();
      _hasMore = true; // Assume there's more until proven otherwise
    });
    // Add a small delay for better user experience for typing search
    // This prevents too many rapid API calls
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_searchQuery == query) {
        // Only fetch if query hasn't changed during delay
        _fetchStock();
      }
    });
  }

  Future<void> _scanBarcode() async {
    try {
      var result = await BarcodeScanner.scan();
      if (result.rawContent.isNotEmpty) {
        _searchController.text = result.rawContent;
        _applyFilter(result.rawContent);
      }
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'ການສະແກນຖືກຍົກເລີກ ຫຼື ເກີດຂໍ້ຜິດພາດ: $e',
              style: const TextStyle(
                fontFamily: 'NotoSansLao',
                color: AppColors.white,
              ),
            ),
            backgroundColor: AppColors.orangeAccent,
          ),
        );
      }
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
      backgroundColor: AppColors.lightBlue,

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
                onChanged: (value) => _applyFilter(
                  value,
                ), // Use onChanged directly with _applyFilter
                decoration: InputDecoration(
                  hintText: 'ຄົ້ນຫາສິນຄ້າ...',
                  hintStyle: _subtitleTextStyle,
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AppColors.primaryBlue,
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(
                      Icons.qr_code_scanner,
                      color: AppColors.primaryBlue,
                    ),
                    onPressed: _scanBarcode,
                  ),
                  filled: true,
                  fillColor: AppColors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.primaryBlue,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: _allData.isEmpty && !_isLoading
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 80,
                            color: AppColors.grey300,
                          ),
                          const SizedBox(height: 20),
                          Text(
                            _searchQuery.isEmpty
                                ? "ຍັງບໍ່ມີຂໍ້ມູນສິນຄ້າ."
                                : "ບໍ່ພົບສິນຄ້າສໍາລັບ '${_searchQuery}'.",
                            style: _noDataTextStyle,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _searchQuery.isEmpty
                                ? "ລອງດຶງຂໍ້ມູນລົງມາເພີ່ມ."
                                : "ລອງຄົ້ນຫາດ້ວຍຄໍາອື່ນ.",
                            style: _subtitleTextStyle,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      itemCount: _allData.length + (_hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index >= _allData.length) {
                          return Padding(
                            padding: const EdgeInsets.all(16),
                            child: Center(
                              child: _isLoading
                                  ? const CircularProgressIndicator(
                                      color: AppColors.primaryBlue,
                                    )
                                  : Text(
                                      "ບໍ່ມີສິນຄ້າເພີ່ມເຕີມ",
                                      style: _loadingTextStyle,
                                    ),
                            ),
                          );
                        }

                        final item = _allData[index];
                        final double balanceQty =
                            double.tryParse(
                              item['balance_qty']?.toString() ?? '0.0',
                            ) ??
                            0.0;
                        final Color balanceColor = balanceQty > 0
                            ? AppColors.salesAccentColor
                            : AppColors.redAccent;

                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          elevation:
                              3, // Add more elevation for a floating effect
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              15,
                            ), // More rounded corners
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(
                              16.0,
                            ), // Increase padding
                            child: Row(
                              children: [
                                // Leading icon
                                Icon(
                                  Icons
                                      .category_outlined, // Or Icons.inventory_2_outlined
                                  color: AppColors.primaryBlue,
                                  size: 28,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item['ic_name'] ?? 'ບໍ່ມີຊື່ສິນຄ້າ',
                                        style: _titleTextStyle,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "ຫົວໜ່ວຍ: ${item['ic_unit_code'] ?? 'N/A'}",
                                        style: _subtitleTextStyle,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                // Balance quantity
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      "ຄົງເຫຼືອ:",
                                      style: _subtitleTextStyle,
                                    ),
                                    Text(
                                      balanceQty.toStringAsFixed(
                                        0,
                                      ), // Display as integer if no decimals are needed
                                      style: _balanceTextStyle.copyWith(
                                        color: balanceColor,
                                      ),
                                    ),
                                  ],
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
      ),
    );
  }
}
