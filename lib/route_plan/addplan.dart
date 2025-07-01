import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:odgcashvan/database/sql_helper.dart';
import 'package:odgcashvan/route_plan/customerforrouteplan.dart';
import 'package:odgcashvan/utility/my_constant.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Addplan extends StatefulWidget {
  const Addplan({super.key});

  @override
  State<Addplan> createState() => _AddplanState();
}

class _AddplanState extends State<Addplan> {
  List<Map<String, dynamic>> _journals = [];
  TextEditingController _dateInputController = TextEditingController();

  String? _selectedDateForApi;
  bool _isSaving = false;

  final DateFormat _apiDateFormat = DateFormat('yyyy-MM-dd');
  final DateFormat _displayDateFormat = DateFormat('dd-MM-yyyy');

  // Define consistent colors for the theme
  final Color _primaryBlue = Colors.blue.shade600;
  final Color _accentBlue = Colors.blue.shade800;
  final Color _lightBlue = Colors.blue.shade50;
  final Color _textMutedColor = Colors.grey.shade600;

  @override
  void initState() {
    super.initState();
    _initializeDate();
    _refreshJournals();
  }

  void _initializeDate() {
    final now = DateTime.now();
    _dateInputController.text = _displayDateFormat.format(now);
    _selectedDateForApi = _apiDateFormat.format(now);
  }

  void _refreshJournals() async {
    final data = await SQLHelper.Allcustomer();
    setState(() {
      _journals = data;
    });
  }

  void _deleteItem(String id) async {
    await SQLHelper.deleteacustomerbyid(id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'ລົບລາຍການຮ້ານຄ້າສຳເລັດ',
            style: TextStyle(fontFamily: 'NotoSansLao', color: Colors.white),
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
    _refreshJournals();
  }

  Future<void> _saveToDatabase() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          Center(child: CircularProgressIndicator(color: _primaryBlue)),
    );

