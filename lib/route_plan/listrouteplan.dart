import 'dart:async';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:odgcashvan/login/login.dart';
import 'package:odgcashvan/route_plan/addplan.dart';
import 'package:odgcashvan/route_plan/close_rout_plan.dart';
import 'package:odgcashvan/route_plan/open_plan.dart'; // Make sure this is StartPlanPage
import 'package:odgcashvan/route_plan/routeplandetail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utility/my_constant.dart';

class ListRoutePlan extends StatefulWidget {
  const ListRoutePlan({super.key});

  @override
  State<ListRoutePlan> createState() => _ListRoutePlanState();
}

class _ListRoutePlanState extends State<ListRoutePlan> {
  // Date formatters
  final DateFormat _apiDateFormat = DateFormat('yyyy-MM-dd');
  final DateFormat _displayDateFormat = DateFormat(
    'dd-MM-yyyy',
  ); // Not directly used but good to keep
  final DateFormat _fullDateTimeFormat = DateFormat('dd-MM-yyyy HH:mm');
  final DateFormat _timeFormat = DateFormat('HH:mm');

  // Internal date strings for API calls
  String? _selectedFromDate; // Currently not used for filtering API calls
  String? _selectedToDate; // Currently not used for filtering API calls

  bool _isLoading = false;
  List _routePlans = [];

