import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:odgcashvan/database/sql_helper.dart';
import 'package:odgcashvan/utility/my_constant.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../listorderbycust.dart'; // Make sure this path is correct

class Payment extends StatefulWidget {
  final String cust_code;
  final String total_amount; // Changed to final for consistency

  const Payment({
    Key? key, // Added Key for consistency
    required this.cust_code,
    required this.total_amount,
  }) : super(key: key);

  @override
  State<Payment> createState() => _PaymentState();
}

class _PaymentState extends State<Payment> {
  bool _isLoading = false; // Track loading state
  List<Map<String, dynamic>> _journals = [];
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage; // Renamed for clarity

  // Define consistent colors for the theme
  final Color _primaryBlue = Colors.blue.shade600;
  final Color _accentBlue = Colors.blue.shade800;
  final Color _backgroundColor = Colors.grey.shade100;
  final Color _cardColor = Colors.white;
  final Color _textColor = Colors.grey.shade800;
  final Color _mutedTextColor = Colors.grey.shade600;
  final Color _successColor = Colors.green.shade600; // Used for amounts/success
  final Color _errorColor = Colors.red.shade600; // Used for errors/warnings
  final Color _buttonPrimaryColor = Colors.blue.shade700; // For main buttons
  final Color _borderColor = Colors.grey.shade300; // Used for borders

  // Number formatter for currency display
  final NumberFormat _currencyFormatter = NumberFormat(
    '#,##0.00',
  ); // With decimals
  final NumberFormat _integerFormatter = NumberFormat(
    '#,##0',
  ); // For larger integer amounts

