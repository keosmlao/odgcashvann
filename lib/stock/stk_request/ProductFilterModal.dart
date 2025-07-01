import 'package:flutter/material.dart';
import 'package:odgcashvan/stock/brand.dart';
import 'package:odgcashvan/stock/cat.dart';
import 'package:odgcashvan/stock/group_sub.dart';
import 'package:odgcashvan/stock/group_sub_2.dart';
import 'package:odgcashvan/stock/groupmain.dart';
import 'package:odgcashvan/stock/pettern.dart';

class ProductFilterModal extends StatefulWidget {
  final String wh_code;
  final String sh_code;
  final Map<String, String?> initialFilters; // To pre-fill filter fields

  const ProductFilterModal({
    super.key,
    required this.wh_code,
    required this.sh_code,
    required this.initialFilters,
  });

  @override
  State<ProductFilterModal> createState() => _ProductFilterModalState();
}

class _ProductFilterModalState extends State<ProductFilterModal> {
  // Local controllers for filter input fields
  final TextEditingController _groupMainNameController =
      TextEditingController();
  final TextEditingController _groupSubNameController = TextEditingController();
  final TextEditingController _groupSub2NameController =
      TextEditingController();
  final TextEditingController _catNameController = TextEditingController();
  final TextEditingController _brandNameController = TextEditingController();
  final TextEditingController _patternNameController = TextEditingController();

  // Local variables to hold selected filter codes (what will be returned)
  String? _selectedGroupMainCode;
  String? _selectedGroupSubCode;
  String? _selectedGroupSub2Code;
  String? _selectedCatCode;
  String? _selectedBrandCode;
  String? _selectedPatternCode;

  // Theme Colors (consistent with ListProductForRequest)
  final Color _primaryColor = const Color(0xFF64B5F6); // Light Blue
  final Color _accentColor = const Color(0xFF2196F3); // Deeper Blue
  final Color _textColorPrimary = const Color(0xFF212121); // Almost black
  final Color _textColorSecondary = const Color(0xFF757575); // Medium grey

  @override
  void initState() {
    super.initState();
    // Initialize controllers and selected codes from initialFilters
    _selectedGroupMainCode = widget.initialFilters['group_main'];
    _selectedGroupSubCode = widget.initialFilters['group_sub'];
    _selectedGroupSub2Code = widget.initialFilters['group_sub_2'];
    _selectedCatCode = widget.initialFilters['cat'];
    _selectedBrandCode = widget.initialFilters['brand'];
    _selectedPatternCode = widget.initialFilters['pattern'];

    // For names, we'd ideally get them from the codes, but for simplicity,
    // if the modal is dismissed and reopened, the names would be lost unless
    // a reverse lookup is performed or names are also passed (more complex).
    // For now, we'll leave name controllers empty if codes are present
    // but names aren't explicitly passed.
    // If you need names to persist, you'd need to pass them from ListProductForRequest as well.
  }

  @override
  void dispose() {
    _groupMainNameController.dispose();
    _groupSubNameController.dispose();
    _groupSub2NameController.dispose();
    _catNameController.dispose();
    _brandNameController.dispose();
    _patternNameController.dispose();
    super.dispose();
  }

  void _clearFilters() {
    setState(() {
      _groupMainNameController.clear();
      _groupSubNameController.clear();
      _groupSub2NameController.clear();
      _catNameController.clear();
      _brandNameController.clear();
      _patternNameController.clear();

      _selectedGroupMainCode = null;
      _selectedGroupSubCode = null;
      _selectedGroupSub2Code = null;
      _selectedCatCode = null;
      _selectedBrandCode = null;
      _selectedPatternCode = null;
    });
  }

  void _applyFilters() {
    Navigator.pop(context, {
      'group_main': _selectedGroupMainCode,
      'group_sub': _selectedGroupSubCode,
      'group_sub_2': _selectedGroupSub2Code,
      'cat': _selectedCatCode,
      'brand': _selectedBrandCode,
      'pattern': _selectedPatternCode,
    });
  }

