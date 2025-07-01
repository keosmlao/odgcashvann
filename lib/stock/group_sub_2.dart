import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utility/my_constant.dart';

class GroupSub2 extends StatefulWidget {
  final String group_main; // Use 'final' for StatefulWidget properties
  final String group_sub; // Use 'final' for StatefulWidget properties
  const GroupSub2({
    super.key,
    required this.group_main,
    required this.group_sub,
  });

  @override
  State<GroupSub2> createState() => _GroupSub2State();
}

class _GroupSub2State extends State<GroupSub2> {
  List _data = []; // Renamed for consistency
  bool _isLoading = false; // Added loading state

  // Define consistent colors
  final Color _primaryBlue = Colors.blue.shade600;
  final Color _cardBgColor = Colors.white;
  final Color _cardBorderColor = Colors.grey.shade200;
  final Color _groupNameColor = Colors.black87;
  final Color _mutedTextColor = Colors.grey.shade600;
  final Color _arrowIconColor = Colors.grey.shade400;

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
      var response = await get(
        Uri.parse(
          "${MyConstant().domain}/vansale_groupsub2/${widget.group_main}/${widget.group_sub}",
        ),
      );

      if (response.statusCode == 200) {
        var result = json.decode(response.body);
        setState(() {
          _data = result['list'];
        });
      } else {
        // Handle non-200 responses
        _showInfoSnackBar(
          'Failed to load sub groups (level 2): ${response.statusCode}',
          Colors.red,
        );
        print("Failed to load data: ${response.statusCode}");
      }
    } catch (error) {
      // Handle network or parsing errors
      _showInfoSnackBar(
        'Error loading sub groups (level 2): $error',
        Colors.red,
      );
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
          "ກຸ່ມສິນຄ້າຍ່ອຍ 2", // Changed title to reflect "Sub Group 2"
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
                    "ບໍ່ພົບກຸ່ມສິນຄ້າຍ່ອຍ 2.", // Message for no sub groups (level 2)
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
                    "ກະລຸນາກວດສອບກຸ່ມຫຼັກ ແລະ ກຸ່ມຍ່ອຍ 1 ທີ່ເລືອກ.", // Suggestion
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
                final String imageUrl =
                    groupItem['name_2'] ??
                    ''; // Assuming name_2 is the image URL

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
