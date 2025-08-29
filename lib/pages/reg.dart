import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Reg extends StatefulWidget {
  const Reg({super.key});

  @override
  State<Reg> createState() => _RegState();
}

class _RegState extends State<Reg> {
  String? authKey;
  String startDate = DateTime.now().toString().split(" ")[0];
  String? endDate;
  bool loading = true;
  List<dynamic>? regs;
  final contr = TextEditingController();
  final focusNode = FocusNode();
  late String maxDate;
  String? userId;
  final days = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"];
  final messes = ['Yuktahar', 'Palash', 'Kadamba (Veg)', 'Kadmaba (Non-Veg)'];
  final values = ['yuktahar', 'palash', 'kadamba-veg', 'kadamba-nonveg'];

  /// Capitalize given string
  String capt(String s) {
    return "${s[0].toUpperCase()}${s.substring(1).toLowerCase()}";
  }

  /// Compare two registrations based on date and meal type
  int comp(dynamic a, dynamic b) {
    if (a['meal_date'] == b['meal_date']) {
      if (a['meal_type'] == b['meal_type']) return -1;
      if (a['meal_type'] == 'breakfast') return -1;
      if (a['meal_type'] == 'dinner') return 1;
      if (a['meal_type'] == 'lunch') {
        if (b['meal_type'] == 'dinner' || b['meal_type'] == 'snacks') return -1;
        return 1;
      }
      return a['meal_type'] == 'snacks' && b['meal_type'] == 'dinner' ? -1 : 1;
    }
    return DateTime.tryParse(a['meal_date'])!.isBefore(DateTime.tryParse(b['meal_date'])!) ? -1 : 1;
  }

  /// Fetch registrations from the API
  Future<List> getRegs() async {
    final res = await http.get(
      Uri.parse('https://mess.iiit.ac.in/api/registrations?from=$startDate&to=$endDate'),
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
      setState(() {});
      return ["Error"];
    }
    dynamic temp = jsonDecode(res.body)['data'];
    temp.sort(comp);
    userId ??= temp.last['user_id'];
    return temp;
  }

  /// Switch to previous week
  void prevWeek() async {
    startDate = DateTime.tryParse(startDate)!.subtract(Duration(days: 7)).toString().split(" ")[0];
    endDate = DateTime.tryParse(startDate)!.add(Duration(days: 6)).toString().split(" ")[0];
    regs = await getRegs();
    setState(() {});
  }


  /// Switch to next week
  void nextWeek() async {
    startDate = DateTime.tryParse(startDate)!.add(Duration(days: 7)).toString().split(" ")[0];
    endDate = DateTime.tryParse(startDate)!.add(Duration(days: 6)).toString().split(" ")[0];
    if (DateTime.tryParse(endDate!)!.isAfter(DateTime.tryParse(maxDate)!)) {
      endDate = maxDate; // Don't go above the maximum allowed registration date
    }
    regs = await getRegs();
    setState(() {});
  }

  /// Register for a meal
  void register(Map<String, dynamic> meal, String mess, bool updating) async {
    final res = await http.post(
      Uri.parse('https://mess.iiit.ac.in/api/registrations'),
      headers: {"Authorization": ?authKey, 'Content-Type': 'application/json'},
      body: jsonEncode({
        'meal_date': meal['meal_date'],
        'meal_type': meal['meal_type'],
        'meal_mess': mess,
        'guests': 0,
      }),
    );
    if (res.statusCode == 403) {
      if (jsonDecode(res.body)['error']['code'] == 'mess-closed') {
        Fluttertoast.showToast(
          msg: "Mess not available for this meal",
          backgroundColor: Colors.red,
        );
      } else if (jsonDecode(res.body)['error']['code'] == 'capacity-exceeded') {
        Fluttertoast.showToast(msg: "Mess capacity full", backgroundColor: Colors.red);
      }
    } else if (res.statusCode == 500) {
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
    } else if (res.statusCode == 200) {
      Fluttertoast.showToast(
        msg: updating ? 'Meal updated successfully' : 'Meal registered successfully',
        backgroundColor: Colors.green,
      );
      regs = await getRegs();
      regs!.sort(comp);
      Navigator.pop(context);
      setState(() {});
    }
  }

