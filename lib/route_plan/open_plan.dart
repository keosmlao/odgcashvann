import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../utility/my_constant.dart';
import 'car_driver.dart';
import 'driver.dart';

class StartPlanPage extends StatefulWidget {
  final String doc_no;

  const StartPlanPage({Key? key, required this.doc_no}) : super(key: key);

  @override
  _StartPlanPageState createState() => _StartPlanPageState();
}

class _StartPlanPageState extends State<StartPlanPage> {
  String? car_code, driver_code, route_plan_id;
  TextEditingController carNameController = TextEditingController();
  TextEditingController driverNameController = TextEditingController();
  TextEditingController kipAmountController = TextEditingController(text: '0');
  TextEditingController bahtAmountController = TextEditingController(text: '0');

  DateTime now = DateTime.now();
  bool isLoading = false;

  // Define consistent colors for the theme
  final Color _primaryColor = Colors.deepPurple; // Changed to Deep Purple
  final Color _accentColor = Colors.deepPurpleAccent;
  final Color _backgroundColor = Colors.deepPurple.shade50;
  final Color _cardColor = Colors.white;
  final Color _textColor = Colors.grey.shade800;
  final Color _hintColor = Colors.grey.shade500;
  final Color _buttonColor = Colors.green.shade600; // Stronger green for action

  @override
  void initState() {
    super.initState();
    findUser();
    kipAmountController.addListener(_formatKipAmount);
    bahtAmountController.addListener(_formatBahtAmount);
  }

  @override
  void dispose() {
    carNameController.dispose();
    driverNameController.dispose();
    kipAmountController.dispose();
    bahtAmountController.dispose();
    super.dispose();
  }

