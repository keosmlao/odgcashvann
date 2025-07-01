import 'dart:convert' show json;

import 'package:flutter/material.dart';
import 'package:http/http.dart';

import '../../utility/my_constant.dart';

class City extends StatefulWidget {
  final String? province; // Made final as it's passed in constructor
  const City({Key? key, required this.province}) : super(key: key);

  @override
  State<City> createState() => _CityState();
}

class _CityState extends State<City> {
  // Removed unused nameUser, CodeUser
  List _cities = []; // Renamed 'data' for clarity and consistency
  bool _isLoading = false; // Added loading state

  // Define consistent colors for the theme
  final Color _primaryBlue = Colors.blue.shade600;
  final Color _accentBlue = Colors.blue.shade800;
  final Color _lightBlue = Colors.blue.shade50;
  final Color _textMutedColor = Colors.grey.shade600;

  @override
  void initState() {
    super.initState();
    _fetchCities(); // Renamed 'showdata' for clarity
  }

  Future<void> _fetchCities() async {
    if (widget.province == null || widget.province!.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'ບໍ່ພົບລະຫັດແຂວງ. ກະລຸນາເລືອກແຂວງກ່ອນ.',
              style: TextStyle(fontFamily: 'NotoSansLao', color: Colors.white),
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
        setState(() => _cities = []); // Clear list if province is null
      }
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await get(
        Uri.parse("${MyConstant().domain}/city/${widget.province}"),
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        setState(() {
          _cities = result['list'] ?? [];
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'ຜິດພາດໃນການໂຫຼດຂໍ້ມູນເມືອງ: ${response.statusCode}',
                style: TextStyle(
                  fontFamily: 'NotoSansLao',
                  color: Colors.white,
                ),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() => _cities = []); // Clear data on error
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
      print("Error fetching cities: $e");
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
          "ເລືອກເມືອງ", // More descriptive title
          style: TextStyle(fontFamily: 'NotoSansLao', color: Colors.white),
        ),
        backgroundColor: _primaryBlue, // Consistent AppBar color
        foregroundColor: Colors.white, // White icons/text
        centerTitle: true,
        elevation: 0, // Flat design
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchCities,
            tooltip: 'ໂຫຼດຂໍ້ມູນເມືອງຄືນໃໝ່',
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: _primaryBlue,
              ), // Loading indicator
            )
          : _cities.isEmpty
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
                    "ບໍ່ພົບຂໍ້ມູນເມືອງ.",
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
                    "ກະລຸນາລອງເລືອກແຂວງອື່ນ ຫຼື ກວດສອບຂໍ້ມູນ.",
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
                itemCount: _cities.length,
                itemBuilder: (BuildContext context, int index) {
                  final city = _cities[index];
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
                        Navigator.of(
                          context,
                        ).pop({"code": city['code'], "name_1": city['name_1']});
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
                                    city['name_1'],
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
                                    "ລະຫັດ: ${city['code']}",
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
