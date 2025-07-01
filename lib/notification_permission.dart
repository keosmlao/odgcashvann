import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationPermissionPage extends StatefulWidget {
  const NotificationPermissionPage({Key? key}) : super(key: key);

  @override
  State<NotificationPermissionPage> createState() =>
      _NotificationPermissionPageState();
}

class _NotificationPermissionPageState
    extends State<NotificationPermissionPage> {
  String _status = 'ກວດສອບສິດ...';

  @override
  void initState() {
    super.initState();
    _checkAndRequest();
  }

  Future<void> _checkAndRequest() async {
    final status = await Permission.notification.status;

    if (status.isGranted) {
      setState(() => _status = '✅ ອະນຸຍາດແລ້ວ');
    } else {
      final result = await Permission.notification.request();
      if (result.isGranted) {
        setState(() => _status = '✅ ອະນຸຍາດແລ້ວ');
      } else if (result.isDenied) {
        setState(() => _status = '❌ ຖືກປະຕິເສດ');
      } else if (result.isPermanentlyDenied) {
        setState(() => _status = '⚠️ ຖືກປະຕິເສດຖາວອນ');
      }
    }
  }

  Future<void> _openAppSettings() async {
    final opened = await openAppSettings();
    if (!opened) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ເປີດ Settings ບໍ່ສຳເລັດ')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Permission'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text('ສະຖານະ: $_status', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _checkAndRequest,
              icon: const Icon(Icons.notifications_active),
              label: const Text('ຂໍອະນຸຍາດ Notification'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: _openAppSettings,
              icon: const Icon(Icons.settings),
              label: const Text('ເປີດ Settings ດ້ວຍຕົວເອງ'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
