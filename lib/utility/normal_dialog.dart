import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

Future<void> normalDialog(
    BuildContext context, String message, String content) async {
  showCupertinoDialog(
    context: context,
    builder: (context) {
      return CupertinoAlertDialog(
        title: Text(message),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      );
    },
  );
}

Future<void> normalDialogConfirm(
    BuildContext context, String message, String content) async {
  showCupertinoDialog(
    context: context,
    builder: (context) {
      return CupertinoAlertDialog(
        title: Text(message),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: Text('ອອກເລີຍ'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('ກັບຄືນ'),
          ),
        ],
      );
    },
  );
}

Future<void> normalDialog2(
    BuildContext context, String title, String message) async {
  showDialog(
    context: context,
    builder: (context) => SimpleDialog(
      title: ListTile(
        leading: Image.asset('images/logo.png'),
        title: Text(title),
        subtitle: Text(message),
      ),
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            // FlatButton(
            // onPressed: () => Navigator.pop(context),
            // child: Text(
            //   'OK',
            //   style: TextStyle(color: Colors.red),
            // )),
          ],
        )
      ],
    ),
  );
}
