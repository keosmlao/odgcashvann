import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // Use alias for clarity

import '../utility/my_constant.dart';

class ListSock extends StatefulWidget {
  const ListSock({super.key});

  @override
  State<ListSock> createState() => _ListSockState();
}

class _ListSockState extends State<ListSock> {
  List<dynamic> _originalData = []; // Renamed from 'data' for clarity
  List<dynamic> _filteredData = []; // Renamed from 'filteredData'
  TextEditingController _searchController =
      TextEditingController(); // Renamed for consistency
  bool _isLoading = false; // Added loading state
  String? _errorMessage; // Added error message state

  // Define consistent color palette for 'blue soft' theme
  final Color _primaryColor = const Color(
    0xFF64B5F6,
  ); // Light Blue (similar to lightBlue.shade400)
  final Color _accentColor = const Color(
    0xFF2196F3,
  ); // Deeper Blue (similar to blue.shade600)
  final Color _backgroundColor = const Color(
    0xFFE3F2FD,
  ); // Very light Blue (similar to blue.shade50)
  final Color _cardColor = Colors.white; // Pure white for cards
  final Color _textColorPrimary = const Color(
    0xFF212121,
  ); // Almost black for main text
  final Color _textColorSecondary = const Color(
    0xFF757575,
  ); // Medium grey for secondary text
  final Color _errorColor = const Color(0xFFEF5350); // Red for error messages

  @override
  void initState() {
    super.initState();
    _fetchWarehouses(); // Renamed showdata to _fetchWarehouses
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchWarehouses() async {
    // Changed return type to void and renamed
    setState(() {
      _isLoading = true;
      _errorMessage = null; // Clear previous error
    });

    try {
      var response = await http.get(
        Uri.parse(MyConstant().domain + "/listwarehouse"),
      );
      if (response.statusCode == 200) {
        var result = json.decode(response.body);
        setState(() {
          _originalData = result['list'] ?? []; // Ensure it's a list
          _filteredData = _originalData; // Initialize filtered data
          if (_searchController.text.isNotEmpty) {
            // Apply filter if text already present
            _applyFilter(_searchController.text);
          }
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage =
              'ໂຫຼດຂໍ້ມູນສາງບໍ່ສຳເລັດ: ${response.statusCode}'; // Load warehouse data failed
        });
        _showSnackBar(_errorMessage!, _errorColor);
        print(
          "API Error: ${response.statusCode}, Body: ${response.body}",
        ); // Debug
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage =
            'ເກີດຂໍ້ຜິດພາດໃນການໂຫຼດຂໍ້ມູນ: $e'; // Error loading data
      });
      _showSnackBar(_errorMessage!, _errorColor);
      print("Network/Parsing Error: $e"); // Debug
    }
  }

  void _applyFilter(String query) {
    // Renamed filterSearch to _applyFilter
    setState(() {
      if (query.isEmpty) {
        _filteredData = _originalData; // If query is empty, show all data
      } else {
        _filteredData = _originalData.where((item) {
          final itemCode = item['code']?.toString().toLowerCase() ?? '';
          final itemName = item['name_1']?.toString().toLowerCase() ?? '';
          final lowerCaseQuery = query.toLowerCase();
          return itemCode.contains(lowerCaseQuery) ||
              itemName.contains(lowerCaseQuery);
        }).toList();
      }
    });
  }

