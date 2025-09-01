import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mess_iiit/components/drawer.dart';
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
  String date = DateTime.now().toString().split(" ")[0];
  late List<dynamic> regs;
  bool upcoming = false;
  bool ongoing = false;
  late String type, mess;
  Map<String, List> timings = {
    'Breakfast': [
      [7, 30],
      [9, 30],
    ],
    'Lunch': [
      [12, 30],
      [14, 30],
    ],
    'Snacks': [
      [16, 45],
      [18, 15],
    ],
    'Dinner': [
      [19, 30],
      [21, 30],
    ],
  };

  /// Capitalize given string
  String capt(String s) {
    return "${s[0].toUpperCase()}${s.substring(1).toLowerCase()}";
  }

  /// Read auth key from local storage and get info about user
  Future<void> getAuthKey() async {
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
    name = jsonDecode(res.body)['data']['name'];
  }

  /// Compare two registrations based on meal type
  int comp(dynamic a, dynamic b) {
    if (a['meal_type'] == b['meal_type']) return -1;
    if (a['meal_type'] == 'breakfast') return -1;
    if (a['meal_type'] == 'dinner') return 1;
    if (a['meal_type'] == 'lunch') {
      if (b['meal_type'] == 'dinner' || b['meal_type'] == 'snacks') return -1;
      return 1;
    }
    return a['meal_type'] == 'snacks' && b['meal_type'] == 'dinner' ? -1 : 1;
  }

  /// Fetch registrations for the current day
  Future<void> getTodayRegs() async {
    final res = await http.get(
      Uri.parse('https://mess.iiit.ac.in/api/registrations?from=$date&to=$date'),
      headers: {"Authorization": ?authKey},
    );
    if (res.statusCode != 200) {
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
    }
    regs = jsonDecode(res.body)['data'];
    regs.sort(comp);
  }

  /// Initialization and setup
  void init() async {
    await getAuthKey();
    await getTodayRegs();
    for (int i = 0; i < regs.length; i++) {
      Map<String, dynamic> reg = regs[i];
      if (reg['category'] != 'registered') continue;
      if (reg['availed_at'] != null || reg['cancelled_at'] != null) continue;
      type = capt(reg['meal_type']);
      mess = capt(reg['meal_mess']);
      DateTime now = DateTime.now();
      if (now.isBefore(now.copyWith(hour: timings[type]![0][0], minute: timings[type]![0][1]))) {
        upcoming = true;
        break;
      } else if (now.isBefore(
        now.copyWith(hour: timings[type]![1][0], minute: timings[type]![1][1]),
      )) {
        ongoing = true;
        break;
      }
    }
    setState(() {
      loading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => init());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: SideDrawer(),
      appBar: AppBar(
        title: Text('IIIT Mess Portal'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            onPressed: () {
              showAboutDialog(
                context: context,
                applicationIcon: Image.asset('images/icon.png', scale: 17),
                applicationName: 'MessyMatters',
                applicationVersion: '1.0.0',
                children: [
                  SelectableText(
                    'Made by Sumanyu Aggarwal.\n\nSource Code:\nhttps://github.com/SuPythony/MessyMatters',
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
                                  children: [Icon(Icons.restaurant_menu, color: Colors.green)],
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
                                  children: [Icon(Icons.list, color: Colors.green)],
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
                                  children: [Icon(Icons.settings, color: Colors.green)],
                                ),
                                subtitle: const Text('Update your settings'),
                                trailing: const Icon(Icons.navigate_next),
                              ),
                            ),
                          ),
                        ),
                        Expanded(child: Container()),
                        Column(
                          children: [
                            Divider(),
                            !upcoming && !ongoing
                                ? Text(
                                    'All meals finished for the day!',
                                    style: TextStyle(fontSize: 18),
                                  )
                                : IntrinsicHeight(
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                      children: [
                                        Text(
                                          upcoming ? 'Upcoming' : 'Ongoing',
                                          style: TextStyle(fontSize: 18),
                                        ),
                                        VerticalDivider(),
                                        Text(type, style: TextStyle(fontSize: 18)),
                                        VerticalDivider(),
                                        Column(
                                          children: [
                                            Text(mess, style: TextStyle(fontSize: 16)),
                                            Text(
                                              '${timings[type]![0][0]}:${timings[type]![0][1]}-'
                                              '${timings[type]![1][0]}:${timings[type]![1][1]}',
                                              style: TextStyle(fontSize: 13),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                          ],
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
