import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:odgcashvan/database/sql_helper.dart';
import 'package:odgcashvan/utility/my_constant.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Ensure this is imported if used elsewhere

import 'customer/city.dart'; // Assuming these paths are correct
import 'customer/province.dart'; // Assuming these paths are correct

class CustomerForRouteplan extends StatefulWidget {
  final String from_route;
  // province and city parameters are now managed internally for clarity,
  // removed from constructor as they were commented out in Addplan originally.
  // If you need them in constructor, please add them back.
  const CustomerForRouteplan({super.key, required this.from_route});

  @override
  State<CustomerForRouteplan> createState() => _CustomerForRouteplanState();
}

class _CustomerForRouteplanState extends State<CustomerForRouteplan> {
  List _availableCustomers = []; // Renamed 'data' for clarity
  List<Map<String, dynamic>> _addedCustomers =
      []; // Renamed '_journals' for clarity
  bool _isLoading = false; // Renamed 'isLoading' for consistency

  String? _selectedProvinceCode; // Renamed for consistency
  String? _selectedCityCode; // Renamed for consistency

  final TextEditingController _searchQueryController =
      TextEditingController(); // Renamed for clarity
  final TextEditingController _provinceDisplayController =
      TextEditingController(); // Renamed for clarity
  final TextEditingController _cityDisplayController =
      TextEditingController(); // Renamed for clarity

  // Theme colors
  final Color _primaryBlue = Colors.blue.shade600;
  final Color _accentBlue = Colors.blue.shade800;
  final Color _lightBlue = Colors.blue.shade50;
  final Color _textMutedColor = Colors.grey.shade600;

  @override
  void initState() {
    super.initState();
    _fetchAvailableCustomers(); // Initial data load
    _refreshAddedCustomers(); // Load customers already added to the plan
  }

  void _refreshAddedCustomers() async {
    final result = await SQLHelper.Allcustomer();
    setState(() {
      _addedCustomers = result;
    });
  }

