import 'dart:convert';

import 'package:barcode_scan2/platform_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:odgcashvan/utility/my_constant.dart';
import 'package:odgcashvan/utility/my_style.dart';

import '../database/sql_helper.dart';
import 'group_sub.dart';
import 'group_sub_2.dart';
import 'groupmain.dart';
import 'stockbalancefromsmldetail.dart';

class ProductList extends StatefulWidget {
  const ProductList({super.key});

  @override
  State<ProductList> createState() => _ProductListState();
}

class _ProductListState extends State<ProductList> {
  List<Map<String, dynamic>> _journals = [];
  var barcode = "";
  String filter = 'all';
  TextEditingController txtQuery = new TextEditingController();
  String? group_main = '',
      group_sub = '',
      group_sun_2 = '',
      cat_code = '',
      brand_code = '',
      pattern_code = '';
  TextEditingController group_main_name = new TextEditingController();
  TextEditingController group_sub_name = new TextEditingController();
  TextEditingController group_sub_name_2 = new TextEditingController();
  TextEditingController cat = new TextEditingController();
  TextEditingController brand = new TextEditingController();
  TextEditingController petten = new TextEditingController();
  @override
  void initState() {
    super.initState();
    _refreshJournals();
    // findUser();
    // showdata();
  }

  _refreshJournals() async {
    final data = await SQLHelper.getAllproduct();
    setState(() {
      print(data);
      _journals = data;
    });
    // getCount();
  }

  _getbygm() async {
    final data = await SQLHelper.getAllprobygm(group_main.toString());
    setState(() {
      print(data);
      _journals = data;
    });
    // getCount();
  }

  _getbygmgs() async {
    final data = await SQLHelper.getAllprobygmgs(
      group_main.toString(),
      group_sub.toString(),
    );
    // final dataa = await SQLHelper.getDocNo();
    setState(() {
      print(data);
      _journals = data;
    });
    // getCount();
  }

  _getbygmgsgs() async {
    final data = await SQLHelper.getAllprobygmgsgs2(
      group_main.toString(),
      group_sub.toString(),
      group_sun_2.toString(),
    );
    // final dataa = await SQLHelper.getDocNo();
    setState(() {
      print(data);
      _journals = data;
    });
    // getCount();
  }

  getCat() async {
    final data = await SQLHelper.getAllprobygmgsgs2cat(
      group_main.toString(),
      group_sub.toString(),
      group_sun_2.toString(),
      cat_code.toString(),
    );
    // final dataa = await SQLHelper.getDocNo();
    setState(() {
      print(data);
      _journals = data;
    });
    // getCount();
  }

  getPettern() async {
    final data = await SQLHelper.getAllprobygmgsgs2catpettern(
      group_main.toString(),
      group_sub.toString(),
      group_sun_2.toString(),
      cat_code.toString(),
      pattern_code.toString(),
    );
    // final dataa = await SQLHelper.getDocNo();
    setState(() {
      print(data);
      _journals = data;
    });
    // getCount();
  }

