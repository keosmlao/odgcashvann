// lib/POS/product_filter_modal.dart
import 'package:flutter/material.dart';
import 'package:odgcashvan/stock/brand.dart';
import 'package:odgcashvan/stock/cat.dart';
import 'package:odgcashvan/stock/group_sub.dart';
import 'package:odgcashvan/stock/group_sub_2.dart';
import 'package:odgcashvan/stock/groupmain.dart';
import 'package:odgcashvan/stock/pettern.dart';
import 'package:odgcashvan/utility/my_constant.dart'; // Assuming MyConstant is needed for API calls within filter selection pages
import 'package:odgcashvan/utility/my_style.dart'; // Assuming MyStyle is needed for colors

class ProductFilterModal extends StatefulWidget {
  final Map<String, String?> currentFilters;
  final String? whCode;
  final String? shCode;

  const ProductFilterModal({
    super.key,
    required this.currentFilters,
    this.whCode,
    this.shCode,
  });

  @override
  State<ProductFilterModal> createState() => _ProductFilterModalState();
}

class _ProductFilterModalState extends State<ProductFilterModal> {
  // Local controllers and variables for the modal's filter selections
  String? _group_main,
      _group_sub,
      _group_sub_2,
      _cat_code,
      _brand_code,
      _pattern_code;
  final TextEditingController _group_main_name = TextEditingController();
  final TextEditingController _group_sub_name = TextEditingController();
  final TextEditingController _group_sub_name_2 = TextEditingController();
  final TextEditingController _cat = TextEditingController();
  final TextEditingController _brand = TextEditingController();
  final TextEditingController _petten = TextEditingController();

  // Define consistent colors for the theme based on MyStyle
  final Color _inputFieldFillColor = Colors.white;
  final Color _inputFieldBorderColor = Colors.grey.shade400;
  final Color _inputFieldFocusedBorderColor = Colors.blue.shade700;
  final Color _defaultIconColor = Colors.grey.shade700;
  final Color _textColor = Colors.black87;
  final Color _mutedColor = Colors.grey.shade600;

  @override
  void initState() {
    super.initState();
    // Initialize modal's state with current filters passed from parent
    _group_main = widget.currentFilters['group_main'];
    _group_sub = widget.currentFilters['group_sub'];
    _group_sub_2 = widget.currentFilters['group_sub_2'];
    _cat_code = widget.currentFilters['cat_code'];
    _brand_code = widget.currentFilters['brand_code'];
    _pattern_code = widget.currentFilters['pattern_code'];

    _group_main_name.text = widget.currentFilters['group_main_name'] ?? '';
    _group_sub_name.text = widget.currentFilters['group_sub_name'] ?? '';
    _group_sub_name_2.text = widget.currentFilters['group_sub_2_name'] ?? '';
    _cat.text = widget.currentFilters['cat_name'] ?? '';
    _brand.text = widget.currentFilters['brand_name'] ?? '';
    _petten.text = widget.currentFilters['pattern_name'] ?? '';
  }

