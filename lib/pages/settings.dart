import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  int index = 0;
  bool loading = true;
  String? authKey;
  Map<String, dynamic>? prefs, key;
  bool p1 = false, p2 = false, p3 = false, p4 = false, p5 = false;

  /// Initialization ans setup
  void init() async {
    authKey = (await SharedPreferences.getInstance()).getString('authKey');
    final res = await http.get(
      Uri.parse('https://mess.iiit.ac.in/api/preferences'),
      headers: {"Authorization": ?authKey},
    );
    final res2 = await http.get(
      Uri.parse('https://mess.iiit.ac.in/api/auth/keys/info'),
      headers: {"Authorization": ?authKey},
    );
    if (res.statusCode == 500 || res2.statusCode == 500) {
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
    }
    prefs = jsonDecode(res.body)['data'];
    key = jsonDecode(res2.body)['data'];
    p1 = prefs!['notify_not_registered'];
    p2 = prefs!['notify_malloc_happened'];
    p3 = prefs!['auto_reset_token_daily'];
    p4 = prefs!['enable_unregistered'];
    p5 = prefs!['nag_for_feedback'];
    setState(() {
      loading = false;
    });
  }

  /// Navigate to onboarding to update auth key
  void updateKey() async {
    (await SharedPreferences.getInstance()).remove('authKey');
    Navigator.pushNamedAndRemoveUntil(context, '/onboarding', (_) => false);
  }

  /// Save updated preferences
  void savePrefs() async {
    final res = await http.put(
      Uri.parse('https://mess.iiit.ac.in/api/preferences'),
      headers: {"Authorization": ?authKey, 'Content-Type': 'application/json'},
      body: jsonEncode({
        'notify_not_registered': p1,
        'notify_malloc_happened': p2,
        'auto_reset_token_daily': p3,
        'enable_unregistered': p4,
        'nag_for_feedback': p5,
      }),
    );
    if (res.statusCode == 500) {
      Navigator.pop(context);
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
    } else if (res.statusCode == 204) {
      Fluttertoast.showToast(
        msg: 'Preferences updated successfully',
        backgroundColor: Colors.green,
      );
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => init());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: index,
        onTap: (ind) {
          setState(() {
            index = ind;
          });
        },
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.ballot), label: 'Preferences'),
          BottomNavigationBarItem(icon: Icon(Icons.key), label: 'Auth Key'),
        ],
      ),
      body: SafeArea(
        child: loading
            ? Center(child: CircularProgressIndicator())
            : index == 0
            ? SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.only(top: 10, bottom: 10),
                  child: Column(
                    children: [
                      ListTile(
                        title: Text('Send registration reminder email'),
                        subtitle: Text('Sends a reminder one day before the registration deadline'),
                        trailing: Switch(
                          value: p1,
                          onChanged: (val) {
                            setState(() {
                              p1 = val;
                            });
                          },
                        ),
                        titleTextStyle: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontSize: 17.5,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                      ListTile(
                        title: Text('Send random allocation email'),
                        subtitle: Text(
                          'Sends an email with meals if you\'ve been randomly allocated',
                        ),
                        trailing: Switch(
                          value: p2,
                          onChanged: (val) {
                            setState(() {
                              p2 = val;
                            });
                          },
                        ),
                        titleTextStyle: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontSize: 17.5,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                      ListTile(
                        title: Text('Auto-reset QR code'),
                        subtitle: Text('Resets the QR code automatically at 02:00 every day'),
                        trailing: Switch(
                          value: p3,
                          onChanged: (val) {
                            setState(() {
                              p3 = val;
                            });
                          },
                        ),
                        titleTextStyle: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontSize: 17.5,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                      ListTile(
                        title: Text('Allow availing unregistered meals'),
                        subtitle: Text('Allow availing meals on-the-spot at unregistered rates'),
                        trailing: Switch(
                          value: p4,
                          onChanged: (val) {
                            setState(() {
                              p4 = val;
                            });
                          },
                        ),
                        titleTextStyle: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontSize: 17.5,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                      ListTile(
                        title: Text('Ask for feedback'),
                        subtitle: Text('Prompts for feedback after every availed meal'),
                        trailing: Switch(
                          value: p5,
                          onChanged: (val) {
                            setState(() {
                              p5 = val;
                            });
                          },
                        ),
                        titleTextStyle: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontSize: 17.5,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                      SizedBox(height: 30),
                      ElevatedButton(
                        onPressed: savePrefs,
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(5)),
                          ),
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.green,
                        ),
                        child: Text('Save Preferences', style: TextStyle(fontSize: 17.5)),
                      ),
                    ],
                  ),
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'Name:',
                                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      'Created On:',
                                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      'Expires On:',
                                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(key!['name'], style: TextStyle(fontSize: 17)),
                                    Text(
                                      DateTime.tryParse(
                                        key!['created_at'],
                                      ).toString().split(' ')[0],
                                      style: TextStyle(fontSize: 17),
                                    ),
                                    Text(
                                      DateTime.tryParse(
                                        key!['expires_at'],
                                      ).toString().split(' ')[0],
                                      style: TextStyle(fontSize: 17),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            SizedBox(height: 15),
                            ElevatedButton(
                              onPressed: updateKey,
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.all(Radius.circular(5)),
                                ),
                                foregroundColor: Colors.white,
                                backgroundColor: Colors.green,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.edit_note_rounded, size: 20),
                                  SizedBox(width: 5),
                                  Text('Change Auth Key', style: TextStyle(fontSize: 15)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
