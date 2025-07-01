import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:odgcashvan/utility/my_constant.dart';

class Cat extends StatefulWidget {
  final String wh_code; // Use 'final' for StatefulWidget properties
  final String sh_code;
  final String group_main;
  final String group_sub;
  final String group_sub_2;
  final String cat; // This 'cat' parameter seems unused in the API call body
  final String pattern;
  final String brand;

  const Cat({
    super.key,
    required this.wh_code,
    required this.sh_code,
    required this.group_main,
    required this.group_sub,
    required this.group_sub_2,
    required this.cat, // Keep if needed for navigation, but note API call
    required this.pattern,
    required this.brand,
  });

  @override
  State<Cat> createState() => _CatState();
}

class _CatState extends State<Cat> {
  List _data = []; // Renamed for consistency
  bool _isLoading = false; // Added loading state

  // Define consistent colors
  final Color _primaryBlue = Colors.blue.shade600;
  final Color _cardBgColor = Colors.white;
  final Color _cardBorderColor = Colors.grey.shade200;
  final Color _categoryNameColor = Colors.black87;
  final Color _itemCountColor =
      Colors.deepPurple.shade700; // Distinct color for count
  final Color _mutedTextColor = Colors.grey.shade600;
  final Color _arrowIconColor =
      Colors.grey.shade400; // Color for trailing arrow

  @override
  void initState() {
    super.initState();
    _showData(); // Renamed for consistency
  }

  Future<void> _showData() async {
    setState(() {
      _isLoading = true; // Start loading
    });

    try {
      String datas = json.encode({
        "wh_code": widget.wh_code.toString(),
        "sh_code": widget.sh_code.toString(),
        "group_main": widget.group_main.toString(),
        "group_sub": widget.group_sub.toString(),
        "group_sub_2": widget.group_sub_2.toString(),
        "cat": "", // API call specifies empty string for 'cat'
        "pattern": widget.pattern.toString(),
        "item_brand": widget.brand,
      });

      var response = await post(
        Uri.parse("${MyConstant().domain}/vanstockCat"),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: datas,
      );

      if (response.statusCode == 200) {
        var result = json.decode(response.body);
        setState(() {
          _data = result['list'];
        });
      } else {
        // Handle non-200 responses
        _showInfoSnackBar(
          'Failed to load categories: ${response.statusCode}',
          Colors.red,
        );
        print("Failed to load data: ${response.statusCode}");
      }
    } catch (error) {
      // Handle network or parsing errors
      _showInfoSnackBar('Error loading categories: $error', Colors.red);
      print("Error: $error");
    } finally {
      setState(() {
        _isLoading = false; // End loading
      });
    }
  }

  void _showInfoSnackBar(String message, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(
              fontFamily: 'NotoSansLao', // Ensure font consistency
              color: Colors.white,
            ),
          ),
          backgroundColor: color,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "ໝວດສິນຄ້າ", // Title for categories
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontFamily: 'NotoSansLao', // Apply consistent font
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: _primaryBlue,
        centerTitle: true,
        foregroundColor: Colors.white, // Ensures back button is white
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: _primaryBlue,
              ), // Loading indicator
            )
          : _data.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.category_outlined, // Relevant icon for categories
                    size: 80,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "ບໍ່ພົບໝວດສິນຄ້າ.", // Message for no categories
                    style: TextStyle(
                      fontFamily: 'NotoSansLao',
                      fontSize: 18,
                      color: _mutedTextColor,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "ກະລຸນາກວດສອບຕົວກອງທີ່ເລືອກ.", // Suggestion
                    style: TextStyle(
                      fontFamily: 'NotoSansLao',
                      fontSize: 15,
                      color: Colors.grey.shade500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : ListView.builder(
              // Changed from GridView.builder to ListView.builder
              padding: const EdgeInsets.all(
                10.0,
              ), // Overall padding for the list
              itemCount: _data.length,
              itemBuilder: (context, index) {
                final categoryItem = _data[index];
                // No image URL seems to be available in this data, so we'll use an icon

                return Card(
                  // Each item is a Card
                  elevation: 2, // Subtle elevation for list items
                  margin: const EdgeInsets.symmetric(
                    vertical: 6,
                  ), // Vertical spacing between cards
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      10,
                    ), // Slightly rounded corners
                    side: BorderSide(
                      color: _cardBorderColor,
                      width: 1,
                    ), // Subtle border
                  ),
                  color: _cardBgColor,
                  clipBehavior: Clip
                      .antiAlias, // Ensures content respects rounded corners
                  child: InkWell(
                    // Provides ripple effect on tap
                    onTap: () {
                      Navigator.of(context).pop({
                        "code": categoryItem['item_category'],
                        "name_1": categoryItem['item_cat_name'],
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 12.0,
                      ),
                      child: Row(
                        // Using a Row for content in ListView
                        children: [
                          Icon(
                            Icons.folder_open, // A suitable icon for category
                            size: 30,
                            color: _primaryBlue,
                          ),
                          const SizedBox(
                            width: 16,
                          ), // Space between icon and text

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  categoryItem['item_cat_name']
                                      .toString(), // Category name
                                  style: TextStyle(
                                    color: _categoryNameColor,
                                    fontSize:
                                        18, // Larger font for category name
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'NotoSansLao',
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${categoryItem['count_item']} ລາຍການ', // Combined count and label
                                  style: TextStyle(
                                    color: _itemCountColor,
                                    fontSize: 14,
                                    fontFamily: 'NotoSansLao',
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8), // Space before arrow

                          Icon(
                            // Trailing arrow
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: _arrowIconColor,
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
}