  void _showSnackBar(String message, Color color) {
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
      backgroundColor: _backgroundColor, // Apply soft blue background
      appBar: AppBar(
        title: const Text(
          "ເລືອກສາງ", // Select Warehouse (more descriptive title)
          style: TextStyle(
            color: Colors.white, // White title for contrast on blue
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: _primaryColor, // Soft blue AppBar
        elevation: 4, // Add a subtle shadow
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white), // White icon
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchWarehouses,
        color: _accentColor, // Color of the refresh indicator
        child: Column(
          children: [
            // --- Search Bar Section ---
            Padding(
              padding: const EdgeInsets.all(16.0), // Consistent padding
              child: Material(
                elevation: 4, // More pronounced shadow for the search bar
                borderRadius: BorderRadius.circular(15), // More rounded corners
                child: TextField(
                  controller: _searchController,
                  onChanged: _applyFilter, // Apply filter as text changes
                  decoration: InputDecoration(
                    hintText:
                        'ຄົ້ນຫາສາງ (ລະຫັດ/ຊື່)', // Search warehouse (code/name)
                    hintStyle: TextStyle(
                      fontFamily: 'NotoSansLao',
                      color: _textColorSecondary.withOpacity(0.7),
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: _accentColor, // Themed search icon
                      size: 24,
                    ),
                    filled: true,
                    fillColor:
                        _cardColor, // White background for the input field
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 20,
                    ), // Increased padding
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        15,
                      ), // Match Material border radius
                      borderSide: BorderSide.none, // No border for cleaner look
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(
                        color: _primaryColor,
                        width: 2,
                      ), // Highlight on focus
                    ),
                  ),
                  style: TextStyle(
                    fontFamily: 'NotoSansLao',
                    color: _textColorPrimary,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            // --- Warehouse List Section ---
            Expanded(child: _buildBodyContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildBodyContent() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: _primaryColor,
            ), // Themed progress indicator
            const SizedBox(height: 16),
            Text(
              'ກຳລັງໂຫຼດຂໍ້ມູນສາງ...', // Loading warehouse data
              style: TextStyle(
                fontFamily: 'NotoSansLao',
                color: _textColorSecondary,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 60,
                color: _errorColor,
              ), // Error icon
              const SizedBox(height: 16),
              Text(
                'ເກີດຂໍ້ຜິດພາດ: $_errorMessage',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'NotoSansLao',
                  color: _errorColor, // Error text color
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _fetchWarehouses,
                icon: const Icon(Icons.refresh, color: Colors.white),
                label: const Text(
                  'ລອງໃໝ່', // Try Again
                  style: TextStyle(
                    fontFamily: 'NotoSansLao',
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accentColor, // Themed button color
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  elevation: 3,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_filteredData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.warehouse_outlined, // Icon for no warehouses
              size: 80,
              color: Colors.blue.shade200, // Softer blue for empty state icon
            ),
            const SizedBox(height: 20),
            Text(
              _searchController.text.isEmpty
                  ? 'ບໍ່ມີສາງ.' // No warehouses
                  : 'ບໍ່ພົບສາງທີ່ກົງກັນ.', // No matching warehouses
              style: TextStyle(
                fontFamily: 'NotoSansLao',
                color: _textColorSecondary,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: _fetchWarehouses,
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: const Text(
                'ໂຫຼດຂໍ້ມູນໃໝ່', // Reload data
                style: TextStyle(
                  fontFamily: 'NotoSansLao',
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor, // Themed button color
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(10), // Padding around the list
      itemCount: _filteredData.length,
      itemBuilder: (BuildContext context, int index) {
        final item = _filteredData[index];
        return Card(
          elevation: 3, // Subtle shadow for each card
          margin: const EdgeInsets.symmetric(
            vertical: 8,
            horizontal: 5,
          ), // Spacing between cards
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              12,
            ), // Rounded corners for cards
          ),
          color: _cardColor, // White card background
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 10,
            ), // Padding inside ListTile
            leading: Icon(
              Icons.warehouse_outlined,
              color: _accentColor,
              size: 30,
            ), // Themed leading icon
            title: Text(
              item['name_1']?.toString() ?? 'ບໍ່ລະບຸຊື່ສາງ', // Warehouse name
              style: TextStyle(
                fontFamily: 'NotoSansLao',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _textColorPrimary,
              ),
            ),
            subtitle: Text(
              'ລະຫັດ: ${item['code']?.toString() ?? 'N/A'}', // Warehouse code
              style: TextStyle(
                fontFamily: 'NotoSansLao',
                fontSize: 14,
                color: _textColorSecondary,
              ),
            ),
            trailing: Icon(
              Icons.arrow_forward_ios,
              color: _accentColor,
              size: 20,
            ), // Themed trailing icon
            onTap: () {
              Navigator.of(
                context,
              ).pop({"code": item['code'], "name_1": item['name_1']});
            },
          ),
        );
      },
    );
  }
}
