import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:odgcashvan/route_plan/customer/checkin.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../utility/my_constant.dart';

class ListCustomer extends StatefulWidget {
  const ListCustomer({super.key});

  @override
  State<ListCustomer> createState() => _ListCustomerState();
}

class _ListCustomerState extends State<ListCustomer> {
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
            "/listcustomerinnroute/" +
            preferences.getString('usercode').toString(),
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
          "ລາຍຊື່ຮ້ານຄ້າປະຈຳແຜນ",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.blue,
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
                        // trailing: Icon(Icons.add_a_photo),
                        title: Text('${data[index]['cust_name']}'),

                        subtitle: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Divider(),
                            Text('ທີ່ຢູ່: ${data[index]['address']}'),
                            Text(' ${data[index]['address_2']}'),
                            Text('+ ${data[index]['area_name']}'),
                            Text('+ ${data[index]['logistic_name']}'),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  'ມູນຄ່າບິນລ້າສຸດ: ${data[index]['total_amount']}',
                                ),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  'ມູນຄ່າເງິນລ້າສຸດ: ${data[index]['payment']}',
                                ),
                              ],
                            ),
                            Divider(),
                            Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      height: 30,
                                      width: 100,
                                      child: OutlinedButton(
                                        style: OutlinedButton.styleFrom(
                                          side: BorderSide(
                                            width: 1.0,
                                            color: Colors.blue,
                                          ), // กำหนดขอบปุ่ม
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              5.0,
                                            ), // ปรับความโค้งของขอบ
                                          ),
                                        ),
                                        onPressed: () {},
                                        child: Text("MAP"),
                                      ),
                                    ),
                                    Container(
                                      height: 30,
                                      // width: ,
                                      child: OutlinedButton(
                                        style: OutlinedButton.styleFrom(
                                          side: BorderSide(
                                            width: 1.0,
                                            color: Colors.blue,
                                          ), // กำหนดขอบปุ่ม
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              5.0,
                                            ), // ปรับความโค้งของขอบ
                                          ),
                                        ),
                                        onPressed: () async {
                                          await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => CheckIn(
                                                cust_code:
                                                    data[index]['cust_code']
                                                        .toString(),
                                                doc_no: data[index]['doc_no']
                                                    .toString(),
                                                checkin: data[index]['checkin']
                                                    .toString(),
                                                latlng: data[index]['latlng']
                                                    .toString(),
                                                pic: data[index]['pic1']
                                                    .toString(),
                                              ),
                                            ),
                                          );
                                        },
                                        child: Text("Check-In"),
                                      ),
                                    ),
                                    // Container(
                                    //     height: 30,
                                    //     // width: 100,
                                    //     child: OutlinedButton(
                                    //         style: OutlinedButton.styleFrom(
                                    //           backgroundColor: Colors.amber,
                                    //           side: BorderSide(
                                    //               width: 1.0,
                                    //               color: Colors
                                    //                   .red), // กำหนดขอบปุ่ม
                                    //           shape: RoundedRectangleBorder(
                                    //             borderRadius:
                                    //                 BorderRadius.circular(
                                    //                     5.0), // ปรับความโค้งของขอบ
                                    //           ),
                                    //         ),
                                    //         onPressed: () async {
                                    //           await Navigator.push(
                                    //               context,
                                    //               MaterialPageRoute(
                                    //                 builder: (context) =>
                                    //                     ListOrder(
                                    //                   cust_code: data[index]
                                    //                           ['cust_code']
                                    //                       .toString(),
                                    //                   cust_group_1: data[
                                    //                               index]
                                    //                           ['group_main']
                                    //                       .toString(),
                                    //                   cust_group_2: data[
                                    //                               index]
                                    //                           ['group_sub_1']
                                    //                       .toString(),
                                    //                 ),
                                    //               ));
                                    //         },
                                    //         child: Text(
                                    //           "ເປິດບີນ",
                                    //           style: TextStyle(
                                    //               color: Colors.red),
                                    //         )))
                                  ],
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
