import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:odgcashvan/database/sql_helper.dart';
import 'package:odgcashvan/utility/my_constant.dart';

import 'package:shared_preferences/shared_preferences.dart';

class AddCountStockDetail extends StatefulWidget {
  String item_code, item_name, unit_code;
  AddCountStockDetail({
    super.key,
    required this.item_code,
    required this.item_name,
    required this.unit_code,
  });

  @override
  State<AddCountStockDetail> createState() => _AddCountStockDetailState();
}

class _AddCountStockDetailState extends State<AddCountStockDetail> {
  String? balance_qty = '0', usercode;

  TextEditingController count_qty = new TextEditingController();

  @override
  void initState() {
    super.initState();
    findUser();
  }

  void findUser() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    setState(() {
      usercode = preferences.getString('usercode').toString();
    });
  }

  Future<Null> getStockbalance() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    var datas = json.encode({
      "item_code": widget.item_code.toString(),
      "wh_code": preferences.getString('wh_code').toString(),
      "sh_code": preferences.getString('sh_code').toString(),
    });
    var response = await post(
      Uri.parse(MyConstant().domain + "/stockblbywhsh"),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: datas,
    );

    // SharedPreferences preferences = await SharedPreferences.getInstance();
    // var response =
    //     await get(Uri.parse(MyConstant().domain + "/job_completebymgt/" + id));
    var result = json.decode(response.body);
    print(result);
    setState(() {
      balance_qty = result['balance_qty']?.toString() ?? '0';
    });
  }

  Future<void> _addItem(
    String item_code,
    String item_name,
    String balance_qty,
    String count_qty,
    String unit_code,
    String sale_code,
  ) async {
    await SQLHelper.createCountstock(
      item_code,
      item_name,
      balance_qty,
      count_qty,
      unit_code,
      sale_code,
    );
    Navigator.pop(context);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("ລາຍລະອຽດ", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.orange[800],
        centerTitle: true,
      ),
      body: Container(
        width: double.infinity,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          // crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              child: Text(
                widget.item_code,
                style: TextStyle(color: Colors.black, fontSize: 16),
              ),
            ),
            Container(
              margin: const EdgeInsets.only(left: 20, right: 20, bottom: 10),
              width: double.infinity,
              color: Colors.amber,
              alignment: Alignment.center,
              child: Center(
                child: Text(
                  widget.item_name,
                  style: TextStyle(color: Colors.green[800], fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Text(widget.unit_code),
            Container(
              margin: const EdgeInsets.only(left: 20, right: 20),
              alignment: Alignment.center,
              child: TextFormField(
                controller: count_qty,
                // onChanged: search,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15),
                keyboardType: TextInputType.number,
              ),
            ),
            Container(
              margin: EdgeInsets.only(left: 20, right: 20, top: 10),
              width: double.infinity,
              height: 40,
              color: Colors.blue[800],
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(side: BorderSide.none),
                onPressed: () async {
                  _addItem(
                    widget.item_code,
                    widget.item_name,
                    balance_qty.toString(),
                    count_qty.text,
                    widget.unit_code,
                    usercode.toString(),
                  );
                },
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text(
                  "ເພີມ",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
