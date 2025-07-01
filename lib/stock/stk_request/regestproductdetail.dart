import 'dart:convert';
import 'package:flutter/cupertino.dart'; // For CupertinoAlertDialog
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // Use http alias for clarity
import 'package:odgcashvan/utility/my_constant.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart'; // For FontAwesomeIcons

import '../../utility/app_colors.dart'; // Import your AppColors
import 'editqty.dart';
import 'productforeditrequest.dart';

class ReqestProductDetail extends StatefulWidget {
  final String doc_no;
  final String wh_code;
  final String sh_code;
  final String doc_date;
  final String edit_status; // '0' for editable, '1' for read-only

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

class _ReqestProductDetailState extends State<ReqestProductDetail> {
  bool _isEditingMode = false;
  List<dynamic> _requestItems = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Set initial editing mode based on edit_status from widget
    _isEditingMode = widget.edit_status == '0';
    _fetchRequestDetails();
  }

  Future<void> _fetchRequestDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http.get(
        Uri.parse(
          "${MyConstant().domain}/listrequestVansaledetail/${widget.doc_no}",
        ),
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        setState(() {
          _requestItems = result['list'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'ໂຫຼດລາຍການສິນຄ້າບໍ່ສຳເລັດ: ${response.statusCode}';
        });
        _showSnackBar(_errorMessage!, AppColors.errorColor);
        print("Server error: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'ເກີດຂໍ້ຜິດພາດໃນການໂຫຼດຂໍ້ມູນ: $e';
      });
      _showSnackBar('ເກີດຂໍ້ຜິດພາດໃນການໂຫຼດຂໍ້ມູນ: $e', AppColors.errorColor);
      print("Network error: $e");
    }
  }

  Future<void> _deleteItem(String rowId) async {
    // Show a small, non-blocking loading indicator
    final overlay = OverlayEntry(
      builder: (context) => Center(
        child: CircularProgressIndicator(color: AppColors.primaryBlue),
      ),
    );
    Overlay.of(context).insert(overlay);

    try {
      final response = await http.get(
        Uri.parse("${MyConstant().domain}/deleteiteminrequeststk/$rowId"),
      );
      overlay.remove(); // Dismiss loading indicator

      if (response.statusCode == 200) {
        _showSnackBar('ລົບລາຍການສຳເລັດແລ້ວ', AppColors.successColor);
        _fetchRequestDetails(); // Refresh the list
      } else {
        _showSnackBar(
          'ລົບລາຍການບໍ່ສຳເລັດ: ${response.statusCode}',
          AppColors.errorColor,
        );
        print(
          "Server error on delete: ${response.statusCode} - ${response.body}",
        );
      }
    } catch (e) {
      overlay.remove(); // Dismiss loading indicator
      _showSnackBar('ເກີດຂໍ້ຜິດພາດໃນການລົບລາຍການ: $e', AppColors.errorColor);
      print("Network error on delete: $e");
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
              color: AppColors.white,
            ),
          ),
          backgroundColor: color,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _confirmDeleteItem(String rowId, String itemName) {
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
          "ທ່ານແນ່ໃຈບໍ່ວ່າຕ້ອງການລົບສິນຄ້າ '$itemName' ອອກຈາກໃບຂໍໂອນນີ້?",
          style: TextStyle(
            fontFamily: 'NotoSansLao',
            fontSize: 13, // Reduced font size
            color: AppColors.textColorPrimary,
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              _deleteItem(rowId);
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
            onPressed: () => Navigator.pop(context), // Close dialog
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: Text(
          "ໃບຂໍໂອນ: ${widget.doc_no}",
          style: const TextStyle(
            color: AppColors.white,
            fontFamily: 'NotoSansLao',
            fontWeight: FontWeight.bold,
            fontSize: 18, // Reduced font size
          ),
        ),
        actions: [
          if (widget.edit_status ==
              '0') // Only show edit button if allowed to edit
            IconButton(
              onPressed: () {
                setState(() {
                  _isEditingMode = !_isEditingMode; // Toggle editing mode
                });
                _showSnackBar(
                  _isEditingMode ? 'ໂໝດແກ້ໄຂ: ເປີດ' : 'ໂໝດແກ້ໄຂ: ປິດ',
                  _isEditingMode
                      ? AppColors.accentBlue
                      : AppColors.textColorSecondary,
                );
              },
              icon: Icon(
                _isEditingMode
                    ? Icons.check_circle_outline
                    : Icons.edit_outlined,
                color: AppColors.white,
                size: 22, // Reduced icon size
              ),
              tooltip: _isEditingMode ? 'ສິ້ນສຸດການແກ້ໄຂ' : 'ແກ້ໄຂລາຍການ',
            ),
        ],
        backgroundColor: AppColors.accentBlue,
        centerTitle: true,
        elevation: 0,
      ),
      floatingActionButton: _isEditingMode
          ? FloatingActionButton.extended(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProductForEditRequest(
                      wh_code: widget.wh_code,
                      sh_code: widget.sh_code,
                      doc_no: widget.doc_no,
                      doc_date: widget.doc_date,
                    ),
                  ),
                );
                _fetchRequestDetails(); // Refresh data after adding product
              },
              label: const Text(
                'ເພີ່ມສິນຄ້າ',
                style: TextStyle(
                  fontFamily: 'NotoSansLao',
                  color: AppColors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14, // Reduced font size
                ),
              ),
              icon: const Icon(
                Icons.add_shopping_cart,
                color: AppColors.white,
                size: 20,
              ), // Reduced icon size
              backgroundColor: AppColors.actionButtonColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ), // Reduced border radius
            )
          : null,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.primaryBlue),
            const SizedBox(height: 12), // Reduced spacing
            Text(
              'ກຳລັງໂຫຼດລາຍການສິນຄ້າ...',
              style: TextStyle(
                fontFamily: 'NotoSansLao',
                color: AppColors.textColorSecondary,
                fontSize: 15, // Reduced font size
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
              Icon(
                Icons.error_outline,
                size: 50, // Reduced icon size
                color: AppColors.errorColor,
              ),
              const SizedBox(height: 12), // Reduced spacing
              Text(
                'ເກີດຂໍ້ຜິດພາດ: $_errorMessage',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'NotoSansLao',
                  color: AppColors.errorColor,
                  fontSize: 15, // Reduced font size
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16), // Reduced spacing
              ElevatedButton.icon(
                onPressed: _fetchRequestDetails,
                icon: const Icon(
                  Icons.refresh,
                  color: AppColors.white,
                  size: 20,
                ), // Reduced icon size
                label: const Text(
                  'ລອງໃໝ່',
                  style: TextStyle(
                    fontFamily: 'NotoSansLao',
                    color: AppColors.white,
                    fontSize: 15, // Reduced font size
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

    if (_requestItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_bag_outlined,
              size: 70, // Reduced icon size
              color: AppColors.grey300,
            ),
            const SizedBox(height: 16), // Reduced spacing
            Text(
              'ບໍ່ມີສິນຄ້າໃນໃບຂໍໂອນນີ້.',
              style: TextStyle(
                fontFamily: 'NotoSansLao',
                color: AppColors.textColorSecondary,
                fontSize: 16, // Reduced font size
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6), // Reduced spacing
            if (_isEditingMode)
              Text(
                'ກົດປຸ່ມ "+" ເພື່ອເພີ່ມສິນຄ້າ.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'NotoSansLao',
                  color: AppColors.textColorSecondary.withOpacity(0.7),
                  fontSize: 13, // Reduced font size
                ),
              ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8.0), // Reduced overall padding
      itemCount: _requestItems.length,
      itemBuilder: (context, index) {
        final item = _requestItems[index];
        final String rowId = item['roworder'].toString();
        final String itemName = item['item_name'] ?? 'ບໍ່ມີຊື່';

        return Card(
          elevation: 2, // Reduced elevation
          margin: const EdgeInsets.symmetric(
            vertical: 6.0,
          ), // Reduced vertical margin
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12), // Reduced border radius
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0), // Reduced padding
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            itemName,
                            style: const TextStyle(
                              fontFamily: 'NotoSansLao',
                              fontWeight: FontWeight.bold,
                              fontSize: 16, // Reduced font size
                              color: AppColors.textColorPrimary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3), // Reduced spacing
                          Text(
                            'ລະຫັດສິນຄ້າ: ${item['item_code'] ?? 'N/A'}',
                            style: TextStyle(
                              fontFamily: 'NotoSansLao',
                              fontSize: 12, // Reduced font size
                              color: AppColors.textColorSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8), // Reduced spacing
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'ຈຳນວນ',
                          style: TextStyle(
                            fontFamily: 'NotoSansLao',
                            fontSize: 11, // Reduced font size
                            color: AppColors.textColorSecondary,
                          ),
                        ),
                        Text(
                          '${item['qty']} ${item['unit_code'] ?? 'N/A'}',
                          style: const TextStyle(
                            fontFamily: 'NotoSansLao',
                            fontWeight: FontWeight.bold,
                            fontSize: 16, // Reduced font size
                            color: AppColors.accentBlue,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (_isEditingMode) ...[
                  const Divider(
                    height: 20,
                    thickness: 0.8,
                  ), // Reduced height and thickness
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditQty(
                                wh_code: widget.wh_code,
                                sh_code: widget.sh_code,
                                ic_code: item['item_code'].toString(),
                                qty: item['qty'].toString(),
                                unit_code: item['unit_code'].toString(),
                                doc_no: widget.doc_no,
                              ),
                            ),
                          );
                          _fetchRequestDetails(); // Refresh data after editing
                        },
                        icon: const Icon(
                          Icons.edit,
                          size: 18,
                          color: AppColors.primaryBlue,
                        ), // Reduced icon size
                        label: const Text(
                          "ແກ້ໃຂ",
                          style: TextStyle(
                            fontFamily: 'NotoSansLao',
                            color: AppColors.primaryBlue,
                            fontWeight: FontWeight.bold,
                            fontSize: 13, // Reduced font size
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue.withOpacity(
                            0.08,
                          ), // Reduced opacity
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              6,
                            ), // Reduced border radius
                            side: BorderSide(
                              color: AppColors.primaryBlue.withOpacity(0.3),
                            ), // Reduced opacity
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ), // Reduced padding
                        ),
                      ),
                      const SizedBox(width: 8), // Reduced spacing
                      ElevatedButton.icon(
                        onPressed: () => _confirmDeleteItem(rowId, itemName),
                        icon: const Icon(
                          Icons.delete_forever,
                          size: 18,
                          color: AppColors.errorColor,
                        ), // Reduced icon size
                        label: const Text(
                          "ລົບ",
                          style: TextStyle(
                            fontFamily: 'NotoSansLao',
                            color: AppColors.errorColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 13, // Reduced font size
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.errorColor.withOpacity(
                            0.08,
                          ), // Reduced opacity
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              6,
                            ), // Reduced border radius
                            side: BorderSide(
                              color: AppColors.errorColor.withOpacity(0.3),
                            ), // Reduced opacity
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ), // Reduced padding
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
