import 'dart:convert' show json;

import 'package:flutter/material.dart';
import 'package:http/http.dart';

import '../../utility/my_constant.dart';

class Province extends StatefulWidget {
  const Province({super.key});

  @override
  State<Province> createState() => _ProvinceState();
}

class _ProvinceState extends State<Province> {
  // Removed unused nameUser, CodeUser
  List _provinces = []; // Renamed 'data' for clarity and consistency
  bool _isLoading = false; // Added loading state

  // Define consistent colors for the theme
  final Color _primaryBlue = Colors.blue.shade600;
  final Color _accentBlue = Colors.blue.shade800;
  final Color _lightBlue = Colors.blue.shade50;
  final Color _textMutedColor = Colors.grey.shade600;

  @override
  void initState() {
    super.initState();
    _fetchProvinces(); // Renamed 'showdata' for clarity
  }

  Future<void> _fetchProvinces() async {
    setState(() => _isLoading = true);
    try {
      final response = await get(
        Uri.parse(
          "${MyConstant().domain}/province",
        ), // Use string interpolation for clarity
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        setState(() {
          _provinces = result['list'] ?? [];
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'ຜິດພາດໃນການໂຫຼດຂໍ້ມູນແຂວງ: ${response.statusCode}',
                style: TextStyle(
                  fontFamily: 'NotoSansLao',
                  color: Colors.white,
                ),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() => _provinces = []); // Clear data on error
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'ເກີດຂໍ້ຜິດພາດ: $e',
              style: TextStyle(fontFamily: 'NotoSansLao', color: Colors.white),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
      print("Error fetching provinces: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _lightBlue, // Consistent background color
      appBar: AppBar(
        title: Text(
          "ເລືອກແຂວງ", // More descriptive title
          style: TextStyle(fontFamily: 'NotoSansLao', color: Colors.white),
        ),
        backgroundColor: _primaryBlue, // Consistent AppBar color
        foregroundColor: Colors.white, // White icons/text
        centerTitle: true,
        elevation: 0, // Flat design
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchProvinces,
            tooltip: 'ໂຫຼດຂໍ້ມູນແຂວງຄືນໃໝ່',
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: _primaryBlue,
              ), // Loading indicator
            )
          : _provinces.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.location_off_outlined,
                    size: 80,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "ບໍ່ພົບຂໍ້ມູນແຂວງ.",
                    style: TextStyle(
                      fontFamily: 'NotoSansLao',
                      fontSize: 18,
                      color: _textMutedColor,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "ກະລຸນາກວດສອບການເຊື່ອມຕໍ່ ຫຼື ລອງໃໝ່.",
                    style: TextStyle(
                      fontFamily: 'NotoSansLao',
                      fontSize: 15,
                      color: Colors.grey[500],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ), // Overall padding
              child: ListView.builder(
                itemCount: _provinces.length,
                itemBuilder: (BuildContext context, int index) {
                  final province = _provinces[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      vertical: 6.0,
                    ), // Spacing between cards
                    elevation: 2, // Subtle shadow
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        10,
                      ), // Rounded corners
                    ),
                    child: InkWell(
                      // Add InkWell for tap feedback
                      onTap: () {
                        Navigator.of(context).pop({
                          "code": province['code'],
                          "name_1": province['name_1'],
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ), // Inner padding
                        child: Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              color: _primaryBlue,
                              size: 24,
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    province['name_1'], // Display name_1 as main title
                                    style: TextStyle(
                                      fontFamily: 'NotoSansLao',
                                      fontWeight: FontWeight.bold,
                                      color:
                                          _accentBlue, // Darker blue for name
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "ລະຫັດ: ${province['code']}", // Display code as subtitle
                                    style: TextStyle(
                                      fontFamily: 'NotoSansLao',
                                      color: _textMutedColor,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.grey.shade400,
                              size: 18,
                            ), // Indication of navigation
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
