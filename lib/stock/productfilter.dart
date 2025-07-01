import 'package:flutter/material.dart';
import 'package:odgcashvan/stock/group_sub_2.dart';

import 'group_sub.dart';
import 'groupmain.dart';

class ProductFilter extends StatefulWidget {
  const ProductFilter({super.key});

  @override
  State<ProductFilter> createState() => _ProductFilterState();
}

class _ProductFilterState extends State<ProductFilter> {
  String? group_main, group_sub, group_sun_2;
  TextEditingController group_main_name = new TextEditingController();
  TextEditingController group_sub_name = new TextEditingController();
  TextEditingController group_sub_name_2 = new TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Filter")),
      body: Container(
        child: Column(
          children: [
            Container(
              margin: EdgeInsets.only(top: 10, left: 20, right: 20),
              width: MediaQuery.of(context).size.width,
              height: 50,
              // padding: EdgeInsets.only(left: 20, right: 20, top: 10),
              child: TextFormField(
                controller: group_main_name,
                // onChanged: search,
                readOnly: true,
                style: TextStyle(
                  fontSize: 16, // Set the font size
                  color: Colors.black, // Optional: Set text color
                ),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.fromLTRB(10.0, 5.0, 10.0, 5.0),
                  hintText: "ເລືອກກຸ່ມຫຼັກ",
                  hintStyle: TextStyle(fontSize: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5.0),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black),
                  ),
                  prefixIcon: Icon(Icons.add),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.add, size: 15),
                    onPressed: () async {
                      final result = await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) {
                            return GroupMain();
                          },
                        ),
                      );
                      if (null != result) {
                        setState(() {
                          group_main_name.text = result['name_1'];
                          group_main = result['code'];
                        });
                      }
                    },
                  ),
                ),
              ),
            ),
            Container(
              margin: EdgeInsets.only(top: 10, left: 20, right: 20),
              width: MediaQuery.of(context).size.width,
              height: 50,
              // padding: EdgeInsets.only(left: 20, right: 20, top: 10),
              child: TextFormField(
                controller: group_sub_name,
                // onChanged: search,
                readOnly: true,
                style: TextStyle(
                  fontSize: 16, // Set the font size
                  color: Colors.black, // Optional: Set text color
                ),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.fromLTRB(10.0, 5.0, 10.0, 5.0),
                  hintText: "ເລືອກກຸ່ມຍ່ອຍ 1",
                  hintStyle: TextStyle(fontSize: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5.0),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black),
                  ),
                  prefixIcon: Icon(Icons.add),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.add, size: 15),
                    onPressed: () async {
                      final result = await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) {
                            return GroupSub(groupMain: group_main.toString());
                          },
                        ),
                      );
                      if (null != result) {
                        setState(() {
                          group_sub_name.text = result['name_1'];
                          group_sub = result['code'];
                        });
                      }
                    },
                  ),
                ),
              ),
            ),
            Container(
              margin: EdgeInsets.only(top: 10, left: 20, right: 20),
              width: MediaQuery.of(context).size.width,
              height: 50,
              // padding: EdgeInsets.only(left: 20, right: 20, top: 10),
              child: TextFormField(
                controller: group_sub_name_2,
                // onChanged: search,
                readOnly: true,
                style: TextStyle(
                  fontSize: 16, // Set the font size
                  color: Colors.black, // Optional: Set text color
                ),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.fromLTRB(10.0, 5.0, 10.0, 5.0),
                  hintText: "ເລືອກກຸ່ມຍ່ອຍ 2",
                  hintStyle: TextStyle(fontSize: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5.0),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black),
                  ),
                  prefixIcon: Icon(Icons.add),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.add, size: 15),
                    onPressed: () async {
                      final result = await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) {
                            return GroupSub2(
                              group_main: group_main.toString(),
                              group_sub: group_sub.toString(),
                            );
                          },
                        ),
                      );
                      if (null != result) {
                        setState(() {
                          group_sub_name_2.text = result['name_1'];
                          group_sun_2 = result['code'];
                        });
                      }
                    },
                  ),
                ),
              ),
            ),
            Container(
              margin: EdgeInsets.only(top: 10, left: 20, right: 20),
              width: MediaQuery.of(context).size.width,
              height: 50,
              // padding: EdgeInsets.only(left: 20, right: 20, top: 10),
              child: TextFormField(
                // controller: to_sh_name,
                // onChanged: search,
                readOnly: true,
                style: TextStyle(
                  fontSize: 16, // Set the font size
                  color: Colors.black, // Optional: Set text color
                ),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.fromLTRB(10.0, 5.0, 10.0, 5.0),
                  hintText: "ເລືອກໝວດ",
                  hintStyle: TextStyle(fontSize: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5.0),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black),
                  ),
                  prefixIcon: Icon(Icons.add),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.add, size: 15),
                    onPressed: () async {
                      // final result = await Navigator.of(context)
                      //     .push(MaterialPageRoute(builder: (context) {
                      //   return ListLocation(
                      //     wh_codes: wh_code_new.toString(),
                      //   );
                      // }));
                      // if (null != result) {
                      //   setState(() {
                      //     to_sh_name.text = result['name_1'];
                      //     sh_code_new = result['code'];
                      //   });
                      // }
                    },
                  ),
                ),
              ),
            ),
            Container(
              margin: EdgeInsets.only(top: 10, left: 20, right: 20),
              width: MediaQuery.of(context).size.width,
              height: 50,
              // padding: EdgeInsets.only(left: 20, right: 20, top: 10),
              child: TextFormField(
                // controller: to_sh_name,
                // onChanged: search,
                readOnly: true,
                style: TextStyle(
                  fontSize: 16, // Set the font size
                  color: Colors.black, // Optional: Set text color
                ),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.fromLTRB(10.0, 5.0, 10.0, 5.0),
                  hintText: "ຮູບແບບ",
                  hintStyle: TextStyle(fontSize: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5.0),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black),
                  ),
                  prefixIcon: Icon(Icons.add),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.add, size: 15),
                    onPressed: () async {
                      // final result = await Navigator.of(context)
                      //     .push(MaterialPageRoute(builder: (context) {
                      //   return ListLocation(
                      //     wh_codes: wh_code_new.toString(),
                      //   );
                      // }));
                      // if (null != result) {
                      //   setState(() {
                      //     to_sh_name.text = result['name_1'];
                      //     sh_code_new = result['code'];
                      //   });
                      // }
                    },
                  ),
                ),
              ),
            ),
            Container(
              margin: EdgeInsets.only(top: 10, left: 20, right: 20),
              width: MediaQuery.of(context).size.width,
              height: 50,
              // padding: EdgeInsets.only(left: 20, right: 20, top: 10),
              child: TextFormField(
                // controller: to_sh_name,
                // onChanged: search,
                readOnly: true,
                style: TextStyle(
                  fontSize: 16, // Set the font size
                  color: Colors.black, // Optional: Set text color
                ),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.fromLTRB(10.0, 5.0, 10.0, 5.0),
                  hintText: "ຫຍີ່ຫໍ້",
                  hintStyle: TextStyle(fontSize: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5.0),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black),
                  ),
                  prefixIcon: Icon(Icons.add),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.add, size: 15),
                    onPressed: () async {
                      // final result = await Navigator.of(context)
                      //     .push(MaterialPageRoute(builder: (context) {
                      //   return ListLocation(
                      //     wh_codes: wh_code_new.toString(),
                      //   );
                      // }));
                      // if (null != result) {
                      //   setState(() {
                      //     to_sh_name.text = result['name_1'];
                      //     sh_code_new = result['code'];
                      //   });
                      // }
                    },
                  ),
                ),
              ),
            ),
            Container(
              width: MediaQuery.of(context).size.width,
              height: 50,
              margin: EdgeInsets.all(20),
              color: Colors.blue[800],
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(side: BorderSide.none),
                onPressed: () async {
                  // savedata();
                },
                icon: Icon(Icons.search, color: Colors.white),
                label: Text("ຄົ້ນຫາ", style: TextStyle(color: Colors.white)),
              ),
            ),
            Divider(),
          ],
        ),
      ),
    );
  }
}
