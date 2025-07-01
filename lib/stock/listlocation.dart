import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // Use alias for clarity

import '../utility/my_constant.dart';

class ListLocation extends StatefulWidget {
  final String wh_codes; // Changed to final
  const ListLocation({super.key, required this.wh_codes});

  @override
  State<ListLocation> createState() => _ListLocationState();
}

class _ListLocationState extends State<ListLocation> {
  List<dynamic> _locations = []; // Renamed data to _locations for clarity
  bool _isLoading = false; // Add loading state
  String? _errorMessage; // Add error message state

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
    _fetchLocations(); // Renamed showdata to _fetchLocations for clarity
    // Removed the debug print here for cleaner final code
  }

  Future<void> _fetchLocations() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null; // Clear previous error
    });

    try {
      final response = await http.get(
        Uri.parse("${MyConstant().domain}/listsmlLocation/${widget.wh_codes}"),
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        setState(() {
          _locations = result['list'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'ໂຫຼດຂໍ້ມູນທີ່ເກັບບໍ່ສຳເລັດ: ${response.statusCode}';
        });
        _showSnackBar(_errorMessage!, _errorColor);
        print(
          "API Error: ${response.statusCode}, Body: ${response.body}",
        ); // Keep for debugging
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'ເກີດຂໍ້ຜິດພາດໃນການໂຫຼດຂໍ້ມູນ: $e';
      });
      _showSnackBar(_errorMessage!, _errorColor);
      print("Network/Parsing Error: $e"); // Keep for debugging
    }
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
          "ເລືອກພື້ນທີ່ຈັດເກັບ", // Select Storage Area (more descriptive title)
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
        onRefresh: _fetchLocations,
        color: _accentColor, // Color of the refresh indicator
        child: _buildBodyContent(),
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
              'ກຳລັງໂຫຼດຂໍ້ມູນທີ່ເກັບ...', // Loading storage data
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
                onPressed: _fetchLocations,
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

    if (_locations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_off_outlined, // Icon for no locations
              size: 80,
              color: Colors.blue.shade200, // Softer blue for empty state icon
            ),
            const SizedBox(height: 20),
            Text(
              'ບໍ່ພົບພື້ນທີ່ຈັດເກັບສິນຄ້າ.', // No storage locations found
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
              onPressed: _fetchLocations,
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
      itemCount: _locations.length,
      itemBuilder: (BuildContext context, int index) {
        final item = _locations[index];
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
              Icons.location_on_outlined,
              color: _accentColor,
              size: 30,
            ), // Themed leading icon
            title: Text(
              item['name_1']?.toString() ??
                  'ບໍ່ລະບຸຊື່ທີ່ເກັບ', // Storage area name
              style: TextStyle(
                fontFamily: 'NotoSansLao',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _textColorPrimary,
              ),
            ),
            subtitle: Text(
              'ລະຫັດ: ${item['code']?.toString() ?? 'N/A'}', // Storage area code
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
