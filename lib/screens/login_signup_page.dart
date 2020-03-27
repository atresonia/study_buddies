import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:study_buddies/services/auth.dart';
import 'package:study_buddies/services/shared_prefs_helper.dart';


class LoginSignupPage extends StatefulWidget {
  final BaseAuth auth;
  final VoidCallback loginCallback;

  LoginSignupPage({this.auth, this.loginCallback});

  @override
  State<StatefulWidget> createState() {
    return LoginSignupPageState();
  }
}

class LoginSignupPageState extends State<LoginSignupPage> {
  final formKey = new GlobalKey<FormState>();
  final GlobalKey<ScaffoldState> scaffoldKey = new GlobalKey<ScaffoldState>();
  TextEditingController emailController;

  String email;
  String password;
  String errorMessage;

  bool isLoginForm;
  bool isLoading;

  @override
  void initState() {
    errorMessage = "";
    isLoading = false;
    isLoginForm = true;
    super.initState();

    getSavedEmailAddress();

    checkLoggedInStatus();
  }

  Future<void> checkLoggedInStatus() async {
    // See https://stackoverflow.com/questions/54469191/persist-user-auth-flutter-firebase
    FirebaseUser currentUser = await widget.auth.getCurrentUser();
    if (currentUser != null) {
      // Go to home page
      print("User is already logged in; skipping login page");
      Crashlytics.instance.setUserEmail(currentUser.email);

      /*Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (BuildContext context) =>
              HomePage(auth: widget.auth, user: currentUser)));*/
    }
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        key: scaffoldKey,
        appBar: new AppBar(
          title: new Text("Study Buddies"),
        ),
        body: Stack(
          children: <Widget>[showLogo(), showForm(), showCircularProgress()],
        ));
  }

  Future<Null> getSavedEmailAddress() async {
    email = await SharedPreferencesHelper.getEmailAddress();

    setState(() {
      emailController = new TextEditingController(text: email);
    });
  }

  Widget showCircularProgress() {
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    return Container(
      height: 0.0,
      width: 0.0,
    );
  }

  Widget showLogo() {
    return new Hero(
      tag: 'hero',
      child: Padding(
          padding: EdgeInsets.fromLTRB(50.0, 30.0, 50.0, 70.0),
          child: Image.asset('images/ucsc.png')),
    );
  }

  Widget showForm() {
    return new Container(
        padding: EdgeInsets.all(16.0),
        child: new Form(
            key: formKey,
            child: new ListView(
              shrinkWrap: true,
              children: <Widget>[
                showEmailInput(),
                showPasswordInput(),
                showPrimaryButton(),
                showSecondaryButton()
              ],
            )));
  }

  /*
  FutureBuilder<String> showFutureEmailInput() {
    return FutureBuilder<String>(
      future: SharedPreferencesHelper.getEmailAddress(),
      initialData: "",
      builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
        return showEmailInput(snapshot.hasData ? snapshot.data : "");
      },
    );
  }
  */

  Widget showEmailInput() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0.0, 140.0, 0.0, 0.0),
      child: new TextFormField(
        controller: emailController,
        maxLines: 1,
        keyboardType: TextInputType.emailAddress,
        autofocus: false,
        decoration: new InputDecoration(
            hintText: 'Email',
            icon: new Icon(
              Icons.mail,
              color: Colors.grey,
            )),
        validator: (value) => value.isEmpty ? 'Email can\'t be empty' : null,
        onSaved: (value) => email = value.trim(),
      ),
    );
  }

  Widget showPasswordInput() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0.0, 15.0, 0.0, 0.0),
      child: new TextFormField(
        maxLines: 1,
        obscureText: true,
        autofocus: false,
        decoration: new InputDecoration(
            hintText: 'Password',
            icon: new Icon(
              Icons.lock,
              color: Colors.grey,
            )),
        validator: (value) => value.isEmpty ? 'Password can\'t be empty' : null,
        onSaved: (value) => password = value.trim(),
      ),
    );
  }

  Widget showPrimaryButton() {
    return new Padding(
        padding: EdgeInsets.fromLTRB(0.0, 45.0, 0.0, 0.0),
        child: SizedBox(
          height: 40.0,
          child: new RaisedButton(
            elevation: 5.0,
            shape: new RoundedRectangleBorder(
                borderRadius: new BorderRadius.circular(30.0)),
            color: Colors.blue,
            child: new Text(isLoginForm ? 'Login' : 'Create account',
                style: new TextStyle(fontSize: 20.0, color: Colors.white)),
            onPressed: validateAndSubmit,
          ),
        ));
  }

  Widget showSecondaryButton() {
    return new FlatButton(
        child: new Text(
            isLoginForm ? 'Create an account' : 'Have an account? Sign in',
            style: new TextStyle(fontSize: 18.0, fontWeight: FontWeight.w300)),
        onPressed: toggleFormMode);
  }

  void toggleFormMode() {
    resetForm();
    setState(() {
      isLoginForm = !isLoginForm;
    });
  }

  void resetForm() {
    formKey.currentState.reset();
    errorMessage = "";
  }

  // Perform login or sign up
  void validateAndSubmit() async {
    setState(() {
      errorMessage = "";
      isLoading = true;
    });

    if (validateAndSave()) {
      FirebaseUser user;
      try {
        if (isLoginForm) {
          user = await widget.auth.signIn(email, password);
          print('Signed in: ${user.uid}');
        } else {
          user = await widget.auth.signUp(email, password);
          widget.auth.sendEmailVerification();
          showVerifyEmailSentDialog();
          // print('Signed up user: $userId');
        }
        setState(() {
          isLoading = false;
        });

        if (user != null && isLoginForm) {
          SharedPreferencesHelper.setEmailAddress(email);
          widget.loginCallback();
        }
      } catch (e) {
        print("Error in validateAndSave: $e");
        showMessage(e.message);
        setState(() {
          isLoading = false;
          errorMessage = e.message;
          formKey.currentState.reset();
        });
      }
    }
    /*
      String userId = await widget.auth.signIn(email, password);
      print("User $userId signed in");

      setState(() {
        isLoading = false;
      });

      this.widget.loginCallback();
      */
  }

  void showVerifyEmailSentDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // return object of type Dialog
        return AlertDialog(
          title: new Text("Verify your account"),
          content:
              new Text("Link to verify account has been sent to your email"),
          actions: <Widget>[
            new FlatButton(
              child: new Text("Dismiss"),
              onPressed: () {
                toggleFormMode();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // Check if form is valid before perform login or signup
  bool validateAndSave() {
    final form = formKey.currentState;
    if (form.validate()) {
      form.save();
      return true;
    }
    return false;
  }

  void showMessage(String msg) {
    final snackBar = SnackBar(backgroundColor: Colors.red, content: Text(msg));
    scaffoldKey.currentState.showSnackBar(snackBar);
  }
}
