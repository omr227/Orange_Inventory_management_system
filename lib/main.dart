import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:orange_inv/adminItems.dart';
import 'package:orange_inv/userPage.dart';
import 'coustum.dart' as coustum;

void main() {
  runApp(const MyApp());
}


class AuthItem {
  final String users;


  AuthItem({
    required this.users,

  });

  factory AuthItem.fromJson(Map<String, dynamic> json) {
    return AuthItem(
      users: json['username'],
    );
  }
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});
  
  @override
  
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const LoginPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  
  @override
  
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
final List<String> usernames = [];
 String? selectedUser;
  bool hidePassword = true;
  final TextEditingController passwordController = TextEditingController();

  void _togglePasswordVisibility() {
    setState(() {
      hidePassword = !hidePassword;
    });
  }

  Future <void> getUsers() async{
   var headers = {
  'Authorization': 'Basic T1JBTkdFSU5WOk9yYW5nZSMyMDI1Iw=='
 };
var request = http.Request('GET', Uri.parse('https://g7bac86685e277f-omarbase.adb.eu-frankfurt-1.oraclecloudapps.com/ords/orangeinv/inv/auth'));


request.headers.addAll(headers);

http.StreamedResponse response = await request.send();

if (response.statusCode == 200) {
  final authResponse = jsonDecode(await response.stream.bytesToString())['items'] as List<dynamic>;
List<AuthItem> authItems =
   authResponse.map((item)=>AuthItem.fromJson(item)).toList();
setState(() {
  usernames.clear();
  usernames.addAll(authItems.map((item) => item.users));
});
}else {
  print(response.reasonPhrase);
}
  }

Future<void> login(String user, String pass) async {
    if (selectedUser == Null || passwordController.text.isEmpty) return;
    try {
      var request = http.Request(
        'POST',
        Uri.parse(
          'https://g7bac86685e277f-omarbase.adb.eu-frankfurt-1.oraclecloudapps.com/ords/orangeinv/inv/auth?username=$user&pass=$pass',
        ),
      );

      http.StreamedResponse response = await request.send();

      if (response.statusCode == 200) {
        //parse the string json into map
        final authResponse = jsonDecode(await response.stream.bytesToString());
        //pass it to the model to factor it to authitem
        AuthItem authItems = AuthItem.fromJson(authResponse);
        if(authItems.users=="unauthorized"){
            throw Exception("Invalid password");
        }else{

          switch (authItems.users) {
            case 'Admin':
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AdminItems(),
                ),
              );
              break;
             default:
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => UserPage(),
                ),
              );
              break;
           
          }
        }
        print(authItems.users);
      } else {
        print(response.reasonPhrase);
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
  }
 

  @override
  void initState() {
    super.initState();
    getUsers();
  }

  
  @override
  void dispose() {
    // This will run when page is closed
    print("Page closed!");
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      body:Container(
        decoration: BoxDecoration(gradient:  LinearGradient(
  colors: [Colors.blueGrey, Colors.black],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
)),
        child: Center(
        child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.max,
              children: [
                 const Icon(Icons.lock_person_sharp,
                      size: 80, color: Colors.black45),
                const SizedBox(height:kToolbarHeight),
                // Username Dropdown
                  coustum.buildDropdown("Select your username", usernames,
                    selectedUser, (val) => selectedUser = val??' '),
                const SizedBox(height: 16),
                // Password Field with toggle
                TextField(
 style: const TextStyle(color: Colors.white),
                   cursorColor: Colors.black,
                  controller: passwordController,
                  obscureText: hidePassword,
                  decoration: InputDecoration(
                    
    
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.black26,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
                    labelText: 'Password',
                    suffixIcon: IconButton(
                      color: Color(0xFFFA812F),
                      icon: Icon(
                        hidePassword ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: _togglePasswordVisibility,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
        
                // Login Button
                SizedBox(
                  width: double.infinity,
                  height: 45,
                  child: ElevatedButton(
                    style:   ElevatedButton.styleFrom(
                    foregroundColor: Color.fromARGB(255, 0, 0, 0),
                      backgroundColor: Colors.transparent

                    ),
                    onPressed: ()=>login(selectedUser!, passwordController.text.trim()) ,
                    child: const Text('Login'),
                  ),
                ),
              ],
            ),
          
        ),
        ),
      )
    );
  }
}