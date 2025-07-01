import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:odgcashvan/Sale/listorderbycust.dart';
import 'package:odgcashvan/utility/my_constant.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart'; // Import for DateFormat

import '../Sale/salepage.dart';
import 'customer/checkin.dart';
import 'customer/cuscredit.dart';
import 'customer/customerinformation.dart';
import 'customerforrouteplan.dart';

class RoutePlanDetail extends StatefulWidget {
  final String doc_no;
  final String doc_date;
  final String route_plan_stt;

  const RoutePlanDetail({
    super.key,
    required this.doc_no,
    required this.doc_date,
    required this.route_plan_stt,
  });

  @override
  State<RoutePlanDetail> createState() => _RoutePlanDetailState();
}

class _RoutePlanDetailState extends State<RoutePlanDetail> {
  List _customerRouteData = [];
  bool _isLoading = true;

  String? _newCustCode,
      _newCustName,
      _newAreaCode,
      _newLogisticArea,
      _newLatlng;

  final Color _primaryBlue = Colors.blue.shade600;
  final Color _accentBlue = Colors.blue.shade800;
  final Color _lightBlue = Colors.blue.shade50;
  final Color _textMutedColor = Colors.grey.shade600;

  // DateFormat for parsing checkin time if it's like "HH:mm" or "YYYY-MM-DD HH:mm"
  // Assuming 'checkin' comes as "YYYY-MM-DD HH:mm" for sorting purposes
  final DateFormat _checkinDateTimeFormat = DateFormat('yyyy-MM-dd HH:mm');

  @override
  void initState() {
    super.initState();
    _fetchCustomerRouteData();
    print(widget.route_plan_stt.toString());
  }

