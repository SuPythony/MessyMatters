import 'package:flutter/material.dart';

class SideDrawer extends StatelessWidget {
  const SideDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Theme.of(context).colorScheme.inversePrimary),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "MessyMatters",
                  style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          ListTile(
            selected: ModalRoute.of(context)?.settings.name == '/home',
            leading: const Icon(Icons.home),
            title: const Text("Home"),
            onTap: () {
              Navigator.pop(context);
              if (ModalRoute.of(context)?.settings.name != '/home') {
                Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
              }
            },
          ),
          ListTile(
            selected: ModalRoute.of(context)?.settings.name == '/menu',
            leading: const Icon(Icons.restaurant_menu),
            title: const Text("Menu"),
            onTap: () {
              Navigator.pop(context);
              if (ModalRoute.of(context)?.settings.name != '/menu') {
                Navigator.pushNamed(context, '/menu');
              }
            },
          ),
          ListTile(
            selected: ModalRoute.of(context)?.settings.name == '/reg',
            leading: const Icon(Icons.list),
            title: const Text("Registrations"),
            onTap: () {
              Navigator.pop(context);
              if (ModalRoute.of(context)?.settings.name != '/reg') {
                Navigator.pushNamed(context, '/reg');
              }
            },
          ),
          ListTile(
            selected: ModalRoute.of(context)?.settings.name == '/settings',
            leading: const Icon(Icons.settings),
            title: const Text("Settings"),
            onTap: () {
              Navigator.pop(context);
              if (ModalRoute.of(context)?.settings.name != '/settings') {
                Navigator.pushNamed(context, '/settings');
              }
            },
          ),
        ],
      ),
    );
  }
}
