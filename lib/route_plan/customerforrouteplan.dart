import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:odgcashvan/database/sql_helper.dart';
import 'package:odgcashvan/utility/my_constant.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'customer/city.dart';
import 'customer/province.dart';

class CustomerForRouteplan extends StatefulWidget {
  final String from_route;

  const CustomerForRouteplan({super.key, required this.from_route});

  @override
  State<CustomerForRouteplan> createState() => _CustomerForRouteplanState();
}

class _CustomerForRouteplanState extends State<CustomerForRouteplan> {
  List _availableCustomers = [];
  List<Map<String, dynamic>> _addedCustomers = [];
  bool _isLoading = false;

  String? _selectedProvinceCode;
  String? _selectedCityCode;

  final TextEditingController _searchQueryController = TextEditingController();
  final TextEditingController _provinceDisplayController =
      TextEditingController();
  final TextEditingController _cityDisplayController = TextEditingController();

  // Theme colors - more descriptive names
  final Color _primaryColor = Colors.blue.shade700;
  final Color _accentColor = Colors.blue.shade900;
  final Color _backgroundColor = Colors.grey.shade50;
  final Color _textColor = Colors.grey.shade800;
  final Color _lightTextColor = Colors.grey.shade600;
  final Color _successColor = Colors.green.shade700;
  final Color _errorColor = Colors.red.shade700;

  @override
  void initState() {
    super.initState();
    _fetchAvailableCustomers();
    _refreshAddedCustomers();
    _searchQueryController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchQueryController.removeListener(_onSearchChanged);
    _searchQueryController.dispose();
    _provinceDisplayController.dispose();
    _cityDisplayController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    // Debounce search to avoid too many API calls
    // You might want to implement a debounce mechanism here
    // For simplicity, we'll call directly, but for production,
    // consider a Timer.debounce to reduce API calls.
    _fetchAvailableCustomers();
  }

  void _refreshAddedCustomers() async {
    setState(() => _isLoading = true); // Show loading while refreshing local DB
    final result = await SQLHelper.Allcustomer();
    setState(() {
      _addedCustomers = result;
      _isLoading = false; // Hide loading after refreshing local DB
    });
  }