  /// Uncancel a meal
  void uncancel(Map<String, dynamic> meal) async {
    final res = await http.post(
      Uri.parse('https://mess.iiit.ac.in/api/registrations/uncancel'),
      headers: {"Authorization": ?authKey, 'Content-Type': 'application/json'},
      body: jsonEncode({'meal_date': meal['meal_date'], 'meal_type': meal['meal_type']}),
    );
    if (res.statusCode == 403) {
      Fluttertoast.showToast(
        msg: 'The uncancellation window has closed',
        backgroundColor: Colors.red,
      );
      Navigator.pop(context);
    } else if (res.statusCode == 500) {
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
      Fluttertoast.showToast(msg: 'Meal uncancelled successfully', backgroundColor: Colors.green);
      regs = await getRegs();
      regs!.sort(comp);
      Navigator.pop(context);
      setState(() {});
    }
  }

  /// Cancel a meal
  void cancel(Map<String, dynamic> meal) async {
    final res = await http.post(
      Uri.parse('https://mess.iiit.ac.in/api/registrations/cancel'),
      headers: {"Authorization": ?authKey, 'Content-Type': 'application/json'},
      body: jsonEncode({'meal_date': meal['meal_date'], 'meal_type': meal['meal_type']}),
    );
    if (res.statusCode == 403) {
      Fluttertoast.showToast(
        msg: 'The cancellation window has closed',
        backgroundColor: Colors.red,
      );
      Navigator.pop(context);
    } else if (res.statusCode == 500) {
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
      Fluttertoast.showToast(msg: 'Meal cancelled successfully', backgroundColor: Colors.green);
      regs = await getRegs();
      regs!.sort(comp);
      Navigator.pop(context);
      setState(() {});
    }
  }

  /// Give feedback for a meal
  void feedback(Map<String, dynamic> meal, int rating, String remarks) async {
    final res = await http.post(
      Uri.parse('https://mess.iiit.ac.in/api/registrations/feedback'),
      headers: {"Authorization": ?authKey, 'Content-Type': 'application/json'},
      body: jsonEncode({
        'meal_date': meal['meal_date'],
        'meal_type': meal['meal_type'],
        'rating': rating,
        'remarks': remarks,
      }),
    );
    if (res.statusCode == 403) {
      Fluttertoast.showToast(msg: 'The feedback window has closed', backgroundColor: Colors.red);
      Navigator.pop(context);
    } else if (res.statusCode == 500) {
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
      Fluttertoast.showToast(msg: 'Feedback submitted successfully', backgroundColor: Colors.green);
      regs = await getRegs();
      regs!.sort(comp);
      Navigator.pop(context);
      setState(() {});
    }
  }

