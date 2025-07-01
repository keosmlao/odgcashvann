import 'dart:async'; // For Timer
import 'dart:convert';
import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For PlatformException
import 'package:http/http.dart' as http; // Use http alias
import 'package:odgcashvan/stock/cat.dart';
import '../../utility/my_constant.dart';
// import '../../utility/my_style.dart'; // We'll replace MyStyle with AppColors
import '../../utility/app_colors.dart'; // New import for AppColors
import '../brand.dart';
import '../group_sub.dart';
import '../group_sub_2.dart';
import '../groupmain.dart';
import '../pettern.dart';
import 'productdetailforrequest.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart'; // For modern icons

// Define a class to hold the filter data, making it easier to pass around
class ProductFilterData {
  String? groupMainCode;
  String? groupSubCode;
  String? groupSub2Code;
  String? categoryCode;
  String? brandCode;
  String? patternCode;

  TextEditingController groupMainNameController;
  TextEditingController groupSubNameController;
  TextEditingController groupSub2NameController;
  TextEditingController categoryController;
  TextEditingController brandController;
  TextEditingController patternController;

  ProductFilterData({
    this.groupMainCode = '',
    this.groupSubCode = '',
    this.groupSub2Code = '',
    this.categoryCode = '',
    this.brandCode = '',
    this.patternCode = '',
  }) : groupMainNameController = TextEditingController(),
       groupSubNameController = TextEditingController(),
       groupSub2NameController = TextEditingController(),
       categoryController = TextEditingController(),
       brandController = TextEditingController(),
       patternController = TextEditingController();

  // Constructor to initialize from existing filter data
  ProductFilterData.fromExisting({
    this.groupMainCode, // Use optional for consistency with default
    this.groupSubCode,
    this.groupSub2Code,
    this.categoryCode,
    this.brandCode,
    this.patternCode,
    required String groupMainName,
    required String groupSubName,
    required String groupSub2Name,
    required String categoryName,
    required String brandName,
    required String patternName,
  }) : groupMainNameController = TextEditingController(text: groupMainName),
       groupSubNameController = TextEditingController(text: groupSubName),
       groupSub2NameController = TextEditingController(text: groupSub2Name),
       categoryController = TextEditingController(text: categoryName),
       brandController = TextEditingController(text: brandName),
       patternController = TextEditingController(text: patternName);

  void dispose() {
    groupMainNameController.dispose();
    groupSubNameController.dispose();
    groupSub2NameController.dispose();
    categoryController.dispose();
    brandController.dispose();
    patternController.dispose();
  }

  // Method to check if any filter is applied
  bool areFiltersApplied() {
    return (groupMainCode?.isNotEmpty ?? false) ||
        (groupSubCode?.isNotEmpty ?? false) ||
        (groupSub2Code?.isNotEmpty ?? false) ||
        (categoryCode?.isNotEmpty ?? false) ||
        (brandCode?.isNotEmpty ?? false) ||
        (patternCode?.isNotEmpty ?? false);
  }
}

// Separate StatefulWidget for the Filter Modal to manage its own state
class ProductFilterModal extends StatefulWidget {
  final String whCode;
  final String shCode;
  final ProductFilterData initialFilterData;

  const ProductFilterModal({
    super.key,
    required this.whCode,
    required this.shCode,
    required this.initialFilterData,
  });

  @override
  State<ProductFilterModal> createState() => _ProductFilterModalState();
}

class _ProductFilterModalState extends State<ProductFilterModal> {
  late ProductFilterData _currentFilterData;

