import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:orange_inv/transaction_display.dart';
import 'package:orange_inv/transactions_add.dart';
import 'coustum.dart' as coustum;

class InvoiceItem {
  final int invoiceId;
  final String destination;
  final String vendor;
  final String invoiceDate;
  final String invoiceStatus;
  final int overHead;
  final String description;

  InvoiceItem({
    required this.description,
    required this.invoiceId,
    required this.destination,
    required this.vendor,
    required this.invoiceDate,
    required this.invoiceStatus,
    required this.overHead,
  });

  factory InvoiceItem.fromJson(Map<String, dynamic> json) {
    return InvoiceItem(
      description: json['invoice_description'],
      invoiceId: json['invoiceid'],
      destination: json['destination'],
      vendor: json['vendor'],
      invoiceDate: json['invoicedate'],
      invoiceStatus: json['invoicestatus'],
      overHead: json['overhead'],
    );
  }
}

class InvoicePage extends StatefulWidget {
  const InvoicePage({super.key});

  @override
  State<InvoicePage> createState() => _InvoicePageState();
}

class _InvoicePageState extends State<InvoicePage> {
  List<InvoiceItem> invoices = [];
  final TextEditingController _searchController = TextEditingController();

  final TextEditingController vendorController = TextEditingController();
  final TextEditingController description = TextEditingController();

  final TextEditingController invoiceIdController = TextEditingController();

