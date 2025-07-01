import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../database/sql_helper.dart';
import 'addcountstockdetail.dart';

class ListProduct extends StatefulWidget {
  const ListProduct({super.key});

  @override
  State<ListProduct> createState() => _ListProductState();
}

class _ListProductState extends State<ListProduct> {
  List<Map<String, dynamic>> _journals = [];
  var barcode = "";
  TextEditingController txtQuery = new TextEditingController();
  @override
  void initState() {
    super.initState();
    _refreshJournals();
  }

  _refreshJournals() async {
    final data = await SQLHelper.getAllproduct();
    // final dataa = await SQLHelper.getDocNo();
    setState(() {
      print(data);
      _journals = data;
    });
    // getCount();
  }

  Future scan() async {
    try {
      var barcode = await BarcodeScanner.scan();
      setState(() => this.barcode = barcode.rawContent);

      setState(() async {
        txtQuery.text = barcode.rawContent;
        search(txtQuery.text);
      });
    } on PlatformException catch (e) {
      if (e.code == BarcodeScanner.cameraAccessDenied) {
        // The user did not grant the camera permission.
      } else {
        // Unknown error.
      }
    } on FormatException {
      // User returned using the "back"-button before scanning anything.
    } catch (e) {
      // Unknown error.
    }
  }

  void search(String query) async {
    final data = await SQLHelper.getAllproduct();
    if (query.isEmpty) {
      setState(() {
        _journals = data;
      });
    } else {
      final data = await SQLHelper.queryByRow(txtQuery.text);
      setState(() {
        _journals = data;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "ລາຍການສິນຄ້າ",
          style: TextStyle(color: Colors.white, fontSize: 20),
        ),
        centerTitle: true,
        backgroundColor: Colors.blue,
      ),
      body: Container(
        alignment: Alignment.center,
        child: Column(
          children: [
            Container(
              margin: EdgeInsets.only(left: 5, right: 5, top: 2),
              // height: 10,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  TextFormField(
                    controller: txtQuery,
                    onChanged: search,
                    decoration: InputDecoration(
                      contentPadding: EdgeInsets.fromLTRB(10.0, 5.0, 10.0, 5.0),
                      hintText: "ຄົ້ນຫາສິນຄ້າ",
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(5.0)),
                      focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.black)),
                      prefixIcon: Icon(Icons.search),
                      suffixIcon: IconButton(
                        icon: Icon(Icons.qr_code_scanner_sharp),
                        onPressed: () {
                          scan();
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _journals.length == 0
                ? Expanded(
                    child: Center(
                      child: Text("ບໍພົບລາຍການສິນຄ້າ"),
                    ),
                  )
                : Expanded(
                    child: ListView.builder(
                      itemCount: _journals.length,
                      itemBuilder: (context, index) => Card(
                        // color: Colors.orange[200],
                        // margin: const EdgeInsets.all(15),
                        child: ListTile(
                          title: _journals[index]['barcode'] == ''
                              ? Text("ບໍພົບ Barcode",
                                  style: TextStyle(
                                      color: Colors.red,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold))
                              : Text(_journals[index]['barcode'],
                                  style: TextStyle(
                                      color: Colors.blue,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '+ ' + _journals[index]['item_code'],
                                style: TextStyle(
                                    color: Colors.green, fontSize: 12),
                              ),
                              Text('+ ' + _journals[index]['item_name'],
                                  style: TextStyle(
                                      color: Color.fromARGB(255, 164, 129, 3),
                                      fontSize: 12)),
                              Text('+ ' + _journals[index]['unitCost'],
                                  style: TextStyle(
                                      color: Color.fromARGB(255, 164, 129, 3),
                                      fontSize: 12)),
                            ],
                          ),
                          onTap: () async {
                            await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AddCountStockDetail(
                                    item_code: _journals[index]['item_code'],
                                    item_name: _journals[index]['item_name'],
                                    unit_code: _journals[index]['unitCost'],
                                  ),
                                ));
                            _refreshJournals();
                          },
                        ),
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
