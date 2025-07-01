import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../utility/my_constant.dart';

class EditQty extends StatefulWidget {
  final String wh_code, sh_code, ic_code, qty, unit_code, doc_no;
  const EditQty(
      {super.key,
      required this.wh_code,
      required this.sh_code,
      required this.ic_code,
      required this.qty,
      required this.unit_code,
      required this.doc_no});

  @override
  State<EditQty> createState() => _EditQtyState();
}

class _EditQtyState extends State<EditQty> {
  TextEditingController txtQuery = TextEditingController();
  String? balance_qty, ic_unit_code;
  @override
  void initState() {
    super.initState();
    showdata();
    txtQuery.text = widget.qty.toString();
  }

  Future<Null> showdata() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    String datas = json.encode({
      // "area_code": preferences.getString('area_code').toString(),
      // "logistic_area": preferences.getString('logistic_code').toString(),
      "wh_code": widget.wh_code.toString(),
      "sh_code": widget.sh_code.toString(),
      "ic_code": widget.ic_code
    });
    var response = await post(
        Uri.parse(MyConstant().domain + "/stockblbyiccodeandwh"),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: datas);
    var result = json.decode(response.body);
    setState(() {
      balance_qty = result['balance_qty'].toString();
      ic_unit_code = result['ic_unit_code'].toString();
    });
  }

  Future<Null> updateProQty() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    String datas = json.encode({
      "doc_no": widget.doc_no.toString(),
      "wh_code": widget.wh_code.toString(),
      "sh_code": widget.sh_code.toString(),
      "ic_code": widget.ic_code,
      "qty": txtQuery.text
    });
    var response = await post(
        Uri.parse(MyConstant().domain + "/updateRegestQty"),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: datas);
    var result = json.decode(response.body);
    Navigator.pop(context);
    // setState(() {
    //   balance_qty = result['balance_qty'].toString();
    //   ic_unit_code = result['ic_unit_code'].toString();
    // });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("ແກ້ໃຂຈຳນວນ"),
      ),
      body: Container(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            margin: EdgeInsets.only(bottom: 10),
            child: Text(
              'ສິນຄ້າໃນໃບຂໍເບີກ ${widget.qty} ${widget.unit_code}',
              style: TextStyle(
                fontSize: 20,
                // color: Colors.blue,
                fontWeight: FontWeight.bold,
                foreground: Paint()
                  ..style = PaintingStyle.stroke // ใช้เส้นขอบ
                  ..strokeWidth = 1 // ความหนาเส้นขอบ
                  ..color = Colors.blue, // สีของเส้นขอบ
              ),
            ),
          ),
          Container(
            margin: EdgeInsets.only(left: 30, right: 30),
            child: TextFormField(
              controller: txtQuery,
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: 'ຈຳນວນໃໝ່',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10), // มุมโค้งของ Border
                  borderSide: BorderSide(
                    color: Colors.grey, // สีของ Border
                    width: 1.5, // ความหนาของ Border
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: Colors.blue, // สีของ Border ขณะไม่ได้ Focus
                    width: 1.5,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: Colors.green, // สีของ Border ขณะ Focus
                    width: 2.0,
                  ),
                ),
              ),
            ),
          ),
          Divider(),
          Text(
            'ຈຳນວນຄົງເຫຼືອໃນສາງ ${balance_qty.toString()} ${ic_unit_code.toString()}',
            style: TextStyle(
              fontSize: 20,
              // color: Colors.blue,
              fontWeight: FontWeight.bold,
              foreground: Paint()
                ..style = PaintingStyle.stroke // ใช้เส้นขอบ
                ..strokeWidth = 1 // ความหนาเส้นขอบ
                ..color = Colors.green, // สีของเส้นขอบ
            ),
          ),
          Divider(),
          Container(
            width: 250,
            child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: Colors.blue, // สีของเส้นขอบ
                    width: 2.0, // ความหนาของเส้นขอบ
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12), // มุมโค้งของปุ่ม
                  ),
                ),
                onPressed: () {
                  if (double.parse(balance_qty.toString()) >=
                      double.parse(txtQuery.text)) {
                    updateProQty();
                  } else {
                    showCupertinoDialog(
                      context: context,
                      builder: (context) {
                        return CupertinoAlertDialog(
                          title: Text("ຄຳເຕືອນ"),
                          content: Text("ຍອດຄົງເຫຼືອໃນສາງບໍພຽງພໍກັບການເບີກ"),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text('OK'),
                            ),
                          ],
                        );
                      },
                    );
                  }
                },
                child: Text("ບັນທຶກ")),
          )
        ],
      )),
    );
  }
}
