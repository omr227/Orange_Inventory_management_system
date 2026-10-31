import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

class ProductsTrans {
  final String productName;
  final int productId;
  final String uom;

  ProductsTrans({
    required this.productId,
    required this.productName,
    required this.uom,
  });

  factory ProductsTrans.fromJson(Map<String, dynamic> json) {
    return ProductsTrans(
      uom: json['uom'],
      productName: json['productdescription'],
      productId: json['productcode'],
    );
  }
}

class TransactionAddPage extends StatefulWidget {
  final int invoiceId;
  final String vendor;
  final String sentDate;
  final String description;

  const TransactionAddPage({
    super.key,
    required this.sentDate,
    required this.description,
    required this.vendor,
    required this.invoiceId,
  });

  @override
  // ignore: library_private_types_in_public_api, no_logic_in_create_state
  TransactionAddPageState createState() => TransactionAddPageState();
}

class TransactionAddPageState extends State<TransactionAddPage> {
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController();
  TextEditingController _productController = TextEditingController();

  final List<Map<String, dynamic>> _products = [];

  final List<String> _productsList = [];
  final List<int> _productsIDList = [];
  final List<String> _productsUOMList = [];

  @override
  void initState() {
    super.initState();
    debugPrint("${widget.invoiceId}");
    debugPrint(widget.sentDate);
    debugPrint(widget.vendor);
    debugPrint(widget.description);

    loadProducts();
  }

