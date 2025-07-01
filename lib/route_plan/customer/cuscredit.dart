import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:odgcashvan/utility/my_constant.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class CustCredit extends StatefulWidget {
  final String? cust_code;
  const CustCredit({super.key, this.cust_code});

  @override
  State<CustCredit> createState() => _CustCreditState();
}

class _CustCreditState extends State<CustCredit> {
  String _totalAmount = '0.00';
  String _totalOnDue = '0.00';
  String _totalOverdue = '0.00';
  bool _isLoading = true;

  List<dynamic> _detailList = [];

  final NumberFormat _currencyFormatter = NumberFormat.currency(
    locale: 'lo_LA',
    symbol: '',
    decimalDigits: 2,
  );

  @override
  void initState() {
    super.initState();
    _fetchCreditData();
  }

  Future<void> _fetchCreditData() async {
    setState(() => _isLoading = true);

    SharedPreferences preferences = await SharedPreferences.getInstance();
    String? userCode = preferences.getString('usercode');

    if (widget.cust_code == null ||
        widget.cust_code!.isEmpty ||
        userCode == null) {
      _showError('ຂໍ້ມູນບໍ່ຄົບຖ້ວນ');
      return;
    }

    try {
      var res = await get(
        Uri.parse(
          "${MyConstant().domain}/sum_creditbyarcv?custcode=${widget.cust_code}",
        ),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
      );

      if (res.statusCode == 200) {
        var resBody = json.decode(res.body);
        setState(() {
          _totalAmount = _currencyFormatter.format(
            double.tryParse(resBody['balance_amount'].toString()) ?? 0,
          );
          _totalOnDue = _currencyFormatter.format(
            double.tryParse(resBody['credit_ondue'].toString()) ?? 0,
          );
          _totalOverdue = _currencyFormatter.format(
            double.tryParse(resBody['credit_overdue'].toString()) ?? 0,
          );
        });
      }

      // Load detail list
      await _fetchCreditDetails();
    } catch (e) {
      _showError("Error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchCreditDetails() async {
    try {
      var res = await get(
        Uri.parse(
          "${MyConstant().domain}/credit_detail_list?custcode=${widget.cust_code}",
        ),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
      );

      if (res.statusCode == 200) {
        var data = json.decode(res.body);
        setState(() => _detailList = data['list'] ?? []);
      }
    } catch (e) {
      _showError("Error loading detail: $e");
    }
  }

  void _showError(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            msg,
            style: const TextStyle(
              fontFamily: 'NotoSansLao',
              color: Colors.white,
            ),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
    setState(() {
      _isLoading = false;
      _totalAmount = '0.00';
      _totalOnDue = '0.00';
      _totalOverdue = '0.00';
      _detailList = [];
    });
  }

  Widget _buildCreditCard({
    required String label,
    required String amount,
    required Color backgroundColor,
    required Color textColor,
    double height = 70,
    double width = 160,
    double amountFontSize = 26,
    double labelFontSize = 14,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      color: backgroundColor,
      child: SizedBox(
        height: height,
        width: width,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              amount,
              style: TextStyle(
                fontFamily: 'NotoSansLao',
                fontSize: amountFontSize,
                color: textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'NotoSansLao',
                fontSize: labelFontSize,
                color: textColor.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color _primaryBlue = Colors.blue.shade600;
    final Color _accentBlue = Colors.blue.shade800;
    final Color _lightBlue = Colors.blue.shade50;

    return Scaffold(
      backgroundColor: _lightBlue,
      appBar: AppBar(
        title: const Text(
          "ລາຍລະອຽດໜີ້",
          style: TextStyle(fontFamily: 'NotoSansLao', color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: _primaryBlue,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: _primaryBlue))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildCreditCard(
                    label: "ໜີ້ທັງໝົດ",
                    amount: _totalAmount,
                    backgroundColor: _accentBlue,
                    textColor: Colors.white,
                    height: 120,
                    width: double.infinity,
                    amountFontSize: 36,
                    labelFontSize: 16,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildCreditCard(
                        label: "ຢູ່ໃນກຳນົດ",
                        amount: _totalOnDue,
                        backgroundColor: Colors.green.shade600,
                        textColor: Colors.white,
                        height: 90,
                        width: MediaQuery.of(context).size.width / 2 - 25,
                      ),
                      _buildCreditCard(
                        label: "ກາຍກຳນົດ",
                        amount: _totalOverdue,
                        backgroundColor: Colors.red.shade600,
                        textColor: Colors.white,
                        height: 90,
                        width: MediaQuery.of(context).size.width / 2 - 25,
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  const Divider(),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "ລາຍການເຄື່ອນໄຫວໜີ້",
                      style: TextStyle(
                        fontFamily: 'NotoSansLao',
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: _accentBlue,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _detailList.isEmpty
                      ? const Text(
                          "ບໍ່ມີຂໍ້ມູນເຄື່ອນໄຫວ",
                          style: TextStyle(fontFamily: 'NotoSansLao'),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _detailList.length,
                          itemBuilder: (context, index) {
                            final item = _detailList[index];
                            return ListTile(
                              title: Text(
                                "ເອກະສານ: ${item['doc_no']}",
                                style: const TextStyle(
                                  fontFamily: 'NotoSansLao',
                                ),
                              ),
                              subtitle: Text(
                                "ວັນທີ: ${item['doc_date']}",
                                style: const TextStyle(
                                  fontFamily: 'NotoSansLao',
                                ),
                              ),
                              trailing: Text(
                                "${item['amount']} B",
                                style: const TextStyle(
                                  fontFamily: 'NotoSansLao',
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),
    );
  }
}
