import 'dart:async';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utility/my_constant.dart';
import '../login/login.dart';
import '../route_plan/addplan.dart';
import '../route_plan/close_rout_plan.dart';
import '../route_plan/open_plan.dart';
import '../route_plan/routeplandetail.dart';

class ListRoutePlan extends StatefulWidget {
  const ListRoutePlan({super.key});

  @override
  State<ListRoutePlan> createState() => _ListRoutePlanState();
}

class _ListRoutePlanState extends State<ListRoutePlan> {
  final DateFormat _apiDateFormat = DateFormat('yyyy-MM-dd');
  final DateFormat _fullDateTimeFormat = DateFormat('dd-MM-yyyy HH:mm');
  final DateFormat _timeFormat = DateFormat('HH:mm');

  bool _isLoading = false;
  List _routePlans = [];
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchRoutePlans();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _deleteRoutePlan(String docNo) async {
    try {
      final response = await get(
        Uri.parse("${MyConstant().domain}/delete_route_plan/$docNo"),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          _showInfoSnackBar('ລົບແຜນເດີນລົດສຳເລັດແລ້ວ', Colors.green);
          _fetchRoutePlans();
        }
      } else {
        if (mounted) {
          _showInfoSnackBar(
            'ບໍ່ສາມາດລົບແຜນເດີນລົດໄດ້: ${response.statusCode}',
            Colors.red,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        _showInfoSnackBar('ເກີດຂໍ້ຜິດພາດໃນການລົບແຜນເດີນລົດ: $e', Colors.red);
      }
    }
  }

  Future<void> _fetchRoutePlans() async {
    setState(() => _isLoading = true);

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String userCode = prefs.getString('usercode') ?? '';

      if (userCode.isEmpty) {
        if (mounted) {
          _showInfoSnackBar(
            'ບໍ່ພົບລະຫັດຜູ້ໃຊ້. ກະລຸນາເຂົ້າສູ່ລະບົບໃໝ່',
            Colors.orange,
          );
        }
        _logout();
        return;
      }

      final response = await get(
        Uri.parse("${MyConstant().domain}/listvanrouteplan?salecode=$userCode"),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        setState(() => _routePlans = result['list'] ?? []);
      } else {
        if (mounted) {
          _showInfoSnackBar(
            'ບໍ່ສາມາດໂຫຼດແຜນເດີນລົດໄດ້: ${response.statusCode}',
            Colors.red,
          );
        }
        setState(() => _routePlans = []);
      }
    } catch (e) {
      if (mounted) {
        _showInfoSnackBar('ເກີດຂໍ້ຜິດພາດໃນການໂຫຼດຂໍ້ມູນ: $e', Colors.red);
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const Login()),
        (Route<dynamic> route) => false,
      );
    }
  }

  void _showLogoutConfirmationDialog() {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: const Text("ຢືນຢັນການອອກຈາກລະບົບ"),
          content: const Text("ທ່ານແນ່ໃຈບໍ່ວ່າຕ້ອງການອອກຈາກລະບົບ?"),
          actions: <Widget>[
            CupertinoDialogAction(
              onPressed: () {
                Navigator.pop(context);
                _logout();
              },
              child: const Text(
                'ອອກຈາກລະບົບ',
                style: TextStyle(color: Colors.red),
              ),
            ),
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(context),
              child: const Text('ຍົກເລີກ'),
            ),
          ],
        );
      },
    );
  }

  void _showInfoSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'ແຜນຍັງບໍ່ໃດ້ອະນຸມັດ':
        return Colors.red;
      case 'ລໍຖ້າດຳເນີນຕາມແຜນ':
        return Colors.orange;
      case 'ດຳເນີນຕາມແຜນ':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  // ✅ ປັບປຸງ: ກວດສອບ status ກ່ອນອະນຸຍາດໃຫ້ລົບ
  void _handleDeleteAction(String docNo, String status) {
    // ກວດສອບວ່າແຜນກຳລັງດຳເນີນການຢູ່ບໍ່
    if (status == 'ດຳເນີນຕາມແຜນ') {
      // ສະແດງ dialog ແຈ້ງເຕືອນວ່າບໍ່ສາມາດລົບໄດ້
      showCupertinoDialog(
        context: context,
        builder: (BuildContext context) {
          return CupertinoAlertDialog(
            title: const Text("ບໍ່ສາມາດລົບໄດ້"),
            content: const Text(
              "ບໍ່ສາມາດລົບແຜນເດີນລົດທີ່ກຳລັງດຳເນີນການຢູ່ໄດ້\nກະລຸນາປິດແຜນກ່ອນ",
            ),
            actions: <Widget>[
              CupertinoDialogAction(
                onPressed: () => Navigator.pop(context),
                child: const Text('ຕົກລົງ'),
              ),
            ],
          );
        },
      );
      return; // ອອກຈາກ function ໂດຍບໍ່ລົບ
    }

    // ຖ້າ status ບໍ່ແມ່ນ 'ດຳເນີນຕາມແຜນ' ໃຫ້ສະແດງ dialog ຢືນຢັນການລົບ
    _showDeleteConfirmationDialog(docNo);
  }

  void _showDeleteConfirmationDialog(String docNo) {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: const Text("ລົບແຜນເດີນລົດ"),
          content: const Text("ທ່ານແນ່ໃຈບໍ່ວ່າຕ້ອງການລົບແຜນເດີນລົດນີ້?"),
          actions: <Widget>[
            CupertinoDialogAction(
              onPressed: () {
                Navigator.pop(context);
                _deleteRoutePlan(docNo);
              },
              child: const Text('ຢືນຢັນ', style: TextStyle(color: Colors.red)),
            ),
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(context),
              child: const Text('ຍົກເລີກ'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color backgroundColor,
    required VoidCallback onPressed,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: ElevatedButton.icon(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: backgroundColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(vertical: 8),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            elevation: 1,
          ),
          icon: Icon(icon, size: 18),
          label: Text(label, style: const TextStyle(fontSize: 13)),
        ),
      ),
    );
  }

  String _getElapsedTime(String startPlanFullDateTimeString) {
    try {
      final DateTime startDateTime = _fullDateTimeFormat.parse(
        startPlanFullDateTimeString,
      );
      final Duration elapsed = DateTime.now().difference(startDateTime);

      if (elapsed.isNegative) return "ແຜນຍັງບໍ່ເລີ່ມ";

      int totalMinutes = elapsed.inMinutes;
      int hours = totalMinutes ~/ 60;
      int minutes = totalMinutes % 60;

      String formattedTime = '';
      if (hours > 0) formattedTime += '${hours}h ';
      formattedTime += '${minutes}m';

      if (hours == 0 && minutes == 0) {
        return elapsed.inSeconds > 0 ? "ເລີ່ມດຽວນີ້" : "0m";
      }
      return formattedTime.trim();
    } catch (e) {
      return "N/A";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "ແຜນເດີນລົດ",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _fetchRoutePlans,
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'ໂຫຼດຂໍ້ມູນຄືນໃໝ່',
          ),
          IconButton(
            onPressed: _showLogoutConfirmationDialog,
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'ອອກຈາກລະບົບ',
          ),
        ],
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade800, Colors.blue.shade400],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const Addplan()),
          );
          _fetchRoutePlans();
        },
        backgroundColor: Colors.blue[600],
        child: const Icon(Icons.add, color: Colors.white),
        tooltip: 'ເພີ່ມແຜນເດີນລົດໃໝ່',
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.blue))
          : _routePlans.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 80,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "ບໍ່ພົບແຜນເດີນລົດ",
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "ກົດປຸ່ມ '+' ເພື່ອເພີ່ມແຜນໃໝ່",
                    style: TextStyle(fontSize: 15, color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: _routePlans.length,
              itemBuilder: (context, index) {
                var item = _routePlans[index];
                var status = item['plan_status'].toString();

                String startPlanFullDateTime =
                    item['start_plan']?.toString() ?? '';
                String finishPlanFullDateTime =
                    item['finish_plan']?.toString() ?? '';
                String startPlanDisplayTime = "N/A";
                String finishPlanDisplayTime = "N/A";

                try {
                  if (startPlanFullDateTime.isNotEmpty) {
                    startPlanDisplayTime = _timeFormat.format(
                      _fullDateTimeFormat.parse(startPlanFullDateTime),
                    );
                  }
                  if (finishPlanFullDateTime.isNotEmpty) {
                    finishPlanDisplayTime = _timeFormat.format(
                      _fullDateTimeFormat.parse(finishPlanFullDateTime),
                    );
                  }
                } catch (e) {
                  // Handle parsing errors silently
                }

                List customerList = item['cust_list'] ?? [];

                return InkWell(
                  // ✅ ປັບປຸງ: ເອີ້ນ _handleDeleteAction ແທນ _showDeleteConfirmationDialog
                  onLongPress: () =>
                      _handleDeleteAction(item['doc_no'], status),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RoutePlanDetail(
                          doc_no: item['doc_no'],
                          doc_date: item['doc_date'],
                          route_plan_stt: status,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          spreadRadius: 2,
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                "${item['doc_no'] ?? 'N/A'} | ${item['doc_date'] ?? 'N/A'}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.blue,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor(
                                  status,
                                ).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                status,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _getStatusColor(status),
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        // Vehicle, Driver & Customer Count
                        Row(
                          children: [
                            const Icon(
                              Icons.local_shipping_outlined,
                              size: 18,
                              color: Colors.deepPurple,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "${item['car_name']?.isEmpty ?? true ? 'N/A' : item['car_name']} | ",
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.black87,
                              ),
                            ),
                            const Icon(
                              Icons.person_outline,
                              size: 18,
                              color: Colors.deepPurple,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "${item['driver_name']?.isEmpty ?? true ? 'N/A' : item['driver_name']}",
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.black87,
                              ),
                            ),
                            const Spacer(),
                            const Icon(
                              Icons.storefront_outlined,
                              size: 18,
                              color: Colors.teal,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "${item['cust_count'] ?? '0'} ຮ້ານ",
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Time Display
                        if (status == 'ດຳເນີນຕາມແຜນ' &&
                            startPlanFullDateTime.isNotEmpty)
                          Row(
                            children: [
                              const Icon(
                                Icons.timer_outlined,
                                size: 18,
                                color: Colors.green,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "ເລີ່ມ: $startPlanDisplayTime | ແລ່ນມາແລ້ວ: **${_getElapsedTime(startPlanFullDateTime)}**",
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          )
                        else
                          Row(
                            children: [
                              const Icon(
                                Icons.access_time,
                                size: 18,
                                color: Colors.cyan,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "ເວລາແຜນ: $startPlanDisplayTime - $finishPlanDisplayTime",
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),

                        // Customer List
                        if (customerList.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          const Divider(
                            height: 1,
                            thickness: 0.5,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "ລາຍຊື່ຮ້ານຄ້າ:",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blueGrey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: customerList.map<Widget>((customer) {
                              bool isCheckedIn =
                                  customer['checkin'] != null &&
                                  customer['checkin'].isNotEmpty;
                              Color checkinColor = isCheckedIn
                                  ? Colors.green
                                  : Colors.red;
                              IconData checkinIcon = isCheckedIn
                                  ? Icons.check_circle_outline
                                  : Icons.cancel_outlined;

                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 2.0,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      checkinIcon,
                                      size: 16,
                                      color: checkinColor,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        customer['cust_name'].toString(),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: checkinColor,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ],

                        const SizedBox(height: 16),

                        // Action Buttons
                        Row(
                          children: [
                            if (status == 'ລໍຖ້າດຳເນີນຕາມແຜນ')
                              _buildActionButton(
                                label: "ເປີດແຜນ",
                                icon: Icons.play_arrow,
                                backgroundColor: Colors.blue.shade600,
                                onPressed: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          StartPlanPage(doc_no: item['doc_no']),
                                    ),
                                  );
                                  _fetchRoutePlans();
                                },
                              ),
                            if (status == 'ດຳເນີນຕາມແຜນ')
                              _buildActionButton(
                                label: "ປິດແຜນ",
                                icon: Icons.stop,
                                backgroundColor: Colors.redAccent,
                                onPressed: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => Close_rout_plan(
                                        doc_no: item['doc_no'],
                                      ),
                                    ),
                                  );
                                  _fetchRoutePlans();
                                },
                              ),
                            if (status == 'ລໍຖ້າດຳເນີນຕາມແຜນ' ||
                                status == 'ດຳເນີນຕາມແຜນ')
                              const SizedBox(width: 8),
                            _buildActionButton(
                              label: "ລາຍລະອຽດ",
                              icon: Icons.info_outline,
                              backgroundColor: Colors.blueGrey,
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => RoutePlanDetail(
                                      doc_no: item['doc_no'],
                                      doc_date: item['doc_date'],
                                      route_plan_stt: status,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
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