  getBrand() async {
    final data = await SQLHelper.getAllprobygmgsgs2catpetternb(
      group_main.toString(),
      group_sub.toString(),
      group_sun_2.toString(),
      cat_code.toString(),
      pattern_code.toString(),
      brand_code.toString(),
    );
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

  // void search(String query) async {
  //   String txt = query.toUpperCase();
  //   txtQuery.text = txt;
  //   if (txt.isEmpty) {
  //     setState(() {
  //       _journals = _journals;
  //     });
  //   } else {
  //     setState(() {
  //       _journals = _journals
  //           .where((element) =>
  //               element['barcode'].toString().contains(txt) ||
  //               element['item_name'].toString().contains(txt))
  //           .toList();
  //     });
  //   }
  //   // final data = await SQLHelper.getAllproduct();
  //   // if (query.isEmpty) {
  //   //   setState(() {
  //   //     _journals = data;
  //   //   });
  //   // } else {
  //   //   final data = await SQLHelper.queryByRow(txt);
  //   //   setState(() {
  //   //     _journals = data;
  //   //   });
  //   // }
  // }
  void search(String query) async {
    String txt = query.toUpperCase();
    txtQuery.text = txt;
    final data =
        await SQLHelper.getAllproduct(); // ดึงข้อมูลสดจากฐานข้อมูลทุกครั้ง

    if (txt.isEmpty) {
      setState(() {
        _journals = data;
      });
    } else {
      setState(() {
        _journals = data.where((element) {
          // <-- ต้องใช้ 'data' แทน '_journals'
          String barcode = element['barcode'].toString().toUpperCase();
          String itemName = element['item_name'].toString().toUpperCase();
          return barcode.contains(txt) || itemName.contains(txt);
        }).toList();
      });
    }
  }

  bool _isLoading = false; // ตัวแปรสถานะเพื่อเช็คว่าโหลดอยู่หรือไม่

  Future<void> getStock() async {
    setState(() {
      _isLoading = true; // เริ่มแสดงสถานะการโหลด
    });

    try {
      Uri url = Uri.parse(MyConstant().domain + "/allproduct");
      var response = await get(
        url,
        headers: {"Keep-Alive": "timeout=5, max=1"},
      );
      var result = json.decode(response.body);
      await SQLHelper.deleteAll();
      for (var item in result['list']) {
        await _addItem(
          item['code'],
          item['name_1'],
          item['unit_cost'],
          item['barcode'],
          item['group_main'],
          item['main_name'],
          item['group_sub'],
          item['sub_name'],
          item['group_sub2'],
          item['sub_name_2'],
          item['item_brand'],
          item['average_cost'],
          item['item_pattern'],
          item['pattern_name'],
          item['cat_name'],
          item['item_category'],
        );
      }

      // แสดงข้อความว่าเสร็จสิ้น
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ໂຫຼດຂໍ້ມູນສຳເລັດ!')));
    } catch (e) {
      print("Error: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() {
        _isLoading = false; // หยุดสถานะการโหลด
        _refreshJournals();
      });
    }
  }

