import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:odgcashvan/utility/my_constant.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StockBand extends StatefulWidget {
  const StockBand({super.key});

  @override
  State<StockBand> createState() => _StockBandState();
}

class _StockBandState extends State<StockBand> {
  List _data = [];
  bool _isLoading = false;

  // Define consistent colors
  final Color _primaryBlue = Colors.blue.shade600;
  final Color _accentBlue = Colors.blue.shade800;
  final Color _cardBgColor = Colors.white;
  final Color _cardBorderColor = Colors.grey.shade200;
  final Color _brandNameColor = Colors.black87;
  final Color _itemCountColor = Colors.deepPurple.shade700;
  final Color _mutedTextColor = Colors.grey.shade600;

  @override
  void initState() {
    super.initState();
    _showData();
  }

  Future<void> _showData() async {
    setState(() {
      _isLoading = true;
    });
    SharedPreferences preferences = await SharedPreferences.getInstance();
    try {
      String datas = json.encode({
        "wh_code": preferences.getString('wh_code').toString(),
        "sh_code": preferences.getString('sh_code').toString(),
      });
      var response = await post(
        Uri.parse("${MyConstant().domain}/vanstockBrand"),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: datas,
      );

      if (response.statusCode == 200) {
        var result = json.decode(response.body);
        setState(() {
          _data = result['list'];
        });
      } else {
        _showInfoSnackBar(
          'Failed to load brands: ${response.statusCode}',
          Colors.red,
        );
        print("Failed to load data: ${response.statusCode}");
      }
    } catch (error) {
      _showInfoSnackBar('Error loading brands: $error', Colors.red);
      print("Error: $error");
    } finally {
      setState(() {
        _isLoading = false;
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
              fontFamily: 'NotoSansLao',
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
          "ຍີ່ຫໍ້ສິນຄ້າ",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontFamily: 'NotoSansLao',
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: _primaryBlue,
        centerTitle: true,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: _primaryBlue))
          : _data.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.branding_watermark_outlined,
                    size: 80,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "ບໍ່ພົບຍີ່ຫໍ້ສິນຄ້າ.",
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
          : ListView.builder(
              // Changed from GridView.builder to ListView.builder
              padding: const EdgeInsets.all(10.0), // Padding for the list
              itemCount: _data.length,
              itemBuilder: (context, index) {
                final brandItem = _data[index];
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
                    side: BorderSide(color: _cardBorderColor, width: 1),
                  ),
                  color: _cardBgColor,
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () {
                      Navigator.of(context).pop({
                        "code": brandItem['brand_code'],
                        "name_1": brandItem['brand_name'],
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
                            Icons.label_outline, // Icon representing brand
                            size: 30,
                            color: _primaryBlue,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  brandItem['brand_name'].toString(),
                                  style: TextStyle(
                                    color: _brandNameColor,
                                    fontSize: 18, // Larger font for brand name
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'NotoSansLao',
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${brandItem['count_item']} ລາຍການ', // Combined count and label
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
                          Icon(
                            // Optional: Add a trailing arrow
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: Colors.grey.shade400,
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
