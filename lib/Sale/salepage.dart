import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:odgcashvan/Sale/payment/payment.dart';
import 'package:odgcashvan/database/sql_helper.dart';
import 'package:odgcashvan/utility/my_constant.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'payment/homepayment.dart';
import '../POS/stocksale.dart';
import '../utility/app_colors.dart';

class ModernSalePage extends StatefulWidget {
  final String cust_code;
  final String cust_group_1;
  final String cust_group_2;

  const ModernSalePage({
    super.key,
    required this.cust_code,
    required this.cust_group_1,
    required this.cust_group_2,
  });

  @override
  State<ModernSalePage> createState() => _ModernSalePageState();
}

class _ModernSalePageState extends State<ModernSalePage>
    with TickerProviderStateMixin {
  List _availableStock = [];
  double _totalAmount = 0.00;
  List<Map<String, dynamic>> _currentOrderItems = [];

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final NumberFormat _currencyFormatter = NumberFormat('#,##0.00');

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _fetchAvailableStock();
    _refreshOrderItems();
  }

  void _initAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchAvailableStock() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? whCode = prefs.getString('wh_code');
    String? shCode = prefs.getString('sh_code');

    if (whCode == null || whCode.isEmpty || shCode == null || shCode.isEmpty) {
      if (mounted) {
        _showCompactSnackBar(
          'ຂໍ້ມູນສາງບໍ່ຄົບຖ້ວນ. ບໍ່ສາມາດໂຫຼດສິນຄ້າ.',
          AppColors.redAccent,
          Icons.error_outline,
        );
      }
      setState(() => _availableStock = []);
      return;
    }

    try {
      final res = await post(
        Uri.parse("${MyConstant().domain}/vanstocksale"),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: json.encode({
          "cust_group_1": widget.cust_group_1,
          "cust_group_2": widget.cust_group_2,
          "wh_code": whCode,
          "sh_code": shCode,
        }),
      );

      final result = jsonDecode(res.body);
      setState(() => _availableStock = result['list'] ?? []);
    } catch (e) {
      if (mounted) {
        _showCompactSnackBar(
          'ເກີດຂໍ້ຜິດພາດໃນການໂຫຼດສິນຄ້າ',
          AppColors.redAccent,
          Icons.error_outline,
        );
      }
      setState(() => _availableStock = []);
    }
  }

  void _showCompactSnackBar(String message, Color color, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: AppColors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontFamily: 'NotoSansLao',
                  color: AppColors.white,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _refreshOrderItems() async {
    final data = await SQLHelper.getOrdersbtcust(widget.cust_code);
    setState(() {
      _currentOrderItems = data;
      _totalAmount = data.fold(
        0.0,
        (sum, e) =>
            sum +
            (double.tryParse(e['sum_amount']?.toString() ?? '0.0') ?? 0.0),
      );
    });
    _animationController.reset();
    _animationController.forward();
  }

  void _deleteOrderItem(String id) async {
    await SQLHelper.deleteItemOrder(id);
    if (mounted) {
      _showCompactSnackBar(
        'ລົບລາຍການສຳເລັດ',
        Colors.green,
        Icons.check_circle_outline,
      );
    }
    _refreshOrderItems();
  }

  void _confirmDeleteOrderItem(String id, String itemName) {
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text(
          "ລົບລາຍການ",
          style: TextStyle(
            fontFamily: 'NotoSansLao',
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        content: Text(
          "ລົບ $itemName ອອກຈາກລາຍການ?",
          style: const TextStyle(fontFamily: 'NotoSansLao', fontSize: 14),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () {
              _deleteOrderItem(id);
              Navigator.pop(context);
            },
            child: const Text(
              "ຢືນຢັນ",
              style: TextStyle(
                fontFamily: 'NotoSansLao',
                color: AppColors.redAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "ຍົກເລີກ",
              style: TextStyle(
                fontFamily: 'NotoSansLao',
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showModernPaymentSelection() {
    if (_currentOrderItems.isEmpty || _totalAmount <= 0) {
      _showCompactSnackBar(
        'ບໍ່ມີສິນຄ້າໃນລາຍການ',
        AppColors.orangeAccent,
        Icons.warning_amber_outlined,
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext bc) {
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
            ),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: const BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.grey300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF3B82F6), Color(0xFF1E40AF)],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.payments_outlined,
                          color: AppColors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'ວິທີຊໍາລະເງິນ',
                        style: TextStyle(
                          fontFamily: 'NotoSansLao',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildModernPaymentOption(
                    bc,
                    Icons.account_balance_wallet_outlined,
                    'ຈ່າຍດ້ວຍເງິນສົດ',
                    const Color(0xFF059669),
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => HomePayment(
                          cust_code: widget.cust_code,
                          total_amount: _totalAmount.toString(),
                        ),
                      ),
                    ).then((value) => _refreshOrderItems()),
                  ),
                  const SizedBox(height: 12),
                  _buildModernPaymentOption(
                    bc,
                    Icons.qr_code_scanner_outlined,
                    'ຈ່າຍດ້ວຍການໂອນ',
                    const Color(0xFF7C3AED),
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => Payment(
                          cust_code: widget.cust_code,
                          total_amount: _totalAmount.toString(),
                        ),
                      ),
                    ).then((value) => _refreshOrderItems()),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildModernPaymentOption(
    BuildContext bc,
    IconData icon,
    String title,
    Color color,
    VoidCallback onTap,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.white, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontFamily: 'NotoSansLao',
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: Icon(Icons.arrow_forward_ios_rounded, size: 16, color: color),
        onTap: () {
          Navigator.pop(bc);
          onTap();
        },
      ),
    );
  }

  Widget _buildCompactHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E40AF), Color(0xFF3B82F6)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_rounded,
                  color: AppColors.white,
                  size: 20,
                ),
                onPressed: () => Navigator.pop(context),
              ),
              const Expanded(
                child: Text(
                  "ໜ້າຂາຍສິນຄ້າ",
                  style: TextStyle(
                    color: AppColors.white,
                    fontFamily: 'NotoSansLao',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_currentOrderItems.length}',
                  style: const TextStyle(
                    color: AppColors.white,
                    fontFamily: 'NotoSansLao',
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactItemCard(Map<String, dynamic> item, int index) {
    final double itemSumAmount =
        double.tryParse(item['sum_amount']?.toString() ?? '0.0') ?? 0.0;
    final bool isMainProduct = item['product_type'] == 'main';

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isMainProduct
                          ? [const Color(0xFF3B82F6), const Color(0xFF1E40AF)]
                          : [const Color(0xFFF59E0B), const Color(0xFFD97706)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isMainProduct
                        ? Icons.inventory_2_outlined
                        : Icons.card_giftcard_outlined,
                    color: AppColors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['item_name'],
                        style: const TextStyle(
                          fontFamily: 'NotoSansLao',
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: AppColors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            '${item['qty']} ${item['unit_code']}',
                            style: const TextStyle(
                              fontFamily: 'NotoSansLao',
                              fontSize: 11,
                              color: Color(0xFF6B7280),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (item['discount'] != '0')
                            Container(
                              margin: const EdgeInsets.only(left: 6),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEF4444),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '-${item['discount']}%',
                                style: const TextStyle(
                                  fontFamily: 'NotoSansLao',
                                  fontSize: 9,
                                  color: AppColors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _currencyFormatter.format(itemSumAmount),
                      style: const TextStyle(
                        fontFamily: 'NotoSansLao',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF059669),
                      ),
                    ),
                    const SizedBox(height: 2),
                    GestureDetector(
                      onTap: () => _confirmDeleteOrderItem(
                        item['item_code'].toString(),
                        item['item_name'].toString(),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.delete_outline_rounded,
                          color: Color(0xFFEF4444),
                          size: 16,
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
    );
  }

  Widget _buildCompactBottomBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF3F4F6), Color(0xFFE5E7EB)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "ມູນຄ່າທັງໝົດ:",
                      style: TextStyle(
                        fontFamily: 'NotoSansLao',
                        fontSize: 15,
                        color: Color(0xFF374151),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      _currencyFormatter.format(_totalAmount),
                      style: const TextStyle(
                        fontFamily: 'NotoSansLao',
                        fontSize: 18,
                        color: Color(0xFF059669),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6366F1).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ModernStockSale(custcode: widget.cust_code),
                            ),
                          ).then((value) => _refreshOrderItems());
                        },
                        icon: const Icon(
                          Icons.add_shopping_cart_outlined,
                          color: AppColors.white,
                          size: 18,
                        ),
                        label: const Text(
                          "ເພີ່ມສິນຄ້າ",
                          style: TextStyle(
                            fontFamily: 'NotoSansLao',
                            color: AppColors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF059669), Color(0xFF047857)],
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF059669).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: _showModernPaymentSelection,
                        icon: const Icon(
                          Icons.payments_outlined,
                          size: 18,
                          color: AppColors.white,
                        ),
                        label: const Text(
                          "ຮັບເງິນ",
                          style: TextStyle(
                            fontFamily: 'NotoSansLao',
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          _buildCompactHeader(),
          Expanded(
            child: _currentOrderItems.isEmpty
                ? Center(
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
                              Icons.shopping_bag_outlined,
                              size: 40,
                              color: Color(0xFF9CA3AF),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            "ຍັງບໍ່ມີສິນຄ້າໃນລາຍການ",
                            style: TextStyle(
                              fontFamily: 'NotoSansLao',
                              fontSize: 16,
                              color: Color(0xFF6B7280),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "ກົດ 'ເພີ່ມສິນຄ້າ' ເພື່ອເລີ່ມຕົ້ນ",
                            style: TextStyle(
                              fontFamily: 'NotoSansLao',
                              fontSize: 13,
                              color: const Color(0xFF9CA3AF),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: _currentOrderItems.length,
                    padding: const EdgeInsets.all(12),
                    itemBuilder: (_, index) {
                      return _buildCompactItemCard(
                        _currentOrderItems[index],
                        index,
                      );
                    },
                  ),
          ),
          _buildCompactBottomBar(),
        ],
      ),
    );
  }
}
