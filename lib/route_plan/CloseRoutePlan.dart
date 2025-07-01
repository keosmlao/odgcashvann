import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:odgcashvan/route_plan/RoutePlanService.dart';

import 'package:shared_preferences/shared_preferences.dart';

import '../utility/my_constant.dart';
import '../utility/my_style.dart';

class CloseRoutePlan extends StatefulWidget {
  final String docNo;
  const CloseRoutePlan({super.key, required this.docNo});

  @override
  State<CloseRoutePlan> createState() => _CloseRoutePlanState();
}

class _CloseRoutePlanState extends State<CloseRoutePlan> {
  String? routePlanId;
  TextEditingController txtKip = TextEditingController();
  TextEditingController txtBaht = TextEditingController();
  TextEditingController txtSaleKip = TextEditingController();
  TextEditingController txtSaleBaht = TextEditingController();
  TextEditingController txtTotalKip = TextEditingController();
  TextEditingController txtTotalBaht = TextEditingController();
  DateTime now = DateTime.now();
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    findUser();
    fetchData();
  }

  void findUser() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    setState(() {
      routePlanId = preferences.getString('route_id') ?? '';
    });
  }

  Future<void> fetchData() async {
    setState(() {
      isLoading = true;
    });

    try {
      final result = await RoutePlanService.getPlanDetails(widget.docNo);
      if (result != null) {
        setState(() {
          txtKip.text = NumberFormat(
            '#,##0',
          ).format(double.parse(result['kip_for_charge']));
          txtBaht.text = NumberFormat(
            '#,##0',
          ).format(double.parse(result['baht_for_charge']));
          txtSaleKip.text = NumberFormat(
            '#,##0',
          ).format(double.parse(result['sale_kip']));
          txtSaleBaht.text = NumberFormat(
            '#,##0',
          ).format(double.parse(result['sale_baht']));
          txtTotalKip.text = NumberFormat('#,##0').format(
            double.parse(result['kip_for_charge']) +
                double.parse(result['sale_kip']),
          );
          txtTotalBaht.text = NumberFormat('#,##0').format(
            double.parse(result['baht_for_charge']) +
                double.parse(result['sale_baht']),
          );
        });
      }
    } catch (e) {
      _showErrorDialog("Error", "Failed to load data: ${e.toString()}");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> finishPlan() async {
    setState(() {
      isLoading = true;
    });

    try {
      SharedPreferences preferences = await SharedPreferences.getInstance();
      String formattedDate = DateFormat('yyyy-MM-dd HH:mm').format(now);

      final success = await RoutePlanService.finishPlan(
        saleCode: preferences.getString('usercode') ?? '',
        finishDate: formattedDate,
        routeId: widget.docNo,
      );

      if (success) {
        _showSuccessDialog();
      } else {
        _showErrorDialog("ຄຳເຕືອນ", "ມີຂໍ້ຜິດພາດ ກະລຸນາລອງໃໝ່");
      }
    } catch (e) {
      _showErrorDialog("Error", "Failed to complete the plan: ${e.toString()}");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _showSuccessDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) {
        return CupertinoAlertDialog(
          title: Text("ສຳເລັດ"),
          content: Text("ປິດແຜນການເດີນລົດສຳເລັດ"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(String title, String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) {
        return CupertinoAlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("ປິດແຜນການເດີນລົດ"),
        backgroundColor: Colors.blue,
        centerTitle: true,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(10),
              child: Column(
                children: [
                  _buildSummaryCard(
                    MyStyle().odien1,
                    "ເງິນທອນ",
                    txtBaht,
                    txtKip,
                  ),
                  SizedBox(height: 10),
                  _buildSummaryCard(
                    MyStyle().odien3,
                    "ເງິນສົດຈາກຂາຍ",
                    txtSaleBaht,
                    txtSaleKip,
                  ),
                  SizedBox(height: 10),
                  _buildSummaryCard(
                    Colors.green,
                    "ລວມເງິນສົດ",
                    txtTotalBaht,
                    txtTotalKip,
                  ),
                  SizedBox(height: 20),
                  OutlinedButton.icon(
                    onPressed: finishPlan,
                    icon: Icon(Icons.close),
                    label: Text("ປິດແຜນການເດີນລົດ"),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryCard(
    Color color,
    String label,
    TextEditingController baht,
    TextEditingController kip,
  ) {
    return Container(
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildTextField(label + " (ບາດ)", baht),
          SizedBox(height: 10),
          _buildTextField(label + " (ກີບ)", kip),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return TextField(
      textAlign: TextAlign.right,
      controller: controller,
      style: TextStyle(fontSize: 20, color: Colors.white),
      readOnly: true,
      decoration: InputDecoration(
        border: OutlineInputBorder(),
        labelText: label,
        floatingLabelBehavior: FloatingLabelBehavior.always,
      ),
    );
  }
}