  /// Build the widgets for the registrations UI
  Widget buildRegs() {
    List<Widget> rows = [];
    List<String> meals = ['breakfast', 'lunch', 'snacks', 'dinner'];
    int k = 0;
    List<Map<String, dynamic>> temp = [];
    List<Map<String, dynamic>> spot = [];
    // Add the unregistered meals to the list
    for (int i = 0; i < regs!.length; i++) {
      String type = regs![i]['meal_type'];
      //on the spot registration
      if (regs![i]['registered_at'] == regs![i]['availed_at'] &&
          regs![i]['registered_at'] != null) {
        regs![i]['category'] = 'registered';
        spot.add(regs![i]);
        continue;
      }
      if (type == meals[k]) {
        k++;
        k %= 4;
        temp.add(regs![i]);
        continue;
      }
      while (type != meals[k]) {
        temp.add({
          'meal_date': regs![i]['meal_date'],
          'meal_type': meals[k],
          'meal_mess': null,
          'category': 'unregistered',
          'user_id': regs![i]['user_id'],
          "registered_at": null,
          "cancelled_at": null,
          "availed_at": null,
          "availed_price": null,
          "monthly_reg": null,
          "metadata": null,
        });
        k++;
        k %= 4;
      }
      if (type == meals[k]) {
        k++;
        k %= 4;
        temp.add(regs![i]);
      }
    }
    regs = temp;
    regs!.sort(comp);
    // add unregistered meals after the date of the last meal in the list until endDate
    if (DateTime.tryParse(startDate)!.isBefore(DateTime.tryParse(endDate!)!) ||
        (regs!.isNotEmpty &&
            DateTime.tryParse(regs!.last['meal_date'])!.isBefore(DateTime.tryParse(endDate!)!))) {
      var cur = regs!.isEmpty
          ? DateTime.tryParse(startDate)!
          : DateUtils.addDaysToDate(DateTime.tryParse(regs!.last['meal_date'])!, 1);
      while (cur.isBefore(DateTime.tryParse(endDate!)!.add(Duration(days: 1)))) {
        for (int i = 0; i < 4; i++) {
          regs!.add({
            'meal_date': cur.toString().split(" ")[0],
            'meal_type': meals[i],
            'meal_mess': null,
            'category': 'unregistered',
            'user_id': userId,
            "registered_at": null,
            "cancelled_at": null,
            "availed_at": null,
            "availed_price": null,
            "monthly_reg": null,
            "metadata": null,
          });
        }
        cur = cur.add(Duration(days: 1));
      }
    }
    for (int i = 0; i < spot.length; i++) {
      regs!.add(spot[i]);
    }
    regs!.sort(comp);
    for (int i = 0; i < regs!.length; i++) {
      Map<String, dynamic> meal = regs![i];
      if (i == 0) {
        rows.add(
          Row(
            children: [
              Expanded(child: Divider()),
              Padding(
                padding: EdgeInsets.only(left: 5, right: 5),
                child: Text(
                  days[DateTime.tryParse(regs![i]['meal_date'])!.weekday - 1],
                  style: TextStyle(fontSize: 16),
                ),
              ),
              Expanded(child: Divider()),
            ],
          ),
        );
      }
      rows.add(
        Card(
          child: InkWell(
            splashColor: Colors.grey,
            onTap: () async {
              String? curVal;
              showDialog(
                context: context,
                builder: (context) {
                  if (meal['availed_at'] != null) {
                    // Can submit feedback
                    if (meal['metadata'] != null && meal['metadata']['feedback'] == true) {
                      // Feedback already submitted
                      return AlertDialog(
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(capt(meal['meal_mess']), style: TextStyle(fontSize: 18)),
                              ],
                            ),
                            SizedBox(height: 15),
                            Text('Feedback already submitted'),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: Text('OK'),
                          ),
                        ],
                      );
                    }
                    // ask (nag) for feedback
                    int rating = 0;
                    return GestureDetector(
                      onTap: () {
                        focusNode.unfocus();
                      },
                      child: Dialog(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(10, 20, 10, 20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(capt(meal['meal_mess']), style: TextStyle(fontSize: 18)),
                                ],
                              ),
                              SizedBox(height: 15),
                              Text('Rate meal:', style: TextStyle(fontSize: 16)),
                              SizedBox(height: 10),
                              RatingBar(
                                minRating: 1,
                                maxRating: 5,
                                initialRating: 1,
                                onRatingUpdate: (value) {
                                  rating = value.toInt();
                                },
                                ratingWidget: RatingWidget(
                                  full: Icon(Icons.star, color: Colors.amber),
                                  half: Icon(Icons.star_half, color: Colors.amber),
                                  empty: Icon(Icons.star, color: Colors.grey),
                                ),
                              ),
                              SizedBox(height: 10),
                              TextField(
                                controller: contr,
                                focusNode: focusNode,
                                minLines: 3,
                                maxLines: null,
                                decoration: InputDecoration(
                                  hintText: "Remarks (optional)",
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              SizedBox(height: 15),
                              ElevatedButton(
                                onPressed: () {
                                  feedback(meal, rating, contr.text);
                                },
                                style: ElevatedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.all(Radius.circular(5)),
                                  ),
                                  foregroundColor: Colors.white,
                                  backgroundColor: Colors.green,
                                ),
                                child: Text('Submit'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }
                  // Calculation the registration and cancellation deadlines for the meal
                  var bef = DateTime.tryParse(meal['meal_date'])!.subtract(Duration(days: 3));
                  bool regOver =
                      bef.isBefore(DateTime.now()) ||
                      DateUtils.isSameDay(DateTime.now(), bef) ||
                      DateUtils.isSameDay(DateTime.now(), DateTime.tryParse(meal['meal_date'])) ||
                      DateTime.tryParse(meal['meal_date'])!.isBefore(DateTime.now());
                  bef = DateTime.tryParse(meal['meal_date'])!.subtract(Duration(days: 1));
                  bool cancelOver =
                      bef.isBefore(DateTime.now()) ||
                      DateUtils.isSameDay(DateTime.now(), bef) ||
                      DateUtils.isSameDay(DateTime.now(), DateTime.tryParse(meal['meal_date'])) ||
                      DateTime.tryParse(meal['meal_date'])!.isBefore(DateTime.now());
                  if (meal['cancelled_at'] != null) {
                    // Can uncancel
                    if (cancelOver) {
                      return AlertDialog(
                        content: Text(
                          "The uncancellation window has passed",
                          style: TextStyle(fontSize: 15),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: Text('OK'),
                          ),
                        ],
                      );
                    }
                    return Dialog(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(10, 20, 10, 20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(capt(meal['meal_mess']), style: TextStyle(fontSize: 17)),
                              ],
                            ),
                            SizedBox(height: 10),
                            ElevatedButton(
                              onPressed: () {
                                uncancel(meal);
                              },
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.all(Radius.circular(5)),
                                ),
                                foregroundColor: Colors.white,
                                backgroundColor: Colors.green,
                              ),
                              child: Text('Uncancel'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  if (meal['category'] == 'unregistered') {
                    // Can register
                    if (regOver) {
                      return AlertDialog(
                        content: Text(
                          "The registration window has passed",
                          style: TextStyle(fontSize: 15),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: Text('OK'),
                          ),
                        ],
                      );
                    }
                    return Dialog(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(10, 20, 10, 20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                StatefulBuilder(
                                  builder: (context, setState) {
                                    return DropdownButton(
                                      value: curVal,
                                      hint: Text('Choose mess'),
                                      alignment: Alignment.center,
                                      items: messes
                                          .map(
                                            (mess) => DropdownMenuItem(
                                              value: values[messes.indexOf(mess)],
                                              child: Text(mess),
                                            ),
                                          )
                                          .toList(),
                                      onChanged: (val) {
                                        setState(() {
                                          curVal = val;
                                        });
                                      },
                                    );
                                  },
                                ),
                              ],
                            ),
                            SizedBox(height: 10),
                            ElevatedButton(
                              onPressed: () {
                                if (curVal != null) {
                                  register(meal, curVal!, false);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.all(Radius.circular(5)),
                                ),
                                foregroundColor: Colors.white,
                                backgroundColor: Colors.green,
                              ),
                              child: Text('Register'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  // Registered for the meal
                  curVal = meal['meal_mess'];
                  if (DateTime.tryParse(meal['meal_date'])!.isBefore(DateTime.now()) &&
                      !DateUtils.isSameDay(DateTime.tryParse(meal['meal_date']), DateTime.now())) {
                    // Meal missed
                    return AlertDialog(
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(capt(meal['meal_mess']), style: TextStyle(fontSize: 18)),
                            ],
                          ),
                          SizedBox(height: 15),
                          Text('You missed this meal.'),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: Text('OK'),
                        ),
                      ],
                    );
                  }
                  if (cancelOver) {
                    // Deadline to cancel over
                    return AlertDialog(
                      content: Text(
                        "The cancellation window has passed",
                        style: TextStyle(fontSize: 15),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: Text('OK'),
                        ),
                      ],
                    );
                  }
                  // Can register
                  return Dialog(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(10, 20, 10, 20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              StatefulBuilder(
                                builder: (context, setState) {
                                  return DropdownButton(
                                    value: curVal,
                                    hint: Text('Choose mess'),
                                    alignment: Alignment.center,
                                    items: messes
                                        .map(
                                          (mess) => DropdownMenuItem(
                                            value: values[messes.indexOf(mess)],
                                            child: Text(mess),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: regOver
                                        ? null
                                        : (val) {
                                            setState(() {
                                              curVal = val as String;
                                            });
                                          },
                                  );
                                },
                              ),
                            ],
                          ),
                          SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: regOver
                                ? null
                                : () { // Can update if registration window not over
                                    if (curVal != null) {
                                      register(meal, curVal!, true);
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.all(Radius.circular(5)),
                              ),
                              foregroundColor: Colors.white,
                              backgroundColor: Colors.green,
                            ),
                            child: Text('Update Registration'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              cancel(meal);
                            },
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.all(Radius.circular(5)),
                              ),
                              foregroundColor: Colors.white,
                              backgroundColor: Colors.red,
                            ),
                            child: Text('Cancel Registration'),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
            // Main meal UI
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(meal['meal_date'], style: TextStyle(fontSize: 14)),
                  Row(
                    children: [
                      Text(
                        capt(
                          meal['category'] == 'unregistered'
                              ? 'unregistered'
                              : meal['availed_at'] != null
                              ? 'availed'
                              : meal['cancelled_at'] != null
                              ? 'cancelled'
                              : DateTime.tryParse(meal['meal_date'])!.isBefore(DateTime.now()) &&
                                    !DateUtils.isSameDay(
                                      DateTime.tryParse(meal['meal_date']),
                                      DateTime.now(),
                                    )
                              ? 'missed'
                              : meal['meal_mess'] == 'kadamba-veg'
                              ? 'Kadamba (V)'
                              : meal['meal_mess'] == 'kadambda-nonveg'
                              ? 'Kadamba (NV)'
                              : meal['meal_mess'],
                        ),
                        style: TextStyle(fontSize: 16),
                      ),
                      SizedBox(width: 10),
                      meal['category'] == 'registered' &&
                              DateTime.tryParse(meal['meal_date'])!.isBefore(DateTime.now())
                          ? meal['availed_at'] != null
                                ? Icon(Icons.check_circle, size: 20, color: Colors.green)
                                : meal['cancelled_at'] != null
                                ? Icon(Icons.cancel, size: 20, color: Colors.red)
                                : !DateUtils.isSameDay(
                                    DateTime.tryParse(meal['meal_date']),
                                    DateTime.now(),
                                  )
                                ? Icon(Icons.do_not_disturb_on, color: Colors.yellow[600])
                                : Icon(Icons.circle_outlined, size: 20)
                          : Icon(Icons.circle_outlined, size: 20),
                      SizedBox(width: 10),
                      Text(capt(meal['meal_type']), style: TextStyle(fontSize: 17)),
                      Icon(Icons.keyboard_arrow_right),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      // Day
      if (regs![i]['meal_type'] == 'dinner' &&
          i < regs!.length - 1 &&
          regs![i + 1]['meal_type'] != 'dinner') {
        rows.add(
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.only(left: 5, right: 5),
                      child: Text(
                        days[DateTime.tryParse(regs![i + 1]['meal_date'])!.weekday - 1],
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                    Expanded(child: Divider()),
                  ],
                ),
              ],
            ),
          ),
        );
      }
    }
    return SingleChildScrollView(child: Column(children: rows));
  }

