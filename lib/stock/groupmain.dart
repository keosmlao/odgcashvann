import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:odgcashvan/utility/my_constant.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GroupMain extends StatefulWidget {
  const GroupMain({super.key});

  @override
  State<GroupMain> createState() => _GroupMainState();
}

class _GroupMainState extends State<GroupMain> {
  List _data = [];
  bool _isLoading = false;

  // Define consistent colors
  final Color _primaryBlue = Colors.blue.shade600;
  final Color _cardBgColor = Colors.white;
  final Color _cardBorderColor = Colors.grey.shade200;
  final Color _groupNameColor = Colors.black87;
  final Color _mutedTextColor = Colors.grey.shade600;
  final Color _arrowIconColor =
      Colors.grey.shade400; // Color for trailing arrow

  @override
  void initState() {
    super.initState();
    _showData();
  }

  Future<void> _showData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      var response = await get(
        Uri.parse("${MyConstant().domain}/vansale_groupmain"),
      );

      if (response.statusCode == 200) {
        var result = json.decode(response.body);
        setState(() {
          _data = result['list'];
        });
      } else {
        _showInfoSnackBar(
          'Failed to load main groups: ${response.statusCode}',
          Colors.red,
        );
        print("Failed to load data: ${response.statusCode}");
      }
    } catch (error) {
      _showInfoSnackBar('Error loading main groups: $error', Colors.red);
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
          "ກຸ່ມສິນຄ້າຫຼັກ",
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
                    Icons.category_outlined,
                    size: 80,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "ບໍ່ພົບກຸ່ມສິນຄ້າຫຼັກ.",
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
                    "ກະລຸນາກວດສອບການຕັ້ງຄ່າຂໍ້ມູນຂອງທ່ານ.",
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
              padding: const EdgeInsets.all(
                10.0,
              ), // Overall padding for the list
              itemCount: _data.length,
              itemBuilder: (context, index) {
                final groupItem = _data[index];
                final String imageUrl = groupItem['name_2'] ?? '';

                return Card(
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
                        "code": groupItem['code'],
                        "name_1": groupItem['name_1'],
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(
                        8.0,
                      ), // Padding inside each card
                      child: Row(
                        // Row for image and text
                        children: [
                          // Image on the left
                          Container(
                            width: 70, // Fixed width for the image
                            height: 70, // Fixed height for the image
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: Colors
                                  .grey
                                  .shade200, // Placeholder background
                            ),
                            clipBehavior: Clip.antiAlias,
                            child:
                                (imageUrl.isNotEmpty &&
                                    Uri.tryParse(imageUrl)?.hasAbsolutePath ==
                                        true)
                                ? Image.network(
                                    imageUrl,
                                    fit: BoxFit.cover,
                                    loadingBuilder:
                                        (context, child, loadingProgress) {
                                          if (loadingProgress == null)
                                            return child;
                                          return Center(
                                            child: CircularProgressIndicator(
                                              value:
                                                  loadingProgress
                                                          .expectedTotalBytes !=
                                                      null
                                                  ? loadingProgress
                                                            .cumulativeBytesLoaded /
                                                        loadingProgress
                                                            .expectedTotalBytes!
                                                  : null,
                                              color: _primaryBlue,
                                            ),
                                          );
                                        },
                                    errorBuilder: (context, error, stackTrace) {
                                      return Icon(
                                        Icons.broken_image_outlined,
                                        size: 40,
                                        color: Colors.grey.shade400,
                                      );
                                    },
                                  )
                                : Icon(
                                    Icons
                                        .image_not_supported_outlined, // Placeholder icon
                                    size: 40,
                                    color: Colors.grey.shade400,
                                  ),
                          ),
                          const SizedBox(
                            width: 16,
                          ), // Space between image and text
                          // Group Name on the right
                          Expanded(
                            child: Text(
                              groupItem['name_1'].toString(),
                              style: TextStyle(
                                color: _groupNameColor,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'NotoSansLao',
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8), // Space before arrow
                          // Trailing arrow
                          Icon(
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
