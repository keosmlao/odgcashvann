import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:odgcashvan/stock/countstock/listbillstkcountDetail.dart';
import 'package:odgcashvan/utility/my_constant.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'addcountstock.dart';

class ListBillStockCount extends StatefulWidget {
  const ListBillStockCount({super.key});

  @override
  State<ListBillStockCount> createState() => _ListBillStockCountState();
}

class _ListBillStockCountState extends State<ListBillStockCount>
    with SingleTickerProviderStateMixin {
  // Controllers & Variables
  final TextEditingController _fromDateController = TextEditingController();
  final TextEditingController _toDateController = TextEditingController();
  final DateFormat _displayFormatter = DateFormat('dd-MM-yyyy');
  final DateFormat _apiFormatter = DateFormat('yyyy-MM-dd');

  List<dynamic> _stockCountList = [];
  bool _isLoading = false;
  String? _errorMessage;
  DateTime _fromDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _toDate = DateTime.now();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Modern Blue Theme Colors
  static const Color primaryBlue = Color(0xff2196F3);
  static const Color accentBlue = Color(0xff1976D2);
  static const Color lightBlue = Color(0xff64B5F6);
  static const Color darkBlue = Color(0xff0D47A1);
  static const Color backgroundBlue = Color(0xffE3F2FD);
  static const Color cardBlue = Color(0xffBBDEFB);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _initializeData();
    _animationController.forward();
  }

  @override
  void dispose() {
    _fromDateController.dispose();
    _toDateController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  /// Initialize initial data
  void _initializeData() {
    _fromDateController.text = _displayFormatter.format(_fromDate);
    _toDateController.text = _displayFormatter.format(_toDate);
    _fetchStockCountData(_fromDate, _toDate);
  }

  /// Fetch stock count data from API
  Future<void> _fetchStockCountData(DateTime fromDate, DateTime toDate) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final userCode = prefs.getString('usercode') ?? '';

      if (userCode.isEmpty) {
        throw Exception('ບໍ່ພົບລະຫັດຜູ້ໃຊ້');
      }

      final requestBody = jsonEncode({
        "sale_code": userCode,
        "from_date": _apiFormatter.format(fromDate),
        "to_date": _apiFormatter.format(toDate),
      });

      final response = await post(
        Uri.parse('${MyConstant().domain}/listbillcountstock'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: requestBody,
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        setState(() {
          _stockCountList = result['list'] ?? [];
          _isLoading = false;
        });
      } else {
        throw Exception('ເກີດຂໍ້ຜິດພາດໃນການໂຫຼດຂໍ້ມູນ');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  /// Delete stock count bill
  Future<void> _deleteStockCountBill(String docNo) async {
    try {
      final response = await get(
        Uri.parse('${MyConstant().domain}/delete_billcount_stk/$docNo'),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        _showSnackBar('ລົບຂໍ້ມູນສຳເລັດ', Colors.green);
        _fetchStockCountData(_fromDate, _toDate);
      } else {
        throw Exception('ເກີດຂໍ້ຜິດພາດໃນການລົບຂໍ້ມູນ');
      }
    } catch (e) {
      _showSnackBar('ເກີດຂໍ້ຜິດພາດ: ${e.toString()}', Colors.red);
    }
  }

  /// Show date picker for from date
  Future<void> _selectFromDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _fromDate,
      firstDate: DateTime(2020),
      lastDate: _toDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: primaryBlue,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null && pickedDate != _fromDate) {
      setState(() {
        _fromDate = pickedDate;
        _fromDateController.text = _displayFormatter.format(pickedDate);
      });
      _fetchStockCountData(_fromDate, _toDate);
    }
  }

  /// Show date picker for to date
  Future<void> _selectToDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _toDate,
      firstDate: _fromDate,
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: primaryBlue,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null && pickedDate != _toDate) {
      setState(() {
        _toDate = pickedDate;
        _toDateController.text = _displayFormatter.format(pickedDate);
      });
      _fetchStockCountData(_fromDate, _toDate);
    }
  }

  /// Show confirmation dialog for deletion
  void _showDeleteConfirmation(String docNo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.warning_amber_rounded,
                color: Colors.red.shade600,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'ຢືນຢັນການລົບ',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Text(
          'ທ່ານແນ່ໃຈບໍ່ວ່າຕ້ອງການລົບໃບກວດນັບນີ້?\nການກະທຳນີ້ບໍ່ສາມາດຍົກເລີກໄດ້',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'ຍົກເລີກ',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteStockCountBill(docNo);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('ລົບ'),
          ),
        ],
      ),
    );
  }

  /// Show snack bar message
  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /// Navigate to add stock count page
  Future<void> _navigateToAddStockCount() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const Addcountstock()),
    );

    if (result == true) {
      _fetchStockCountData(_fromDate, _toDate);
    }
  }

  /// Navigate to stock count detail page
  void _navigateToStockCountDetail(String docNo) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ListBillStkCountDetail(doc_no: docNo),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundBlue,
      body: CustomScrollView(
        slivers: [
          // Modern App Bar with Gradient
          // SliverAppBar(
          //   expandedHeight: 120,
          //   floating: false,
          //   pinned: true,
          //   elevation: 0,
          //   flexibleSpace: FlexibleSpaceBar(
          //     background: Container(
          //       decoration: const BoxDecoration(
          //         gradient: LinearGradient(
          //           begin: Alignment.topLeft,
          //           end: Alignment.bottomRight,
          //           colors: [primaryBlue, accentBlue, darkBlue],
          //         ),
          //       ),
          //     ),
          //     title: const Text(
          //       'ລາຍການໃບກວດນັບສິນຄ້າ',
          //       style: TextStyle(
          //         fontSize: 18,
          //         fontWeight: FontWeight.bold,
          //         color: Colors.white,
          //       ),
          //     ),
          //     centerTitle: true,
          //   ),
          //   backgroundColor: primaryBlue,
          //   iconTheme: const IconThemeData(color: Colors.white),
          // ),

          // Date Selection Section
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: _buildDateSelectionSection(),
            ),
          ),

          // Content Section
          SliverFillRemaining(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: _buildContentSection(),
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  /// Build floating action button
  Widget _buildFloatingActionButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primaryBlue, accentBlue],
        ),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        onPressed: _navigateToAddStockCount,
        backgroundColor: Colors.transparent,
        elevation: 0,
        icon: const Icon(
          Icons.add_circle_outline,
          color: Colors.white,
          size: 24,
        ),
        label: const Text(
          'ສ້າງໃໝ່',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  /// Build date selection section
  Widget _buildDateSelectionSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [primaryBlue, lightBlue],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.date_range,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'ເລືອກຊ່ວງວັນທີ',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: darkBlue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Date Range Selection
            Row(
              children: [
                Expanded(
                  child: _buildDateField(
                    'ແຕ່ວັນທີ',
                    _fromDateController,
                    _selectFromDate,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDateField(
                    'ຫາວັນທີ',
                    _toDateController,
                    _selectToDate,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Quick Date Buttons
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildQuickDateChip(
                  'ມື້ນີ້',
                  Icons.today,
                  () => _setQuickDateRange(0),
                ),
                _buildQuickDateChip(
                  '7 ວັນ',
                  Icons.date_range,
                  () => _setQuickDateRange(7),
                ),
                _buildQuickDateChip(
                  '30 ວັນ',
                  Icons.calendar_month,
                  () => _setQuickDateRange(30),
                ),
                _buildQuickDateChip(
                  '90 ວັນ',
                  Icons.calendar_view_month,
                  () => _setQuickDateRange(90),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Build date input field
  Widget _buildDateField(
    String label,
    TextEditingController controller,
    VoidCallback onTap,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          readOnly: true,
          onTap: onTap,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            filled: true,
            fillColor: backgroundBlue,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: primaryBlue, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            suffixIcon: Container(
              margin: const EdgeInsets.all(8),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: primaryBlue,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.calendar_today,
                size: 16,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Build quick date selection chip
  Widget _buildQuickDateChip(
    String label,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                primaryBlue.withOpacity(0.1),
                lightBlue.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: primaryBlue.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: primaryBlue),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: primaryBlue,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Set quick date range
  void _setQuickDateRange(int days) {
    setState(() {
      _toDate = DateTime.now();
      _fromDate = days == 0
          ? DateTime.now()
          : DateTime.now().subtract(Duration(days: days));
      _fromDateController.text = _displayFormatter.format(_fromDate);
      _toDateController.text = _displayFormatter.format(_toDate);
    });
    _fetchStockCountData(_fromDate, _toDate);
  }

  /// Build content section
  Widget _buildContentSection() {
    if (_isLoading) {
      return _buildLoadingSection();
    }

    if (_errorMessage != null) {
      return _buildErrorSection();
    }

    if (_stockCountList.isEmpty) {
      return _buildEmptySection();
    }

    return _buildStockCountList();
  }

  /// Build loading section
  Widget _buildLoadingSection() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: primaryBlue.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(primaryBlue),
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'ກຳລັງໂຫຼດຂໍ້ມູນ...',
            style: TextStyle(
              fontSize: 16,
              color: primaryBlue,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Build error section
  Widget _buildErrorSection() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.red.shade600,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'ເກີດຂໍ້ຜິດພາດ',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'ບໍ່ສາມາດໂຫຼດຂໍ້ມູນໄດ້',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _fetchStockCountData(_fromDate, _toDate),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              icon: const Icon(Icons.refresh),
              label: const Text(
                'ລອງໃໝ່',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build empty section
  Widget _buildEmptySection() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: primaryBlue.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    primaryBlue.withOpacity(0.1),
                    lightBlue.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.inventory_2_outlined,
                size: 64,
                color: primaryBlue.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'ບໍ່ມີຂໍ້ມູນໃບກວດນັບ',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: darkBlue,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'ໃນຊ່ວງວັນທີທີ່ເລືອກ',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  /// Build stock count list
  Widget _buildStockCountList() {
    return Column(
      children: [
        // Summary Card
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                primaryBlue.withOpacity(0.1),
                lightBlue.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: primaryBlue.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [primaryBlue, lightBlue],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.inventory_2,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ທັງໝົດ ${_stockCountList.length} ໃບກວດນັບ',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: darkBlue,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_displayFormatter.format(_fromDate)} - ${_displayFormatter.format(_toDate)}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // List Items
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _stockCountList.length,
            itemBuilder: (context, index) {
              final item = _stockCountList[index];
              return _buildStockCountCard(item, index);
            },
          ),
        ),
      ],
    );
  }

  /// Build stock count card
  Widget _buildStockCountCard(dynamic item, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToStockCountDetail(item['doc_no']),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Leading Avatar
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [primaryBlue, lightBlue],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ເລກທີ: ${item['doc_no']}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: darkBlue,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 16,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${item['doc_date']}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.inventory,
                            size: 16,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${item['item_count']} ລາຍການ',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Action Menu
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'view') {
                      _navigateToStockCountDetail(item['doc_no']);
                    } else if (value == 'delete') {
                      _showDeleteConfirmation(item['doc_no']);
                    }
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'view',
                      child: ListTile(
                        leading: Icon(Icons.visibility, color: primaryBlue),
                        title: Text('ເບິ່ງລາຍລະອຽດ'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        leading: Icon(Icons.delete, color: Colors.red),
                        title: Text('ລົບ', style: TextStyle(color: Colors.red)),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: backgroundBlue,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.more_vert, color: primaryBlue),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
