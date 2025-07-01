import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utility/my_constant.dart';
import 'comfirmdispatch.dart';
import 'imagePrint.dart';

class ListOrderbyCust extends StatefulWidget {
  final String cust_code;
  const ListOrderbyCust({super.key, required this.cust_code});

  @override
  State<ListOrderbyCust> createState() => _ListOrderbyCustState();
}

class _ListOrderbyCustState extends State<ListOrderbyCust> {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  List _orders = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Define consistent colors for the theme - A slightly warmer, professional palette
  final Color _primaryColor = const Color(0xFF1E88E5); // Deeper Blue
  final Color _accentColor = const Color(
    0xFF42A5F5,
  ); // Lighter Blue for accents
  final Color _backgroundColor = const Color(0xFFF0F2F5); // Light Grayish Blue
  final Color _cardColor = Colors.white;
  final Color _textColorPrimary = const Color(0xFF263238); // Dark Grey
  final Color _textColorSecondary = const Color(0xFF78909C); // Muted Grey
  final Color _statusConfirmedColor = const Color(
    0xFF43A047,
  ); // Green (success)
  final Color _statusPendingColor = const Color(0xFFFFB300); // Amber (warning)
  final Color _statusReadyToDispatchColor = const Color(
    0xFFE53935,
  ); // Red (danger/action needed)
  final Color _giftItemColor = const Color(
    0xFF1E88E5,
  ); // Primary blue for gifts

  final NumberFormat _currencyFormatter = NumberFormat('#,##0.00');

