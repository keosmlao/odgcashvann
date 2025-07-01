// import 'package:flutter/material.dart';
// import 'package:odgcashvan/POS/pospage.dart';
// import 'package:odgcashvan/route_plan/listrouteplan.dart';
// import 'package:odgcashvan/stock/homestock.dart';
// import 'package:odgcashvan/utility/my_style.dart';
// import '../utility/signout_process.dart';

// class HomePos extends StatefulWidget {
//   const HomePos({super.key});

//   @override
//   State<HomePos> createState() => _HomePosState();
// }

// class _HomePosState extends State<HomePos> with SingleTickerProviderStateMixin {
//   late AnimationController _animationController;
//   late Animation<double> _animation;

//   @override
//   void initState() {
//     super.initState();
//     _animationController = AnimationController(
//       vsync: this,
//       duration: const Duration(
//         milliseconds: 700,
//       ), // Slightly increased duration
//     );
//     _animation = Tween<double>(begin: 0.8, end: 1.0).animate(
//       // Start from a more noticeable smaller size (0.8)
//       CurvedAnimation(
//         parent: _animationController,
//         curve: Curves.easeOutCubic, // A slightly more pronounced easing curve
//       ),
//     );
//     _animationController.forward();
//   }

//   @override
//   void dispose() {
//     _animationController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final Color primaryColor = MyStyle().odien3;
//     final Color backgroundColor = Colors.grey.shade50;
//     final Color cardBackgroundColor = Colors.white;
//     final Color accentRedColor = Colors.red.shade400;

//     return Scaffold(
//       backgroundColor: backgroundColor,
//       appBar: AppBar(
//         title: const Text(
//           "ໜ້າຫຼັກລະບົບ POS",
//           style: TextStyle(
//             color: Colors.white,
//             fontWeight: FontWeight.bold,
//             fontFamily: 'NotoSansLao',
//           ),
//         ),
//         backgroundColor: primaryColor,
//         centerTitle: true,
//         elevation: 0,
//         toolbarHeight: 70,
//       ),
//       body: ScaleTransition(
//         // This is where the animation is applied
//         scale: _animation,
//         alignment: Alignment.center, // Ensure it scales from the center
//         child: Padding(
//           padding: const EdgeInsets.all(32.0),
//           child: Column(
//             children: [
//               // --- Header Image/Banner ---
//               Container(
//                 decoration: BoxDecoration(
//                   borderRadius: BorderRadius.circular(30.0),
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.grey.withOpacity(0.15),
//                       spreadRadius: 2,
//                       blurRadius: 15,
//                       offset: const Offset(0, 8),
//                     ),
//                   ],
//                 ),
//                 child: ClipRRect(
//                   borderRadius: BorderRadius.circular(30.0),
//                   child: Image.asset(
//                     'assets/odg.jpg',
//                     width: double.infinity,
//                     height: MediaQuery.of(context).size.height * 0.22,
//                     fit: BoxFit.cover,
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 40),

//               // --- Grid of Menu Cards ---
//               Expanded(
//                 child: GridView.count(
//                   crossAxisCount: 2,
//                   crossAxisSpacing: 24,
//                   mainAxisSpacing: 24,
//                   childAspectRatio: 1,
//                   physics: const NeverScrollableScrollPhysics(),
//                   children: [
//                     _buildMenuCard(
//                       icon: Icons.map_rounded,
//                       label: "ແຜນເດີນລົດ",
//                       onTap: () {
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                             builder: (_) => const ListRoutePlan(),
//                           ),
//                         );
//                       },
//                       cardColor: cardBackgroundColor,
//                       iconColor: primaryColor,
//                       labelColor: Colors.blueGrey.shade800,
//                     ),
//                     _buildMenuCard(
//                       icon: Icons.warehouse,
//                       label: "ຈັດການສາງ",
//                       onTap: () {
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(builder: (_) => const Homestock()),
//                         );
//                       },
//                       cardColor: cardBackgroundColor,
//                       iconColor: primaryColor,
//                       labelColor: Colors.blueGrey.shade800,
//                     ),
//                     _buildMenuCard(
//                       icon: Icons.shopping_cart,
//                       label: "ການຂາຍ",
//                       onTap: () {
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(builder: (_) => const PosPAge()),
//                         );
//                       },
//                       cardColor: cardBackgroundColor,
//                       iconColor: primaryColor,
//                       labelColor: Colors.blueGrey.shade800,
//                     ),
//                     _buildMenuCard(
//                       icon: Icons.logout,
//                       label: "ອອກລະບົບ",
//                       onTap: () => signOutProcess(context),
//                       cardColor: Colors.red.shade50,
//                       iconColor: accentRedColor,
//                       labelColor: accentRedColor,
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildMenuCard({
//     required IconData icon,
//     required String label,
//     required VoidCallback onTap,
//     Color? cardColor,
//     Color? iconColor,
//     Color? labelColor,
//   }) {
//     return Container(
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(30),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.grey.withOpacity(0.1),
//             spreadRadius: 1,
//             blurRadius: 12,
//             offset: const Offset(0, 6),
//           ),
//         ],
//       ),
//       child: Card(
//         elevation: 0,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
//         color: cardColor ?? Colors.white,
//         child: InkWell(
//           borderRadius: BorderRadius.circular(30),
//           onTap: onTap,
//           splashColor: (iconColor ?? MyStyle().odien3).withOpacity(0.15),
//           highlightColor: (iconColor ?? MyStyle().odien3).withOpacity(0.08),
//           child: Padding(
//             padding: const EdgeInsets.all(20.0),
//             child: Center(
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Icon(icon, size: 72, color: iconColor ?? MyStyle().odien3),
//                   const SizedBox(height: 18),
//                   Text(
//                     label,
//                     textAlign: TextAlign.center,
//                     style: TextStyle(
//                       fontSize: 21,
//                       fontWeight: FontWeight.w600,
//                       color: labelColor ?? Colors.blueGrey.shade800,
//                       fontFamily: 'NotoSansLao',
//                       height: 1.2,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
