import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart';
import 'package:mess_iiit/pages/auth_check.dart';
import 'package:mess_iiit/pages/home.dart';
import 'package:mess_iiit/pages/menu.dart';
import 'package:mess_iiit/pages/onboarding.dart';
import 'package:mess_iiit/pages/reg.dart';
import 'package:mess_iiit/pages/settings.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  PlatformDispatcher.instance.onError = (error, _) { // Not connected to campus Wi-Fi or VPN
    if (error is ClientException) {
      Fluttertoast.showToast(
        msg: "Please connect to the campus network",
        backgroundColor: Colors.red,
      );
    }
    return true;
  };
  runApp(MessIIIT());
}

class MessIIIT extends StatelessWidget {
  const MessIIIT({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    return MaterialApp(
      title: 'MessyMatters',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.green)),
      initialRoute: '/home',
      routes: {
        '/home': (_) => Home(),
        '/auth': (_) => AuthCheck(),
        '/onboarding': (_) => Onboarding(),
        '/menu': (_) => Menu(),
        '/reg': (_) => Reg(),
        '/settings': (_) => Settings(),
      },
    );
  }
}
