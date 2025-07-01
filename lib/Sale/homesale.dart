import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:odgcashvan/Sale/Customer/listcustomer.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utility/my_constant.dart';
import '../utility/signout_process.dart';
import '../Sale/saleinvoice.dart';
import '../stock/stockbalance.dart';
import '../stock/stk_request/requestproduct.dart';
import '../stock/countstock/homecountstock.dart';
import '../stock/productlist.dart';
import '../route_plan/listrouteplan.dart';

class HomeSale extends StatefulWidget {
  const HomeSale({super.key});

  @override
  State<HomeSale> createState() => _HomeSaleState();
}

class _HomeSaleState extends State<HomeSale> {
  String? username, formattedDate, start_plan = '0';

  @override
  void initState() {
    super.initState();
    formattedDate = DateFormat('dd-MM-yyyy').format(DateTime.now());
    findUser();
    checkPlanStatus();
  }

  void findUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      username = prefs.getString('username') ?? '';
    });
  }

  Future<void> checkPlanStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var response = await Uri.parse(
      "${MyConstant().domain}/check_route_plan_start/${prefs.getString('usercode')}",
    );
    var result = json.decode((await get(response)).body);
    setState(() {
      start_plan = result['status'].toString();
    });
  }

  Widget buildMenuCard({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: Colors.blueAccent),
              const SizedBox(height: 12),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> menuItems = [];

    if (start_plan != '0') {
      menuItems.add(
        buildMenuCard(
          icon: Icons.route,
          label: "ທາງເດີນລົດ",
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ListCustomer()),
          ),
        ),
      );
    } else {
      menuItems.add(
        buildMenuCard(
          icon: Icons.play_circle_fill,
          label: "ເລີ່ມ",
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ListRoutePlan()),
            );
            checkPlanStatus();
          },
        ),
      );
    }

    menuItems.addAll([
      buildMenuCard(
        icon: Icons.pages,
        label: "ບິນຂາຍ",
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => SaleInvoice()),
        ),
      ),
      buildMenuCard(
        icon: Icons.warehouse,
        label: "ສິນຄ້າຄົງເຫຼືອ",
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => StockBalance()),
        ),
      ),
      buildMenuCard(
        icon: Icons.move_to_inbox,
        label: "ຂໍໂອນສິນຄ້າ",
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => RequestProduct()),
        ),
      ),
      buildMenuCard(
        icon: Icons.checklist,
        label: "ກວດນັບສາງ",
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => HomeCountStock()),
        ),
      ),
      buildMenuCard(
        icon: Icons.list_alt,
        label: "ລາຍຊື່ສິນຄ້າ",
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ProductList()),
        ),
      ),
    ]);

    if (start_plan != '0') {
      menuItems.add(
        buildMenuCard(
          icon: Icons.stop_circle,
          label: "ສິນສຸດການຂາຍ",
          onTap: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text("ສິນສຸດ"),
                content: Text("ກົດຢືນຢັນເພື່ອສິນສຸດການຂາຍ"),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text("ຍົກເລີກ"),
                  ),
                  TextButton(
                    onPressed: () {
                      // TODO: handle stop logic
                      Navigator.pop(context);
                    },
                    child: Text("ຢືນຢັນ"),
                  ),
                ],
              ),
            );
          },
        ),
      );
    }

    menuItems.add(
      buildMenuCard(
        icon: Icons.logout,
        label: "ອອກລະບົບ",
        onTap: () => signOutProcess(context),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('ລະບົບຂາຍ'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            color: Colors.blueAccent,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  username ?? '',
                  style: TextStyle(fontSize: 20, color: Colors.white),
                ),
                SizedBox(height: 4),
                Text(
                  formattedDate ?? '',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: menuItems,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
