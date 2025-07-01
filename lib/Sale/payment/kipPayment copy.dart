import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class KipPayment extends StatefulWidget {
  final String cust_code, total_amount;
  const KipPayment(
      {super.key, required this.cust_code, required this.total_amount});

  @override
  State<KipPayment> createState() => _KipPaymentState();
}

class _KipPaymentState extends State<KipPayment> {
  @override
  Widget build(BuildContext context) {
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted) // เปิดใช้งาน JavaScript
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

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Received: ${message.message}')),
          );
          Navigator.pop(context);
        },
      )
      ..loadFlutterAsset('assets/index.html'); // โหลดไฟล์ HTML

    return Scaffold(
      appBar: AppBar(
        title: Text('Local HTML WebView'),
      ),
      body: WebViewWidget(controller: controller),
    );
  }
}
