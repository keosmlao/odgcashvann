import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_signaturepad/signaturepad.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;

import '../utility/my_constant.dart';

class ConfirmDispatchScreen extends StatefulWidget {
  final String doc_no;
  const ConfirmDispatchScreen({super.key, required this.doc_no});

  @override
  State<ConfirmDispatchScreen> createState() => _ConfirmDispatchScreenState();
}

class _ConfirmDispatchScreenState extends State<ConfirmDispatchScreen>
    with SingleTickerProviderStateMixin {
  final _signatureKey = GlobalKey<SfSignaturePadState>();
  bool _isLoading = false;
  bool _hasSigned = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _saveSignature() async {
    setState(() => _isLoading = true);

    try {
      final image = await _signatureKey.currentState!.toImage(pixelRatio: 3.0);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

      final response = await http.post(
        Uri.parse('${MyConstant().domain}/confirmDispatch'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: json.encode({
          'sign': base64.encode(bytes!.buffer.asUint8List()),
          'doc_no': widget.doc_no,
          'doc_date': DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()),
        }),
      );

      if (mounted) {
        if (response.statusCode == 200) {
          _showSuccessDialog();
        } else {
          throw Exception('Server Error');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'ເກີດຂໍ້ຜິດພາດ ກະລຸນາລອງໃໝ່',
              style: TextStyle(fontFamily: 'NotoSansLao'),
            ),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.check_circle,
            color: Colors.green.shade600,
            size: 48,
          ),
        ),
        title: const Text(
          'ສຳເລັດ',
          style: TextStyle(
            fontFamily: 'NotoSansLao',
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'ບັນທຶກລາຍເຊັນສຳເລັດແລ້ວ\nຂອບໃຈທີ່ໃຊ້ບໍລິການ',
          style: TextStyle(fontFamily: 'NotoSansLao'),
          textAlign: TextAlign.center,
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context)
              ..pop()
              ..pop(),
            child: const Text(
              'ສິ້ນສຸດ',
              style: TextStyle(fontFamily: 'NotoSansLao'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.grey.shade800,
        title: const Text(
          'ຢືນຢັນການເຊັນຮັບ',
          style: TextStyle(
            fontFamily: 'NotoSansLao',
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Header Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            FontAwesomeIcons.fileSignature,
                            color: Colors.blue.shade600,
                            size: 32,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'ເອກະສານເລກທີ',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                            fontFamily: 'NotoSansLao',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.doc_no,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'NotoSansLao',
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Signature Instructions
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.amber.shade700,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'ກະລຸນາເຊັນຊື່ຂອງທ່ານໃນຊ່ອງຂ້າງລຸ່ມເພື່ອຢືນຢັນການຮັບສິນຄ້າ',
                            style: TextStyle(
                              fontSize: 14,
                              fontFamily: 'NotoSansLao',
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Signature Pad
                  Container(
                    width: double.infinity,
                    height: 280,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade300, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 15,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        height: 300,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: SfSignaturePad(
                          key: _signatureKey,
                          backgroundColor: Colors.white,
                          strokeColor: Colors.black,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Clear Button
                  TextButton.icon(
                    onPressed: () {
                      _signatureKey.currentState?.clear();
                      setState(() => _hasSigned = false);
                    },
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text(
                      'ລົບລາຍເຊັນ',
                      style: TextStyle(fontFamily: 'NotoSansLao'),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey.shade600,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Confirm Button
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: double.infinity,
                    height: 56,
                    child: FilledButton.icon(
                      onPressed: _isLoading ? null : _saveSignature,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check_circle, size: 20),
                      label: Text(
                        _isLoading ? 'ກຳລັງບັນທຶກ...' : 'ຢືນຢັນການເຊັນຮັບ',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'NotoSansLao',
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.blue.shade600,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Text(
                    DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now()),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                      fontFamily: 'NotoSansLao',
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
