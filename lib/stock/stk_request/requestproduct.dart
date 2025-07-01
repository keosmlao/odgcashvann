import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart'; // For rich icons

import '../../utility/my_constant.dart';
import 'regestproductdetail.dart';
import 'requestpage.dart'; // The page for creating a new request
import '../../utility/app_colors.dart'; // Ensure this import points to your AppColors file

class RequestProduct extends StatefulWidget {
  const RequestProduct({super.key});

  @override
  State<RequestProduct> createState() => _RequestProductState();
}

class _RequestProductState extends State<RequestProduct> {
  TextEditingController _dateController = TextEditingController();
  List<dynamic> _requests = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Define consistent color palette for 'blue soft' theme - Using AppColors directly now
  // final Color _primaryColor = const Color(0xFF64B5F6);
  // final Color _accentColor = const Color(0xFF2196F3);
  // final Color _backgroundColor = const Color(0xFFE3F2FD);
  // final Color _cardColor = Colors.white;
  // final Color _textColorPrimary = const Color(0xFF212121);
  // final Color _textColorSecondary = const Color(0xFF757575);
  // final Color _successColor = const Color(0xFF4CAF50);
  // final Color _pendingColor = const Color(0xFFFFC107);
  // final Color _errorColor = const Color(0xFFEF5350);
  // final Color _actionButtonColor = const Color(0xFF1565C0);
  // final Color _infoChipColorFrom = const Color(0xFF42A5F5);
  // final Color _infoChipColorTo = const Color(0xFF4CAF50);

  @override
  void initState() {
    super.initState();
    _dateController.text = DateFormat('dd-MM-yyyy').format(DateTime.now());
    _fetchRequests();
  }

