import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesHelper {

  static final String kEmailAddress = "email_address";

  static Future<String> getEmailAddress() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(kEmailAddress) ?? "";
  }

  static Future<bool> setEmailAddress(String value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(kEmailAddress, value);
  }
}