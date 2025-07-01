import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:odgcashvan/utility/my_constant.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProductForEditDetail extends StatefulWidget {
  final String item_code,
      item_name,
      unit_code,
      barcode,
      qty,
      doc_no,
      doc_date,
      wh_code,
      sh_code;
  const ProductForEditDetail({
    super.key,
    required this.item_code,
    required this.item_name,
    required this.unit_code,
    required this.barcode,
    required this.qty,
    required this.doc_no,
    required this.doc_date,
    required this.wh_code,
    required this.sh_code,
  });

  @override
  State<ProductForEditDetail> createState() => _ProductForEditDetailState();
}

class _ProductForEditDetailState extends State<ProductForEditDetail> {
  var data = [];
  TextEditingController txtQuery = TextEditingController();
  DateTime now = DateTime.now(); // Get current date and time
  bool isLoading = false; // Loading state flag
  bool isLoadingbt = false; // Loading state flag
  var formatter = DateFormat('yyyy-MM-dd');
  @override
  void initState() {
    super.initState();
    showdata();
    txtQuery.text = '1';
  }

  Future<Null> showdata() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    var response = await get(
      Uri.parse(
        MyConstant().domain +
            "/stockbalancedetail/" +
            preferences.getString('wh_code').toString(),
      ),
    );
    var result = json.decode(response.body);
    // print(result);
    setState(() {
      data = result['list'];
    });
  }

  Future<Null> updateProQty(
    String item_code,
    String item_name,
    String unit_code,
    String barcode,
    String qty,
  ) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    String datas = json.encode({
      "doc_no": widget.doc_no.toString(),
      "doc_date": widget.doc_date.toString(),
      "item_code": item_code.toString(),
      "item_name": item_name.toString(),
      "unit_code": unit_code.toString(),
      "barcode": "",
      "qty": txtQuery.text,
      "from_wh": widget.wh_code.toString(),
      "from_sh": widget.sh_code.toString(),
      "to_wh": preferences.getString('wh_code').toString(),
      "to_sh": preferences.getString('sh_code').toString(),
      "user_created": preferences.getString('usercode').toString(),
    });
    var response = await post(
      Uri.parse(MyConstant().domain + "/updateProductRegestQty"),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: datas,
    );
    var result = json.decode(response.body);

    // Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("ລາຍລະອຽດ", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue,
        centerTitle: true,
      ),
      body: Container(
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              child: Text(
                widget.item_code.toString(),
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Container(
              alignment: Alignment.center,
              // color: Colors.green,
              child: Text(
                widget.item_name.toString(),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
            Container(
              margin: EdgeInsets.all(10),
              child: Text(widget.qty.toString()),
            ),
            Container(
              margin: EdgeInsets.all(10),
              child: Text(widget.unit_code.toString()),
            ),
            Container(
              margin: const EdgeInsets.only(left: 60, right: 60, bottom: 10),
              alignment: Alignment.center,
              child: TextFormField(
                controller: txtQuery,
                // onChanged: search,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  // labelText: 'Full Name',
                ),
              ),
            ),
            Container(
              width: double.infinity,
              height: 35,
              margin: const EdgeInsets.only(left: 60, right: 60, bottom: 10),
              color: Colors.blue[800],
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(side: BorderSide.none),
                onPressed: () async {
                  if (int.parse(widget.qty.toString()) >=
                      int.parse(txtQuery.text)) {
                    setState(() {
                      isLoadingbt = true; // เริ่มการโหลด
                    });

                    await updateProQty(
                      widget.item_code,
                      widget.item_name,
                      widget.unit_code,
                      widget.barcode,
                      txtQuery.text,
                    );

                    setState(() {
                      isLoadingbt = false; // การโหลดเสร็จสิ้น
                    });
                    Navigator.pop(context);
                    Navigator.pop(context);
                  } else {
                    showCupertinoDialog(
                      context: context,
                      builder: (context) {
                        return CupertinoAlertDialog(
                          title: Text("ຄຳເຕືອນ"),
                          content: Text("ເກີນຈຳນວນ"),
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
                icon: const Icon(Icons.save, color: Colors.white),
                label: const Text(
                  "ເພີ່ມລາຍການ",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
            Divider(),
            Text("ລາຍການສິນຄ້ານີ້ໃນສາງລົດ"),
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                scrollDirection: Axis.vertical,
                itemCount: data.length,
                itemBuilder: (BuildContext context, int index) {
                  return Card(
                    color: Colors.amber[100],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        1.0,
                      ), // Set the radius here
                    ),
                    elevation: 1,
                    child: ListTile(
                      subtitle: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${data[index]['wh'] + ':' + data[index]['sh']}',
                          ),
                          Text(
                            '${data[index]['qty'].toString() + ' ' + data[index]['ic_unit_code']}',
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
