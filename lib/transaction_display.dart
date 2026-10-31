import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class GrandTotal{
  final double total;
  GrandTotal({
    required this.total
  });
  factory GrandTotal.fromJson(Map<String, dynamic> json) {
    return GrandTotal(
      total: (json['total'] as num).toDouble()
    );
  }
}

class Transaction {
  final int productcode;
  final String productName;
  final int invoiceId;
  final double quantity;
  final double rest_quantity;
  final String status;
  final String uom;
  final double price;

  Transaction({
    required this.rest_quantity,
    required this.productName,
    required this.invoiceId,
    required this.status,
    required this.uom,
    required this.productcode,
    required this.quantity,
    required this.price,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      rest_quantity:( json['restquantity']as num).toDouble(),
      uom: json['uom'] ?? '',
      invoiceId: json['invoiceid'],
      productName: json['productdescription'],
      status: json['transactionstatus'],
      productcode: json['productcode'],
      quantity: (json['quantity'] as num).toDouble(),
      price: (json['price'] as num).toDouble(),
    );
  }
}

class TransactionDisplayPage extends StatefulWidget {
  final int sent_invoiceID;
  const TransactionDisplayPage({super.key, required this.sent_invoiceID});

  @override
  State<TransactionDisplayPage> createState() =>
      _TransactionDisplayPageState(sent_invoiceID: sent_invoiceID);
}

class _TransactionDisplayPageState extends State<TransactionDisplayPage> {
  final int sent_invoiceID;
  _TransactionDisplayPageState({required this.sent_invoiceID});
  List<Transaction> transactions = [];
  final TextEditingController _searchController = TextEditingController();
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    loadTransactions();
            sent_invoiceID == 0 ? null : culcGrandTotal();

    
  }

  String title() {
    if (sent_invoiceID == 0) {
      return "Transactions";
    } else {
      return "Transactions#$sent_invoiceID";
    }
  }

  Future<int> search_invoice() async {
    String? url;
    if (int.tryParse(_searchController.text) != null&&sent_invoiceID==0) {
      url =
          "https://g7bac86685e277f-omarbase.adb.eu-frankfurt-1.oraclecloudapps.com/ords/orangeinv/inv/get_transactions_byinvoiceid?sentid=${_searchController.text}";
    } else if (_searchController.text == "IN" ||
        _searchController.text == "OUT"&&sent_invoiceID==0) {
      url="https://g7bac86685e277f-omarbase.adb.eu-frankfurt-1.oraclecloudapps.com/ords/orangeinv/inv/get_trans_byStatus?status=${_searchController.text}";
    } else if (_searchController.text.isEmpty) {
      print("i am nothing");
      return 0;
    } else if(sent_invoiceID==0){

     url="https://g7bac86685e277f-omarbase.adb.eu-frankfurt-1.oraclecloudapps.com/ords/orangeinv/inv/get_trans_byProductName?productname=${_searchController.text}";       
    }else{
           url="https://g7bac86685e277f-omarbase.adb.eu-frankfurt-1.oraclecloudapps.com/ords/orangeinv/inv/get_trans_byProductName?productname=${_searchController.text}&invoiceid=$sent_invoiceID";       
    }

    setState(() => isLoading = true);

    var headers = {'Authorization': 'Basic U1BJQ1lURVNUOk9tYXIjMjIyMjA3Iw=='};
    var request = http.Request(
      'GET',
      Uri.parse(url),
    );
    request.headers.addAll(headers);

    try {
      final response = await request.send();
      if (response.statusCode == 200) {
        final items =
            jsonDecode(await response.stream.bytesToString())['items']
                as List<dynamic>;

        setState(() {
          transactions = items
              .map((item) => Transaction.fromJson(item))
              .toList();
        });
      } else {
        debugPrint("Failed: ${response.reasonPhrase}");
      }
    } catch (e) {
      debugPrint("Error loading transactions: $e");
    } finally {
      setState(() => isLoading = false);
    }

    return 0;
  }

  Future<void> loadTransactions() async {
    setState(() => isLoading = true);

    var headers = {'Authorization': 'Basic T1JBTkdFSU5WOk9yYW5nZSMyMDI1Iw=='};
    var request = http.Request(
      'GET',
      Uri.parse(
        sent_invoiceID == 0
            ? 'https://g7bac86685e277f-omarbase.adb.eu-frankfurt-1.oraclecloudapps.com/ords/orangeinv/inv/get_transactions'
            : 'https://g7bac86685e277f-omarbase.adb.eu-frankfurt-1.oraclecloudapps.com/ords/orangeinv/inv/get_transactions_byinvoiceid?sentid=$sent_invoiceID',
      ),
    );
    request.headers.addAll(headers);

    //try {
      final response = await request.send();
      if (response.statusCode == 200) {
        final items =
            jsonDecode(await response.stream.bytesToString())['items']
                as List<dynamic>;

        setState(() {
          transactions = items
              .map((item) => Transaction.fromJson(item))
              .toList();
        });

        print(items.length);
      } else {
        debugPrint("Failed: ${response.reasonPhrase}");
      }
    //} catch (e) {
     // debugPrint("Error loading transactions: $e");
    //} finally {
      setState(() => isLoading = false);
    //}

    setState(() => isLoading = false);

  }

  String? grandTotlaText;
  Future<void> culcGrandTotal() async {
 var headers = {
  'Authorization': 'Basic T1JBTkdFSU5WOk9yYW5nZSMyMDI1Iw=='
};
var request = http.Request('GET', Uri.parse('https://g7bac86685e277f-omarbase.adb.eu-frankfurt-1.oraclecloudapps.com/ords/orangeinv/inv/grand_total?sent_id=$sent_invoiceID'));

request.headers.addAll(headers);

http.StreamedResponse response = await request.send();

if (response.statusCode == 200) {
  final items = jsonDecode(await response.stream.bytesToString());

      GrandTotal parseGrands() {
        return GrandTotal.fromJson(items);
      }

      GrandTotal Grands = parseGrands();
      print(Grands.total);
      setState(() =>  grandTotlaText="${Grands.total} EGP");
     
}
else {
  print(response.reasonPhrase);
}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
extendBodyBehindAppBar: true,
      appBar:AppBar(title: Text(title(),style: TextStyle(color: Colors.white),),
      centerTitle: true,
      backgroundColor: Colors.transparent,),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blueGrey,Colors.black],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
          child: Column(
            children: [
              // 🔹 Transactions List
              Expanded(
                child: isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.blue),
                      )
                    : RefreshIndicator(
                        color: Colors.blue,
          backgroundColor: Colors.transparent,
                        onRefresh: loadTransactions,
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(
                            parent: BouncingScrollPhysics(),
                          ),
                          itemCount: transactions.length+1,
                          itemBuilder: (context, index) {
                            if(index==0){
             return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: TextField(
                  controller: _searchController,
                  // keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: sent_invoiceID==0 ?"Search by Invoice ID, Product Name, Status...": "Search by Product Name...",
                    hintStyle: const TextStyle(color: Colors.white54),
                    prefixIcon: IconButton(onPressed:search_invoice, icon: Icon(Icons.search,color: Colors.white,)),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.15),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon:
                        IconButton(
                            icon: const Icon(
                              Icons.clear,
                              color: Colors.white70,
                            ),
                            onPressed: () {
                              setState(() {
                              _searchController.text="";
                              });},
                          )
                        ,
                  ),
                 
                ),
              ); 
                            }

