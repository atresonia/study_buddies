import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:study_buddies/model/auth_status.dart';
//import 'package:study_buddies/screens/courses_page.dart';
import 'package:study_buddies/services/auth.dart';

import '../main.dart';

//import 'home_page.dart';
import 'login_signup_page.dart';

class RootPage extends StatefulWidget {
  final BaseAuth auth;

  RootPage({this.auth});

  @override
  State<StatefulWidget> createState() {
    return new RootPageState();
  }
}

class RootPageState extends State<RootPage> {

  FirebaseUser user;
  AuthStatus authStatus = AuthStatus.NOT_DETERMINED;
  final dbRef = Firestore.instance;
  int numCoursesSelected = -1;

  @override
  void initState() {
    print("In RootPageState.initState(): AuthStatus is $authStatus");
    super.initState();

    if (authStatus == AuthStatus.LOGGED_IN) {
      return;
    }

    print("In RootPageState.initState(): Checking login status...");

    isLoggedIn().then((loggedIn) {
      print("In RootPageState.initState(): Done checking login status: $loggedIn");
      handleAuthStatus(loggedIn);
    });
  }

  @override
  Widget build(BuildContext context) {
    print("In RootPageState.build(): authStatus is $authStatus");
    switch (authStatus) {
      case AuthStatus.NOT_DETERMINED:
        return Center(
          child: CircularProgressIndicator(),
        );

      case AuthStatus.NOT_LOGGED_IN:
        return new LoginSignupPage(auth: widget.auth, loginCallback: loginCallback);
       /*
      case AuthStatus.LOGGED_IN:
        // Check if the user has selected courses
        if (numCoursesSelected == -1) {
          // Still checking
          return Center(
            child: CircularProgressIndicator(),
          );
        } else if (numCoursesSelected == 0) {
          print("User ${user.email} has no courses selected");
          return new CoursesPage(auth: widget.auth, user: user);
        } else {
          return new HomePage(auth: widget.auth, user: user);
        }
        break;

      default:
        return new LoginSignupPage(auth: widget.auth, loginCallback: loginCallback);
    */}
  }

  Future<bool> isLoggedIn() async {
    // See https://stackoverflow.com/questions/54469191/persist-user-auth-flutter-firebase
    user = await widget.auth.getCurrentUser();
    if (user != null && user.isEmailVerified) {
      // Go to home page
      print("In RootPageState.isLoggedIn(): User ${user.email} is logged in");
      Crashlytics.instance.setUserEmail(user.email);
      return true;
    }

    return false;
  }

  /*
  Future<int> getNumUserCourses() async {
    QuerySnapshot snapshot = await dbRef.collection("users").document(user.uid)
        .collection("courses").getDocuments();
    return snapshot.documents.length;
  }
  */

  Future<List<String>> getSelectedCourses() async {
    QuerySnapshot snapshot = await dbRef.collection("users").document(user.uid)
        .collection("courses").getDocuments();
    return snapshot.documents.map((docSnapshot) {
      return docSnapshot.documentID;
    }).toList();
  }

  void loginCallback() {
    print("In RootPageState.loginCallback()");
    isLoggedIn().then((loggedIn) {
      handleAuthStatus(loggedIn);
    });
  }

  void handleAuthStatus(bool loggedIn) {
    if (loggedIn) {
      authStatus = AuthStatus.LOGGED_IN;

      getSelectedCourses().then((selectedCourses) {
        numCoursesSelected = selectedCourses.length;
        print("$numCoursesSelected selected courses in the database: ${selectedCourses.toString()}");

        setState(() {});
      });

    } else {
      setState(() {
        authStatus = AuthStatus.NOT_LOGGED_IN;
      });
    }
  }

}