  Future<void> _fetchAvailableCustomers() async {
    if (_isLoading) return; // Prevent multiple simultaneous fetches
    setState(() => _isLoading = true);
    try {
      final payload = json.encode({
        'province': _selectedProvinceCode,
        'city': _selectedCityCode,
        'query': _searchQueryController.text.trim(),
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
        _showSnackBar(
          'ຜິດພາດໃນການໂຫຼດລູກຄ້າ: ${response.statusCode}',
          _errorColor,
        );
      }
    } catch (e) {
      _showSnackBar('ຜິດພາດໃນການໂຫຼດຂໍ້ມູນ: $e', _errorColor);
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

    setState(() => _isLoading = true); // Show loading while adding
    await SQLHelper.creatCustomer(
      item['cust_code'],
      item['cust_name'],
      item['area_code'],
      item['logistic_area'],
      item['latlng'],
    );
    _refreshAddedCustomers(); // Refresh the list of added customers
    _showSnackBar('ເພີ່ມລູກຄ້າສຳເລັດ', _successColor);
    setState(() => _isLoading = false); // Hide loading
  }

  void _removeCustomerFromLocalDB(String id) async {
    setState(() => _isLoading = true); // Show loading while removing
    await SQLHelper.deleteacustomerbyid(id);
    _refreshAddedCustomers(); // Refresh the list of added customers
    _fetchAvailableCustomers(); // Re-fetch to ensure consistency if needed
    _showSnackBar('ລົບລູກຄ້າສຳເລັດ', _errorColor);
    setState(() => _isLoading = false); // Hide loading
  }

  void _showAlreadyAddedDialog() {
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text(
          "ຄຳເຕືອນ",
          style: TextStyle(
            fontFamily: 'NotoSansLao',
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          "ຮ້ານນີ້ເພີ່ມແລ້ວໃນແຜນການເດີນທາງ.",
          style: TextStyle(fontFamily: 'NotoSansLao'),
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text(
              "ຕົກລົງ",
              style: TextStyle(fontFamily: 'NotoSansLao', color: Colors.blue),
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
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
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: const Text(
          "ເລືອກລູກຄ້າ",
          style: TextStyle(
            fontFamily: 'NotoSansLao',
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              _fetchAvailableCustomers();
              _refreshAddedCustomers();
            },
            tooltip: 'ໂຫຼດຂໍ້ມູນລູກຄ້າຄືນໃໝ່',
          ),
        ],
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildFilterAndSearchBar(),
                const SizedBox(height: 20),
                if (_addedCustomers.isNotEmpty) ...[
                  _buildSectionHeader(
                    "ລູກຄ້າທີ່ເພີ່ມແລ້ວ",
                    Icons.playlist_add_check,
                    _successColor,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: _addedCustomers.length * 75.0 > 225
                        ? 225 // Max height for added customers list
                        : _addedCustomers.length * 75.0,
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _addedCustomers.length,
                      itemBuilder: (context, index) {
                        final cust = _addedCustomers[index];
                        return _buildCustomerListItem(
                          customer: cust,
                          isAdded: true,
                          onRemove: () =>
                              _removeCustomerFromLocalDB(cust['id'].toString()),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Divider(height: 1, thickness: 0.8, color: Colors.grey),
                  const SizedBox(height: 20),
                ],
                _buildSectionHeader(
                  "ລູກຄ້າທີ່ມີ",
                  Icons.person_add_alt_1,
                  _primaryColor,
                ),
                const SizedBox(height: 12),
                Expanded(child: _buildAvailableCustomerList()),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.4),
              child: Center(
                child: CircularProgressIndicator(color: _primaryColor),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color iconColor) {
    return Container(
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(width: 10),
          Text(
            title,
            style: TextStyle(
              fontFamily: 'NotoSansLao',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterAndSearchBar() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildFilterField(
                controller: _provinceDisplayController,
                label: "ແຂວງ",
                icon: Icons.location_on_outlined,
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
            const SizedBox(width: 12),
            Expanded(
              child: _buildFilterField(
                controller: _cityDisplayController,
                label: "ເມືອງ",
                icon: Icons.business_outlined,
                onTap: () async {
                  if (_selectedProvinceCode == null ||
                      _selectedProvinceCode!.isEmpty) {
                    _showSnackBar("ກະລຸນາເລືອກແຂວງກ່ອນ", Colors.orange);
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
        const SizedBox(height: 15),
        TextField(
          controller: _searchQueryController,
          style: TextStyle(fontFamily: 'NotoSansLao', color: _textColor),
          decoration: InputDecoration(
            hintText: 'ຄົ້ນຫາລູກຄ້າ...',
            hintStyle: TextStyle(
              fontFamily: 'NotoSansLao',
              color: _lightTextColor,
            ),
            prefixIcon: Icon(Icons.search, color: _primaryColor),
            suffixIcon: _searchQueryController.text.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear, color: Colors.grey),
                    onPressed: () {
                      _searchQueryController.clear();
                      _fetchAvailableCustomers();
                    },
                  )
                : null,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(color: _primaryColor.withOpacity(0.2)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(color: _accentColor, width: 2.0),
            ),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 12,
              horizontal: 18,
            ),
          ),
        ),
      ],
    );
  }

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
            color: _accentColor,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: _primaryColor, size: 22),
            hintText: label,
            hintStyle: TextStyle(
              fontFamily: 'NotoSansLao',
              color: _lightTextColor,
              fontSize: 14,
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(color: _primaryColor.withOpacity(0.2)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(color: _accentColor, width: 2.0),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomerListItem({
    required Map<String, dynamic> customer,
    required bool isAdded,
    VoidCallback? onAdd,
    VoidCallback? onRemove,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ),
        leading: CircleAvatar(
          backgroundColor: isAdded
              ? _successColor.withOpacity(0.1)
              : _primaryColor.withOpacity(0.1),
          radius: 25,
          child: Icon(
            isAdded ? Icons.check_circle_outline : Icons.person_outline,
            color: isAdded ? _successColor : _primaryColor,
            size: 28,
          ),
        ),
        title: Text(
          customer['cust_name'] ?? 'ບໍ່ມີຊື່',
          style: TextStyle(
            fontFamily: 'NotoSansLao',
            fontWeight: FontWeight.bold,
            color: _textColor,
            fontSize: 16,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          customer['adress1'] ??
              (customer['cust_code'] != null
                  ? 'ລະຫັດ: ${customer['cust_code']}'
                  : 'ບໍ່ມີຂໍ້ມູນ'),
          style: TextStyle(
            fontFamily: 'NotoSansLao',
            color: _lightTextColor,
            fontSize: 13,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: isAdded
            ? IconButton(
                icon: Icon(
                  Icons.remove_circle_outline,
                  color: _errorColor,
                  size: 30,
                ),
                onPressed: onRemove,
                tooltip: 'ລົບອອກຈາກແຜນ',
              )
            : IconButton(
                icon: Icon(
                  Icons.add_circle_outline,
                  color: _primaryColor,
                  size: 30,
                ),
                onPressed: onAdd,
                tooltip: 'ເພີ່ມເຂົ້າແຜນ',
              ),
      ),
    );
  }

  Widget _buildAvailableCustomerList() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: _primaryColor));
    } else if (_availableCustomers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.sentiment_dissatisfied_outlined,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 25),
            Text(
              "ບໍ່ພົບລູກຄ້າທີ່ກົງກັນ",
              style: TextStyle(
                fontFamily: 'NotoSansLao',
                fontSize: 18,
                color: _textColor,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              "ລອງປັບປ່ຽນການຄົ້ນຫາ ຫຼື ເລືອກແຂວງ/ເມືອງໃໝ່.",
              style: TextStyle(
                fontFamily: 'NotoSansLao',
                fontSize: 14,
                color: _lightTextColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    } else {
      // Filter out customers already added to the local database
      final List filteredAvailableCustomers = _availableCustomers.where((item) {
        return !_addedCustomers.any(
          (addedCust) => addedCust['cust_code'] == item['cust_code'],
        );
      }).toList();

      if (filteredAvailableCustomers.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.check_circle_outline,
                size: 80,
                color: _successColor.withOpacity(0.3),
              ),
              const SizedBox(height: 25),
              Text(
                "ລູກຄ້າທັງໝົດໄດ້ຖືກເພີ່ມແລ້ວ!",
                style: TextStyle(
                  fontFamily: 'NotoSansLao',
                  fontSize: 18,
                  color: _textColor,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                "ບໍ່ມີລູກຄ້າໃໝ່ໃຫ້ເພີ່ມໃນປັດຈຸບັນ.",
                style: TextStyle(
                  fontFamily: 'NotoSansLao',
                  fontSize: 14,
                  color: _lightTextColor,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }
      return ListView.builder(
        itemCount: filteredAvailableCustomers.length,
        itemBuilder: (context, index) {
          final item = filteredAvailableCustomers[index];
          return _buildCustomerListItem(
            customer: item,
            isAdded: false,
            onAdd: () async {
              if (widget.from_route == '0') {
                await _addCustomerToLocalDB(item);
              } else {
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
