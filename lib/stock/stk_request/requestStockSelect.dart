import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:odgcashvan/database/sql_helper.dart';
import 'package:odgcashvan/utility/normal_dialog.dart'; // Assuming this provides a standard dialog
import 'package:odgcashvan/utility/my_style.dart'; // Assuming MyStyle has theme colors

import 'package:shared_preferences/shared_preferences.dart';

import '../../utility/my_constant.dart';

class RequestStockSelect extends StatefulWidget {
  final String wh_code, sh_code;
  const RequestStockSelect({
    super.key,
    required this.wh_code,
    required this.sh_code,
  });

  @override
  State<RequestStockSelect> createState() => _RequestStockSelectState();
}

class _RequestStockSelectState extends State<RequestStockSelect> {
  final TextEditingController _remarkController =
      TextEditingController(); // Renamed for clarity
  bool _isLoading = false; // To manage loading state

  @override
  void dispose() {
    _remarkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "ເພີ່ມເຕີມຂໍ້ມູນໂອນສິນຄ້າ", // More specific title: "Additional Transfer Info"
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: MyStyle().odien1, // Use theme color
        centerTitle: true,
        elevation: 4, // Add a subtle shadow
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0), // Consistent padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch, // Stretch children
          children: [
            Text(
              "ໝາຍເຫດ:", // Remark label
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _remarkController,
              maxLines: 6, // Allow more lines for detailed remarks
              decoration: InputDecoration(
                hintText: 'ປ້ອນໜາຍເຫດເພີ່ມເຕີມທີ່ນີ້...', // Hint text
                hintStyle: TextStyle(color: Colors.grey.shade400),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0), // Rounded corners
                  borderSide: BorderSide(
                    color: Colors.grey.shade300,
                    width: 1.5,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide(
                    color: Colors.grey.shade400,
                    width: 1.5,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide(
                    color: MyStyle().odien1,
                    width: 2.5,
                  ), // Focus color
                ),
                contentPadding: const EdgeInsets.all(16.0), // Inner padding
              ),
            ),
            const Spacer(), // Pushes the button to the bottom
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: MyStyle().odien1, // Theme color for button
                foregroundColor: Colors.white, // Text/icon color
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                ), // Larger padding
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0), // Rounded corners
                ),
                elevation: 5, // Add shadow
              ),
              onPressed: _isLoading
                  ? null
                  : _saveRequestToDatabase, // Disable when loading
              icon: _isLoading
                  ? const SizedBox(
                      width: 24, // Size for CircularProgressIndicator
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                    )
                  : const Icon(Icons.save, size: 28), // Save icon
              label: Text(
                _isLoading
                    ? "ກຳລັງບັນທຶກ..."
                    : "ບັນທຶກໃບຂໍໂອນສິນຄ້າເຂົ້າລົດ", // Text changes based on loading
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveRequestToDatabase() async {
    setState(() {
      _isLoading = true; // Start loading
    });

    try {
      String formattedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
      String formattedTime = DateFormat(
        'HH:mm',
      ).format(DateTime.now()); // Added seconds for more precision

      SharedPreferences preferences = await SharedPreferences.getInstance();
      final List<Map<String, dynamic>> draftData =
          await SQLHelper.getDratRpstock();

      // Validate if there are items in the draft before saving
      if (draftData.isEmpty) {
        if (mounted) {
          normalDialog(
            context,
            'ຂໍ້ມູນບໍ່ຄົບຖ້ວນ',
            "ກະລຸນາເພີ່ມລາຍການສິນຄ້າກ່ອນບັນທຶກ.",
          );
        }
        return; // Exit function if no items
      }

      String? toWhCode = preferences.getString('wh_code');
      String? toShCode = preferences.getString('sh_code');
      String? userCode = preferences.getString('usercode');

      // Basic validation for shared preferences data
      if (toWhCode == null || toShCode == null || userCode == null) {
        if (mounted) {
          normalDialog(
            context,
            'ຂໍ້ມູນບໍ່ຄົບຖ້ວນ',
            "ບໍ່ພົບຂໍ້ມູນສາງປາຍທາງ ຫຼື ຂໍ້ມູນຜູ້ໃຊ້, ກະລຸນາເຂົ້າສູ່ລະບົບໃໝ່.",
          );
        }
        return;
      }

      String jsonProduct = json.encode({
        'from_wh': widget.wh_code,
        'from_sh': widget.sh_code,
        'to_wh': toWhCode,
        'to_sh': toShCode,
        'remark': _remarkController.text.trim(), // Trim whitespace
        'user_created': userCode,
        'doc_date': formattedDate,
        'doc_time': formattedTime,
        'detail': draftData,
      });

      print(
        'Sending Request Body: $jsonProduct',
      ); // Debugging: print the payload

      var response =
          await post(
            Uri.parse(MyConstant().domain + "/savereqestbyvansale"),
            headers: {'Content-Type': 'application/json; charset=UTF-8'},
            body: jsonProduct,
          ).timeout(
            const Duration(seconds: 20),
          ); // Add a timeout for network requests

      if (response.statusCode == 200) {
        print(
          'Server Response: ${response.body}',
        ); // Debugging: print server response
        final responseData = json.decode(response.body);
        if (responseData['status'] == 'complete') {
          // Assuming your API returns a status
          await _clearDraftAndNavigate(
            context,
            'ບັນທຶກສຳເລັດ',
            responseData['message'] ?? "ບັນທຶກໃບຂໍໂອນສິນຄ້າເຂົ້າລົດສຳເລັດແລ້ວ!",
          );
        } else {
          if (mounted) {
            normalDialog(
              context,
              'ເກີດຂໍ້ຜິດພາດ',
              responseData['message'] ??
                  "ບໍ່ສາມາດບັນທຶກໃບຂໍໂອນສິນຄ້າໄດ້. ກະລຸນາລອງໃໝ່.",
            );
          }
        }
      } else {
        print("HTTP Error: ${response.statusCode}, Body: ${response.body}");
        if (mounted) {
          normalDialog(
            context,
            'ຂໍ້ຜິດພາດການເຊື່ອມຕໍ່',
            "ບໍ່ສາມາດຕິດຕໍ່ເຊີບເວີໄດ້, ກະລຸນາລອງໃໝ່.\nລະຫັດຂໍ້ຜິດພາດ: ${response.statusCode}",
          );
        }
      }
    } catch (e) {
      print("Exception during save: $e");
      if (mounted) {
        normalDialog(context, 'ຂໍ້ຜິດພາດ', "ເກີດຂໍ້ຜິດພາດ: $e");
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false; // Stop loading
        });
      }
    }
  }

  Future<void> _clearDraftAndNavigate(
    BuildContext context,
    String title,
    String message,
  ) async {
    await SQLHelper.deleteRespro(); // Clear local draft
    if (mounted) {
      normalDialog(context, title, message); // Show success message
      // Pop multiple times to go back to the main request list or home screen
      // Assuming 3 pops takes you back to RequestPage, then one more to its parent
      Navigator.of(
        context,
      ).popUntil((route) => route.isFirst); // Go back to the first route
    }
  }
}
