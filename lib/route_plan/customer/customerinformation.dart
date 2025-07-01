import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:odgcashvan/utility/my_constant.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart'; // For launching phone, Line, Facebook

class CustomerInformation extends StatefulWidget {
  final String code; // Made final
  const CustomerInformation({super.key, required this.code});

  @override
  State<CustomerInformation> createState() => _CustomerInformationState();
}

class _CustomerInformationState extends State<CustomerInformation> {
  // Use a map to store all customer data for easier management
  Map<String, dynamic>? _customerData;
  bool _isLoading = true; // Loading state

  // Define consistent colors for the theme
  final Color _primaryBlue = Colors.blue.shade600;
  final Color _accentBlue = Colors.blue.shade800;
  final Color _lightBlue = Colors.blue.shade50;
  final Color _textMutedColor = Colors.grey.shade600;

  @override
  void initState() {
    super.initState();
    _fetchCustomerData(); // Renamed 'getData' for clarity
  }

  Future<void> _fetchCustomerData() async {
    setState(() => _isLoading = true);
    SharedPreferences preferences =
        await SharedPreferences.getInstance(); // Ensure SharedPreferences is initialized

    try {
      final response = await get(
        Uri.parse("${MyConstant().domain}/ar_customerdetai/${widget.code}"),
      );

      if (response.statusCode == 200) {
        var resBody = json.decode(response.body);
        setState(() {
          _customerData = resBody;
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'ຜິດພາດໃນການໂຫຼດຂໍ້ມູນລູກຄ້າ: ${response.statusCode}',
                style: const TextStyle(
                  fontFamily: 'NotoSansLao',
                  color: Colors.white,
                ),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() => _customerData = null); // Set to null on error
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'ເກີດຂໍ້ຜິດພາດໃນການໂຫຼດຂໍ້ມູນ: $e',
              style: const TextStyle(
                fontFamily: 'NotoSansLao',
                color: Colors.white,
              ),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
      print("Error fetching customer data: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Helper to build an information row
  Widget _buildInfoRow(
    IconData icon,
    String label,
    String? value, {
    Color? iconColor,
    Color? valueColor,
    bool isActionable = false,
    VoidCallback? onTap,
  }) {
    final displayValue = value?.isNotEmpty == true ? value : 'N/A';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: iconColor ?? _primaryBlue),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'NotoSansLao',
                    fontSize: 14,
                    color: _textMutedColor,
                  ),
                ),
                const SizedBox(height: 2),
                GestureDetector(
                  // Make the value tappable if it's an action
                  onTap: isActionable && onTap != null ? onTap : null,
                  child: Text(
                    displayValue!,
                    style: TextStyle(
                      fontFamily: 'NotoSansLao',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color:
                          valueColor ??
                          (isActionable ? _primaryBlue : Colors.black87),
                      decoration: isActionable
                          ? TextDecoration.underline
                          : TextDecoration.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper to build a section header
  Widget _buildSectionHeader(String title, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 20.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.headlineSmall!.copyWith(
          fontFamily: 'NotoSansLao',
          fontWeight: FontWeight.bold,
          color: color ?? _accentBlue,
        ),
      ),
    );
  }

  // Function to launch external apps
  Future<void> _launchUrl(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'ບໍ່ສາມາດເປີດ: $url',
              style: const TextStyle(
                fontFamily: 'NotoSansLao',
                color: Colors.white,
              ),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _lightBlue,
      appBar: AppBar(
        title: Text(
          "ຂໍ້ມູນລູກຄ້າ",
          style: const TextStyle(
            fontFamily: 'NotoSansLao',
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: _primaryBlue,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: _primaryBlue))
          : _customerData == null || _customerData!.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.person_off_outlined,
                    size: 80,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "ບໍ່ພົບຂໍ້ມູນລູກຄ້າ.",
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
                    "ກະລຸນາກວດສອບລະຫັດລູກຄ້າ.",
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
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- Customer Header Section ---
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: _primaryBlue,
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(20),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _customerData!['name_1'] ?? 'N/A',
                            style: Theme.of(context).textTheme.headlineMedium!
                                .copyWith(
                                  fontFamily: 'NotoSansLao',
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'ລະຫັດລູກຄ້າ: ${widget.code}',
                            style: Theme.of(context).textTheme.titleMedium!
                                .copyWith(
                                  fontFamily: 'NotoSansLao',
                                  color: Colors.white.withOpacity(0.8),
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // --- General Information Section ---
                    _buildSectionHeader("ຂໍ້ມູນທົ່ວໄປ"),
                    _buildInfoRow(
                      Icons.place,
                      "ທີ່ຢູ່",
                      _customerData!['address'],
                    ),
                    _buildInfoRow(
                      Icons.apartment,
                      "ເມືອງ",
                      _customerData!['amper'],
                    ),
                    _buildInfoRow(
                      Icons.public,
                      "ແຂວງ",
                      _customerData!['province'],
                    ),
                    _buildInfoRow(
                      Icons.store,
                      "ລະດັບຮ້ານຄ້າ",
                      _customerData!['dimension_1'],
                    ),
                    _buildInfoRow(
                      Icons.business_center_outlined,
                      "ເລກທະບຽນວິສະຫະກິດ",
                      _customerData!['trade_license'],
                    ),

                    const SizedBox(height: 20),

                    // --- Contact Information Section ---
                    _buildSectionHeader("ຂໍ້ມູນຕິດຕໍ່"),
                    _buildInfoRow(
                      Icons.phone,
                      "ເບີໂທ",
                      _customerData!['telephone'],
                      isActionable: true,
                      onTap: () {
                        if (_customerData!['telephone'] != null &&
                            _customerData!['telephone'].isNotEmpty) {
                          _launchUrl('tel:${_customerData!['telephone']}');
                        }
                      },
                    ),
                    _buildInfoRow(
                      Icons.line_style,
                      "Line ID",
                      _customerData!['line_id'],
                      isActionable: true,
                      onTap: () {
                        if (_customerData!['line_id'] != null &&
                            _customerData!['line_id'].isNotEmpty) {
                          _launchUrl(
                            'https://line.me/ti/p/~${_customerData!['line_id']}',
                          ); // Example for Line
                        }
                      },
                    ),
                    _buildInfoRow(
                      Icons.facebook,
                      "Facebook",
                      _customerData!['facebook'],
                      isActionable: true,
                      onTap: () {
                        if (_customerData!['facebook'] != null &&
                            _customerData!['facebook'].isNotEmpty) {
                          _launchUrl(
                            'https://www.facebook.com/${_customerData!['facebook']}',
                          ); // Example for Facebook
                        }
                      },
                    ),

                    const SizedBox(height: 20),

                    // --- Sales & Logistics Information Section ---
                    _buildSectionHeader("ຂໍ້ມູນການຂາຍ ແລະຂົນສົ່ງ"),
                    _buildInfoRow(
                      Icons.area_chart,
                      "ເຂດການຂາຍ",
                      _customerData!['area_code'],
                    ),
                    _buildInfoRow(
                      Icons.local_shipping,
                      "ເຂດຂົນສົ່ງ",
                      _customerData!['logistic_area'],
                    ),

                    const SizedBox(height: 20),

                    // --- Credit Status Section ---
                    _buildSectionHeader("ສະຖານະລູກໜີ້"),
                    _buildInfoRow(
                      Icons.attach_money,
                      "ວົງເງິນຕິດໜີ້",
                      _customerData!['credit_money'] != null &&
                              _customerData!['credit_money'].toString() != '0'
                          ? _customerData!['credit_money'].toString()
                          : 'ບໍມີ', // Show "ບໍມີ" if 0 or null
                      iconColor:
                          _customerData!['credit_money'] != null &&
                              _customerData!['credit_money'].toString() != '0'
                          ? Colors.green.shade700
                          : Colors.red.shade700,
                      valueColor:
                          _customerData!['credit_money'] != null &&
                              _customerData!['credit_money'].toString() != '0'
                          ? Colors.green.shade700
                          : Colors.red.shade700,
                    ),
                    _buildInfoRow(
                      Icons.calendar_today,
                      "ຈຳນວນວັນ",
                      _customerData!['credit_day'] != null &&
                              _customerData!['credit_day'].toString() != '0'
                          ? _customerData!['credit_day'].toString()
                          : 'ບໍມີ',
                    ),
                    _buildInfoRow(
                      Icons.check_circle_outline,
                      "ສະຖານະການຂາຍ",
                      _customerData!['credit_status'] != null &&
                              _customerData!['credit_status'].toString() != '0'
                          ? "ສາມາດຂາຍຕິດໜີ້ໃດ້"
                          : "ສົດຢ່າງດຽວ",
                      iconColor:
                          _customerData!['credit_status'] != null &&
                              _customerData!['credit_status'].toString() != '0'
                          ? Colors.green.shade700
                          : Colors.red.shade700,
                      valueColor:
                          _customerData!['credit_status'] != null &&
                              _customerData!['credit_status'].toString() != '0'
                          ? Colors.green.shade700
                          : Colors.red.shade700,
                    ),

                    const SizedBox(height: 20),

                    // --- Location Section (Placeholder for Map) ---
                    _buildSectionHeader("ທີ່ຕັ້ງຮ້ານ"),
                    Container(
                      height: 200, // Placeholder height for map
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 60,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              "ແຜນທີ່ຕັ້ງຮ້ານຄ້າ",
                              style: TextStyle(
                                fontFamily: 'NotoSansLao',
                                fontSize: 16,
                                color: _textMutedColor,
                              ),
                            ),
                            // You can add a button here to launch an external map
                            // or integrate GoogleMap widget if dependencies are managed.
                            TextButton.icon(
                              onPressed: () {
                                // Example: Launch Google Maps with customer's lat/lng
                                // if (_customerData!['latitude'] != null && _customerData!['longitude'] != null) {
                                //   _launchUrl('https://www.google.com/maps/search/?api=1&query=${_customerData!['latitude']},${_customerData!['longitude']}');
                                // } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'ບໍ່ມີຂໍ້ມູນທີ່ຕັ້ງ',
                                      style: TextStyle(
                                        fontFamily: 'NotoSansLao',
                                        color: Colors.white,
                                      ),
                                    ),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                                // }
                              },
                              icon: Icon(Icons.navigation, color: _primaryBlue),
                              label: Text(
                                'ເປີດແຜນທີ່',
                                style: TextStyle(
                                  fontFamily: 'NotoSansLao',
                                  color: _primaryBlue,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }
}
