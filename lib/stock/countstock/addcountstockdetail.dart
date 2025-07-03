import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:odgcashvan/database/sql_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddCountStockDetail extends StatefulWidget {
  final String item_code;
  final String item_name;
  final String unit_code;

  const AddCountStockDetail({
    super.key,
    required this.item_code,
    required this.item_name,
    required this.unit_code,
  });

  @override
  State<AddCountStockDetail> createState() => _AddCountStockDetailState();
}

class _AddCountStockDetailState extends State<AddCountStockDetail>
    with SingleTickerProviderStateMixin {
  // Controllers & Variables
  final TextEditingController _countController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  String? _userCode;
  bool _isSaving = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  // Modern Blue Theme Colors
  static const Color primaryBlue = Color(0xff2196F3);
  static const Color accentBlue = Color(0xff1976D2);
  static const Color lightBlue = Color(0xff64B5F6);
  static const Color darkBlue = Color(0xff0D47A1);
  static const Color backgroundBlue = Color(0xffE3F2FD);
  static const Color cardBlue = Color(0xffBBDEFB);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeInOut),
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
          ),
        );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.4, 1.0, curve: Curves.elasticOut),
      ),
    );

    _initializeData();
    _animationController.forward();
  }

  @override
  void dispose() {
    _countController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  /// Initialize data
  Future<void> _initializeData() async {
    await _findUser();
  }

  /// Find user from preferences
  Future<void> _findUser() async {
    try {
      SharedPreferences preferences = await SharedPreferences.getInstance();
      setState(() {
        _userCode = preferences.getString('usercode');
      });
    } catch (e) {
      _showSnackBar('ເກີດຂໍ້ຜິດພາດໃນການໂຫຼດຂໍ້ມູນຜູ້ໃຊ້', Colors.red);
    }
  }

  /// Add item to database
  Future<void> _addItem() async {
    if (!_formKey.currentState!.validate()) return;

    if (_countController.text.trim().isEmpty) {
      _showSnackBar('ກະລຸນາປ້ອນຈຳນວນ', Colors.orange);
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await SQLHelper.createCountstock(
        widget.item_code,
        widget.item_name,
        '0', // Default balance value since we removed balance functionality
        _countController.text.trim(),
        widget.unit_code,
        _userCode ?? '',
      );

      _showSnackBar('ເພີ່ມສິນຄ້າສຳເລັດ', Colors.green);

      // Add some delay for better UX
      await Future.delayed(const Duration(milliseconds: 500));

      Navigator.pop(context, true);
    } catch (e) {
      _showSnackBar('ເກີດຂໍ້ຜິດພາດໃນການບັນທຶກ: ${e.toString()}', Colors.red);
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  /// Show snack bar
  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /// Validate quantity input
  String? _validateQuantity(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'ກະລຸນາປ້ອນຈຳນວນ';
    }

    final quantity = double.tryParse(value.trim());
    if (quantity == null) {
      return 'ກະລຸນາປ້ອນຕົວເລກທີ່ຖືກຕ້ອງ';
    }

    if (quantity < 0) {
      return 'ຈຳນວນບໍ່ສາມາດຕ່ຳກວ່າ 0';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundBlue,
      body: CustomScrollView(
        slivers: [
          // Modern App Bar
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [primaryBlue, accentBlue, darkBlue],
                  ),
                ),
              ),
              title: const Text(
                'ລາຍລະອຽດສິນຄ້າ',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              centerTitle: true,
            ),
            backgroundColor: primaryBlue,
            iconTheme: const IconThemeData(color: Colors.white),
          ),

          // Content
          SliverFillRemaining(hasScrollBody: false, child: _buildContent()),
        ],
      ),
    );
  }

  /// Build main content
  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            // Product Info Card
            FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: _buildProductInfoCard(),
              ),
            ),

            const SizedBox(height: 20),

            // Count Input Card
            FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: _buildCountInputCard(),
              ),
            ),

            const Spacer(),

            // Action Buttons
            ScaleTransition(
              scale: _scaleAnimation,
              child: _buildActionButtons(),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  /// Build product info card
  Widget _buildProductInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
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
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [primaryBlue, lightBlue],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.inventory_2,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Text(
                'ຂໍ້ມູນສິນຄ້າ',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: darkBlue,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Product Code
          _buildInfoRow(
            'ລະຫັດສິນຄ້າ',
            widget.item_code,
            Icons.qr_code,
            Colors.green,
          ),

          const SizedBox(height: 12),

          // Product Name
          _buildInfoRow(
            'ຊື່ສິນຄ້າ',
            widget.item_name,
            Icons.label,
            primaryBlue,
          ),

          const SizedBox(height: 12),

          // Unit Code
          _buildInfoRow('ໜ່ວຍ', widget.unit_code, Icons.scale, Colors.orange),
        ],
      ),
    );
  }

  /// Build info row
  Widget _buildInfoRow(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: darkBlue,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Build count input card
  Widget _buildCountInputCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
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
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [primaryBlue, lightBlue],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.edit, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              const Text(
                'ຈຳນວນທີ່ນັບໄດ້',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: darkBlue,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Input Field
          TextFormField(
            controller: _countController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: darkBlue,
            ),
            validator: _validateQuantity,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            decoration: InputDecoration(
              hintText: 'ປ້ອນຈຳນວນ',
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 24),
              filled: true,
              fillColor: backgroundBlue,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: primaryBlue, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red, width: 2),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 20,
              ),
              suffixIcon: Container(
                margin: const EdgeInsets.all(8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.unit_code,
                  style: const TextStyle(
                    color: primaryBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Quick Number Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildQuickNumberButton('0'),
              _buildQuickNumberButton('1'),
              _buildQuickNumberButton('5'),
              _buildQuickNumberButton('10'),
              _buildQuickNumberButton('清除', isAction: true),
            ],
          ),
        ],
      ),
    );
  }

  /// Build quick number button
  Widget _buildQuickNumberButton(String value, {bool isAction = false}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (isAction) {
            _countController.clear();
          } else {
            _countController.text = value;
          }
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isAction ? Colors.red.shade50 : primaryBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isAction
                  ? Colors.red.shade200
                  : primaryBlue.withOpacity(0.3),
            ),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isAction ? Colors.red.shade600 : primaryBlue,
            ),
          ),
        ),
      ),
    );
  }

  /// Build action buttons
  Widget _buildActionButtons() {
    return Row(
      children: [
        // Cancel Button
        Expanded(
          child: OutlinedButton(
            onPressed: _isSaving ? null : () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.grey.shade400),
              foregroundColor: Colors.grey.shade700,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'ຍົກເລີກ',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),

        const SizedBox(width: 16),

        // Save Button
        Expanded(
          flex: 2,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: const LinearGradient(colors: [primaryBlue, accentBlue]),
              boxShadow: [
                BoxShadow(
                  color: primaryBlue.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _addItem,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.add, size: 20),
              label: Text(
                _isSaving ? 'ກຳລັງບັນທຶກ...' : 'ເພີ່ມສິນຄ້າ',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