  Future<void> _fetchCustomerRouteData() async {
    setState(() => _isLoading = true);
    SharedPreferences preferences = await SharedPreferences.getInstance();
    String? userCode = preferences.getString('usercode');

    if (userCode == null || userCode.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'ບໍ່ພົບລະຫັດຜູ້ໃຊ້. ກະລຸນາເຂົ້າສູ່ລະບົບໃໝ່',
              style: TextStyle(fontFamily: 'NotoSansLao', color: Colors.white),
            ),
          ),
        );
      }
      setState(() {
        _customerRouteData = [];
        _isLoading = false;
      });
      return;
    }

    String jsonBody = json.encode({
      'sale_code': userCode,
      'route_id': widget.doc_no,
    });

    try {
      var response = await post(
        Uri.parse("${MyConstant().domain}/listcustomerinnroute"),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonBody,
      );

      if (response.statusCode == 200) {
        var result = json.decode(response.body);
        setState(() {
          _customerRouteData = result['list'] ?? [];
          // --- NEW: Sort the data based on checkin time ---
          _customerRouteData.sort((a, b) {
            String checkinA = a['checkin'].toString();
            String checkinB = b['checkin'].toString();

            // If both are not checked in or both are "N/A", maintain original order or sort by name/code
            if (checkinA.isEmpty && checkinB.isEmpty) {
              return 0; // Maintain original order or use another fallback sort
            }
            // If A is checked in and B is not, A comes first (negative means A comes before B)
            if (checkinA.isNotEmpty && checkinB.isEmpty) {
              return -1;
            }
            // If B is checked in and A is not, B comes first
            if (checkinA.isEmpty && checkinB.isNotEmpty) {
              return 1;
            }

            // Both are checked in, compare by time (latest first)
            try {
              DateTime timeA = _checkinDateTimeFormat.parse(checkinA);
              DateTime timeB = _checkinDateTimeFormat.parse(checkinB);
              return timeB.compareTo(
                timeA,
              ); // Sort in descending order (latest first)
            } catch (e) {
              print("Error parsing checkin time for sorting: $e");
              return 0; // Fallback if parsing fails
            }
          });
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'ຜິດພາດໃນການໂຫຼດຂໍ້ມູນຮ້ານຄ້າ: ${response.statusCode}',
                style: const TextStyle(
                  fontFamily: 'NotoSansLao',
                  color: Colors.white,
                ),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() => _customerRouteData = []);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'ເກີດຂໍ້ຜິດພາດໃນການໂຫຼດຂໍ້ມູນ: $error',
              style: const TextStyle(
                fontFamily: 'NotoSansLao',
                color: Colors.white,
              ),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
      print("Error fetching customer route data: $error");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addMoreCustomerToRoute() async {
    if (_newCustCode == null || _newCustCode!.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'ບໍ່ມີລູກຄ້າໃຫ້ເພີ່ມ. ກະລຸນາເລືອກລູກຄ້າ.',
              style: TextStyle(fontFamily: 'NotoSansLao', color: Colors.white),
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    SharedPreferences preferences = await SharedPreferences.getInstance();
    String? userCode = preferences.getString('usercode');

    if (userCode == null || userCode.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'ບໍ່ພົບລະຫັດຜູ້ໃຊ້. ກະລຸນາເຂົ້າສູ່ລະບົບໃໝ່',
              style: TextStyle(fontFamily: 'NotoSansLao', color: Colors.white),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    String jsonBody = json.encode({
      'doc_no': widget.doc_no,
      'doc_date': widget.doc_date,
      'cust_code': _newCustCode,
      'area_code': _newAreaCode,
      'logistic_area': _newLogisticArea,
      'latlng': _newLatlng,
      'sale_code': userCode,
    });

    try {
      var response = await post(
        Uri.parse("${MyConstant().domain}/addcusttoroutplan"),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonBody,
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'ເພີ່ມລູກຄ້າເຂົ້າແຜນສຳເລັດ',
                style: TextStyle(
                  fontFamily: 'NotoSansLao',
                  color: Colors.white,
                ),
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
        _fetchCustomerRouteData();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'ຜິດພາດໃນການເພີ່ມລູກຄ້າ: ${response.statusCode}',
                style: const TextStyle(
                  fontFamily: 'NotoSansLao',
                  color: Colors.white,
                ),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'ເກີດຂໍ້ຜິດພາດໃນການເພີ່ມລູກຄ້າ: $e',
              style: const TextStyle(
                fontFamily: 'NotoSansLao',
                color: Colors.white,
              ),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
      print("Error adding customer to route: $e");
    } finally {
      setState(() {
        _newCustCode = null;
        _newCustName = null;
        _newAreaCode = null;
        _newLogisticArea = null;
        _newLatlng = null;
      });
    }
  }

  Future<void> _deleteCustomerFromRoute(String routeCustomerId) async {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: const Text("ລົບລູກຄ້າອອກຈາກແຜນ"),
          content: const Text(
            "ທ່ານແນ່ໃຈບໍ່ວ່າຕ້ອງການລົບລູກຄ້ານີ້ອອກຈາກແຜນ?",
            style: TextStyle(fontFamily: 'NotoSansLao'),
          ),
          actions: <Widget>[
            CupertinoDialogAction(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  var response = await get(
                    Uri.parse(
                      "${MyConstant().domain}/delete_cust_route_plan/$routeCustomerId",
                    ),
                  );
                  if (response.statusCode == 200) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'ລົບລູກຄ້າສຳເລັດ',
                            style: TextStyle(
                              fontFamily: 'NotoSansLao',
                              color: Colors.white,
                            ),
                          ),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                    _fetchCustomerRouteData();
                  } else {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'ຜິດພາດໃນການລົບລູກຄ້າ: ${response.statusCode}',
                            style: const TextStyle(
                              fontFamily: 'NotoSansLao',
                              color: Colors.white,
                            ),
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'ເກີດຂໍ້ຜິດພາດໃນການລົບ: $e',
                          style: const TextStyle(
                            fontFamily: 'NotoSansLao',
                            color: Colors.white,
                          ),
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                  print("Error deleting customer from route: $e");
                }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _lightBlue,
      appBar: AppBar(
        title: Text(
          "ແຜນເດີນລົດ: ${widget.doc_no}",
          style: const TextStyle(
            fontFamily: 'NotoSansLao',
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _fetchCustomerRouteData,
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'ໂຫຼດຂໍ້ມູນຄືນໃໝ່',
          ),
        ],
        centerTitle: true,
        backgroundColor: _primaryBlue,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: widget.route_plan_stt.toString() != 'ດຳເນີນຕາມແຜນ'
          ? FloatingActionButton.extended(
              onPressed: () async {
                final result = await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) {
                      return CustomerForRouteplan(from_route: '1');
                    },
                  ),
                );
                if (result != null) {
                  setState(() {
                    _newCustCode = result['cust_code'];
                    _newCustName = result['cust_name'];
                    _newAreaCode = result['area_code'];
                    _newLogisticArea = result['logistic_area'];
                    _newLatlng = result['latlng'];
                  });
                  _addMoreCustomerToRoute();
                }
              },
              label: const Text(
                "ເພີ່ມຮ້ານຄ້າ",
                style: TextStyle(
                  fontFamily: 'NotoSansLao',
                  color: Colors.white,
                ),
              ),
              icon: const Icon(
                Icons.person_add_alt_1_outlined,
                color: Colors.white,
              ),
              backgroundColor: _primaryBlue,
              heroTag: 'addCustomerRouteFab',
            )
          : null,
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: _primaryBlue))
          : _customerRouteData.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.location_off_outlined,
                    size: 80,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "ບໍ່ພົບຮ້ານຄ້າໃນແຜນເດີນລົດນີ້.",
                    style: TextStyle(
                      fontFamily: 'NotoSansLao',
                      fontSize: 18,
                      color: _textMutedColor,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "ກະລຸນາກົດປຸ່ມ '+' ເພື່ອເພີ່ມຮ້ານຄ້າ.",
                    style: TextStyle(
                      fontFamily: 'NotoSansLao',
                      fontSize: 15,
                      color: Colors.grey[500],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12.0),
              itemCount: _customerRouteData.length,
              itemBuilder: (BuildContext context, int index) {
                final item = _customerRouteData[index];
                final String checkinStatus = item['checkin'].toString();
                final bool isCheckedIn = checkinStatus.isNotEmpty;

                // Parse and display checkin time in HH:mm format if available
                String checkinDisplayTime = '';
                if (isCheckedIn) {
                  try {
                    // Assuming 'checkin' from API is 'YYYY-MM-DD HH:mm'
                    DateTime checkinDateTime = _checkinDateTimeFormat.parse(
                      checkinStatus,
                    );
                    checkinDisplayTime = DateFormat(
                      'HH:mm',
                    ).format(checkinDateTime);
                  } catch (e) {
                    print("Error parsing checkin time for display: $e");
                    checkinDisplayTime = 'N/A';
                  }
                }

                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 3,
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: InkWell(
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              CustomerInformation(code: "${item['cust_code']}"),
                        ),
                      );
                      _fetchCustomerRouteData();
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // --- Top Row: Customer Name & Check-in Status ---
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Text(
                                  '${item['cust_name']}',
                                  style: TextStyle(
                                    fontFamily: 'NotoSansLao',
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: _accentBlue,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: isCheckedIn
                                      ? Colors.green.shade100
                                      : Colors.red.shade100,
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Text(
                                  isCheckedIn
                                      ? '✅ ເຊັກອິນແລ້ວ ($checkinDisplayTime)'
                                      : '❌ ຍັງບໍ່ເຊັກອິນ', // Display time with checkin status
                                  style: TextStyle(
                                    fontFamily: 'NotoSansLao',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isCheckedIn
                                        ? Colors.green.shade700
                                        : Colors.red.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'ລະຫັດ: ${item['cust_code']}',
                            style: TextStyle(
                              fontFamily: 'NotoSansLao',
                              fontSize: 12,
                              color: _textMutedColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '📍 ${item['address'] ?? 'N/A'}' +
                                (item['address_2']?.isNotEmpty == true
                                    ? ', ${item['address_2']}'
                                    : ''),
                            style: TextStyle(
                              fontFamily: 'NotoSansLao',
                              fontSize: 12,
                              color: _textMutedColor,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),

                          const SizedBox(height: 16),
                          const Divider(
                            height: 1,
                            thickness: 0.5,
                            color: Colors.black12,
                          ),
                          const SizedBox(height: 16),

                          // 💰 Financial Info (Horizontal layout)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildCompactInfoColumn(
                                icon: Icons.receipt_long,
                                label: 'ບິນລ້າສຸດ',
                                value: item['total_amount']?.toString() ?? '0',
                                // removed specific valueColor, now controlled by _buildCompactInfoColumn default
                              ),
                              _buildCompactInfoColumn(
                                icon: Icons.payments,
                                label: 'ເງິນລ້າສຸດ',
                                value: item['payment']?.toString() ?? '0',
                                // removed specific valueColor
                              ),
                              _buildCompactInfoColumn(
                                icon: Icons.format_list_numbered,
                                label: 'ຈຳນວນບິນ',
                                value: item['billcount']?.toString() ?? '0',
                                unit: ' ບິນ',
                                // Conditional color for billcount remains
                                valueColor:
                                    (item['billcount']?.toString() ?? '0') ==
                                        '0'
                                    ? Colors.red.shade700
                                    : Colors.green.shade700,
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // --- Primary Action Button (Check-in / Sale) ---
                          if (widget.route_plan_stt.toString() ==
                              'ດຳເນີນຕາມແຜນ')
                            isCheckedIn
                                ? // If Checked-in (Show Sale Button)
                                  SizedBox(
                                    width: double.infinity,
                                    height: 40, // Reduced height
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => SalePage(
                                              cust_code: "${item['cust_code']}",
                                              cust_group_1:
                                                  "${item['group_main']}",
                                              cust_group_2:
                                                  "${item['group_sub_1']}",
                                            ),
                                          ),
                                        );
                                      },
                                      icon: const Icon(
                                        Icons.shopping_cart_outlined,
                                        color: Colors.white,
                                        size: 18, // Reduced icon size
                                      ),
                                      label: const Text(
                                        'ຂາຍສິນຄ້າ',
                                        style: TextStyle(
                                          fontFamily: 'NotoSansLao',
                                          fontSize: 14, // Reduced font size
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        elevation: 3,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 8,
                                          horizontal: 16,
                                        ), // Adjusted padding
                                      ),
                                    ),
                                  )
                                : // If NOT Checked-in (Show Check-in Button)
                                  SizedBox(
                                    width: double.infinity,
                                    height: 40, // Reduced height
                                    child: ElevatedButton.icon(
                                      onPressed: () async {
                                        await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => CheckIn(
                                              doc_no: widget.doc_no.toString(),
                                              cust_code: "${item['cust_code']}",
                                              checkin: item['checkin']
                                                  .toString(),
                                              latlng: item['latlng'].toString(),
                                              pic: item['pic1'].toString(),
                                            ),
                                          ),
                                        );
                                        _fetchCustomerRouteData();
                                      },
                                      icon: const Icon(
                                        Icons.login,
                                        color: Colors.white,
                                        size: 18, // Reduced icon size
                                      ),
                                      label: const Text(
                                        "ເຊັກອິນ",
                                        style: TextStyle(
                                          fontFamily: 'NotoSansLao',
                                          fontSize: 14, // Reduced font size
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: _primaryBlue,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        elevation: 3,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 8,
                                          horizontal: 16,
                                        ), // Adjusted padding
                                      ),
                                    ),
                                  )
                          else if (widget.route_plan_stt.toString() !=
                                  'ດຳເນີນຕາມແຜນ' &&
                              !isCheckedIn)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.red.shade400,
                                  width: 1.5,
                                ),
                              ),
                              child: Text(
                                '❌ ບໍ່ສາມາດເຊັກອິນໄດ້ (ແຜນຍັງບໍ່ເລີ່ມ)',
                                style: TextStyle(
                                  fontFamily: 'NotoSansLao',
                                  color: Colors.red.shade700,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),

                          const SizedBox(
                            height: 16,
                          ), // Reduced space before secondary actions
                          // --- Secondary Actions (Row of TextButtons/Icons) ---
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildSecondaryActionButton(
                                Icons.history,
                                'ປະຫວັດຊື້',
                                () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ListOrderbyCust(
                                        cust_code: "${item['cust_code']}",
                                      ),
                                    ),
                                  );
                                  _fetchCustomerRouteData();
                                },
                              ),
                              _buildSecondaryActionButton(
                                Icons.account_balance_wallet_outlined,
                                'ໜີ້ຄົງເຫຼືອ',
                                () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => CustCredit(
                                        cust_code: "${item['cust_code']}",
                                      ),
                                    ),
                                  );
                                  _fetchCustomerRouteData();
                                },
                              ),
                              _buildSecondaryActionButton(
                                Icons.delete_outline,
                                'ລົບອອກ',
                                () => _deleteCustomerFromRoute(
                                  item['route_customer_id'].toString(),
                                ),
                                isDestructive: true,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  // Modified _buildCompactInfoColumn for consistent styling
  Widget _buildCompactInfoColumn({
    required IconData icon,
    required String label,
    required String value,
    String unit = '',
    Color? valueColor, // Optional: for conditional coloring like 'billcount'
  }) {
    // Define standard colors and sizes
    const double iconSize = 20; // Standardized icon size
    final Color iconColor = Colors.grey.shade700; // Consistent icon color
    const double labelFontSize = 12; // Standardized label font size
    final Color labelColor = Colors.grey.shade600; // Consistent label color
    const double valueFontSize = 14; // Standardized value font size
    final Color defaultValueColor = Colors.black87; // Default value color

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: iconSize,
          color: iconColor,
        ), // Standardized icon size and color
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'NotoSansLao',
            fontSize: labelFontSize, // Standardized label font size
            color: labelColor, // Standardized label color
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        Text(
          '$value$unit',
          style: TextStyle(
            fontFamily: 'NotoSansLao',
            fontSize: valueFontSize, // Standardized value font size
            fontWeight: FontWeight.bold,
            color:
                valueColor ??
                defaultValueColor, // Use provided color or default
          ),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ],
    );
  }

  Widget _buildSecondaryActionButton(
    IconData icon,
    String label,
    VoidCallback onPressed, {
    bool isDestructive = false,
  }) {
    return Expanded(
      child: TextButton.icon(
        onPressed: onPressed,
        icon: Icon(
          icon,
          size: 20,
          color: isDestructive ? Colors.red.shade600 : Colors.grey.shade700,
        ),
        label: Text(
          label,
          style: TextStyle(
            fontFamily: 'NotoSansLao',
            fontSize: 12,
            color: isDestructive ? Colors.red.shade600 : Colors.grey.shade700,
          ),
        ),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          alignment: Alignment.center,
        ),
      ),
    );
  }
}
