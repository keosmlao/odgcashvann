import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For TextInputFormatter
import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:odgcashvan/Sale/comfirmdispatch.dart';
import 'package:odgcashvan/Sale/listorderbycust.dart';
import 'package:odgcashvan/utility/my_constant.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../database/sql_helper.dart'; // Ensure this path is correct

class HomePayment extends StatefulWidget {
  final String cust_code;
  final String total_amount; // Total amount due for the order
  const HomePayment({
    Key? key,
    required this.cust_code,
    required this.total_amount,
  }) : super(key: key);

  @override
  State<HomePayment> createState() => _HomePaymentState();
}

class _HomePaymentState extends State<HomePayment> {
  final TextEditingController _bahtAmountController = TextEditingController();
  final TextEditingController _kipAmountController = TextEditingController();
  final TextEditingController _kipInBahtEquivalentController =
      TextEditingController();

  double _exchangeRate = 0;
  double _remainingBahtAmount = 0;
  double _remainingKipAmount = 0;

  List<Map<String, dynamic>> _orderItems = [];
  String? _docNo;
  bool _isSaving = false;

  final NumberFormat _currencyFormatter = NumberFormat('#,##0.00');
  final NumberFormat _integerFormatter = NumberFormat('#,##0');

  // Define a more modern and consistent color palette
  final Color _primaryColor = const Color(0xFF007BFF); // A vibrant blue
  final Color _accentColor = const Color(
    0xFF0056B3,
  ); // A darker blue for accents
  final Color _backgroundColor = const Color(
    0xFFF8F9FA,
  ); // Light gray background
  final Color _cardColor = Colors.white;
  final Color _textColor = const Color(0xFF343A40); // Dark gray for text
  final Color _mutedTextColor = const Color(
    0xFF6C757D,
  ); // Lighter gray for hints/secondary text
  final Color _successColor = const Color(0xFF28A745); // Green for success
  final Color _errorColor = const Color(0xFFDC3545); // Red for errors
  final Color _borderColor = const Color(0xFFCED4DA); // Light gray for borders
  final Color _focusedBorderColor = const Color(
    0xFF007BFF,
  ); // Primary blue for focused borders

  @override
  void initState() {
    super.initState();
    _fetchExchangeRate();
    _bahtAmountController.text = _integerFormatter.format(0);
    _kipAmountController.text = _integerFormatter.format(0);
    _kipInBahtEquivalentController.text = _currencyFormatter.format(0.00);
  }

  @override
  void dispose() {
    _bahtAmountController.dispose();
    _kipAmountController.dispose();
    _kipInBahtEquivalentController.dispose();
    super.dispose();
  }

