import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';

class Onboarding extends StatefulWidget {
  const Onboarding({super.key});

  @override
  State<Onboarding> createState() => _OnboardingState();
}

class _OnboardingState extends State<Onboarding> {
  final contr = TextEditingController();
  final focusNode = FocusNode();
  bool loading = false;
  bool isError = false;
  bool showScanner = false;
  String error = "";

  /// Save entered auth key to local storage
  Future<void> saveAuthKey(String authKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('authKey', authKey);
    Fluttertoast.showToast(
      msg: "Auth Key Validated",
      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
    );
  }

  /// Check if entered auth key is valid
  Future<void> checkAuthKey(String authKey) async {
    setState(() {
      loading = true;
      isError = false;
    });
    final res = await http.get(
      Uri.parse('https://mess.iiit.ac.in/api/auth/me'),
      headers: {"Authorization": authKey},
    );
    if (res.statusCode == 401 || res.statusCode == 500) {
      isError = true;
      if (res.statusCode == 401) {
        error = "Invalid Auth Key";
      } else {
        error = "Internal Server Error";
      }
      setState(() {});
    } else {
      await saveAuthKey(authKey);
      Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
    }
    setState(() {
      loading = false;
    });
  }

  @override
  void dispose() {
    contr.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return showScanner
        ? PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, result) {
              setState(() {
                showScanner = false;
              });
            },
            child: MobileScanner(
              onDetect: (res) {
                contr.text = (res.barcodes.first.rawValue)!;
                setState(() {
                  showScanner = false;
                });
                checkAuthKey(contr.text);
              },
            ),
          )
        : GestureDetector(
            onTap: () {
              focusNode.unfocus();
            },
            child: Scaffold(
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
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Center(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextField(
                              focusNode: focusNode,
                              controller: contr,
                              decoration: InputDecoration(
                                hintText: "Mess Portal Auth Key",
                                border: OutlineInputBorder(),
                              ),
                            ),
                            SizedBox(height: 10),
                            loading
                                ? Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text('Validating Auth Key'),
                                      SizedBox(width: 10),
                                      SizedBox(
                                        width: 15,
                                        height: 15,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      ),
                                    ],
                                  )
                                : Column(
                                    children: [
                                      ElevatedButton(
                                        onPressed: () {
                                          checkAuthKey(contr.text);
                                        },
                                        style: ElevatedButton.styleFrom(
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.all(Radius.circular(5)),
                                          ),
                                        ),
                                        child: Text('Submit'),
                                      ),
                                      SizedBox(height: 5),
                                      ElevatedButton(
                                        onPressed: () async {
                                          setState(() {
                                            showScanner = true;
                                          });
                                        },
                                        style: ElevatedButton.styleFrom(
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.all(Radius.circular(5)),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.qr_code),
                                            SizedBox(width: 5),
                                            Text('Scan QR Code'),
                                          ],
                                        ),
                                      ),
                                      Visibility(
                                        visible: isError,
                                        child: Column(
                                          children: [
                                            SizedBox(height: 5),
                                            Text(error, style: TextStyle(color: Colors.red)),
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
              ),
            ),
          );
  }
}
