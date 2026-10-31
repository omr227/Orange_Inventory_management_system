import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;


class InvStock {
   final int productcode;
  final String productName;
  final String uom;
  final double quantity;
   final double price;

  InvStock({
    required this.uom,
    required this.productName,
    required this.productcode,
    required this.quantity,
    required this.price
  });
  factory InvStock.fromJson(Map<String, dynamic>json){
    return InvStock(
      uom: json['uom'],
      productName: json['productdescription'],
      productcode:json['productcode'],
      quantity:(json['quantity']as num).toDouble(),
      price:(json['price']as num).toDouble(),
    );
  }
}


class StockPage extends StatefulWidget {
  const StockPage({super.key});

  @override
  State<StockPage> createState() => _StockPageState();
}

class _StockPageState extends State<StockPage> {
  // Example stock list
    List <InvStock> InvStockLis=[];
    List<Map<String, dynamic>> stockItems=[] ;
  @override

   initState() {
    super.initState();
    loadStock();
  }
bool isloading=false;
  Future <void> loadStock()async{
    setState(()=> isloading=true);
    var headers = {
  'Authorization': 'Basic T1JBTkdFSU5WOk9yYW5nZSMyMDI1Iw=='
};
var request = http.Request('GET', Uri.parse('https://g7bac86685e277f-omarbase.adb.eu-frankfurt-1.oraclecloudapps.com/ords/orangeinv/inv/get_stock'));

request.headers.addAll(headers);

http.StreamedResponse response = await request.send();

if (response.statusCode == 200) {
  
      final stock =
          jsonDecode(await response.stream.bytesToString())['items']
              as List<dynamic>;
      setState(() {
InvStockLis.clear();
        InvStockLis.addAll(stock.map((e) => InvStock.fromJson(e)));
for(var row in InvStockLis){
  stockItems.add({
    'productname':row.productName,
    'uom':row.uom,
    'quantity':row.quantity,
    'price':row.price,
    'productcode':row.productcode
  });
}
});}
else {
  print(response.reasonPhrase);
}
    setState(()=> isloading=false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Inventory Stock", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        centerTitle: true,
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
        child:
        isloading? const Center(child: CircularProgressIndicator(),): RefreshIndicator(
           color: Colors.blue,
          backgroundColor: Colors.transparent,
          onRefresh: loadStock,
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: stockItems.length,
                  itemBuilder: (context, index) {
                    final item = stockItems[index];
                    return Card(
                      color: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      elevation: 5,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Product Name
                            Text(
                              "${item["productname"]}",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
         Text("${item['quantity']} ${item['uom']} × ${item['price']} EGP",style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                              ),
                              )
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