  // Helper method for filter input fields (similar to the one in StockSale)
  Widget _buildFilterInputField({
    required TextEditingController controller,
    required String hintText,
    required VoidCallback onPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: TextFormField(
        controller: controller,
        readOnly: true,
        style: TextStyle(
          fontSize: 16,
          color: _textColor,
          fontFamily: 'NotoSansLao',
        ),
        textAlign: TextAlign.center,
        decoration: InputDecoration(
          filled: true,
          fillColor: _inputFieldFillColor,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 10.0,
            vertical: 10.0,
          ),
          hintText: hintText,
          hintStyle: TextStyle(
            fontSize: 16,
            fontFamily: 'NotoSansLao',
            color: _mutedColor,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: BorderSide(color: _inputFieldBorderColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: BorderSide(color: _inputFieldBorderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: BorderSide(
              color: _inputFieldFocusedBorderColor,
              width: 2,
            ),
          ),
          suffixIcon: IconButton(
            icon: Icon(Icons.search, color: _defaultIconColor),
            onPressed: onPressed,
            tooltip: 'ເລືອກ $hintText',
          ),
        ),
      ),
    );
  }

  // Method to clear all filters
  void _clearFilters() {
    setState(() {
      _group_main = null;
      _group_sub = null;
      _group_sub_2 = null;
      _cat_code = null;
      _brand_code = null;
      _pattern_code = null;
      _group_main_name.clear();
      _group_sub_name.clear();
      _group_sub_name_2.clear();
      _cat.clear();
      _brand.clear();
      _petten.clear();
    });
  }

  // Method to apply filters and return to parent
  void _applyFilters() {
    Navigator.pop(context, {
      'group_main': _group_main,
      'group_sub': _group_sub,
      'group_sub_2': _group_sub_2,
      'cat_code': _cat_code,
      'brand_code': _brand_code,
      'pattern_code': _pattern_code,
      'group_main_name': _group_main_name.text,
      'group_sub_name': _group_sub_name.text,
      'group_sub_2_name': _group_sub_name_2.text,
      'cat_name': _cat.text,
      'brand_name': _brand.text,
      'pattern_name': _petten.text,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Theme.of(context).canvasColor, // Use theme's background color
        borderRadius: const BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Make it wrap content
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              height: 4,
              width: 40,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "ກັ່ນຕອງສິນຄ້າ",
            style: TextStyle(
              fontFamily: 'NotoSansLao',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Expanded(
            // Use Expanded to make the filter fields scrollable if too many
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildFilterInputField(
                    controller: _group_main_name,
                    hintText: "ກຸ່ມຫຼັກ",
                    onPressed: () async {
                      final result = await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const GroupMain(),
                        ),
                      );
                      if (result != null) {
                        setState(() {
                          _group_main_name.text = result['name_1'];
                          _group_main = result['code'];
                        });
                      }
                    },
                  ),
                  _buildFilterInputField(
                    controller: _group_sub_name,
                    hintText: "ກຸ່ມຍ່ອຍ 1",
                    onPressed: () async {
                      final result = await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) =>
                              GroupSub(groupMain: _group_main.toString()),
                        ),
                      );
                      if (result != null) {
                        setState(() {
                          _group_sub_name.text = result['name_1'];
                          _group_sub = result['code'];
                        });
                      }
                    },
                  ),
                  _buildFilterInputField(
                    controller: _group_sub_name_2,
                    hintText: "ກຸ່ມຍ່ອຍ 2",
                    onPressed: () async {
                      final result = await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => GroupSub2(
                            group_main: _group_main.toString(),
                            group_sub: _group_sub.toString(),
                          ),
                        ),
                      );
                      if (result != null) {
                        setState(() {
                          _group_sub_name_2.text = result['name_1'];
                          _group_sub_2 = result['code'];
                        });
                      }
                    },
                  ),
                  _buildFilterInputField(
                    controller: _cat,
                    hintText: "ໝວດ",
                    onPressed: () async {
                      final result = await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => Cat(
                            wh_code: widget.whCode.toString(),
                            sh_code: widget.shCode.toString(),
                            group_main: _group_main.toString(),
                            group_sub: _group_sub.toString(),
                            group_sub_2: _group_sub_2.toString(),
                            cat: _cat_code.toString(),
                            pattern: _pattern_code.toString(),
                            brand: _brand_code.toString(),
                          ),
                        ),
                      );
                      if (result != null) {
                        setState(() {
                          _cat.text = result['name_1'];
                          _cat_code = result['code'];
                        });
                      }
                    },
                  ),
                  _buildFilterInputField(
                    controller: _petten,
                    hintText: "ຮູບແບບ",
                    onPressed: () async {
                      final result = await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => Pettern(
                            wh_code: widget.whCode.toString(),
                            sh_code: widget.shCode.toString(),
                            group_main: _group_main.toString(),
                            group_sub: _group_sub.toString(),
                            group_sub_2: _group_sub_2.toString(),
                            cat: _cat_code.toString(),
                            pattern: _pattern_code.toString(),
                            brand: _brand_code.toString(),
                          ),
                        ),
                      );
                      if (result != null) {
                        setState(() {
                          _petten.text = result['name_1'];
                          _pattern_code = result['code'];
                        });
                      }
                    },
                  ),
                  _buildFilterInputField(
                    controller: _brand,
                    hintText: "ຫຍີ່ຫໍ້",
                    onPressed: () async {
                      final result = await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => Brand(
                            wh_code: widget.whCode.toString(),
                            sh_code: widget.shCode.toString(),
                            group_main: _group_main.toString(),
                            group_sub: _group_sub.toString(),
                            group_sub_2: _group_sub_2.toString(),
                            cat: _cat_code.toString(),
                            pattern: _pattern_code.toString(),
                            brand: _brand_code.toString(),
                          ),
                        ),
                      );
                      if (result != null) {
                        setState(() {
                          _brand.text = result['name_1'];
                          _brand_code = result['code'];
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _clearFilters,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    "ລົບລ້າງ",
                    style: TextStyle(fontFamily: 'NotoSansLao', fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _applyFilters,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        Colors.blue.shade700, // Use a strong blue for apply
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    "ນຳໃຊ້",
                    style: TextStyle(fontFamily: 'NotoSansLao', fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(
            height: MediaQuery.of(context).viewInsets.bottom > 0 ? 0 : 20,
          ), // Prevent keyboard overlap
        ],
      ),
    );
  }
}
