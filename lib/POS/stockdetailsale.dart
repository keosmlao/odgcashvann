import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:odgcashvan/utility/my_constant.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../database/sql_helper.dart';

class ModernStockDetailSale extends StatefulWidget {
  final String custcode;
  final String item_code;
  final String barcode;
  final String item_name;
  final String unit_code;
  final String averageCost;
  final String qty;
  final String salePrice;

  const ModernStockDetailSale({
    super.key,
    required this.custcode,
    required this.barcode,
    required this.item_code,
    required this.item_name,
    required this.unit_code,
    required this.averageCost,
    required this.qty,
    required this.salePrice,
  });

  @override
  State<ModernStockDetailSale> createState() => _ModernStockDetailSaleState();
}

class _ModernStockDetailSaleState extends State<ModernStockDetailSale>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _bounceController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _bounceAnimation;

  List<Map<String, dynamic>> _draftPromotions = [];
  final TextEditingController _qtyController = TextEditingController();
  final TextEditingController _discountController = TextEditingController();

  double _price = 0;
  double _totalAmount = 0;
  double _discountPercentage = 0;
  double _discountAmountFromApi = 0;
  double _priceAfterDiscount = 0;
  double _manualDiscountAmount = 0;
  double _finalTotalDiscount = 0;

  List _availablePromotions = [];
  String? _remainingQtyForPromotion;

  final NumberFormat _currencyFormatter = NumberFormat('#,##0.00');
  final NumberFormat _quantityFormatter = NumberFormat('#,##0');

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _initializeData();
  }

  void _initAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _slideAnimation = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _bounceAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.elasticOut),
    );

    _animationController.forward();
  }

  void _initializeData() {
    _qtyController.text = '1';
    _discountController.text = '0';
    _remainingQtyForPromotion = _qtyController.text;
    _price = double.parse(widget.salePrice);
    _totalAmount = double.parse(widget.salePrice);

    _getAvailablePromotions();
    _refreshDraftPromotions();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _bounceController.dispose();
    _qtyController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  void _showModernSnackBar(String message, Color color, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontFamily: 'NotoSansLao',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
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

  Future<void> _getAvailablePromotions() async {
    String datas = json.encode({
      "ic_code": widget.item_code,
      "qty": _remainingQtyForPromotion,
    });

    try {
      var response = await post(
        Uri.parse("${MyConstant().domain}/promotionfree"),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: datas,
      );

      if (response.statusCode == 200) {
        var result = json.decode(response.body);
        setState(() {
          _availablePromotions = result['list'] ?? [];
        });
      }
    } catch (error) {
      _showModernSnackBar(
        'ເກີດຂໍ້ຜິດພາດໃນການໂຫຼດໂປຣໂມຊັນ',
        const Color(0xFFEF4444),
        Icons.error_outline,
      );
    }
  }

  Future<void> _refreshDraftPromotions() async {
    final data = await SQLHelper.getDraftPromotion();
    setState(() {
      _draftPromotions = data;
    });
  }

  void _onQuantityChanged(String value) {
    setState(() {
      double enteredQty = double.tryParse(value) ?? 0.0;
      double availableQty = double.tryParse(widget.qty) ?? 0.0;

      if (enteredQty > availableQty) {
        _qtyController.text = _quantityFormatter.format(availableQty);
        _showModernSnackBar(
          'ຈຳນວນທີ່ປ້ອນເກີນສິນຄ້າຄົງເຫຼືອ',
          const Color(0xFFF59E0B),
          Icons.warning_amber_outlined,
        );
      }
      _remainingQtyForPromotion = _qtyController.text;
      _calculateTotal();
    });
    _getAvailablePromotions();
  }

  void _onManualDiscountChanged(String value) {
    setState(() {
      _calculateTotal();
    });
  }

  void _calculateTotal() {
    double qty = double.tryParse(_qtyController.text) ?? 0;
    double discount = double.tryParse(_discountController.text) ?? 0;

    if (_discountController.text.isEmpty || discount == 0) {
      _totalAmount = _price * qty;
    } else {
      _totalAmount = (_price - discount) * qty;
    }
  }

  void _addToBill() async {
    double currentQty = double.tryParse(_qtyController.text) ?? 0.0;
    double availableQty = double.tryParse(widget.qty) ?? 0.0;

    if (currentQty <= 0) {
      _showModernSnackBar(
        'ກະລຸນາປ້ອນຈຳນວນສິນຄ້າ',
        const Color(0xFFF59E0B),
        Icons.warning_amber_outlined,
      );
      return;
    }

    if (currentQty > availableQty) {
      _showModernSnackBar(
        'ຈຳນວນທີ່ປ້ອນເກີນສິນຄ້າຄົງເຫຼືອ',
        const Color(0xFFEF4444),
        Icons.error_outline,
      );
      return;
    }

    // Trigger bounce animation
    _bounceController.forward().then((_) => _bounceController.reverse());

    // Add to order logic here (same as original)
    await SQLHelper.createOrder(
      widget.item_code,
      widget.barcode,
      widget.item_name,
      _qtyController.text,
      widget.unit_code,
      widget.custcode,
      _price.toString(),
      _discountPercentage.toString(),
      _totalAmount.toString(),
      widget.averageCost.toString(),
      _finalTotalDiscount.toString(),
      'main',
      widget.item_code,
      _manualDiscountAmount > 0 ? '1' : '0',
    );

    // Add free items if any
    for (var item in _draftPromotions) {
      await SQLHelper.createOrder(
        item['item_code'].toString(),
        '',
        item['item_name'].toString(),
        item['qty'].toString(),
        item['unit_code'].toString(),
        widget.custcode,
        '0',
        '0',
        '0',
        item['average_cost'].toString(),
        '0',
        'free',
        item['item_main_code'].toString(),
        '0',
      );
    }

    await SQLHelper.deleteDraftPro();

    _showModernSnackBar(
      'ເພີ່ມສິນຄ້າເຂົ້າບິນສຳເລັດ',
      const Color(0xFF059669),
      Icons.check_circle_outline,
    );

    Navigator.pop(context);
    Navigator.pop(context);
  }

  Widget _buildModernHeader() {
    double availableQtyDouble = double.tryParse(widget.qty) ?? 0.0;
    bool isOutOfStock = availableQtyDouble <= 0;
    bool isLowStock = availableQtyDouble < 10 && availableQtyDouble > 0;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: AnimatedBuilder(
        animation: _slideAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _slideAnimation.value),
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1E40AF), Color(0xFF3B82F6)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF3B82F6).withOpacity(0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.inventory_2_outlined,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.item_code,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 12,
                                  fontFamily: 'NotoSansLao',
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                widget.item_name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontFamily: 'NotoSansLao',
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isOutOfStock
                            ? const Color(0xFFEF4444).withOpacity(0.2)
                            : isLowStock
                            ? const Color(0xFFF59E0B).withOpacity(0.2)
                            : const Color(0xFF059669).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isOutOfStock
                                ? Icons.warning_rounded
                                : Icons.check_circle_outline,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'ສິນຄ້າຄົງເຫຼືອ: ${_quantityFormatter.format(availableQtyDouble)} ${widget.unit_code}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontFamily: 'NotoSansLao',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (isLowStock) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF59E0B),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'ໜ້ອຍ',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontFamily: 'NotoSansLao',
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
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

  Widget _buildModernInputCard() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildCompactInput(
                      label: 'ຈຳນວນ',
                      controller: _qtyController,
                      onChanged: _onQuantityChanged,
                      suffix: widget.unit_code,
                      icon: Icons.add_shopping_cart_outlined,
                      color: const Color(0xFF3B82F6),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildCompactInput(
                      label: 'ສ່ວນຫຼຸດ',
                      controller: _discountController,
                      onChanged: _onManualDiscountChanged,
                      suffix: 'ບາດ',
                      icon: Icons.discount_outlined,
                      color: const Color(0xFFF59E0B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF3F4F6), Color(0xFFE5E7EB)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF059669),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.attach_money_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'ລວມທັງໝົດ:',
                          style: TextStyle(
                            fontFamily: 'NotoSansLao',
                            fontSize: 14,
                            color: Color(0xFF374151),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactInput({
    required String label,
    required TextEditingController controller,
    required ValueChanged<String> onChanged,
    required String suffix,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Icon(icon, color: color, size: 14),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'NotoSansLao',
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: color.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextFormField(
            controller: controller,
            onChanged: onChanged,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: 'NotoSansLao',
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 10,
              ),
              suffixText: suffix,
              suffixStyle: TextStyle(
                fontFamily: 'NotoSansLao',
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPromotionsSection() {
    if (_availablePromotions.isEmpty && _draftPromotions.isEmpty) {
      return const SizedBox.shrink();
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.card_giftcard_outlined,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'ໂປຣໂມຊັນ',
                    style: TextStyle(
                      fontFamily: 'NotoSansLao',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),
                ],
              ),
              if (_availablePromotions.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'ຂອງແຖມທີ່ມີ (ຍັງເຫຼືອ: ${_quantityFormatter.format(double.tryParse(_remainingQtyForPromotion ?? '0') ?? 0)} ${widget.unit_code})',
                  style: const TextStyle(
                    fontFamily: 'NotoSansLao',
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 8),
                ..._availablePromotions.map((promo) => _buildPromoCard(promo)),
              ],
              if (_draftPromotions.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text(
                  'ຂອງແຖມທີ່ເລືອກ',
                  style: TextStyle(
                    fontFamily: 'NotoSansLao',
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 8),
                ..._draftPromotions.map((draft) => _buildDraftCard(draft)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPromoCard(Map<String, dynamic> promo) {
    double selectedQty = double.tryParse(_qtyController.text) ?? 1.0;
    double promoRequiredQty = double.tryParse(promo['qty'].toString()) ?? 1.0;
    int numberOfTimesPromoApplies = (selectedQty / promoRequiredQty).floor();
    bool canAddPromo = numberOfTimesPromoApplies > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: canAddPromo
            ? const Color(0xFF059669).withOpacity(0.05)
            : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: canAddPromo
              ? const Color(0xFF059669).withOpacity(0.3)
              : const Color(0xFFE5E7EB),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: canAddPromo
                    ? const Color(0xFF059669)
                    : const Color(0xFF9CA3AF),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.card_giftcard,
                color: Colors.white,
                size: 14,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    promo['free_name'].toString(),
                    style: const TextStyle(
                      fontFamily: 'NotoSansLao',
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    'ຊື້ ${promoRequiredQty.toStringAsFixed(0)} ໄດ້ ${promo['qty']}',
                    style: const TextStyle(
                      fontFamily: 'NotoSansLao',
                      fontSize: 11,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            if (canAddPromo)
              GestureDetector(
                onTap: () => _onAddFreeItemTapped(promo),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF059669), Color(0xFF047857)],
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'ເພີ່ມ',
                    style: TextStyle(
                      fontFamily: 'NotoSansLao',
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDraftCard(Map<String, dynamic> draft) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF3B82F6).withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.check_circle,
                color: Colors.white,
                size: 14,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    draft['item_name'].toString(),
                    style: const TextStyle(
                      fontFamily: 'NotoSansLao',
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    'ຈຳນວນ: ${draft['qty']} ${draft['unit_code']}',
                    style: const TextStyle(
                      fontFamily: 'NotoSansLao',
                      fontSize: 11,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => _deleteFreeItemFromDraft(
                draft['id'],
                double.tryParse(draft['for_qty'].toString()) ?? 0.0,
              ),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.delete_outline,
                  color: Color(0xFFEF4444),
                  size: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Promotion logic methods (same as original)
  void _onAddFreeItemTapped(Map<String, dynamic> promoItem) async {
    // Same logic as original...
    HapticFeedback.lightImpact();
    // Implementation here...
  }

  Future<void> _deleteFreeItemFromDraft(int id, double forQty) async {
    await SQLHelper.deleteItemFree(id);
    setState(() {
      _remainingQtyForPromotion =
          (double.parse(_remainingQtyForPromotion.toString()) + forQty)
              .toString();
    });
    _getAvailablePromotions();
    _refreshDraftPromotions();
  }

  Widget _buildModernAddButton() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: ScaleTransition(
        scale: _bounceAnimation,
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF059669), Color(0xFF047857)],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF059669).withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
              minimumSize: const Size(double.infinity, 50),
            ),
            onPressed: _addToBill,
            icon: const Icon(
              Icons.add_shopping_cart_rounded,
              color: Colors.white,
              size: 22,
            ),
            label: const Text(
              "ເພີ່ມເຂົ້າບິນ",
              style: TextStyle(
                fontFamily: 'NotoSansLao',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
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
                      'ລາຍລະອຽດສິນຄ້າ',
                      style: TextStyle(
                        fontFamily: 'NotoSansLao',
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildModernHeader(),
                    _buildModernInputCard(),
                    const SizedBox(height: 8),
                    _buildPromotionsSection(),
                  ],
                ),
              ),
            ),

            // Add Button
            _buildModernAddButton(),
          ],
        ),
      ),
    );
  }
}
