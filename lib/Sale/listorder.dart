import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'comfirmdispatch.dart';
import 'imagePrint.dart';
import '../utility/my_constant.dart';

class ListOrder extends StatefulWidget {
  const ListOrder({super.key});

  @override
  State<ListOrder> createState() => _ListOrderState();
}

class _ListOrderState extends State<ListOrder> {
  List<dynamic> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await _setupFirebase();
    await _loadOrders();
  }

  Future<void> _setupFirebase() async {
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission();

    FirebaseMessaging.onMessage.listen((message) {
      if (message.notification != null) {
        _showNotification(message.notification!);
      }
    });

    final token = await messaging.getToken();
    print("FCM Token: $token");
  }

  void _showNotification(RemoteNotification notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(notification.title ?? 'ແຈ້ງເຕືອນ'),
        content: Text(notification.body ?? ''),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ປິດ'),
          ),
        ],
      ),
    );
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final response = await http.post(
        Uri.parse('${MyConstant().domain}/listorderincust'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: json.encode({
          "doc_date": DateFormat('yyyy-MM-dd').format(DateTime.now()),
          "sale_code": prefs.getString('usercode') ?? '',
          "cust_code": "",
        }),
      );

      final result = json.decode(response.body);
      setState(() {
        _orders = result['list'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('ເກີດຂໍ້ຜິດພາດ: $e')));
      }
    }
  }

  Future<void> _deleteOrder(String docNo) async {
    try {
      await http.get(
        Uri.parse('${MyConstant().domain}/deletesaleorderbill/$docNo'),
      );
      await _loadOrders();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('ລົບບໍ່ສຳເລັດ: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadOrders,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _orders.isEmpty
            ? const Center(
                child: Text(
                  'ບໍ່ມີຂໍ້ມູນ',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: _orders.length,
                itemBuilder: (context, index) =>
                    _buildOrderCard(_orders[index]),
              ),
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final status = order['status']?.toString() ?? '';
    final isDispatchable = status == 'ເບີກຈ່າຍຂອງໃດ້';
    final isCompleted = status == 'ສຳເລັດ';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onLongPress: () => _showDeleteDialog(order['doc_no']?.toString() ?? ''),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildOrderHeader(order, isDispatchable),
              const SizedBox(height: 12),
              _buildOrderInfo(order),
              const SizedBox(height: 8),
              _buildOrderItems(order['list'] ?? []),
              if (isCompleted) ...[
                const SizedBox(height: 12),
                _buildPrintButton(order['doc_no']?.toString() ?? ''),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderHeader(Map<String, dynamic> order, bool isDispatchable) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            order['status']?.toString() ?? '',
            style: const TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        if (isDispatchable)
          ElevatedButton(
            onPressed: () =>
                _navigateToConfirm(order['doc_no']?.toString() ?? ''),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: const Text('ຢືນຢັນການເບີກຈ່າຍ'),
          ),
      ],
    );
  }

  Widget _buildOrderInfo(Map<String, dynamic> order) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('ວັນທີ: ${order['doc_date'] ?? ''}'),
        Text('ເລກທີ: ${order['doc_no'] ?? ''}'),
        Text('ຈຳນວນ: ${order['count_item'] ?? 0}'),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            'ມູນຄ່າ: ${_formatAmount(order['total_amount'])}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildOrderItems(List<dynamic> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 4),
            child: Text(
              '${item['item_name'] ?? ''} ${item['qty'] ?? 0} ${item['unit_code'] ?? ''}',
              style: TextStyle(
                color: item['remark'] == 'free'
                    ? Colors.red
                    : Colors.green.shade600,
              ),
            ),
          ),
        ),
        const Divider(),
      ],
    );
  }

  Widget _buildPrintButton(String docNo) {
    return SizedBox(
      width: 120,
      child: OutlinedButton.icon(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => PrintImage(doc_no: docNo)),
        ),
        icon: const Icon(Icons.print),
        label: const Text('ພີມບິນ'),
      ),
    );
  }

  void _showDeleteDialog(String docNo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ລົບເລີຍ'),
        content: const Text('ຢືນຢັນການລົບ'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteOrder(docNo);
            },
            child: const Text('ລົບເລີຍ'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ກັບຄືນ'),
          ),
        ],
      ),
    );
  }

  Future<void> _navigateToConfirm(String docNo) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ConfirmDispatchScreen(doc_no: docNo),
      ),
    );
    await _loadOrders();
  }

  String _formatAmount(dynamic amount) {
    try {
      final value = double.parse(amount?.toString() ?? '0');
      return NumberFormat('#,##0').format(value);
    } catch (e) {
      return '0';
    }
  }
}