  /// Initialization ans setup
  void init() async {
    final prefs = await SharedPreferences.getInstance();
    authKey = prefs.getString('authKey');
    endDate = DateTime.tryParse(startDate)!.add(Duration(days: 6)).toString().split(" ")[0];
    regs = await getRegs();
    regs!.sort(comp);
    DateTime? d = DateTime.tryParse(startDate!);
    if (DateTime(d!.year, d!.month + 1, 0).isBefore(d)) {
      endDate = DateTime(d!.year, d!.month + 1, 0).toString().split(" ")[0];
    }
    final res = await http.get(
      Uri.parse('https://mess.iiit.ac.in/api/config/registration-max-date'),
      headers: {"Authorization": ?authKey},
    );
    maxDate = jsonDecode(res.body)['data'];
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
      appBar: AppBar(
        title: Text('Registrations'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SafeArea(
        child: loading
            ? Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          startDate,
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        Text(' - ', style: TextStyle(fontSize: 20)),
                        Text(endDate!, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        ElevatedButton(
                          onPressed: prevWeek,
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.all(Radius.circular(5)),
                            ),
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.green,
                            disabledBackgroundColor: Theme.of(context).colorScheme.inversePrimary,
                            disabledForegroundColor: Colors.white,
                          ),
                          child: Text('Previous Week'),
                        ),
                        ElevatedButton(
                          onPressed: endDate == maxDate ? null : nextWeek,
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.all(Radius.circular(5)),
                            ),
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.green,
                            disabledBackgroundColor: Theme.of(context).colorScheme.inversePrimary,
                            disabledForegroundColor: Colors.white,
                          ),
                          child: Text('Next Week'),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(padding: const EdgeInsets.all(10), child: buildRegs()),
                  ),
                ],
              ),
      ),
    );
  }
}