  void findUser() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    setState(() {
      route_plan_id = preferences.getString('route_id') ?? '';
    });
  }

  Future<void> openPlan() async {
    setState(() {
      isLoading = true;
    });

    String formattedDate = DateFormat('yyyy-MM-dd HH:mm').format(now);
    String jsonProduct = json.encode({
      'doc_no': widget.doc_no,
      'plan_start': formattedDate,
      'driver': driver_code,
      'car': car_code,
      'kip_amount': kipAmountController.text.replaceAll(',', ''),
      'baht_amounnt': bahtAmountController.text.replaceAll(',', ''),
    });

    try {
      var response = await http.post(
        Uri.parse('${MyConstant().domain}/start_plan'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonProduct,
      );

      if (response.statusCode == 200) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('route_id', widget.doc_no);

        _showAlertDialog(
          title: "ສຳເລັດ",
          content: "ແຜນໄດ້ຖືກເປີດດຳເນີນການແລ້ວ.",
          isError: false,
          onOkPressed: () {
            Navigator.pop(context); // Pop current dialog
            // Navigator.pop(context); // Pop StartPlanPage
          },
        );
      } else {
        final errorBody = jsonDecode(response.body);
        final errorMessage =
            errorBody['message'] ?? 'ເກີດຂໍ້ຜິດພາດ: ບໍ່ສາມາດເລີ່ມແຜນໄດ້.';
        throw Exception(errorMessage);
      }
    } catch (e) {
      _showAlertDialog(
        title: 'ຂໍ້ຜິດພາດ',
        content:
            'ບໍ່ສາມາດເລີ່ມແຜນໄດ້: ${e.toString().contains("Exception:") ? e.toString().replaceFirst("Exception: ", "") : e.toString()}. ກະລຸນາລອງໃໝ່ອີກຄັ້ງ.',
        isError: true,
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _formatKipAmount() {
    _formatCurrencyInput(kipAmountController);
  }

  void _formatBahtAmount() {
    _formatCurrencyInput(bahtAmountController);
  }

  void _formatCurrencyInput(TextEditingController controller) {
    String text = controller.text.replaceAll(',', '');
    if (text.isEmpty) {
      return;
    }
    try {
      final value = int.parse(text);
      final formattedValue = NumberFormat('#,##0').format(value);
      if (controller.text != formattedValue) {
        controller.value = controller.value.copyWith(
          text: formattedValue,
          selection: TextSelection.collapsed(offset: formattedValue.length),
        );
      }
    } catch (e) {
      controller.value = controller.value.copyWith(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: const Text(
          "ເປີດແຜນການເດີນລົດ",
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'NotoSansLao',
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: _primaryColor,
        centerTitle: true,
        elevation: 4, // Added a slight elevation for depth
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: _primaryColor))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- Header with Date/Time ---
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 15,
                      horizontal: 20,
                    ),
                    decoration: BoxDecoration(
                      color: _primaryColor,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: _primaryColor.withOpacity(0.3),
                          spreadRadius: 2,
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "ເອກະສານເລກທີ: ${widget.doc_no}",
                          style: const TextStyle(
                            fontFamily: 'NotoSansLao',
                            fontSize: 16,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          DateFormat('ວັນທີ dd/MM/yyyy ເວລາ HH:mm').format(now),
                          style: const TextStyle(
                            fontFamily: 'NotoSansLao',
                            fontSize: 18,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // --- Selection Card: Driver ---
                  _buildSectionCard(
                    title: "ຂໍ້ມູນຄົນຂັບ",
                    children: [
                      _buildSelectionField(
                        label: "ເລືອກຄົນຂັບລົດ",
                        controller: driverNameController,
                        icon: Icons.person_outline,
                        onPressed: () async {
                          final result = await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) {
                                return const Driver();
                              },
                            ),
                          );
                          if (result != null) {
                            setState(() {
                              driverNameController.text = result['name_1'];
                              driver_code = result['code'];
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),

                  // --- Selection Card: Car ---
                  _buildSectionCard(
                    title: "ຂໍ້ມູນລົດ",
                    children: [
                      _buildSelectionField(
                        label: "ເລືອກລົດ",
                        controller: carNameController,
                        icon: Icons.directions_car_outlined,
                        onPressed: () async {
                          final result = await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) {
                                return const CarDriver();
                              },
                            ),
                          );
                          if (result != null) {
                            setState(() {
                              carNameController.text = result['name_1'];
                              car_code = result['code'];
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),

                  // --- Initial Cash Card ---
                  _buildSectionCard(
                    title: "ຈໍານວນເງິນຕັ້ງຕົ້ນ (ໃນລົດ)",
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildAmountInput(
                              "ກີບ",
                              kipAmountController,
                              '₭',
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: _buildAmountInput(
                              "ບາດ",
                              bahtAmountController,
                              '฿',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),

                  // --- Start Plan Button ---
                  SizedBox(
                    height: 55,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (route_plan_id == null || route_plan_id!.isEmpty) {
                          openPlan();
                        } else {
                          _showAlertDialog(
                            title: "ຄຳເຕືອນ",
                            content:
                                "ມີແຜນກຳລັງດຳເນີນການຢູ່ແລ້ວ. ກະລຸນາປິດແຜນເກົ່າກ່ອນເລີ່ມແຜນໃໝ່.",
                            isError: true,
                          );
                        }
                      },
                      icon: const Icon(
                        Icons.play_circle_fill_outlined,
                        size: 28,
                        color: Colors.white,
                      ),
                      label: const Text(
                        "ເລີ່ມແຜນ",
                        style: TextStyle(
                          fontFamily: 'NotoSansLao',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _buttonColor, // Use distinct button color
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 8, // More prominent shadow for action button
                        shadowColor: _buttonColor.withOpacity(0.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // --- Reusable Section Card Widget ---
  Widget _buildSectionCard({
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      color: _cardColor,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontFamily: 'NotoSansLao',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _primaryColor,
              ),
            ),
            const Divider(height: 25, thickness: 1, color: Colors.grey),
            ...children, // Spread the children widgets
          ],
        ),
      ),
    );
  }

  // --- Reusable Selection Input Field ---
  Widget _buildSelectionField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
        decoration: BoxDecoration(
          color: _backgroundColor.withOpacity(
            0.5,
          ), // Slightly lighter background for the field
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(icon, size: 24, color: _accentColor),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'NotoSansLao',
                      fontSize: 13,
                      color: _hintColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    controller.text.isEmpty ? 'ກົດເລືອກ' : controller.text,
                    style: TextStyle(
                      fontFamily: 'NotoSansLao',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _textColor,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 18, color: _hintColor),
          ],
        ),
      ),
    );
  }

  // --- Reusable Amount Input Field ---
  Widget _buildAmountInput(
    String label,
    TextEditingController controller,
    String currencySymbol,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'NotoSansLao',
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: _textColor,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          textAlign: TextAlign.start,
          style: TextStyle(
            fontFamily: 'NotoSansLao',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: _textColor,
          ),
          decoration: InputDecoration(
            hintText: '0',
            hintStyle: TextStyle(fontFamily: 'NotoSansLao', color: _hintColor),
            suffixText: currencySymbol,
            suffixStyle: TextStyle(
              fontFamily: 'NotoSansLao',
              color: _textColor,
              fontWeight: FontWeight.bold,
            ),
            filled: true,
            fillColor: _backgroundColor.withOpacity(
              0.5,
            ), // Lighter fill for input fields
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: BorderSide(color: Colors.grey.shade300, width: 1.0),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: BorderSide(
                color: _accentColor,
                width: 2.0,
              ), // Accent color on focus
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 15,
              vertical: 15,
            ),
          ),
        ),
      ],
    );
  }

  // --- Reusable Alert Dialog ---
  void _showAlertDialog({
    required String title,
    required String content,
    bool isError = false,
    VoidCallback? onOkPressed, // Optional callback for OK button
  }) {
    showCupertinoDialog(
      context: context,
      builder: (context) {
        return CupertinoAlertDialog(
          title: Text(
            title,
            style: TextStyle(
              fontFamily: 'NotoSansLao',
              fontWeight: FontWeight.bold,
              color: isError ? Colors.red : Colors.black,
            ),
          ),
          content: Text(
            content,
            style: const TextStyle(fontFamily: 'NotoSansLao'),
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () {
                Navigator.pop(context); // Always pop the dialog
                onOkPressed?.call(); // Call the optional callback if provided
              },
              child: Text(
                'ຕົກລົງ',
                style: TextStyle(
                  fontFamily: 'NotoSansLao',
                  color: isError ? Colors.red : _primaryColor,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
