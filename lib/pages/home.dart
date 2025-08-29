import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  bool loading = true;
  late String name;
  String? authKey;

  /// Read auth key from local storage and get info about user
  void getAuthKey() async {
    final prefs = await SharedPreferences.getInstance();
    authKey = prefs.getString('authKey');
    final res = await http.get(
      Uri.parse('https://mess.iiit.ac.in/api/auth/me'),
      headers: {"Authorization": ?authKey},
    );
    if (res.statusCode == 500) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text("Internal Server Error"),
            content: Text("Please try again later"),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.popUntil(context, (_) => false);
                },
                child: Text("Ok"),
              ),
            ],
          );
        },
      );
      return;
    } else if (res.statusCode == 401) {
      prefs.remove('authKey');
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text("Invalid Auth Key"),
            content: Text("Please enter auth key again"),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/onboarding');
                },
                child: Text("Ok"),
              ),
            ],
          );
        },
      );
      return;
    }
    setState(() {
      loading = false;
      name = jsonDecode(res.body)['data']['name'];
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => getAuthKey());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('IIIT Mess Portal'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            onPressed: () {
              showAboutDialog(
                context: context,
                children: [
                  SelectableText(
                    'Made by Sumanyu Aggarwal. Source Code:\nhttps://github.com/SuPythony/MessyMatters',
                  ),
                ],
              );
            },
            icon: Icon(Icons.info_outline),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: loading || authKey == null
              ? CircularProgressIndicator()
              : Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Center(
                    child: Column(
                      children: [
                        Padding(
                          padding: EdgeInsets.only(top: 10),
                          child: Column(
                            children: [
                              ShaderMask(
                                shaderCallback: (bounds) => LinearGradient(
                                  colors: [Colors.red, Colors.yellow[700]!],
                                ).createShader(bounds),
                                child: Text(
                                  'MessyMatters',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.pirataOne(
                                    fontSize: MediaQuery.of(context).size.width / 6,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              ShaderMask(
                                shaderCallback: (bounds) => LinearGradient(
                                  colors: [Colors.green.shade700, Colors.green],
                                ).createShader(bounds),
                                child: Text(
                                  'Welcome, $name',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.pangolin(
                                    fontSize: MediaQuery.of(context).size.width / 15,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: MediaQuery.of(context).size.height / 10),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(10, 10, 10, 2.5),
                          child: Card(
                            elevation: 5,
                            child: InkWell(
                              splashColor: Colors.grey,
                              onTap: () {
                                Navigator.pushNamed(context, '/menu');
                              },
                              child: ListTile(
                                title: Text(
                                  'Menu',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                                leading: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.restaurant_menu, color: Colors.green),
                                  ],
                                ),
                                subtitle: const Text('View mess menu'),
                                trailing: const Icon(Icons.navigate_next),
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(10, 10, 10, 2.5),
                          child: Card(
                            elevation: 5,
                            child: InkWell(
                              splashColor: Colors.grey,
                              onTap: () {
                                Navigator.pushNamed(context, '/reg');
                              },
                              child: ListTile(
                                title: Text(
                                  'Registrations',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                                leading: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.list, color: Colors.green),
                                  ],
                                ),
                                subtitle: const Text('Manage your registrations'),
                                trailing: const Icon(Icons.navigate_next),
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(10, 10, 10, 2.5),
                          child: Card(
                            elevation: 5,
                            child: InkWell(
                              splashColor: Colors.grey,
                              onTap: () {
                                Navigator.pushNamed(context, '/settings');
                              },
                              child: ListTile(
                                title: Text(
                                  'Settings',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                                leading: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.settings, color: Colors.green),
                                  ],
                                ),
                                subtitle: const Text('Update your settings'),
                                trailing: const Icon(Icons.navigate_next),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
