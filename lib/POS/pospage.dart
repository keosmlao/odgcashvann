// import 'package:flutter/material.dart';
// import 'package:odgcashvan/POS/pos.dart';
// import 'package:odgcashvan/utility/my_style.dart';

// import 'package:shared_preferences/shared_preferences.dart';

// import '../Sale/listorder.dart';

// class PosPAge extends StatefulWidget {
//   const PosPAge({super.key});

//   @override
//   State<PosPAge> createState() => _PosPAgeState();
// }

// class _PosPAgeState extends State<PosPAge> {
//   Widget? currentWidget;
//   String? nameUser, title;

//   @override
//   void initState() {
//     super.initState();
//     findUser();
//     currentWidget = Pos();
//     title = 'ຂາຍ';
//   }

//   Future<Null> findUser() async {
//     SharedPreferences preferences = await SharedPreferences.getInstance();
//     setState(() {
//       nameUser = preferences.getString('username');
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(
//           title.toString(),
//           style: TextStyle(color: Colors.white, fontSize: 30),
//         ),
//         // backgroundColor: MyStyle().odien1,
//         centerTitle: true,
//       ),
//       drawer: Drawer(
//         child: ListView(
//           padding: EdgeInsets.zero,
//           children: [
//             DrawerHeader(
//               decoration: BoxDecoration(color: MyStyle().odien1),
//               child: Text(
//                 'ລານການ',
//                 style: TextStyle(color: Colors.white, fontSize: 24),
//               ),
//             ),
//             ListTile(
//               leading: Icon(Icons.shopping_cart),
//               title: Text('ຂາຍ'),
//               onTap: () {
//                 Navigator.pop(context);
//                 setState(() {
//                   currentWidget = Pos();
//                   title = 'ຂາຍ';
//                 });
//               },
//             ),
//             ListTile(
//               leading: Icon(Icons.bar_chart),
//               title: Text('ລາຍງານຂາຍ'),
//               onTap: () {
//                 // Add your onTap code here
//                 Navigator.pop(context);
//                 setState(() {
//                   currentWidget = ListOrder();
//                   title = 'ລາຍງານຂາຍ';
//                 });
//               },
//             ),
//             Divider(),
//             ListTile(
//               leading: Icon(Icons.arrow_back),
//               title: Text('ກັບໄປໜ້າຫຼັກ'),
//               onTap: () {
//                 Navigator.pop(context);
//                 Navigator.pop(context);
//               },
//             ),
//           ],
//         ),
//       ),
//       body: currentWidget,
//     );
//   }
// }
