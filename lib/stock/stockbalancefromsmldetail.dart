import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:odgcashvan/utility/my_constant.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StockBalanceSmlDetail extends StatefulWidget {
  final String? ic_code, ic_name;
  const StockBalanceSmlDetail({super.key, this.ic_code, this.ic_name});

  @override
  State<StockBalanceSmlDetail> createState() => _StockBalanceSmlDetailState();
}

class _StockBalanceSmlDetailState extends State<StockBalanceSmlDetail> {
  // List<Map<String, dynamic>> _journals = [];
  var data = [];
  var barcode = "";
  TextEditingController txtQuery = new TextEditingController();
  @override
  void initState() {
    super.initState();
    showdata();
    // findUser();
    // showdata();
  }

  Future<Null> showdata() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();

    var response = await get(
      Uri.parse(
        MyConstant().domain + "/stock_detail/" + widget.ic_code.toString(),
      ),
    );
    var result = json.decode(response.body);
    print(result);
    setState(() {
      data = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "ສິນຄ້າຄົງເຫຼືອ",
          style: TextStyle(color: Colors.white, fontSize: 20),
        ),
        centerTitle: true,
        backgroundColor: Colors.blue,
      ),
      body: Container(
        alignment: Alignment.center,
        child: ListView.builder(
          itemCount: data.length,
          itemBuilder: (context, index) {
            final row = data[index];
            return Card(
              margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: ListTile(
                title: Text(
                  row['ic_name'].toString(),
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ຈຳນວນ: ${row['qty']} ${row['ic_unit_code']}'),
                    Text(
                      'ສາງ: ${row['wh']} ${row['sh']}',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
