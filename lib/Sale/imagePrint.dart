import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:http/http.dart';
import 'package:odgcashvan/utility/my_constant.dart';
import 'package:odgcashvan/utility/my_style.dart';
// import 'package:image_gallery_saver/image_gallery_saver.dart';

import 'package:permission_handler/permission_handler.dart';

class PrintImage extends StatefulWidget {
  String doc_no;
  PrintImage({super.key, required this.doc_no});

  @override
  State<PrintImage> createState() => _PrintImageState();
}

class _PrintImageState extends State<PrintImage> {
  GlobalKey _globalKey = GlobalKey();
  var data = [];
  String? sign;
  String? doc_no,
      doc_date,
      cust_code,
      cust_name,
      address,
      tel,
      total_amount,
      vat_rate,
      total_vat_value,
      total_value,
      sale_name,
      cust_line_id;
  @override
  void initState() {
    super.initState();
    print(widget.doc_no);
    showdata();
    // _checkin = widget.checkin.toString();
  }

  Future<Null> showdata() async {
    var response = await get(
      Uri.parse(
        MyConstant().domain + "/vansaleImage/" + widget.doc_no.toString(),
      ),
    );
    var result = json.decode(response.body);
    setState(() {
      print(result['list']);
      sign = result['sign'].toString();
      doc_no = result['doc_no'].toString();
      doc_date = result['doc_date'].toString();
      cust_code = result['cust_code'].toString();
      cust_name = result['cust_name'].toString();
      tel = result['telephone'].toString();
      address = result['address'].toString();
      total_amount = result['total_amount'].toString();
      total_value = result['total_value'].toString();
      total_vat_value = result['total_vat_value'].toString();
      sale_name = result['sale_name'].toString();
      cust_line_id = result['cust_line_id'].toString();
      data = result['list'];
    });
  }

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

  // Method to send image message via Line OA API
  Future<void> sendLineImageMessage(
    String userId,
    String accessToken,
    String imageUrl,
    String previewImageUrl,
  ) async {
    final url = 'https://api.line.me/v2/bot/message/push';

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $accessToken',
    };

    final body = json.encode({
      'to': userId,
      'messages': [
        {
          'type': 'image',
          'originalContentUrl': imageUrl,
          'previewImageUrl': previewImageUrl,
        },
      ],
    });