  @override
  void dispose() {
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _fetchRequests() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    SharedPreferences preferences = await SharedPreferences.getInstance();
    String? whCode = preferences.getString('wh_code');

    if (whCode == null || whCode.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'ບໍ່ພົບລະຫັດສາງ. ກະລຸນາເຂົ້າສູ່ລະບົບໃໝ່.';
      });
      _showSnackBar(_errorMessage!, AppColors.errorColor);
      return;
    }

    try {
      final response = await http.get(
        Uri.parse("${MyConstant().domain}/listrequestVansale/$whCode"),
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        setState(() {
          _requests = result['list'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'ໂຫຼດລາຍການຂໍໂອນບໍ່ສຳເລັດ: ${response.statusCode}';
        });
        _showSnackBar(_errorMessage!, AppColors.errorColor);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'ເກີດຂໍ້ຜິດພາດໃນການໂຫຼດຂໍ້ມູນ: $e';
      });
      _showSnackBar('ເກີດຂໍ້ຜິດພາດໃນການໂຫຼດຂໍ້ມູນ: $e', AppColors.errorColor);
      print("Error fetching requests: $e");
    }
  }

  Future<void> _deleteRequest(String id) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Center(
          child: CircularProgressIndicator(color: AppColors.primaryBlue),
        );
      },
    );

    try {
      final response = await http.get(
        Uri.parse("${MyConstant().domain}/delete_reqest_tf/$id"),
      );
      Navigator.pop(context); // Dismiss loading dialog

      if (response.statusCode == 200) {
        _showSnackBar('ລົບລາຍການສຳເລັດແລ້ວ', AppColors.successColor);
        _fetchRequests(); // Refresh the list
      } else {
        _showSnackBar(
          'ລົບລາຍການບໍ່ສຳເລັດ: ${response.statusCode}',
          AppColors.errorColor,
        );
      }
    } catch (e) {
      Navigator.pop(context); // Dismiss loading dialog
      _showSnackBar('ເກີດຂໍ້ຜິດພາດໃນການລົບລາຍການ: $e', AppColors.errorColor);
      print("Error deleting request: $e");
    }
  }

  void _showSnackBar(String message, Color color) {
    if (mounted) {
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 12.0,
            vertical: 8.0,
          ), // Reduced horizontal & vertical padding
          child: Column(
            children: [
              // --- Header: Title, Date Filter, and Refresh ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      "ລາຍການຂໍໂອນສິນຄ້າ",
                      style: TextStyle(
                        fontFamily: 'NotoSansLao',
                        fontSize: 20, // Reduced font size
                        fontWeight: FontWeight.bold,
                        color: AppColors.textColorPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8), // Reduced spacing
                  // Date Filter Button
                  _buildDateFilterButton(),
                  const SizedBox(width: 8), // Reduced spacing
                  // Refresh Button
                  IconButton(
                    icon: Icon(
                      Icons.refresh,
                      color: AppColors.accentBlue,
                      size: 26, // Reduced icon size
                    ),
                    onPressed: _fetchRequests,
                    tooltip: 'ໂຫຼດຂໍ້ມູນໃໝ່',
                  ),
                ],
              ),
              const SizedBox(height: 12), // Reduced spacing
              // --- Request List Section ---
              Expanded(child: _buildRequestListContent()),
              const SizedBox(height: 12), // Reduced spacing
              // --- Main Action Button: Create New Request ---
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.actionButtonColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                    ), // Reduced vertical padding
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        10,
                      ), // Reduced border radius
                    ),
                    elevation: 4, // Reduced elevation
                  ),
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RequestPage(),
                      ),
                    );
                    _fetchRequests();
                  },
                  icon: const Icon(
                    Icons.add_circle_outline,
                    color: Colors.white,
                    size: 18, // Reduced icon size
                  ),
                  label: const Text(
                    "ສ້າງໃບຂໍໂອນສິນຄ້າໃໝ່",
                    style: TextStyle(
                      fontFamily: 'NotoSansLao',
                      fontSize: 16, // Reduced font size
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Widget for Date Filter Button ---
  Widget _buildDateFilterButton() {
    return InkWell(
      onTap: () async {
        DateTime? pickedDate = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
          builder: (context, child) {
            return Theme(
              data: ThemeData.light().copyWith(
                colorScheme: ColorScheme.light(
                  primary: AppColors.primaryBlue, // Themed primary color
                  onPrimary: Colors.white,
                  onSurface: AppColors.textColorPrimary,
                ),
                textButtonTheme: TextButtonThemeData(
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.accentBlue,
                  ),
                ),
                dialogBackgroundColor: AppColors.cardColor,
              ),
              child: child!,
            );
          },
        );
        if (pickedDate != null) {
          setState(() {
            _dateController.text = DateFormat('dd-MM-yyyy').format(pickedDate);
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 6,
        ), // Further reduced padding
        decoration: BoxDecoration(
          color: AppColors.cardColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Colors.grey.shade300,
            width: 0.8,
          ), // Thinner border
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 3, // Reduced blur
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_month, color: AppColors.accentBlue, size: 20),
            const SizedBox(width: 6),
            Text(
              _dateController.text,
              style: TextStyle(
                fontFamily: 'NotoSansLao',
                fontSize: 14, // Reduced font size
                color: AppColors.textColorPrimary,
              ),
            ),
            Icon(
              Icons.arrow_drop_down,
              color: AppColors.textColorSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  // --- Widget for Request List Content (handles states) ---
  Widget _buildRequestListContent() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.primaryBlue),
            const SizedBox(height: 10), // Reduced spacing
            Text(
              'ກຳລັງໂຫຼດລາຍການຂໍໂອນ...',
              style: TextStyle(
                fontFamily: 'NotoSansLao',
                color: AppColors.textColorSecondary,
                fontSize: 14, // Reduced font size
              ),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0), // Reduced padding
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 50, color: AppColors.errorColor),
              const SizedBox(height: 12),
              Text(
                'ເກີດຂໍ້ຜິດພາດ: $_errorMessage',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'NotoSansLao',
                  color: AppColors.errorColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _fetchRequests,
                icon: const Icon(Icons.refresh, color: Colors.white, size: 20),
                label: const Text(
                  'ລອງໃໝ່',
                  style: TextStyle(
                    fontFamily: 'NotoSansLao',
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
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
      );
    }

    if (_requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 70,
              color: Colors.blue.shade200,
            ),
            const SizedBox(height: 16),
            Text(
              'ບໍ່ມີລາຍການຂໍໂອນສິນຄ້າ.',
              style: TextStyle(
                fontFamily: 'NotoSansLao',
                color: AppColors.textColorSecondary,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'ກົດປຸ່ມ "ສ້າງໃບຂໍໂອນສິນຄ້າໃໝ່" ເພື່ອເລີ່ມຕົ້ນ.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'NotoSansLao',
                color: AppColors.textColorSecondary.withOpacity(0.7),
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _requests.length,
      padding: const EdgeInsets.symmetric(
        vertical: 4.0,
      ), // Reduced overall vertical padding
      itemBuilder: (context, index) {
        final request = _requests[index];
        Color statusColor = _getStatusColor(request['doc_status']);
        bool canDelete = request['doc_status'] == 'ລໍຖ້າອະນຸມັດ';

        return Card(
          elevation: 3, // Slightly reduced elevation
          margin: const EdgeInsets.symmetric(
            vertical: 6,
          ), // Reduced vertical margin
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12), // Reduced border radius
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ReqestProductDetail(
                    doc_no: request['doc_no'],
                    doc_date: request['doc_date'],
                    wh_code: request['wh_from'],
                    sh_code: request['location_from'],
                    edit_status: canDelete ? '0' : '1',
                  ),
                ),
              );
              _fetchRequests();
            },
            onLongPress: canDelete
                ? () => _handleDeletePrompt(
                    context,
                    request['doc_status'],
                    request['doc_no'],
                  )
                : null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- Card Header: Doc No, Date, Status ---
                Container(
                  padding: const EdgeInsets.fromLTRB(
                    12,
                    10,
                    12,
                    6,
                  ), // Reduced padding
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1), // Reduced opacity
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.grey.shade200,
                        width: 0.8,
                      ), // Thinner border
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'ໃບຂໍໂອນ: ${request['doc_no']}',
                              style: TextStyle(
                                fontFamily: 'NotoSansLao',
                                fontWeight: FontWeight.bold,
                                fontSize: 17, // Reduced font size
                                color: AppColors.textColorPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4, // Reduced vertical padding
                            ),
                            decoration: BoxDecoration(
                              color: statusColor,
                              borderRadius: BorderRadius.circular(
                                16,
                              ), // Slightly smaller border radius
                            ),
                            child: Text(
                              request['doc_status'],
                              style: const TextStyle(
                                fontFamily: 'NotoSansLao',
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12, // Reduced font size
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3), // Reduced spacing
                      Text(
                        'ວັນທີ: ${request['doc_date']}',
                        style: TextStyle(
                          fontFamily: 'NotoSansLao',
                          color: AppColors.textColorSecondary,
                          fontSize: 12, // Reduced font size
                        ),
                      ),
                    ],
                  ),
                ),

                // --- Transfer Flow Section ---
                Padding(
                  padding: const EdgeInsets.all(12), // Reduced padding
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildWarehouseInfo(
                            label: "ຈາກສາງ",
                            wh: request['wh_from'],
                            location: request['location_from'],
                            color: AppColors.infoChipColorFrom,
                            icon: FontAwesomeIcons.warehouse,
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6.0,
                            ),
                            child: FaIcon(
                              FontAwesomeIcons.solidArrowAltCircleRight,
                              size: 24, // Reduced icon size
                              color: AppColors.textColorSecondary,
                            ),
                          ),
                          _buildWarehouseInfo(
                            label: "ຫາສາງ",
                            wh: request['wh_to'],
                            location: request['location_to'],
                            color: AppColors.infoChipColorTo,
                            icon: FontAwesomeIcons.truckFast,
                          ),
                        ],
                      ),
                      if (request['remark'] != null &&
                          request['remark'].isNotEmpty) ...[
                        const SizedBox(height: 10), // Reduced spacing
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FaIcon(
                              FontAwesomeIcons.noteSticky,
                              size: 16,
                              color: AppColors.textColorSecondary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'ໝາຍເຫດ: ${request['remark']}',
                                style: TextStyle(
                                  fontFamily: 'NotoSansLao',
                                  color: AppColors.textColorSecondary,
                                  fontSize: 12, // Reduced font size
                                  fontStyle: FontStyle.italic,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                // --- Footer: Creator Info ---
                Container(
                  padding: const EdgeInsets.fromLTRB(
                    12,
                    6,
                    12,
                    10,
                  ), // Reduced padding
                  decoration: BoxDecoration(
                    color: AppColors.backgroundColor,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                  ),
                  child: Align(
                    alignment: Alignment.bottomRight,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FaIcon(
                          FontAwesomeIcons.userPen,
                          size: 14, // Reduced icon size
                          color: AppColors.textColorSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'ຜູ້ຂໍໂອນ: ${request['creator_code']}',
                          style: TextStyle(
                            fontFamily: 'NotoSansLao',
                            color: AppColors.textColorSecondary,
                            fontSize: 11, // Reduced font size
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- Helper widget for Warehouse Info Columns ---
  Widget _buildWarehouseInfo({
    required String label,
    required String wh,
    required String location,
    required Color color,
    required IconData icon,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              FaIcon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'NotoSansLao',
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            'ສາງ: $wh',
            style: TextStyle(
              fontFamily: 'NotoSansLao',
              color: AppColors.textColorPrimary,
              fontSize: 12,
            ),
          ),
          Text(
            'ທີ່ເກັບ: $location',
            style: TextStyle(
              fontFamily: 'NotoSansLao',
              color: AppColors.textColorPrimary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // --- Helper function for Status Color ---
  Color _getStatusColor(String status) {
    switch (status) {
      case 'ລໍຖ້າອະນຸມັດ':
        return AppColors.pendingColor; // Amber
      case 'ອະນຸມັດແລ້ວ':
        return AppColors.successColor; // Green
      case 'ປະຕິເສດ':
        return AppColors.errorColor; // Red
      default:
        return AppColors.textColorSecondary; // Grey for unknown
    }
  }

  // --- Helper function for Delete Confirmation Dialog ---
  void _handleDeletePrompt(BuildContext context, String status, String docNo) {
    if (status == 'ລໍຖ້າອະນຸມັດ') {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: Text(
            "ຢືນຢັນການລົບ",
            style: TextStyle(
              fontFamily: 'NotoSansLao',
              fontWeight: FontWeight.bold,
              color: AppColors.errorColor,
            ),
          ),
          content: Text(
            "ທ່ານແນ່ໃຈບໍ່ວ່າຕ້ອງການລົບໃບຂໍໂອນເລກທີ $docNo ນີ້?\n(ການກະທຳນີ້ບໍ່ສາມາດກັບຄືນໄດ້)",
            style: TextStyle(
              fontFamily: 'NotoSansLao',
              fontSize: 13,
              color: AppColors.textColorPrimary,
            ),
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () {
                Navigator.pop(context);
                _deleteRequest(docNo);
              },
              child: Text(
                'ລົບເລີຍ',
                style: TextStyle(
                  fontFamily: 'NotoSansLao',
                  color: AppColors.errorColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'ຍົກເລີກ',
                style: TextStyle(
                  fontFamily: 'NotoSansLao',
                  color: AppColors.accentBlue,
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: Text(
            "ບໍ່ສາມາດລົບໄດ້",
            style: TextStyle(
              fontFamily: 'NotoSansLao',
              fontWeight: FontWeight.bold,
              color: AppColors.primaryBlue,
            ),
          ),
          content: Text(
            "ໃບຂໍໂອນເລກທີ $docNo ມີການເຄື່ອນໄຫວແລ້ວ, ບໍ່ສາມາດລົບໄດ້.",
            style: TextStyle(
              fontFamily: 'NotoSansLao',
              fontSize: 13,
              color: AppColors.textColorPrimary,
            ),
          ),
          actions: [
            CupertinoDialogAction(
              isDefaultAction: true,
              textStyle: TextStyle(
                fontFamily: 'NotoSansLao',
                color: AppColors.primaryBlue,
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text('ຕົກລົງ'),
            ),
          ],
        ),
      );
    }
  }
}
