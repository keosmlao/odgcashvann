import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:odgcashvan/stock/stk_request/listproductforrequest.dart';
import '../../database/sql_helper.dart';
import '../listlocation.dart';
import '../liststock.dart';
import 'requestStockSelect.dart';

class RequestPage extends StatefulWidget {
  const RequestPage({super.key});

  @override
  State<RequestPage> createState() => _RequestPageState();
}

class _RequestPageState extends State<RequestPage> {
  List<Map<String, dynamic>> _draftProducts = [];
  String? _selectedWhCode = '';
  String? _selectedShCode = '';
  final TextEditingController _whNameController = TextEditingController();
  final TextEditingController _shNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _refreshDraftProducts();
  }

  @override
  void dispose() {
    _whNameController.dispose();
    _shNameController.dispose();
    super.dispose();
  }

  Future<void> _refreshDraftProducts() async {
    final data = await SQLHelper.getDratRpstock();
    setState(() {
      _draftProducts = data;
    });
  }

  void _showAppDialog({
    required String title,
    required String content,
    required List<Widget> actions,
  }) {
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(content),
        actions: actions,
      ),
    );
  }

  Widget _buildDialogButton(
    String text,
    VoidCallback onPressed, {
    Color? textColor,
    bool isDefaultAction = false,
    bool isDestructiveAction = false,
  }) {
    return CupertinoDialogAction(
      isDefaultAction: isDefaultAction,
      isDestructiveAction: isDestructiveAction,
      onPressed: onPressed,
      child: Text(text, style: TextStyle(color: textColor)),
    );
  }

  void _deleteDraftItem(int id) async {
    await SQLHelper.deleteRegestItem(id);
    _refreshDraftProducts();
  }

  @override
  Widget build(BuildContext context) {
    final bool isLocationSelected =
        _selectedWhCode != null &&
        _selectedWhCode!.isNotEmpty &&
        _selectedShCode != null &&
        _selectedShCode!.isNotEmpty;
    final bool hasDraftProducts = _draftProducts.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "ໂອນສິນຄ້າເຂົ້າລົດ",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18, // Further reduced app bar title
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.blue.shade700,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (hasDraftProducts) {
              _showAppDialog(
                title: "ຄຳເຕືອນ",
                content: "ມີລາຍການສິນຄ້າທີ່ຍັງບໍ່ໄດ້ບັນທຶກ, ຕ້ອງການອອກບໍ?",
                actions: [
                  _buildDialogButton(
                    "ຍົກເລີກ",
                    () => Navigator.pop(context),
                    isDefaultAction: true,
                  ),
                  _buildDialogButton(
                    "ອອກ",
                    () => Navigator.of(context).pop(true),
                    textColor: Colors.red,
                    isDestructiveAction: true,
                  ),
                ],
              );
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildLocationSelectionSection(),
          const SizedBox(height: 12), // Reduced spacing
          _buildProductListHeader(),
          const SizedBox(height: 8), // Reduced spacing
          Expanded(
            child: hasDraftProducts
                ? _buildDraftProductList()
                : _buildEmptyState(),
          ),
          _buildActionButtons(isLocationSelected, hasDraftProducts),
        ],
      ),
    );
  }

  // --- Widget Builders for Sections ---

  Widget _buildLocationSelectionSection() {
    return Container(
      padding: const EdgeInsets.all(10.0), // Further reduced padding
      color: Colors.blue.shade50,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "ຂໍ້ມູນສາງ ແລະ ທີ່ເກັບ",
            style: TextStyle(
              fontSize: 15, // Further reduced font
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade800,
            ),
          ),
          const SizedBox(height: 10), // Further reduced spacing
          _buildLocationInputField(
            context: context,
            label: "ສາງ",
            controller: _whNameController,
            icon: Icons.warehouse_outlined,
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ListSock()),
              );
              if (result != null) {
                setState(() {
                  _whNameController.text = result['name_1'];
                  _selectedWhCode = result['code'];
                  _shNameController.clear();
                  _selectedShCode = '';
                });
                _refreshDraftProducts();
              }
            },
          ),
          const SizedBox(height: 10), // Further reduced spacing
          _buildLocationInputField(
            context: context,
            label: "ພື້ນທີ່ຈັດເກັບ",
            controller: _shNameController,
            icon: Icons.storage_outlined,
            onTap: () async {
              if (_selectedWhCode == null || _selectedWhCode!.isEmpty) {
                _showAppDialog(
                  title: "ຄຳເຕືອນ",
                  content: "ກະລຸນາເລືອກສາງກ່ອນ",
                  actions: [
                    _buildDialogButton("OK", () => Navigator.pop(context)),
                  ],
                );
                return;
              }
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ListLocation(wh_codes: _selectedWhCode!),
                ),
              );
              if (result != null) {
                setState(() {
                  _shNameController.text = result['name_1'];
                  _selectedShCode = result['code'];
                });
                _refreshDraftProducts();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLocationInputField({
    required BuildContext context,
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13, // Further reduced font
            color: Colors.blue.shade800,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4), // Further reduced spacing
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 10,
            ), // Further reduced padding
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.shade50.withOpacity(0.5),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: Colors.blue.shade600,
                  size: 20,
                ), // Further reduced icon size
                const SizedBox(width: 8), // Further reduced spacing
                Expanded(
                  child: Text(
                    controller.text.isEmpty ? 'ກະລຸນາເລືອກ' : controller.text,
                    style: TextStyle(
                      fontSize: 14, // Further reduced font
                      color: controller.text.isEmpty
                          ? Colors.grey.shade600
                          : Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey.shade400,
                  size: 14,
                ), // Further reduced icon size
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProductListHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          Expanded(child: Divider(thickness: 1, color: Colors.grey.shade300)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Text(
              "ລາຍການສິນຄ້າທີ່ເລືອກ",
              style: TextStyle(
                fontSize: 15, // Further reduced font
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(child: Divider(thickness: 1, color: Colors.grey.shade300)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 60, // Further reduced icon size
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 10), // Further reduced spacing
          const Text(
            "ຍັງບໍ່ມີລາຍການສິນຄ້າທີ່ຖືກເພີ່ມ",
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey,
            ), // Further reduced font
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6), // Further reduced spacing
          Text(
            "ກະລຸນາເລືອກສາງ ແລະ ພື້ນທີ່ຈັດເກັບ\nເພື່ອເລີ່ມເພີ່ມສິນຄ້າ",
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ), // Further reduced font
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDraftProductList() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      itemCount: _draftProducts.length,
      separatorBuilder: (context, index) => const Divider(
        height: 10, // Further reduced space between items
        thickness: 0.5,
        color: Colors.grey,
        indent: 10,
        endIndent: 10,
      ),
      itemBuilder: (context, index) {
        final item = _draftProducts[index];
        return Dismissible(
          key: Key(item['id'].toString()),
          direction: DismissDirection.endToStart,
          background: Container(
            color: Colors.red.shade600,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: const Icon(
              Icons.delete,
              color: Colors.white,
              size: 26,
            ), // Further reduced icon size
          ),
          confirmDismiss: (direction) async {
            return await showCupertinoDialog(
              context: context,
              builder: (BuildContext context) {
                return CupertinoAlertDialog(
                  title: const Text("ຢືນຢັນການລົບ"),
                  content: Text("ຕ້ອງການລົບລາຍການ ${item['item_name']} ນີ້ບໍ?"),
                  actions: <Widget>[
                    _buildDialogButton(
                      "ຍົກເລີກ",
                      () => Navigator.of(context).pop(false),
                      isDefaultAction: true,
                    ),
                    _buildDialogButton(
                      "ລົບ",
                      () => Navigator.of(context).pop(true),
                      textColor: Colors.red,
                      isDestructiveAction: true,
                    ),
                  ],
                );
              },
            );
          },
          onDismissed: (direction) {
            _deleteDraftItem(item['id']);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${item['item_name']} ຖືກລົບແລ້ວ'),
                backgroundColor: Colors.red,
              ),
            );
          },
          child: _buildProductListItem(item),
        );
      },
    );
  }

  Widget _buildProductListItem(Map<String, dynamic> item) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 6,
        horizontal: 8,
      ), // Further reduced padding
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            backgroundColor: Colors.blue.shade100,
            radius: 20, // Further reduced radius
            child: Icon(
              Icons.inventory_outlined,
              size: 24, // Further reduced icon size
              color: Colors.blue.shade600,
            ),
          ),
          const SizedBox(width: 10), // Further reduced spacing
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['item_name'],
                  style: const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 15, // Further reduced font size
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3), // Further reduced spacing
                Text(
                  "Barcode: ${item['barcode'].isEmpty ? 'ບໍພົບ Barcode' : item['barcode']}",
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontSize: 12, // Further reduced font size
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 1), // Further reduced spacing
                Text(
                  "ລະຫັດ: ${item['item_code']}",
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12, // Further reduced font size
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10), // Further reduced spacing
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 3,
                ), // Further reduced padding
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(
                    5,
                  ), // Further reduced border radius
                ),
                child: Text(
                  "${item['qty']}",
                  style: TextStyle(
                    fontSize: 18, // Further reduced font size
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                  ),
                ),
              ),
              const SizedBox(height: 2), // Further reduced spacing
              Text(
                item['unit_code'],
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                ), // Further reduced font size
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(bool isLocationSelected, bool hasDraftProducts) {
    return Container(
      padding: const EdgeInsets.all(10.0), // Further reduced padding
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            spreadRadius: 3,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isLocationSelected
                  ? () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ListProductForRequest(
                            wh_code: _selectedWhCode!,
                            sh_code: _selectedShCode!,
                          ),
                        ),
                      );
                      _refreshDraftProducts();
                    }
                  : () {
                      _showAppDialog(
                        title: "ຄຳເຕືອນ",
                        content: "ກະລຸນາເລືອກສາງ ແລະ ພື້ນທີ່ຈັດເກັບກ່ອນ.",
                        actions: [
                          _buildDialogButton(
                            "OK",
                            () => Navigator.pop(context),
                          ),
                        ],
                      );
                    },
              icon: const Icon(
                Icons.add_shopping_cart,
                size: 22,
              ), // Further reduced icon size
              label: const Text(
                "ເພີ່ມສິນຄ້າ",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ), // Further reduced font size
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isLocationSelected
                    ? Colors.green.shade600
                    : Colors.grey.shade400,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                ), // Further reduced padding
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: isLocationSelected ? 3 : 0,
              ),
            ),
          ),
          const SizedBox(height: 8), // Further reduced spacing
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: hasDraftProducts
                  ? () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RequestStockSelect(
                            wh_code: _selectedWhCode!,
                            sh_code: _selectedShCode!,
                          ),
                        ),
                      );
                      _refreshDraftProducts();
                    }
                  : null,
              icon: const Icon(
                Icons.save,
                size: 22,
              ), // Further reduced icon size
              label: const Text(
                "ບັນທຶກຄຳຂໍໂອນ",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ), // Further reduced font size
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: hasDraftProducts
                    ? Colors.blue.shade700
                    : Colors.grey.shade400,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                ), // Further reduced padding
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: hasDraftProducts ? 3 : 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
