import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';
// import 'package:odgcashvan/utility/my_style.dart'; // No longer used directly for colors
import 'package:shared_preferences/shared_preferences.dart';

import '../utility/my_constant.dart';

class Close_rout_plan extends StatefulWidget {
  final String doc_no;
  const Close_rout_plan({super.key, required this.doc_no});

  @override
  State<Close_rout_plan> createState() => _Close_rout_planState();
}

class _Close_rout_planState extends State<Close_rout_plan> {
  String? route_plan_id;
  TextEditingController _initialKipController =
      TextEditingController(); // Initial cash brought
  TextEditingController _initialBahtController = TextEditingController();
  TextEditingController _salesKipController =
      TextEditingController(); // Sales collected
  TextEditingController _salesBahtController = TextEditingController();
  TextEditingController _totalKipController =
      TextEditingController(); // Initial + Sales
  TextEditingController _totalBahtController = TextEditingController();

  DateTime now = DateTime.now();
  bool _isLoading = false;

  // Define consistent colors for the theme
  final Color _primaryColor = Colors.blue.shade700; // AppBar and key elements
  final Color _accentColor = Colors.blue.shade500; // For minor highlights
  final Color _backgroundColor = Colors.blue.shade50; // Overall background
  final Color _cardColor = Colors.white; // Card backgrounds
  final Color _textColorPrimary = Colors.grey.shade800; // Main text
  final Color _textColorSecondary =
      Colors.grey.shade600; // Labels and less important text
  final Color _incomeColor = Colors.green.shade700; // Green for total income
  final Color _initialCashColor =
      Colors.deepOrange.shade600; // Orange for initial cash
  final Color _salesCashColor = Colors.purple.shade600; // Purple for sales cash

  // Formatter for currency display
  final NumberFormat _currencyFormatter = NumberFormat('#,##0');

  @override
  void initState() {
    super.initState();
    findUser();
    _fetchPlanData(); // Renamed showdata() to _fetchPlanData()
  }

