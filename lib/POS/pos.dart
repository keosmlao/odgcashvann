// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:odgcashvan/POS/custlistforpos.dart';
// import 'package:odgcashvan/POS/stocksale.dart';
// import 'package:odgcashvan/Sale/payment/homepayment.dart';
// import 'package:odgcashvan/Sale/payment/kipPayment.dart';
// import 'package:odgcashvan/Sale/payment/payment.dart';
// import 'package:odgcashvan/database/sql_helper.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// class Pos extends StatefulWidget {
//   const Pos({super.key});

//   @override
//   State<Pos> createState() => _PosState();
// }

// class _PosState extends State<Pos> {
//   final TextEditingController cust_name = TextEditingController();
//   String? route_plan_id;
//   String cust_code = '', group_main = '', group_sub_1 = '';
//   double total_amount = 0.00;
//   List<Map<String, dynamic>> _journals = [];

//   Color get orange => const Color(0xFFFF6F3C);

//   @override
//   void initState() {
//     super.initState();
//     _refreshJournals();
//     findUser();
//   }

//   void findUser() async {
//     SharedPreferences preferences = await SharedPreferences.getInstance();
//     setState(() {
//       route_plan_id = preferences.getString('route_id').toString();
//     });
//   }

//   void _refreshJournals() async {
//     final data = await SQLHelper.getOrdersbtcust(cust_code.toString());
//     setState(() {
//       _journals = data;
//       total_amount = data.fold(
//         0.0,
//         (sum, item) => sum + double.parse(item['sum_amount']),
//       );
//     });
//   }

