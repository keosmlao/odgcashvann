import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utility/my_constant.dart';
import 'comfirmdispatch.dart';
import 'imagePrint.dart';

class ListOrderbyCust extends StatefulWidget {
  final String cust_code;
  const ListOrderbyCust({super.key, required this.cust_code});

  @override
  State<ListOrderbyCust> createState() => _ListOrderbyCustState();
}

class _ListOrderbyCustState extends State<ListOrderbyCust> {
  List<dynamic> _orders = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _setupFirebase();
    _loadOrders();
  }

  Future<void> _setupFirebase() async {
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission();

    // Listen for messages when app is in foreground
    FirebaseMessaging.onMessage.listen((message) {
      if (message.notification != null) {
        _showNotificationDialog(message);
      }
    });

    // Handle message when app is opened from notification
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      final docNo = message.data['doc_no'];
      if (docNo != null) _navigateToConfirm(docNo);
    });
  }

  void _showNotificationDialog(RemoteMessage message) {
    final docNo = message.data['doc_no'];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            color: Colors.green,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_circle, color: Colors.white, size: 32),
        ),
        title: Text(
          message.notification?.title ?? 'ແຈ້ງເຕືອນ',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('ບິນເລກທີ $docNo ພ້ອມເບີກຈ່າຍແລ້ວ'),
            const SizedBox(height: 8),
            const Text(
              'ກະລຸນາຢືນຢັນການເບີກຈ່າຍ',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (docNo != null) _navigateToConfirm(docNo);
            },
            child: const Text(
              'ຢືນຢັນເລີຍ',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ປິດ'),
          ),
        ],
      ),
    );
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final response = await http.post(
        Uri.parse('${MyConstant().domain}/listorderincust'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: json.encode({
          "doc_date": DateFormat('yyyy-MM-dd').format(DateTime.now()),
          "sale_code": prefs.getString('usercode') ?? '',
          "cust_code": widget.cust_code,
        }),
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        setState(() {
          _orders = result['list'] ?? [];
          _isLoading = false;
        });
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _deleteOrder(String docNo) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(Icons.warning, color: Colors.red, size: 48),
        title: const Text('ລົບລາຍການ'),
        content: Text('ທ່ານແນ່ໃຈບໍ່ວ່າຕ້ອງການລົບບິນເລກທີ $docNo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'ລົບເລີຍ',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ຍົກເລີກ'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await http.get(
          Uri.parse('${MyConstant().domain}/deletesaleorderbill/$docNo'),
        );
        _loadOrders();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('ລົບລາຍການສຳເລັດ'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('ລົບບໍ່ສຳເລັດ: $e'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  Future<void> _navigateToConfirm(String docNo) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ConfirmDispatchScreen(doc_no: docNo),
      ),
    );
    _loadOrders();
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'ສຳເລັດ':
        return Colors.green;
      case 'ເບີກຈ່າຍຂອງໃດ້':
        return Colors.red;
      case 'ກຳລັງດຳເນີນການ':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'ສຳເລັດ':
        return Icons.check_circle;
      case 'ເບີກຈ່າຍຂອງໃດ້':
        return Icons.warning;
      case 'ກຳລັງດຳເນີນການ':
        return Icons.hourglass_empty;
      default:
        return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'ລາຍການສັ່ງຊື້',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: RefreshIndicator(onRefresh: _loadOrders, child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'ກຳລັງໂຫຼດລາຍການສັ່ງຊື້...',
              style: TextStyle(color: Colors.grey),
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
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('ເກີດຂໍ້ຜິດພາດ: $_error', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadOrders,
              icon: const Icon(Icons.refresh),
              label: const Text('ລອງໃໝ່'),
            ),
          ],
        ),
      );
    }

    if (_orders.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'ບໍ່ມີລາຍການສັ່ງຊື້ສຳລັບລູກຄ້ານີ້',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'ດຶງລົງເພື່ອໂຫຼດຂໍ້ມູນໃໝ່',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _orders.length,
      itemBuilder: (context, index) => _buildOrderCard(_orders[index]),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final status = order['status']?.toString() ?? '';
    final statusColor = _getStatusColor(status);
    final statusIcon = _getStatusIcon(status);
    final isDispatchable = status == 'ເບີກຈ່າຍຂອງໃດ້';
    final isCompleted = status == 'ສຳເລັດ';
    final orderItems = order['list'] as List<dynamic>? ?? [];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onLongPress: () => _deleteOrder(order['doc_no']?.toString() ?? ''),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with document number and status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      order['doc_no']?.toString() ?? '',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      border: Border.all(color: statusColor),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 16, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          status,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Order basic info
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Text('ວັນທີ: ${order['doc_date'] ?? ''}'),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.numbers, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text('ຈຳນວນ: ${order['count_item'] ?? 0} ລາຍການ'),
                ],
              ),

              const SizedBox(height: 12),

              // Total amount
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'ມູນຄ່າທັງໝົດ: ${NumberFormat('#,##0').format(double.tryParse(order['total_amount']?.toString() ?? '0') ?? 0)} ກີບ',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              // Order items detail
              if (orderItems.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'ລາຍລະອຽດສິນຄ້າ:',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: orderItems.map((item) {
                      final isGift = item['remark'] == 'free';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            Icon(
                              isGift ? Icons.card_giftcard : Icons.circle,
                              size: isGift ? 18 : 12,
                              color: isGift ? Colors.blue : Colors.green,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${item['item_name'] ?? ''} - ${item['qty'] ?? 0} ${item['unit_code'] ?? ''}${isGift ? ' (ຂອງແຖມ)' : ''}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isGift ? Colors.blue : Colors.black87,
                                  fontWeight: isGift
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],

              // Action buttons
              if (isDispatchable || isCompleted) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: isDispatchable
                      ? ElevatedButton.icon(
                          onPressed: () => _navigateToConfirm(
                            order['doc_no']?.toString() ?? '',
                          ),
                          icon: const Icon(Icons.check_circle, size: 20),
                          label: const Text('ຢືນຢັນການເບີກຈ່າຍ'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        )
                      : OutlinedButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PrintImage(
                                doc_no: order['doc_no']?.toString() ?? '',
                              ),
                            ),
                          ),
                          icon: const Icon(Icons.print, size: 20),
                          label: const Text('ພິມບິນ'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
