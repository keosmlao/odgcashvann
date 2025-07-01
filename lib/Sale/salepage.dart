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
import '../utility/app_colors.dart'; // Import your new AppColors

class SalePage extends StatefulWidget {
  final String cust_code;
  final String cust_group_1;
  final String cust_group_2;

  const SalePage({
    super.key,
    required this.cust_code,
    required this.cust_group_1,
    required this.cust_group_2,
  });

  @override
  State<SalePage> createState() => _SalePageState();
}

class _SalePageState extends State<SalePage> {
  List _availableStock = [];
  double _totalAmount = 0.00;
  List<Map<String, dynamic>> _currentOrderItems = [];

  // Number formatter for currency display
  final NumberFormat _currencyFormatter = NumberFormat('#,##0.00');

  @override
  void initState() {
    super.initState();
    _fetchAvailableStock();
    _refreshOrderItems();
  }

  Future<void> _fetchAvailableStock() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? whCode = prefs.getString('wh_code');
    String? shCode = prefs.getString('sh_code');

    if (whCode == null || whCode.isEmpty || shCode == null || shCode.isEmpty) {
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'ເກີດຂໍ້ຜິດພາດໃນການໂຫຼດສິນຄ້າ: $e',
              style: const TextStyle(
                fontFamily: 'NotoSansLao',
                color: AppColors.white,
              ),
            ),
            backgroundColor: AppColors.redAccent,
          ),
        );
      }
      setState(() => _availableStock = []);
    }
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
  }

  void _deleteOrderItem(String id) async {
    await SQLHelper.deleteItemOrder(id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'ລົບລາຍການສຳເລັດ',
            style: TextStyle(fontFamily: 'NotoSansLao', color: AppColors.white),
          ),
          backgroundColor: AppColors.redAccent,
        ),
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
          ),
        ),
        content: Text(
          "ທ່ານແນ່ໃຈບໍ່ວ່າຕ້ອງການລົບ $itemName ນີ້ອອກຈາກລາຍການ?",
          style: const TextStyle(fontFamily: 'NotoSansLao'),
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
              ),
            ),
          ),
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "ຍົກເລີກ",
              style: TextStyle(fontFamily: 'NotoSansLao'),
            ),
          ),
        ],
      ),
    );
  }

  // --- New: Show Payment Method Selection Bottom Sheet ---
  void _showPaymentMethodSelection() {
    if (_currentOrderItems.isEmpty || _totalAmount <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'ບໍ່ມີສິນຄ້າໃນລາຍການ ຫຼື ມູນຄ່າເປັນ 0.',
              style: TextStyle(
                fontFamily: 'NotoSansLao',
                color: AppColors.white,
              ),
            ),
            backgroundColor: AppColors.orangeAccent,
          ),
        );
      }
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent, // Make the background transparent
      builder: (BuildContext bc) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(16.0),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min, // Take minimum height
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'ເລືອກວິທີຊໍາລະເງິນ',
                  style: TextStyle(
                    fontFamily: 'NotoSansLao',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryBlue,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: Icon(Icons.money, color: AppColors.salesAccentColor),
                  title: const Text(
                    'ຈ່າຍດ້ວຍເງິນສົດ',
                    style: TextStyle(
                      fontFamily: 'NotoSansLao',
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                    size: 18,
                    color: AppColors.textMutedColor,
                  ),
                  onTap: () {
                    Navigator.pop(bc); // Close the bottom sheet
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => HomePayment(
                          cust_code: widget.cust_code,
                          total_amount: _totalAmount.toString(),
                        ),
                      ),
                    ).then((value) => _refreshOrderItems());
                  },
                ),
                Divider(color: AppColors.grey300),
                ListTile(
                  leading: Icon(Icons.qr_code, color: AppColors.primaryBlue),
                  title: const Text(
                    'ຈ່າຍດ້ວຍການໂອນ',
                    style: TextStyle(
                      fontFamily: 'NotoSansLao',
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                    size: 18,
                    color: AppColors.textMutedColor,
                  ),
                  onTap: () {
                    Navigator.pop(bc); // Close the bottom sheet
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => Payment(
                          cust_code: widget.cust_code,
                          total_amount: _totalAmount.toString(),
                        ),
                      ),
                    ).then((value) => _refreshOrderItems());
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBlue,
      appBar: AppBar(
        title: const Text(
          "ໜ້າຂາຍສິນຄ້າ",
          style: TextStyle(color: AppColors.white, fontFamily: 'NotoSansLao'),
        ),
        backgroundColor: AppColors.primaryBlue,
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: AppColors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "ມູນຄ່າທັງໝົດ:",
                    style: TextStyle(
                      fontFamily: 'NotoSansLao',
                      fontSize: 18,
                      color: AppColors.textMutedColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    _currencyFormatter.format(_totalAmount),
                    style: TextStyle(
                      fontFamily: 'NotoSansLao',
                      fontSize: 22,
                      color: AppColors.salesAccentColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                StockSale(custcode: widget.cust_code),
                          ),
                        ).then((value) => _refreshOrderItems());
                      },
                      icon: const Icon(
                        Icons.add_shopping_cart,
                        color: AppColors.white,
                        size: 20,
                      ),
                      label: const Text(
                        "ເພີ່ມສິນຄ້າ",
                        style: TextStyle(
                          fontFamily: 'NotoSansLao',
                          color: AppColors.white,
                          fontSize: 15,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.buttonPrimaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 12,
                        ),
                        elevation: 3,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed:
                          _showPaymentMethodSelection, // Call the new selection function
                      icon: const Icon(
                        Icons.attach_money_rounded,
                        size: 20,
                        color: AppColors.white,
                      ),
                      label: const Text(
                        "ຮັບເງິນ",
                        style: TextStyle(
                          fontFamily: 'NotoSansLao',
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.salesAccentColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 12,
                        ),
                        elevation: 3,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      body: _currentOrderItems.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_bag_outlined,
                    size: 80,
                    color: AppColors.grey300,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "ຍັງບໍ່ມີສິນຄ້າໃນລາຍການຂາຍ.",
                    style: TextStyle(
                      fontFamily: 'NotoSansLao',
                      fontSize: 18,
                      color: AppColors.textMutedColor,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "ກົດປຸ່ມ 'ເພີ່ມສິນຄ້າ' ເພື່ອເລີ່ມຕົ້ນ.",
                    style: TextStyle(
                      fontFamily: 'NotoSansLao',
                      fontSize: 15,
                      color: AppColors.grey500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: _currentOrderItems.length,
              padding: const EdgeInsets.all(16.0),
              itemBuilder: (_, index) {
                final item = _currentOrderItems[index];
                final double itemSumAmount =
                    double.tryParse(item['sum_amount']?.toString() ?? '0.0') ??
                    0.0;

                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: item['product_type'] == 'main'
                                ? AppColors.primaryBlue.withOpacity(0.1)
                                : AppColors.orange100.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            item['product_type'] == 'main'
                                ? Icons.inventory_2_outlined
                                : Icons.card_giftcard_outlined,
                            color: item['product_type'] == 'main'
                                ? AppColors.primaryBlue
                                : AppColors.orange600,
                            size: 24,
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
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: AppColors.black87,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_currencyFormatter.format(double.tryParse(item['price']?.toString() ?? '0.0') ?? 0.0)} x ${item['qty']} ${item['unit_code']} (-${item['discount']}%)',
                                style: TextStyle(
                                  fontFamily: 'NotoSansLao',
                                  fontSize: 12,
                                  color: AppColors.textMutedColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _currencyFormatter.format(itemSumAmount),
                          style: TextStyle(
                            fontFamily: 'NotoSansLao',
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.salesAccentColor,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: AppColors.redAccent,
                          ),
                          onPressed: () => _confirmDeleteOrderItem(
                            item['item_code'].toString(),
                            item['item_name'].toString(),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