  @override
  void initState() {
    super.initState();
    // No initial data fetch for journals here, as they are fetched in savetodatabase
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 800, // Optimize image size for upload
        maxHeight: 800,
        imageQuality: 90, // Adjust quality for smaller file size
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'ບໍ່ສາມາດເລືອກຮູບພາບ: $e',
              style: const TextStyle(
                fontFamily: 'NotoSansLao',
                color: Colors.white,
              ),
            ),
            backgroundColor: _errorColor,
          ),
        );
      }
      print("Error picking image: $e");
    }
  }

  Future<void> _saveToDatabase() async {
    if (_selectedImage == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'ກະລຸນາແນບຮູບພາບສະລິບກ່ອນ',
              style: TextStyle(fontFamily: 'NotoSansLao', color: Colors.white),
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return; // Stop if no image selected
    }

    setState(() {
      _isLoading = true; // Show loading indicator
    });

    try {
      FirebaseMessaging messaging = FirebaseMessaging.instance;
      String? token = await messaging.getToken();
      String img1Base64 = base64.encode(_selectedImage!.readAsBytesSync());

      final data = await SQLHelper.getOrdersbtcust(widget.cust_code);
      setState(() {
        _journals = data; // Assign fetched order items
      });

      SharedPreferences preferences = await SharedPreferences.getInstance();

      final Map<String, dynamic> requestBody = {
        "cust_code": widget.cust_code,
        "side_code": preferences.getString('side_code'),
        "department_code": preferences.getString('department_code'),
        "sale_code": preferences.getString('usercode'),
        "total_amount": widget.total_amount,
        "wh_code": preferences.getString('wh_code'),
        "sh_code": preferences.getString('sh_code'),
        "bank_account": preferences.getString('bank_account'),
        "tokend": token,
        "payment_image": img1Base64,
        "route_id": preferences.getString('route_id'),
        "bill": _journals,
      };

      var response = await post(
        Uri.parse("${MyConstant().domain}/savevansale"),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        await SQLHelper.deleteAlloder();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'ບັນທຶກການຊຳລະສຳເລັດ',
                style: TextStyle(
                  fontFamily: 'NotoSansLao',
                  color: Colors.white,
                ),
              ),
              backgroundColor: _successColor,
            ),
          );
        }
        // Pop current screen (Payment), then pop previous screen (SalePage's payment options)
        // and navigate to ListOrderbyCust
        Navigator.of(context).popUntil(
          (route) => route.isFirst,
        ); // Pop all routes until the first one
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ListOrderbyCust(cust_code: widget.cust_code),
          ),
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'ບໍ່ສາມາດບັນທຶກການຊຳລະໄດ້: ${response.statusCode}',
                style: const TextStyle(
                  fontFamily: 'NotoSansLao',
                  color: Colors.white,
                ),
              ),
              backgroundColor: _errorColor,
            ),
          );
        }
        print(
          "Failed to save payment: ${response.statusCode}, Body: ${response.body}",
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'ເກີດຂໍ້ຜິດພາດ: $e',
              style: const TextStyle(
                fontFamily: 'NotoSansLao',
                color: Colors.white,
              ),
            ),
            backgroundColor: _errorColor,
          ),
        );
      }
      print("Error saving payment: $e");
    } finally {
      setState(() {
        _isLoading = false; // Hide loading indicator
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    double totalAmount = double.tryParse(widget.total_amount) ?? 0.0;

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: const Text(
          "ຊຳລະຜ່ານການໂອນ",
          style: TextStyle(color: Colors.white, fontFamily: 'NotoSansLao'),
        ),
        centerTitle: true,
        backgroundColor: _primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Total Amount Display
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              color: Colors
                  .green, // Green background for total amount due for transfer
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 20,
                  horizontal: 16,
                ),
                child: Column(
                  children: [
                    Text(
                      "ຍອດເງິນທີ່ຕ້ອງໂອນ",
                      style: TextStyle(
                        fontFamily: 'NotoSansLao',
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _currencyFormatter.format(totalAmount),
                      style: const TextStyle(
                        fontFamily: 'NotoSansLao',
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      "ບາດ",
                      style: TextStyle(
                        fontFamily: 'NotoSansLao',
                        fontSize: 20,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // QR Code Section
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              color: _cardColor,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Text(
                      "ກະລຸນາສະແກນ QR ເພື່ອໂອນ",
                      style: TextStyle(
                        fontFamily: 'NotoSansLao',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _primaryBlue,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 15),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: _borderColor, width: 1.0),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.asset(
                          'assets/qrbaht.jpg', // Ensure this image exists in your assets
                          height: 250, // Fixed height for consistency
                          width: double.infinity,
                          fit: BoxFit
                              .contain, // Use contain to ensure full image is visible
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 250,
                              color: Colors.grey.shade200,
                              child: Center(
                                child: Icon(
                                  Icons.qr_code_2,
                                  size: 100,
                                  color: Colors.grey.shade400,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      "ກະລຸນາໂອນເງິນໃຫ້ຖືກຕ້ອງຕາມຈຳນວນທີ່ສະແດງ.",
                      style: TextStyle(
                        fontFamily: 'NotoSansLao',
                        fontSize: 14,
                        color: _errorColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Attach Slip Section
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              color: _cardColor,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      "ແນບ SLIP ການໂອນເງິນ",
                      style: TextStyle(
                        fontFamily: 'NotoSansLao',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _primaryBlue,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 15),
                    _selectedImage == null
                        ? Column(
                            children: [
                              SizedBox(
                                height: 120, // Placeholder height
                                child: Center(
                                  child: Icon(
                                    Icons.receipt_long,
                                    size: 60,
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 15),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            _accentBlue, // Darker blue for camera
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                      ),
                                      onPressed: () =>
                                          _pickImage(ImageSource.camera),
                                      icon: const Icon(Icons.camera_alt),
                                      label: const Text(
                                        "ຖ່າຍຮູບ",
                                        style: TextStyle(
                                          fontFamily: 'NotoSansLao',
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            _buttonPrimaryColor, // Primary blue for gallery
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                      ),
                                      onPressed: () =>
                                          _pickImage(ImageSource.gallery),
                                      icon: const Icon(Icons.photo_library),
                                      label: const Text(
                                        "ຄັງຮູບ",
                                        style: TextStyle(
                                          fontFamily: 'NotoSansLao',
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          )
                        : Column(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: _borderColor,
                                    width: 1.0,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.file(
                                    _selectedImage!,
                                    height: 200, // Fixed height for consistency
                                    width: double.infinity,
                                    fit: BoxFit.cover, // Cover the area
                                  ),
                                ),
                              ),
                              const SizedBox(height: 15),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        _errorColor, // Red for delete
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _selectedImage = null;
                                    });
                                  },
                                  icon: const Icon(Icons.delete_forever),
                                  label: const Text(
                                    "ລົບຮູບພາບ",
                                    style: TextStyle(
                                      fontFamily: 'NotoSansLao',
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),

            // Confirm Payment Button
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: _isLoading
                    ? null
                    : _saveToDatabase, // Disable when loading
                style: ElevatedButton.styleFrom(
                  backgroundColor: _buttonPrimaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 5,
                ),
                icon: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.check_circle_outline, size: 28),
                label: Text(
                  _isLoading ? "ກຳລັງບັນທຶກ..." : "ຢືນຢັນການຊຳລະ",
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