  // --- API Call: Fetch Exchange Rate ---
  Future<void> _fetchExchangeRate() async {
    try {
      final response = await get(
        Uri.parse("${MyConstant().domain}/exchang_rate"),
      );
      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        setState(() {
          _exchangeRate =
              double.tryParse(result['exange_rate']?.toString() ?? '0.0') ??
              0.0;
        });
        _calculateAmounts();
      } else {
        _showInfoSnackBar(
          'Failed to load exchange rate: ${response.statusCode}',
          _errorColor,
        );
      }
    } catch (e) {
      _showInfoSnackBar('Error fetching exchange rate: $e', _errorColor);
      print("Error fetching exchange rate: $e");
    }
  }

  // --- API Call: Get Document Number ---
  Future<void> _getDocNoAndSaveOrder() async {
    _showFullScreenLoading();
    try {
      final response = await get(
        Uri.parse("${MyConstant().domain}/getdoc_no/CAV"),
      );
      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        _docNo = result.toString();
        await _saveOrderToApi();
      } else {
        _showInfoSnackBar(
          'Failed to get document number: ${response.statusCode}',
          _errorColor,
        );
      }
    } catch (e) {
      _showInfoSnackBar('Error getting document number: $e', _errorColor);
      print("Error getting document number: $e");
    } finally {
      _hideFullScreenLoading();
    }
  }

  // --- API Call: Save Order ---
  Future<void> _saveOrderToApi() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    _orderItems = await SQLHelper.getOrdersbtcust(widget.cust_code);

    final String kipAmountClean = _kipAmountController.text.replaceAll(',', '');
    final String bahtAmountClean = _bahtAmountController.text.replaceAll(
      ',',
      '',
    );
    final String kipInBahtClean = _kipInBahtEquivalentController.text
        .replaceAll(',', '');

    final Map<String, dynamic> jsonProduct = {
      "doc_no": _docNo.toString(),
      "cust_code": widget.cust_code.toString(),
      "side_code": preferences.getString('side_code').toString(),
      "department_code": preferences.getString('department_code').toString(),
      "sale_code": preferences.getString('usercode').toString(),
      "total_amount": widget.total_amount,
      "kip_amount": kipAmountClean,
      "baht_amount": bahtAmountClean,
      "kip_in_baht": kipInBahtClean,
      "wh_code": preferences.getString('wh_code').toString(),
      "sh_code": preferences.getString('sh_code').toString(),
      "exchange_rate": _exchangeRate,
      "route_id": preferences.getString('route_id').toString(),
      "bill": _orderItems,
    };

    try {
      final response = await post(
        Uri.parse("${MyConstant().domain}/savevansaleCash"),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: json.encode(jsonProduct),
      );

      if (response.statusCode == 200) {
        await SQLHelper.deleteAlloder();
        _showInfoSnackBar('ບັນທຶກການຊຳລະສຳເລັດ', _successColor);

        Navigator.of(context).popUntil((route) => route.isFirst);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ListOrderbyCust(cust_code: widget.cust_code.toString()),
          ),
        );
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ConfirmDispatchScreen(doc_no: _docNo.toString()),
          ),
        );
      } else {
        _showInfoSnackBar(
          'Failed to save payment: ${response.statusCode}',
          _errorColor,
        );
        print("Failed to save order: ${response.statusCode}");
        print("Response body: ${response.body}");
      }
    } catch (e) {
      _showInfoSnackBar('Error saving payment: $e', _errorColor);
      print("Error saving payment: $e");
    }
  }

  // --- UI Logic: Calculation Handlers ---
  void _calculateAmounts() {
    double totalAmountDue = double.tryParse(widget.total_amount) ?? 0.0;
    double bahtPaid =
        double.tryParse(_bahtAmountController.text.replaceAll(',', '')) ?? 0.0;
    double kipPaid =
        double.tryParse(_kipAmountController.text.replaceAll(',', '')) ?? 0.0;

    double kipToBahtEquivalent = (_exchangeRate != 0)
        ? kipPaid / _exchangeRate
        : 0.0;

    _kipInBahtEquivalentController.text = _currencyFormatter.format(
      kipToBahtEquivalent,
    );

    double totalPaidInBaht = bahtPaid + kipToBahtEquivalent;
    double remainingBaht = totalAmountDue - totalPaidInBaht;

    setState(() {
      _remainingBahtAmount = remainingBaht;
      _remainingKipAmount = remainingBaht * _exchangeRate;
    });
  }

  void _onBahtAmountChanged(String text) {
    _bahtAmountController.text = text.isEmpty ? '' : _formatNumberInput(text);
    _bahtAmountController.selection = TextSelection.fromPosition(
      TextPosition(offset: _bahtAmountController.text.length),
    );
    _calculateAmounts();
  }

  void _onKipAmountChanged(String text) {
    _kipAmountController.text = text.isEmpty ? '' : _formatNumberInput(text);
    _kipAmountController.selection = TextSelection.fromPosition(
      TextPosition(offset: _kipAmountController.text.length),
    );
    _calculateAmounts();
  }

  // --- Utility: Number Formatting for Input Fields ---
  String _formatNumberInput(String value) {
    final cleanValue = value.replaceAll(',', '');
    if (cleanValue.isEmpty) return '';
    if (cleanValue.contains('.')) {
      final parts = cleanValue.split('.');
      String integerPart = parts[0];
      String decimalPart = parts.length > 1 ? parts[1] : '';
      return _integerFormatter.format(double.parse(integerPart)) +
          (decimalPart.isNotEmpty ? '.' + decimalPart : '');
    } else {
      final number = double.tryParse(cleanValue) ?? 0.0;
      return _integerFormatter.format(number);
    }
  }

  // --- UI Feedback: SnackBar & Loading Indicator ---
  void _showInfoSnackBar(String message, Color color) {
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

  void _showFullScreenLoading() {
    setState(() {
      _isSaving = true;
    });
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return PopScope(
          canPop: false,
          child: Center(child: CircularProgressIndicator(color: _primaryColor)),
        );
      },
    );
  }

  void _hideFullScreenLoading() {
    if (_isSaving) {
      Navigator.of(context, rootNavigator: true).pop();
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    double totalAmountDue = double.tryParse(widget.total_amount) ?? 0.0;
    bool isPaymentComplete = _remainingBahtAmount <= 0;
    bool hasOverpaid = _remainingBahtAmount < 0;

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: const Text(
          "ໜ້າຊຳລະເງິນ",
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'NotoSansLao',
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(8.0), // Further reduced overall padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- Total Amount Due Card ---
            Card(
              elevation: 3, // Reduced elevation
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ), // Slightly less rounded
              color: _primaryColor,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 12,
                ), // Further reduced padding
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      "ຍອດເງິນທີ່ຕ້ອງຊຳລະ",
                      style: TextStyle(
                        fontFamily: 'NotoSansLao',
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14, // Further reduced font size
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6), // Reduced spacing
                    Text(
                      _currencyFormatter.format(totalAmountDue),
                      style: const TextStyle(
                        fontFamily: 'NotoSansLao',
                        fontSize: 44, // Reduced from 48
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      "ບາດ",
                      style: TextStyle(
                        fontFamily: 'NotoSansLao',
                        fontSize: 18, // Reduced from 20
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16), // Reduced spacing
            // --- Exchange Rate Display ---
            Container(
              padding: const EdgeInsets.symmetric(
                vertical: 8,
                horizontal: 12,
              ), // Further reduced padding
              decoration: BoxDecoration(
                color: _cardColor,
                borderRadius: BorderRadius.circular(
                  10,
                ), // Slightly less rounded
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04), // Lighter shadow
                    spreadRadius: 1,
                    blurRadius: 2, // Less blur
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.currency_exchange,
                    color: _accentColor,
                    size: 22,
                  ), // Reduced icon size
                  const SizedBox(width: 6), // Reduced spacing
                  Text(
                    'ອັດຕາແລກປ່ຽນ: 1 ບາດ = ${_integerFormatter.format(_exchangeRate)} ກີບ',
                    style: TextStyle(
                      fontFamily: 'NotoSansLao',
                      fontSize: 15, // Further reduced font size
                      fontWeight: FontWeight.w600,
                      color: _textColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16), // Reduced spacing
            // --- Payment Input & Status Section ---
            Card(
              elevation: 3, // Reduced elevation
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ), // Slightly less rounded
              color: _cardColor,
              child: Padding(
                padding: const EdgeInsets.all(12.0), // Reduced padding
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Baht Input
                    _buildPaymentInputField(
                      label: 'ຈຳນວນເງິນສົດ (ບາດ)',
                      controller: _bahtAmountController,
                      onChanged: _onBahtAmountChanged,
                      hintText: '0',
                      icon: Icons.attach_money,
                      suffixText: 'ບາດ',
                    ),
                    const SizedBox(height: 18), // Reduced spacing
                    // Kip Input
                    _buildPaymentInputField(
                      label: 'ຈຳນວນເງິນສົດ (ກີບ)',
                      controller: _kipAmountController,
                      onChanged: _onKipAmountChanged,
                      hintText: '0',
                      icon: Icons.currency_lira,
                      suffixText: 'ກີບ',
                    ),
                    const SizedBox(height: 10), // Reduced spacing
                    // Kip Equivalent in Baht (Read-only)
                    _buildReadOnlyDisplayField(
                      label: 'ມູນຄ່າກີບທຽບເທົ່າບາດ',
                      controller: _kipInBahtEquivalentController,
                      suffixText: 'ບາດ',
                    ),
                    const SizedBox(height: 18), // Reduced spacing
                    // Remaining/Change Display Card
                    Container(
                      padding: const EdgeInsets.all(14), // Reduced padding
                      decoration: BoxDecoration(
                        color: isPaymentComplete
                            ? (hasOverpaid ? _successColor : _primaryColor)
                            : _errorColor,
                        borderRadius: BorderRadius.circular(
                          10,
                        ), // Slightly less rounded
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(
                              0.08,
                            ), // Lighter shadow
                            spreadRadius: 1,
                            blurRadius: 3,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            isPaymentComplete
                                ? (hasOverpaid ? "ເງິນທອນ" : "ຊຳລະຄົບຖ້ວນແລ້ວ")
                                : "ຍອດເງິນທີ່ຕ້ອງຊຳລະຄົງເຫຼືອ",
                            style: TextStyle(
                              fontFamily: 'NotoSansLao',
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 15, // Further reduced font size
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 6), // Reduced spacing
                          Text(
                            _currencyFormatter.format(
                              _remainingBahtAmount.abs(),
                            ),
                            style: const TextStyle(
                              fontFamily: 'NotoSansLao',
                              fontSize: 36, // Reduced from 40
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          Text(
                            'ບາດ / ${_integerFormatter.format(_remainingKipAmount.abs())} ກີບ',
                            style: TextStyle(
                              fontFamily: 'NotoSansLao',
                              fontSize: 16, // Reduced from 18
                              color: Colors.white.withOpacity(0.9),
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20), // Reduced spacing
            // --- Save Button ---
            SizedBox(
              width: double.infinity,
              height: 50, // Reduced from 55
              child: ElevatedButton.icon(
                onPressed: isPaymentComplete ? _getDocNoAndSaveOrder : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isPaymentComplete
                      ? _primaryColor
                      : Colors.grey.shade400,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      10,
                    ), // Slightly less rounded
                  ),
                  elevation: 4, // Reduced shadow
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                  ), // Reduced padding
                ),
                icon: const Icon(
                  Icons.receipt_long,
                  size: 26,
                ), // Reduced icon size
                label: Text(
                  isPaymentComplete ? "ບັນທຶກການຊຳລະ" : "ກະລຸນາຊຳລະໃຫ້ຄົບຖ້ວນ",
                  style: const TextStyle(
                    fontFamily: 'NotoSansLao',
                    fontSize: 16, // Reduced font size
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

  // --- Helper Widgets ---

  Widget _buildPaymentInputField({
    required String label,
    required TextEditingController controller,
    required ValueChanged<String> onChanged,
    required String hintText,
    required IconData icon,
    String? suffixText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'NotoSansLao',
            fontSize: 14, // Reduced font size
            fontWeight: FontWeight.w600,
            color: _textColor,
          ),
        ),
        const SizedBox(height: 6), // Reduced spacing
        TextField(
          controller: controller,
          onChanged: onChanged,
          textAlign: TextAlign.right,
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
            _thousandSeparatorFormatter(),
          ],
          style: TextStyle(
            fontSize: 24, // Reduced from 26
            fontWeight: FontWeight.bold,
            color: _textColor,
            fontFamily: 'NotoSansLao',
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(
              fontFamily: 'NotoSansLao',
              color: _mutedTextColor.withOpacity(0.6),
              fontSize: 24, // Reduced from 26
            ),
            filled: true,
            fillColor: _backgroundColor,
            prefixIcon: Icon(
              icon,
              color: _accentColor,
              size: 24,
            ), // Reduced icon size
            suffixText: suffixText,
            suffixStyle: TextStyle(
              fontFamily: 'NotoSansLao',
              fontSize: 16, // Reduced from 18
              color: _mutedTextColor,
              fontWeight: FontWeight.w600,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8), // Slightly less rounded
              borderSide: BorderSide(
                color: _borderColor,
                width: 1.0,
              ), // Thinner border
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: _borderColor, width: 1.0),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: _focusedBorderColor,
                width: 2.0,
              ), // Thinner focused border
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ), // Further reduced padding
            suffixIcon:
                controller.text.isNotEmpty &&
                    (double.tryParse(controller.text.replaceAll(',', '')) ??
                            0) >
                        0
                ? IconButton(
                    icon: Icon(
                      Icons.clear,
                      size: 18,
                      color: _mutedTextColor,
                    ), // Reduced icon size
                    onPressed: () {
                      controller.text = _integerFormatter.format(0);
                      onChanged('0');
                    },
                  )
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildReadOnlyDisplayField({
    required String label,
    required TextEditingController controller,
    String? suffixText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'NotoSansLao',
            fontSize: 14, // Reduced font size
            fontWeight: FontWeight.w600,
            color: _textColor,
          ),
        ),
        const SizedBox(height: 6), // Reduced spacing
        TextField(
          controller: controller,
          readOnly: true,
          textAlign: TextAlign.right,
          style: TextStyle(
            fontSize: 24, // Reduced from 26
            fontWeight: FontWeight.bold,
            color: _textColor,
            fontFamily: 'NotoSansLao',
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: _backgroundColor,
            suffixText: suffixText,
            suffixStyle: TextStyle(
              fontFamily: 'NotoSansLao',
              fontSize: 16, // Reduced from 18
              color: _mutedTextColor,
              fontWeight: FontWeight.w600,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8), // Slightly less rounded
              borderSide: BorderSide(color: _borderColor, width: 1.0),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: _borderColor, width: 1.0),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: _focusedBorderColor, width: 2.0),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ), // Further reduced padding
          ),
        ),
      ],
    );
  }

  TextInputFormatter _thousandSeparatorFormatter() {
    return TextInputFormatter.withFunction((oldValue, newValue) {
      final String newText = newValue.text;
      final String cleanedText = newText.replaceAll(RegExp(r'[^\d.]'), '');

      if (cleanedText.isEmpty) {
        return TextEditingValue();
      }

      final List<String> parts = cleanedText.split('.');
      String integerPart = parts[0];
      String decimalPart = parts.length > 1 ? '.' + parts[1] : '';

      final String formattedIntegerPart = NumberFormat(
        '#,###',
      ).format(double.tryParse(integerPart) ?? 0.0);

      final String finalFormattedText = formattedIntegerPart + decimalPart;

      return TextEditingValue(
        text: finalFormattedText,
        selection: TextSelection.collapsed(
          offset:
              finalFormattedText.length -
              (newValue.text.length - newValue.selection.end),
        ),
      );
    });
  }
}