  void findUser() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    setState(() {
      route_plan_id = preferences.getString(
        'route_id',
      ); // No .toString() needed if already String
    });
  }

  Future<void> _fetchPlanData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await get(
        Uri.parse('${MyConstant().domain}/getplanstillstart/${widget.doc_no}'),
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        setState(() {
          _initialKipController.text = _currencyFormatter.format(
            double.tryParse(result['kip_for_charge'] ?? '0.0') ?? 0.0,
          );
          _initialBahtController.text = _currencyFormatter.format(
            double.tryParse(result['baht_for_charge'] ?? '0.0') ?? 0.0,
          );
          _salesKipController.text = _currencyFormatter.format(
            double.tryParse(result['sale_kip'] ?? '0.0') ?? 0.0,
          );
          _salesBahtController.text = _currencyFormatter.format(
            double.tryParse(result['sale_baht'] ?? '0.0') ?? 0.0,
          );

          double totalKip =
              (double.tryParse(result['kip_for_charge'] ?? '0.0') ?? 0.0) +
              (double.tryParse(result['sale_kip'] ?? '00.0') ?? 0.0);
          double totalBaht =
              (double.tryParse(result['baht_for_charge'] ?? '0.0') ?? 0.0) +
              (double.tryParse(result['sale_baht'] ?? '0.0') ?? 0.0);

          _totalKipController.text = _currencyFormatter.format(totalKip);
          _totalBahtController.text = _currencyFormatter.format(totalBaht);
        });
      } else {
        _showAlertDialog(
          title: "ຂໍ້ຜິດພາດ",
          content: "ບໍ່ສາມາດໂຫຼດຂໍ້ມູນແຜນໄດ້. ລະຫັດ: ${response.statusCode}",
          isError: true,
        );
      }
    } catch (e) {
      _showAlertDialog(
        title: "ຂໍ້ຜິດພາດ",
        content: "ເກີດຂໍ້ຜິດພາດໃນການໂຫຼດຂໍ້ມູນ: $e",
        isError: true,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _finishPlan() async {
    setState(() {
      _isLoading = true;
    });

    SharedPreferences preferences = await SharedPreferences.getInstance();
    String formattedDate = DateFormat('yyyy-MM-dd HH:mm').format(now);

    // Clean and parse values for sending to API
    String returnKip = _initialKipController.text.replaceAll(',', '');
    String returnBaht = _initialBahtController.text.replaceAll(',', '');
    String saleKip = _salesKipController.text.replaceAll(',', '');
    String saleBaht = _salesBahtController.text.replaceAll(',', '');

    String jsonBody = json.encode({
      'route_id': widget.doc_no,
      'sale_code': preferences.getString('usercode'),
      'fishis_plan': formattedDate,
      'return_chage_kip': returnKip.isEmpty ? '0' : returnKip,
      'return_chage_baht': returnBaht.isEmpty ? '0' : returnBaht,
      'sale_kip': saleKip.isEmpty ? '0' : saleKip,
      'sale_baht': saleBaht.isEmpty ? '0' : saleBaht,
    });

    try {
      final response = await post(
        Uri.parse("${MyConstant().domain}/finish_plan"),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonBody,
      );

      final resBody = json.decode(response.body);

      if (response.statusCode == 200 && resBody['status'] == 'complete') {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          'route_id',
          '',
        ); // Clear route_id after successful close

        _showAlertDialog(
          title: "ສຳເລັດ",
          content: "ແຜນຖືກປິດສຳເລັດແລ້ວ.",
          isError: false,
          onOkPressed: () {
            Navigator.pop(context); // Pop Close_rout_plan page
          },
        );
      } else {
        String errorMessage =
            resBody['message'] ?? 'ມີການເຄື່ອນໄຫວທີ່ບໍ່ສຳເລັດ.';
        _showAlertDialog(
          title: "ຄຳເຕືອນ",
          content: errorMessage,
          isError: true,
        );
      }
    } catch (e) {
      _showAlertDialog(
        title: "ຂໍ້ຜິດພາດ",
        content: "ເກີດຂໍ້ຜິດພາດໃນການປິດແຜນ: $e",
        isError: true,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Reusable Alert Dialog
  void _showAlertDialog({
    required String title,
    required String content,
    bool isError = false,
    VoidCallback? onOkPressed,
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
                Navigator.pop(context);
                onOkPressed?.call();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: const Text(
          "ປິດແຜນການເດີນລົດ",
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'NotoSansLao',
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: _primaryColor,
        centerTitle: true,
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: _primaryColor))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- Header with Plan ID and Date/Time ---
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
                          "ແຜນເລກທີ: ${widget.doc_no}",
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

                  // --- Initial Cash / Return Cash Section ---
                  _buildSummaryCard(
                    title: "ເງິນຕັ້ງຕົ້ນ (ເງິນທອນ)",
                    color: _initialCashColor, // Distinct color for initial cash
                    icon: Icons.attach_money_outlined,
                    children: [
                      _buildAmountDisplayField(
                        label: 'ເງິນກີບ',
                        controller: _initialKipController,
                        currencySymbol: '₭',
                      ),
                      const SizedBox(height: 15),
                      _buildAmountDisplayField(
                        label: 'ເງິນບາດ',
                        controller: _initialBahtController,
                        currencySymbol: '฿',
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),

                  // --- Sales Cash Section ---
                  _buildSummaryCard(
                    title: "ເງິນສົດຈາກການຂາຍ",
                    color: _salesCashColor, // Distinct color for sales
                    icon: Icons.shopping_bag_outlined,
                    children: [
                      _buildAmountDisplayField(
                        label: 'ເງິນກີບ',
                        controller: _salesKipController,
                        currencySymbol: '₭',
                      ),
                      const SizedBox(height: 15),
                      _buildAmountDisplayField(
                        label: 'ເງິນບາດ',
                        controller: _salesBahtController,
                        currencySymbol: '฿',
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),

                  // --- Total Cash Section ---
                  _buildSummaryCard(
                    title: "ລວມເງິນສົດທັງໝົດ",
                    color: _incomeColor, // Green for total income
                    icon: Icons.account_balance_wallet_outlined,
                    children: [
                      _buildAmountDisplayField(
                        label: 'ເງິນກີບ',
                        controller: _totalKipController,
                        currencySymbol: '₭',
                      ),
                      const SizedBox(height: 15),
                      _buildAmountDisplayField(
                        label: 'ເງິນບາດ',
                        controller: _totalBahtController,
                        currencySymbol: '฿',
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),

                  // --- Close Plan Button ---
                  SizedBox(
                    height: 55,
                    child: ElevatedButton.icon(
                      onPressed: _finishPlan, // Call the close plan function
                      icon: const Icon(
                        Icons.close,
                        size: 28,
                        color: Colors.white,
                      ),
                      label: const Text(
                        "ປິດແຜນການເດີນລົດ",
                        style: TextStyle(
                          fontFamily: 'NotoSansLao',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _primaryColor, // Use primary color for button
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 8, // Prominent shadow for action button
                        shadowColor: _primaryColor.withOpacity(0.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // --- Reusable Summary Card Widget ---
  Widget _buildSummaryCard({
    required String title,
    required Color color,
    required IconData icon,
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
            Row(
              children: [
                Icon(
                  icon,
                  size: 28,
                  color: color,
                ), // Icon related to the section
                const SizedBox(width: 10),
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'NotoSansLao',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color, // Title color matches the section theme
                  ),
                ),
              ],
            ),
            const Divider(height: 25, thickness: 1, color: Colors.grey),
            ...children, // Spread the children widgets (amount fields)
          ],
        ),
      ),
    );
  }

  // --- Reusable Amount Display Field (read-only TextField) ---
  Widget _buildAmountDisplayField({
    required String label,
    required TextEditingController controller,
    required String currencySymbol,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'NotoSansLao',
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: _textColorSecondary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          readOnly: true, // Make it read-only
          textAlign: TextAlign.end, // Align text to the right for numbers
          style: TextStyle(
            fontFamily: 'NotoSansLao',
            fontSize: 24, // Larger font for amounts
            fontWeight: FontWeight.bold,
            color: _textColorPrimary,
          ),
          decoration: InputDecoration(
            suffixText: currencySymbol, // Currency symbol at the end
            suffixStyle: TextStyle(
              fontFamily: 'NotoSansLao',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _textColorPrimary,
            ),
            filled: true,
            fillColor: _backgroundColor.withOpacity(0.4), // Light fill
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: BorderSide.none, // No border for cleaner look
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: BorderSide(color: Colors.grey.shade300, width: 1.0),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: BorderSide(color: _accentColor, width: 2.0),
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
}
