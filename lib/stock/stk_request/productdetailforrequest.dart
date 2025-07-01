import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:odgcashvan/utility/my_constant.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../database/sql_helper.dart';
import '../../utility/my_style.dart'; // Assuming MyStyle has colors like odien1, odien3

class ProductDetailForRequest extends StatefulWidget {
  final String item_code;
  final String item_name;
  final String unit_code;
  final String barcode;
  final String
  qty; // This 'qty' is the available balance, so it should be parsed to int

  const ProductDetailForRequest({
    super.key,
    required this.item_code,
    required this.item_name,
    required this.unit_code,
    required this.barcode,
    required this.qty,
  });

  @override
  State<ProductDetailForRequest> createState() =>
      _ProductDetailForRequestState();
}

class _ProductDetailForRequestState extends State<ProductDetailForRequest> {
  List<dynamic> _stockDetails = []; // Renamed 'data' for clarity
  final TextEditingController _quantityController = TextEditingController();
  bool _isLoadingDetails = false; // Loading state for stock details
  final _formKey = GlobalKey<FormState>(); // For form validation

  @override
  void initState() {
    super.initState();
    _fetchStockDetails();
    _quantityController.text = '1'; // Default quantity to 1
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _fetchStockDetails() async {
    setState(() {
      _isLoadingDetails = true;
    });

    try {
      SharedPreferences preferences = await SharedPreferences.getInstance();
      String? whCode = preferences.getString('wh_code');

      if (whCode == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Warehouse code not found.')),
          );
        }
        return;
      }

      final response = await get(
        Uri.parse("${MyConstant().domain}/stockbalancedetail/$whCode"),
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        setState(() {
          _stockDetails = result['list'] ?? []; // Handle null list
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to load stock details: ${response.statusCode}',
              ),
            ),
          );
        }
      }
    } catch (e) {
      print('Error fetching stock details: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('An error occurred. Try again.')),
        );
      }
    } finally {
      setState(() {
        _isLoadingDetails = false;
      });
    }
  }

  Future<void> _addItemToDraft() async {
    if (_formKey.currentState!.validate()) {
      final int requestedQty = int.parse(_quantityController.text);
      final int availableQty = int.parse(widget.qty);

      if (requestedQty > availableQty) {
        _showAlertDialog(
          title: "ຄຳເຕືອນ",
          content: "ຈຳນວນທີ່ຂໍເກີນຈຳນວນທີ່ມີໃນສະຕ໋ອກລົດ",
        );
        return;
      }

      if (requestedQty <= 0) {
        _showAlertDialog(
          title: "ຄຳເຕືອນ",
          content: "ກະລຸນາປ້ອນຈຳນວນຫຼາຍກວ່າ 0",
        );
        return;
      }

      try {
        await SQLHelper.addtodraftRp(
          widget.item_code,
          widget.item_name,
          widget.unit_code,
          widget.barcode,
          _quantityController.text, // Save as string
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('ເພີ່ມລາຍການສຳເລັດ!'), // Item added successfully
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2), // Show for 2 seconds
            ),
          );
          Navigator.pop(context); // Pop back to previous screen
        }
      } catch (e) {
        print('Error adding item to draft: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'ເກີດຂໍ້ຜິດພາດໃນການເພີ່ມລາຍການ',
              ), // Error adding item
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    }
  }

  void _showAlertDialog({required String title, required String content}) {
    showCupertinoDialog(
      context: context,
      builder: (context) {
        return CupertinoAlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ຕົກລົງ'), // OK
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "ລາຍລະອຽດສິນຄ້າ", // Product Details
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: MyStyle().odien1,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Product Name and Code
                Text(
                  widget.item_name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.item_code,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const Divider(height: 24, thickness: 1),

                // Available Quantity
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.inventory, color: Colors.blueGrey),
                    const SizedBox(width: 8),
                    Text(
                      'ຈຳນວນຄົງເຫຼືອ: ${widget.qty} ${widget.unit_code}', // Available quantity
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.blueAccent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Quantity Input Field
                TextFormField(
                  controller: _quantityController,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'ຈຳນວນທີ່ຕ້ອງການ', // Requested Quantity
                    labelStyle: const TextStyle(color: Colors.grey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: BorderSide(color: MyStyle().odien1, width: 2),
                    ),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.add_circle, color: Colors.green),
                      onPressed: () {
                        int currentQty =
                            int.tryParse(_quantityController.text) ?? 0;
                        _quantityController.text = (currentQty + 1).toString();
                      },
                    ),
                    prefixIcon: IconButton(
                      icon: const Icon(Icons.remove_circle, color: Colors.red),
                      onPressed: () {
                        int currentQty =
                            int.tryParse(_quantityController.text) ?? 0;
                        if (currentQty > 1) {
                          _quantityController.text = (currentQty - 1)
                              .toString();
                        }
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'ກະລຸນາປ້ອນຈຳນວນ'; // Please enter quantity
                    }
                    if (int.tryParse(value) == null) {
                      return 'ປ້ອນຕົວເລກເທົ່ານັ້ນ'; // Enter numbers only
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 30),

                // Add Item Button
                ElevatedButton.icon(
                  onPressed: _addItemToDraft,
                  icon: const Icon(
                    Icons.add_shopping_cart,
                    color: Colors.white,
                    size: 28,
                  ),
                  label: const Text(
                    "ເພີ່ມເຂົ້າລາຍການຂໍ", // Add to Request List
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        MyStyle().odien1, // Use a consistent theme color
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 5,
                  ),
                ),
                const SizedBox(height: 20),

                // Section Title for Stock in Van
                // Moved from inside _stockDetails.isEmpty check
                Text(
                  "ລາຍການສິນຄ້ານີ້ໃນສາງລົດ", // Items of this product in van stock
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: MyStyle().odien3,
                  ),
                  textAlign: TextAlign.center,
                ),
                const Divider(height: 20, thickness: 1),

                // Stock Details List
                _isLoadingDetails
                    ? const Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : _stockDetails.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Center(
                          child: Text(
                            "ບໍ່ມີຂໍ້ມູນສິນຄ້ານີ້ໃນສາງລົດ", // No stock details in van
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _stockDetails.length,
                        itemBuilder: (BuildContext context, int index) {
                          final stockItem = _stockDetails[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              vertical: 6,
                              horizontal: 0,
                            ),
                            elevation: 3, // Slightly more elevation
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                10,
                              ), // More rounded corners
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(
                                16.0,
                              ), // More padding
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Icon for location
                                  Icon(
                                    Icons.location_on,
                                    color: MyStyle().odien1,
                                    size: 28,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'ສະຖານທີ່: ${stockItem['wh'] ?? 'N/A'} : ${stockItem['sh'] ?? 'N/A'}',
                                          style: const TextStyle(
                                            fontSize:
                                                16, // Slightly larger font
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'ຈຳນວນ: ${stockItem['qty']?.toString() ?? 'N/A'} ${stockItem['ic_unit_code'] ?? ''}',
                                          style: const TextStyle(
                                            fontSize: 15,
                                            color: Colors.blueGrey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Optional: Add a subtle quantity indicator
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: MyStyle().odien3.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      '${stockItem['qty']?.toString() ?? '0'}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: MyStyle().odien3,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
