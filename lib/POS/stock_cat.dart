import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:odgcashvan/utility/my_constant.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StockCat extends StatefulWidget {
  const StockCat({super.key});

  @override
  State<StockCat> createState() => _StockCatState();
}

class _StockCatState extends State<StockCat> {
  List _data = []; // Renamed for consistency
  bool _isLoading = false; // Added loading state

  // Define consistent colors
  final Color _primaryBlue = Colors.blue.shade600;
  final Color _accentBlue = Colors.blue.shade800;
  final Color _cardBgColor = Colors.white;
  final Color _cardBorderColor = Colors.grey.shade200;
  final Color _categoryNameColor = Colors.black87;
  final Color _itemCountColor =
      Colors.deepPurple.shade700; // Distinct color for count
  final Color _mutedTextColor = Colors.grey.shade600;

  @override
  void initState() {
    super.initState();
    _showData(); // Renamed for consistency
  }

  Future<void> _showData() async {
    setState(() {
      _isLoading = true; // Start loading
    });
    SharedPreferences preferences = await SharedPreferences.getInstance();
    try {
      String datas = json.encode({
        "wh_code": preferences.getString('wh_code').toString(),
        "sh_code": preferences.getString('sh_code').toString(),
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
          "ໝວດສິນຄ້າ",
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
                    Icons.category_outlined,
                    size: 80,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "ບໍ່ພົບໝວດສິນຄ້າ.",
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
                    "ກະລຸນາກວດສອບຂໍ້ມູນສາງຂອງທ່ານ.",
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
          : Padding(
              padding: const EdgeInsets.all(
                10.0,
              ), // Overall padding for the grid
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Dynamically adjust crossAxisCount based on screen width
                  int crossAxisCount = 2; // Default for mobile portrait
                  if (constraints.maxWidth > 800) {
                    crossAxisCount = 4; // For tablets or larger screens
                  } else if (constraints.maxWidth > 500) {
                    crossAxisCount =
                        3; // For slightly larger phones or landscape
                  }

                  return GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 12, // Increased spacing between columns
                      mainAxisSpacing: 12, // Increased spacing between rows
                      childAspectRatio:
                          1.0, // Make cards square-like for better visual balance
                    ),
                    itemCount: _data.length,
                    itemBuilder: (context, index) {
                      return Card(
                        elevation: 4, // Add elevation for a lifted effect
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            15,
                          ), // More rounded corners
                          side: BorderSide(
                            color: _cardBorderColor,
                            width: 1,
                          ), // Subtle border
                        ),
                        color: _cardBgColor, // White background for card
                        clipBehavior: Clip
                            .antiAlias, // Ensures content respects rounded corners
                        child: InkWell(
                          // Provides ripple effect on tap
                          onTap: () {
                            Navigator.of(context).pop({
                              "code": _data[index]['cat_code'],
                              "name_1": _data[index]['cat_name'],
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(
                              12.0,
                            ), // Padding inside each card
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment
                                  .center, // Vertically center content
                              crossAxisAlignment: CrossAxisAlignment
                                  .center, // Horizontally center content
                              children: [
                                Icon(
                                  Icons.category, // Icon representing category
                                  size: 40,
                                  color: _primaryBlue, // Primary color for icon
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  '${_data[index]['count_item']}', // Item count
                                  style: TextStyle(
                                    color: _itemCountColor,
                                    fontSize: 32, // Large font for count
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'NotoSansLao',
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                Text(
                                  'ລາຍການ', // Label for item count
                                  style: TextStyle(
                                    color: _mutedTextColor,
                                    fontSize: 14,
                                    fontFamily: 'NotoSansLao',
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 10),
                                // Separator or subtle divider for category name
                                Divider(
                                  height: 1,
                                  thickness: 0.5,
                                  color: Colors.grey.shade300,
                                ),
                                const SizedBox(height: 10),
                                Expanded(
                                  // Ensure category name doesn't overflow
                                  child: Text(
                                    '${_data[index]['cat_name']}', // Category name
                                    style: TextStyle(
                                      color: _categoryNameColor,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'NotoSansLao',
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
    );
  }
}
