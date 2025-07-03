import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:odgcashvan/utility/my_constant.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../utility/app_colors.dart';
import 'editqty.dart';
import 'productforeditrequest.dart';

class ReqestProductDetail extends StatefulWidget {
  final String doc_no;
  final String wh_code;
  final String sh_code;
  final String doc_date;
  final String edit_status;

  const ReqestProductDetail({
    super.key,
    required this.doc_no,
    required this.wh_code,
    required this.sh_code,
    required this.doc_date,
    required this.edit_status,
  });

  @override
  State<ReqestProductDetail> createState() => _ReqestProductDetailState();
}

class _ReqestProductDetailState extends State<ReqestProductDetail>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  bool _editing = false;
  List<dynamic> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnim = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOut));
    _editing = widget.edit_status == '0';
    _fetch();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await http.get(
        Uri.parse(
          "${MyConstant().domain}/listrequestVansaledetail/${widget.doc_no}",
        ),
      );

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        setState(() {
          _items = data['list'] ?? [];
          _loading = false;
        });
        _animCtrl.forward();
      } else {
        setState(() {
          _loading = false;
          _error = 'ໂຫຼດລົ້ມເຫຼວ';
        });
        _toast(_error!, Colors.red);
      }
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'ເຊື່ອມຕໍ່ລົ້ມເຫຼວ';
      });
      _toast(_error!, Colors.red);
    }
  }

  Future<void> _delete(String rowId) async {
    _showLoading();
    try {
      final res = await http.get(
        Uri.parse("${MyConstant().domain}/deleteiteminrequeststk/$rowId"),
      );
      Navigator.pop(context);

      if (res.statusCode == 200) {
        _toast('ລົບສຳເລັດ', Colors.green);
        _fetch();
      } else {
        _toast('ລົບລົ້ມເຫຼວ', Colors.red);
      }
    } catch (e) {
      Navigator.pop(context);
      _toast('ລົບລົ້ມເຫຼວ', Colors.red);
    }
  }

  void _showLoading() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppColors.primaryBlue),
              const SizedBox(height: 12),
              const Text(
                'ກຳລັງປະມວນຜົນ...',
                style: TextStyle(fontFamily: 'NotoSansLao', fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _toast(String msg, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            msg,
            style: const TextStyle(fontFamily: 'NotoSansLao', fontSize: 12),
          ),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          margin: const EdgeInsets.all(12),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(child: _buildContent()),
        ],
      ),
      floatingActionButton: _editing ? _buildFab() : null,
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 80,
      floating: false,
      pinned: true,
      backgroundColor: AppColors.primaryBlue,
      foregroundColor: Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          widget.doc_no,
          style: const TextStyle(
            fontFamily: 'NotoSansLao',
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        titlePadding: const EdgeInsets.only(left: 16, bottom: 12),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primaryBlue,
                AppColors.primaryBlue.withOpacity(0.8),
              ],
            ),
          ),
        ),
      ),
      actions: [
        if (widget.edit_status == '0')
          IconButton(
            onPressed: () {
              setState(() => _editing = !_editing);
              _toast(
                _editing ? 'ເປີດໂໝດແກ້ໄຂ' : 'ປິດໂໝດແກ້ໄຂ',
                _editing ? Colors.blue : Colors.grey,
              );
            },
            icon: Icon(_editing ? Icons.check_circle : Icons.edit, size: 20),
          ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppColors.primaryBlue),
              const SizedBox(height: 12),
              const Text(
                'ກຳລັງໂຫຼດ...',
                style: TextStyle(fontFamily: 'NotoSansLao', fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 40, color: Colors.red.shade300),
              const SizedBox(height: 12),
              Text(
                _error!,
                style: const TextStyle(fontFamily: 'NotoSansLao', fontSize: 14),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _fetch,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('ລອງໃໝ່', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_items.isEmpty) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inbox_outlined, size: 40, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              const Text(
                'ບໍ່ມີສິນຄ້າ',
                style: TextStyle(
                  fontFamily: 'NotoSansLao',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              if (_editing)
                Text(
                  'ກົດປຸ່ມ + ເພື່ອເພີ່ມສິນຄ້າ',
                  style: TextStyle(
                    fontFamily: 'NotoSansLao',
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return FadeTransition(
      opacity: _fadeAnim,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary card
            _buildSummaryCard(),
            const SizedBox(height: 12),

            // Items list
            Text(
              'ລາຍການສິນຄ້າ (${_items.length})',
              style: const TextStyle(
                fontFamily: 'NotoSansLao',
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            ..._items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return AnimatedContainer(
                duration: Duration(milliseconds: 300 + (index * 100)),
                curve: Curves.easeOutBack,
                child: _buildItemCard(item),
              );
            }).toList(),

            const SizedBox(height: 60), // Space for FAB
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      color: AppColors.primaryBlue.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'ສະຫຼຸບ',
                  style: TextStyle(
                    fontFamily: 'NotoSansLao',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _editing ? Colors.orange : Colors.blue,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _editing ? 'ສາມາດແກ້ໄຂ' : 'ອ່ານເທົ່ານັ້ນ',
                    style: const TextStyle(
                      fontFamily: 'NotoSansLao',
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _buildSummaryItem('ວັນທີ', widget.doc_date)),
                Expanded(
                  child: _buildSummaryItem('ຈຳນວນລາຍການ', '${_items.length}'),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(child: _buildSummaryItem('ຈາກສາງ', widget.wh_code)),
                Expanded(child: _buildSummaryItem('ທີ່ເກັບ', widget.sh_code)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Column(
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
        const SizedBox(height: 1),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'NotoSansLao',
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildItemCard(Map<String, dynamic> item) {
    final rowId = item['roworder'].toString();
    final itemName = item['item_name'] ?? 'ບໍ່ມີຊື່';
    final itemCode = item['item_code'] ?? 'N/A';
    final qty = item['qty'] ?? '0';
    final unit = item['unit_code'] ?? 'N/A';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        itemName,
                        style: const TextStyle(
                          fontFamily: 'NotoSansLao',
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          itemCode,
                          style: TextStyle(
                            fontFamily: 'NotoSansLao',
                            fontSize: 10,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // Quantity
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text(
                        qty,
                        style: TextStyle(
                          fontFamily: 'NotoSansLao',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                      Text(
                        unit,
                        style: TextStyle(
                          fontFamily: 'NotoSansLao',
                          fontSize: 10,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Action buttons
            if (_editing) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditQty(
                            wh_code: widget.wh_code,
                            sh_code: widget.sh_code,
                            ic_code: itemCode,
                            qty: qty.toString(),
                            unit_code: unit,
                            doc_no: widget.doc_no,
                          ),
                        ),
                      );
                      _fetch();
                    },
                    icon: const Icon(Icons.edit, size: 14),
                    label: const Text(
                      'ແກ້ໄຂ',
                      style: TextStyle(fontFamily: 'NotoSansLao', fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 4),
                  TextButton.icon(
                    onPressed: () => _showDeleteDialog(rowId, itemName),
                    icon: const Icon(Icons.delete, size: 14, color: Colors.red),
                    label: const Text(
                      'ລົບ',
                      style: TextStyle(
                        fontFamily: 'NotoSansLao',
                        fontSize: 12,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFab() {
    return FloatingActionButton(
      onPressed: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductForEditRequest(
              wh_code: widget.wh_code,
              sh_code: widget.sh_code,
              doc_no: widget.doc_no,
              doc_date: widget.doc_date,
            ),
          ),
        );
        _fetch();
      },
      backgroundColor: AppColors.primaryBlue,
      foregroundColor: Colors.white,
      child: const Icon(Icons.add, size: 24),
    );
  }

  void _showDeleteDialog(String rowId, String itemName) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        title: const Text(
          'ຢືນຢັນການລົບ',
          style: TextStyle(fontFamily: 'NotoSansLao', fontSize: 14),
        ),
        content: Text(
          'ທ່ານຕ້ອງການລົບ "$itemName" ບໍ?',
          style: const TextStyle(fontFamily: 'NotoSansLao', fontSize: 12),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'ຍົກເລີກ',
              style: TextStyle(fontFamily: 'NotoSansLao', fontSize: 12),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _delete(rowId);
            },
            child: const Text(
              'ລົບ',
              style: TextStyle(
                fontFamily: 'NotoSansLao',
                fontSize: 12,
                color: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
