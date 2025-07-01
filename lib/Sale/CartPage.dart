import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CartItem {
  String name;
  int quantity;
  double price;

  CartItem({required this.name, required this.quantity, required this.price});

  double get total => quantity * price;
}

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final List<CartItem> _cartItems = [
    CartItem(name: "ນ້ຳດື່ມຕິດໂຕ", quantity: 2, price: 5000),
    CartItem(name: "ຂອງຄົວ", quantity: 1, price: 15000),
  ];
  double _discount = 0.0;

  final currencyFormat = NumberFormat.currency(
    locale: 'lo_LA',
    symbol: '₭',
    decimalDigits: 0,
  );

  double get _subtotal => _cartItems.fold(0, (sum, item) => sum + item.total);
  double get _total => _subtotal - _discount;

  void _updateQuantity(int index, bool increase) {
    setState(() {
      if (increase) {
        _cartItems[index].quantity++;
      } else if (_cartItems[index].quantity > 1) {
        _cartItems[index].quantity--;
      }
    });
  }

  void _updateDiscount(String value) {
    setState(() {
      _discount = double.tryParse(value) ?? 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'ກະຕ່າສິນຄ້າ',
          style: TextStyle(fontFamily: 'NotoSansLao'),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _cartItems.length,
              itemBuilder: (context, index) {
                final item = _cartItems[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: ListTile(
                    title: Text(
                      item.name,
                      style: const TextStyle(fontFamily: 'NotoSansLao'),
                    ),
                    subtitle: Text(
                      "ລາຄາ: ${currencyFormat.format(item.price)} x ${item.quantity} = ${currencyFormat.format(item.total)}",
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: () => _updateQuantity(index, false),
                        ),
                        Text('${item.quantity}'),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: () => _updateQuantity(index, true),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                TextField(
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'ສ່ວນຫຼຸດ (₭)',
                    prefixIcon: Icon(Icons.discount),
                  ),
                  onChanged: _updateDiscount,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'ລາຄາລວມ:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(currencyFormat.format(_subtotal)),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'ສ່ວນຫຼຸດ:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text('-${currencyFormat.format(_discount)}'),
                  ],
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'ຍອດສຸດທິ:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      currencyFormat.format(_total),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.payment),
                    label: const Text(
                      'ດຳເນີນການຊຳລະ',
                      style: TextStyle(fontFamily: 'NotoSansLao'),
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'ຊຳລະສຳເລັດ: ${currencyFormat.format(_total)}',
                          ),
                        ),
                      );
                    },
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
