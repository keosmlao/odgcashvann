import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:odgcashvan/utility/my_constant.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../database/sql_helper.dart';
import '../comfirmdispatch.dart';
import '../listorderbycust.dart';

class KipPayment extends StatefulWidget {
  final String cust_code, total_amount;
  const KipPayment({
    super.key,
    required this.cust_code,
    required this.total_amount,
  });

  @override
  State<KipPayment> createState() => _KipPaymentState();
}

class _KipPaymentState extends State<KipPayment> {
  late WebViewController controller;
  List<Map<String, dynamic>> _journals = [];
  String? doc_no;
  String? exchange_rat;
  double total_kip_amount = 0;
  @override
  void initState() {
    super.initState();
    check_rate();
    getdoc_no();

    print("docno " + doc_no.toString());
  }

  Future<Null> getdoc_no() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    var response = await get(Uri.parse(MyConstant().domain + "/getdoc_no/CAV"));
    var result = json.decode(response.body);
    print("doc_no " + result);

    setState(() {
      doc_no = result;
    });
    print("docno " + doc_no.toString());
    // String paymentUrl =
    //     'https://www.odienmall.com/payment_qr/${doc_no}/${total_kip_amount}';
    String paymentUrl = 'https://www.odienmall.com/payment_qr/1233/1';
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted) // เปิดใช้งาน JavaScript
      ..loadRequest(Uri.parse(paymentUrl))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            print('Page started loading: $url');
          },
          onPageFinished: (url) {
            print('Page finished loading: $url');
          },
        ),
      )
      ..addJavaScriptChannel(
        'FlutterChannel', // ชื่อ channel ที่สื่อสารกับ JavaScript
        onMessageReceived: (message) {
          // เมื่อ Flutter ได้รับข้อความจาก JavaScript
          print('Message from JS: ${message.message}');

          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Received: ການໂອນເງິນສຳເລັດ')));
          savetodatabase();
        },
      );
  }

  Future<Null> check_rate() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    var response = await get(Uri.parse(MyConstant().domain + "/exchang_rate"));
    var result = json.decode(response.body);
    print(result['exange_rate']);
    setState(() {
      exchange_rat = result['exange_rate'].toString();
      total_kip_amount =
          double.parse(widget.total_amount.toString()) *
          double.parse(exchange_rat.toString());
    });
  }

  Future<void> savetodatabase() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    // Get FCM Token
    String? token = await messaging.getToken();
    String img1 = '';
    final data = await SQLHelper.getOrdersbtcust(widget.cust_code);
    setState(() {
      _journals = data;
    });
    SharedPreferences preferences = await SharedPreferences.getInstance();

    String jsonProduct = json.encode({
      "doc_no": doc_no.toString(),
      "cust_code": widget.cust_code.toString(),
      "side_code": preferences.getString('side_code').toString(),
      "department_code": preferences.getString('department_code').toString(),
      "sale_code": preferences.getString('usercode').toString(),
      "total_amount": widget.total_amount,
      "total_amount_2": total_kip_amount.toString(),
      "wh_code": preferences.getString('wh_code').toString(),
      "sh_code": preferences.getString('sh_code').toString(),
      "exchange_rate": exchange_rat,
      "tokend": token,
      "route_id": preferences.getString('route_id').toString(),
      "bill": _journals,
    });
    try {
      var response = await post(
        Uri.parse("${MyConstant().domain}/savevansaleKip"),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonProduct,
      );
      print(response.statusCode);
      if (response.statusCode == 200) {
        _deleteItemAll();
        Navigator.pop(context);
        Navigator.pop(context);
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ListOrderbyCust(cust_code: widget.cust_code.toString()),
          ),
        );
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ConfirmDispatchScreen(doc_no: doc_no.toString()),
          ),
        );
      } else {}
    } catch (e) {
      print(e.toString());
    }
  }

  // Delete an item
  void _deleteItemAll() async {
    await SQLHelper.deleteAlloder();
    // ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
    //   content: Text('Successfully'),
    // ));

    // _refreshJournals();
    // Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('ຊຳລະເງິນ'), // ตั้งชื่อแอปให้เหมาะสม
      ),
      body: Column(
        children: [
          Divider(),
          Text(
            'ອັດຕາແລກປ່ຽນ : ${exchange_rat.toString()}',
            style: TextStyle(fontSize: 20),
          ),
          Divider(),
          Container(
            // margin: EdgeInsets.all(5),
            padding: EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              color: Colors.green[800], // สีพื้นหลัง
              border: Border.all(
                color: Colors.blue, // สีของเส้นขอบ
                width: 2.0, // ความกว้างของเส้นขอบ
              ),
              // borderRadius: BorderRadius.circular(12), // มุมโค้งของเส้นขอบ
            ),
            alignment: Alignment.center,
            child: Text(
              NumberFormat(
                '#,##0',
              ).format(double.parse(total_kip_amount.toString())),
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          // SizedBox(height: 20),
          Expanded(child: WebViewWidget(controller: controller)),
        ],
      ),
    );
  }
}
