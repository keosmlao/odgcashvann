import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:odgcashvan/stock/countstock/showstkcountcompare.dart';
import 'package:odgcashvan/utility/my_constant.dart';

import 'package:shared_preferences/shared_preferences.dart';

class ReportCompareStockCount extends StatefulWidget {
  const ReportCompareStockCount({super.key});

  @override
  State<ReportCompareStockCount> createState() =>
      _ReportCompareStockCountState();
}

class _ReportCompareStockCountState extends State<ReportCompareStockCount> {
  TextEditingController dateInput = TextEditingController();
  var data = [];

  DateTime now = DateTime.now(); // Get current date and time

  var formatter = DateFormat('yyyy-MM-dd');

  @override
  void initState() {
    super.initState();
    var formattshow = DateFormat('dd-MM-yyyy');
    dateInput.text = formattshow.format(now);

    showdata(formatter.format(now));
  }

  Future<Null> showdata(id) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    var datas = json.encode({
      "sale_code": preferences.getString('usercode').toString(),
      "doc_date": id.toString(),
    });
    var response = await post(
      Uri.parse(MyConstant().domain + "/listbillcountstock"),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: datas,
    );
    var result = json.decode(response.body);
    setState(() {
      data = result['list'];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            margin: EdgeInsets.all(10),
            child: Text(
              "ເລືອກວັນທີ",
              style: TextStyle(color: Colors.orange[800], fontSize: 16),
            ),
          ),
          Container(
            // width: 300,
            child: TextFormField(
              controller: dateInput,
              textAlign: TextAlign.center,
              readOnly: true,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.fromLTRB(10.0, 5.0, 10.0, 5.0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xffdc8405)),
                ),
                // prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.calendar_month),
                  onPressed: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(1950),
                      //DateTime.now() - not to allow to choose before today.
                      lastDate: DateTime(2100),
                    );

                    String formattedDate = DateFormat(
                      'dd-MM-yyyy',
                    ).format(pickedDate!);
                    setState(() {
                      dateInput.text =
                          formattedDate; //set output date to TextField value.
                      showdata(DateFormat('yyyy-MM-dd').format(pickedDate));
                    });
                  },
                ),
              ),
            ),
          ),
          Divider(color: Colors.red),
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
                          Text('+ ວັນທີ: ${data[index]['doc_date']}'),
                          Text('+ ເລກທີ: ${data[index]['doc_no']}'),
                          Text('+ ຈຳນວນ: ${data[index]['item_count']} ລາຍການ'),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ShowStkCountCompare(
                              doc_no: data[index]['doc_no'],
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
