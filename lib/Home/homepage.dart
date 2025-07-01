import 'package:flutter/material.dart';
import 'package:odgcashvan/route_plan/listrouteplan.dart';
import 'package:odgcashvan/stock/homestock.dart';

// Assuming these are still valid, even if commented out in widgetOptions
// import '../Sale/homesale.dart';
// import '../Sale/report/homereport.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  // The widgets to display for each tab
  static const List<Widget> _widgetOptions = <Widget>[
    ListRoutePlan(), // This is the 'ແຜນເດີນລົດ' tab
    Homestock(), // This is the 'ສາງສິນຄ້າ' tab
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: _widgetOptions.elementAt(_selectedIndex)),
      bottomNavigationBar: BottomNavigationBar(
        // Set the overall background color of the BottomNavigationBar
        backgroundColor: Colors.blue[600], // Matches your AppBar's soft blue
        // Color of the selected item (icon and text)
        selectedItemColor: Colors.white, // White stands out nicely on blue
        // Color of unselected items (icon and text)
        unselectedItemColor: Colors.blue[200], // A lighter blue for unselected
        // Type of BottomNavigationBar
        // Set to fixed if you have 3 items or less and want them evenly spaced
        // Set to shifting if you want the selected item to expand and reveal its background color (which we've removed on items)
        type: BottomNavigationBarType.fixed, // Recommended for consistent color

        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.route), // A more relevant icon for 'Route Plan'
            label: 'ແຜນເດີນລົດ',
            // Removed individual backgroundColor from here for a unified look
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.warehouse), // A more relevant icon for 'Stock'
            label: 'ສາງສິນຄ້າ',
            // Removed individual backgroundColor from here
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
