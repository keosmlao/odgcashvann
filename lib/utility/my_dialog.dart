import 'dart:io';

import 'package:flutter/material.dart';
// import 'package:geolocator/geolocator.dart';

class Mydialog {
  Future<Null> alertLocationService(context) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: ListTile(
          title: Text("location Service ປິດຢູ່"),
          subtitle: Text("ກະລຸນາເປິດ Location Service ກ່ອນ"),
        ),
        actions: [
          TextButton(
              onPressed: () async {
                // await Geolocator.openLocationSettings();
                exit(0);
              },
              child: Text("OK"))
        ],
      ),
    );
  }
}
