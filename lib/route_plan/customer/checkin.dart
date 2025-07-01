import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:location/location.dart';
import 'package:odgcashvan/utility/my_constant.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CheckIn extends StatefulWidget {
  final String cust_code, doc_no, checkin, latlng, pic;

  const CheckIn({
    Key? key,
    required this.cust_code,
    required this.doc_no,
    required this.checkin,
    required this.latlng,
    required this.pic,
  }) : super(key: key);

  @override
  State<CheckIn> createState() => _CheckInState();
}

class _CheckInState extends State<CheckIn> {
  File? _selectedImage;
  bool _isSaving = false;
  bool _isLocationLoading = true;

  String _currentTime = '';
  String _currentDate = '';
  Location _locationService = Location();
  LocationData? _currentLocation;
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};

  final Color _primaryBlue = Colors.blue.shade600;
  final Color _accentBlue = Colors.blue.shade800;
  final Color _lightBlue = Colors.blue.shade50;
  final Color _textMutedColor = Colors.grey.shade600;

  // DateFormat for parsing checkin time if it's like "YYYY-MM-DD HH:mm:ss" for display
  // Note: The API response for 'checkin' field is assumed to be 'YYYY-MM-DD HH:mm:ss' or 'YYYY-MM-DD HH:mm'
  // Let's use a flexible format to parse if it exists, for display only.
  final DateFormat _checkinDateTimeFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

  @override
  void initState() {
    super.initState();
    _getCurrentTime();
    _getLocation();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  void _getCurrentTime() {
    final now = DateTime.now();
    _currentTime = DateFormat('HH:mm:ss').format(now);
    _currentDate = DateFormat('yyyy-MM-dd').format(now);
  }

  Future<void> _getLocation() async {
    bool serviceEnabled = await _locationService.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _locationService.requestService();
      if (!serviceEnabled) {
        setState(() => _isLocationLoading = false);
        return;
      }
    }

    PermissionStatus permission = await _locationService.hasPermission();
    if (permission == PermissionStatus.denied) {
      permission = await _locationService.requestPermission();
      if (permission != PermissionStatus.granted) {
        setState(() => _isLocationLoading = false);
        return;
      }
    }

    try {
      final loc = await _locationService.getLocation();
      setState(() {
        _currentLocation = loc;
        _isLocationLoading = false;
        if (_currentLocation != null) {
          _markers.add(
            Marker(
              markerId: const MarkerId('currentLocation'),
              position: LatLng(
                _currentLocation!.latitude!,
                _currentLocation!.longitude!,
              ),
              infoWindow: const InfoWindow(title: 'ຕຳແໜ່ງປະຈຸບັນ'),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueAzure,
              ),
            ),
          );
        }
      });
    } catch (e) {
      print("Error getting location: $e");
      setState(() => _isLocationLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'ບໍ່ສາມາດດຶງຂໍ້ມູນຕຳແໜ່ງໄດ້: $e',
              style: const TextStyle(
                fontFamily: 'NotoSansLao',
                color: Colors.white,
              ),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  LatLng _stringToLatLng(String value) {
    if (value.isEmpty || !value.contains(',')) {
      return const LatLng(0, 0);
    }
    try {
      final parts = value.split(',');
      return LatLng(double.parse(parts[0]), double.parse(parts[1]));
    } catch (e) {
      print("Error parsing latlng string: $e");
      return const LatLng(0, 0);
    }
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.camera,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (picked != null) {
      setState(() => _selectedImage = File(picked.path));
    }
  }

  Future<void> _saveCheckIn() async {
    if (_currentLocation == null) {
      _showAlertDialog(
        "ແຈ້ງເຕືອນ",
        "ບໍ່ສາມາດດຶງຂໍ້ມູນຕຳແໜ່ງປະຈຸບັນໄດ້. ກະລຸນາລອງໃໝ່.",
      );
      return;
    }
    if (_selectedImage == null) {
      // This check is now redundant due to button state, but good for safety
      _showAlertDialog("ແຈ້ງເຕືອນ", "ກະລຸນາຖ່າຍຮູບເພື່ອເຊັກອິນ.");
      return;
    }

    setState(() => _isSaving = true);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          Center(child: CircularProgressIndicator(color: _primaryBlue)),
    );

    try {
      final imgBytes = await _selectedImage!.readAsBytes();
      final imgBase64 = base64.encode(imgBytes);

      SharedPreferences prefs = await SharedPreferences.getInstance();
      String userCode = prefs.getString('usercode') ?? '';

      if (userCode.isEmpty) {
        throw Exception("User code not found. Please log in again.");
      }

      final data = jsonEncode({
        'doc_no': widget.doc_no,
        'sale_code': userCode,
        'latlng':
            '${_currentLocation!.latitude},${_currentLocation!.longitude}',
        'cust_code': widget.cust_code,
        'checkin': '$_currentDate $_currentTime',
        'pic': imgBase64,
      });

      final response = await post(
        Uri.parse("${MyConstant().domain}/vansalecheckin"),
        headers: {'Content-Type': 'application/json'},
        body: data,
      );

      Navigator.of(context).pop();

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'ບັນທຶກການເຊັກອິນສຳເລັດ',
                style: TextStyle(
                  fontFamily: 'NotoSansLao',
                  color: Colors.white,
                ),
              ),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(true);
        }
      } else {
        throw Exception(
          "Failed to save check-in. Status: ${response.statusCode}",
        );
      }
    } catch (e) {
      Navigator.of(context).pop();
      if (mounted) {
        _showAlertDialog("ບັນທຶກບໍ່ສຳເລັດ", "ເກີດຂໍ້ຜິດພາດ: $e");
      }
      print("Error saving check-in: $e");
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _showAlertDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          title,
          style: TextStyle(
            fontFamily: 'NotoSansLao',
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(content, style: TextStyle(fontFamily: 'NotoSansLao')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "OK",
              style: TextStyle(fontFamily: 'NotoSansLao', color: _primaryBlue),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isAlreadyCheckedIn = widget.checkin != '';

    return Scaffold(
      backgroundColor: _lightBlue,
      appBar: AppBar(
        title: const Text(
          "CHECK-IN",
          style: TextStyle(fontFamily: 'NotoSansLao', color: Colors.white),
        ),
        backgroundColor: _primaryBlue,
        centerTitle: true,
        elevation: 0,
      ),
      body: isAlreadyCheckedIn ? _buildCheckedInView() : _buildCheckInForm(),
    );
  }

  Widget _buildCheckInForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // --- Photo Section ---
          Text(
            "1. ຖ່າຍຮູບສະຖານທີ່",
            style: Theme.of(context).textTheme.titleLarge!.copyWith(
              fontFamily: 'NotoSansLao',
              fontWeight: FontWeight.bold,
              color: _accentBlue,
            ),
          ),
          const SizedBox(height: 15),
          Container(
            height: 250,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: _primaryBlue.withOpacity(0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: _selectedImage == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.image_outlined,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'ຍັງບໍ່ມີຮູບພາບ',
                          style: TextStyle(
                            fontFamily: 'NotoSansLao',
                            color: _textMutedColor,
                          ),
                        ),
                      ],
                    ),
                  )
                : Image.file(_selectedImage!, fit: BoxFit.cover),
          ),
          const SizedBox(height: 15),
          ElevatedButton.icon(
            onPressed: _pickImage,
            icon: const Icon(Icons.camera_alt_outlined, size: 24),
            label: const Text(
              "ຖ່າຍຮູບ",
              style: TextStyle(
                fontFamily: 'NotoSansLao',
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 4,
            ),
          ),

          const SizedBox(height: 30),

          // --- Map Section ---
          Text(
            "2. ຢືນຢັນຕຳແໜ່ງ",
            style: Theme.of(context).textTheme.titleLarge!.copyWith(
              fontFamily: 'NotoSansLao',
              fontWeight: FontWeight.bold,
              color: _accentBlue,
            ),
          ),
          const SizedBox(height: 15),
          Container(
            height: 250,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: _primaryBlue.withOpacity(0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: _isLocationLoading
                ? Center(child: CircularProgressIndicator(color: _primaryBlue))
                : _currentLocation == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.location_off,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'ບໍ່ພົບຕຳແໜ່ງ',
                          style: TextStyle(
                            fontFamily: 'NotoSansLao',
                            color: _textMutedColor,
                          ),
                        ),
                      ],
                    ),
                  )
                : GoogleMap(
                    onMapCreated: (controller) {
                      _mapController = controller;
                      if (_currentLocation != null) {
                        setState(() {
                          _markers.add(
                            Marker(
                              markerId: const MarkerId('currentLocation'),
                              position: LatLng(
                                _currentLocation!.latitude!,
                                _currentLocation!.longitude!,
                              ),
                              infoWindow: const InfoWindow(
                                title: 'ຕຳແໜ່ງປະຈຸບັນ',
                              ),
                              icon: BitmapDescriptor.defaultMarkerWithHue(
                                BitmapDescriptor.hueAzure,
                              ),
                            ),
                          );
                        });
                      }
                    },
                    initialCameraPosition: CameraPosition(
                      target: LatLng(
                        _currentLocation!.latitude!,
                        _currentLocation!.longitude!,
                      ),
                      zoom: 16,
                    ),
                    myLocationEnabled: true,
                    scrollGesturesEnabled: false,
                    zoomControlsEnabled: false,
                    mapType: MapType.normal,
                    markers: _markers,
                  ),
          ),

          const SizedBox(height: 30),

          // --- Save Button ---
          ElevatedButton.icon(
            // Button is disabled if _selectedImage is null or if _isSaving
            onPressed: (_selectedImage == null || _isSaving)
                ? null
                : _saveCheckIn,
            icon: _isSaving
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                  )
                : const Icon(Icons.check_circle_outline, size: 28),
            label: Text(
              _isSaving ? "ກຳລັງບັນທຶກ..." : "ບັນທຶກການ Check-in",
              style: const TextStyle(
                fontFamily: 'NotoSansLao',
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 5,
              disabledBackgroundColor: _primaryBlue.withOpacity(0.4),
              disabledForegroundColor: Colors.white.withOpacity(0.5),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildCheckedInView() {
    // A single DateFormat for parsing the widget.checkin string
    // Assuming checkin is 'YYYY-MM-DD HH:mm:ss'
    final DateFormat _checkinFullDisplayFormat = DateFormat(
      'yyyy-MM-dd HH:mm:ss',
    );

    String displayCheckinTime = 'N/A';
    try {
      if (widget.checkin.isNotEmpty) {
        final DateTime parsedCheckin = _checkinFullDisplayFormat.parse(
          widget.checkin,
        );
        displayCheckinTime = _checkinFullDisplayFormat.format(parsedCheckin);
      }
    } catch (e) {
      print("Error parsing checkin time for display: $e");
    }

    LatLng checkedInLocation = const LatLng(0, 0);
    if (widget.latlng.isNotEmpty && widget.latlng.contains(',')) {
      try {
        checkedInLocation = _stringToLatLng(widget.latlng);
      } catch (e) {
        print("Error parsing widget.latlng for checked-in view: $e");
      }
    }

    ImageProvider? imageProvider;
    if (widget.pic.isNotEmpty) {
      try {
        // Assume pic is base64 encoded image string
        final imageBytes = base64Decode(widget.pic);
        imageProvider = MemoryImage(imageBytes);
      } catch (e) {
        print("Error decoding base64 image for checked-in view: $e");
        imageProvider = null; // Set to null if decoding fails
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // --- Confirmation Message ---
          Container(
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.green.shade400, width: 2),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 30,
                  color: Colors.green.shade700,
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Text(
                    "ທ່ານໄດ້ເຊັກອິນສຳເລັດແລ້ວ!",
                    style: TextStyle(
                      fontFamily: 'NotoSansLao',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 25),

          // --- Check-in Details ---
          Text(
            "ລາຍລະອຽດການເຊັກອິນ",
            style: Theme.of(context).textTheme.headlineSmall!.copyWith(
              fontFamily: 'NotoSansLao',
              fontWeight: FontWeight.bold,
              color: _accentBlue,
            ),
          ),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildDetailRow(
                  Icons.access_time,
                  "ເວລາເຊັກອິນ",
                  displayCheckinTime,
                  Colors.blueGrey,
                ),
                _buildDetailRow(
                  Icons.location_on_outlined,
                  "ຕຳແໜ່ງເຊັກອິນ",
                  "${checkedInLocation.latitude.toStringAsFixed(6)}, ${checkedInLocation.longitude.toStringAsFixed(6)}",
                  Colors.blueGrey,
                ),
              ],
            ),
          ),
          const SizedBox(height: 25),

          // --- Captured Image ---
          Text(
            "ຮູບພາບທີ່ຖ່າຍ",
            style: Theme.of(context).textTheme.headlineSmall!.copyWith(
              fontFamily: 'NotoSansLao',
              fontWeight: FontWeight.bold,
              color: _accentBlue,
            ),
          ),
          const SizedBox(height: 15),
          Container(
            height: 280,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: _primaryBlue.withOpacity(0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: imageProvider != null
                ? Image(
                    image: imageProvider,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 50,
                              color: Colors.red,
                            ),
                            Text(
                              'ບໍ່ສາມາດສະແດງຮູບພາບໄດ້',
                              style: TextStyle(
                                fontFamily: 'NotoSansLao',
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.broken_image_outlined,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'ບໍ່ມີຮູບພາບທີ່ບັນທຶກ',
                          style: TextStyle(
                            fontFamily: 'NotoSansLao',
                            color: _textMutedColor,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: 25),

          // --- Map Display ---
          Text(
            "ແຜນທີ່ຕຳແໜ່ງ",
            style: Theme.of(context).textTheme.headlineSmall!.copyWith(
              fontFamily: 'NotoSansLao',
              fontWeight: FontWeight.bold,
              color: _accentBlue,
            ),
          ),
          const SizedBox(height: 15),
          Container(
            height: 280,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: _primaryBlue.withOpacity(0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: GoogleMap(
              onMapCreated: (controller) => _mapController = controller,
              initialCameraPosition: CameraPosition(
                target: checkedInLocation,
                zoom: 17,
              ),
              markers: {
                Marker(
                  markerId: const MarkerId('checkedInLocation'),
                  position: checkedInLocation,
                  infoWindow: const InfoWindow(title: 'ຈຸດ Check-in'),
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueGreen,
                  ),
                ),
              },
              zoomGesturesEnabled: false,
              scrollGesturesEnabled: false,
              mapType: MapType.normal,
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // Helper for detail rows in _buildCheckedInView
  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value,
    Color iconColor,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 24, color: iconColor),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'NotoSansLao',
                  fontSize: 14,
                  color: _textMutedColor,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontFamily: 'NotoSansLao',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