  Future<void> _fetchAvailableCustomers() async {
    setState(() => _isLoading = true);
    try {
      // SharedPreferences preferences = await SharedPreferences.getInstance(); // If sale_code is needed for this API
      // String saleCode = preferences.getString('usercode') ?? ''; // Example if API requires it

      final payload = json.encode({
        'province': _selectedProvinceCode,
        'city': _selectedCityCode,
        'query': _searchQueryController.text.trim(),
        // 'sale_code': saleCode, // Uncomment if your API needs sale_code here
      });

      final response = await post(
        Uri.parse("${MyConstant().domain}/customerlistforcashvan"),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: payload,
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        setState(() {
          _availableCustomers = result['list'] ?? [];
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'ຜິດພາດໃນການໂຫຼດລູກຄ້າ: ${response.statusCode}',
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'ຜິດພາດໃນການໂຫຼດຂໍ້ມູນ: $e',
              style: const TextStyle(
                fontFamily: 'NotoSansLao',
                color: Colors.white,
              ),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
      print("Error fetching customers: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<int> _checkIfCustomerIsAlreadyAdded(String custCode) async {
    final db = await SQLHelper.db();
    final result = await db.rawQuery(
      'SELECT COUNT(cust_code) as count FROM customer WHERE cust_code = ?',
      [custCode],
    );
    return result.first['count'] as int;
  }

  Future<void> _addCustomerToLocalDB(Map<String, dynamic> item) async {
    final exists = await _checkIfCustomerIsAlreadyAdded(item['cust_code']);
    if (exists > 0) {
      _showAlreadyAddedDialog();
      return;
    }

    await SQLHelper.creatCustomer(
      item['cust_code'],
      item['cust_name'],
      item['area_code'],
      item['logistic_area'],
      item['latlng'],
    );

    _refreshAddedCustomers(); // Refresh the list of added customers

    // Optionally remove from available list if it's a one-time selection
    // setState(() {
    //   _availableCustomers.removeWhere((e) => e['cust_code'] == item['cust_code']);
    // });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'ເພີ່ມລູກຄ້າສຳເລັດ',
            style: TextStyle(fontFamily: 'NotoSansLao', color: Colors.white),
          ),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _removeCustomerFromLocalDB(String id) async {
    await SQLHelper.deleteacustomerbyid(id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'ລົບລູກຄ້າສຳເລັດ',
            style: TextStyle(fontFamily: 'NotoSansLao', color: Colors.white),
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
    _refreshAddedCustomers(); // Refresh the list of added customers
    _fetchAvailableCustomers(); // Refresh available list in case it was removed from there
  }

  void _showAlreadyAddedDialog() {
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text(
          "ຄຳເຕືອນ",
          style: TextStyle(fontFamily: 'NotoSansLao'),
        ),
        content: const Text(
          "ຮ້ານນີ້ເພີ່ມແລ້ວໃນແຜນ.",
          style: TextStyle(fontFamily: 'NotoSansLao'),
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text(
              "OK",
              style: TextStyle(fontFamily: 'NotoSansLao', color: Colors.blue),
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _lightBlue, // Consistent background color
      appBar: AppBar(
        title: const Text(
          "ເລືອກລູກຄ້າສຳລັບແຜນ", // More descriptive title
          style: TextStyle(fontFamily: 'NotoSansLao', color: Colors.white),
        ),
        backgroundColor: _primaryBlue,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0, // Flat design
        actions: [
          IconButton(
            // Refresh button in app bar
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchAvailableCustomers,
            tooltip: 'ໂຫຼດຂໍ້ມູນລູກຄ້າຄືນໃໝ່',
          ),
        ],
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16), // Increased overall padding
            child: Column(
              children: [
                _buildFilterAndSearchBar(), // Combined filter and search
                const SizedBox(height: 16), // Spacing after filters/search
                Expanded(
                  child: Column(
                    children: [
                      // --- Section: Added Customers ---
                      if (_addedCustomers.isNotEmpty) ...[
                        _buildSectionHeader(
                          "ລູກຄ້າທີ່ເພີ່ມແລ້ວ",
                          Icons.check_circle_outline,
                          _primaryBlue,
                          Colors.green.shade700,
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height:
                              _addedCustomers.length * 70.0 >
                                  210 // Adjust height dynamically or cap it
                              ? 210 // Max height for added customers list
                              : _addedCustomers.length * 70.0,
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: _addedCustomers.length,
                            itemBuilder: (context, index) {
                              final cust = _addedCustomers[index];
                              return _buildCustomerListItem(
                                customer: cust,
                                isAdded: true,
                                onRemove: () => _removeCustomerFromLocalDB(
                                  cust['id'].toString(),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Divider(
                          height: 1,
                          thickness: 0.8,
                          color: Colors.grey,
                        ), // Visual separator
                        const SizedBox(height: 20),
                      ],

                      // --- Section: Available Customers ---
                      _buildSectionHeader(
                        "ເລືອກລູກຄ້າ",
                        Icons.person_add_alt_1_outlined,
                        _primaryBlue,
                        _accentBlue,
                      ),
                      const SizedBox(height: 8),
                      Expanded(child: _buildAvailableCustomerList()),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.4), // Darker overlay
              child: Center(
                child: CircularProgressIndicator(color: _primaryBlue),
              ),
            ),
        ],
      ),
    );
  }

  // --- New Helper: Section Header ---
  Widget _buildSectionHeader(
    String title,
    IconData icon,
    Color iconColor,
    Color textColor,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4), // Reduced padding
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge!.copyWith(
              // Larger font for headers
              fontWeight: FontWeight.bold,
              fontFamily: 'NotoSansLao',
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  // --- New Helper: Filter and Search Bar ---
  Widget _buildFilterAndSearchBar() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildFilterField(
                controller: _provinceDisplayController,
                label: "ແຂວງ",
                icon: Icons.map_outlined,
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => Province()),
                  );
                  if (result != null) {
                    setState(() {
                      _provinceDisplayController.text = result['name_1'];
                      _selectedProvinceCode = result['code'];
                      _cityDisplayController.clear();
                      _selectedCityCode = null;
                    });
                    _fetchAvailableCustomers();
                  }
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildFilterField(
                controller: _cityDisplayController,
                label: "ເມືອງ",
                icon: Icons.location_city_outlined,
                onTap: () async {
                  if (_selectedProvinceCode == null) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "ກະລຸນາເລືອກແຂວງກ່ອນ",
                            style: TextStyle(
                              fontFamily: 'NotoSansLao',
                              color: Colors.white,
                            ),
                          ),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    }
                    return;
                  }
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => City(province: _selectedProvinceCode),
                    ),
                  );
                  if (result != null) {
                    setState(() {
                      _cityDisplayController.text = result['name_1'];
                      _selectedCityCode = result['code'];
                    });
                    _fetchAvailableCustomers();
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _searchQueryController,
          onChanged: (value) => _fetchAvailableCustomers(),
          style: TextStyle(fontFamily: 'NotoSansLao', color: _accentBlue),
          decoration: InputDecoration(
            hintText: 'ຄົ້ນຫາລູກຄ້າ...',
            hintStyle: TextStyle(
              fontFamily: 'NotoSansLao',
              color: _textMutedColor,
            ),
            prefixIcon: Icon(Icons.search, color: _primaryBlue),
            suffixIcon: IconButton(
              icon: Icon(Icons.clear, color: Colors.grey),
              onPressed: () {
                _searchQueryController.clear();
                _fetchAvailableCustomers();
              },
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none, // No border by default
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: _primaryBlue.withOpacity(0.3),
              ), // Subtle border
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: _primaryBlue,
                width: 2.0,
              ), // Stronger focus border
            ),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 10,
              horizontal: 15,
            ), // Compact padding
          ),
        ),
      ],
    );
  }

  // --- New Helper: Filter Field (Read-only input with tap action) ---
  Widget _buildFilterField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AbsorbPointer(
        child: TextField(
          controller: controller,
          readOnly: true,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'NotoSansLao',
            color: _accentBlue,
            fontSize: 13,
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: _primaryBlue, size: 20),
            hintText: label,
            hintStyle: TextStyle(
              fontFamily: 'NotoSansLao',
              color: _textMutedColor,
              fontSize: 13,
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _primaryBlue.withOpacity(0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _primaryBlue, width: 2.0),
            ),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 10,
            ), // Compact padding
          ),
        ),
      ),
    );
  }

  // --- New Helper: Customer List Item ---
  Widget _buildCustomerListItem({
    required Map<String, dynamic> customer,
    required bool isAdded,
    VoidCallback? onAdd,
    VoidCallback? onRemove,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(
        vertical: 6,
        horizontal: 2,
      ), // Slightly reduced horizontal margin
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: isAdded
              ? Colors.green.shade100
              : _primaryBlue.withOpacity(0.1),
          radius: 22,
          child: Icon(
            isAdded ? Icons.check : Icons.person_outline,
            color: isAdded ? Colors.green.shade700 : _primaryBlue,
            size: 24,
          ),
        ),
        title: Text(
          customer['cust_name'],
          style: TextStyle(
            fontFamily: 'NotoSansLao',
            fontWeight: FontWeight.bold,
            color: Colors.black87,
            fontSize: 15,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          customer['adress1'] ??
              customer['cust_code'], // Show address if available, else code
          style: TextStyle(
            fontFamily: 'NotoSansLao',
            color: _textMutedColor,
            fontSize: 13,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        trailing: isAdded
            ? IconButton(
                icon: Icon(
                  Icons.remove_circle_outline,
                  color: Colors.redAccent,
                  size: 28,
                ),
                onPressed: onRemove,
                tooltip: 'ລົບອອກຈາກແຜນ',
              )
            : IconButton(
                icon: Icon(
                  Icons.add_circle_outline,
                  color: _primaryBlue,
                  size: 28,
                ),
                onPressed: onAdd,
                tooltip: 'ເພີ່ມເຂົ້າແຜນ',
              ),
      ),
    );
  }

  // --- New Helper: Available Customer List ---
  Widget _buildAvailableCustomerList() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: _primaryBlue));
    } else if (_availableCustomers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_off_outlined,
              size: 70,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 20),
            Text(
              "ບໍ່ພົບລູກຄ້າ",
              style: TextStyle(
                fontFamily: 'NotoSansLao',
                fontSize: 17,
                color: _textMutedColor,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              "ລອງປັບການຄົ້ນຫາ ຫຼື ເລືອກແຂວງ/ເມືອງໃໝ່.",
              style: TextStyle(
                fontFamily: 'NotoSansLao',
                fontSize: 15,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    } else {
      return ListView.builder(
        itemCount: _availableCustomers.length,
        itemBuilder: (context, index) {
          final item = _availableCustomers[index];
          // Check if the current available customer is already in the added list
          final bool alreadyAdded = _addedCustomers.any(
            (addedCust) => addedCust['cust_code'] == item['cust_code'],
          );

          // Only show 'Add' button if not already added
          if (alreadyAdded) {
            return const SizedBox.shrink(); // Hide the item if already added
          }

          return _buildCustomerListItem(
            customer: item,
            isAdded: false, // This item is from available list, not yet added
            onAdd: () async {
              // Handle adding customer to local DB
              if (widget.from_route == '0') {
                await _addCustomerToLocalDB(item);
                // After adding, you might want to re-filter _availableCustomers
                // or visually update this specific item. For simplicity,
                // we're relying on _refreshAddedCustomers and then filtering in the builder.
              } else {
                // If from a different route, just pop back with data
                Navigator.pop(context, {
                  'cust_code': item['cust_code'],
                  'cust_name': item['cust_name'],
                  'area_code': item['area_code'],
                  'logistic_area': item['logistic_area'],
                  'latlng': item['latlng'],
                });
              }
            },
          );
        },
      );
    }
  }
}