  // Helper widget to build a filter selection field
  Widget _buildFilterSelectField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    required VoidCallback onPressed,
    required VoidCallback onClear, // Added onClear callback
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        readOnly: true,
        style: TextStyle(
          fontSize: 16,
          color: _textColorPrimary,
          fontFamily: 'NotoSansLao',
        ),
        decoration: InputDecoration(
          labelText: labelText,
          labelStyle: TextStyle(
            color: _textColorSecondary,
            fontFamily: 'NotoSansLao',
          ),
          floatingLabelStyle: TextStyle(
            color: _accentColor,
            fontWeight: FontWeight.bold,
            fontFamily: 'NotoSansLao',
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: _accentColor, width: 2),
          ),
          suffixIcon: controller.text.isNotEmpty
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.clear, color: Colors.grey.shade600),
                      onPressed: onClear,
                    ),
                    IconButton(
                      icon: Icon(Icons.search, color: _accentColor),
                      onPressed: onPressed,
                    ),
                  ],
                )
              : IconButton(
                  icon: Icon(Icons.search, color: _accentColor),
                  onPressed: onPressed,
                ),
          prefixIcon: Icon(icon, color: _primaryColor),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        onTap: onPressed, // Allow tapping the field to open selection
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height:
          MediaQuery.of(context).size.height *
          0.85, // Take 85% of screen height
      decoration: BoxDecoration(
        color: Theme.of(context).canvasColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      child: Column(
        children: [
          // Drag handle and Title
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Container(
                  height: 5,
                  width: 50,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "ກັ່ນຕອງສິນຄ້າ", // Filter Products
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: _textColorPrimary,
                        fontFamily: 'NotoSansLao',
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: _textColorSecondary),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(),
              ],
            ),
          ),
          // Filter fields
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              children: [
                _buildFilterSelectField(
                  controller: _groupMainNameController,
                  labelText: "ກຸ່ມຫຼັກ", // Group Main
                  icon: Icons.bookmark_outline,
                  onPressed: () async {
                    final result = await Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => GroupMain()),
                    );
                    if (result != null) {
                      setState(() {
                        _groupMainNameController.text = result['name_1'];
                        _selectedGroupMainCode = result['code'];
                      });
                    }
                  },
                  onClear: () {
                    // Clear for Group Main
                    setState(() {
                      _groupMainNameController.clear();
                      _selectedGroupMainCode = null;
                      _groupSubNameController.clear();
                      _selectedGroupSubCode = null;
                      _groupSub2NameController.clear();
                      _selectedGroupSub2Code = null;
                    });
                  },
                ),
                _buildFilterSelectField(
                  controller: _groupSubNameController,
                  labelText: "ກຸ່ມຍ່ອຍ 1", // Group Sub 1
                  icon: Icons.category_outlined,
                  onPressed: () async {
                    if (_selectedGroupMainCode == null ||
                        _selectedGroupMainCode!.isEmpty) {
                      // Show warning if main group not selected
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'ກະລຸນາເລືອກກຸ່ມຫຼັກກ່ອນ',
                            style: TextStyle(fontFamily: 'NotoSansLao'),
                          ),
                        ),
                      );
                      return;
                    }
                    final result = await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) =>
                            GroupSub(groupMain: _selectedGroupMainCode!),
                      ),
                    );
                    if (result != null) {
                      setState(() {
                        _groupSubNameController.text = result['name_1'];
                        _selectedGroupSubCode = result['code'];
                      });
                    }
                  },
                  onClear: () {
                    // Clear for Group Sub
                    setState(() {
                      _groupSubNameController.clear();
                      _selectedGroupSubCode = null;
                      _groupSub2NameController.clear();
                      _selectedGroupSub2Code = null;
                    });
                  },
                ),
                _buildFilterSelectField(
                  controller: _groupSub2NameController,
                  labelText: "ກຸ່ມຍ່ອຍ 2", // Group Sub 2
                  icon: Icons.class_outlined,
                  onPressed: () async {
                    if (_selectedGroupSubCode == null ||
                        _selectedGroupSubCode!.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'ກະລຸນາເລືອກກຸ່ມຍ່ອຍ 1 ກ່ອນ',
                            style: TextStyle(fontFamily: 'NotoSansLao'),
                          ),
                        ),
                      );
                      return;
                    }
                    final result = await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => GroupSub2(
                          group_main: _selectedGroupMainCode!,
                          group_sub: _selectedGroupSubCode!,
                        ),
                      ),
                    );
                    if (result != null) {
                      setState(() {
                        _groupSub2NameController.text = result['name_1'];
                        _selectedGroupSub2Code = result['code'];
                      });
                    }
                  },
                  onClear: () {
                    // Clear for Group Sub 2
                    setState(() {
                      _groupSub2NameController.clear();
                      _selectedGroupSub2Code = null;
                    });
                  },
                ),
                _buildFilterSelectField(
                  controller: _catNameController,
                  labelText: "ໝວດ", // Category
                  icon: Icons.widgets_outlined,
                  onPressed: () async {
                    final result = await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => Cat(
                          wh_code: widget.wh_code,
                          sh_code: widget.sh_code,
                          group_main: _selectedGroupMainCode ?? '',
                          group_sub: _selectedGroupSubCode ?? '',
                          group_sub_2: _selectedGroupSub2Code ?? '',
                          cat:
                              _selectedCatCode ?? '', // Pass current cat filter
                          pattern:
                              _selectedPatternCode ??
                              '', // Pass current pattern filter
                          brand:
                              _selectedBrandCode ??
                              '', // Pass current brand filter
                        ),
                      ),
                    );
                    if (result != null) {
                      setState(() {
                        _catNameController.text = result['name_1'];
                        _selectedCatCode = result['code'];
                      });
                    }
                  },
                  onClear: () {
                    // Clear for Category
                    setState(() {
                      _catNameController.clear();
                      _selectedCatCode = null;
                    });
                  },
                ),
                _buildFilterSelectField(
                  controller: _brandNameController,
                  labelText: "ຫຍີ່ຫໍ້", // Brand
                  icon: Icons.branding_watermark_outlined,
                  onPressed: () async {
                    final result = await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => Brand(
                          wh_code: widget.wh_code,
                          sh_code: widget.sh_code,
                          group_main: _selectedGroupMainCode ?? '',
                          group_sub: _selectedGroupSubCode ?? '',
                          group_sub_2: _selectedGroupSub2Code ?? '',
                          cat: _selectedCatCode ?? '',
                          pattern: _selectedPatternCode ?? '',
                          brand:
                              _selectedBrandCode ??
                              '', // Pass current brand filter
                        ),
                      ),
                    );
                    if (result != null) {
                      setState(() {
                        _brandNameController.text = result['name_1'];
                        _selectedBrandCode = result['code'];
                      });
                    }
                  },
                  onClear: () {
                    // Clear for Brand
                    setState(() {
                      _brandNameController.clear();
                      _selectedBrandCode = null;
                    });
                  },
                ),
                _buildFilterSelectField(
                  controller: _patternNameController,
                  labelText: "ຮູບແບບ", // Pattern
                  icon: Icons.style_outlined,
                  onPressed: () async {
                    final result = await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => Pettern(
                          wh_code: widget.wh_code,
                          sh_code: widget.sh_code,
                          group_main: _selectedGroupMainCode ?? '',
                          group_sub: _selectedGroupSubCode ?? '',
                          group_sub_2: _selectedGroupSub2Code ?? '',
                          cat: _selectedCatCode ?? '',
                          pattern:
                              _selectedPatternCode ??
                              '', // Pass current pattern filter
                          brand: _selectedBrandCode ?? '',
                        ),
                      ),
                    );
                    if (result != null) {
                      setState(() {
                        _patternNameController.text = result['name_1'];
                        _selectedPatternCode = result['code'];
                      });
                    }
                  },
                  onClear: () {
                    // Clear for Pattern
                    setState(() {
                      _patternNameController.clear();
                      _selectedPatternCode = null;
                    });
                  },
                ),
              ],
            ),
          ),
          // Action Buttons
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade300,
                      foregroundColor: _textColorPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: _clearFilters,
                    child: const Text(
                      "ລ້າງການກັ່ນຕອງ", // Clear Filter
                      style: TextStyle(
                        fontSize: 18,
                        fontFamily: 'NotoSansLao',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accentColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: _applyFilters,
                    child: const Text(
                      "ນຳໃຊ້ການກັ່ນຕອງ", // Apply Filter
                      style: TextStyle(
                        fontSize: 18,
                        fontFamily: 'NotoSansLao',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
