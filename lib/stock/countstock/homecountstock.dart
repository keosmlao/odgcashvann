import 'package:flutter/material.dart';

import 'listbillstockcount.dart';
import 'reportcomparestock.dart';

class HomeCountStock extends StatefulWidget {
  const HomeCountStock({super.key});

  @override
  State<HomeCountStock> createState() => _HomeCountStockState();
}

class _HomeCountStockState extends State<HomeCountStock> {
  Widget? currentWidget;

  String? title;

  @override
  void initState() {
    super.initState();
    currentWidget = ListBillStockCount();
    title = 'ລາຍການໃບກວດນັບ';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          title.toString(),
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.orange[800],
        automaticallyImplyLeading: false, // Hides the back button
      ),
      endDrawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.orange[800],
              ),
              child: Text(
                'Menu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.add),
              title: Text('ລາຍການໃບກວດນັບ'),
              onTap: () {
                setState(() {
                  title = 'ລາຍການໃບກວດນັບ';
                });
                currentWidget = ListBillStockCount();
                Navigator.pop(context);
                // Navigate to the Home screen or perform an action
              },
            ),
            ListTile(
              leading: Icon(Icons.report),
              title: Text('ລາຍງານ'),
              onTap: () {
                setState(() {
                  title = 'ລາຍງານ';
                });
                currentWidget = ReportCompareStockCount();

                Navigator.pop(context);
                // Navigate to the Settings screen or perform an action
              },
            ),
            // ListTile(
            //   leading: Icon(Icons.logout),
            //   title: Text('Logout'),
            //   onTap: () {
            //     Navigator.pop(context);
            //     // Handle logout or another action
            //   },
            // ),
          ],
        ),
      ),
      body: currentWidget,
    );
  }
}
