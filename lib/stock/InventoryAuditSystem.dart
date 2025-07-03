import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:barcode_scan2/barcode_scan2.dart';

class InventoryAuditSystem extends StatefulWidget {
  const InventoryAuditSystem({super.key});

  @override
  State<InventoryAuditSystem> createState() => _InventoryAuditSystemState();
}

class _InventoryAuditSystemState extends State<InventoryAuditSystem> {
  List<Map<String, dynamic>> _audits = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadAudits();
  }

  void _loadAudits() {
    setState(() {
      _audits = [
        {
          'id': 'AUD001',
          'date': '2025-01-15',
          'warehouse': 'ສາງກາງ',
          'location': 'A001',
          'status': 'ລໍຖ້າ',
          'items_count': 25,
          'scanned_count': 0,
          'creator': 'ພະນັກງານ A',
        },
        {
          'id': 'AUD002',
          'date': '2025-01-14',
          'warehouse': 'ສາງກາງ',
          'location': 'B002',
          'status': 'ດຳເນີນການ',
          'items_count': 18,
          'scanned_count': 12,
          'creator': 'ພະນັກງານ B',
        },
        {
          'id': 'AUD003',
          'date': '2025-01-13',
          'warehouse': 'ສາງກາງ',
          'location': 'C003',
          'status': 'ສຳເລັດ',
          'items_count': 30,
          'scanned_count': 30,
          'creator': 'ພະນັກງານ C',
        },
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildAuditList()),
          ],
        ),
      ),
      floatingActionButton: _buildFab(),
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
                'ໃບກວດນັບສິນຄ້າ',
                style: TextStyle(
                  fontFamily: 'NotoSansLao',
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: () => _loadAudits(),
                icon: const Icon(Icons.refresh),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.blue.withOpacity(0.1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatsCard('ທັງໝົດ', _audits.length.toString(), Colors.blue),
              const SizedBox(width: 8),
              _buildStatsCard(
                'ລໍຖ້າ',
                _audits.where((a) => a['status'] == 'ລໍຖ້າ').length.toString(),
                Colors.orange,
              ),
              const SizedBox(width: 8),
              _buildStatsCard(
                'ສຳເລັດ',
                _audits.where((a) => a['status'] == 'ສຳເລັດ').length.toString(),
                Colors.green,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontFamily: 'NotoSansLao',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'NotoSansLao',
                fontSize: 12,
                color: color.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuditList() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_audits.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            const Text(
              'ບໍ່ມີໃບກວດນັບ',
              style: TextStyle(
                fontFamily: 'NotoSansLao',
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'ກົດປຸ່ມ + ເພື່ອສ້າງໃບກວດນັບໃໝ່',
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
      itemCount: _audits.length,
      itemBuilder: (context, index) => _buildAuditCard(_audits[index]),
    );
  }

  Widget _buildAuditCard(Map<String, dynamic> audit) {
    final status = audit['status'] ?? '';
    final statusColor = _getStatusColor(status);
    final progress = audit['items_count'] > 0
        ? (audit['scanned_count'] / audit['items_count'])
        : 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _openAuditDetail(audit),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          audit['id'],
                          style: const TextStyle(
                            fontFamily: 'NotoSansLao',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'ວັນທີ: ${audit['date']}',
                          style: TextStyle(
                            fontFamily: 'NotoSansLao',
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
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
              const SizedBox(height: 12),

              // Location Info
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.warehouse,
                      size: 16,
                      color: Colors.blue.shade700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          audit['warehouse'],
                          style: const TextStyle(
                            fontFamily: 'NotoSansLao',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'ທີ່ຕັ້ງ: ${audit['location']}',
                          style: TextStyle(
                            fontFamily: 'NotoSansLao',
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Progress
              if (status == 'ດຳເນີນການ' || status == 'ສຳເລັດ') ...[
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'ຄວາມຄືບໜ້າ',
                                style: TextStyle(
                                  fontFamily: 'NotoSansLao',
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              Text(
                                '${audit['scanned_count']}/${audit['items_count']}',
                                style: const TextStyle(
                                  fontFamily: 'NotoSansLao',
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          LinearProgressIndicator(
                            value: progress,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              statusColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],

              // Creator
              Row(
                children: [
                  Icon(Icons.person, size: 14, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    audit['creator'],
                    style: TextStyle(
                      fontFamily: 'NotoSansLao',
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFab() {
    return FloatingActionButton.extended(
      onPressed: () => _createNewAudit(),
      icon: const Icon(Icons.add),
      label: const Text(
        'ສ້າງໃບກວດນັບ',
        style: TextStyle(fontFamily: 'NotoSansLao'),
      ),
      backgroundColor: Colors.blue,
      foregroundColor: Colors.white,
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'ລໍຖ້າ':
        return Colors.orange;
      case 'ດຳເນີນການ':
        return Colors.blue;
      case 'ສຳເລັດ':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  void _openAuditDetail(Map<String, dynamic> audit) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AuditDetailPage(audit: audit)),
    );
  }

  void _createNewAudit() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateAuditPage()),
    );
  }
}

// Audit Detail Page
class AuditDetailPage extends StatefulWidget {
  final Map<String, dynamic> audit;

  const AuditDetailPage({super.key, required this.audit});

  @override
  State<AuditDetailPage> createState() => _AuditDetailPageState();
}

class _AuditDetailPageState extends State<AuditDetailPage> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  void _loadItems() {
    setState(() {
      _items = [
        {
          'code': 'PRD001',
          'name': 'ເຄື່ອງດື່ມ A',
          'expected_qty': 50,
          'actual_qty': 48,
          'unit': 'ກະປ໋ອງ',
          'scanned': true,
          'variance': -2,
        },
        {
          'code': 'PRD002',
          'name': 'ເຄື່ອງດື່ມ B',
          'expected_qty': 30,
          'actual_qty': 32,
          'unit': 'ກະປ໋ອງ',
          'scanned': true,
          'variance': 2,
        },
        {
          'code': 'PRD003',
          'name': 'ເຄື່ອງດື່ມ C',
          'expected_qty': 25,
          'actual_qty': null,
          'unit': 'ກະປ໋ອງ',
          'scanned': false,
          'variance': null,
        },
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          widget.audit['id'],
          style: const TextStyle(
            fontFamily: 'NotoSansLao',
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          if (widget.audit['status'] == 'ດຳເນີນການ')
            IconButton(
              onPressed: _scanBarcode,
              icon: const Icon(Icons.qr_code_scanner),
            ),
        ],
      ),
      body: Column(
        children: [
          _buildDetailHeader(),
          Expanded(child: _buildItemsList()),
        ],
      ),
    );
  }

  Widget _buildDetailHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _buildInfoCard('ສາງ', widget.audit['warehouse'])),
              const SizedBox(width: 8),
              Expanded(
                child: _buildInfoCard('ທີ່ຕັ້ງ', widget.audit['location']),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildInfoCard('ວັນທີ', widget.audit['date'])),
              const SizedBox(width: 8),
              Expanded(child: _buildInfoCard('ສະຖານະ', widget.audit['status'])),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'NotoSansLao',
              fontSize: 10,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'NotoSansLao',
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsList() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _items.length,
      itemBuilder: (context, index) => _buildItemCard(_items[index]),
    );
  }

  Widget _buildItemCard(Map<String, dynamic> item) {
    final scanned = item['scanned'] ?? false;
    final variance = item['variance'];
    final hasVariance = variance != null && variance != 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: scanned ? Colors.green.shade200 : Colors.grey.shade200,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: scanned ? null : () => _openCountDialog(item),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Status indicator
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: scanned ? Colors.green : Colors.grey,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['name'],
                          style: const TextStyle(
                            fontFamily: 'NotoSansLao',
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'ລະຫັດ: ${item['code']}',
                          style: TextStyle(
                            fontFamily: 'NotoSansLao',
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Quantities
              Row(
                children: [
                  Expanded(
                    child: _buildQtyInfo(
                      'ຄາດໝາຍ',
                      '${item['expected_qty']} ${item['unit']}',
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildQtyInfo(
                      'ນັບໄດ້',
                      scanned
                          ? '${item['actual_qty']} ${item['unit']}'
                          : 'ຍັງບໍ່ນັບ',
                      scanned ? Colors.green : Colors.grey,
                    ),
                  ),
                ],
              ),

              // Variance
              if (hasVariance) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: variance > 0
                        ? Colors.green.shade50
                        : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        variance > 0 ? Icons.add : Icons.remove,
                        size: 16,
                        color: variance > 0 ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'ຄວາມແຕກຕ່າງ: ${variance.abs()} ${item['unit']}',
                        style: TextStyle(
                          fontFamily: 'NotoSansLao',
                          fontSize: 12,
                          color: variance > 0 ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
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
    );
  }

  Widget _buildQtyInfo(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'NotoSansLao',
              fontSize: 10,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'NotoSansLao',
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _scanBarcode() async {
    try {
      final result = await BarcodeScanner.scan();
      if (result.rawContent.isNotEmpty) {
        // Find item by barcode and open count dialog
        _showToast('ສະແກນໄດ້: ${result.rawContent}');
      }
    } catch (e) {
      _showToast('ສະແກນລົ້ມເຫຼວ');
    }
  }

  void _openCountDialog(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (_) => CountDialog(item: item),
    );
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontFamily: 'NotoSansLao'),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// Count Dialog
class CountDialog extends StatefulWidget {
  final Map<String, dynamic> item;

  const CountDialog({super.key, required this.item});

  @override
  State<CountDialog> createState() => _CountDialogState();
}

class _CountDialogState extends State<CountDialog> {
  final _qtyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _qtyController.text = widget.item['expected_qty'].toString();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'ປ້ອນຈຳນວນ',
        style: TextStyle(fontFamily: 'NotoSansLao'),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.item['name'],
            style: const TextStyle(
              fontFamily: 'NotoSansLao',
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'ຄາດໝາຍ: ${widget.item['expected_qty']} ${widget.item['unit']}',
            style: const TextStyle(fontFamily: 'NotoSansLao'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _qtyController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'ຈຳນວນທີ່ນັບໄດ້',
              labelStyle: TextStyle(fontFamily: 'NotoSansLao'),
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'ຍົກເລີກ',
            style: TextStyle(fontFamily: 'NotoSansLao'),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            // Save count
            Navigator.pop(context);
          },
          child: const Text(
            'ບັນທຶກ',
            style: TextStyle(fontFamily: 'NotoSansLao'),
          ),
        ),
      ],
    );
  }
}

// Create Audit Page
class CreateAuditPage extends StatefulWidget {
  const CreateAuditPage({super.key});

  @override
  State<CreateAuditPage> createState() => _CreateAuditPageState();
}

class _CreateAuditPageState extends State<CreateAuditPage> {
  final _warehouseController = TextEditingController();
  final _locationController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'ສ້າງໃບກວດນັບໃໝ່',
          style: TextStyle(fontFamily: 'NotoSansLao'),
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _warehouseController,
              decoration: const InputDecoration(
                labelText: 'ສາງ',
                labelStyle: TextStyle(fontFamily: 'NotoSansLao'),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'ທີ່ຕັ້ງ',
                labelStyle: TextStyle(fontFamily: 'NotoSansLao'),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                );
                if (date != null) {
                  setState(() => _selectedDate = date);
                }
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'ວັນທີ',
                  labelStyle: TextStyle(fontFamily: 'NotoSansLao'),
                  border: OutlineInputBorder(),
                ),
                child: Text(
                  DateFormat('dd/MM/yyyy').format(_selectedDate),
                  style: const TextStyle(fontFamily: 'NotoSansLao'),
                ),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Create audit
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                ),
                child: const Text(
                  'ສ້າງໃບກວດນັບ',
                  style: TextStyle(fontFamily: 'NotoSansLao'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
