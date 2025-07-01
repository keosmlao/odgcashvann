import 'package:flutter/material.dart';
import 'package:odgcashvan/login/login.dart';

Future<Null> signOutProcess(BuildContext context) async {
  // SharedPreferences preferences = await SharedPreferences.getInstance();
  // preferences.clear();
  // exit(0);

  MaterialPageRoute route = MaterialPageRoute(builder: (context) => Login());
  Navigator.pushAndRemoveUntil(context, route, (route) => false);
}