final tx = transactions[index-1];
                            final isIn = tx.status == "IN";


                               if(transactions.isNotEmpty){
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeInOut,
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: isIn
                                      ? [
                                          Colors.green.shade400,
                                          Colors.green.shade900,
                                        ]
                                      : [
                                          Colors.red.shade400,
                                          Colors.red.shade900,
                                        ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(2, 4),
                                  ),
                                ],
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16),
                                leading: CircleAvatar(
                                  radius: 28,
                                  backgroundColor: Colors.white24,
                                  child: Icon(
                                    isIn
                                        ? Icons.arrow_downward
                                        : Icons.arrow_upward,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ),
                                title: Text(
                                  tx.productName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Invoice ID: ${tx.invoiceId}",
                                        style: const TextStyle(
                                          color: Colors.white70,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "Qty: ${tx.quantity} ${tx.uom}",
                                        style: const TextStyle(
                                          color: Colors.white70,
                                        ),
                                      ),
                                      Text(
                                        "price per ${tx.uom}: ${tx.price}",
                                        style: const TextStyle(
                                          color: Colors.white70,
                                        ),
                                      ),
                                        Text(
                                        "Rest Quantity :${tx.rest_quantity}",
                                        style: const TextStyle(
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                trailing: Text(
                                  "${tx.price.toDouble() * tx.quantity} EGP",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            );}
                               return null;
                          },
                        ),
                      ),
              ),
              sent_invoiceID == 0
                  ? SizedBox()
                  : grandTotlaText == null
                  ? Text("Grand Totla: 0")
                  : Text("Grand Totla: $grandTotlaText"),
            ],
          ),
        ),
      
    );
  }
}
