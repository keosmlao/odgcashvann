import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:odgcashvan/Sale/comfirmdispatch.dart';
import 'package:odgcashvan/Sale/listorderbycust.dart';
import 'package:odgcashvan/utility/my_constant.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../database/sql_helper.dart';

class HomePayment extends StatefulWidget {
  final String cust_code;
  final String total_amount;

  const HomePayment({
    Key? key,
    required this.cust_code,
    required this.total_amount,
  }) : super(key: key);

  @override
  State<HomePayment> createState() => _HomePaymentState();
}

class _HomePaymentState extends State<HomePayment>
    with TickerProviderStateMixin {
  final TextEditingController _bahtAmountController = TextEditingController();
  final TextEditingController _kipAmountController = TextEditingController();
  final TextEditingController _kipInBahtEquivalentController =
      TextEditingController();

  late AnimationController _fadeAnimationController;
  late AnimationController _slideAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  double _exchangeRate = 0;
  double _remainingBahtAmount = 0;
  double _remainingKipAmount = 0;
  List<Map<String, dynamic>> _orderItems = [];
  String? _docNo;
  bool _isSaving = false;
  bool _isLoading = false;

  final NumberFormat _currencyFormatter = NumberFormat('#,##0.00');
  final NumberFormat _integerFormatter = NumberFormat('#,##0');

  // Modern color scheme
  final Color _primaryColor = const Color(0xFF6366F1); // Indigo
  final Color _secondaryColor = const Color(0xFF10B981); // Emerald
  final Color _accentColor = const Color(0xFFF59E0B); // Amber
  final Color _errorColor = const Color(0xFFEF4444); // Red
  final Color _backgroundColor = const Color(0xFFF8FAFC); // Slate 50
  final Color _cardColor = Colors.white;
  final Color _textPrimary = const Color(0xFF1E293B); // Slate 800
  final Color _textSecondary = const Color(0xFF64748B); // Slate 500
  final Color _borderColor = const Color(0xFFE2E8F0); // Slate 200

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _fetchExchangeRate();
    _initializeControllers();
  }

  void _setupAnimations() {
    _fadeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _slideAnimationController,
            curve: Curves.easeOutCubic,
          ),
        );
  }

  void _initializeControllers() {
    _bahtAmountController.text = '0';
    _kipAmountController.text = '0';
    _kipInBahtEquivalentController.text = '0.00';

    _bahtAmountController.addListener(
      () => _onBahtAmountChanged(_bahtAmountController.text),
    );
    _kipAmountController.addListener(
      () => _onKipAmountChanged(_kipAmountController.text),
    );
  }

  @override
  void dispose() {
    _fadeAnimationController.dispose();
    _slideAnimationController.dispose();
    _bahtAmountController.dispose();
    _kipAmountController.dispose();
    _kipInBahtEquivalentController.dispose();
    super.dispose();
  }

  Future<void> _fetchExchangeRate() async {
    setState(() => _isLoading = true);
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
        _fadeAnimationController.forward();
        _slideAnimationController.forward();
      } else {
        _showSnackBar(
          'Failed to load exchange rate: ${response.statusCode}',
          _errorColor,
        );
      }
    } catch (e) {
      _showSnackBar('Error fetching exchange rate: $e', _errorColor);
    } finally {
      setState(() => _isLoading = false);
    }
  }

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
        _showSnackBar(
          'Failed to get document number: ${response.statusCode}',
          _errorColor,
        );
      }
    } catch (e) {
      _showSnackBar('Error getting document number: $e', _errorColor);
    } finally {
      _hideFullScreenLoading();
    }
  }

  Future<void> _saveOrderToApi() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    _orderItems = await SQLHelper.getOrdersbtcust(widget.cust_code);

    final double kipAmountValue =
        double.tryParse(_kipAmountController.text.replaceAll(',', '')) ?? 0.0;
    final double bahtAmountValue =
        double.tryParse(_bahtAmountController.text.replaceAll(',', '')) ?? 0.0;
    final double kipInBahtEquivalentValue =
        double.tryParse(
          _kipInBahtEquivalentController.text.replaceAll(',', ''),
        ) ??
        0.0;

    final Map<String, dynamic> jsonProduct = {
      "doc_no": _docNo.toString(),
      "cust_code": widget.cust_code.toString(),
      "side_code": preferences.getString('side_code').toString(),
      "department_code": preferences.getString('department_code').toString(),
      "sale_code": preferences.getString('usercode').toString(),
      "total_amount": widget.total_amount,
      "kip_amount": kipAmountValue.toString(),
      "baht_amount": bahtAmountValue.toString(),
      "kip_in_baht": kipInBahtEquivalentValue.toString(),
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
        _showSnackBar('ບັນທຶກການຊຳລະສຳເລັດ', _secondaryColor);

        Navigator.of(context).popUntil((route) => route.isFirst);
        Navigator.pushReplacement(
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
        _showSnackBar(
          'Failed to save payment: ${response.statusCode}',
          _errorColor,
        );
      }
    } catch (e) {
      _showSnackBar('Error saving payment: $e', _errorColor);
    }
  }

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
    final String formattedText = text.isEmpty ? '0' : _formatNumberInput(text);
    if (_bahtAmountController.text != formattedText) {
      _bahtAmountController.value = TextEditingValue(
        text: formattedText,
        selection: TextSelection.collapsed(offset: formattedText.length),
      );
    }
    _calculateAmounts();
  }

  void _onKipAmountChanged(String text) {
    final String formattedText = text.isEmpty ? '0' : _formatNumberInput(text);
    if (_kipAmountController.text != formattedText) {
      _kipAmountController.value = TextEditingValue(
        text: formattedText,
        selection: TextSelection.collapsed(offset: formattedText.length),
      );
    }
    _calculateAmounts();
  }

  String _formatNumberInput(String value) {
    final cleanValue = value.replaceAll(',', '');
    if (cleanValue.isEmpty) return '0';
    if (cleanValue == '.') return '0.';

    if (double.tryParse(cleanValue) == null && !cleanValue.endsWith('.')) {
      return value;
    }

    if (cleanValue.contains('.')) {
      final parts = cleanValue.split('.');
      String integerPart = parts[0];
      String decimalPart = parts.length > 1 ? parts[1] : '';

      String formattedIntegerPart = NumberFormat(
        '#,##0',
      ).format(double.parse(integerPart));
      return formattedIntegerPart +
          (decimalPart.isNotEmpty ? '.' + decimalPart : '');
    } else {
      final number = double.tryParse(cleanValue) ?? 0.0;
      return NumberFormat('#,##0').format(number);
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
              fontWeight: FontWeight.w500,
            ),
          ),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  void _showFullScreenLoading() {
    setState(() => _isSaving = true);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: Container(
          color: Colors.black54,
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: _cardColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    color: _primaryColor,
                    strokeWidth: 3,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "ກຳລັງດຳເນີນການ...",
                    style: TextStyle(
                      fontFamily: 'NotoSansLao',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Payment Suggestion Box
                  if (_remainingBahtAmount > 0) ...[
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _accentColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: _accentColor.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.lightbulb_outline,
                            color: _accentColor,
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'ແນະນຳການຊຳລະ:',
                                  style: TextStyle(
                                    fontFamily: 'NotoSansLao',
                                    fontSize: 9,
                                    color: _accentColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  'ຈ່າຍກີບ: ${_integerFormatter.format(_remainingKipAmount)} ກີບ',
                                  style: TextStyle(
                                    fontFamily: 'NotoSansLao',
                                    fontSize: 9,
                                    color: _textPrimary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Quick fill button for Kip
                          GestureDetector(
                            onTap: () {
                              _kipAmountController.text = _integerFormatter
                                  .format(_remainingKipAmount);
                              _onKipAmountChanged(_kipAmountController.text);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _accentColor,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'ໃຊ້',
                                style: TextStyle(
                                  fontFamily: 'NotoSansLao',
                                  fontSize: 8,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _hideFullScreenLoading() {
    if (_isSaving) {
      Navigator.of(context, rootNavigator: true).pop();
      setState(() => _isSaving = false);
    }
  }

  // NEW METHOD: Build Kip Equivalent Calculator Section
  Widget _buildKipEquivalentCalculator() {
    double totalAmountDue = double.tryParse(widget.total_amount) ?? 0.0;
    double equivalentKipForTotal = totalAmountDue * _exchangeRate;

    // Calculate equivalent Kip for remaining amount
    double remainingAmountPositive = _remainingBahtAmount > 0
        ? _remainingBahtAmount
        : 0;
    double equivalentKipForRemaining = remainingAmountPositive * _exchangeRate;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _secondaryColor.withOpacity(0.1),
            _secondaryColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _secondaryColor.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: _secondaryColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _secondaryColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.calculate_outlined,
                  color: _secondaryColor,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'ການຄຳນວນຍອດເງິນ ແລະ ຕົວເລືອກຊຳລະໄວ',
                  style: TextStyle(
                    fontFamily: 'NotoSansLao',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _textPrimary,
                  ),
                ),
              ),
              // Info icon with tooltip
              Tooltip(
                message:
                    'ຍອດເງິນທີ່ຄິດໄລ່ຈາກອັດຕາແລກປ່ຽນປັດຈຸບັນ ພ້ອມຕົວເລືອກຊຳລະໄວ',
                child: Icon(
                  Icons.info_outline,
                  color: _secondaryColor,
                  size: 14,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Total Amount in Kip
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _borderColor),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'ຍອດທັງໝົດເປັນກີບ:',
                      style: TextStyle(
                        fontFamily: 'NotoSansLao',
                        fontSize: 11,
                        color: _textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${_integerFormatter.format(equivalentKipForTotal)} ກີບ',
                      style: TextStyle(
                        fontFamily: 'NotoSansLao',
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: _secondaryColor,
                      ),
                    ),
                  ],
                ),

                if (_remainingBahtAmount > 0) ...[
                  const SizedBox(height: 6),
                  Divider(color: _borderColor, height: 1),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'ຍອດທີ່ຕ້ອງຊຳລະເປັນກີບ:',
                        style: TextStyle(
                          fontFamily: 'NotoSansLao',
                          fontSize: 11,
                          color: _textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${_integerFormatter.format(equivalentKipForRemaining)} ກີບ',
                        style: TextStyle(
                          fontFamily: 'NotoSansLao',
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _errorColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Divider
          Divider(color: _borderColor, height: 1),

          const SizedBox(height: 8),

          // Quick Payment Header
          Text(
            'ຕົວເລືອກຊຳລະໄວ',
            style: TextStyle(
              fontFamily: 'NotoSansLao',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _textPrimary,
            ),
          ),

          const SizedBox(height: 8),

          // Baht Payments Label
          Row(
            children: [
              Icon(Icons.payments, color: _primaryColor, size: 12),
              const SizedBox(width: 4),
              Text(
                'ຊຳລະດ້ວຍບາດ',
                style: TextStyle(
                  fontFamily: 'NotoSansLao',
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: _primaryColor,
                ),
              ),
            ],
          ),

          const SizedBox(height: 4),

          // Quick Payment Suggestions - Baht Row
          Row(
            children: [
              Expanded(
                child: _buildQuickPaymentButton(
                  label: 'ຊຳລະທັງໝົດດ້ວຍບາດ',
                  amount: totalAmountDue,
                  icon: Icons.account_balance_wallet,
                  currency: 'ບາດ',
                  color: _primaryColor,
                  onTap: () {
                    _bahtAmountController.text = _currencyFormatter.format(
                      totalAmountDue,
                    );
                    _kipAmountController.text = '0';
                    _onBahtAmountChanged(_bahtAmountController.text);
                    _onKipAmountChanged(_kipAmountController.text);
                  },
                ),
              ),

              if (_remainingBahtAmount > 0) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: _buildQuickPaymentButton(
                    label: 'ຊຳລະທີ່ເຫຼືອດ້ວຍບາດ',
                    amount: remainingAmountPositive,
                    icon: Icons.payments,
                    currency: 'ບາດ',
                    color: _primaryColor,
                    onTap: () {
                      double currentBaht =
                          double.tryParse(
                            _bahtAmountController.text.replaceAll(',', ''),
                          ) ??
                          0.0;
                      double newBahtAmount =
                          currentBaht + remainingAmountPositive;
                      _bahtAmountController.text = _currencyFormatter.format(
                        newBahtAmount,
                      );
                      _onBahtAmountChanged(_bahtAmountController.text);
                    },
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 8),

          // Kip Payments Label
          Row(
            children: [
              Icon(
                Icons.account_balance_wallet,
                color: _secondaryColor,
                size: 12,
              ),
              const SizedBox(width: 4),
              Text(
                'ຊຳລະດ້ວຍກີບ',
                style: TextStyle(
                  fontFamily: 'NotoSansLao',
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: _secondaryColor,
                ),
              ),
            ],
          ),

          const SizedBox(height: 4),

          // Quick Payment Suggestions - Kip Row
          Row(
            children: [
              Expanded(
                child: _buildQuickPaymentButton(
                  label: 'ຊຳລະທັງໝົດດ້ວຍກີບ',
                  amount: equivalentKipForTotal,
                  icon: Icons.payments,
                  currency: 'ກີບ',
                  color: _secondaryColor,
                  onTap: () {
                    _kipAmountController.text = _integerFormatter.format(
                      equivalentKipForTotal,
                    );
                    _bahtAmountController.text = '0';
                    _onKipAmountChanged(_kipAmountController.text);
                    _onBahtAmountChanged(_bahtAmountController.text);
                  },
                ),
              ),

              if (_remainingBahtAmount > 0) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: _buildQuickPaymentButton(
                    label: 'ຊຳລະທີ່ເຫຼືອດ້ວຍກີບ',
                    amount: equivalentKipForRemaining,
                    icon: Icons.account_balance_wallet,
                    currency: 'ກີບ',
                    color: _secondaryColor,
                    onTap: () {
                      double currentKip =
                          double.tryParse(
                            _kipAmountController.text.replaceAll(',', ''),
                          ) ??
                          0.0;
                      double newKipAmount =
                          currentKip + equivalentKipForRemaining;
                      _kipAmountController.text = _integerFormatter.format(
                        newKipAmount,
                      );
                      _onKipAmountChanged(_kipAmountController.text);
                    },
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 8),

          // Exchange Rate Reference
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _backgroundColor,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 12, color: _textSecondary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'ອ້າງອີງ: 1 ບາດ = ${_integerFormatter.format(_exchangeRate)} ກີບ',
                    style: TextStyle(
                      fontFamily: 'NotoSansLao',
                      fontSize: 9,
                      color: _textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickPaymentButton({
    required String label,
    required double amount,
    required IconData icon,
    required String currency,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'NotoSansLao',
                fontSize: 8,
                fontWeight: FontWeight.w600,
                color: _textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              currency == 'ກີບ'
                  ? '${_integerFormatter.format(amount)} $currency'
                  : '${_currencyFormatter.format(amount)} $currency',
              style: TextStyle(
                fontFamily: 'NotoSansLao',
                fontSize: 8,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double totalAmountDue = double.tryParse(widget.total_amount) ?? 0.0;
    bool isPaymentComplete = _remainingBahtAmount <= 0;
    bool hasOverpaid = _remainingBahtAmount < 0;

    return Scaffold(
      backgroundColor: _backgroundColor,
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: _primaryColor,
                    strokeWidth: 3,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'ກຳລັງໂຫລດ...',
                    style: TextStyle(
                      fontFamily: 'NotoSansLao',
                      fontSize: 16,
                      color: _textSecondary,
                    ),
                  ),
                ],
              ),
            )
          : CustomScrollView(
              slivers: [
                // Compact App Bar
                SliverAppBar(
                  expandedHeight: 60,
                  floating: false,
                  pinned: true,
                  backgroundColor: _primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  flexibleSpace: FlexibleSpaceBar(
                    title: const Text(
                      'ການຊຳລະເງິນ',
                      style: TextStyle(
                        fontFamily: 'NotoSansLao',
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            _primaryColor,
                            _primaryColor.withOpacity(0.8),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Compact Content Layout
                SliverPadding(
                  padding: const EdgeInsets.all(8),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Total Amount Section
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: _buildTotalAmountSection(totalAmountDue),
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Exchange Rate Section
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: _buildExchangeRateSection(),
                      ),

                      const SizedBox(height: 8),

                      // NEW: Kip Equivalent Calculator Section
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: _buildKipEquivalentCalculator(),
                      ),

                      const SizedBox(height: 8),

                      // Payment Input Section
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: _buildPaymentInputSection(),
                      ),

                      const SizedBox(height: 8),

                      // Status Section
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: _buildStatusSection(
                          isPaymentComplete,
                          hasOverpaid,
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Action Button
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: _buildActionButton(isPaymentComplete),
                      ),

                      const SizedBox(height: 8), // Minimal bottom padding
                    ]),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildTotalAmountSection(double totalAmountDue) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_primaryColor, _primaryColor.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.receipt_long, color: Colors.white, size: 16),
              const SizedBox(width: 4),
              Text(
                'ຍອດເງິນທີ່ຕ້ອງຊຳລະ',
                style: TextStyle(
                  fontFamily: 'NotoSansLao',
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _currencyFormatter.format(totalAmountDue),
            style: const TextStyle(
              fontFamily: 'NotoSansLao',
              fontSize: 28,
              color: Colors.white,
              fontWeight: FontWeight.bold,
              height: 1.0,
            ),
          ),
          Text(
            'ບາດ',
            style: TextStyle(
              fontFamily: 'NotoSansLao',
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExchangeRateSection() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(Icons.currency_exchange, color: _accentColor, size: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'ອັດຕາແລກປ່ຽນ: 1 ບາດ = ${_integerFormatter.format(_exchangeRate)} ກີບ',
              style: TextStyle(
                fontFamily: 'NotoSansLao',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentInputSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ປ້ອນຈຳນວນເງິນ',
            style: TextStyle(
              fontFamily: 'NotoSansLao',
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 10),

          // Baht Input
          _buildCurrencyInput(
            label: 'ເງິນບາດ',
            controller: _bahtAmountController,
            onChanged: _onBahtAmountChanged,
            currency: 'ບາດ',
            icon: Icons.payments,
            color: _primaryColor,
          ),

          const SizedBox(height: 10),

          // Kip Input
          _buildCurrencyInput(
            label: 'ເງິນກີບ',
            controller: _kipAmountController,
            onChanged: _onKipAmountChanged,
            currency: 'ກີບ',
            icon: Icons.payments,
            color: _secondaryColor,
          ),

          const SizedBox(height: 10),

          // Equivalent Display with Smart Calculation
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _backgroundColor,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: _borderColor),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.calculate, color: _textSecondary, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      'ການຄິດໄລ່ການຊຳລະ',
                      style: TextStyle(
                        fontFamily: 'NotoSansLao',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'ກີບທຽບເທົ່າ:',
                      style: TextStyle(
                        fontFamily: 'NotoSansLao',
                        fontSize: 9,
                        color: _textSecondary,
                      ),
                    ),
                    Text(
                      '${_kipInBahtEquivalentController.text} ບາດ',
                      style: TextStyle(
                        fontFamily: 'NotoSansLao',
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: _textPrimary,
                      ),
                    ),
                  ],
                ),
                // Show total paid calculation
                if (double.tryParse(
                          _bahtAmountController.text.replaceAll(',', ''),
                        ) !=
                        0 ||
                    double.tryParse(
                          _kipAmountController.text.replaceAll(',', ''),
                        ) !=
                        0) ...[
                  const SizedBox(height: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'ລວມຈ່າຍແລ້ວ:',
                        style: TextStyle(
                          fontFamily: 'NotoSansLao',
                          fontSize: 9,
                          color: _textSecondary,
                        ),
                      ),
                      Text(
                        '${_currencyFormatter.format((double.tryParse(_bahtAmountController.text.replaceAll(',', '')) ?? 0.0) + (double.tryParse(_kipInBahtEquivalentController.text.replaceAll(',', '')) ?? 0.0))} ບາດ',
                        style: TextStyle(
                          fontFamily: 'NotoSansLao',
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: _primaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrencyInput({
    required String label,
    required TextEditingController controller,
    required ValueChanged<String> onChanged,
    required String currency,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'NotoSansLao',
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: _textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          height: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            textAlign: TextAlign.right,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _textPrimary,
              fontFamily: 'NotoSansLao',
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: _cardColor,
              prefixIcon: Container(
                margin: const EdgeInsets.all(6),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(icon, color: color, size: 14),
              ),
              suffixText: currency,
              suffixStyle: TextStyle(
                fontFamily: 'NotoSansLao',
                fontSize: 12,
                color: _textSecondary,
                fontWeight: FontWeight.w600,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: _borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: _borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: color, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 8,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusSection(bool isPaymentComplete, bool hasOverpaid) {
    Color statusColor = isPaymentComplete
        ? (hasOverpaid ? _secondaryColor : _primaryColor)
        : _errorColor;

    IconData statusIcon = isPaymentComplete
        ? (hasOverpaid ? Icons.monetization_on : Icons.check_circle)
        : Icons.warning;

    String statusText = isPaymentComplete
        ? (hasOverpaid ? 'ເງິນທອນ' : 'ຊຳລະຄົບຖ້ວນ')
        : 'ຍອດເງິນທີ່ຕ້ອງຊຳລະຄົງເຫຼືອ';

    // Check if user is primarily using Kip for payment
    double kipPaid =
        double.tryParse(_kipAmountController.text.replaceAll(',', '')) ?? 0.0;
    double bahtPaid =
        double.tryParse(_bahtAmountController.text.replaceAll(',', '')) ?? 0.0;
    bool isPrimaryKip = kipPaid > 0 && kipPaid >= bahtPaid;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [statusColor, statusColor.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(statusIcon, color: Colors.white, size: 18),
              const SizedBox(width: 6),
              Text(
                statusText,
                style: TextStyle(
                  fontFamily: 'NotoSansLao',
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Show Kip first if user is primarily using Kip
          if (isPrimaryKip) ...[
            Text(
              _integerFormatter.format(_remainingKipAmount.abs()),
              style: const TextStyle(
                fontFamily: 'NotoSansLao',
                fontSize: 24,
                color: Colors.white,
                fontWeight: FontWeight.bold,
                height: 1.0,
              ),
            ),
            Text(
              'ກີບ (${_currencyFormatter.format(_remainingBahtAmount.abs())} ບາດ)',
              style: TextStyle(
                fontFamily: 'NotoSansLao',
                fontSize: 10,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ] else ...[
            Text(
              _currencyFormatter.format(_remainingBahtAmount.abs()),
              style: const TextStyle(
                fontFamily: 'NotoSansLao',
                fontSize: 24,
                color: Colors.white,
                fontWeight: FontWeight.bold,
                height: 1.0,
              ),
            ),
            Text(
              'ບາດ (${_integerFormatter.format(_remainingKipAmount.abs())} ກີບ)',
              style: TextStyle(
                fontFamily: 'NotoSansLao',
                fontSize: 10,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButton(bool isPaymentComplete) {
    return Container(
      width: double.infinity,
      height: 42,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        boxShadow: isPaymentComplete
            ? [
                BoxShadow(
                  color: _primaryColor.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: ElevatedButton(
        onPressed: isPaymentComplete ? _getDocNoAndSaveOrder : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: isPaymentComplete ? _primaryColor : _textSecondary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isPaymentComplete ? Icons.check_circle : Icons.warning,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              isPaymentComplete ? 'ບັນທຶກການຊຳລະ' : 'ກະລຸນາຊຳລະໃຫ້ຄົບຖ້ວນ',
              style: const TextStyle(
                fontFamily: 'NotoSansLao',
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