//   void _deleteItem(String id) async {
//     await SQLHelper.deleteItemOrder(id);
//     ScaffoldMessenger.of(
//       context,
//     ).showSnackBar(const SnackBar(content: Text('ລົບສິນຄ້າສໍາເລັດ')));
//     _refreshJournals();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey[100],
//       body: SafeArea(
//         child: Column(
//           children: [
//             // Header - Total Amount
//             Container(
//               width: double.infinity,
//               padding: const EdgeInsets.all(24),
//               decoration: BoxDecoration(
//                 color: orange,
//                 borderRadius: const BorderRadius.vertical(
//                   bottom: Radius.circular(24),
//                 ),
//                 boxShadow: [
//                   BoxShadow(color: orange.withOpacity(0.4), blurRadius: 10),
//                 ],
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   const Text(
//                     "ຍອດລວມ",
//                     style: TextStyle(color: Colors.white70, fontSize: 16),
//                   ),
//                   const SizedBox(height: 4),
//                   Text(
//                     NumberFormat('#,##0').format(total_amount),
//                     style: const TextStyle(
//                       fontSize: 40,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.white,
//                     ),
//                   ),
//                 ],
//               ),
//             ),

//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 16),
//               child: Card(
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: Padding(
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 16,
//                     vertical: 12,
//                   ),
//                   child: Column(
//                     children: [
//                       Row(
//                         children: [
//                           Icon(Icons.person, color: orange),
//                           const SizedBox(width: 8),
//                           Expanded(
//                             child: Text(
//                               cust_code == ''
//                                   ? "ກົດເພື່ອເລືອກລູກຄ້າ"
//                                   : "ລູກຄ້າ: ${cust_name.text}",
//                               style: const TextStyle(fontSize: 16),
//                             ),
//                           ),
//                           if (route_plan_id != '')
//                             TextButton(
//                               onPressed: _selectCustomer,
//                               child: Text(
//                                 cust_code == '' ? "ເລືອກ" : "ແກ້ໄຂ",
//                                 style: const TextStyle(color: Colors.blue),
//                               ),
//                             ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),

//             if (cust_code != '')
//               Padding(
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 16,
//                   vertical: 8,
//                 ),
//                 child: Card(
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   color: orange.withOpacity(0.05),
//                   child: ListTile(
//                     leading: Icon(Icons.add_shopping_cart, color: orange),
//                     title: const Text("ເພີ່ມສິນຄ້າ"),
//                     onTap: _goToStock,
//                   ),
//                 ),
//               ),

//             // Product List
//             Expanded(
//               child: _journals.isEmpty
//                   ? const Center(child: Text("ບໍພົບລາຍການສິນຄ້າ"))
//                   : ListView.builder(
//                       padding: const EdgeInsets.symmetric(horizontal: 16),
//                       itemCount: _journals.length,
//                       itemBuilder: (context, index) {
//                         final item = _journals[index];
//                         return Card(
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(16),
//                           ),
//                           elevation: 3,
//                           margin: const EdgeInsets.symmetric(vertical: 6),
//                           child: ListTile(
//                             contentPadding: const EdgeInsets.all(16),
//                             title: Text(
//                               item['item_name'],
//                               style: const TextStyle(
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                             subtitle: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Text("Barcode: ${item['barcode'] ?? "-"}"),
//                                 Text(
//                                   "Qty: ${item['qty']} ${item['unit_code']}",
//                                 ),
//                                 Text(
//                                   "ລາຄາລວມ: ${NumberFormat('#,##0').format(double.parse(item['sum_amount']))} ₭",
//                                   style: const TextStyle(
//                                     fontWeight: FontWeight.w600,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                             trailing: IconButton(
//                               icon: const Icon(
//                                 Icons.delete,
//                                 color: Colors.redAccent,
//                               ),
//                               onPressed: () =>
//                                   _deleteItem(item['item_code'].toString()),
//                             ),
//                           ),
//                         );
//                       },
//                     ),
//             ),

//             // Payment Button
//             if (_journals.isNotEmpty)
//               Container(
//                 width: double.infinity,
//                 margin: const EdgeInsets.all(16),
//                 child: FilledButton.icon(
//                   onPressed: _showPaymentOptions,
//                   icon: const Icon(Icons.payment),
//                   label: const Text("ຮັບເງິນ", style: TextStyle(fontSize: 20)),
//                   style: FilledButton.styleFrom(
//                     backgroundColor: orange,
//                     padding: const EdgeInsets.symmetric(vertical: 16),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(20),
//                     ),
//                   ),
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }

//   void _selectCustomer() async {
//     final result = await Navigator.push(
//       context,
//       MaterialPageRoute(builder: (_) => const CustListforPos()),
//     );
//     if (result != null) {
//       setState(() {
//         cust_name.text = result['name_1'];
//         cust_code = result['code'];
//         group_main = result['group_main'];
//         group_sub_1 = result['group_sub_1'];
//       });
//       _refreshJournals();
//     }
//   }

//   void _goToStock() async {
//     await Navigator.push(
//       context,
//       MaterialPageRoute(builder: (context) => StockSale(custcode: cust_code)),
//     );
//     _refreshJournals();
//   }

//   void _showPaymentOptions() {
//     showCupertinoModalPopup(
//       context: context,
//       builder: (context) => CupertinoActionSheet(
//         title: const Text('ເລືອກປະເພດການຮັບເງິນ'),
//         actions: [
//           CupertinoActionSheetAction(
//             child: const Text('ເງິນສົດ'),
//             onPressed: () => Navigator.push(
//               context,
//               MaterialPageRoute(
//                 builder: (context) => HomePayment(
//                   cust_code: cust_code,
//                   total_amount: total_amount.toString(),
//                 ),
//               ),
//             ),
//           ),
//           CupertinoActionSheetAction(
//             child: const Text('ໂອນບາດ'),
//             onPressed: () => Navigator.push(
//               context,
//               MaterialPageRoute(
//                 builder: (context) => Payment(
//                   cust_code: cust_code,
//                   total_amount: total_amount.toString(),
//                 ),
//               ),
//             ),
//           ),
//           CupertinoActionSheetAction(
//             child: const Text('ໂອນກີບ'),
//             onPressed: () => Navigator.push(
//               context,
//               MaterialPageRoute(
//                 builder: (context) => KipPayment(
//                   cust_code: cust_code,
//                   total_amount: total_amount.toString(),
//                 ),
//               ),
//             ),
//           ),
//         ],
//         cancelButton: CupertinoActionSheetAction(
//           isDestructiveAction: true,
//           onPressed: () => Navigator.pop(context),
//           child: const Text('ຍົກເລີກ'),
//         ),
//       ),
//     );
//   }
// }
