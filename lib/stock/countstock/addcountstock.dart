import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:odgcashvan/database/sql_helper.dart';
import 'package:odgcashvan/stock/countstock/listproduct.dart';
import 'package:odgcashvan/utility/my_constant.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Addcountstock extends StatefulWidget {
  const Addcountstock({super.key});

  @override
  State<Addcountstock> createState() => _AddcountstockState();
}

class _AddcountstockState extends State<Addcountstock> {
  List<Map<String, dynamic>> _journals = [];
  DateTime now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _refreshJournals();
  }

  _refreshJournals() async {
    final data = await SQLHelper.getDraftProductcount();
    // final dataa = await SQLHelper.getDocNo();
    setState(() {
      print(data);
      _journals = data;
    });
    // getCount();
  }

  Future<void> savetodatabase() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    // Get FCM Token
    String? token = await messaging.getToken();

    SharedPreferences preferences = await SharedPreferences.getInstance();
    String formattedDate = DateFormat('yyyy-MM-dd HH:mm').format(now);
    String formattedTime = DateFormat('HH:mm').format(now);
    String jsonProduct = json.encode({
      // "side_code": preferences.getString('side_code').toString(),
      // "department_code": preferences.getString('department_code').toString(),
      "sale_code": preferences.getString('usercode').toString(),
      "wh_code": preferences.getString('wh_code').toString(),
      "sh_code": preferences.getString('sh_code').toString(),
      "doc_date": formattedDate.toString(),
      "doc_time": formattedTime.toString(),
      "tokend": token,
      "item_count": _journals.length,
      "bill": _journals,
    });
    try {
      var response = await post(
        Uri.parse("${MyConstant().domain}/savecounttobase"),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonProduct,
      );
      print(response.statusCode);
      if (response.statusCode == 200) {
        _deleteItemAll();
        Navigator.pop(context);
        Navigator.pop(context);
      } else {}
    } catch (e) {
      print(e.toString());
    }
  }

  void _deleteItem(int id) async {
    print(id);
    await SQLHelper.deleteItemcountbyid(id);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Successfully deleted a journal!')),
    );
    _refreshJournals();
  }

  void _deleteItemAll() async {
    await SQLHelper.deleteallitem_count();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Successfully deleted a journal!')),
    );
    _refreshJournals();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("ລາຍການກວດນັບ", style: TextStyle(color: Colors.white)),
        actions: [
          Container(
            height: 30,
            margin: EdgeInsets.only(right: 10),
            child: OutlinedButton(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ListProduct()),
                );
                _refreshJournals();
              },
              child: Text("ສິນຄ້າ", style: TextStyle(color: Colors.white)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: Colors.blue,
                  width: 2.0,
                ), // Border color and width
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5.0), // Rounded corners
                ),
              ),
            ),
          ),
        ],
        backgroundColor: Colors.orange[800],
        centerTitle: true,
      ),
      body: Container(
        alignment: Alignment.center,
        child: Column(
          children: [
            _journals.length == 0
                ? Expanded(child: Center(child: Text("ບໍພົບລາຍການສິນຄ້າ")))
                : Expanded(
                    child: ListView.builder(
                      itemCount: _journals.length,
                      itemBuilder: (context, index) => Card(
                        // color: Colors.orange[200],
                        // margin: const EdgeInsets.all(15),
                        child: ListTile(
                          subtitle: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '+ ' + _journals[index]['item_code'],
                                style: TextStyle(
                                  color: Colors.green,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                '+ ' + _journals[index]['item_name'],
                                style: TextStyle(
                                  color: Color.fromARGB(255, 164, 129, 3),
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                '+ ${_journals[index]['count_qty'].toString()} ${_journals[index]['unit_code']}',
                                style: TextStyle(
                                  color: Color.fromARGB(255, 164, 129, 3),
                                  fontSize: 12,
                                ),
                              ),
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
                                        _deleteItem(_journals[index]['id']);
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
                      ),
                    ),
                  ),
            Container(
              margin: EdgeInsets.only(left: 5, right: 5),
              width: double.infinity,
              height: 40,
              color: Colors.blue[800],
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(side: BorderSide.none),
                onPressed: () async {
                  savetodatabase();
                },
                icon: const Icon(Icons.add_card, color: Colors.white),
                label: const Text(
                  "ບັນທຶກ",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
