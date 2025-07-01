import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:odgcashvan/utility/my_constant.dart';

import 'package:shared_preferences/shared_preferences.dart';

class CustListforPos extends StatefulWidget {
  const CustListforPos({super.key});

  @override
  State<CustListforPos> createState() => _CustListforPosState();
}

class _CustListforPosState extends State<CustListforPos> {
  List<dynamic> data = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    showdata();
  }

  Future<void> showdata() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    try {
      var response = await get(
        Uri.parse(
          "${MyConstant().domain}/customerforpos/${preferences.getString('route_id')}",
        ),
      );
      var result = json.decode(response.body);
      setState(() {
        data = result['list'];
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      // Show error (optional)
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('ເກີດຂໍ້ຜິດພາດ: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color orange = const Color(0xFFFF6F3C);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "ລາຍຊື່ຮ້ານຄ້າປະຈຳແຜນ",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: orange,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : data.isEmpty
          ? const Center(child: Text("ບໍ່ພົບລູກຄ້າ"))
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: data.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (BuildContext context, int index) {
                final customer = data[index];
                return ListTile(
                  tileColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                  leading: CircleAvatar(
                    backgroundColor: orange,
                    child: Text(
                      customer['cust_code'].substring(0, 1),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(
                    customer['cust_name'],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text("ລະຫັດ: ${customer['cust_code']}"),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.of(context).pop({
                      "code": customer['cust_code'],
                      "name_1": customer['cust_name'],
                      "group_main": customer['group_main'],
                      "group_sub_1": customer['group_sub_1'],
                    });
                  },
                );
              },
            ),
    );
  }
}
