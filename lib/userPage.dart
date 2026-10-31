import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

class InvStock {
  final int productcode;
  final String productName;
  final String uom;
  final double quantity;
  InvStock({
    required this.uom,
    required this.productName,
    required this.productcode,
    required this.quantity,
  });
  factory InvStock.fromJson(Map<String, dynamic> json) {
    return InvStock(
      uom: json['uom'],
      productName: json['productdescription'],
      productcode: json['productcode'],
      quantity: (json['quantity'] as num).toDouble(),
    );
  }
}

class UserPage extends StatefulWidget {
  
  const UserPage({super.key});
  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  // Example stock list
  List<InvStock> InvStockLis = [];
  List<Map<String, dynamic>> stockItems = [];
  @override
  initState() {
    super.initState();
    loadStock();
  }

  bool isloading = false;
  List<dynamic> quantities=[];

  Future<void> loadStock() async { 
    setState(() => isloading = true);
    var headers = {'Authorization': 'Basic T1JBTkdFSU5WOk9yYW5nZSMyMDI1Iw=='};
    var request = http.Request(
      'GET',
      Uri.parse(
        'https://g7bac86685e277f-omarbase.adb.eu-frankfurt-1.oraclecloudapps.com/ords/orangeinv/inv/selectStock',
      ),
    );

    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      stockItems.clear();
      final stock =
          jsonDecode(await response.stream.bytesToString())['items']
              as List<dynamic>;
      setState(() {
        InvStockLis.clear();
        InvStockLis.addAll(stock.map((e) => InvStock.fromJson(e)));
        for (var row in InvStockLis) {
          stockItems.add({
            'productname': row.productName,
            'quantity': row.quantity,
            'productcode': row.productcode,
          });
          quantities.add(0);
        }
      });
    } else {
      print(response.reasonPhrase);
    }
    setState(() => isloading = false);
  }

  bool ismax = false;
  void checkforquntity(dynamic index, dynamic currentQuntity) {
    if (currentQuntity.isEmpty){quantities[index]=0;
     print(quantities[index]);
      setState(() => ismax = false);
     return;
    } 
    if (double.parse(currentQuntity) >
        double.parse("${stockItems[index]['quantity']}")) {
      setState(() => ismax = true);
    } else {
      if(currentQuntity!=0){
        quantities[index]=currentQuntity;
        print(quantities[index]);
      }else if(currentQuntity==0||currentQuntity.isEmpty){
 quantities[index]=0;
         print(quantities[index]);

      }
      setState(() => ismax = false);
  }
  }
   

  Future<void> order() async{
    if(ismax) return;
     List<Map<String,dynamic>> itemsTable=[];
 for(int i=0;i<quantities.length;i++){
  if(quantities[i].toString()!='0'){
    itemsTable.add({'productcode':stockItems[i]['productcode'],'quantity':quantities[i],'destination':"hyper"});
  }
 }
 setState(() => isloading =true);
 var headers = {
  'Authorization': 'Basic T1JBTkdFSU5WOk9yYW5nZSMyMDI1Iw=='
};
var request = http.Request('POST', Uri.parse('https://g7bac86685e277f-omarbase.adb.eu-frankfurt-1.oraclecloudapps.com/ords/orangeinv/inv/add_Order'));
request.body = jsonEncode(itemsTable);
request.headers.addAll(headers);

http.StreamedResponse response = await request.send();

if (response.statusCode == 200) {
  print(await response.stream.bytesToString());
}
else {
  print(response.reasonPhrase);
}

 setState(() => isloading =false);
  ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("${response.reasonPhrase}")),
    );

 for(var record in itemsTable){
  print("---------------------------");
  print(record['productcode']);
  print(record['quantity']);
  print(record['destination']);
  print("---------------------------");

 }

 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "Choose your items",
          style: TextStyle(color: Colors.white),
        ),
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
        child: isloading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
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
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            elevation: 5,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
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
                                  TextField(
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(
                                        RegExp(r'^\d*\.?\d*'),
                                      ),
                                    ],
                                    cursorColor: Colors.grey,
                                    decoration: InputDecoration(
                                      labelText: "Quantity",
                                      labelStyle: const TextStyle(
                                        color: Colors.white,
                                      ),
                                      enabledBorder: const UnderlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Colors.white,
                                        ), // color when not focused
                                      ),
                                      focusedBorder: UnderlineInputBorder(
                                        borderSide: BorderSide(
                                          color: ismax
                                              ? Colors.red
                                              : Colors.black,
                                          width: 2,
                                        ), // color when focused
                                      ),
                                    ),
                                    style: const TextStyle(color: Colors.white),
                                    onChanged: (value) {
                                      checkforquntity(index, value);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    TextButton(
                      onPressed: order,
                      child: Text(
                        "Order",
                        style: TextStyle(fontSize: 20, color: Colors.black45),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
