import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:odgcashvan/utility/my_constant.dart';
import 'package:odgcashvan/utility/signout_process.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeAcc extends StatefulWidget {
  const HomeAcc({super.key});

  @override
  State<HomeAcc> createState() => _HomeAccState();
}

class _HomeAccState extends State<HomeAcc> {
  var data = [];
  FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
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
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                showdata();
                // Navigator.pop(context);
              },
              child: Text('ອອກເລີຍ'),
            ),
            // TextButton(
            //   onPressed: () => Navigator.pop(context),
            //   child: Text('ອອກ'),
            // ),
          ],
        );
      },
    );
  }

  Future<Null> showdata() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    var response = await get(
      Uri.parse(MyConstant().domain + "/listbillforchecktransfer"),
    );
    var result = json.decode(response.body);
    // print(result);
    setState(() {
      data = result['list'];
    });
  }

  Future<Null> savetoDb(id, doc_date, total_amount, cust_code, fcm) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    String datass = json.encode({
      'doc_no': id.toString(),
      'sale_code': preferences.getString('usercode').toString(),
      'doc_date': doc_date.toString(),
      'total_amount': total_amount.toString(),
      'cust_code': cust_code.toString(),
      'fcm': fcm.toString(),
    });
    try {
      var response = await post(
        Uri.parse("${MyConstant().domain}/confirmpayment"),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: datass,
      );
      if (response.statusCode == 200) {
        showdata();
      } else {}
    } catch (e) {
      print(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("ລາຍຊື່ຂໍກວດສອບ", style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.blue,
        actions: <Widget>[
          IconButton(icon: Icon(Icons.history), onPressed: () => {showdata()}),
          IconButton(
            icon: Icon(Icons.exit_to_app),
            onPressed: () => signOutProcess(context),
          ),
        ],
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
                        title: Row(
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
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
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
                                    onPressed: () {
                                      showCupertinoDialog(
                                        context: context,
                                        builder: (context) {
                                          return CupertinoAlertDialog(
                                            title: Text("ອະນຸມັດ"),
                                            content: Text(
                                              "ກະລຸນາກົດຢືນຢັນເພື່ອອະນຸມັດ",
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () {
                                                  savetoDb(
                                                    data[index]['doc_no'],
                                                    data[index]['doc_date'],
                                                    data[index]['total_amount'],
                                                    data[index]['cust_code'],
                                                    data[index]['tokend_fcm'],
                                                  );
                                                  Navigator.pop(context);
                                                },
                                                child: Text('ຢືນຢັນ'),
                                              ),
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(context),
                                                child: Text('ກັບຄືນ'),
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    },
                                    child: Text("ອະນຸມັດ"),
                                  ),
                                ),
                                Text(
                                  'ມູນຄ່າບິນ: ${NumberFormat('#,##0').format(double.parse(data[index]['total_amount']))}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: Colors.orange[800],
                                  ),
                                ),
                              ],
                            ),
                            Divider(),
                            Container(
                              child: Center(
                                child: Image.memory(
                                  base64Decode(data[index]['pic'].toString()),
                                  fit: BoxFit.fill,
                                  height: 300,
                                  width: 300,
                                ),
                              ),
                            ),
                            Divider(),
                            ListView.builder(
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              itemCount: data[index]['list'].length,
                              itemBuilder: (context, innerIndex) {
                                return Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${data[index]['list'][innerIndex]['item_name']} ${data[index]['list'][innerIndex]['qty']} ${data[index]['list'][innerIndex]['unit_code']}',
                                      style: TextStyle(
                                        color:
                                            data[index]['list'][innerIndex]['remark'] ==
                                                'free'
                                            ? Color.fromARGB(255, 237, 111, 102)
                                            : Colors.green[600],
                                      ),
                                    ),
                                  ],
                                );
                              },
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
