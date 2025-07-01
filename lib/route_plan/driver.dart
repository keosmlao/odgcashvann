import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:odgcashvan/utility/my_constant.dart';

class Driver extends StatefulWidget {
  const Driver({super.key});

  @override
  State<Driver> createState() => _DriverState();
}

class _DriverState extends State<Driver> {
  List _drivers = []; // Renamed 'data' to '_drivers' for clarity
  bool _isLoading = true; // New state variable for loading
  String? _errorMessage; // New state variable for error messages

  // Define consistent colors for the theme
  final Color _primaryColor = Colors.blue.shade700; // Consistent primary color
  final Color _accentColor =
      Colors.blue.shade500; // Accent color for icons/highlight
  final Color _backgroundColor = Colors.blue.shade50; // Light background
  final Color _cardColor = Colors.white; // Card background color
  final Color _textColorPrimary = Colors.grey.shade800; // Main text color
  final Color _textColorSecondary =
      Colors.grey.shade600; // Secondary text color

  @override
  void initState() {
    super.initState();
    _fetchDrivers(); // Renamed showdata() to _fetchDrivers()
  }

  Future<void> _fetchDrivers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null; // Clear any previous errors
    });

    try {
      final response = await get(
        Uri.parse("${MyConstant().domain}/drivervansale"),
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        setState(() {
          _drivers = result['list'] ?? []; // Ensure it's not null
          _isLoading = false;
        });
      } else {
        // Handle non-200 responses
        setState(() {
          _isLoading = false;
          _errorMessage =
              'Failed to load drivers. Status code: ${response.statusCode}';
        });
      }
    } catch (e) {
      // Handle network or parsing errors
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error fetching data: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor, // Apply consistent background color
      appBar: AppBar(
        title: const Text(
          "ລາຍຊື່ຄົນຂັບ",
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'NotoSansLao',
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: _primaryColor, // Apply consistent primary color
        centerTitle: true,
        elevation: 2, // Add subtle shadow to AppBar
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: _primaryColor),
            const SizedBox(height: 16),
            Text(
              'ກຳລັງໂຫຼດຂໍ້ມູນຄົນຂັບ...',
              style: TextStyle(
                fontFamily: 'NotoSansLao',
                color: _textColorSecondary,
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
              Icon(Icons.error_outline, size: 60, color: Colors.red.shade400),
              const SizedBox(height: 16),
              Text(
                'ເກີດຂໍ້ຜິດພາດ: $_errorMessage',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'NotoSansLao',
                  color: Colors.red.shade700,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _fetchDrivers,
                icon: const Icon(Icons.refresh, color: Colors.white),
                label: const Text(
                  'ລອງໃໝ່',
                  style: TextStyle(
                    fontFamily: 'NotoSansLao',
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accentColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_drivers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_alt_outlined,
              size: 80,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 20),
            Text(
              'ບໍ່ພົບຂໍ້ມູນຄົນຂັບ.',
              style: TextStyle(
                fontFamily: 'NotoSansLao',
                color: _textColorSecondary,
                fontSize: 18,
              ),
            ),
            Text(
              'ກະລຸນາກວດສອບການເຊື່ອມຕໍ່ ຫຼື ຕິດຕໍ່ຜູ້ເບິ່ງແຍງລະບົບ.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'NotoSansLao',
                color: _textColorSecondary.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16), // Padding around the list
      itemCount: _drivers.length,
      itemBuilder: (BuildContext context, int index) {
        final driver = _drivers[index];
        return Card(
          elevation: 3, // Add more pronounced shadow to cards
          margin: const EdgeInsets.only(bottom: 12), // Space between cards
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              12,
            ), // Rounded corners for cards
          ),
          color: _cardColor, // Apply card background color
          child: InkWell(
            // Use InkWell for better visual feedback on tap
            onTap: () {
              Navigator.of(
                context,
              ).pop({"code": driver['code'], "name_1": driver['name_1']});
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.person_outline,
                      size: 28,
                      color: _primaryColor, // Icon color
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          driver['name_1'] ??
                              'ບໍ່ມີຊື່', // Use null-aware operator for safety
                          style: TextStyle(
                            fontFamily: 'NotoSansLao',
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: _textColorPrimary, // Main text color
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'ລະຫັດພະນັກງານ: ${driver['code'] ?? 'N/A'}', // Display code as subtitle
                          style: TextStyle(
                            fontFamily: 'NotoSansLao',
                            fontSize: 14,
                            color: _textColorSecondary, // Secondary text color
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: _accentColor,
                    size: 20,
                  ), // Trailing arrow icon
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
