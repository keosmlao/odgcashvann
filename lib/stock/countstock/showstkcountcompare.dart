import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:odgcashvan/utility/my_constant.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ShowStkCountCompare extends StatefulWidget {
  String doc_no;
  ShowStkCountCompare({super.key, required this.doc_no});

  @override
  State<ShowStkCountCompare> createState() => _ShowStkCountCompareState();
}

class _ShowStkCountCompareState extends State<ShowStkCountCompare> {
  var data = [];
  @override
  void initState() {
    super.initState();

    showdata();
  }

  Future<Null> showdata() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();

    var response = await get(
      Uri.parse(
        MyConstant().domain +
            "/listbillcountstockdetail/" +
            widget.doc_no.toString(),
      ),
    );
    var result = json.decode(response.body);
    // print(result);
    setState(() {
      data = result['list'];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "ລາຍການສິນຄ້າໃນໃບກວດນັບ",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.orange,
        centerTitle: true,
      ),
      body: Container(
        child: Column(
          children: [
            Expanded(
              child: Container(
                margin: EdgeInsets.all(5),
                // height: 300,
                decoration: BoxDecoration(
                  color: Colors.white,
                  // borderRadius: BorderRadius.all(Radius.circular(1)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 1,
                      blurRadius: 1,
                      // offset: Offset(0, 3), // changes position of shadow
                    ),
                  ],
                ),
                child: ListView.builder(
                  itemCount: data.length,
                  itemBuilder: (BuildContext context, int index) {
                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          1.0,
                        ), // ปรับค่าความโค้งของขอบ
                      ),
                      elevation: 2, // ระดับเงา
                      child: ListTile(
                        subtitle: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Divider(),
                            Text('+ ${data[index]['item_code']}'),
                            Text('+ ${data[index]['item_name']}'),
                            Divider(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'ວັນທີ: ${data[index]['doc_date']}',
                                  style: TextStyle(color: Colors.green[800]),
                                ),
                                Text(
                                  'ເວລາ: ${data[index]['doc_time']}',
                                  style: TextStyle(color: Colors.green[800]),
                                ),
                              ],
                            ),
                            Text("***************"),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'ຄົງເຫຼືອ: ${data[index]['balance_qty']} ${data[index]['unit_code']}',
                                  style: TextStyle(
                                    color: Colors.green[800],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'ນັບໃດ້: ${data[index]['count_qty']} ${data[index]['unit_code']}',
                                  style: TextStyle(
                                    color: Colors.green[800],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  'ຜົນຕ່າງ: ${data[index]['diff']} ${data[index]['unit_code']}',
                                  style: TextStyle(
                                    color: double.parse(data[index]['diff']) > 0
                                        ? Colors.orange[800]
                                        : Colors.red[800],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
