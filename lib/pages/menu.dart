import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Menu extends StatefulWidget {
  const Menu({super.key});

  @override
  State<Menu> createState() => _MenuState();
}

class _MenuState extends State<Menu> {
  String? authKey;
  bool loading = false;
  final dateContr = TextEditingController();
  String? date;
  String? day;
  final days = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"];
  List<dynamic>? menu;

  /// Fetch the menu from the API
  Future<List> getMenu() async {
    final res = await http.get(
      Uri.parse('https://mess.iiit.ac.in/api/mess/menus?on=$date'),
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
      return ["Error"];
    }
    return jsonDecode(res.body)['data'];
  }

  /// Update the UI with the menu of the newly selected day
  void updateMenus() async {
    setState(() {
      loading = true;
    });
    menu = await getMenu();
    setState(() {
      loading = false;
    });
  }

  /// Capitalize given string
  String capt(String s) {
    return "${s[0].toUpperCase()}${s.substring(1).toLowerCase()}";
  }

  /// Build the menu widgets for selected meal
  Widget buildSingleMenu(Map<String, dynamic>? data, String type) {
    if (data == null) {
      return CircularProgressIndicator();
    }
    if (data["days"][day?.toLowerCase()] == null) return Container();
    final items = data["days"][day?.toLowerCase()][type];
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Card(
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.green,
                border: Border.all(color: Colors.green),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(10),
                  topRight: Radius.circular(10),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(5),
                    child: Text(
                      capt(data["mess"]),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 17.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: ListView.separated(
                physics: NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: items.length,
                itemBuilder: (_, index) {
                  if (items[index]["item"] == "") return Container();
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(child: Text(items[index]["item"], style: TextStyle(fontSize: 15))),
                      Text(capt(items[index]["category"]), style: TextStyle(fontSize: 12)),
                    ],
                  );
                },
                separatorBuilder: (_, index) {
                  if (items[index]["item"] == "") return Container();
                  return Divider();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Initialization ans setup
  void init() async {
    final prefs = await SharedPreferences.getInstance();
    authKey = prefs.getString('authKey');
    day = days[DateTime.now().weekday - 1];
    date = DateTime.now().toString().split(" ")[0];
    dateContr.text = "$day, ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}";
    setState(() {});
    updateMenus();
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
        title: Text('Menu'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Row(
                children: [
                  IconButton(
                    onPressed:
                        date != null &&
                            DateUtils.isSameDay(DateTime.tryParse(date!), DateTime.now())
                        ? null
                        : () {
                            final newDate = DateTime.tryParse(date!)?.subtract(Duration(days: 1));
                            setState(() {
                              day = days[newDate!.weekday - 1];
                              date = newDate.toString().split(" ")[0];
                              dateContr.text =
                                  "$day, ${newDate.day}/${newDate.month}/${newDate.year}";
                            });
                            updateMenus();
                          },
                    icon: Icon(Icons.arrow_left),
                    color: Colors.green,
                    disabledColor: Theme.of(context).colorScheme.inversePrimary,
                    iconSize: 25,
                  ), // Prev day button
                  Expanded(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: MediaQuery.of(context).size.width / 2,
                          child: TextField(
                            scrollPhysics: ScrollPhysics(),
                            readOnly: true,
                            controller: dateContr,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        IconButton(
                          onPressed: () async {
                            final selectedDate = await showDatePicker(
                              context: context,
                              firstDate: DateTime.now(),
                              lastDate: DateTime(2050),
                              initialDate: DateTime.tryParse(date!),
                            );
                            if (selectedDate != null) {
                              setState(() {
                                day = days[selectedDate!.weekday - 1];
                                date = selectedDate.toString().split(" ")[0];
                                dateContr.text =
                                    "$day, ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}";
                              });
                              updateMenus();
                            }
                          },
                          icon: Icon(Icons.calendar_month),
                        ),
                      ],
                    ),
                  ), // Date-picker
                  IconButton(
                    onPressed: date != null && DateTime.tryParse(date!)?.year == 2050
                        ? null
                        : () {
                            final newDate = DateTime.tryParse(date!)?.add(Duration(days: 1));
                            setState(() {
                              day = days[newDate!.weekday - 1];
                              date = newDate.toString().split(" ")[0];
                              dateContr.text =
                                  "$day, ${newDate.day}/${newDate.month}/${newDate.year}";
                            });
                            updateMenus();
                          },
                    icon: Icon(Icons.arrow_right),
                    color: Colors.green,
                    disabledColor: Theme.of(context).colorScheme.inversePrimary,
                    iconSize: 25,
                  ), // Next day button
                ],
              ),
            ),
            SizedBox(height: 10),
            loading
                ? Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [CircularProgressIndicator()],
                    ),
                  )
                : Expanded(
                    child: DefaultTabController(
                      length: 4,
                      initialIndex: // Open menu of ongoing/upcoming meal based on current time
                      date != null && DateTime.tryParse(date!)!.isAfter(DateTime.now())
                          ? 0
                          : DateTime.now().isBefore(
                              DateTime.tryParse(
                                DateTime.now().toString(),
                              )!.copyWith(hour: 9, minute: 30),
                            )
                          ? 0
                          : DateTime.now().isBefore(
                              DateTime.tryParse(
                                DateTime.now().toString(),
                              )!.copyWith(hour: 14, minute: 30),
                            )
                          ? 1
                          : DateTime.now().isBefore(
                              DateTime.tryParse(
                                DateTime.now().toString(),
                              )!.copyWith(hour: 18, minute: 0),
                            )
                          ? 2
                          : 3,
                      child: Column(
                        children: [
                          SizedBox(
                            height: 50,
                            child: TabBar(
                              dividerHeight: 50,
                              dividerColor: Theme.of(context).colorScheme.surface,
                              indicatorSize: TabBarIndicatorSize.label,
                              tabs: [
                                Text(
                                  "Breakfast",
                                  style: TextStyle(
                                    fontSize: MediaQuery.of(context).size.width / 28,
                                  ),
                                ),
                                Text(
                                  "Lunch",
                                  style: TextStyle(
                                    fontSize: MediaQuery.of(context).size.width / 28,
                                  ),
                                ),
                                Text(
                                  "Snacks",
                                  style: TextStyle(
                                    fontSize: MediaQuery.of(context).size.width / 28,
                                  ),
                                ),
                                Text(
                                  "Dinner",
                                  style: TextStyle(
                                    fontSize: MediaQuery.of(context).size.width / 28,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 10),
                          Expanded(
                            child: TabBarView(
                              children: ["breakfast", "lunch", "snacks", "dinner"]
                                  .map(
                                    (type) => ListView.builder(
                                      itemBuilder: (_, index) {
                                        return buildSingleMenu(menu?[index], type);
                                      },
                                      itemCount: menu?.length,
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
