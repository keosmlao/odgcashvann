import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:odgcashvan/utility/my_constant.dart';
// import 'package:saletool/utility/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

// import '../../../model/salehistmodel.dart';
class BillHist extends StatefulWidget {
  String? Cust_Code;
  BillHist({super.key, this.Cust_Code});

  @override
  State<BillHist> createState() => _BillHistState();
}

class _BillHistState extends State<BillHist> {
  // late Future<List<SaleHistoryModel>> getdData;
  var data = [];
  @override
  void initState() {
    super.initState();
    showdata();
  }

  Future<void> showdata() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    var server = preferences.getString('server').toString();
    var port = preferences.getString('ports').toString();
    String datas = json.encode({
      // "area_code": preferences.getString('area_code').toString(),
      // "logistic_area": preferences.getString('logistic_code').toString(),
      "department_code": preferences.getString('department').toString(),
      "cust_code": widget.Cust_Code,
    });
    var response = await post(
      Uri.parse(MyConstant().domain + "/salehistory"),
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
      appBar: AppBar(
        title: const Text(
          "ລາຍການບິນຂາຍສິນຄ້າ",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue,
        centerTitle: true,
      ),
      body: Container(
        child: Column(
          children: [
            data.isEmpty
                ? Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(top: 1),
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
                      child: const Center(child: Text("ບໍ່ມີລາຍການ")),
                    ),
                  )
                : Expanded(
                    child: ListView.builder(
                      itemCount: data.length,
                      shrinkWrap: true,
                      physics: const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics(),
                      ),
                      scrollDirection: Axis.vertical,
                      itemBuilder: (BuildContext context, int index) {
                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              1.0,
                            ), // กำหนดรัศมีของมุม
                          ),
                          elevation: 2, // กำหนดเงาใต้ Card
                          child: ListTile(
                            // trailing: Icon(Icons.add_a_photo),
                            title: Text(
                              'ເລກທີ'
                              '${data[index]['doc_no']}',
                            ),
                            subtitle: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("ວັນທີ ${data[index]['doc_date']}"),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "ຈຳນວນ ${data[index]['item_count']} ລາຍການ",
                                    ),
                                    Text(
                                      "ມູນຄ່າ ${data[index]['total_amount']}",
                                      style: const TextStyle(color: Colors.red),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            onTap: () {
                              // Navigator.push(
                              //   context,
                              //   MaterialPageRoute(
                              //     builder: (context) => BillHistDetail(
                              //         doc_no: data[index]['doc_no'].toString()),
                              //   ),
                              // );
                              // SystemChrome.setPreferredOrientations(
                              //   [
                              //     DeviceOrientation.landscapeLeft,
                              //     DeviceOrientation.landscapeRight
                              //   ],
                              // );
                            },
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
