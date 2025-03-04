import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:new_firebase/screens/main_screen.dart';

class RegisterController {
  static Future<void> registerWithEmail({
    required BuildContext context,
    required String email,
    required String password,
    required String name,
    required String nis,
  }) async {
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      var userId = FirebaseAuth.instance.currentUser!.uid;
      var db = FirebaseFirestore.instance;

      Map<String, dynamic> data = {
        "name": name,
        "nis": nis,
        "email": email,
        "id": userId.toString(),
      };
      try {
        await db.collection("users").doc(userId.toString()).set(data);
      } catch (e) {
        print(e);
      }

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) {
            return MainScreen();
          },
        ),
        (route) {
          return false;
        },
      );

      print("Account Created Successfully");
    } catch (e) {
      SnackBar messageSnackbar = SnackBar(
        backgroundColor: Colors.red,
        content: Text(e.toString()),
      );

      ScaffoldMessenger.of(context).showSnackBar(messageSnackbar);
    }
  }
}
