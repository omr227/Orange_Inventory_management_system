import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'coustum.dart' as coustum;

class Product {
  final int productId;
  final String productName;
  final String category;
  final String uom;
  final int productcode;

  Product({
    required this.productcode,
    required this.productId,
    required this.productName,
    required this.category,
    required this.uom,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      productcode: json['productcode']??"null",
      productId: json['productid']??"null",
      productName: json['productdescription']??"null",
      category: json['category']??"null",
      uom: json['uom']??"null",
    );
  }
}

class ItemsPage extends StatefulWidget {
  const ItemsPage({super.key});

  @override
  State<ItemsPage> createState() => _ItemsPageState();
}

class _ItemsPageState extends State<ItemsPage> {
  final List<Product> _productItems = [];
  final TextEditingController _searchController = TextEditingController();
  int _selectedItem = 0;
  String? _itemName;
  String _searchQuery = "";

  bool _isMenuOpen = false;

  String? _selectedCategory;
  String? _selectedUOM;

  @override
  void initState() {
    super.initState();
    loadItems();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<dynamic> ids = [];
  List<dynamic> codes = [];
  bool isLoading = true;
  Future<void> loadItems() async {
_isloadingfunc(true);
    ids.clear();
    codes.clear();
    _productItems.clear();

    var headers = {
      'Authorization': 'Basic T1JBTkdFSU5WOk9yYW5nZSMyMDI1Iw==',
      'Content-Type': 'text/plain',
    };
    var request = http.Request(
      'GET',
      Uri.parse(
        'https://g7bac86685e277f-omarbase.adb.eu-frankfurt-1.oraclecloudapps.com/ords/orangeinv/products/?limit=500',
      ),
    );

    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();
    if (response.statusCode == 200) {
      final items =
          jsonDecode(await response.stream.bytesToString())['items']
              as List<dynamic>;
      setState(() {
        _productItems.clear();
        _productItems.addAll(items.map((e) => Product.fromJson(e)));
        for (var row in _productItems) {
          ids.add(row.productId);
          codes.add(row.productcode);
        }
        ids.sort();
        codes.sort();
      });
    } else {
      debugPrint("Failed to load items: ${response.reasonPhrase}");
    }
    _isloadingfunc(false);
  }
void _isloadingfunc(bool load){
if(load){
  setState(() => isLoading = true); 
}else{
  setState(() => isLoading = false); 
}}
void _showSnackBar(String message, {required int status}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: status == 201|| status == 200 ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.fixed,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12))));}
  Future<void> addItem(
    String name,
    String category,
    String uom,
    int nextId,
    int nextcode,
  ) async {
    _isloadingfunc(true);
    var headers = {'Authorization': 'Basic T1JBTkdFSU5WOk9yYW5nZSMyMDI1Iw=='};
    var request = http.Request(
      'POST',
      Uri.parse(
        'https://g7bac86685e277f-omarbase.adb.eu-frankfurt-1.oraclecloudapps.com/ords/orangeinv/products/?productid=$nextId&productdescription=$name&productcode=$nextcode&category=$category&uom=$uom',
      ),
    );

    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();
    if (response.statusCode == 201) {
        _showSnackBar("Item created successfully", status: 201);
        
    } else {
      _showSnackBar("Failed to create item", status: 555);
      debugPrint("Failed to post");
    }
    await loadItems();
  }

  Future<void> deleteItem() async {
    if (_selectedItem == 0) return;
_isloadingfunc(true);
    var headers = {'Authorization': 'Basic T1JBTkdFSU5WOk9yYW5nZSMyMDI1Iw=='};
    final url =
        "https://g7bac86685e277f-omarbase.adb.eu-frankfurt-1.oraclecloudapps.com/ords/orangeinv/products/$_selectedItem";

    var request = http.Request('DELETE', Uri.parse(url))
      ..headers.addAll(headers);

    http.StreamedResponse response = await request.send();
    if (response.statusCode == 200) {
      _showSnackBar("Item deleted successfully", status: 200);
      await loadItems();
    } else {
      _showSnackBar("Failed to delete item", status: 555);
      debugPrint("Delete failed: ${response.reasonPhrase}");
    }
    _selectedItem = 0;
    _isloadingfunc(false);
  }

  void _toggleCheckbox(bool? value, int itemId, String itemName) {
    setState(() {
      if (value == true) {
        _selectedItem = itemId;
        _itemName = itemName;
      } else {
        _selectedItem = 0;
        _itemName = null;
      }
    });
  }

  void _showAddItemDialog(BuildContext context) {
    final nameController = TextEditingController();
    const categories = [
      'fruit',
      'ice',
      'solo',
      'biscuits',
      'powder',
      'milk',
      'nuts',
      'hygence',
      'drinks',
      'herbs',
      'dessert',
      'cups',
      'flavor',
      'sugar',
    ];
    const uomList = ['kilo', 'gallon', 'liter', 'package', 'row'];

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            backgroundColor: Colors.grey[900],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              "Add Item",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.white,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  coustum.buildTextField(
                    nameController,
                    "Item Name",
                    isNumber: false,
                  ),
                  const SizedBox(height: 16),
                  coustum.buildDropdown(
                    "Select Category",
                    categories,
                    _selectedCategory,
                    (val) => setState(() => _selectedCategory = val),
                  ),
                  const SizedBox(height: 16),
                  coustum.buildDropdown(
                    "Select UOM",
                    uomList,
                    _selectedUOM,
                    (val) => setState(() => _selectedUOM = val),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "Cancel",
                  style: TextStyle(color: Colors.red),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (nameController.text.isNotEmpty &&
                      _selectedCategory != null &&
                      _selectedUOM != null) {
                    Navigator.pop(context);
                      addItem(
                      nameController.text,
                      _selectedCategory!,
                      _selectedUOM!,
                      ids.isEmpty ? 1 : ids.last + 1,
                      codes.isEmpty ? 1000 : codes.last + 1,
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text("Add", style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredItems = _productItems.where((item) {
      final query = _searchQuery.toLowerCase();
      return item.productName.toLowerCase().contains(query) ||
          item.category.toLowerCase().contains(query) ||
          item.uom.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text("ITEMS", style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blueGrey,Colors.black],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : _productItems.isEmpty
            ? Center(child: Text("No Products Found"))
            : Column(
                children: [
                  Expanded(
                    child: RefreshIndicator(
                      color: Colors.blue,
                      backgroundColor: Colors.transparent,
                      onRefresh: loadItems,
                      child: ListView.builder(
                        itemCount:
                            filteredItems.length + 1, // +1 for search bar
                        itemBuilder: (context, i) {
                          if (i == 0) {
                            // ✅ Search bar is the first "item" in the list
                            return Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: TextField(
                                controller: _searchController,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  hintText:
                                      "Search by name, category or uom...",
                                  hintStyle: const TextStyle(
                                    color: Colors.white70,
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.search,
                                    color: Colors.white,
                                  ),
                                  filled: true,
                                  fillColor: Colors.black54.withOpacity(0.4),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                onChanged: (val) =>
                                    setState(() => _searchQuery = val),
                              ),
                            );
                          }

                          final item = filteredItems[i - 1]; // shift index
                          final isSelected = _selectedItem == item.productId;

                          return Card(
                            color: Colors.grey[900]?.withOpacity(0.9),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: ListTile(
                              onTap: () => debugPrint("${item.productcode}"),
                              leading: CircleAvatar(
                                backgroundColor: Colors.transparent,
                                child: Container(
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: [Colors.purple, Colors.blue],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      "${item.productId}",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              title: Text(
                                item.productName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                "${item.category} • ${item.uom}",
                                style: const TextStyle(color: Colors.white70),
                              ),
                              trailing: Checkbox(
                                value: isSelected,
                                onChanged: (v) => _toggleCheckbox(
                                  v,
                                  item.productId,
                                  item.productName,
                                ),
                                activeColor: Colors.green,
                                checkColor: Colors.black,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
      ),

      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isMenuOpen) ...[
            coustum.buildGradientFab(
              icon: Icons.delete,
              colors: [Colors.red, Colors.orange],
              onPressed: deleteItem,
            ),
            const SizedBox(height: 12),
            coustum.buildGradientFab(
              icon: Icons.add,
              colors: [Colors.green, Colors.teal],
              onPressed: () => _showAddItemDialog(context),
            ),
            const SizedBox(height: 12),
          ],
          coustum.buildGradientFab(
            icon: _isMenuOpen ? Icons.close : Icons.menu,
            colors: [Colors.black, Colors.lightBlue],
            onPressed: () => setState(() => _isMenuOpen = !_isMenuOpen),
          ),
        ],
      ),
    );
  }
}