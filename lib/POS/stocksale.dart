import 'dart:convert';
import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:http/http.dart' as http;
import 'package:odgcashvan/POS/stockdetailsale.dart';
import 'package:odgcashvan/utility/my_constant.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ModernStockSale extends StatefulWidget {
  final String custcode;
  const ModernStockSale({super.key, required this.custcode});

  @override
  State<ModernStockSale> createState() => _ModernStockSaleState();
}

class _ModernStockSaleState extends State<ModernStockSale>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  late AnimationController _animationController;
  late AnimationController _searchAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _searchAnimation;

  List<dynamic> _allData = [];
  int _offset = 0;
  final int _limit = 15; // Increased for better performance
  bool _isLoading = false;
  bool _hasMore = true;
  String _searchQuery = "";
  bool _isSearchFocused = false;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _fetchStock();
    _setupScrollListener();
  }

  void _initAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _searchAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutQuart),
    );

    _searchAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _searchAnimationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _animationController.forward();
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !_isLoading &&
          _hasMore) {
        _fetchStock();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchAnimationController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchStock() async {
    if (_isLoading) return;
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
          if (_offset == _limit) {
            _allData = newItems; // First load
          } else {
            _allData.addAll(newItems); // Append for pagination
          }
          _hasMore = newItems.length == _limit;
        });

        _animationController.reset();
        _animationController.forward();
      }
    } catch (e) {
      _showErrorSnackBar('ເກີດຂໍ້ຜິດພາດໃນການໂຫຼດຂໍ້ມູນ');
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

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontFamily: 'NotoSansLao', fontSize: 13),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
    );
  }

  Future<void> _scanBarcode() async {
    try {
      HapticFeedback.lightImpact();
      var result = await BarcodeScanner.scan();
      if (result.rawContent.isNotEmpty) {
        _searchController.text = result.rawContent;
        _applyFilter(result.rawContent);
      }
    } catch (e) {
      _showErrorSnackBar('ບໍ່ສາມາດສະແກນບາໂຄດໄດ້');
    }
  }

  Widget _buildModernSearchBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.white, Color(0xFFF8FAFC)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _applyFilter,
        onTap: () {
          setState(() => _isSearchFocused = true);
          _searchAnimationController.forward();
        },
        onEditingComplete: () {
          setState(() => _isSearchFocused = false);
          _searchAnimationController.reverse();
          FocusScope.of(context).unfocus();
        },
        style: const TextStyle(
          fontFamily: 'NotoSansLao',
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: 'ຄົ້ນຫາສິນຄ້າ, ບາໂຄດ...',
          hintStyle: const TextStyle(
            fontFamily: 'NotoSansLao',
            color: Color(0xFF9CA3AF),
            fontSize: 14,
          ),
          prefixIcon: AnimatedBuilder(
            animation: _searchAnimation,
            builder: (context, child) {
              return Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _isSearchFocused
                        ? [const Color(0xFF3B82F6), const Color(0xFF1E40AF)]
                        : [const Color(0xFF9CA3AF), const Color(0xFF6B7280)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.search_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              );
            },
          ),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_searchController.text.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    _searchController.clear();
                    _applyFilter('');
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      color: Color(0xFFEF4444),
                      size: 16,
                    ),
                  ),
                ),
              GestureDetector(
                onTap: _scanBarcode,
                child: Container(
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.qr_code_scanner_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
          filled: true,
          fillColor: Colors.transparent,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildCompactProductCard(Map<String, dynamic> item, int index) {
    final double balanceQty =
        double.tryParse(item['balance_qty']?.toString() ?? '0') ?? 0;
    final double salePrice =
        double.tryParse(item['sale_price']?.toString() ?? '0') ?? 0;
    final bool isLowStock = balanceQty < 10;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: TweenAnimationBuilder(
        duration: Duration(milliseconds: 300 + (index * 50)),
        tween: Tween<double>(begin: 0, end: 1),
        builder: (context, double value, child) {
          return Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: Opacity(
              opacity: value,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ModernStockDetailSale(
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
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Product Icon/Avatar
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isLowStock
                                    ? [
                                        const Color(0xFFEF4444),
                                        const Color(0xFFDC2626),
                                      ]
                                    : [
                                        const Color(0xFF059669),
                                        const Color(0xFF047857),
                                      ],
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              isLowStock
                                  ? Icons.inventory_2_outlined
                                  : Icons.shopping_bag_outlined,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Product Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['ic_name'] ?? '',
                                  style: const TextStyle(
                                    fontFamily: 'NotoSansLao',
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: Color(0xFF111827),
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isLowStock
                                            ? const Color(
                                                0xFFEF4444,
                                              ).withOpacity(0.1)
                                            : const Color(
                                                0xFF059669,
                                              ).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        '${balanceQty.toInt()} ${item['ic_unit_code'] ?? ''}',
                                        style: TextStyle(
                                          fontFamily: 'NotoSansLao',
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: isLowStock
                                              ? const Color(0xFFEF4444)
                                              : const Color(0xFF059669),
                                        ),
                                      ),
                                    ),
                                    if (isLowStock) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 4,
                                          vertical: 1,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFEF4444),
                                          borderRadius: BorderRadius.circular(
                                            3,
                                          ),
                                        ),
                                        child: const Text(
                                          'ໜ້ອຍ',
                                          style: TextStyle(
                                            fontFamily: 'NotoSansLao',
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // Price & Action
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${salePrice.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontFamily: 'NotoSansLao',
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF059669),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF3B82F6),
                                      Color(0xFF1E40AF),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'ເລືອກ',
                                  style: TextStyle(
                                    fontFamily: 'NotoSansLao',
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).primaryColor,
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'ກຳລັງໂຫຼດ...',
            style: TextStyle(
              fontFamily: 'NotoSansLao',
              fontSize: 13,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF6B7280).withOpacity(0.1),
                    const Color(0xFF6B7280).withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.inventory_outlined,
                size: 40,
                color: Color(0xFF9CA3AF),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'ບໍ່ພົບສິນຄ້າ',
              style: TextStyle(
                fontFamily: 'NotoSansLao',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'ລອງຄົ້ນຫາດ້ວຍຄໍາສັບອື່ນ',
              style: TextStyle(
                fontFamily: 'NotoSansLao',
                fontSize: 13,
                color: Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // Modern Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1E40AF), Color(0xFF3B82F6)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF3B82F6).withOpacity(0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'ສິນຄ້າສຳລັບຂາຍ',
                      style: TextStyle(
                        fontFamily: 'NotoSansLao',
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_allData.length}',
                      style: const TextStyle(
                        fontFamily: 'NotoSansLao',
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Search Bar
            _buildModernSearchBar(),

            // Content
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  setState(() {
                    _offset = 0;
                    _allData.clear();
                    _hasMore = true;
                  });
                  await _fetchStock();
                },
                color: const Color(0xFF3B82F6),
                child: _allData.isEmpty && !_isLoading
                    ? _buildEmptyState()
                    : ListView.builder(
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount:
                            _allData.length + (_hasMore && _isLoading ? 1 : 0),
                        padding: const EdgeInsets.only(bottom: 16),
                        itemBuilder: (context, index) {
                          if (index >= _allData.length) {
                            return _buildLoadingIndicator();
                          }
                          return _buildCompactProductCard(
                            _allData[index],
                            index,
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