  @override
  void initState() {
    super.initState();
    // Deep copy initial data to allow independent modification in modal
    _currentFilterData = ProductFilterData.fromExisting(
      groupMainCode: widget.initialFilterData.groupMainCode,
      groupSubCode: widget.initialFilterData.groupSubCode,
      groupSub2Code: widget.initialFilterData.groupSub2Code,
      categoryCode: widget.initialFilterData.categoryCode,
      brandCode: widget.initialFilterData.brandCode,
      patternCode: widget.initialFilterData.patternCode,
      groupMainName: widget.initialFilterData.groupMainNameController.text,
      groupSubName: widget.initialFilterData.groupSubNameController.text,
      groupSub2Name: widget.initialFilterData.groupSub2NameController.text,
      categoryName: widget.initialFilterData.categoryController.text,
      brandName: widget.initialFilterData.brandController.text,
      patternName: widget.initialFilterData.patternController.text,
    );
  }

  @override
  void dispose() {
    _currentFilterData.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.8, // Start at 80% of screen height
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false, // Don't expand to full screen by default
      builder: (_, controller) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Modal drag handle
              Container(
                height: 5,
                width: 40,
                decoration: BoxDecoration(
                  color: AppColors.grey300,
                  borderRadius: BorderRadius.circular(5),
                ),
                margin: const EdgeInsets.only(bottom: 16),
              ),
              Text(
                'ກັ່ນຕອງສິນຄ້າ',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.accentBlue, // Using AppColors
                ),
              ),
              const Divider(),
              Expanded(
                child: ListView(
                  controller: controller,
                  children: [
                    _buildFilterInputField(
                      context: context,
                      controller: _currentFilterData.groupMainNameController,
                      hintText: "ກຸ່ມຫຼັກ",
                      onTap: () async {
                        final result = await Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => GroupMain()),
                        );
                        if (result != null) {
                          setState(() {
                            _currentFilterData.groupMainNameController.text =
                                result['name_1'];
                            _currentFilterData.groupMainCode = result['code'];
                            // Clear dependent fields when main group changes
                            _currentFilterData.groupSubNameController.clear();
                            _currentFilterData.groupSubCode = '';
                            _currentFilterData.groupSub2NameController.clear();
                            _currentFilterData.groupSub2Code = '';
                            _currentFilterData.categoryController.clear();
                            _currentFilterData.categoryCode = '';
                            _currentFilterData.brandController.clear();
                            _currentFilterData.brandCode = '';
                            _currentFilterData.patternController.clear();
                            _currentFilterData.patternCode = '';
                          });
                        }
                      },
                    ),
                    _buildFilterInputField(
                      context: context,
                      controller: _currentFilterData.groupSubNameController,
                      hintText: "ກຸ່ມຍ່ອຍ 1",
                      onTap: () async {
                        if ((_currentFilterData.groupMainCode?.isEmpty ??
                            true)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('ກະລຸນາເລືອກກຸ່ມຫຼັກກ່ອນ'),
                            ),
                          );
                          return;
                        }
                        final result = await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => GroupSub(
                              groupMain: _currentFilterData.groupMainCode
                                  .toString(),
                            ),
                          ),
                        );
                        if (result != null) {
                          setState(() {
                            _currentFilterData.groupSubNameController.text =
                                result['name_1'];
                            _currentFilterData.groupSubCode = result['code'];
                            // Clear dependent fields
                            _currentFilterData.groupSub2NameController.clear();
                            _currentFilterData.groupSub2Code = '';
                            _currentFilterData.categoryController.clear();
                            _currentFilterData.categoryCode = '';
                            _currentFilterData.brandController.clear();
                            _currentFilterData.brandCode = '';
                            _currentFilterData.patternController.clear();
                            _currentFilterData.patternCode = '';
                          });
                        }
                      },
                    ),
                    _buildFilterInputField(
                      context: context,
                      controller: _currentFilterData.groupSub2NameController,
                      hintText: "ກຸ່ມຍ່ອຍ 2",
                      onTap: () async {
                        if ((_currentFilterData.groupMainCode?.isEmpty ??
                                true) ||
                            (_currentFilterData.groupSubCode?.isEmpty ??
                                true)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'ກະລຸນາເລືອກກຸ່ມຫຼັກ ແລະ ກຸ່ມຍ່ອຍ 1 ກ່ອນ',
                              ),
                            ),
                          );
                          return;
                        }
                        final result = await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => GroupSub2(
                              group_main: _currentFilterData.groupMainCode
                                  .toString(),
                              group_sub: _currentFilterData.groupSubCode
                                  .toString(),
                            ),
                          ),
                        );
                        if (result != null) {
                          setState(() {
                            _currentFilterData.groupSub2NameController.text =
                                result['name_1'];
                            _currentFilterData.groupSub2Code = result['code'];
                            // Clear dependent fields
                            _currentFilterData.categoryController.clear();
                            _currentFilterData.categoryCode = '';
                            _currentFilterData.brandController.clear();
                            _currentFilterData.brandCode = '';
                            _currentFilterData.patternController.clear();
                            _currentFilterData.patternCode = '';
                          });
                        }
                      },
                    ),
                    _buildFilterInputField(
                      context: context,
                      controller: _currentFilterData.categoryController,
                      hintText: "ໝວດ",
                      onTap: () async {
                        final result = await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => Cat(
                              wh_code: widget.whCode,
                              sh_code: widget.shCode,
                              group_main: _currentFilterData.groupMainCode
                                  .toString(),
                              group_sub: _currentFilterData.groupSubCode
                                  .toString(),
                              group_sub_2: _currentFilterData.groupSub2Code
                                  .toString(),
                              cat: _currentFilterData.categoryCode
                                  .toString(), // This should be passed as filter
                              pattern: _currentFilterData.patternCode
                                  .toString(), // This should be passed as filter
                              brand: _currentFilterData.brandCode
                                  .toString(), // This should be passed as filter
                            ),
                          ),
                        );
                        if (result != null) {
                          setState(() {
                            _currentFilterData.categoryController.text =
                                result['name_1'];
                            _currentFilterData.categoryCode = result['code'];
                            // Clear dependent fields
                            _currentFilterData.brandController.clear();
                            _currentFilterData.brandCode = '';
                            _currentFilterData.patternController.clear();
                            _currentFilterData.patternCode = '';
                          });
                        }
                      },
                    ),
                    _buildFilterInputField(
                      context: context,
                      controller: _currentFilterData.patternController,
                      hintText: "ຮູບແບບ",
                      onTap: () async {
                        final result = await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => Pettern(
                              wh_code: widget.whCode,
                              sh_code: widget.shCode,
                              group_main: _currentFilterData.groupMainCode
                                  .toString(),
                              group_sub: _currentFilterData.groupSubCode
                                  .toString(),
                              group_sub_2: _currentFilterData.groupSub2Code
                                  .toString(),
                              cat: _currentFilterData.categoryCode.toString(),
                              pattern: _currentFilterData.patternCode
                                  .toString(), // This should be passed as filter
                              brand: _currentFilterData.brandCode
                                  .toString(), // This should be passed as filter
                            ),
                          ),
                        );
                        if (result != null) {
                          setState(() {
                            _currentFilterData.patternController.text =
                                result['name_1'];
                            _currentFilterData.patternCode = result['code'];
                            // Clear dependent fields
                            _currentFilterData.brandController.clear();
                            _currentFilterData.brandCode = '';
                          });
                        }
                      },
                    ),
                    _buildFilterInputField(
                      context: context,
                      controller: _currentFilterData.brandController,
                      hintText: "ຫຍີ່ຫໍ້",
                      onTap: () async {
                        final result = await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => Brand(
                              wh_code: widget.whCode,
                              sh_code: widget.shCode,
                              group_main: _currentFilterData.groupMainCode
                                  .toString(),
                              group_sub: _currentFilterData.groupSubCode
                                  .toString(),
                              group_sub_2: _currentFilterData.groupSub2Code
                                  .toString(),
                              cat: _currentFilterData.categoryCode.toString(),
                              pattern: _currentFilterData.patternCode
                                  .toString(),
                              brand: _currentFilterData.brandCode
                                  .toString(), // This should be passed as filter
                            ),
                          ),
                        );
                        if (result != null) {
                          setState(() {
                            _currentFilterData.brandController.text =
                                result['name_1'];
                            _currentFilterData.brandCode = result['code'];
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // Clear all filters within the modal
                        setState(() {
                          _currentFilterData.groupMainCode = '';
                          _currentFilterData.groupSubCode = '';
                          _currentFilterData.groupSub2Code = '';
                          _currentFilterData.categoryCode = '';
                          _currentFilterData.brandCode = '';
                          _currentFilterData.patternCode = '';
                          _currentFilterData.groupMainNameController.clear();
                          _currentFilterData.groupSubNameController.clear();
                          _currentFilterData.groupSub2NameController.clear();
                          _currentFilterData.categoryController.clear();
                          _currentFilterData.brandController.clear();
                          _currentFilterData.patternController.clear();
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            AppColors.orangeAccent, // Clear button color
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'ລ້າງຄ່າ', // Clear filters
                        style: TextStyle(fontSize: 18, color: AppColors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context, _currentFilterData);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            AppColors.accentBlue, // Apply button color
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'ນຳໃຊ້', // Apply filters
                        style: TextStyle(fontSize: 18, color: AppColors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  /// Helper method for creating a consistent filter input field.
  Widget _buildFilterInputField({
    required BuildContext context,
    required TextEditingController controller,
    required String hintText,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        readOnly: true,
        style: const TextStyle(fontSize: 16, color: AppColors.black87),
        textAlign: TextAlign.center,
        decoration: InputDecoration(
          filled: true,
          fillColor: AppColors.grey100,
          contentPadding: const EdgeInsets.fromLTRB(10.0, 15.0, 10.0, 15.0),
          hintText: hintText,
          hintStyle: const TextStyle(
            fontSize: 16,
            color: AppColors.textColorSecondary,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: BorderSide.none, // Use no border
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: BorderSide(
              color: AppColors.grey300,
              width: 0.8,
            ), // Softer border
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: AppColors.accentBlue, width: 2),
            borderRadius: BorderRadius.circular(10.0),
          ),
          suffixIcon: IconButton(
            icon: const Icon(
              Icons.search,
              size: 24,
              color: AppColors.textColorSecondary,
            ),
            onPressed: onTap,
          ),
        ),
      ),
    );
  }
}

class ListProductForRequest extends StatefulWidget {
  final String wh_code, sh_code;

  const ListProductForRequest({
    super.key,
    required this.wh_code,
    required this.sh_code,
  });

  @override
  State<ListProductForRequest> createState() => _ListProductForRequestState();
}

class _ListProductForRequestState extends State<ListProductForRequest> {
  List<dynamic> _products = [];
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController =
      ScrollController(); // For infinite scrolling

  late ProductFilterData _filterData; // Holds current filter state

  bool _isLoading = false; // Initial loading state (for first fetch/filters)
  bool _isLoadingMore = false; // Loading state for pagination
  int _offset = 0;
  final int _limit = 20; // Number of items to fetch per request
  bool _hasMore = true; // Indicates if there's more data to load

  Timer? _debounce; // For search input debounce

  @override
  void initState() {
    super.initState();
    _filterData = ProductFilterData(); // Initialize filter data
    _fetchProducts(reset: true); // Initial fetch

    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
              _scrollController.position.maxScrollExtent &&
          !_isLoading &&
          !_isLoadingMore &&
          _hasMore) {
        _fetchProducts(reset: false); // Load more data
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _filterData.dispose(); // Dispose controllers in filter data
    _debounce?.cancel(); // Cancel any active debounce timer
    super.dispose();
  }

  /// Fetches product data based on current filters and search query.
  /// `reset` parameter determines if the list should be cleared and pagination reset.
  Future<void> _fetchProducts({bool reset = false}) async {
    if ((_isLoading || _isLoadingMore) && !reset)
      return; // Prevent concurrent fetches unless resetting

    if (reset) {
      setState(() {
        _products.clear();
        _offset = 0;
        _hasMore = true;
        _isLoading = true; // Show main loading indicator
      });
    } else {
      if (!_hasMore) return; // No more data to load
      setState(() {
        _isLoadingMore = true; // Show load more indicator
      });
    }

    try {
      final Map<String, String?> requestBody = {
        "wh_code": widget.wh_code,
        "sh_code": widget.sh_code,
        "group_main": _filterData.groupMainCode,
        "group_sub": _filterData.groupSubCode,
        "group_sub_2": _filterData.groupSub2Code,
        "cat": _filterData.categoryCode,
        "pattern": _filterData.patternCode,
        "item_brand": _filterData.brandCode,
        "query": _searchController.text.trim(), // Use trimmed text for query
        "limit": _limit.toString(),
        "offset": _offset.toString(),
      };

      print('Request Body: ${json.encode(requestBody)}'); // Debugging

      final response = await http.post(
        // Use http.post as you've aliased it
        Uri.parse("${MyConstant().domain}/vanstockforrequest"),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        final List<dynamic> newItems = result['list'] ?? [];

        setState(() {
          if (reset) {
            _products = newItems;
          } else {
            _products.addAll(newItems);
          }
          _offset += newItems
              .length; // Increment offset by actual number of items received
          _hasMore =
              newItems.length ==
              _limit; // Check if the number of items received is equal to the limit
        });
      } else {
        print("Failed to load data: ${response.statusCode} - ${response.body}");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'ໂຫຼດຂໍ້ມູນສິນຄ້າບໍ່ສຳເລັດ: ${response.statusCode}',
                style: const TextStyle(fontFamily: 'NotoSansLao'),
              ),
              backgroundColor: AppColors.errorColor,
            ),
          );
        }
      }
    } catch (error) {
      print("Error fetching products: $error");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'ເກີດຂໍ້ຜິດພາດ. ກະລຸນາກວດສອບການເຊື່ອມຕໍ່: $error',
              style: const TextStyle(fontFamily: 'NotoSansLao'),
            ),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  /// Handles search input with a debounce.
  void _applySearch(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _searchController.text = query.toUpperCase(); // Ensure uppercase
      _fetchProducts(reset: true); // Reset and fetch with new query
    });
  }

  /// Handles barcode scanning.
  Future<void> _scanBarcode() async {
    try {
      final ScanResult barcodeResult = await BarcodeScanner.scan();
      if (!mounted) return; // Check mounted after async operation
      setState(() {
        _searchController.text = barcodeResult.rawContent
            .toUpperCase(); // Ensure uppercase
      });
      _fetchProducts(
        reset: true,
      ); // Fetch products with scanned barcode as query
    } on PlatformException catch (e) {
      if (e.code == BarcodeScanner.cameraAccessDenied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'ບໍ່ອະນຸຍາດເຂົ້າເຖິງກ້ອງ.',
                style: TextStyle(fontFamily: 'NotoSansLao'),
              ),
              backgroundColor: AppColors.errorColor,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'ເກີດຂໍ້ຜິດພາດ: ${e.message}',
                style: const TextStyle(fontFamily: 'NotoSansLao'),
              ),
              backgroundColor: AppColors.errorColor,
            ),
          );
        }
      }
    } on FormatException {
      // User cancelled the scan
      print('Scan cancelled by user');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'ເກີດຂໍ້ຜິດພາດທີ່ບໍ່ຮູ້ຈັກໃນຂະນະສະແກນ: $e',
              style: const TextStyle(fontFamily: 'NotoSansLao'),
            ),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    }
  }

  /// Resets all filter values and re-fetches data.
  void _resetAllFiltersAndSearch() {
    setState(() {
      _filterData.groupMainCode = '';
      _filterData.groupSubCode = '';
      _filterData.groupSub2Code = '';
      _filterData.categoryCode = '';
      _filterData.brandCode = '';
      _filterData.patternCode = '';
      _filterData.groupMainNameController.clear();
      _filterData.groupSubNameController.clear();
      _filterData.groupSub2NameController.clear();
      _filterData.categoryController.clear();
      _filterData.brandController.clear();
      _filterData.patternController.clear();
      _searchController.clear(); // Clear search query as well
    });
    _fetchProducts(reset: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "ລາຍການສິນຄ້າ",
          style: TextStyle(
            color: AppColors.white,
            fontSize: 20,
            fontFamily: 'NotoSansLao',
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.accentBlue, // Using AppColors
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildFilterAndSearchSection(), // Combined section
          Expanded(
            child: RefreshIndicator(
              // Added RefreshIndicator
              onRefresh: () => _fetchProducts(reset: true),
              color: AppColors.primaryBlue,
              child: _buildProductList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterAndSearchSection() {
    bool areFiltersActive = _filterData.areFiltersApplied();

    return Container(
      color: AppColors.secondaryBlue, // Using AppColors
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildFilterActionButton(
                label: "ທັງໝົດ",
                icon: Icons.select_all, // Changed icon for "All"
                isSelected: !areFiltersActive,
                onPressed:
                    _resetAllFiltersAndSearch, // Reset all filters and search
              ),
              const SizedBox(width: 8),
              _buildFilterActionButton(
                label: "ກັ່ນຕອງ",
                icon: Icons.filter_alt,
                isSelected: areFiltersActive,
                onPressed: () async {
                  final ProductFilterData? newFilterData =
                      await showModalBottomSheet<ProductFilterData>(
                        context: context,
                        isScrollControlled: true,
                        builder: (BuildContext context) {
                          return ProductFilterModal(
                            whCode: widget.wh_code,
                            shCode: widget.sh_code,
                            initialFilterData: ProductFilterData.fromExisting(
                              groupMainCode: _filterData.groupMainCode,
                              groupSubCode: _filterData.groupSubCode,
                              groupSub2Code: _filterData.groupSub2Code,
                              categoryCode: _filterData.categoryCode,
                              brandCode: _filterData.brandCode,
                              patternCode: _filterData.patternCode,
                              groupMainName:
                                  _filterData.groupMainNameController.text,
                              groupSubName:
                                  _filterData.groupSubNameController.text,
                              groupSub2Name:
                                  _filterData.groupSub2NameController.text,
                              categoryName: _filterData.categoryController.text,
                              brandName: _filterData.brandController.text,
                              patternName: _filterData.patternController.text,
                            ),
                          );
                        },
                      );

                  if (newFilterData != null) {
                    setState(() {
                      _filterData.dispose(); // Dispose old controllers
                      _filterData = newFilterData; // Assign new filter data
                    });
                    _fetchProducts(
                      reset: true,
                    ); // Re-fetch products with new filters
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildSearchBar(),
        ],
      ),
    );
  }

  Widget _buildFilterActionButton({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onPressed,
  }) {
    return Expanded(
      child: OutlinedButton.icon(
        icon: Icon(
          icon,
          color: isSelected ? AppColors.white : AppColors.textColorPrimary,
        ),
        style: OutlinedButton.styleFrom(
          backgroundColor: isSelected
              ? AppColors.filterButtonActive
              : AppColors.white,
          side: BorderSide(
            color: isSelected
                ? AppColors.filterButtonActive
                : AppColors.grey300, // Softer border when not selected
            width: 1.5, // Slightly thinner border
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8), // Slightly less rounded
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 8,
          ), // Reduced padding
        ),
        onPressed: onPressed,
        label: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.white : AppColors.textColorPrimary,
            fontSize: 15, // Slightly smaller font size
            fontFamily: 'NotoSansLao',
          ),
        ),
      ),
    );
  }

  /// Builds the search bar with text input and QR scanner.
  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      onChanged: _applySearch, // Use the debounced search function
      decoration: InputDecoration(
        filled: true,
        fillColor: AppColors.white,
        contentPadding: const EdgeInsets.fromLTRB(10.0, 5.0, 10.0, 5.0),
        hintText: "ຄົ້ນຫາສິນຄ້າ",
        hintStyle: const TextStyle(
          color: AppColors.textColorSecondary,
          fontFamily: 'NotoSansLao',
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(color: AppColors.transparent),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.accentBlue, width: 2),
          borderRadius: BorderRadius.circular(8.0),
        ),
        prefixIcon: const Icon(
          Icons.search,
          color: AppColors.textColorSecondary,
        ),
        suffixIcon: IconButton(
          icon: Icon(Icons.qr_code_scanner_sharp, color: AppColors.blueGrey),
          onPressed: _scanBarcode,
        ),
      ),
    );
  }

  /// Builds the main product list display area.
  Widget _buildProductList() {
    if (_isLoading && _products.isEmpty) {
      // Show initial loading spinner if no data yet
      return Center(
        child: CircularProgressIndicator(color: AppColors.primaryBlue),
      );
    } else if (_products.isEmpty && !_isLoading) {
      // No products found after loading
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 80,
              color: AppColors.grey300,
            ),
            const SizedBox(height: 20),
            Text(
              "ບໍ່ມີຂໍ້ມູນສິນຄ້າ",
              style: TextStyle(
                fontSize: 18,
                color: AppColors.textColorSecondary,
                fontFamily: 'NotoSansLao',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "ລອງປັບປຸງການກັ່ນຕອງ ຫຼື ຄົ້ນຫາໃໝ່.",
              style: TextStyle(
                fontSize: 14,
                color: AppColors.grey500,
                fontFamily: 'NotoSansLao',
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    } else {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: AppColors.grey500.withOpacity(0.1), // Softer shadow
              spreadRadius: 1, // Reduced spread
              blurRadius: 5, // Reduced blur
              offset: const Offset(0, 2), // Smaller offset
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            double maxWidth = constraints.maxWidth;
            int crossAxisCount = maxWidth < 600 ? 2 : 4;

            return GridView.builder(
              controller: _scrollController, // Attach scroll controller
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1.5 / 2, // Keep aspect ratio consistent
              ),
              padding: const EdgeInsets.all(10),
              itemCount:
                  _products.length +
                  (_hasMore ? 1 : 0), // Add 1 for loading indicator
              itemBuilder: (context, index) {
                if (index == _products.length) {
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Center(
                      child: _isLoadingMore
                          ? CircularProgressIndicator(
                              color: AppColors.primaryBlue,
                            ) // Show loading indicator
                          : (_hasMore
                                ? const SizedBox.shrink()
                                : Text(
                                    'ໝົດຂໍ້ມູນແລ້ວ',
                                    style: TextStyle(
                                      color: AppColors.textColorSecondary,
                                      fontFamily: 'NotoSansLao',
                                    ),
                                  )), // Show "No more data" or empty
                    ),
                  );
                }
                final product = _products[index];
                return _buildProductGridItem(product);
              },
            );
          },
        ),
      );
    }
  }

  /// Builds a single product item for the grid view.
  Widget _buildProductGridItem(Map<String, dynamic> product) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailForRequest(
                item_code: product['ic_code'].toString(),
                item_name: product['ic_name'].toString(),
                unit_code: product['ic_unit_code'].toString(),
                barcode: product['barcode'].toString(),
                qty: product['balance_qty'],
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Image.network(
                  'https://via.placeholder.com/200', // Placeholder image URL
                  width: double.infinity,
                  height:
                      100, // Consider if this fixed height is good for all grid items
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                            : null,
                        color: AppColors.primaryBlue,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.image_not_supported,
                      size: 60,
                      color: AppColors.grey300,
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              Text(
                product['ic_name'] ?? 'Unknown Product',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'NotoSansLao',
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                'ຄົງເຫຼືອ ${product['balance_qty'] ?? '0'}',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.blueGrey,
                  fontFamily: 'NotoSansLao',
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