  String? selectedStatus;
  late String sentDate;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    loadInvoices();
  }

  @override
  void dispose() {
    _searchController.dispose();
    description.dispose();
    vendorController.dispose();
    invoiceIdController.clear();

    super.dispose();
  }

  void _loading(bool value) {
    setState(() => isLoading = value);
  }

  List<dynamic> invoicesID = [];

  Future<int> loadInvoices() async {
    invoices.clear();
    _loading(true);
    try {
      var headers = {'Authorization': 'Basic T1JBTkdFSU5WOk9yYW5nZSMyMDI1Iw=='};
      String url = "";
      if (int.tryParse(_searchController.text) != null) {
        url =
            'https://g7bac86685e277f-omarbase.adb.eu-frankfurt-1.oraclecloudapps.com/ords/orangeinv/invoices/${_searchController.text}';
      } else if (_searchController.text.isEmpty) {
        url =
            "https://g7bac86685e277f-omarbase.adb.eu-frankfurt-1.oraclecloudapps.com/ords/orangeinv/invoices";
      } else {
        url =
            "https://g7bac86685e277f-omarbase.adb.eu-frankfurt-1.oraclecloudapps.com/ords/orangeinv/inv/searchInvoiceByDes?des=${_searchController.text}";
      }
      final request = http.Request('GET', Uri.parse(url))
        ..headers.addAll(headers);
      print("Request URL: $url");
      final response = await request.send();
      final responseBody = jsonDecode(await response.stream.bytesToString());
      if (response.statusCode == 200) {
        print("Response status: ${response.statusCode}");
        if (responseBody['items'] is List) {
          print("Response is a List, parsing invoices list.");
          final items = responseBody['items'] as List<dynamic>;
          invoices = items.map((item) => InvoiceItem.fromJson(item)).toList();
          for (var e in invoices) {
            invoicesID.add(e.invoiceId);
          }
        } else {
          InvoiceItem parseSearchInvoices() {
            return InvoiceItem.fromJson(responseBody);
          }

          setState(() {
            invoices.clear();
            invoices.add(parseSearchInvoices() as InvoiceItem);
          });
          print("Response is a Map, not a List. Parsing single invoice.");
        }
      } else {
        debugPrint(response.reasonPhrase);
      }
    } catch (e) {
      debugPrint("Error loading invoices: $e");
    } finally {
      _loading(false);
    }
    return 0;
  }

  Future<void> _selectDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2025),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: Colors.green, // header background color
              onPrimary: Colors.black, // header text color
              onSurface: Colors.white, // body text color
            ),
            dialogTheme: DialogThemeData(
              backgroundColor: Colors.black,
            ), // background color
          ),
          child: child!,
        );
      },
    );

    if (pickedDate == null) return;

    sentDate =
        "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}T00:00:00Z";

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TransactionAddPage(
          description: description.text.isEmpty ? "none" : description.text,
          invoiceId: int.parse(invoiceIdController.text),
          vendor: vendorController.text,
          sentDate: sentDate,
        ),
      ),
    ).then((_) => loadInvoices());
  }

  void _showInvoicePopup(BuildContext context) {
    Color warningColor = Colors.grey;
    bool invoiceIDValid = true;
    vendorController.clear();
    invoiceIdController.clear();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: Colors.grey[900],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Center(
                child: Text(
                  "Add Invoice",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.white54,
                  ),
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      controller: invoiceIdController,
                      style: const TextStyle(color: Colors.white),
                      onChanged: (value) {
                        if (invoicesID.contains(int.parse(value))) {
                          print("oops");
                          invoiceIDValid = false;
                          setStateDialog(() {
                            warningColor = Colors.red;
                          });
                        } else {
                          invoiceIDValid = true;

                          setStateDialog(() {
                            warningColor = Colors.grey;
                          });
                        }
                      },
                      decoration: InputDecoration(
                        helper: Text(
                          "Invoice ID must be unique",
                          style: TextStyle(
                            color: warningColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        labelText: "Invoice ID",
                        labelStyle: const TextStyle(color: Colors.white70),
                        filled: true,
                        fillColor: Colors.black26,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    coustum.buildTextField(
                      vendorController,
                      "Vendor Name",
                      isNumber: false,
                    ),
                    const SizedBox(height: 12),
                    coustum.buildTextField(
                      description,
                      "Description",
                      isNumber: false,
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    vendorController.clear();
                    description.clear();
                    invoiceIdController.clear();
                  },
                  child: const Text(
                    "Cancel",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (vendorController.text.isEmpty ||
                        invoiceIdController.text.isEmpty ||
                        !invoiceIDValid) {
                      debugPrint("⚠️ Empty fields or invalid Invoice ID");
                    } else {
                      Navigator.pop(context);
                      await _selectDate();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text("Save"),
                ),
              ],
            );
          },
        );
      },
    );
  }
  void _deleteInvoicePopup(
    BuildContext context,
    dynamic invoiceid,
    dynamic index,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Center(
            child: Text(
              "Delete Invoice#$invoiceid",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.white54,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                "Cancel",
                style: TextStyle(color: Colors.white),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);

                await deleteTransactions(invoiceid);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );
  }

  Future<void> deleteinvoice(dynamic invoiceid) async {
    try {
      var headers = {'Authorization': 'Basic T1JBTkdFSU5WOk9yYW5nZSMyMDI1Iw=='};
      var request = http.Request(
        'DELETE',
        Uri.parse(
          'https://g7bac86685e277f-omarbase.adb.eu-frankfurt-1.oraclecloudapps.com/ords/orangeinv/invoices/$invoiceid',
        ),
      );

      request.headers.addAll(headers);

      http.StreamedResponse response = await request.send();

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Deleted Invoice")));
        print(await response.stream.bytesToString());
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Not Deleted Invoice")));
        print(response.reasonPhrase);
      }
    } catch (e) {
      print("falid : $e");
    }
    _loading(false);
    setState(() {
      loadInvoices();
    });
  }

  Future<void> deleteTransactions(dynamic invoiceid) async {
    _loading(true);
    try {
      var headers = {'Authorization': 'Basic T1JBTkdFSU5WOk9yYW5nZSMyMDI1Iw=='};
      var request = http.Request(
        'DELETE',
        Uri.parse(
          'https://g7bac86685e277f-omarbase.adb.eu-frankfurt-1.oraclecloudapps.com/ords/orangeinv/inv/deleteTransactionByInvoiceID?invoiceid=$invoiceid',
        ),
      );

      request.headers.addAll(headers);

      http.StreamedResponse response = await request.send();

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Deleted Transactions")));
        await deleteinvoice(invoiceid);
        print(await response.stream.bytesToString());
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Not Deleted Transactions")));
        loadInvoices();
        print(response.reasonPhrase);
      }
    } catch (e) {
      print("Faild : $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Invoices',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
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
            const SizedBox(height: kToolbarHeight + 20),
            // 🔍 Search Bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Search by Invoice ID, Destination...",
                  hintStyle: const TextStyle(color: Colors.white70),
                  prefixIcon: IconButton(
                    onPressed: loadInvoices,
                    icon: Icon(Icons.search, color: Colors.white),
                  ),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (value) {},
              ),
            ),
            // 📑 Invoices List
            Expanded(
              child: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.blue),
                    )
                  : invoices.isEmpty
                  ? const Center(
                      child: Text(
                        "No Invoices found",
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: loadInvoices,
                      color: Colors.blue,
                      backgroundColor: Colors.transparent,
                      child: ListView.builder(
                        itemCount: invoices.length,
                        padding: const EdgeInsets.all(16),
                        itemBuilder: (context, index) {
                          final invoice = invoices[index];
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Card(
                                color: Colors.white.withOpacity(0.15),
                                elevation: 5,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                margin: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(16),
                                  title: Text(
                                    'Invoice #${invoice.invoiceId}',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      coustum.buildInvoiceRow(
                                        "Destination",
                                        invoice.destination,
                                      ),
                                      coustum.buildInvoiceRow(
                                        "Vendor",
                                        invoice.vendor,
                                      ),
                                      coustum.buildInvoiceRow(
                                        "Date",
                                        invoice.invoiceDate,
                                      ),
                                      coustum.buildInvoiceRow(
                                        "Status",
                                        invoice.invoiceStatus,
                                      ),
                                      coustum.buildInvoiceRow(
                                        "Overhead",
                                        "${invoice.overHead}%",
                                      ),
                                      coustum.buildInvoiceRow(
                                        "Description",
                                        invoice.description,
                                      ),
                                    ],
                                  ),
                                  trailing: IconButton(
                                    onPressed: () {
                                      _deleteInvoicePopup(
                                        context,
                                        invoice.invoiceId,
                                        index,
                                      );
                                    },
                                    icon: Icon(Icons.delete),
                                  ),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => TransactionDisplayPage(
                                          sent_invoiceID: invoice.invoiceId,
                                        ),
                                      ),
                                    );
                                    debugPrint(
                                      "you tapped ya 3slya#${invoice.invoiceId}",
                                    );
                                  },
                                ),
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
      floatingActionButton: SizedBox(
        width: 50,
        height: 50,
        child: FloatingActionButton(
          onPressed: () => _showInvoicePopup(context),
          backgroundColor: Colors.transparent,
          child: coustum.buildGradientFab(
            icon: Icons.add,
            colors: [Colors.black, Colors.teal],
            onPressed: () => _showInvoicePopup(context),
          ),
        ),
      ),
    );
  }
}
