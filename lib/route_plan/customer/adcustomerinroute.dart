import 'package:flutter/material.dart';
import 'package:odgcashvan/utility/my_style.dart';

class AddCustomerInterroute extends StatefulWidget {
  const AddCustomerInterroute({super.key});

  @override
  State<AddCustomerInterroute> createState() => _AddCustomerInterrouteState();
}

class _AddCustomerInterrouteState extends State<AddCustomerInterroute> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("ລາຍຊື່ລູກຄ້າ", style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: MyStyle().odien1,
      ),
    );
  }
}
