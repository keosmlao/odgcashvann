import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
// import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';

class BillingImagePage extends StatefulWidget {
  @override
  _BillingImagePageState createState() => _BillingImagePageState();
}

class _BillingImagePageState extends State<BillingImagePage> {
  GlobalKey _globalKey = GlobalKey();

  // ฟังก์ชันเพื่อขอสิทธิ์การเข้าถึง storage
  Future<void> _requestPermissions() async {
    if (await Permission.manageExternalStorage.request().isGranted) {
      // หากสิทธิ์ได้รับการอนุญาตแล้ว
      // _captureBillingImage();
    } else {
      // หากผู้ใช้ปฏิเสธสิทธิ์
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('กรุณาอนุญาตการเข้าถึงไฟล์ทั้งหมด')),
      );
    }
  }

  // // ฟังก์ชันในการจับภาพจาก widget
  // Future<void> _captureBillingImage() async {
  //   try {
  //     RenderRepaintBoundary boundary = _globalKey.currentContext!
  //         .findRenderObject() as RenderRepaintBoundary;
  //     ui.Image image = await boundary.toImage(pixelRatio: 3.0);
  //     ByteData? byteData =
  //         await image.toByteData(format: ui.ImageByteFormat.png);
  //     Uint8List pngBytes = byteData!.buffer.asUint8List();

  //     // บันทึกรูปภาพลงในแกลเลอรี
  //     final result = await ImageGallerySaver.saveImage(
  //       pngBytes,
  //       quality: 100,
  //       name: "billing_image",
  //     );

  //     if (result['isSuccess']) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(content: Text('บันทึกใบเสร็จลงในแกลเลอรีสำเร็จ')),
  //       );
  //     } else {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(content: Text('เกิดข้อผิดพลาดในการบันทึกภาพ')),
  //       );
  //     }
  //   } catch (e) {
  //     print("Error capturing billing image: $e");
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Generate Billing Image'),
      ),
      body: SingleChildScrollView(
        child: RepaintBoundary(
          key: _globalKey,
          child: Container(
            padding: EdgeInsets.all(20),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  child: Row(
                    children: [
                      Row(
                        children: [
                          Center(
                            child: Image.asset(
                              'assets/odg.jpg',
                              height: 50,
                              width: 100,
                            ),
                          ),
                        ],
                      ),
                      Container(
                          margin: EdgeInsets.only(left: 5),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "ODIEN GROUP",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                "ບ້ານ ຂົວຫຼວງ ເມືອງ ຈັນທະບູລິ ນະຄອນຫຼວງ ວຽງຈັນ",
                                style: TextStyle(
                                  fontSize: 13,
                                  // fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                "Tel: (+856-21) 412663, 412659, 450443, 451434,263412, fax:263411",
                                style: TextStyle(
                                  fontSize: 13,
                                  // fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                "info@odien.net",
                                style: TextStyle(
                                  fontSize: 13,
                                  // fontWeight: FontWeight.bold,
                                ),
                              )
                            ],
                          ))
                    ],
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('ເລກທີ : CAHSP24003775'),
                        Text('ວັນທີ : 02-01-2025'),
                      ],
                    ),
                  ],
                ),
                Center(
                  child: Text(
                    'ບິນຂາຍສິນຄ້າ (ສົດ)',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(height: 10),
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ລູກຄ້າ : CAHSP24003775'),
                    Text('ທີ່ຢູ່ : CAHSP24003775'),
                    Text('tel : CAHSP24003775'),
                  ],
                ),
                Divider(thickness: 1),
                SizedBox(height: 10),
                Table(
                  border: TableBorder.all(),
                  columnWidths: const <int, TableColumnWidth>{
                    0: FixedColumnWidth(50.0),
                    1: FlexColumnWidth(),
                    2: FixedColumnWidth(80.0),
                    3: FixedColumnWidth(100.0),
                    4: FixedColumnWidth(100.0),
                  },
                  children: [
                    TableRow(
                      children: [
                        Center(child: Text('ລ/ດ')),
                        Center(child: Text('ລາຍການສິນຄ້າ')),
                        Center(child: Text('ຈຳນວນ')),
                        Center(child: Text('ລາຄາ')),
                        Center(child: Text('ລວມ')),
                      ],
                    ),
                    TableRow(
                      children: [
                        Center(child: Text('1')),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text('ຂາຍ WHITE R22 13.6KG'),
                        ),
                        Center(child: Text('23')),
                        Center(child: Text('2,850')),
                        Center(child: Text('59,800')),
                      ],
                    ),
                  ],
                ),
                // SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'ລວມລາຄາ: 59,800 ກີບ',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'ສ່ວນຫຼຸດ: 59,800 ກີບ',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'ລວມທັງໝົດ: 59,800 ກີບ',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Container(
                  margin: EdgeInsets.only(left: 40, right: 40),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        child: Column(
                          children: [
                            Text("ລູກຄ້າ"),
                            SizedBox(
                              height: 40,
                            )
                          ],
                        ),
                      ),
                      Container(
                        child: Column(
                          children: [
                            Text("ພະນັກຂາຍ"),
                            SizedBox(
                              height: 40,
                            )
                          ],
                        ),
                      )
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _requestPermissions, // เรียกขอสิทธิ์เมื่อกดปุ่ม
        child: Icon(Icons.save),
      ),
    );
  }
}
