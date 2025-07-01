import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:odgcashvan/utility/my_constant.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart'; // Keep this if rawQuery is specifically used, otherwise consider removing if SQLHelper abstracts it fully

import '../database/sql_helper.dart'; // Ensure this path is correct

class StockDetailSale extends StatefulWidget {
  final String custcode; // Use final for StatefulWidget properties
  final String item_code;
  final String barcode;
  final String item_name;
  final String unit_code;
  final String averageCost;
  final String qty; // This is the balance_qty (stock on hand)
  final String salePrice;

  const StockDetailSale({
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
  State<StockDetailSale> createState() => _StockDetailSaleState();
}

class _StockDetailSaleState extends State<StockDetailSale> {
  List<Map<String, dynamic>> _draftPromotions =
      []; // Renamed _journals for clarity
  final TextEditingController _txtQuery =
      TextEditingController(); // Renamed for consistency
  final TextEditingController _discountTxt =
      TextEditingController(); // Renamed for consistency

  double _price = 0;
  double _totalAmount = 0; // Final calculated total
  double _discountPercentage = 0; // Percentage discount from API
  double _discountAmountFromApi = 0; // Calculated discount amount from API
  double _priceAfterDiscount = 0; // Price after API discount
  double _manualDiscountAmount = 0; // Manual discount amount entered by user
  double _finalTotalDiscount = 0; // Sum of API discount and manual discount

  List _availablePromotions = []; // Renamed promotion for clarity
  String? _remainingQtyForPromotion; // Renamed qty_still for clarity

  // Number formatters
  final NumberFormat _currencyFormatter = NumberFormat(
    '#,##0.00',
  ); // For price values
  final NumberFormat _quantityFormatter = NumberFormat(
    '#,##0',
  ); // For quantity display

  // Define consistent colors
  final Color _primaryColor = Colors.blue.shade600;
  final Color _accentColor = Colors.blue.shade800;
  final Color _textFieldFillColor = Colors.grey.shade100;
  final Color _textFieldBorderColor = Colors.grey.shade300;
  final Color _textFieldFocusedBorderColor = Colors.blue.shade700;
  final Color _priceColor = Colors.green.shade700;
  final Color _discountColor = Colors.orange.shade700;
  final Color _totalColor = Colors.deepPurple.shade700;
  final Color _redAccent = Colors.redAccent;
  final Color _greenAccent = Colors.green;
  final Color _darkTextColor = Colors.black87;
  final Color _mutedTextColor = Colors.grey.shade600;

  // Add these for stock status colors
  final Color _outOfStockColor = Colors.red.shade700;
  final Color _inStockColor = Colors.green.shade700;

  @override
  void initState() {
    super.initState();
    _txtQuery.text = '1'; // Default quantity to 1
    _remainingQtyForPromotion = _txtQuery.text;
    _discountTxt.text = '0'; // Default manual discount to 0
    // _getCalculatedPriceAndDiscount();
    _getAvailablePromotions();
    _refreshDraftPromotions();
    _price = double.parse(widget.salePrice);
    _totalAmount = double.parse(widget.salePrice);
  }

  // // --- Core Calculation and API Call for Price/Discount ---
  // Future<void> _getCalculatedPriceAndDiscount() async {
  //   // Clear existing draft promotions related to this item before new calculations
  //   await SQLHelper.deleteDraftPro();

  //   SharedPreferences preferences = await SharedPreferences.getInstance();
  //   String datas = json.encode({
  //     "cust_code": widget.custcode,
  //     "ic_code": widget.item_code,
  //     "qty": _txtQuery.text,
  //     "unit_code": widget.unit_code,
  //     "sale_type": 1,
  //   });
  //   print(datas);
  //   try {
  //     var response = await post(
  //       Uri.parse("${MyConstant().domain}/get_price_productvs"),
  //       headers: {'Content-Type': 'application/json; charset=UTF-8'},
  //       body: datas,
  //     );

  //     if (response.statusCode == 200) {
  //       var result = json.decode(response.body);
  //       setState(() {
  //         _price =
  //             double.tryParse(result['sale_price']?.toString() ?? '0.0') ?? 0.0;
  //         _discountPercentage =
  //             double.tryParse(result['discount']?.toString() ?? '0.0') ?? 0.0;
  //         _discountAmountFromApi =
  //             double.tryParse(result['discount_amount']?.toString() ?? '0.0') ??
  //             0.0;
  //         _priceAfterDiscount =
  //             double.tryParse(result['after_discount']?.toString() ?? '0.0') ??
  //             0.0;

  //         // Recalculate total discount including manual discount
  //         _manualDiscountAmount =
  //             double.tryParse(
  //               _discountTxt.text.isEmpty ? '0' : _discountTxt.text,
  //             ) ??
  //             0.0;
  //         _finalTotalDiscount = _discountAmountFromApi + _manualDiscountAmount;

  //         // Calculate final total based on price after API discount minus manual discount
  //         _totalAmount =
  //             (_priceAfterDiscount - _manualDiscountAmount) *
  //             (double.tryParse(_txtQuery.text) ?? 1.0);
  //       });
  //     } else {
  //       _showInfoSnackBar(
  //         'Failed to get price: ${response.statusCode}',
  //         Colors.red,
  //       );
  //     }
  //   } catch (error) {
  //     _showInfoSnackBar('Error getting price: $error', Colors.red);
  //     print("Error in getCalculatedPriceAndDiscount: $error");
  //   }
  // }

  // --- Helper method to show SnackBar messages ---
  void _showInfoSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontFamily: 'NotoSansLao'),
        ),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // --- API Call for Promotions ---
  Future<void> _getAvailablePromotions() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
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
      } else {
        _showInfoSnackBar(
          'Failed to load promotions: ${response.statusCode}',
          Colors.red,
        );
      }
    } catch (error) {
      _showInfoSnackBar('Error loading promotions: $error', Colors.red);
      print("Error in getAvailablePromotions: $error");
    }
  }

  // --- Database Operations for Draft Promotions ---
  Future<void> _refreshDraftPromotions() async {
    final data = await SQLHelper.getDraftPromotion();
    setState(() {
      _draftPromotions = data;
    });
  }

  Future<int> _countItemsInDraftById(String id) async {
    final db = await SQLHelper.db();
    var result = await db.rawQuery(
      'SELECT COUNT(*) FROM draft_promotion WHERE item_code = ?',
      [id],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<void> _updateDraftPromotionQty(
    double qtyToAdd,
    String itemCode,
  ) async {
    final db = await SQLHelper.db();
    await db.rawUpdate(
      'UPDATE draft_promotion SET qty = qty + ?, for_qty = qty + ? WHERE item_code = ?', // Assuming for_qty also updates
      [qtyToAdd, qtyToAdd, itemCode],
    );
  }

  Future<void> _addFreeItemToDraft(
    String itemCode,
    String itemName,
    String qty,
    String forQty,
    String unitCode,
    String averageCost,
    String itemMainCode,
  ) async {
    await SQLHelper.createDraftpromotion(
      itemCode,
      itemName,
      qty,
      forQty,
      unitCode,
      averageCost,
      itemMainCode,
    );
  }

  Future<void> _deleteFreeItemFromDraft(int id, double forQty) async {
    await SQLHelper.deleteItemFree(id);
    setState(() {
      _remainingQtyForPromotion =
          (double.parse(_remainingQtyForPromotion.toString()) + forQty)
              .toString();
    });
    _getAvailablePromotions(); // Re-check promotions as remaining qty might change
    _refreshDraftPromotions();
  }

  // --- Add to Order Logic ---
  Future<void> _addOrderToDatabase(
    String itemCode,
    String barcode,
    String itemName,
    String qty,
    String unitCode,
    String custCode,
    String price,
    String discount,
    String sumAmount,
    String averageCost,
    String discountAmount,
    String productType,
    String itemMainCode,
    String discountType,
  ) async {
    await SQLHelper.createOrder(
      itemCode,
      barcode,
      itemName,
      qty,
      unitCode,
      custCode,
      price,
      discount,
      sumAmount,
      averageCost,
      discountAmount,
      productType,
      itemMainCode,
      discountType,
    );
  }

  // --- Handlers for UI Interactions ---
  void _onQuantityChanged(String value) {
    setState(() {
      // Ensure quantity input doesn't exceed available stock
      double enteredQty = double.tryParse(value) ?? 0.0;
      double availableQty = double.tryParse(widget.qty) ?? 0.0;
      if (enteredQty > availableQty) {
        _txtQuery.text = _quantityFormatter.format(availableQty);
        _showInfoSnackBar('ຈຳນວນທີ່ປ້ອນເກີນສິນຄ້າຄົງເຫຼືອ', Colors.orange);
      }
      _remainingQtyForPromotion = _txtQuery.text;
    });
    // _getCalculatedPriceAndDiscount();
    // _getAvailablePromotions();
  }

  void _onManualDiscountChanged(String value) {
    setState(() {
      if (_discountTxt.text == '') {
        _totalAmount = _price * int.parse(_txtQuery.text);
      } else {
        _totalAmount =
            _price -
            (double.parse(_discountTxt.text)) * int.parse(_txtQuery.text);
      }
      // _manualDiscountAmount = double.tryParse(value) ?? 0.0;
      // _finalTotalDiscount = _discountAmountFromApi + _manualDiscountAmount;
      // _totalAmount =
      //     (_priceAfterDiscount - _manualDiscountAmount) *
      //     (double.tryParse(_txtQuery.text) ?? 1.0);
    });
  }

  void _onAddFreeItemTapped(Map<String, dynamic> promoItem) async {
    double selectedQty = (double.tryParse(_txtQuery.text) ?? 1.0);
    double promoRequiredQty =
        double.tryParse(promoItem['qty'].toString()) ?? 1.0;

    // Calculate how many times this promotion applies based on current selected quantity
    int numberOfTimesPromoApplies = (selectedQty / promoRequiredQty).floor();

    if (numberOfTimesPromoApplies <= 0) {
      _showInfoSnackBar(
        'ກະລຸນາປ້ອນຈຳນວນສິນຄ້າຫຼັກໃຫ້ພຽງພໍກັບເງື່ອນໄຂໂປຣໂມຊັນ',
        Colors.orange,
      );
      return;
    }

    int currentDraftCount = await _countItemsInDraftById(
      promoItem['free_ic_code'],
    );

    if (currentDraftCount == 0) {
      await _addFreeItemToDraft(
        promoItem['free_ic_code'],
        promoItem['free_name'],
        (promoItem['qty'] * numberOfTimesPromoApplies)
            .toString(), // Total free qty for this amount
        promoRequiredQty
            .toString(), // The quantity of main item needed for 1 free item
        promoItem['free_ic_unit_code'],
        promoItem['average_cost'],
        widget.item_code,
      );
    } else {
      await _updateDraftPromotionQty(
        (promoItem['qty'] * numberOfTimesPromoApplies),
        promoItem['free_ic_code'],
      );
    }

    _remainingQtyForPromotion =
        (double.parse(_remainingQtyForPromotion.toString()) -
                (promoRequiredQty *
                    numberOfTimesPromoApplies)) // Reduce remaining qty by promo's required qty
            .toString();

    _getAvailablePromotions(); // Re-check promotions with updated remaining qty
    _refreshDraftPromotions();
  }

  void _addToBill() async {
    double currentQty = double.tryParse(_txtQuery.text) ?? 0.0;
    double availableQty = double.tryParse(widget.qty) ?? 0.0;

    if (currentQty <= 0) {
      _showInfoSnackBar('ກະລຸນາປ້ອນຈຳນວນສິນຄ້າ', Colors.orange);
      return;
    }
    if (currentQty > availableQty) {
      _showInfoSnackBar('ຈຳນວນທີ່ປ້ອນເກີນສິນຄ້າຄົງເຫຼືອ', Colors.red);
      return;
    }

    // Add main product to order
    await _addOrderToDatabase(
      widget.item_code,
      widget.barcode,
      widget.item_name,
      _txtQuery.text,
      widget.unit_code,
      widget.custcode,
      _price.toString(),
      _discountPercentage.toString(), // Use percentage as discount field in db
      _totalAmount.toString(),
      widget.averageCost.toString(),
      _finalTotalDiscount.toString(), // Total discount amount
      'main',
      widget.item_code,
      _manualDiscountAmount > 0
          ? '1'
          : '0', // discountType '1' if manual discount applied
    );

    // Add drafted free items to order
    if (_draftPromotions.isNotEmpty) {
      for (var item in _draftPromotions) {
        await _addOrderToDatabase(
          item['item_code'].toString(),
          '', // Free items typically don't have a barcode in sales order
          item['item_name'].toString(),
          item['qty'].toString(),
          item['unit_code'].toString(),
          widget.custcode,
          '0', // Price for free item is 0
          '0', // Discount for free item is 0
          '0', // Sum amount for free item is 0
          item['average_cost'].toString(),
          '0', // Discount amount for free item is 0
          'free',
          item['item_main_code'].toString(),
          '0', // No discount type for free items
        );
      }
    }
    await SQLHelper.deleteDraftPro(); // Clear draft promotions after adding to order
    Navigator.pop(context); // Pop to SalePage
    Navigator.pop(context); // Pop to RoutePlanDetail
  }

  @override
  Widget build(BuildContext context) {
    double availableQtyDouble = double.tryParse(widget.qty) ?? 0.0;
    bool isOutOfStock = availableQtyDouble <= 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "ລາຍລະອຽດສິນຄ້າ",
          style: TextStyle(color: Colors.white, fontFamily: 'NotoSansLao'),
        ),
        backgroundColor: _primaryColor,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Product Header (Code & Name) ---
            Text(
              widget.item_code.toString(),
              style: TextStyle(
                color: _mutedTextColor,
                fontSize: 14,
                fontFamily: 'NotoSansLao',
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.item_name.toString(),
              style: TextStyle(
                color: _accentColor,
                fontWeight: FontWeight.bold,
                fontSize: 22,
                fontFamily: 'NotoSansLao',
              ),
            ),
            const SizedBox(height: 8),
            // --- Available Stock ---
            Row(
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  color: _mutedTextColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'ສິນຄ້າໃນສາງ: ${_quantityFormatter.format(availableQtyDouble)} ${widget.unit_code}',
                  style: TextStyle(
                    color: isOutOfStock ? _outOfStockColor : _inStockColor,
                    fontSize: 16,
                    fontFamily: 'NotoSansLao',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const Divider(height: 30, thickness: 1, color: Colors.grey),

            // --- Quantity Input ---
            _buildLabeledInputField(
              label: 'ຈຳນວນ',
              controller: _txtQuery,
              onChanged: _onQuantityChanged,
              keyboardType: TextInputType.number,
              suffixText: widget.unit_code,
              hintText: 'ປ້ອນຈຳນວນ',
            ),
            const SizedBox(height: 16),

            // --- Price, Discount, Total Display ---
            _buildInfoDisplayRow(
              label: 'ລາຄາ',
              value: _currencyFormatter.format(_price),

              valueColor: _priceColor,
            ),
            // _buildInfoDisplayRow(
            //   label: 'ສ່ວນຫຼຸດ (%)',
            //   value: _currencyFormatter.format(_discountPercentage),
            //   unit: '%',
            //   valueColor: _discountColor,
            // ),
            _buildLabeledInputField(
              label: 'ສ່ວນຫຼຸດເພີ່ມເຕີມ',
              controller: _discountTxt,
              onChanged: _onManualDiscountChanged,
              keyboardType: TextInputType.number,

              hintText: '0',
            ),
            // _buildInfoDisplayRow(
            //   label: 'ລວມສ່ວນຫຼຸດ',
            //   value: _currencyFormatter.format(_finalTotalDiscount),
            //   valueColor: _discountColor,
            // ),
            const Divider(height: 30, thickness: 1, color: Colors.grey),
            _buildInfoDisplayRow(
              label: 'ລວມທັງໝົດ',
              value: _currencyFormatter.format(_totalAmount),

              valueColor: _totalColor,
              isBold: true,
              fontSize: 24,
            ),
            const SizedBox(height: 24),

            // --- Promotion Section ---
            if (_availablePromotions.isNotEmpty) ...[
              Text(
                "ລາຍການຂອງແຖມທີ່ມີ (ຍັງເຫຼືອ: ${_quantityFormatter.format(double.tryParse(_remainingQtyForPromotion ?? '0') ?? 0)} ${widget.unit_code})",
                style: TextStyle(
                  fontFamily: 'NotoSansLao',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _accentColor,
                ),
              ),
              const SizedBox(height: 8),
              ListView.builder(
                shrinkWrap: true,
                physics:
                    const NeverScrollableScrollPhysics(), // Disable scrolling of this list
                itemCount: _availablePromotions.length,
                itemBuilder: (context, index) {
                  final promoItem = _availablePromotions[index];
                  // Calculate how many times this promo applies
                  double selectedQty = double.tryParse(_txtQuery.text) ?? 1.0;
                  double promoRequiredQty =
                      double.tryParse(promoItem['qty'].toString()) ?? 1.0;
                  int numberOfTimesPromoApplies =
                      (selectedQty / promoRequiredQty).floor();
                  bool canAddPromo = numberOfTimesPromoApplies > 0;

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(
                        color: canAddPromo
                            ? Colors.lightBlue.shade100
                            : Colors.grey.shade200,
                        width: 1,
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      title: Text(
                        promoItem['free_name'].toString(),
                        style: TextStyle(
                          fontFamily: 'NotoSansLao',
                          fontWeight: FontWeight.w600,
                          color: _darkTextColor,
                        ),
                      ),
                      subtitle: Text(
                        'ເງື່ອນໄຂ: ຊື້ ${promoRequiredQty.toStringAsFixed(0)} ${widget.unit_code} ໄດ້ ${promoItem['qty']} ໜ່ວຍ',
                        style: TextStyle(
                          fontFamily: 'NotoSansLao',
                          fontSize: 12,
                          color: _mutedTextColor,
                        ),
                      ),
                      trailing: canAddPromo
                          ? ElevatedButton(
                              onPressed: () => _onAddFreeItemTapped(promoItem),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _greenAccent,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                minimumSize: Size.zero,
                              ),
                              child: const Text(
                                'ເພີ່ມ',
                                style: TextStyle(
                                  fontFamily: 'NotoSansLao',
                                  fontSize: 13,
                                ),
                              ),
                            )
                          : Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(
                                'ບໍ່ເຂົ້າເງື່ອນໄຂ',
                                style: TextStyle(
                                  fontFamily: 'NotoSansLao',
                                  fontSize: 12,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
            ],

            // --- Selected Promotion Items ---
            if (_draftPromotions.isNotEmpty) ...[
              Text(
                "ລາຍການຂອງແຖມທີ່ເລືອກ",
                style: TextStyle(
                  fontFamily: 'NotoSansLao',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _accentColor,
                ),
              ),
              const SizedBox(height: 8),
              ListView.builder(
                shrinkWrap: true,
                physics:
                    const NeverScrollableScrollPhysics(), // Disable scrolling of this list
                itemCount: _draftPromotions.length,
                itemBuilder: (context, index) {
                  final draftItem = _draftPromotions[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      title: Text(
                        draftItem['item_name'].toString(),
                        style: TextStyle(
                          fontFamily: 'NotoSansLao',
                          fontWeight: FontWeight.w600,
                          color: _darkTextColor,
                        ),
                      ),
                      subtitle: Text(
                        'ຈຳນວນ: ${draftItem['qty']} ${draftItem['unit_code']}',
                        style: TextStyle(
                          fontFamily: 'NotoSansLao',
                          fontSize: 12,
                          color: _mutedTextColor,
                        ),
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.delete_outline, color: _redAccent),
                        onPressed: () => _deleteFreeItemFromDraft(
                          draftItem['id'],
                          double.tryParse(draftItem['for_qty'].toString()) ??
                              0.0,
                        ),
                        tooltip: 'ລົບຂອງແຖມນີ້',
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
            ],

            // --- Add to Bill Button ---
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 5,
                ),
                onPressed: _addToBill,
                icon: const Icon(Icons.add_shopping_cart, size: 24),
                label: const Text(
                  "ເພິ່ມເຂົ້າບິນ",
                  style: TextStyle(
                    fontFamily: 'NotoSansLao',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Helper Widgets for UI ---
  Widget _buildLabeledInputField({
    required String label,
    required TextEditingController controller,
    required ValueChanged<String> onChanged,
    required TextInputType keyboardType,
    String? suffixText,
    String? hintText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'NotoSansLao',
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: _darkTextColor,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          onChanged: onChanged,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: _darkTextColor,
            fontFamily: 'NotoSansLao',
          ),
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(
              fontFamily: 'NotoSansLao',
              color: _mutedTextColor,
            ),
            filled: true,
            fillColor: _textFieldFillColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: _textFieldBorderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: _textFieldBorderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: _textFieldFocusedBorderColor,
                width: 2,
              ),
            ),
            suffixText: suffixText,
            suffixStyle: TextStyle(
              fontFamily: 'NotoSansLao',
              fontSize: 16,
              color: _mutedTextColor,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoDisplayRow({
    required String label,
    required String value,
    String? unit,
    Color? valueColor,
    bool isBold = false,
    double fontSize = 18,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'NotoSansLao',
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: _darkTextColor,
            ),
          ),
          Text.rich(
            TextSpan(
              text: value,
              style: TextStyle(
                fontFamily: 'NotoSansLao',
                fontSize: fontSize,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                color: valueColor ?? _darkTextColor,
              ),
              children: [
                if (unit != null)
                  TextSpan(
                    text: ' $unit',
                    style: TextStyle(
                      fontFamily: 'NotoSansLao',
                      fontSize: fontSize * 0.8, // Slightly smaller unit font
                      fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                      color: valueColor ?? _mutedTextColor,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
