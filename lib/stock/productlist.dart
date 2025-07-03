import 'dart:convert';
import 'package:barcode_scan2/platform_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:odgcashvan/utility/my_constant.dart';
import '../database/sql_helper.dart';
import 'group_sub.dart';
import 'group_sub_2.dart';
import 'groupmain.dart';
import 'stockbalancefromsmldetail.dart';

class ProductList extends StatefulWidget {
  const ProductList({super.key});

  @override
  State<ProductList> createState() => _ProductListState();
}

class _ProductListState extends State<ProductList>
    with TickerProviderStateMixin {
  // Data Management
  List<Map<String, dynamic>> _allProducts = [];
  List<Map<String, dynamic>> _filteredProducts = [];

  // UI State
  bool _isLoading = false;
  bool _isSyncing = false;
  bool _isFilterExpanded = false;
  String _searchQuery = '';
  String _filterMode = 'all'; // 'all' or 'filter'

  // Controllers
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Filter Controllers
  final TextEditingController _groupMainController = TextEditingController();
  final TextEditingController _groupSubController = TextEditingController();
  final TextEditingController _groupSub2Controller = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _patternController = TextEditingController();
  final TextEditingController _brandController = TextEditingController();

  // Filter Values
  String? _groupMainCode = '';
  String? _groupSubCode = '';
  String? _groupSub2Code = '';
  String? _categoryCode = '';
  String? _patternCode = '';
  String? _brandCode = '';

  // Animation Controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _filterController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _filterAnimation;

  // Theme Colors
  static const Color primaryBlue = Color(0xFF2196F3);
  static const Color accentBlue = Color(0xFF1976D2);
  static const Color lightBlue = Color(0xFF64B5F6);
  static const Color darkBlue = Color(0xFF0D47A1);
  static const Color backgroundBlue = Color(0xFFF3F8FF);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color successGreen = Color(0xFF4CAF50);
  static const Color warningOrange = Color(0xFFFF9800);
  static const Color errorRed = Color(0xFFF44336);

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadProducts();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _filterController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    _disposeFilterControllers();
    super.dispose();
  }

  void _disposeFilterControllers() {
    _groupMainController.dispose();
    _groupSubController.dispose();
    _groupSub2Controller.dispose();
    _categoryController.dispose();
    _patternController.dispose();
    _brandController.dispose();
  }

  /// Initialize animations
  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _filterController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _filterAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _filterController, curve: Curves.easeInOut),
    );
  }

  /// Load products from database
  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);

    try {
      final data = await SQLHelper.getAllproduct();
      setState(() {
        _allProducts = data;
        _applyFilters();
        _isLoading = false;
      });

      _fadeController.forward();
      _slideController.forward();
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('ເກີດຂໍ້ຜິດພາດໃນການໂຫຼດຂໍ້ມູນ: $e', errorRed);
    }
  }

  /// Search functionality
  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
      _applyFilters();
    });
  }

  /// Apply all filters
  void _applyFilters() {
    List<Map<String, dynamic>> filtered = List.from(_allProducts);

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((product) {
        final barcode = (product['barcode'] ?? '').toString().toLowerCase();
        final itemName = (product['item_name'] ?? '').toString().toLowerCase();
        final itemCode = (product['item_code'] ?? '').toString().toLowerCase();
        return barcode.contains(query) ||
            itemName.contains(query) ||
            itemCode.contains(query);
      }).toList();
    }

    // Apply group filters if in filter mode
    if (_filterMode == 'filter') {
      if (_groupMainCode?.isNotEmpty == true) {
        filtered = filtered
            .where((p) => p['group_main'] == _groupMainCode)
            .toList();
      }
      if (_groupSubCode?.isNotEmpty == true) {
        filtered = filtered
            .where((p) => p['group_sub'] == _groupSubCode)
            .toList();
      }
      if (_groupSub2Code?.isNotEmpty == true) {
        filtered = filtered
            .where((p) => p['group_sub2'] == _groupSub2Code)
            .toList();
      }
      // Add more filter conditions as needed
    }

    setState(() {
      _filteredProducts = filtered;
    });
  }

  /// Barcode scanner
  Future<void> _scanBarcode() async {
    try {
      final result = await BarcodeScanner.scan();
      if (result.rawContent.isNotEmpty) {
        setState(() {
          _searchController.text = result.rawContent;
          _searchQuery = result.rawContent;
          _applyFilters();
        });
      }
    } on PlatformException catch (e) {
      if (e.code == BarcodeScanner.cameraAccessDenied) {
        _showSnackBar('ກະລຸນາອະນຸຍາດການເຂົ້າເຖິງກ້ອງຖ່າຍຮູບ', warningOrange);
      } else {
        _showSnackBar('ເກີດຂໍ້ຜິດພາດໃນການສະແກນ: ${e.message}', errorRed);
      }
    } catch (e) {
      _showSnackBar('ເກີດຂໍ້ຜິດພາດໃນການສະແກນ', errorRed);
    }
  }

  /// Sync data from API
  Future<void> _syncFromAPI() async {
    setState(() => _isSyncing = true);

    try {
      final response = await get(
        Uri.parse('${MyConstant().domain}/allproduct'),
        headers: {"Keep-Alive": "timeout=5, max=1"},
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        await SQLHelper.deleteAll();

        for (var item in result['list']) {
          await _addProductToDatabase(item);
        }

        await _loadProducts();
        _showSnackBar('ໂຫຼດຂໍ້ມູນສຳເລັດ', successGreen);
      } else {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      _showSnackBar('ເກີດຂໍ້ຜິດພາດໃນການໂຫຼດຈາກ SML: $e', errorRed);
    } finally {
      setState(() => _isSyncing = false);
    }
  }

  /// Add product to database
  Future<void> _addProductToDatabase(Map<String, dynamic> item) async {
    await SQLHelper.createInven(
      item['code'] ?? '',
      item['name_1'] ?? '',
      item['unit_cost'] ?? '',
      item['barcode'] ?? '',
      item['group_main'] ?? '',
      item['main_name'] ?? '',
      item['group_sub'] ?? '',
      item['sub_name'] ?? '',
      item['group_sub2'] ?? '',
      item['sub_name_2'] ?? '',
      item['item_brand'] ?? '',
      item['average_cost'] ?? '',
      item['item_pattern'] ?? '',
      item['pattern_name'] ?? '',
      item['cat_name'] ?? '',
      item['item_category'] ?? '',
    );
  }

  /// Reset all filters
  void _resetFilters() {
    setState(() {
      _filterMode = 'all';
      _groupMainCode = '';
      _groupSubCode = '';
      _groupSub2Code = '';
      _categoryCode = '';
      _patternCode = '';
      _brandCode = '';

      _groupMainController.clear();
      _groupSubController.clear();
      _groupSub2Controller.clear();
      _categoryController.clear();
      _patternController.clear();
      _brandController.clear();

      _applyFilters();
    });

    if (_isFilterExpanded) {
      _filterController.reverse();
      setState(() => _isFilterExpanded = false);
    }
  }

  /// Toggle filter section
  void _toggleFilter() {
    setState(() {
      _filterMode = _filterMode == 'all' ? 'filter' : 'all';
      _isFilterExpanded = !_isFilterExpanded;
    });

    if (_isFilterExpanded) {
      _filterController.forward();
    } else {
      _filterController.reverse();
      _resetFilters();
    }
  }

  /// Show snack bar
  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundBlue,
      body: RefreshIndicator(
        onRefresh: _loadProducts,
        color: primaryBlue,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            _buildAppBar(),
            _buildFilterSection(),
            _buildSearchSection(),
            _buildContentSection(),
          ],
        ),
      ),
    );
  }

  /// Build app bar
  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [primaryBlue, accentBlue, darkBlue],
            ),
          ),
        ),
        title: const Text(
          'ລາຍການສິນຄ້າ',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      backgroundColor: primaryBlue,
      iconTheme: const IconThemeData(color: Colors.white),
      actions: [
        IconButton(
          icon: Icon(
            _filterMode == 'filter'
                ? Icons.filter_alt
                : Icons.filter_alt_outlined,
            color: Colors.white,
          ),
          onPressed: _toggleFilter,
          tooltip: 'ກັ່ນຕອງ',
        ),
        IconButton(
          icon: _isSyncing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(Icons.cloud_sync, color: Colors.white),
          onPressed: _isSyncing ? null : _syncFromAPI,
          tooltip: 'ດຶງຈາກ SML',
        ),
      ],
    );
  }

  /// Build filter section
  Widget _buildFilterSection() {
    return SliverToBoxAdapter(
      child: AnimatedBuilder(
        animation: _filterAnimation,
        builder: (context, child) {
          return Container(
            height: _filterAnimation.value * 200,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [primaryBlue.withOpacity(0.1), backgroundBlue],
              ),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Opacity(
                opacity: _filterAnimation.value,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildFilterField(
                            'ກຸ່ມຫຼັກ',
                            _groupMainController,
                            Icons.category,
                            () => _selectGroupMain(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildFilterField(
                            'ກຸ່ມຍ່ອຍ 1',
                            _groupSubController,
                            Icons.subdirectory_arrow_right,
                            () => _selectGroupSub(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildFilterField(
                            'ກຸ່ມຍ່ອຍ 2',
                            _groupSub2Controller,
                            Icons.subdirectory_arrow_right,
                            () => _selectGroupSub2(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildFilterField(
                            'ໝວດ',
                            _categoryController,
                            Icons.label,
                            () => {},
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _resetFilters,
                            icon: const Icon(Icons.clear_all),
                            label: const Text('ລ້າງຕົວກອງ'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.grey.shade600,
                              side: BorderSide(color: Colors.grey.shade300),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              _applyFilters();
                              _showSnackBar('ໄດ້ນຳໃຊ້ຕົວກອງແລ້ວ', successGreen);
                            },
                            icon: const Icon(Icons.check),
                            label: const Text('ນຳໃຊ້'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryBlue,
                              foregroundColor: Colors.white,
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
      ),
    );
  }

  /// Build filter field
  Widget _buildFilterField(
    String hint,
    TextEditingController controller,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Container(
      height: 50,
      child: TextFormField(
        controller: controller,
        readOnly: true,
        onTap: onTap,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
          prefixIcon: Icon(icon, color: primaryBlue, size: 20),
          suffixIcon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: primaryBlue, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
        ),
      ),
    );
  }

  /// Build search section
  Widget _buildSearchSection() {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.all(16),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Container(
            decoration: BoxDecoration(
              color: cardBackground,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: primaryBlue.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'ຄົ້ນຫາລະຫັດ, ຊື່, ຫຼື barcode...',
                hintStyle: TextStyle(color: Colors.grey.shade500),
                prefixIcon: const Icon(Icons.search, color: primaryBlue),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_searchController.text.isNotEmpty)
                      IconButton(
                        icon: Icon(Icons.clear, color: Colors.grey.shade600),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged();
                        },
                      ),
                    IconButton(
                      icon: const Icon(
                        Icons.qr_code_scanner,
                        color: primaryBlue,
                      ),
                      onPressed: _scanBarcode,
                      tooltip: 'ສະແກນ Barcode',
                    ),
                  ],
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: backgroundBlue,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Build content section
  Widget _buildContentSection() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_filteredProducts.isEmpty) {
      return _buildEmptyState();
    }

    return _buildProductList();
  }

  /// Build loading state
  Widget _buildLoadingState() {
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(primaryBlue),
            ),
            const SizedBox(height: 16),
            Text(
              'ກຳລັງໂຫຼດຂໍ້ມູນ...',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  /// Build empty state
  Widget _buildEmptyState() {
    return SliverFillRemaining(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.inventory_2_outlined,
                size: 64,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                _searchQuery.isNotEmpty
                    ? 'ບໍ່ພົບສິນຄ້າທີ່ຄົ້ນຫາ'
                    : 'ບໍ່ມີຂໍ້ມູນສິນຄ້າ',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _searchQuery.isNotEmpty
                    ? 'ລອງໃຊ້ຄຳຄົ້ນຫາອື່ນ'
                    : 'ກົດປຸ່ມ "ດຶງຈາກ SML" ເພື່ອໂຫຼດຂໍ້ມູນ',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
              ),
              if (_searchQuery.isEmpty) ...[
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _syncFromAPI,
                  icon: const Icon(Icons.cloud_download),
                  label: const Text('ດຶງຂໍ້ມູນຈາກ SML'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Build product list
  Widget _buildProductList() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: _buildProductCard(_filteredProducts[index], index),
            ),
          );
        }, childCount: _filteredProducts.length),
      ),
    );
  }

  /// Build product card
  Widget _buildProductCard(Map<String, dynamic> product, int index) {
    final barcode = product['barcode']?.toString() ?? '';
    final itemCode = product['item_code']?.toString() ?? '';
    final itemName = product['item_name']?.toString() ?? '';
    final unitCost = product['unitCost']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _navigateToProductDetail(product),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with barcode status
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: barcode.isEmpty
                            ? errorRed.withOpacity(0.1)
                            : successGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        barcode.isEmpty ? 'ບໍ່ມີ Barcode' : 'ມີ Barcode',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: barcode.isEmpty ? errorRed : successGreen,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: primaryBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '#${index + 1}',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: primaryBlue,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Barcode
                if (barcode.isNotEmpty)
                  _buildInfoRow(Icons.qr_code, 'Barcode', barcode, primaryBlue),

                const SizedBox(height: 8),

                // Item code
                _buildInfoRow(Icons.tag, 'ລະຫັດສິນຄ້າ', itemCode, successGreen),

                const SizedBox(height: 8),

                // Item name
                _buildInfoRow(
                  Icons.inventory_2,
                  'ຊື່ສິນຄ້າ',
                  itemName,
                  darkBlue,
                ),

                const SizedBox(height: 8),

                // Unit cost
                if (unitCost.isNotEmpty)
                  _buildInfoRow(
                    Icons.attach_money,
                    'ລາຄາ',
                    unitCost,
                    warningOrange,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build info row
  Widget _buildInfoRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Navigate to product detail
  void _navigateToProductDetail(Map<String, dynamic> product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StockBalanceSmlDetail(
          ic_code: product['item_code']?.toString() ?? '',
          ic_name: product['item_name']?.toString() ?? '',
        ),
      ),
    );
  }

  /// Filter selection methods
  Future<void> _selectGroupMain() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => GroupMain()),
    );

    if (result != null) {
      setState(() {
        _groupMainController.text = result['name_1'] ?? '';
        _groupMainCode = result['code'] ?? '';
        // Clear dependent filters
        _groupSubController.clear();
        _groupSub2Controller.clear();
        _groupSubCode = '';
        _groupSub2Code = '';
      });
      _applyFilters();
    }
  }

  Future<void> _selectGroupSub() async {
    if (_groupMainCode?.isEmpty == true) {
      _showSnackBar('ກະລຸນາເລືອກກຸ່ມຫຼັກກ່ອນ', warningOrange);
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GroupSub(groupMain: _groupMainCode!),
      ),
    );

    if (result != null) {
      setState(() {
        _groupSubController.text = result['name_1'] ?? '';
        _groupSubCode = result['code'] ?? '';
        // Clear dependent filters
        _groupSub2Controller.clear();
        _groupSub2Code = '';
      });
      _applyFilters();
    }
  }

  Future<void> _selectGroupSub2() async {
    if (_groupSubCode?.isEmpty == true) {
      _showSnackBar('ກະລຸນາເລືອກກຸ່ມຍ່ອຍ 1 ກ່ອນ', warningOrange);
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            GroupSub2(group_main: _groupMainCode!, group_sub: _groupSubCode!),
      ),
    );

    if (result != null) {
      setState(() {
        _groupSub2Controller.text = result['name_1'] ?? '';
        _groupSub2Code = result['code'] ?? '';
      });
      _applyFilters();
    }
  }
}
