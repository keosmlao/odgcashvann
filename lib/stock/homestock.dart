import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'countstock/homecountstock.dart';
import 'productlist.dart';
import 'stk_request/requestproduct.dart';
import 'stockbalance.dart';

class Homestock extends StatefulWidget {
  const Homestock({super.key});

  @override
  State<Homestock> createState() => _HomestockState();
}

class _HomestockState extends State<Homestock> {
  String _currentTitle = '';
  Widget? _currentBodyWidget;

  // Define a fresh, modern, and slightly desaturated color palette
  final Color _primaryColor = const Color(0xFF42A5F5); // Medium Blue
  final Color _accentColor = const Color(
    0xFF1976D2,
  ); // Darker Blue for highlights
  final Color _backgroundColor = const Color(
    0xFFF5F7F9,
  ); // Very light grey-blue background
  final Color _cardColor = Colors.white; // Pure white for cards/drawer items
  final Color _textColorPrimary = const Color(
    0xFF212121,
  ); // Almost black for main text
  final Color _textColorSecondary = const Color(
    0xFF757575,
  ); // Medium grey for secondary text
  final Color _selectedItemColor = const Color(
    0xFFE3F2FD,
  ); // Very light blue for selected item background
  final Color _drawerHeaderTextColor = const Color(
    0xFFFFFFFF,
  ); // White for drawer header text
  final Color _drawerHeaderBgColor = const Color(
    0xFF1976D2,
  ); // Dark blue for drawer header

  @override
  void initState() {
    super.initState();
    // Initialize with StockBalance and its corresponding title
    _currentBodyWidget = const StockBalance();
    _currentTitle = "ສາງລົດຄົງເຫຼືອ";
  }

  // Helper method to update selected item and close drawer
  void _selectDrawerItem(String title, Widget widget) {
    Navigator.pop(context); // Close the drawer
    setState(() {
      _currentTitle = title;
      _currentBodyWidget = widget;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: Text(
          _currentTitle,
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'NotoSansLao',
            fontWeight: FontWeight.bold,
            fontSize: 20, // Slightly larger title
          ),
        ),
        centerTitle: true,
        backgroundColor: _primaryColor,
        elevation: 4, // Add a subtle shadow for depth
        iconTheme: const IconThemeData(
          color: Colors.white,
        ), // Ensure drawer icon is white
        toolbarHeight: 70, // Slightly taller app bar
      ),
      drawer: Drawer(
        backgroundColor: _cardColor,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(
              20,
            ), // Rounded top-right corner for modern look
            bottomRight: Radius.circular(20),
          ),
        ),
        child: Column(
          // Use Column instead of ListView directly for more control
          children: <Widget>[
            // --- Drawer Header ---
            Container(
              height: 180, // Taller header
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _drawerHeaderBgColor,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FaIcon(
                    FontAwesomeIcons
                        .truckFast, // More dynamic icon for logistics
                    color: _drawerHeaderTextColor,
                    size: 50,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'ODG Cash Van', // App name
                    style: TextStyle(
                      color: _drawerHeaderTextColor,
                      fontFamily: 'NotoSansLao',
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'ລະບົບຈັດການສາງສິນຄ້າ', // Clearer subtitle
                    style: TextStyle(
                      color: _drawerHeaderTextColor.withOpacity(0.8),
                      fontFamily: 'NotoSansLao',
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            // --- Drawer Items (wrapped in Expanded for scrolling) ---
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(
                  top: 10,
                ), // Small padding from header
                children: [
                  _buildDrawerItem(
                    icon: FontAwesomeIcons.boxesStacked,
                    title: 'ສາງລົດຄົງເຫຼືອ',
                    targetWidget: const StockBalance(),
                    isSelected: _currentBodyWidget is StockBalance,
                  ),
                  _buildDrawerItem(
                    icon: FontAwesomeIcons
                        .truckArrowRight, // More descriptive icon for request
                    title: 'ຂໍໂອນສິນຄ້າ',
                    targetWidget: const RequestProduct(),
                    isSelected: _currentBodyWidget is RequestProduct,
                  ),
                  _buildDrawerItem(
                    icon: FontAwesomeIcons
                        .clipboardCheck, // Icon for checking/auditing
                    title: 'ກວດນັບສິນຄ້າ',
                    targetWidget: const HomeCountStock(),
                    isSelected: _currentBodyWidget is HomeCountStock,
                  ),
                  const Divider(
                    height: 25, // More vertical space for divider
                    thickness: 1,
                    indent: 20,
                    endIndent: 20,
                    color: Color(0xFFE0E0E0),
                  ),
                  _buildDrawerItem(
                    icon: FontAwesomeIcons.boxOpen,
                    title: 'ລາຍການສິນຄ້າທັງໝົດ',
                    targetWidget: const ProductList(),
                    isSelected: _currentBodyWidget is ProductList,
                  ),
                  const Divider(
                    height: 25,
                    thickness: 1,
                    indent: 20,
                    endIndent: 20,
                    color: Color(0xFFE0E0E0),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: _currentBodyWidget,
    );
  }

  // --- Helper method for Drawer ListTiles with enhanced styling ---
  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    Widget? targetWidget,
    bool isSelected = false,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 10.0,
        vertical: 4.0,
      ), // Padding around each item
      child: Material(
        // Use Material for InkWell ripple effect and shadow
        color: isSelected ? _selectedItemColor : _cardColor,
        borderRadius: BorderRadius.circular(
          10,
        ), // Rounded corners for item background
        elevation: isSelected ? 2 : 0, // Subtle elevation for selected item
        child: InkWell(
          onTap: onTap ?? () => _selectDrawerItem(title, targetWidget!),
          borderRadius: BorderRadius.circular(
            10,
          ), // Match Material's border radius
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 12.0,
            ), // Inner padding
            child: Row(
              children: [
                FaIcon(
                  icon,
                  color: isSelected ? _accentColor : _textColorSecondary,
                  size: 20,
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'NotoSansLao',
                      color: isSelected
                          ? _textColorPrimary
                          : _textColorSecondary,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                      fontSize: 16,
                    ),
                  ),
                ),
                if (isSelected) // Add an indicator for the selected item
                  FaIcon(
                    FontAwesomeIcons.angleRight,
                    color: _accentColor,
                    size: 16,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