  // Timer for updating elapsed time
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _initializeDates();
    _fetchRoutePlans();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          // Trigger a rebuild to update elapsed times
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _initializeDates() {
    final now = DateTime.now();
    _selectedFromDate = _apiDateFormat.format(now);
    _selectedToDate = _apiDateFormat.format(now);
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
      print("Error deleting route plan: $e");
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
        // Redirect to login if userCode is not found
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
      print("Error fetching route plans: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // --- New method for logout ---
  Future<void> _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs
        .clear(); // Clear all stored preferences (usercode, route_id, etc.)
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => const Login(),
        ), // Navigate to your login page
        (Route<dynamic> route) =>
            false, // Remove all previous routes from the stack
      );
    }
  }

  void _showLogoutConfirmationDialog() {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: const Text(
            "ຢືນຢັນການອອກຈາກລະບົບ",
            style: TextStyle(
              fontFamily: 'NotoSansLao',
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            "ທ່ານແນ່ໃຈບໍ່ວ່າຕ້ອງການອອກຈາກລະບົບ?",
            style: TextStyle(fontFamily: 'NotoSansLao'),
          ),
          actions: <Widget>[
            CupertinoDialogAction(
              onPressed: () {
                Navigator.pop(context); // Dismiss dialog
                _logout(); // Perform logout
              },
              child: const Text(
                'ອອກຈາກລະບົບ',
                style: TextStyle(fontFamily: 'NotoSansLao', color: Colors.red),
              ),
            ),
            CupertinoDialogAction(
              onPressed: () {
                Navigator.pop(context); // Dismiss dialog
              },
              child: const Text(
                'ຍົກເລີກ',
                style: TextStyle(fontFamily: 'NotoSansLao'),
              ),
            ),
          ],
        );
      },
    );
  }

  // Unified SnackBar display
  void _showInfoSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            fontFamily: 'NotoSansLao',
            color: Colors.white,
          ),
        ),
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

  void _showDeleteConfirmationDialog(String docNo) {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: const Text(
            "ລົບແຜນເດີນລົດ",
            style: TextStyle(
              fontFamily: 'NotoSansLao',
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            "ທ່ານແນ່ໃຈບໍ່ວ່າຕ້ອງການລົບແຜນເດີນລົດນີ້?",
            style: TextStyle(fontFamily: 'NotoSansLao'),
          ),
          actions: <Widget>[
            CupertinoDialogAction(
              onPressed: () {
                Navigator.pop(context);
                _deleteRoutePlan(docNo);
              },
              child: const Text(
                'ຢືນຢັນ',
                style: TextStyle(color: Colors.red, fontFamily: 'NotoSansLao'),
              ),
            ),
            CupertinoDialogAction(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                'ຍົກເລີກ',
                style: TextStyle(fontFamily: 'NotoSansLao'),
              ),
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
          label: Text(
            label,
            style: const TextStyle(fontFamily: 'NotoSansLao', fontSize: 13),
          ),
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

      if (elapsed.isNegative) {
        return "ແຜນຍັງບໍ່ເລີ່ມ";
      }

      int totalMinutes = elapsed.inMinutes;
      int hours = totalMinutes ~/ 60;
      int minutes = totalMinutes % 60;

      String formattedTime = '';
      if (hours > 0) {
        formattedTime += '${hours}h ';
      }
      formattedTime += '${minutes}m';

      if (hours == 0 && minutes == 0) {
        if (elapsed.inSeconds > 0) {
          return "ເລີ່ມດຽວນີ້";
        } else {
          return "0m";
        }
      }
      return formattedTime.trim();
    } catch (e) {
      print(
        "Error calculating elapsed time for '$startPlanFullDateTimeString': $e",
      );
      return "N/A";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "ແຜນເດີນລົດ",
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'NotoSansLao',
            fontWeight: FontWeight.bold,
          ),
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
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.blue),
                  )
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
                          style: TextStyle(
                            fontSize: 18,
                            fontFamily: 'NotoSansLao',
                            color: Colors.grey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "ກົດປຸ່ມ '+' ເພື່ອເພີ່ມແຜນໃໝ່.",
                          style: TextStyle(
                            fontSize: 15,
                            fontFamily: 'NotoSansLao',
                            color: Colors.grey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _routePlans.length,
                    itemBuilder: (context, index) {
                      var item = _routePlans[index];
                      var status = item['plan_status'].toString();

                      // Safely get date and time strings
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
                        print("Error parsing date/time for display: $e");
                      }

                      List customerList = item['cust_list'] ?? [];

                      return InkWell(
                        onLongPress: () =>
                            _showDeleteConfirmationDialog(item['doc_no']),
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
                            color: Colors
                                .blue
                                .shade50, // Light blue background for cards
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.grey.shade200,
                              width: 1,
                            ),
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
                              // --- Top Row: Doc No, Date & Status ---
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      "${item['doc_no'] ?? 'N/A'} | ${item['doc_date'] ?? 'N/A'}",
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium!
                                          .copyWith(
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'NotoSansLao',
                                            color: Colors
                                                .blue[900], // Darker blue for emphasis
                                            fontSize: 16,
                                          ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Status Badge
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
                                        fontFamily: 'NotoSansLao',
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 8),

                              // --- Vehicle, Driver & Customer Count ---
                              Row(
                                children: [
                                  Icon(
                                    Icons.local_shipping_outlined,
                                    size: 18,
                                    color: Colors
                                        .deepPurple[400], // New color for vehicle icon
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    "${item['car_name']?.isEmpty ?? true ? 'N/A' : item['car_name']} | ",
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium!
                                        .copyWith(
                                          fontFamily: 'NotoSansLao',
                                          fontSize: 13,
                                          color: Colors.grey[800],
                                        ),
                                  ),
                                  Icon(
                                    Icons.person_outline,
                                    size: 18,
                                    color: Colors
                                        .deepPurple[400], // New color for person icon
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    "${item['driver_name']?.isEmpty ?? true ? 'N/A' : item['driver_name']}",
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium!
                                        .copyWith(
                                          fontFamily: 'NotoSansLao',
                                          fontSize: 13,
                                          color: Colors.grey[800],
                                        ),
                                  ),
                                  const Spacer(),
                                  Icon(
                                    Icons.storefront_outlined,
                                    size: 18,
                                    color: Colors
                                        .teal[500], // New color for storefront icon
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    "${item['cust_count'] ?? '0'} ຮ້ານ",
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium!
                                        .copyWith(
                                          fontFamily: 'NotoSansLao',
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.black87,
                                        ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 12),

                              // --- Time Display Logic ---
                              if (status == 'ດຳເນີນຕາມແຜນ' &&
                                  startPlanFullDateTime.isNotEmpty)
                                Row(
                                  children: [
                                    Icon(
                                      Icons.timer_outlined,
                                      size: 18,
                                      color: Colors.green[600],
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      "ເລີ່ມ: $startPlanDisplayTime | ແລ່ນມາແລ້ວ: **${_getElapsedTime(startPlanFullDateTime)}**",
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium!
                                          .copyWith(
                                            fontFamily: 'NotoSansLao',
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.green[800],
                                          ),
                                    ),
                                  ],
                                )
                              else
                                Row(
                                  children: [
                                    Icon(
                                      Icons.access_time,
                                      size: 18,
                                      color: Colors
                                          .cyan[500], // New color for plan time icon
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      "ເວລາແຜນ: ${startPlanDisplayTime} - ${finishPlanDisplayTime}",
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium!
                                          .copyWith(
                                            fontFamily: 'NotoSansLao',
                                            fontSize: 13,
                                            color: Colors.grey[800],
                                          ),
                                    ),
                                  ],
                                ),
                              // --- Customer List Section ---
                              if (customerList.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                const Divider(
                                  height: 1,
                                  thickness: 0.5,
                                  color: Colors.grey,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "ລາຍຊື່ຮ້ານຄ້າ:",
                                  style: Theme.of(context).textTheme.bodyMedium!
                                      .copyWith(
                                        fontFamily: 'NotoSansLao',
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blueGrey[700],
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: customerList.map<Widget>((
                                    customer,
                                  ) {
                                    // This is where you determine the check-in status
                                    bool isCheckedIn =
                                        customer['checkin'] != null &&
                                        customer['checkin'].isNotEmpty;

                                    // Based on the status, set the color and icon
                                    Color checkinColor = isCheckedIn
                                        ? Colors
                                              .green[700]! // Green for checked-in
                                        : Colors
                                              .red[700]!; // Red for not checked-in
                                    IconData checkinIcon = isCheckedIn
                                        ? Icons
                                              .check_circle_outline // Checkmark icon
                                        : Icons.cancel_outlined; // Cancel icon

                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 2.0,
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            checkinIcon, // Display the chosen icon
                                            size: 16,
                                            color:
                                                checkinColor, // Apply the chosen color
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              customer['cust_name'].toString(),
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall!
                                                  .copyWith(
                                                    fontFamily: 'NotoSansLao',
                                                    color:
                                                        checkinColor, // Apply the chosen color to text
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

                              // --- Action Buttons ---
                              Row(
                                children: [
                                  if (status == 'ລໍຖ້າດຳເນີນຕາມແຜນ')
                                    _buildActionButton(
                                      label: "ເປີດແຜນ",
                                      icon: Icons.play_arrow,
                                      backgroundColor: Colors.blue[600]!,
                                      onPressed: () async {
                                        await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => StartPlanPage(
                                              doc_no: item['doc_no'],
                                            ),
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
          ),
        ],
      ),
    );
  }
}