  Future<void> loadProducts() async {
    var headers = {'Authorization': 'Basic T1JBTkdFSU5WOk9yYW5nZSMyMDI1Iw=='};
    var request = http.Request(
      'GET',
      Uri.parse(
        'https://g7bac86685e277f-omarbase.adb.eu-frankfurt-1.oraclecloudapps.com/ords/orangeinv/inv/get_productName_Code?limit=1000',
      ),
    );
    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      final items =
          jsonDecode(await response.stream.bytesToString())['items']
              as List<dynamic>;

      List<ProductsTrans> products = items
          .map((item) => ProductsTrans.fromJson(item))
          .toList();

      setState(() {
        for (var item in products) {
          _productsList.add(item.productName);
          _productsIDList.add(item.productId);
          _productsUOMList.add(item.uom);
        }
      });
    } else {
      debugPrint(response.reasonPhrase);
    }
  }

  bool isloading = false;
  Future<void> saveInvoice() async {
    setState(() => isloading = true);
    var headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Basic T1JBTkdFSU5WOk9yYW5nZSMyMDI1Iw==',
    };
    var request = http.Request(
      'POST',
      Uri.parse(
        'https://g7bac86685e277f-omarbase.adb.eu-frankfurt-1.oraclecloudapps.com/ords/orangeinv/inv/add_invoice',
      ),
    );
    request.body = json.encode(sendTransaction);
    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      debugPrint(await response.stream.bytesToString());
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Created invoice")));

      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Not Created invoice")));

      debugPrint(response.reasonPhrase);
    }
    setState(() => isloading = false);
  }

  double get grandTotal {
    return _products.fold(0.0, (sum, item) {
      return sum + (item['price'] * item['quantity']);
    });
  }

  List<Map<String, dynamic>> sendTransaction = [];
  void _addProduct(int index) {
    for (var record in _products) {
      if (_productController.text == record['name']) return;
    }

    final name = _productController.text.trim();
    final price = double.tryParse(_priceController.text) ?? 0;
    final quantity = double.tryParse(_quantityController.text) ?? 0;

    if (name.isEmpty || price <= 0 || quantity <= 0) return;

    sendTransaction.add({
      "productcode":
          _productsIDList[_productsList.indexOf(_productController.text)],
      "invoiceid": widget.invoiceId,
      "quantity": quantity,
      "price": price,
      "transactionstatus": "IN",
      "restquantity": quantity,
      "vendor": widget.vendor,
      "destination": "INV",
      "invoicedate": widget.sentDate,
      "invoicestatus": "PAID",
      "overhead": 5,
      "invoice_description": widget.description,
    });
    setState(() {
      _products.add({
        'uom': _productsUOMList[_productsList.indexOf(_productController.text)],
        'name': name,
        'price': price,
        'quantity': quantity,
      });
    });
    _productController.clear();
    _priceController.clear();
    _quantityController.clear();
  }

  void _deleteProduct(int index) {
    sendTransaction.removeAt(index - 1);
    setState(() {
      _products.removeAt(index - 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    return isloading
        ? Scaffold(
            body: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blueGrey,Colors.black,],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(child: CircularProgressIndicator()),
            ),
          )
        : Scaffold(
            resizeToAvoidBottomInset: true, // fixes keyboard overflow
            extendBodyBehindAppBar: true,
            appBar: AppBar(
              title: Text(
                "Invoice#${widget.invoiceId}",
                style: TextStyle(color: Colors.white),
              ),

              backgroundColor: Colors.transparent,
            ),
            body: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blueGrey,Colors.black],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: _productsList.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      children: [
                        // Input fields
                        // Product list takes remaining space
                        Expanded(
                          child: ListView.builder(
                            itemCount: _products.length + 1,
                            itemBuilder: (context, index) {
                              if (index == 0) {
                                return Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    children: [
                                      Autocomplete<String>(
                                        optionsBuilder:
                                            (
                                              TextEditingValue textEditingValue,
                                            ) {
                                              if (textEditingValue
                                                  .text
                                                  .isEmpty) {
                                                return const Iterable<
                                                  String
                                                >.empty();
                                              }
                                              return _productsList.where(
                                                (product) => product
                                                    .toLowerCase()
                                                    .contains(
                                                      textEditingValue.text
                                                          .toLowerCase(),
                                                    ),
                                              );
                                            },
                                        onSelected: (String selection) {
                                          setState(() {
                                            _productController.text =
                                                selection; // sync with controller
                                          });
                                        },
                                        fieldViewBuilder:
                                            (
                                              context,
                                              controller,
                                              focusNode,
                                              onEditingComplete,
                                            ) {
                                              _productController =
                                                  controller; // link
                                              return TextField(
                                                controller: _productController,
                                                focusNode: focusNode,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                ),
                                                decoration: _inputDecoration(
                                                  "Product / المنتج",
                                                ),
                                              );
                                            },
                                        optionsViewBuilder:
                                            (context, onSelected, options) {
                                              return Align(
                                                alignment: Alignment.topLeft,
                                                child: Material(
                                                  color: Colors.black,
                                                  child: ListView.builder(
                                                    shrinkWrap: true,
                                                    itemCount: options.length,
                                                    itemBuilder: (context, index) {
                                                      final option = options
                                                          .elementAt(index);
                                                      return ListTile(
                                                        title: Text(
                                                          option,
                                                          style:
                                                              const TextStyle(
                                                                color: Colors
                                                                    .white,
                                                              ),
                                                        ),
                                                        onTap: () =>
                                                            onSelected(option),
                                                      );
                                                    },
                                                  ),
                                                ),
                                              );
                                            },
                                      ),
                                      TextField(
                                        controller: _priceController,
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                        keyboardType:
                                            const TextInputType.numberWithOptions(
                                              decimal: true,
                                            ),
                                        inputFormatters: [
                                          FilteringTextInputFormatter.allow(
                                            RegExp(r'^\d*\.?\d*'),
                                          ),
                                        ],
                                        decoration: _inputDecoration(
                                          "Price / السعر",
                                        ),
                                      ),
                                      TextField(
                                        controller: _quantityController,
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                        keyboardType:
                                            const TextInputType.numberWithOptions(
                                              decimal: true,
                                            ),
                                        inputFormatters: [
                                          FilteringTextInputFormatter.allow(
                                            RegExp(r'^\d*\.?\d*'),
                                          ),
                                        ],
                                        decoration: _inputDecoration(
                                          "Quantity / الكمية",
                                        ),
                                      ),

                                      const SizedBox(height: 10),
                                      TextButton(
                                        onPressed: () {
                                          _addProduct(index);
                                        },
                                        child: Text(
                                          "ADD",
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }

                              final item = _products[index - 1];

                              return Card(
                                color: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                child: ListTile(
                                  title: Text(
                                    item['name'],
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(
                                    "Price: ${item['price']} EGP ×  ${item['quantity']} ${item['uom']} = ${(item['price'] * item['quantity']).toStringAsFixed(2)}",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  trailing: IconButton(
                                    icon: Icon(
                                      Icons.delete,
                                      color: Colors.grey[900],
                                    ),
                                    onPressed: () => _deleteProduct(index),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Grand Total: ${grandTotal.toStringAsFixed(2)}",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 10),
                            IconButton(
                              onPressed: _products.isEmpty ? null : saveInvoice,
                              icon: Icon(Icons.save),
                            ),
                          ],
                        ),
                      ],
                    ),
            ),

            // Grand Total always fixed at bottom
          );
  }
}

InputDecoration _inputDecoration(String label) {
  return InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: Colors.white),
  );
}
