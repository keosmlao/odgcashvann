import 'dart:convert';
import 'dart:ui' as ui; // Renamed to avoid conflict with flutter/material

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_signaturepad/signaturepad.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http; // Explicitly alias http

import '../utility/my_constant.dart';

class ConfirmDispatchScreen extends StatefulWidget {
  final String doc_no;

  const ConfirmDispatchScreen({Key? key, required this.doc_no})
    : super(key: key);

  @override
  _ConfirmDispatchScreenState createState() => _ConfirmDispatchScreenState();
}

class _ConfirmDispatchScreenState extends State<ConfirmDispatchScreen> {
  final GlobalKey<SfSignaturePadState> signatureGlobalKey = GlobalKey();
  String _currentDate = '';
  bool _isLoading = false; // Renamed for consistency

  // Define consistent colors for the theme
  final Color _primaryColor = const Color(0xFF007BFF); // A vibrant blue
  final Color _accentColor = const Color(
    0xFF0056B3,
  ); // A darker blue for accents
  final Color _backgroundColor = const Color(
    0xFFF8F9FA,
  ); // Light gray background
  final Color _cardColor = Colors.white;
  final Color _textColorPrimary = const Color(
    0xFF343A40,
  ); // Dark gray for main text
  final Color _textColorSecondary = const Color(
    0xFF6C757D,
  ); // Muted gray for secondary text
  final Color _buttonColor = const Color(
    0xFF28A745,
  ); // Green for confirm button
  final Color _clearButtonColor = const Color(
    0xFFDC3545,
  ); // Red for clear button

  @override
  void initState() {
    super.initState();
    _getCurrentTime();
  }

  void _handleClearButtonPressed() {
    signatureGlobalKey.currentState?.clear(); // Use null-safe access
  }

  void _getCurrentTime() {
    DateTime now = DateTime.now();
    String formattedDate = DateFormat('yyyy-MM-dd HH:mm').format(now);

    setState(() {
      _currentDate = formattedDate;
    });
  }

  void _handleSaveButtonPressed() async {
    setState(() {
      _isLoading = true; // Start loading
    });

    try {
      final data = await signatureGlobalKey.currentState!.toImage(
        pixelRatio: 3.0,
      );
      final bytes = await data.toByteData(format: ui.ImageByteFormat.png);

      if (bytes == null) {
        _showSnackBar('ບໍ່ສາມາດບັນທຶກລາຍເຊັນໄດ້', _clearButtonColor);
        return;
      }

      SharedPreferences preferences = await SharedPreferences.getInstance();
      String requestBody = json.encode({
        'sign': base64.encode(bytes.buffer.asUint8List()),
        'doc_no': widget.doc_no, // Use widget.doc_no directly
        'doc_date': _currentDate,
      });

      var response = await http.post(
        Uri.parse('${MyConstant().domain}/confirmDispatch'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: requestBody,
      );

      if (response.statusCode == 200) {
        _showSnackBar('ບັນທຶກການເບີກຈ່າຍສຳເລັດ', _buttonColor);
        Navigator.pop(context); // Go back after success
      } else {
        _showSnackBar(
          'ເກີດຂໍ້ຜິດພາດ: ${response.statusCode}',
          _clearButtonColor,
        );
        print("Error: ${response.statusCode}, Body: ${response.body}");
      }
    } catch (e) {
      _showSnackBar('ເກີດຂໍ້ຜິດພາດໃນການບັນທຶກ: $e', _clearButtonColor);
      print("Exception: $e");
    } finally {
      setState(() {
        _isLoading = false; // End loading
      });
    }
  }

  void _showSnackBar(String message, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(
              fontFamily: 'NotoSansLao',
              color: Colors.white,
            ),
          ),
          backgroundColor: color,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: const Text(
          "ຢືນຢັນການເບີກຈ່າຍ",
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'NotoSansLao',
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: _primaryColor,
        centerTitle: true,
        foregroundColor: Colors.white, // Ensure back icon is white
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch, // Stretch children
          children: [
            Text(
              "ເລກທີເອກະສານ: ${widget.doc_no}",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'NotoSansLao',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _textColorPrimary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "ກະລຸນາລົງລາຍເຊັນເພື່ອຢືນຢັນການຮັບສິນຄ້າ",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'NotoSansLao',
                fontSize: 16,
                color: _textColorSecondary,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              height: 300, // Fixed height for signature pad
              decoration: BoxDecoration(
                color: _cardColor,
                border: Border.all(color: Colors.grey.shade400, width: 2),
                borderRadius: BorderRadius.circular(12), // Rounded corners
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: SfSignaturePad(
                key: signatureGlobalKey,
                backgroundColor: _cardColor,
                strokeColor: Colors.black,
                minimumStrokeWidth: 1.0,
                maximumStrokeWidth: 4.0,
              ),
            ),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment:
                  MainAxisAlignment.end, // Align clear button to end
              children: <Widget>[
                TextButton.icon(
                  onPressed: _handleClearButtonPressed,
                  icon: Icon(Icons.clear, color: _clearButtonColor, size: 20),
                  label: Text(
                    'ລົບລາຍເຊັນ',
                    style: TextStyle(
                      fontFamily: 'NotoSansLao',
                      color: _clearButtonColor,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 55, // Fixed height for the button
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _buttonColor, // Green button for save
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      12,
                    ), // Rounded button corners
                  ),
                  elevation: 5, // Add shadow
                ),
                onPressed: _isLoading
                    ? null
                    : _handleSaveButtonPressed, // Disable when loading
                icon: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const FaIcon(
                        FontAwesomeIcons
                            .solidFloppyDisk, // Use solid icon for clarity
                        color: Colors.white,
                        size: 20,
                      ),
                label: Text(
                  _isLoading ? "ກຳລັງບັນທຶກ..." : "ບັນທຶກລາຍເຊັນ",
                  style: const TextStyle(
                    fontFamily: 'NotoSansLao',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
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
