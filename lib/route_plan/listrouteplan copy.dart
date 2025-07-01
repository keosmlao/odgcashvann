import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:odgcashvan/route_plan/addplan.dart';
import 'package:odgcashvan/route_plan/close_rout_plan.dart';
import 'package:odgcashvan/route_plan/open_plan.dart';
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
  final DateFormat _displayDateFormat = DateFormat('dd-MM-yyyy');

  // Controllers for date input fields
  final TextEditingController _fromDateController = TextEditingController();
  final TextEditingController _toDateController = TextEditingController();

  // Internal date strings for API calls
  String? _selectedFromDate;
  String? _selectedToDate;

  bool _isLoading = false;
  List _routePlans = [];

  @override
  void initState() {
    super.initState();
    _initializeDates();
    _fetchRoutePlans();
  }

  void _initializeDates() {
    final now = DateTime.now();
    _fromDateController.text = _displayDateFormat.format(now);
    _toDateController.text = _displayDateFormat.format(now);
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ລົບແຜນເດີນລົດສຳເລັດແລ້ວ')),
          );
          _fetchRoutePlans(); // Refresh data after deletion
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('ບໍ່ສາມາດລົບແຜນເດີນລົດໄດ້: ${response.statusCode}'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ເກີດຂໍ້ຜິດພາດໃນການລົບແຜນເດີນລົດ: $e')),
        );
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('ບໍ່ພົບລະຫັດຜູ້ໃຊ້. ກະລຸນາເຂົ້າສູ່ລະບົບໃໝ່'),
            ),
          );
        }
        return;
      }

      final jsonBody = json.encode({
        'sale_code': userCode,
        'from_date': _selectedFromDate,
        'to_date': _selectedToDate,
      });

      final response = await post(
        Uri.parse("${MyConstant().domain}/listvanrouteplan"),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonBody,
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        setState(() => _routePlans = result['list'] ?? []);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'ບໍ່ສາມາດໂຫຼດແຜນເດີນລົດໄດ້: ${response.statusCode}',
              ),
            ),
          );
        }
        setState(() => _routePlans = []); // Clear data on error
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ເກີດຂໍ້ຜິດພາດໃນການໂຫຼດຂໍ້ມູນ: $e')),
        );
      }
      print("Error fetching route plans: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate(BuildContext context, bool isFromDate) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: isFromDate
          ? _apiDateFormat.parse(_selectedFromDate!)
          : _apiDateFormat.parse(_selectedToDate!),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.orange, // Header background color
              onPrimary: Colors.white, // Header text color
              onSurface: Colors.black, // Body text color
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.orange, // Button text color
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      setState(() {
        if (isFromDate) {
          _fromDateController.text = _displayDateFormat.format(pickedDate);
          _selectedFromDate = _apiDateFormat.format(pickedDate);
        } else {
          _toDateController.text = _displayDateFormat.format(pickedDate);
          _selectedToDate = _apiDateFormat.format(pickedDate);
        }
        _fetchRoutePlans(); // Refresh data after date selection
      });
    }
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
          title: const Text("ລົບແຜນເດີນລົດ"),
          content: const Text("ທ່ານແນ່ໃຈບໍ່ວ່າຕ້ອງການລົບແຜນເດີນລົດນີ້?"),
          actions: <Widget>[
            CupertinoDialogAction(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                _deleteRoutePlan(docNo);
              },
              child: const Text('ຢືນຢັນ', style: TextStyle(color: Colors.red)),
            ),
            CupertinoDialogAction(
              onPressed: () {
                Navigator.pop(context); // Close dialog
              },
              child: const Text('ຍົກເລີກ'),
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
        title: const Text(
          "ລາຍການແຜນເດີນລົດ",
          style: TextStyle(color: Colors.white, fontFamily: 'NotoSansLao'),
        ),
        backgroundColor: Colors.orange[800],
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _fetchRoutePlans,
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'ໂຫຼດຂໍ້ມູນຄືນໃໝ່',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const Addplan()),
          );
          _fetchRoutePlans(); // Refresh data after adding a new plan
        },
        child: const Icon(Icons.add), // You can change this icon
        backgroundColor: Colors.orange[800], // Optional: Customize the color
        tooltip: 'Add new item', // Optional: A hint for long press
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.orange),
                  )
                : _routePlans.isEmpty
                ? const Center(
                    child: Text(
                      "ບໍ່ແຜນເດີນລົດ",
                      style: TextStyle(fontSize: 16, fontFamily: 'NotoSansLao'),
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.builder(
                    itemCount: _routePlans.length,
                    itemBuilder: (context, index) {
                      var item = _routePlans[index];
                      var status = item['plan_status'].toString();
                      return GestureDetector(
                        onLongPress: () =>
                            _showDeleteConfirmationDialog(item['doc_no']),
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                          shadowColor: Colors.black26,
                          margin: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          child: ListTile(
                            title: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "${item['doc_no']}/(${item['doc_date']})",
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium!
                                      .copyWith(
                                        fontFamily: 'NotoSansLao',
                                        fontSize: 13,
                                      ),
                                ),
                                Text(
                                  "ຈຳນວນ " +
                                      item['cust_count'].toString() +
                                      " ຮ້ານ",
                                ),
                              ],
                            ),
                            subtitle: Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "ເລີ່ມ" + item['start_plan'].toString(),
                                      style: TextStyle(
                                        fontFamily: 'NotoSansLao',
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      "ສິ້ນສຸດ" +
                                          item['finish_plan'].toString(),
                                      style: TextStyle(
                                        fontFamily: 'NotoSansLao',
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "ລົດ" + item['car_name'].toString(),
                                      style: TextStyle(
                                        fontFamily: 'NotoSansLao',
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      "ຄົນຂັບ" + item['driver_name'].toString(),
                                      style: TextStyle(
                                        fontFamily: 'NotoSansLao',
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // Padding(
                          //   padding: const EdgeInsets.all(16),
                          //   child: Column(
                          //     crossAxisAlignment: CrossAxisAlignment.start,
                          //     children: [
                          //       Row(
                          //         mainAxisAlignment:
                          //             MainAxisAlignment.spaceBetween,
                          //         children: [
                          //           Text(
                          //             "${item['doc_no']}/(${item['doc_date']})",
                          //             style: Theme.of(context)
                          //                 .textTheme
                          //                 .titleMedium!
                          //                 .copyWith(
                          //                   fontFamily: 'NotoSansLao',
                          //                   fontSize: 13,
                          //                 ),
                          //           ),
                          //           Text(
                          //             "ຈຳນວນ " +
                          //                 item['cust_count'].toString() +
                          //                 " ຮ້ານ",
                          //           ),
                          //           // Text(
                          //           //   "ວັນທີ: ${item['doc_date']}",
                          //           //   style: Theme.of(context)
                          //           //       .textTheme
                          //           //       .bodySmall!
                          //           //       .copyWith(fontFamily: 'NotoSansLao'),
                          //           // ),
                          //         ],
                          //       ),
                          //       const Divider(),
                          //       Row(
                          //         mainAxisAlignment:
                          //             MainAxisAlignment.spaceBetween,
                          //         children: [
                          //           Text(
                          //             "ເລີ່ມ" + item['start_plan'].toString(),
                          //             style: TextStyle(
                          //               fontFamily: 'NotoSansLao',
                          //               fontSize: 12,
                          //             ),
                          //           ),
                          //           Text(
                          //             "ສິ້ນສຸດ" +
                          //                 item['finish_plan'].toString(),
                          //             style: TextStyle(
                          //               fontFamily: 'NotoSansLao',
                          //               fontSize: 12,
                          //             ),
                          //           ),
                          //         ],
                          //       ),
                          //       Row(
                          //         mainAxisAlignment:
                          //             MainAxisAlignment.spaceBetween,
                          //         children: [
                          //           Text(
                          //             "ລົດ" + item['car_name'].toString(),
                          //             style: TextStyle(
                          //               fontFamily: 'NotoSansLao',
                          //               fontSize: 12,
                          //             ),
                          //           ),
                          //           Text(
                          //             "ຄົນຂັບ" + item['driver_name'].toString(),
                          //             style: TextStyle(
                          //               fontFamily: 'NotoSansLao',
                          //               fontSize: 12,
                          //             ),
                          //           ),
                          //         ],
                          //       ),
                          //       const Divider(),
                          //       Row(
                          //         mainAxisAlignment: MainAxisAlignment.center,
                          //         children: [
                          //           Text(
                          //             status,
                          //             style: TextStyle(
                          //               fontWeight: FontWeight.bold,
                          //               color: _getStatusColor(status),
                          //               fontFamily: 'NotoSansLao',
                          //               fontSize: 12,
                          //             ),
                          //           ),
                          //           Wrap(
                          //             spacing: 8,
                          //             runSpacing: 4,
                          //             children: [
                          //               if (status == 'ລໍຖ້າດຳເນີນຕາມແຜນ')
                          //                 OutlinedButton(
                          //                   style: OutlinedButton.styleFrom(
                          //                     foregroundColor: Colors.orange,
                          //                     side: const BorderSide(
                          //                       color: Colors.orange,
                          //                     ),
                          //                   ),
                          //                   onPressed: () async {
                          //                     await Navigator.push(
                          //                       context,
                          //                       MaterialPageRoute(
                          //                         builder: (_) => StartPlanPage(
                          //                           doc_no: item['doc_no'],
                          //                         ),
                          //                       ),
                          //                     );
                          //                     _fetchRoutePlans();
                          //                   },
                          //                   child: const Text(
                          //                     "ເປີດ",
                          //                     style: TextStyle(
                          //                       fontFamily: 'NotoSansLao',
                          //                       fontSize: 12,
                          //                     ),
                          //                   ),
                          //                 ),
                          //               if (status == 'ດຳເນີນຕາມແຜນ')
                          //                 OutlinedButton(
                          //                   style: OutlinedButton.styleFrom(
                          //                     foregroundColor: Colors.red,
                          //                     side: const BorderSide(
                          //                       color: Colors.red,
                          //                     ),
                          //                   ),
                          //                   onPressed: () async {
                          //                     await Navigator.push(
                          //                       context,
                          //                       MaterialPageRoute(
                          //                         builder: (_) =>
                          //                             Close_rout_plan(
                          //                               doc_no: item['doc_no'],
                          //                             ),
                          //                       ),
                          //                     );
                          //                     _fetchRoutePlans();
                          //                   },
                          //                   child: const Text(
                          //                     "ປິດ",
                          //                     style: TextStyle(
                          //                       fontFamily: 'NotoSansLao',
                          //                     ),
                          //                   ),
                          //                 ),
                          // ElevatedButton.icon(
                          //   style: ElevatedButton.styleFrom(
                          //     backgroundColor: Colors.blue,
                          //     foregroundColor: Colors.white,
                          //   ),
                          //   onPressed: () {
                          //     Navigator.push(
                          //       context,
                          //       MaterialPageRoute(
                          //         builder: (_) => RoutePlanDetail(
                          //           doc_no: item['doc_no'],
                          //           doc_date: item['doc_date'],
                          //           route_plan_stt: status,
                          //         ),
                          //       ),
                          //     );
                          //   },
                          //   icon: const Icon(Icons.info_outline),
                          //   label: const Text(
                          //     "ລາຍລະອຽດ",
                          //     style: TextStyle(
                          //       fontFamily: 'NotoSansLao',
                          //     ),
                          //   ),
                          // ),
                          //             ],
                          //           ),
                          //         ],
                          //       ),
                          //     ],
                          //   ),
                          // ),
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