    try {
      FirebaseMessaging messaging = FirebaseMessaging.instance;
      String? token = await messaging.getToken();
      SharedPreferences preferences = await SharedPreferences.getInstance();

      if (_journals.isEmpty) {
        Navigator.of(context).pop();
        if (mounted) {
          _showAlertDialog(
            "ແຈ້ງເຕືອນ",
            "ກະລຸນາເພີ່ມລາຍການຮ້ານຄ້າກ່ອນບັນທຶກແຜນ.",
          );
        }
        return;
      }
      if (_selectedDateForApi == null || _selectedDateForApi!.isEmpty) {
        Navigator.of(context).pop();
        if (mounted) {
          _showAlertDialog("ແຈ້ງເຕືອນ", "ກະລຸນາເລືອກວັນທີສຳລັບແຜນເດີນລົດ.");
        }
        return;
      }

      String jsonProduct = json.encode({
        "side_code": preferences.getString('side_code').toString(),
        "department_code": preferences.getString('department_code').toString(),
        "sale_code": preferences.getString('usercode').toString(),
        "area_code": preferences.getString('area_code').toString(),
        "logistic_area": preferences.getString('logistic_area').toString(),
        "doc_date": _selectedDateForApi!,
        "tokend": token,
        "bill": _journals,
      });

      var response = await post(
        Uri.parse("${MyConstant().domain}/saverouteplanvansale"),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonProduct,
      );

      Navigator.of(context).pop();

      if (response.statusCode == 200) {
        await SQLHelper.deleteallcustomer();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'ບັນທຶກແຜນເດີນລົດສຳເລັດ',
                style: TextStyle(
                  fontFamily: 'NotoSansLao',
                  color: Colors.white,
                ),
              ),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } else {
        if (mounted) {
          _showAlertDialog(
            "ບັນທຶກລົ້ມເຫຼວ",
            "ເກີດຂໍ້ຜິດພາດໃນການບັນທຶກແຜນ. ກະລຸນາລອງໃໝ່.",
          );
        }
      }
    } catch (e) {
      Navigator.of(context).pop();
      if (mounted) {
        _showAlertDialog(
          "ເກີດຂໍ້ຜິດພາດ",
          "ບໍ່ສາມາດເຊື່ອມຕໍ່ເຊີເວີໄດ້. ກະລຸນາກວດສອບການເຊື່ອມຕໍ່ອິນເຕີເນັດ.",
        );
      }
      print("Error saving route plan: $e");
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _showAlertDialog(String title, String content) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(
          title,
          style: TextStyle(
            fontFamily: 'NotoSansLao',
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(content, style: TextStyle(fontFamily: 'NotoSansLao')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "OK",
              style: TextStyle(fontFamily: 'NotoSansLao', color: _primaryBlue),
            ),
          ),
        ],
      ),
    );
  }

  // Helper to build a compact section card
  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget content,
    required Color iconColor,
    required Color titleColor,
    List<Widget>? actions,
    double cardPadding = 15.0,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(icon, color: iconColor, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium!.copyWith(
                        fontFamily: 'NotoSansLao',
                        color: titleColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (actions != null) Row(children: actions),
              ],
            ),
            const Divider(height: 20, thickness: 0.8, color: Colors.black12),
            content,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "ສ້າງແຜນເດີນລົດ",
          style: TextStyle(color: Colors.white, fontFamily: 'NotoSansLao'),
        ),
        backgroundColor: _primaryBlue,
        centerTitle: true,
        elevation: 0,
      ),
      body: Container(
        color: _lightBlue,
        child: Column(
          children: [
            // --- Section 1: Date Selection ---
            _buildSectionCard(
              title: "ວັນທີແຜນເດີນລົດ",
              icon: Icons.calendar_today,
              iconColor: _accentBlue,
              titleColor: _accentBlue,
              cardPadding: 15.0,
              content: GestureDetector(
                onTap: () async {
                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(1950),
                    lastDate: DateTime(2100),
                    builder: (context, child) {
                      return Theme(
                        data: ThemeData.light().copyWith(
                          colorScheme: ColorScheme.light(
                            primary: _primaryBlue,
                            onPrimary: Colors.white,
                            onSurface: Colors.black,
                          ),
                          textButtonTheme: TextButtonThemeData(
                            style: TextButton.styleFrom(
                              foregroundColor: _primaryBlue,
                            ),
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (pickedDate != null) {
                    setState(() {
                      _selectedDateForApi = _apiDateFormat.format(pickedDate);
                      _dateInputController.text = _displayDateFormat.format(
                        pickedDate,
                      );
                    });
                  }
                },
                child: AbsorbPointer(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: _lightBlue.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _primaryBlue.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Icon(Icons.event, color: _primaryBlue, size: 22),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _dateInputController.text,
                            style: TextStyle(
                              fontFamily: 'NotoSansLao',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: _accentBlue,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.grey.shade400,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // --- Section 2: Customer List ---
            Expanded(
              child: _buildSectionCard(
                title: "ລາຍການຮ້ານຄ້າ",
                icon: Icons.storefront,
                iconColor: _accentBlue,
                titleColor: _accentBlue,
                cardPadding: 15.0,
                actions: [
                  // --- COMPACTED "Add Customer" Button (OutlinedButton.icon) ---
                  OutlinedButton.icon(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              CustomerForRouteplan(from_route: '0'),
                        ),
                      );
                      _refreshJournals();
                    },
                    icon: Icon(
                      Icons.add_location_alt_outlined,
                      color: _primaryBlue, // Icon color matches theme
                      size: 16, // Even smaller icon
                    ),
                    label: Text(
                      "ເພີ່ມຮ້ານຄ້າ",
                      style: TextStyle(
                        fontFamily: 'NotoSansLao',
                        color: _primaryBlue, // Text color matches theme
                        fontSize: 12, // Even smaller label
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: _primaryBlue,
                        width: 1.0,
                      ), // Thinner border
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          6,
                        ), // More compact rounding
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8, // Reduced horizontal padding
                        vertical: 4, // Reduced vertical padding
                      ),
                      backgroundColor: Colors.white, // White background
                      elevation: 0, // No shadow
                      tapTargetSize:
                          MaterialTapTargetSize.shrinkWrap, // Shrink tap area
                    ),
                  ),
                ],
                content: _journals.isEmpty
                    ? Expanded(
                        // Added Expanded here
                        child: Center(
                          // Added Center here
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.map_outlined,
                                size: 60,
                                color: Colors.grey[350],
                              ),
                              const SizedBox(height: 15),
                              Text(
                                "ຍັງບໍ່ມີຮ້ານຄ້າໃນແຜນເດີນລົດຂອງທ່ານ.",
                                style: TextStyle(
                                  fontFamily: 'NotoSansLao',
                                  fontSize: 15,
                                  color: _textMutedColor,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "ກົດປຸ່ມ 'ເພີ່ມຮ້ານຄ້າ' ດ້ານເທິງ.",
                                style: TextStyle(
                                  fontFamily: 'NotoSansLao',
                                  fontSize: 13,
                                  color: Colors.grey[500],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      )
                    : SizedBox(
                        height: MediaQuery.of(context).size.height * 0.30,
                        child: ListView.builder(
                          itemCount: _journals.length,
                          itemBuilder: (context, index) => Dismissible(
                            key: ValueKey(_journals[index]['id']),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 15,
                              ),
                              color: Colors.redAccent.shade100,
                              child: const Icon(
                                Icons.delete_forever,
                                color: Colors.red,
                                size: 25,
                              ),
                            ),
                            confirmDismiss: (direction) async {
                              return await showCupertinoDialog(
                                context: context,
                                builder: (context) => CupertinoAlertDialog(
                                  title: const Text("ຢືນຢັນການລົບ"),
                                  content: Text(
                                    "ທ່ານແນ່ໃຈບໍວ່າຈະລົບຮ້ານຄ້າ ${_journals[index]['cust_name']} ອອກຈາກແຜນ?",
                                    style: TextStyle(fontFamily: 'NotoSansLao'),
                                  ),
                                  actions: [
                                    CupertinoDialogAction(
                                      onPressed: () =>
                                          Navigator.of(context).pop(true),
                                      child: Text(
                                        "ລົບ",
                                        style: TextStyle(
                                          color: Colors.red,
                                          fontFamily: 'NotoSansLao',
                                        ),
                                      ),
                                    ),
                                    CupertinoDialogAction(
                                      onPressed: () =>
                                          Navigator.of(context).pop(false),
                                      child: Text(
                                        "ຍົກເລີກ",
                                        style: TextStyle(
                                          fontFamily: 'NotoSansLao',
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                            onDismissed: (direction) {
                              _deleteItem(_journals[index]['id'].toString());
                            },
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.03),
                                    blurRadius: 5,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                leading: CircleAvatar(
                                  backgroundColor: _primaryBlue.withOpacity(
                                    0.15,
                                  ),
                                  radius: 18,
                                  child: Text(
                                    (index + 1).toString(),
                                    style: TextStyle(
                                      color: _accentBlue,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  _journals[index]['cust_name'],
                                  style: Theme.of(context).textTheme.titleSmall!
                                      .copyWith(
                                        fontWeight: FontWeight.w600,
                                        fontFamily: 'NotoSansLao',
                                        color: Colors.black87,
                                        fontSize: 14,
                                      ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  _journals[index]['cust_code'],
                                  style: Theme.of(context).textTheme.bodySmall!
                                      .copyWith(
                                        fontFamily: 'NotoSansLao',
                                        color: _textMutedColor,
                                        fontSize: 12,
                                      ),
                                ),
                                trailing: Icon(
                                  Icons.arrow_forward_ios,
                                  color: Colors.grey.shade300,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
              ),
            ),

            // --- Save Plan Button (fixed at bottom) ---
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12,
              ),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  icon: _isSaving
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Icon(Icons.cloud_upload_outlined, size: 24),
                  label: Text(
                    _isSaving ? "ກຳລັງບັນທຶກແຜນ..." : "ບັນທຶກແຜນເດີນລົດ",
                    style: const TextStyle(
                      fontFamily: 'NotoSansLao',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accentBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 5,
                    disabledForegroundColor: Colors.white.withOpacity(0.5),
                    disabledBackgroundColor: _primaryBlue.withOpacity(0.4),
                  ),
                  onPressed: _journals.isEmpty || _isSaving
                      ? null
                      : _saveToDatabase,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
