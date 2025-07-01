import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:odgcashvan/Sale/comfirmdispatch.dart';
import 'package:odgcashvan/utility/my_constant.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'imagePrint.dart';

class ListOrder extends StatefulWidget {
  ListOrder({super.key});

  @override
  State<ListOrder> createState() => _ListOrderState();
}

class _ListOrderState extends State<ListOrder> {
  FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  var data = [];
  @override
  void initState() {
    super.initState();
    showdata();
    // ขอ permission สำหรับ iOS
    _firebaseMessaging.requestPermission();

    // รับข้อความที่เข้ามาเมื่อแอปเปิดอยู่ (foreground)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        // แสดงการแจ้งเตือนแบบ In-app (AlertDialog)
        _showInAppNotification(
          message.notification!.title,
          message.notification!.body,
        );
      }
    });

    // ตรวจสอบว่าแอปได้รับข้อความระหว่างที่เปิดอยู่
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Message clicked! ${message.data}');
    });

    // รับ token ของ FCM
    _firebaseMessaging.getToken().then((token) {
      print("FCM Token: $token");
    });
  }

  // ฟังก์ชันในการแสดงการแจ้งเตือนในแอป
  void _showInAppNotification(String? title, String? body) {
    showCupertinoDialog(
      context: context,
      builder: (context) {
        return CupertinoAlertDialog(
          title: Text(title ?? 'New Notification'),
          content: Text(
            body ?? 'You have received a notification',
            style: TextStyle(color: Colors.green[800]),
          ),
          actions: [
            // TextButton(
            //   onPressed: () {
            //     Navigator.pop(context);
            //     Navigator.pop(context);
            //   },
            //   child: Text('ອອກເລີຍ'),
            // ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('ອອກ'),
            ),
          ],
        );
      },
    );
    // showDialog(
    //   context: context,
    //   builder: (BuildContext context) {
    //     return AlertDialog(
    //       title: Text(title ?? 'New Notification'),
    //       content: Text(body ?? 'You have received a notification'),
    //       actions: <Widget>[
    //         TextButton(
    //           child: Text('OK'),
    //           onPressed: () {
    //             Navigator.of(context).pop();
    //             showdata();
    //           },
    //         ),
    //       ],
    //     );
    //   },
    // );
  }

  Future<Null> showdata() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    DateTime now = DateTime.now(); // Get current date and time
    // var now = DateTime.now();
    var formatter = DateFormat('yyyy-MM-dd');
    String datas = json.encode({
      "doc_date": formatter.format(now),
      "sale_code": preferences.getString('usercode').toString(),
      "cust_code": "",
    });
    var response = await post(
      Uri.parse(MyConstant().domain + "/listorderincust"),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: datas,
    );
    var result = json.decode(response.body);
    // var result = json.decode(response.body);
    print(result);
    setState(() {
      data = result['list'];
    });
  }

  Future<Null> deleteBillCount(id) async {
    var response = await get(
      Uri.parse(MyConstant().domain + "/deletesaleorderbill/" + id),
    );
    var result = json.decode(response.body);
    showdata();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          await showdata();
        },
        child: Container(
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
                          title:
                              data[index]['status'].toString() ==
                                  'ເບີກຈ່າຍຂອງໃດ້'
                              ? Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${data[index]['status']}',
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Container(
                                      height: 35,
                                      child: OutlinedButton(
                                        style: OutlinedButton.styleFrom(
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              5,
                                            ), // Set the radius here
                                          ),
                                        ),
                                        onPressed: () async {
                                          await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  ConfirmDispatchScreen(
                                                    doc_no:
                                                        data[index]['doc_no']
                                                            .toString(),
                                                  ),
                                            ),
                                          );
                                          showdata();
                                        },
                                        child: Text("ຢືນຢັນການເບີກຈ່າຍ"),
                                      ),
                                    ),
                                  ],
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${data[index]['status']}',
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),

                          subtitle: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Divider(),
                              Text('+ ວັນທີ:${data[index]['doc_date']}'),
                              Text('+ ເລກທີ${data[index]['doc_no']}'),
                              Text('+ ຈຳນວນ${data[index]['count_item']}'),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    'ມູນຄ່າບິນ: ${NumberFormat('#,##0').format(double.parse(data[index]['total_amount']))}',
                                  ),
                                ],
                              ),
                              Text("+++++++++++--------------------------"),
                              ListView.builder(
                                shrinkWrap: true,
                                physics: NeverScrollableScrollPhysics(),
                                itemCount: data[index]['list'].length,
                                itemBuilder: (context, innerIndex) {
                                  return Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '    ${data[index]['list'][innerIndex]['item_name']} ${data[index]['list'][innerIndex]['qty']} ${data[index]['list'][innerIndex]['unit_code']}',
                                        style: TextStyle(
                                          color:
                                              data[index]['list'][innerIndex]['remark'] ==
                                                  'free'
                                              ? Color.fromARGB(
                                                  255,
                                                  237,
                                                  111,
                                                  102,
                                                )
                                              : Colors.green[600],
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                              Divider(),
                              data[index]['status'].toString() == 'ສຳເລັດ'
                                  ? Container(
                                      width: 120,
                                      child: OutlinedButton(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => PrintImage(
                                                doc_no: data[index]['doc_no']
                                                    .toString(),
                                              ),
                                            ),
                                          );
                                        },
                                        child: Row(
                                          children: [
                                            Icon(Icons.print),
                                            Text("ພີມບິນ"),
                                          ],
                                        ),
                                      ),
                                    )
                                  : Container(),
                            ],
                          ),
                          onLongPress: () {
                            showCupertinoDialog(
                              context: context,
                              builder: (context) {
                                return CupertinoAlertDialog(
                                  title: Text("ລົບເລີຍ"),
                                  content: Text("ຢືນຢັນການລົບ"),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        deleteBillCount(data[index]['doc_no']);
                                        Navigator.pop(context);
                                      },
                                      child: Text('ລົບເລີຍ'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: Text('ກັບຄືນ'),
                                    ),
                                  ],
                                );
                              },
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
        ),
      ),
    );
  }
}