  @override
  void initState() {
    super.initState();
    _fetchOrders();

    _firebaseMessaging.requestPermission();

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        _showInAppNotification(
          message.notification!.title,
          message.notification!.body,
          message.data['doc_no'],
        );
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (message.data['doc_no'] != null) {
        _navigateToConfirmDispatch(message.data['doc_no']);
      }
    });

    _firebaseMessaging.getToken().then((token) {
      print("FCM Token: $token");
    });
  }

  void _showInAppNotification(String? title, String? body, String? docNo) {
    showCupertinoDialog(
      context: context,
      builder: (context) {
        return CupertinoAlertDialog(
          title: Text(
            title ?? 'ມີຂໍ້ຄວາມໃໝ່',
            style: const TextStyle(
              fontFamily: 'NotoSansLao',
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Icon(
                Icons.check_circle_outline,
                color: _statusConfirmedColor,
                size: 40,
              ),
              const SizedBox(height: 8),
              Text(
                'ບິນເລກທີ ${docNo ?? body} ຊຳລະຖືກຕ້ອງແລ້ວ.' ??
                    'ທ່ານໄດ້ຮັບການແຈ້ງເຕືອນ',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'NotoSansLao',
                  color: _textColorPrimary,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'ກະລຸນາຢືນຢັນການເບີກຈ່າຍ.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'NotoSansLao',
                  color: _textColorSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () {
                Navigator.pop(context);
                if (docNo != null) {
                  _navigateToConfirmDispatch(docNo);
                }
              },
              child: Text(
                'ຢືນຢັນການເບີກຈ່າຍ',
                style: TextStyle(
                  fontFamily: 'NotoSansLao',
                  color: _primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'ປິດ',
                style: TextStyle(
                  fontFamily: 'NotoSansLao',
                  color: _statusReadyToDispatchColor,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _navigateToConfirmDispatch(String docNo) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ConfirmDispatchScreen(doc_no: docNo),
      ),
    );
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    SharedPreferences preferences = await SharedPreferences.getInstance();
    DateTime now = DateTime.now();
    var formatter = DateFormat('yyyy-MM-dd');
    String requestBody = json.encode({
      "doc_date": formatter.format(now),
      "sale_code": preferences.getString('usercode').toString(),
      "cust_code": widget.cust_code,
    });

    try {
      final response = await post(
        Uri.parse("${MyConstant().domain}/listorderincust"),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: requestBody,
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        setState(() {
          _orders = result['list'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage =
              'Failed to load orders. Status code: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error fetching data: $e';
      });
    }
  }

  Future<void> _deleteBillCount(String docNo) async {
    _showLoadingDialog();
    try {
      final response = await get(
        Uri.parse("${MyConstant().domain}/deletesaleorderbill/$docNo"),
      );
      Navigator.pop(context);

      if (response.statusCode == 200) {
        _showAlertDialog(
          title: "ລົບສຳເລັດ",
          content: "ລາຍການສັ່ງຊື້ $docNo ຖືກລົບແລ້ວ.",
          isError: false,
        );
      } else {
        final errorResult = json.decode(response.body);
        _showAlertDialog(
          title: "ລົບບໍ່ສຳເລັດ",
          content:
              "ເກີດຂໍ້ຜິດພາດ: ${errorResult['message'] ?? 'ບໍ່ສາມາດລົບລາຍການໄດ້.'}",
          isError: true,
        );
      }
    } catch (e) {
      Navigator.pop(context);
      _showAlertDialog(
        title: "ຂໍ້ຜິດພາດ",
        content: "ບໍ່ສາມາດລົບລາຍການໄດ້: $e",
        isError: true,
      );
    } finally {
      _fetchOrders();
    }
  }

  void _showAlertDialog({
    required String title,
    required String content,
    bool isError = false,
    VoidCallback? onOkPressed,
  }) {
    showCupertinoDialog(
      context: context,
      builder: (context) {
        return CupertinoAlertDialog(
          title: Text(
            title,
            style: TextStyle(
              fontFamily: 'NotoSansLao',
              fontWeight: FontWeight.bold,
              color: isError ? _statusReadyToDispatchColor : _textColorPrimary,
            ),
          ),
          content: Text(
            content,
            style: const TextStyle(fontFamily: 'NotoSansLao', fontSize: 14),
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () {
                Navigator.pop(context);
                onOkPressed?.call();
              },
              child: Text(
                'ຕົກລົງ',
                style: TextStyle(
                  fontFamily: 'NotoSansLao',
                  color: isError ? _statusReadyToDispatchColor : _primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showLoadingDialog() {
    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return PopScope(
          canPop: false,
          child: Center(child: CircularProgressIndicator(color: _primaryColor)),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: const Text(
          "ລາຍການສັ່ງຊື້",
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'NotoSansLao',
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: _primaryColor,
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: _primaryColor),
            const SizedBox(height: 16),
            Text(
              'ກຳລັງໂຫຼດລາຍການສັ່ງຊື້...',
              style: TextStyle(
                fontFamily: 'NotoSansLao',
                color: _textColorSecondary,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 60,
                color: _statusReadyToDispatchColor,
              ),
              const SizedBox(height: 16),
              Text(
                'ເກີດຂໍ້ຜິດພາດ: $_errorMessage',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'NotoSansLao',
                  color: _statusReadyToDispatchColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _fetchOrders,
                icon: const Icon(Icons.refresh, color: Colors.white),
                label: const Text(
                  'ລອງໃໝ່',
                  style: TextStyle(
                    fontFamily: 'NotoSansLao',
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accentColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  elevation: 3,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 80,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 20),
            Text(
              'ບໍ່ມີລາຍການສັ່ງຊື້ສຳລັບລູກຄ້ານີ້.',
              style: TextStyle(
                fontFamily: 'NotoSansLao',
                color: _textColorSecondary,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'ກວດສອບວັນທີ ຫຼື ເລີ່ມຕົ້ນການສັ່ງຊື້ໃໝ່.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'NotoSansLao',
                color: _textColorSecondary.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _orders.length,
      itemBuilder: (BuildContext context, int index) {
        final order = _orders[index];
        final String status = order['status'] ?? 'ບໍ່ລະບຸ';
        Color statusColor;
        String statusLabel;
        IconData statusIcon;

        switch (status) {
          case 'ສຳເລັດ':
            statusColor = _statusConfirmedColor;
            statusLabel = 'ສຳເລັດ';
            statusIcon = Icons.check_circle_outline;
            break;
          case 'ກຳລັງດຳເນີນການ':
            statusColor = _statusPendingColor;
            statusLabel = 'ກຳລັງດຳເນີນການ';
            statusIcon = Icons.hourglass_empty;
            break;
          case 'ເບີກຈ່າຍຂອງໃດ້':
            statusColor = _statusReadyToDispatchColor;
            statusLabel = 'ພ້ອມເບີກຈ່າຍ';
            statusIcon = Icons.warning_amber_rounded;
            break;
          default:
            statusColor = _textColorSecondary;
            statusLabel = status;
            statusIcon = Icons.info_outline;
        }

        return Card(
          elevation: 5, // Higher elevation for a more pronounced card effect
          margin: const EdgeInsets.only(
            bottom: 18,
          ), // More vertical space between cards
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15), // Rounded corners
          ),
          color: _cardColor,
          child: InkWell(
            onLongPress: () {
              _showAlertDialog(
                title: "ລົບລາຍການ",
                content:
                    "ທ່ານແນ່ໃຈບໍ່ວ່າຕ້ອງການລົບລາຍການສັ່ງຊື້ ${order['doc_no']} ນີ້?",
                isError: true,
                onOkPressed: () => _deleteBillCount(order['doc_no'].toString()),
              );
            },
            borderRadius: BorderRadius.circular(15),
            child: Padding(
              padding: const EdgeInsets.all(20.0), // Generous padding
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Header: Bill Number and Status ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          '${order['doc_no'] ?? 'N/A'}',
                          style: TextStyle(
                            fontFamily: 'NotoSansLao',
                            fontWeight: FontWeight.bold,
                            fontSize: 20, // Larger bill number for prominence
                            color: _textColorPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 15),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(
                            0.18,
                          ), // More vivid background
                          borderRadius: BorderRadius.circular(
                            20,
                          ), // Pill-shaped status
                          border: Border.all(
                            color: statusColor,
                            width: 1.5,
                          ), // Clearer border
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(statusIcon, size: 18, color: statusColor),
                            const SizedBox(width: 6),
                            Text(
                              statusLabel,
                              style: TextStyle(
                                fontFamily: 'NotoSansLao',
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: statusColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(
                    height: 25,
                    thickness: 1.2,
                    color: Colors.grey,
                  ), // Thicker divider
                  // --- Order Details Section ---
                  _buildDetailRow(
                    label: 'ວັນທີ',
                    value: order['doc_date'] ?? 'N/A',
                    icon: Icons.calendar_today,
                  ),
                  _buildDetailRow(
                    label: 'ຈຳນວນລາຍການ',
                    value: '${order['count_item'] ?? '0'} ລາຍການ',
                    icon: Icons.numbers, // Changed icon for count
                  ),
                  const SizedBox(height: 15),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: _primaryColor.withOpacity(
                          0.1,
                        ), // Subtle background for total
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'ມູນຄ່າທັງໝົດ: ${_currencyFormatter.format(double.tryParse(order['total_amount']?.toString() ?? '0.0') ?? 0.0)} ກີບ',
                        style: TextStyle(
                          fontFamily: 'NotoSansLao',
                          fontWeight: FontWeight.bold,
                          fontSize: 22, // Even larger total amount
                          color: _primaryColor,
                        ),
                      ),
                    ),
                  ),
                  const Divider(height: 25, thickness: 1.2, color: Colors.grey),

                  // --- Order Items List ---
                  if (order['list'] != null && order['list'].isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ລາຍລະອຽດສິນຄ້າ:',
                          style: TextStyle(
                            fontFamily: 'NotoSansLao',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _textColorPrimary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: order['list'].length,
                          itemBuilder: (context, innerIndex) {
                            final item = order['list'][innerIndex];
                            final isGift = item['remark'] == 'free';
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 6.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    isGift
                                        ? Icons.card_giftcard
                                        : Icons
                                              .circle_outlined, // Changed icon for regular item
                                    size: isGift ? 20 : 16, // Adjusted size
                                    color: isGift
                                        ? _giftItemColor
                                        : _textColorSecondary.withOpacity(0.7),
                                  ),
                                  SizedBox(width: isGift ? 8 : 10),
                                  Expanded(
                                    child: Text(
                                      '${item['item_name'] ?? 'N/A'} - ${item['qty'] ?? '0'} ${item['unit_code'] ?? ''}'
                                      '${isGift ? ' (ຂອງແຖມ)' : ''}',
                                      style: TextStyle(
                                        fontFamily: 'NotoSansLao',
                                        fontSize: 14,
                                        color: isGift
                                            ? _giftItemColor
                                            : _textColorPrimary,
                                        fontWeight: isGift
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        const Divider(
                          height: 25,
                          thickness: 1.2,
                          color: Colors.grey,
                        ),
                      ],
                    ),

                  // --- Action Buttons Section ---
                  Align(
                    alignment: Alignment.centerRight,
                    child: Wrap(
                      // Use Wrap for responsive button layout
                      spacing: 12, // Horizontal spacing
                      runSpacing: 10, // Vertical spacing if wrapped
                      children: [
                        if (status == 'ເບີກຈ່າຍຂອງໃດ້')
                          ElevatedButton.icon(
                            onPressed: () => _navigateToConfirmDispatch(
                              order['doc_no'].toString(),
                            ),
                            icon: const Icon(
                              Icons.check_circle_outline,
                              color: Colors.white,
                              size: 20,
                            ),
                            label: const Text(
                              "ຢືນຢັນການເບີກຈ່າຍ",
                              style: TextStyle(
                                fontFamily: 'NotoSansLao',
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  _statusReadyToDispatchColor, // Red for urgent action
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              elevation: 3,
                            ),
                          ),
                        if (status == 'ສຳເລັດ')
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PrintImage(
                                    doc_no: order['doc_no'].toString(),
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(
                              Icons.print,
                              color: Colors.white,
                              size: 20,
                            ),
                            label: const Text(
                              "ພິມບິນ",
                              style: TextStyle(
                                fontFamily: 'NotoSansLao',
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  _primaryColor, // Primary blue for print
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              elevation: 3,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Helper widget for detail rows
  Widget _buildDetailRow({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 6.0,
      ), // Slightly more vertical padding
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: _accentColor), // Slightly larger icon
          const SizedBox(width: 10), // More spacing
          Text(
            '$label: ',
            style: TextStyle(
              fontFamily: 'NotoSansLao',
              fontSize: 15, // Slightly larger font
              color: _textColorSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontFamily: 'NotoSansLao',
                fontSize: 15, // Slightly larger font
                color: _textColorPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
