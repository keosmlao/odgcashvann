import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../utility/my_constant.dart';
import 'regestproductdetail.dart';
import 'requestpage.dart';
import '../../utility/app_colors.dart';

class RequestProduct extends StatefulWidget {
  const RequestProduct({super.key});

  @override
  State<RequestProduct> createState() => _RequestProductState();
}

class _RequestProductState extends State<RequestProduct> {
  final _dateCtrl = TextEditingController();
  List<dynamic> _requests = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _dateCtrl.text = DateFormat('dd-MM-yyyy').format(DateTime.now());
    _fetch();
  }

  @override
  void dispose() {
    _dateCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final prefs = await SharedPreferences.getInstance();
    final wh = prefs.getString('wh_code');

    if (wh?.isEmpty != false) {
      setState(() {
        _loading = false;
        _error = 'ບໍ່ພົບລະຫັດສາງ';
      });
      _toast(_error!, AppColors.errorColor);
      return;
    }

    try {
      final res = await http.get(
        Uri.parse("${MyConstant().domain}/listrequestVansale/$wh"),
      );

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        setState(() {
          _requests = data['list'] ?? [];
          _loading = false;
        });
      } else {
        setState(() {
          _loading = false;
          _error = 'ໂຫຼດຂໍ້ມູນລົ້ມເຫຼວ';
        });
        _toast(_error!, AppColors.errorColor);
      }
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'ເຊື່ອມຕໍ່ລົ້ມເຫຼວ';
      });
      _toast(_error!, AppColors.errorColor);
    }
  }

  Future<void> _delete(String id) async {
    _showLoading();
    try {
      final res = await http.get(
        Uri.parse("${MyConstant().domain}/delete_reqest_tf/$id"),
      );
      Navigator.pop(context);

      if (res.statusCode == 200) {
        _toast('ລົບສຳເລັດ', AppColors.successColor);
        _fetch();
      } else {
        _toast('ລົບລົ້ມເຫຼວ', AppColors.errorColor);
      }
    } catch (e) {
      Navigator.pop(context);
      _toast('ລົບລົ້ມເຫຼວ', AppColors.errorColor);
    }
  }

  void _showLoading() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: CircularProgressIndicator(color: AppColors.primaryBlue),
      ),
    );
  }

  void _toast(String msg, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg, style: const TextStyle(fontFamily: 'NotoSansLao')),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildContent()),
            _buildCreateButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "ຂໍໂອນສິນຄ້າ",
                style: TextStyle(
                  fontFamily: 'NotoSansLao',
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  _buildDatePicker(),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _fetch,
                    icon: const Icon(Icons.refresh),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue.withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (date != null) {
          _dateCtrl.text = DateFormat('dd-MM-yyyy').format(date);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.calendar_today, size: 16),
            const SizedBox(width: 4),
            Text(
              _dateCtrl.text,
              style: const TextStyle(fontFamily: 'NotoSansLao', fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.primaryBlue),
            const SizedBox(height: 16),
            const Text(
              'ກຳລັງໂຫຼດ...',
              style: TextStyle(fontFamily: 'NotoSansLao'),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: const TextStyle(fontFamily: 'NotoSansLao', fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _fetch,
              icon: const Icon(Icons.refresh),
              label: const Text('ລອງໃໝ່'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    if (_requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'ບໍ່ມີລາຍການ',
              style: TextStyle(
                fontFamily: 'NotoSansLao',
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'ກົດປຸ່ມ + ເພື່ອສ້າງໃໝ່',
              style: TextStyle(
                fontFamily: 'NotoSansLao',
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _requests.length,
      itemBuilder: (context, index) => _buildRequestCard(_requests[index]),
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> req) {
    final status = req['doc_status'] ?? '';
    final canDelete = status == 'ລໍຖ້າອະນຸມັດ';
    final statusColor = _getStatusColor(status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ReqestProductDetail(
                doc_no: req['doc_no'],
                doc_date: req['doc_date'],
                wh_code: req['wh_from'],
                sh_code: req['location_from'],
                edit_status: canDelete ? '0' : '1',
              ),
            ),
          );
          _fetch();
        },
        onLongPress: canDelete ? () => _showDeleteDialog(req['doc_no']) : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      req['doc_no'] ?? '',
                      style: const TextStyle(
                        fontFamily: 'NotoSansLao',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      status,
                      style: const TextStyle(
                        fontFamily: 'NotoSansLao',
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Date
              Text(
                'ວັນທີ: ${req['doc_date'] ?? ''}',
                style: TextStyle(
                  fontFamily: 'NotoSansLao',
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 12),

              // Transfer info
              Row(
                children: [
                  Expanded(
                    child: _buildLocationInfo(
                      'ຈາກ',
                      req['wh_from'] ?? '',
                      req['location_from'] ?? '',
                      Colors.blue.shade100,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(
                      Icons.arrow_forward,
                      color: Colors.grey.shade400,
                      size: 20,
                    ),
                  ),
                  Expanded(
                    child: _buildLocationInfo(
                      'ຫາ',
                      req['wh_to'] ?? '',
                      req['location_to'] ?? '',
                      Colors.green.shade100,
                    ),
                  ),
                ],
              ),

              // Remark
              if (req['remark'] != null && req['remark'].isNotEmpty) ...[
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.sticky_note_2_outlined,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        req['remark'],
                        style: TextStyle(
                          fontFamily: 'NotoSansLao',
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              // Creator
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.bottomRight,
                child: Text(
                  'ຜູ້ສ້າງ: ${req['creator_code'] ?? ''}',
                  style: TextStyle(
                    fontFamily: 'NotoSansLao',
                    color: Colors.grey.shade500,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationInfo(
    String label,
    String wh,
    String location,
    Color bgColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'NotoSansLao',
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            wh,
            style: const TextStyle(fontFamily: 'NotoSansLao', fontSize: 12),
          ),
          Text(
            location,
            style: TextStyle(
              fontFamily: 'NotoSansLao',
              fontSize: 10,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RequestPage()),
            );
            _fetch();
          },
          icon: const Icon(Icons.add),
          label: const Text(
            'ສ້າງໃບຂໍໂອນໃໝ່',
            style: TextStyle(fontFamily: 'NotoSansLao'),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryBlue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'ລໍຖ້າອະນຸມັດ':
        return Colors.orange;
      case 'ອະນຸມັດແລ້ວ':
        return Colors.green;
      case 'ປະຕິເສດ':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _showDeleteDialog(String docNo) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(
          'ຢືນຢັນການລົບ',
          style: TextStyle(fontFamily: 'NotoSansLao'),
        ),
        content: Text(
          'ທ່ານຕ້ອງການລົບໃບຂໍໂອນເລກທີ $docNo ບໍ?',
          style: const TextStyle(fontFamily: 'NotoSansLao'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'ຍົກເລີກ',
              style: TextStyle(fontFamily: 'NotoSansLao'),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _delete(docNo);
            },
            child: const Text(
              'ລົບ',
              style: TextStyle(fontFamily: 'NotoSansLao', color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
