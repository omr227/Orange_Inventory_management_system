import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:orange_inv/coustum.dart' as coustum;
import 'package:orange_inv/coustum.dart';

class Users {
  final String username;
  Users({required this.username});
  factory Users.fromJson(Map<String, dynamic> json) {
    return Users(username: json['username']);
  }
}
class auth_settings extends StatefulWidget {
  const auth_settings({super.key});

  @override
  State<auth_settings> createState() => _auth_settingsState();
}

class _auth_settingsState extends State<auth_settings> {
  bool isloading= true;
List<dynamic> usernames = [];

//get all users from the api
    Future<void> get_all_users() async {
      
    setState(() => isloading = true);
    try{
    var headers = {'Authorization': 'Basic T1JBTkdFSU5WOk9yYW5nZSMyMDI1Iw=='};
    var request = http.Request(
      'GET',
      Uri.parse(
        'https://g7bac86685e277f-omarbase.adb.eu-frankfurt-1.oraclecloudapps.com/ords/orangeinv/inv/get_all_users',
      ),
    );

    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      final userResponse =
          jsonDecode(await response.stream.bytesToString())['items']
              as List<dynamic>;
      List<Users> parseAuth() {
        return userResponse.map((item) => Users.fromJson(item)).toList();
      }
      usernames.clear();
      setState(() {
        usernames = parseAuth().map((user) => user.username).toList();
      });
    print(usernames.length);
    } else {throw Exception('Failed to load users');
    }}
    catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
      print(e);
    }finally {
    setState(() => isloading = false);
    }}
//delete user from the api
  Future<void> delete_user(String username) async {
    setState(() => isloading = true);
    var headers = {'Authorization': 'Basic T1JBTkdFSU5WOk9yYW5nZSMyMDI1Iw=='};
    var request = http.Request(
      'DELETE',
      Uri.parse(
        'https://g7bac86685e277f-omarbase.adb.eu-frankfurt-1.oraclecloudapps.com/ords/orangeinv/auth/$username',
      ),
    );

    request.headers.addAll(headers);
try{
    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("user $username deleted")));
      print(await response.stream.bytesToString());
      await get_all_users();
    } else {
     throw Exception('Failed to delete user');
    }
}catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
      print(e);
    }finally {
    setState(() => isloading = false);}
  }
//show dialog to add user
 void _showAddUser(BuildContext context) {
    TextEditingController usernameController = TextEditingController();
    TextEditingController passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Center(
            child: Text(
              "Add User",
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
                buildTextField(isNumber: false,usernameController, "username",),

                const SizedBox(height: 12),
                buildTextField(isNumber: false,passwordController, "password"),
              ],
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
                if (usernameController.text!="" ||
                    passwordController.text!="") {
                 Navigator.pop(context);
                   add_user(usernameController.text, passwordController.text);
                  
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text("Add"),
            ),
          ],
        );
      },
    );
  }
//add user to the api
  Future<void> add_user(String username, String pass) async {
    try {
      setState(() => isloading = true);
      var headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Basic T1JBTkdFSU5WOk9yYW5nZSMyMDI1Iw==',
      };
      var request = http.Request(
        'POST',
        Uri.parse(
          'https://g7bac86685e277f-omarbase.adb.eu-frankfurt-1.oraclecloudapps.com/ords/orangeinv/auth/',
        ),
      );
      request.body = json.encode({"pass": pass, "username": username});
      request.headers.addAll(headers);

      http.StreamedResponse response = await request.send();

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("user created")));
        print(await response.stream.bytesToString());
        await get_all_users();
      } else {
        throw Exception('Failed to create user');
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => isloading = false);
    }
  }
//show dialog to edit admin password
  void _showEditAdminPass(BuildContext context) {
    TextEditingController passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Center(
            child: Text(
              "Edit Admin Password",
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
                buildTextField(isNumber: false,passwordController, "New Password"),
              ],
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
                if (passwordController.text!="") {
                 Navigator.pop(context);
                   edit_admin_pass(passwordController.text);
                  
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
  }
//edit Admin password
Future<void> edit_admin_pass(String newPass) async{
  setState(() => isloading = true);
var headers = {
  'Authorization': 'Basic T1JBTkdFSU5WOk9yYW5nZSMyMDI1Iw=='
};
var request = http.Request('POST', Uri.parse('https://g7bac86685e277f-omarbase.adb.eu-frankfurt-1.oraclecloudapps.com/ords/orangeinv/inv/admin_update?pass=$newPass'));
try{
request.headers.addAll(headers);

http.StreamedResponse response = await request.send();

if (response.statusCode == 200) {
   ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Admin password updated")));
  print(await response.stream.bytesToString());
}
else {
  throw Exception('Failed to update admin password');
}
}catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
      print(e);
    }finally {
    setState(() => isloading = false);}
}
void initState() {
    super.initState();
    get_all_users();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title:  Text("Authentication Settings",style: TextStyle(color: Colors.white)),
        centerTitle: true,
         backgroundColor: Colors.transparent,
      ),
      body:  Container(
         decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blueGrey,Colors.black],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: isloading?  Center(child: CircularProgressIndicator()):  ListView.builder(
          itemCount: usernames.length,
          itemBuilder: (context, index) {
            return ListTile(
              title: Text("${usernames[index]}",style: TextStyle(color: Colors.white),),
              contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              leading: CircleAvatar(
                backgroundColor: Colors.blueGrey,
                child: Text(
                  usernames[index][0].toUpperCase(),
                  style: TextStyle(color: Colors.white),
                ),
              ),
              trailing: usernames[index]=="Admin"? IconButton(
                icon: Icon(Icons.password_sharp),
                onPressed: () {
                  _showEditAdminPass(context);
                  print("edit pass: ${usernames[index]}");
                },
              ) : IconButton(
                icon: Icon(Icons.delete),
                onPressed: () {
                  delete_user(usernames[index]);
                  print("Delete user: ${usernames[index]}");
                },
              )
            );
          },
        )
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.transparent,
        onPressed: () {
          // Add your action here
        },
        child:  coustum.buildGradientFab(
            icon: Icons.group_add_sharp,
            colors: [Colors.black, Colors.teal],
            onPressed: () => _showAddUser(context),
          ),
        
      ),
    );
  }
}