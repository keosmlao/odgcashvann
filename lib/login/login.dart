import 'dart:async';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart';
import 'package:http/http.dart' as http;
import 'package:odgcashvan/ACC/homeacc.dart';
import 'package:odgcashvan/Home/homepage.dart';
import 'package:odgcashvan/utility/my_constant.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> with SingleTickerProviderStateMixin {
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _fcmToken = '';
  bool _isLoading = false;
  bool _obscurePassword = true;

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  String _statusMessage = "Initializing...";

  // Define a consistent color scheme
  final Color _primaryColor = Colors.indigo.shade800; // Deep Indigo
  final Color _accentColor =
      Colors.indigo.shade400; // Lighter Indigo for highlights
  final Color _gradientStartColor = Colors.indigo.shade700;
  final Color _gradientEndColor = Colors.blue.shade700; // Blue for gradient end
  final Color _textColor = Colors.white; // White for text on dark background
  final Color _inputFillColor = Colors.white.withOpacity(
    0.2,
  ); // Translucent white for input fields
  final Color _inputBorderColor = Colors.white.withOpacity(0.4);

  // Animation controller for fade-in effect
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    // _checkFirstLaunchAndSendLocation();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );

    _loadSavedCredentials();
    // _setupFirebaseMessaging();
    _animationController.forward(); // Start fade-in animation
  }

  @override
  void dispose() {
    _userController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _setupFirebaseMessaging() async {
    await _firebaseMessaging.requestPermission();
    _firebaseMessaging.getToken().then((token) {
      if (token != null) {
        setState(() {
          _fcmToken = token;
        });
        print("FCM Token: $_fcmToken");
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Message clicked! ${message.data}');
    });
  }

  void _loadSavedCredentials() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    setState(() {
      _userController.text = preferences.getString('usercode') ?? '';
      _passwordController.text = preferences.getString('password') ?? '';
    });
  }

  Future<void> _checkAuthen() async {
    if (_userController.text.isEmpty || _passwordController.text.isEmpty) {
      _showAlertDialog(
        context,
        'ຄຳເຕືອນ',
        'ກະລຸນາປ້ອນຊື່ຜູ້ໃຊ້ ແລະ ລະຫັດຜ່ານ.',
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    String data = json.encode({
      'username': _userController.text,
      'password': _passwordController.text,
      'fcmToken': _fcmToken,
    });
    print("Login request data: $data");

    try {
      var response = await post(
        Uri.parse('${MyConstant().domain}/vansaleLogin'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: data,
      );

      var result = json.decode(response.body);
      print("Login response: ${response.statusCode} - $result");

      if (response.statusCode == 200) {
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('username', result['name_1'] ?? '');
        await prefs.setString('usercode', result['usercode'] ?? '');
        await prefs.setString('password', _passwordController.text);
        if (result['roles'] == 'sale') {
          await prefs.setString('wh_code', result['ic_wht'] ?? '');
          await prefs.setString('sh_code', result['ic_shelf'] ?? '');
          await prefs.setString('side_code', result['side'] ?? '');
          await prefs.setString('department_code', result['department'] ?? '');
          // await prefs.setString('area_code', result['area_code'] ?? '');
          // await prefs.setString('logistic_area', result['logistic_code'] ?? '');
          await prefs.setString('route_id', result['route_plan'] ?? '');
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const HomePage()),
            (route) => false,
          );
        } else {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const HomeAcc()),
            (route) => false,
          );
        }
      } else {
        _showAlertDialog(
          context,
          'ເຂົ້າສູ່ລະບົບບໍ່ສຳເລັດ',
          result['message'] ?? 'ຊື່ຜູ້ໃຊ້ ຫຼື ລະຫັດຜ່ານບໍ່ຖືກຕ້ອງ.',
        );
      }
    } catch (e) {
      print('Login Error: $e');
      _showAlertDialog(
        context,
        'ຂໍ້ຜິດພາດການເຊື່ອມຕໍ່',
        'ບໍ່ສາມາດເຊື່ອມຕໍ່ກັບເຊີເວີໄດ້. ກະລຸນາກວດສອບການເຊື່ອມຕໍ່ອິນເຕີເນັດຂອງທ່ານ.',
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showAlertDialog(BuildContext context, String title, String content) {
    showCupertinoDialog(
      context: context,
      builder: (context) {
        return CupertinoAlertDialog(
          title: Text(
            title,
            style: const TextStyle(
              fontFamily: 'NotoSansLao',
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            content,
            style: const TextStyle(fontFamily: 'NotoSansLao'),
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'ຕົກລົງ',
                style: TextStyle(fontFamily: 'NotoSansLao', color: Colors.blue),
              ),
            ),
          ],
        );
      },
    );
  }

  // --- Core Logic for First Launch and GPS Post ---
  Future<void> _checkFirstLaunchAndSendLocation() async {
    setState(() {
      _statusMessage = "Checking if this is the first launch...";
    });

    final prefs = await SharedPreferences.getInstance();
    const String kFirstLaunchKey = 'isFirstLaunch';
    bool isFirstLaunch = prefs.getBool(kFirstLaunchKey) ?? true;

    if (isFirstLaunch) {
      print('[First Launch Check] This is the first launch!');
      setState(() {
        _statusMessage = "First launch detected! Attempting to send GPS...";
      });
      await _sendGpsLocationToServer();
      await prefs.setBool(kFirstLaunchKey, false); // Mark as not first launch
    } else {
      print('[First Launch Check] App has been launched before.');
      setState(() {
        _statusMessage =
            "App has been launched before. No GPS sent on this run.";
      });
    }
  }

  Future<void> _sendGpsLocationToServer() async {
    setState(() {
      _statusMessage = "Requesting location permissions and service status...";
    });

    try {
      // 1. Check Location Services and Permissions
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _updateStatus(
          'Location services are disabled on your device. Please enable them.',
        );
        print('[GPS Post] Location services disabled.');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        _updateStatus('Location permission denied. Requesting permission...');
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _updateStatus('Location permission denied by user. Cannot send GPS.');
          print('[GPS Post] Location permission denied.');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _updateStatus(
          'Location permissions are permanently denied. Please enable from app settings.',
        );
        print('[GPS Post] Location permissions permanently denied.');
        return;
      }

      // 2. Get Current Position
      _updateStatus('Getting current GPS position...');
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15), // Timeout for getting position
      );

      _updateStatus(
        'GPS position obtained: ${position.latitude}, ${position.longitude}. Preparing to send...',
      );
      print(
        '[GPS Post] Got Position: ${position.latitude}, ${position.longitude}',
      );

      // 3. Prepare data for the server (MATCHING YOUR FLASK API KEYS)
      final Map<String, dynamic> requestBody = {
        'lat': position.latitude,
        'lng': position.longitude,
        'user_code': '22020', // Using the defined user code
        'device_id':
            'your_unique_device_id', // <<< REPLACE THIS with a unique ID for the device
        // You can still send other data for your own logging/debugging,
        // but the Flask API expects only 'lat', 'lng', 'user_code', 'device_id'.
        // 'timestamp': position.timestamp?.toIso8601String(),
        // 'accuracy': position.accuracy,
        // 'altitude': position.altitude,
        // 'speed': position.speed,
        // 'appVersion': '1.0.0',
        // 'event': 'app_install_location',
      };
      final Uri uri = Uri.parse(
        MyConstant().domain + '/savegps',
      ); // <<< UPDATE THIS URL

      _updateStatus('Sending data to server...');
      final response = await http
          .post(
            uri,
            headers: <String, String>{
              'Content-Type': 'application/json; charset=UTF-8',
            },
            body: jsonEncode(requestBody), // Sending the adjusted requestBody
          )
          .timeout(const Duration(seconds: 20)); // Timeout for the HTTP request

      if (response.statusCode == 200) {
        // Flask typically returns 200 for 'ok'
        _updateStatus(
          'GPS location successfully sent to server! Status: ${response.statusCode}',
        );
        print('[GPS Post] Server success: ${response.body}');
      } else {
        _updateStatus(
          'Failed to send GPS location. Status: ${response.statusCode}, Body: ${response.body}',
        );
        print(
          '[GPS Post] Server error: ${response.statusCode}, ${response.body}',
        );
      }
    } on TimeoutException catch (e) {
      _updateStatus('Operation timed out: $e');
      print('[GPS Post Error] Timeout: $e');
    } catch (e) {
      _updateStatus('Error sending GPS location: $e');
      print('[GPS Post Error] General Error: $e');
    }
  }

  void _updateStatus(String message) {
    if (mounted) {
      // Check if the widget is still in the widget tree
      setState(() {
        _statusMessage = message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [_gradientStartColor, _gradientEndColor],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: FadeTransition(
          // Apply fade-in animation to the whole content
          opacity: _fadeAnimation,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 32.0,
                vertical: 40.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // --- App Logo/Icon ---
                  Hero(
                    tag: 'app_logo',
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: _textColor.withOpacity(0.1), // Translucent white
                        borderRadius: BorderRadius.circular(50),
                        border: Border.all(
                          color: _textColor.withOpacity(0.3),
                          width: 2,
                        ), // Subtle border
                      ),
                      child: Icon(
                        Icons
                            .local_shipping_outlined, // A cleaner, more minimalist icon
                        size: 80,
                        color: _textColor, // White icon
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // --- Welcome Text ---
                  Text(
                    'ຍິນດີຕ້ອນຮັບສູ່',
                    style: TextStyle(
                      fontSize: 22,
                      color: _textColor.withOpacity(0.8),
                      fontFamily: 'NotoSansLao',
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  Text(
                    'CASH VAN',
                    style: TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.bold,
                      color: _textColor, // White text
                      letterSpacing: 1.0,
                      fontFamily: 'NotoSansLao',
                    ),
                  ),
                  const SizedBox(height: 48),

                  // --- Username Field ---
                  TextField(
                    controller: _userController,
                    keyboardType: TextInputType.text,
                    decoration: InputDecoration(
                      labelText: 'ລະຫັດຜູ້ໃຊ້',
                      labelStyle: TextStyle(
                        color: _textColor.withOpacity(0.8),
                        fontFamily: 'NotoSansLao',
                      ),
                      prefixIcon: Icon(
                        Icons.person_outline,
                        color: _textColor.withOpacity(0.8),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: _inputFillColor, // Translucent fill
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: _textColor,
                          width: 2,
                        ), // White border on focus
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: _inputBorderColor,
                          width: 1,
                        ), // Translucent border
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 12,
                      ),
                    ),
                    style: TextStyle(
                      color: _textColor,
                      fontSize: 17,
                      fontFamily: 'NotoSansLao',
                    ),
                  ),
                  const SizedBox(height: 20),

                  // --- Password Field ---
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    keyboardType: TextInputType.text,
                    decoration: InputDecoration(
                      labelText: 'ລະຫັດຜ່ານ',
                      labelStyle: TextStyle(
                        color: _textColor.withOpacity(0.8),
                        fontFamily: 'NotoSansLao',
                      ),
                      prefixIcon: Icon(
                        Icons.lock_outline,
                        color: _textColor.withOpacity(0.8),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: _textColor.withOpacity(0.8),
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: _inputFillColor,
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: _textColor, width: 2),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: _inputBorderColor,
                          width: 1,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 12,
                      ),
                    ),
                    style: TextStyle(
                      color: _textColor,
                      fontSize: 17,
                      fontFamily: 'NotoSansLao',
                    ),
                  ),
                  const SizedBox(height: 30),

                  // --- Login Button ---
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: _isLoading
                        ? Center(
                            child: CircularProgressIndicator(
                              color: _textColor,
                            ), // White spinner
                          )
                        : ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  _accentColor, // Use a lighter accent for the button
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              elevation: 5,
                              shadowColor: Colors.black.withOpacity(0.3),
                            ),
                            onPressed: _checkAuthen,
                            child: Text(
                              'ເຂົ້າສູ່ລະບົບ',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                                color: _textColor, // White text on button
                                fontFamily: 'NotoSansLao',
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(height: 20),

                  // --- Forgot Password ---
                  TextButton(
                    onPressed: () {
                      _showAlertDialog(
                        context,
                        'ລືມລະຫັດຜ່ານ?',
                        'ກະລຸນາຕິດຕໍ່ຜູ້ເບິ່ງແຍງລະບົບຂອງທ່ານເພື່ອຂໍຄວາມຊ່ວຍເຫຼືອ.',
                      );
                    },
                    child: Text(
                      'ລືມລະຫັດຜ່ານ?',
                      style: TextStyle(
                        color: _textColor.withOpacity(
                          0.8,
                        ), // Slightly transparent white
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'NotoSansLao',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