  Future<void> _addItem(
    String item_code,
    String item_name,
    String unitCost,
    String barcode,
    String groupMain,
    String mainName,
    String groupSub,
    String subName,
    String groupSub2,
    String subName_2,
    String itemBrand,
    String average_cost,
    String item_pattern,
    String pattern_name,
    String cat_name,
    String item_category,
  ) async {
    await SQLHelper.createInven(
      item_code,
      item_name,
      unitCost,
      barcode,
      groupMain,
      mainName,
      groupSub,
      subName,
      groupSub2,
      subName_2,
      itemBrand,
      average_cost,
      item_pattern,
      pattern_name,
      cat_name,
      item_category,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          await _refreshJournals();
        },
        child: Container(
          // alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                color: Color(0xff557BBB),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: EdgeInsets.only(left: 5),
                      child: Row(
                        children: [
                          Container(
                            margin: EdgeInsets.only(right: 5),
                            child: OutlinedButton.icon(
                              icon: Icon(Icons.all_inbox),
                              style: OutlinedButton.styleFrom(
                                backgroundColor: filter == 'all'
                                    ? MyStyle().odien2
                                    : Colors.white,
                                side: BorderSide(
                                  color: Colors.amber,
                                  width: 2,
                                ), // กำหนดสีและความหนาของเส้นขอบ
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    10,
                                  ), // กำหนดมุมโค้งมน
                                ),
                              ),
                              onPressed: () {
                                setState(() {
                                  filter = 'all';

                                  group_main = '';
                                  group_sub = '';
                                  group_sun_2 = '';
                                  cat_code = '';
                                  brand_code = '';
                                  pattern_code = '';
                                  group_main_name.text = '';
                                  group_sub_name.text = '';
                                  group_sub_name_2.text = '';
                                  cat.text = '';
                                  brand.text = '';
                                  petten.text = '';
                                  _refreshJournals();
                                });
                              },
                              label: Text(
                                "ທັງໝົດ",
                                style: TextStyle(color: Colors.black),
                              ),
                            ),
                          ),
                          Container(
                            // margin: EdgeInsets.all(5),
                            child: OutlinedButton.icon(
                              icon: Icon(Icons.filter_alt),
                              style: OutlinedButton.styleFrom(
                                backgroundColor: filter == 'filter'
                                    ? MyStyle().odien2
                                    : Colors.white,
                                side: BorderSide(
                                  color: Colors.amber,
                                  width: 2,
                                ), // กำหนดสีและความหนาของเส้นขอบ
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    10,
                                  ), // กำหนดมุมโค้งมน
                                ),
                              ),
                              onPressed: () async {
                                setState(() {
                                  filter = 'filter';
                                });
                                // await Navigator.push(
                                //     context,
                                //     MaterialPageRoute(
                                //       builder: (context) => ProductFilter(),
                                //     ));
                              },
                              label: Text("ກັ່ນຕອງ"),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(side: BorderSide.none),
                        onPressed: () async {
                          getStock();
                        },
                        icon: Icon(Icons.download, color: Colors.white),
                        label: Text(
                          "ດຶງຈາກ SML",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              filter != 'all'
                  ? Container(
                      color: Color(0xff557BBB),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  margin: EdgeInsets.only(
                                    top: 10,
                                    left: 20,
                                    right: 20,
                                  ),
                                  width: MediaQuery.of(context).size.width,
                                  height: 50,
                                  // padding: EdgeInsets.only(left: 20, right: 20, top: 10),
                                  child: TextFormField(
                                    controller: group_main_name,

                                    // onChanged: search,
                                    readOnly: true,
                                    style: TextStyle(
                                      fontSize: 16, // Set the font size
                                      color: Colors
                                          .black, // Optional: Set text color
                                    ),
                                    textAlign: TextAlign.center,
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: Colors.white,
                                      contentPadding: EdgeInsets.fromLTRB(
                                        10.0,
                                        5.0,
                                        10.0,
                                        5.0,
                                      ),
                                      hintText: "ກຸ່ມຫຼັກ",
                                      hintStyle: TextStyle(fontSize: 16),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          5.0,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Colors.black,
                                        ),
                                      ),
                                      // prefixIcon: Icon(Icons.clear),
                                      suffixIcon: IconButton(
                                        icon: Icon(Icons.search),
                                        onPressed: () async {
                                          final result =
                                              await Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: (context) {
                                                    return GroupMain();
                                                  },
                                                ),
                                              );
                                          if (null != result) {
                                            setState(() {
                                              group_main_name.text =
                                                  result['name_1'];
                                              group_main = result['code'];
                                            });
                                            _getbygm();
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Container(
                                  margin: EdgeInsets.only(
                                    top: 10,
                                    left: 20,
                                    right: 20,
                                  ),
                                  width: MediaQuery.of(context).size.width,
                                  height: 50,
                                  // padding: EdgeInsets.only(left: 20, right: 20, top: 10),
                                  child: TextFormField(
                                    controller: group_sub_name,
                                    // onChanged: search,
                                    readOnly: true,
                                    style: TextStyle(
                                      fontSize: 16, // Set the font size
                                      color: Colors
                                          .black, // Optional: Set text color
                                    ),
                                    textAlign: TextAlign.center,
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: Colors.white,
                                      contentPadding: EdgeInsets.fromLTRB(
                                        10.0,
                                        5.0,
                                        10.0,
                                        5.0,
                                      ),
                                      hintText: "ກຸ່ມຍ່ອຍ 1",
                                      hintStyle: TextStyle(fontSize: 16),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          5.0,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Colors.black,
                                        ),
                                      ),
                                      // prefixIcon: Icon(Icons.clear),
                                      suffixIcon: IconButton(
                                        icon: Icon(Icons.search),
                                        onPressed: () async {
                                          final result =
                                              await Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: (context) {
                                                    return GroupSub(
                                                      groupMain: group_main
                                                          .toString(),
                                                    );
                                                  },
                                                ),
                                              );
                                          if (null != result) {
                                            setState(() {
                                              group_sub_name.text =
                                                  result['name_1'];
                                              group_sub = result['code'];
                                            });
                                            _getbygmgs();
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Container(
                                  margin: EdgeInsets.only(
                                    top: 10,
                                    left: 20,
                                    right: 20,
                                  ),
                                  width: MediaQuery.of(context).size.width,
                                  height: 50,
                                  // padding: EdgeInsets.only(left: 20, right: 20, top: 10),
                                  child: TextFormField(
                                    controller: group_sub_name_2,
                                    // onChanged: search,
                                    readOnly: true,
                                    style: TextStyle(
                                      fontSize: 16, // Set the font size
                                      color: Colors
                                          .black, // Optional: Set text color
                                    ),
                                    textAlign: TextAlign.center,
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: Colors.white,
                                      contentPadding: EdgeInsets.fromLTRB(
                                        10.0,
                                        5.0,
                                        10.0,
                                        5.0,
                                      ),
                                      hintText: "ກຸ່ມຍ່ອຍ 2",
                                      hintStyle: TextStyle(fontSize: 16),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          5.0,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Colors.black,
                                        ),
                                      ),
                                      // prefixIcon: Icon(Icons.clear),
                                      suffixIcon: IconButton(
                                        icon: Icon(Icons.search),
                                        onPressed: () async {
                                          final result =
                                              await Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: (context) {
                                                    return GroupSub2(
                                                      group_main: group_main
                                                          .toString(),
                                                      group_sub: group_sub
                                                          .toString(),
                                                    );
                                                  },
                                                ),
                                              );
                                          if (null != result) {
                                            setState(() {
                                              group_sub_name_2.text =
                                                  result['name_1'];
                                              group_sun_2 = result['code'];
                                            });
                                            _getbygmgsgs();
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  margin: EdgeInsets.only(
                                    top: 10,
                                    left: 20,
                                    right: 20,
                                  ),
                                  width: MediaQuery.of(context).size.width,
                                  height: 50,
                                  // padding: EdgeInsets.only(left: 20, right: 20, top: 10),
                                  child: TextFormField(
                                    controller: cat,
                                    // onChanged: search,
                                    readOnly: true,
                                    style: TextStyle(
                                      fontSize: 16, // Set the font size
                                      color: Colors
                                          .black, // Optional: Set text color
                                    ),
                                    textAlign: TextAlign.center,
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: Colors.white,
                                      contentPadding: EdgeInsets.fromLTRB(
                                        10.0,
                                        5.0,
                                        10.0,
                                        5.0,
                                      ),
                                      hintText: "ໝວດ",
                                      hintStyle: TextStyle(fontSize: 16),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          5.0,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Colors.black,
                                        ),
                                      ),
                                      // prefixIcon: Icon(Icons.clear),
                                      suffixIcon: IconButton(
                                        icon: Icon(Icons.search),
                                        onPressed: () async {
                                          // final result =
                                          //     await Navigator.of(context).push(
                                          //         MaterialPageRoute(
                                          //             builder: (context) {
                                          //   return Cat(
                                          //     group_main: group_main.toString(),
                                          //     group_sub: group_sub.toString(),
                                          //     group_sub_2: group_sun_2.toString(),
                                          //   );
                                          // }));
                                          // if (null != result) {
                                          //   setState(() {
                                          //     cat.text = result['name_1'];
                                          //     cat_code = result['code'];
                                          //   });
                                          //   getCat();
                                          // }
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Container(
                                  margin: EdgeInsets.only(
                                    top: 10,
                                    left: 20,
                                    right: 20,
                                  ),
                                  width: MediaQuery.of(context).size.width,
                                  height: 50,
                                  // padding: EdgeInsets.only(left: 20, right: 20, top: 10),
                                  child: TextFormField(
                                    controller: petten,
                                    // onChanged: search,
                                    readOnly: true,
                                    style: TextStyle(
                                      fontSize: 16, // Set the font size
                                      color: Colors
                                          .black, // Optional: Set text color
                                    ),
                                    textAlign: TextAlign.center,
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: Colors.white,
                                      contentPadding: EdgeInsets.fromLTRB(
                                        10.0,
                                        5.0,
                                        10.0,
                                        5.0,
                                      ),
                                      hintText: "ຮູບແບບ",
                                      hintStyle: TextStyle(fontSize: 16),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          5.0,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Colors.black,
                                        ),
                                      ),
                                      // prefixIcon: Icon(Icons.clear),
                                      suffixIcon: IconButton(
                                        icon: Icon(Icons.search),
                                        onPressed: () async {
                                          // final result =
                                          //     await Navigator.of(context).push(
                                          //         MaterialPageRoute(
                                          //             builder: (context) {
                                          //   return Pettern(
                                          //     group_main: group_main.toString(),
                                          //     group_sub: group_sub.toString(),
                                          //     group_sub_2: group_sun_2.toString(),
                                          //     cat: cat_code.toString(),
                                          //   );
                                          // }));
                                          // if (null != result) {
                                          //   setState(() {
                                          //     petten.text = result['name_1'];
                                          //     pattern_code = result['code'];
                                          //   });
                                          //   getPettern();
                                          // }
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Container(
                                  margin: EdgeInsets.only(
                                    top: 10,
                                    left: 20,
                                    right: 20,
                                  ),
                                  width: MediaQuery.of(context).size.width,
                                  height: 50,
                                  // padding: EdgeInsets.only(left: 20, right: 20, top: 10),
                                  child: TextFormField(
                                    controller: brand,
                                    // onChanged: search,
                                    readOnly: true,
                                    style: TextStyle(
                                      fontSize: 16, // Set the font size
                                      color: Colors
                                          .black, // Optional: Set text color
                                    ),
                                    textAlign: TextAlign.center,
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: Colors.white,
                                      contentPadding: EdgeInsets.fromLTRB(
                                        10.0,
                                        5.0,
                                        10.0,
                                        5.0,
                                      ),
                                      hintText: "ຫຍີ່ຫໍ້",
                                      hintStyle: TextStyle(fontSize: 16),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          5.0,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Colors.black,
                                        ),
                                      ),
                                      // prefixIcon: Icon(Icons.clear),
                                      suffixIcon: IconButton(
                                        icon: Icon(Icons.search),
                                        onPressed: () async {
                                          // final result =
                                          //     await Navigator.of(context).push(
                                          //         MaterialPageRoute(
                                          //             builder: (context) {
                                          //   return Brand(
                                          //     group_main: group_main.toString(),
                                          //     group_sub: group_sub.toString(),
                                          //     group_sub_2: group_sun_2.toString(),
                                          //     cat: cat_code.toString(),
                                          //     pp: pattern_code.toString(),
                                          //   );
                                          // }));
                                          // if (null != result) {
                                          //   setState(() {
                                          //     brand.text = result['name_1'];
                                          //     brand_code = result['code'];
                                          //   });
                                          //   getBrand();
                                          // }
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Divider(),
                        ],
                      ),
                    )
                  : Container(),
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
                        contentPadding: EdgeInsets.fromLTRB(
                          10.0,
                          5.0,
                          10.0,
                          5.0,
                        ),
                        hintText: "ຄົ້ນຫາສິນຄ້າ",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(5.0),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.black),
                        ),
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
              _isLoading
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(), // วงกลมหมุนแสดงสถานะโหลด
                          SizedBox(height: 10),
                          Text('ກຳລັງໂຫຼດຂໍ້ມູນຈາກ sml...'),
                        ],
                      ),
                    )
                  : _journals.length == 0
                  ? Expanded(child: Center(child: Text("ບໍພົບລາຍການສິນຄ້າ")))
                  : Expanded(
                      child: ListView.builder(
                        itemCount: _journals.length,
                        itemBuilder: (context, index) => Card(
                          // color: Colors.orange[200],
                          // margin: const EdgeInsets.all(15),
                          child: ListTile(
                            title: _journals[index]['barcode'] == ''
                                ? Text(
                                    "ບໍພົບ Barcode",
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : Text(
                                    _journals[index]['barcode'],
                                    style: TextStyle(
                                      color: Colors.blue,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
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
                                  '+ ' + _journals[index]['unitCost'],
                                  style: TextStyle(
                                    color: Color.fromARGB(255, 164, 129, 3),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => StockBalanceSmlDetail(
                                    ic_code: _journals[index]['item_code']
                                        .toString(),
                                    ic_name: _journals[index]['item_name']
                                        .toString(),
                                  ),
                                ),
                              );
                            },
                          ),
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
