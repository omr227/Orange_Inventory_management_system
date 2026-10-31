
import 'package:flutter/material.dart';
import 'package:orange_inv/stockItem.dart';
import 'package:restart_app/restart_app.dart';
import 'items.dart';
import 'showInvoices.dart';
import 'auth_setting.dart';
import 'transaction_display.dart';

class Users {
  final String username;
  Users({required this.username});
  factory Users.fromJson(Map<String, dynamic> json) {
    return Users(username: json['username']);
  }
}

class AdminItems extends StatefulWidget {
  const AdminItems({super.key});

  @override
  State<AdminItems> createState() => _AdminItemsState();

  static const appGradient = LinearGradient(
    colors: [Colors.blueGrey,Colors.black],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const titleStyle = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.bold,
    color: Colors.white,
    letterSpacing: 1.2,
  );

  static const subtitleStyle = TextStyle(color: Colors.white70, fontSize: 16);
}

class _AdminItemsState extends State<AdminItems> {
 
  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const auth_settings()),
              );
            },
            icon: Icon(Icons.settings),
          ),
          IconButton(
            onPressed: () =>Restart.restartApp(),
            icon: Icon(Icons.logout_sharp),
          ),
        ],
        centerTitle: true,
        backgroundColor: Colors.transparent,
        title: const Text(
          "Admin Panel",
          style: AdminItems.titleStyle,
          textAlign: TextAlign.center,
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AdminItems.appGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: 
             
                 Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 30),
                      _buildAdminButton(
                        context,
                        label: "ITEMS",
                        icon: Icons.store,
                        page: const ItemsPage(),
                      ),
                      _buildAdminButton(
                        context,
                        label: "INVOICES",
                        icon: Icons.receipt_long,
                        page: const InvoicePage(),
                      ),
                      _buildAdminButton(
                        context,
                        label: "TRANSACTIONS",
                        icon: Icons.swap_horiz,
                        page: const TransactionDisplayPage(sent_invoiceID: 0),
                      ) ,
                _buildAdminButton(
                  context,
                  label: "STOCK",
                  icon: Icons.inventory,
                  page:  StockPage(),
                ), 
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildAdminButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Widget page,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: ElevatedButton.icon(
        onPressed: () =>
            Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: Colors.black.withOpacity(0.7),
          foregroundColor: Colors.white,
        ),
        icon: Icon(icon, size: 26),
        label: Text(
          label,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