    try {
      final response = await post(Uri.parse(url), headers: headers, body: body);

      if (response.statusCode == 200) {
        print('Image message sent successfully');
      } else {
        print('Failed to send message: ${response.body}');
      }
    } catch (e) {
      print('Error sending message: $e');
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
  //       name: doc_no,
  //     );

  //     if (result['isSuccess']) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(content: Text('ບັນທຶກລົງໃນ Gallery')),
  //       );

  //       // // Upload image to Flask API
  //       await _uploadImage(pngBytes);
  //     } else {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(content: Text('เกิดข้อผิดพลาดในการบันทึกภาพ')),
  //       );
  //     }
  //   } catch (e) {
  //     print("Error capturing billing image: $e");
  //   }
  // }

  Future<void> _uploadImage(Uint8List pngBytes) async {
    final Uri url = Uri.parse(MyConstant().domain + '/uploadbillimg');
    final request = MultipartRequest('POST', url);

    // Add the image bytes to the request
    request.files.add(
      MultipartFile.fromBytes('file', pngBytes, filename: '${doc_no}.png'),
    );

    // Send the request
    final response = await request.send();

    if (response.statusCode == 200) {
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(content: Text('อัพโหลดภาพใบเสร็จสำเร็จ')),
      // );
      // Upload image to Line
      print(cust_line_id.toString());
      if (cust_line_id.toString() != '') {
        settobase();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('SENT LINE ສຳເລັດ')));
      }
    } else {
      print('Image upload failed');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาดในการอัพโหลดภาพ')));
    }
  }

  settobase() async {
    final imageUrl =
        'http://10.0.10.39:5000/uploads/${doc_no}.png'; // Image URL to send via LINE
    final previewUrl =
        'http://10.0.10.39:5000/uploads/${doc_no}.png'; // Preview image URL for LINE
    await sendLineImageMessage(
      cust_line_id.toString(),
      "dtw1zxHNey9iuRcxya7q2a9QyuB7gAp4LB/pd0guH2UkbzPRsQJW6mNfMVYknsohXyTbBHsgxG2oRwRNv4n9x/tBKaRTf/Qwusym/WAi0sPwE15ypptpsSPqUE8E+zIU2Xnjk4dct68vROq9jECzBwdB04t89/1O/w1cDnyilFU=",
      imageUrl,
      previewUrl,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ບິນຂາຍສິນຄ້າ'),
        centerTitle: true,
        backgroundColor: MyStyle().odien1,
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
                            ),
                          ],
                        ),
                      ),
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
                        Text('ເລກທີ :${doc_no}'),
                        Text('ວັນທີ : ${doc_date}'),
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
                    Text('ລູກຄ້າ : ${cust_name}'),
                    Text('ທີ່ຢູ່ : ${address}'),
                    Text('tel : ${tel}'),
                  ],
                ),
                Divider(thickness: 1),
                SizedBox(height: 10),
                Table(
                  border: TableBorder.all(),
                  columnWidths: const <int, TableColumnWidth>{
                    // 0: FixedColumnWidth(60.0),
                    0: FlexColumnWidth(),
                    1: FixedColumnWidth(60.0),
                    2: FixedColumnWidth(80.0),
                    3: FixedColumnWidth(100.0),
                  },
                  children: [
                    // Header Row
                    TableRow(
                      children: [
                        // Center(
                        //     child: Text('ລ/ດ',
                        //         style: TextStyle(fontWeight: FontWeight.bold))),
                        Center(
                          child: Text(
                            'ລາຍການສິນຄ້າ',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Center(
                          child: Text(
                            'ຈຳນວນ',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Center(
                          child: Text(
                            'ລາຄາ',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Center(
                          child: Text(
                            'ລວມ',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    // Data Rows
                    ...data.map((row) {
                      return TableRow(
                        children: [
                          // Center(
                          //   child: Text(row['item_code'].toString(),
                          //       style: TextStyle(fontSize: 12)),
                          // ),
                          Padding(
                            padding: const EdgeInsets.all(5.0),
                            child: Text(
                              row['item_name'],
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                          Center(
                            child: Container(
                              padding: EdgeInsets.only(top: 5),
                              child: Text(
                                row['qty'].toString(),
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          ),
                          Center(
                            child: Container(
                              padding: EdgeInsets.only(top: 5),
                              child: Text(
                                row['price'],
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.only(right: 5, top: 5),
                            child: Text(
                              row['sum_amount'],
                              style: TextStyle(fontSize: 12),
                              textAlign:
                                  TextAlign.right, // Align text to the right
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ],
                ),
                // SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'ລວມລາຄາ: ${total_amount}',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'ອມພ: ${total_vat_value}',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'ລວມທັງໝົດ:  ${total_amount}',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
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
                          // mainAxisAlignment: MainAxisAlignment.start,
                          // crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("ລູກຄ້າ"),
                            Container(
                              child: Image.memory(
                                base64Decode(sign.toString()),
                                fit: BoxFit.fill,
                                height: 150,
                                width: 150,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        child: Column(
                          // mainAxisAlignment: MainAxisAlignment.start,
                          // crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("ພະນັກຂາຍ"),
                            SizedBox(height: 100),
                            Text(sale_name.toString()),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: Container(
        width: double
            .infinity, // Makes the button take up the full width of the screen
        height: 60, // Adjust the height of the button
        margin: EdgeInsets.only(left: 20), // Optional: margin around the button
        child: OutlinedButton(
          onPressed: _requestPermissions, // เรียกขอสิทธิ์เมื่อกดปุ่ม
          style: OutlinedButton.styleFrom(
            // primary: Colors.white, // Text color (foreground)
            side: BorderSide(
              color: Colors.blue,
              width: 2,
            ), // Border color and width
            backgroundColor:
                Colors.blue, // Button background color (can make it filled)
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                8,
              ), // Rounded corners (optional)
            ),
          ),
          child: Row(
            mainAxisAlignment:
                MainAxisAlignment.center, // Center the text and icon
            children: [
              Icon(Icons.print, color: Colors.white), // Print icon
              // SizedBox(width: 8), // Space between the icon and text
              Text(
                "ບັນທຶກ ແລະ ສົ່ງ", // Text in Lao script
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ), // Adjust text color and size
              ),
            ],
          ),
        ),
      ),
    );
  }
}
