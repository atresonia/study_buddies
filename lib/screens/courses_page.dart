import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:study_buddies/model/course.dart';

//import 'package:study_buddies/model/course.dart';
//import 'package:study_buddies/screens/my_courses_page.dart';
import 'package:study_buddies/services/auth.dart';
import 'package:async/async.dart';

import 'home_page.dart';

class CoursesPage extends StatefulWidget {
  final BaseAuth auth;
  final FirebaseUser user;

  CoursesPage({this.auth, this.user});

  @override
  State<StatefulWidget> createState() {
    return new CoursesPageState();
  }
}

//https://github.com/yousoff92/flutter-firebase-crud-app/blob/management-app/lib/screens/item.dart
class CoursesPageState extends State<CoursesPage> {
  List<Course> selectedCourses = new List();
  String searchText;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Select courses"),
          actions: <Widget>[
            new IconButton(
                icon: new Icon(Icons.save),
                tooltip: "Save selection",
                onPressed: addSelectedCourses)
          ],
        ),
        body: Column(
          children: <Widget>[
            TextField(
                autocorrect: false,
                enableSuggestions: false,
                decoration: new InputDecoration(
                    hintText: "Search for course number",
                    contentPadding: EdgeInsets.fromLTRB(20, 0, 20, 0)),
                onChanged: (text) {
                  setState(() {
                    searchText = text
                        .toUpperCase(); // Must uppercase as our course numbers (documentIds) are uppercase
                  });
                }),
            //showCoursesList(),
          ],
        ));
  }

  void addSelectedCourses() async {
    // Add the selected courses to Firebase
    if (selectedCourses.length == 0) {
      return;
    }

    CollectionReference coursesColl = Firestore.instance.collection("users").document(widget.user.uid)
        .collection("courses");
    print("User ${widget.user.uid} Adding selected courses: ${selectedCourses.toString()}");

    // Get a new write batch. Like transactions, batched writes are atomic.
    var batch = Firestore.instance.batch();

    // Add selected courses
    for (Course course in selectedCourses) {
      batch.setData(coursesColl.document(course.number), {"name": course.name});
    }

    await batch.commit().then((value) {
      print("Added selected courses");

      // Go to the study sessions page
//      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) =>
//          HomePage(auth: widget.auth, user: widget.user)));

    }).catchError((err) {
      print("Unable to add selected courses: ${err.toString()}");
    });

  }
}
